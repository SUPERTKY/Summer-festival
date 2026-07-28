--!strict

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChocolateBananaService = {}
ChocolateBananaService.__index = ChocolateBananaService

type StaffState = {
	stallId: string,
	step: string,
	busy: boolean,
	held: { Instance },
	lockObjects: { Instance },
	originalMovement: {
		walkSpeed: number,
		jumpPower: number,
		jumpHeight: number,
		autoRotate: boolean,
	},
}

type DisplayState = {
	instance: Instance,
	prompt: ProximityPrompt,
}

local STEP_DISPLAY_ASSET: { [string]: string } = {
	Empty = "Banana",
	Banana = "Banana",
	Ingredients = "Banana",
	Skewered = "SkeweredBanana",
	Dipped = "DippedBanana",
	Finished = "FinishedBanana",
}

type ChocolateBananaService = typeof(setmetatable(
	{} :: {
		_config: any,
		_moneyService: any,
		_assets: any,
		_remotes: { [string]: RemoteEvent },
		_staffByStall: { [string]: Player },
		_stateByPlayer: { [Player]: StaffState },
		_pendingJoin: { [Player]: { stallId: string, expiresAt: number } },
		_displayByStall: { [string]: DisplayState },
		_currentDisplayByStall: { [string]: Instance },
		_touchTimes: { [Player]: number },
		_bound: { [Instance]: boolean },
	},
	ChocolateBananaService
))

local function getRoot(instance: Instance): BasePart?
	if instance:IsA("BasePart") then
		return instance
	end
	if instance:IsA("Model") then
		return instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function getCharacterPlayer(hit: BasePart): Player?
	local character = hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil
	end
	return Players:GetPlayerFromCharacter(character)
end

local function getStallId(instance: Instance): string?
	local current: Instance? = instance
	while current do
		local value = current:GetAttribute("StallId")
		if type(value) == "string" and value ~= "" then
			return value
		end
		current = current.Parent
	end
	return nil
end

local function createRemote(folder: Folder, name: string): RemoteEvent
	local existing = folder:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	return remote
end

function ChocolateBananaService.new(config: any, moneyService: any, assets: any): ChocolateBananaService
	local packageFolder = ReplicatedStorage:WaitForChild("ChocolateBanana")
	local remoteFolder = packageFolder:FindFirstChild("Remotes")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "Remotes"
		remoteFolder.Parent = packageFolder
	end

	return setmetatable({
		_config = config,
		_moneyService = moneyService,
		_assets = assets,
		_remotes = {
			StaffRequest = createRemote(remoteFolder :: Folder, "StaffRequest"),
			StaffStatus = createRemote(remoteFolder :: Folder, "StaffStatus"),
			Notify = createRemote(remoteFolder :: Folder, "Notify"),
			Action = createRemote(remoteFolder :: Folder, "Action"),
		},
		_staffByStall = {},
		_stateByPlayer = {},
		_pendingJoin = {},
		_displayByStall = {},
		_currentDisplayByStall = {},
		_touchTimes = {},
		_bound = {},
	}, ChocolateBananaService)
end

function ChocolateBananaService:_notify(player: Player, message: string)
	self._remotes.Notify:FireClient(player, message)
end

function ChocolateBananaService:_isNear(player: Player, part: BasePart): boolean
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not root or not root:IsA("BasePart") then
		return false
	end
	return (root.Position - part.Position).Magnitude <= self._config.PromptDistance + 2
end

function ChocolateBananaService:_sendStatus(player: Player)
	local state = self._stateByPlayer[player]
	if state then
		self:_syncCurrentDisplay(state)
	end
	self._remotes.StaffStatus:FireClient(player, {
		isStaff = state ~= nil,
		stallId = if state then state.stallId else nil,
		step = if state then state.step else "None",
		busy = if state then state.busy else false,
	})
end

function ChocolateBananaService:_findTaggedPart(tag: string, stallId: string): BasePart?
	for _, instance in CollectionService:GetTagged(tag) do
		if getStallId(instance) == stallId then
			local root = getRoot(instance)
			if root then
				return root
			end
		end
	end
	return nil
end

function ChocolateBananaService:_clearCurrentDisplay(stallId: string)
	local existing = self._currentDisplayByStall[stallId]
	if existing and existing.Parent then
		existing:Destroy()
	end
	self._currentDisplayByStall[stallId] = nil
end

function ChocolateBananaService:_syncCurrentDisplay(state: StaffState)
	local assetName = STEP_DISPLAY_ASSET[state.step]
	local existing = self._currentDisplayByStall[state.stallId]
	if existing and existing.Parent and existing:GetAttribute("ChocolateBananaDisplayAsset") == assetName then
		return
	end

	self:_clearCurrentDisplay(state.stallId)
	if not assetName then
		return
	end

	local displayPoint = self:_findTaggedPart(self._config.Tags.CurrentStepDisplayPoint, state.stallId)
	if not displayPoint then
		warn(`CurrentStepDisplayPoint was not found for stall {state.stallId}`)
		return
	end

	local item = self._assets:Place(assetName, displayPoint.CFrame, workspace)
	if not item then
		warn(`Could not display {assetName} for stall {state.stallId}`)
		return
	end

	item.Name = `CB_CurrentStep_{assetName}`
	item:SetAttribute("ChocolateBananaDisplayAsset", assetName)
	self._currentDisplayByStall[state.stallId] = item
end

function ChocolateBananaService:_clearHeld(state: StaffState)
	for _, instance in state.held do
		if instance.Parent then
			instance:Destroy()
		end
	end
	table.clear(state.held)
end

function ChocolateBananaService:_attachItem(
	player: Player,
	state: StaffState,
	hand: string,
	itemName: string
): Instance?
	local character = player.Character
	if not character then
		return nil
	end

	local item = self._assets:Attach(character, hand, itemName)
	if item then
		table.insert(state.held, item)
	end
	return item
end

function ChocolateBananaService:_replaceHeld(player: Player, state: StaffState, hand: string, itemName: string): boolean
	self:_clearHeld(state)
	return self:_attachItem(player, state, hand, itemName) ~= nil
end

function ChocolateBananaService:_lockAtStation(player: Player, stallId: string): boolean
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local anchor = self:_findTaggedPart(self._config.Tags.WorkAnchor, stallId)
	if not character or not humanoid or not root or not root:IsA("BasePart") or not anchor then
		return false
	end

	character:PivotTo(anchor.CFrame)
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid.AutoRotate = false

	local rootAttachment = Instance.new("Attachment")
	rootAttachment.Name = "ChocolateBananaPositionAttachment"
	rootAttachment.Parent = root

	local anchorAttachment = Instance.new("Attachment")
	anchorAttachment.Name = "ChocolateBananaStationAttachment"
	anchorAttachment.Parent = anchor

	local position = Instance.new("AlignPosition")
	position.Name = "ChocolateBananaStationLock"
	position.Attachment0 = rootAttachment
	position.Attachment1 = anchorAttachment
	position.ApplyAtCenterOfMass = true
	position.RigidityEnabled = true
	position.Parent = root

	local state = self._stateByPlayer[player]
	if state then
		state.lockObjects = { rootAttachment, anchorAttachment, position }
	end

	local diedConnection: RBXScriptConnection?
	diedConnection = humanoid.Died:Connect(function()
		if diedConnection then
			diedConnection:Disconnect()
		end
		self:_resign(player, false)
	end)
	return true
end

function ChocolateBananaService:_join(player: Player, stallId: string)
	if self._stateByPlayer[player] then
		self:_notify(player, "すでに屋台スタッフです。")
		return
	end
	if self._staffByStall[stallId] then
		self:_notify(player, "この屋台にはすでにスタッフがいます。")
		return
	end

	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if not humanoid then
		self:_notify(player, "キャラクターを確認できませんでした。")
		return
	end

	local state: StaffState = {
		stallId = stallId,
		step = "Empty",
		busy = false,
		held = {},
		lockObjects = {},
		originalMovement = {
			walkSpeed = humanoid.WalkSpeed,
			jumpPower = humanoid.JumpPower,
			jumpHeight = humanoid.JumpHeight,
			autoRotate = humanoid.AutoRotate,
		},
	}
	self._stateByPlayer[player] = state
	self._staffByStall[stallId] = player

	if not self:_lockAtStation(player, stallId) then
		self._stateByPlayer[player] = nil
		self._staffByStall[stallId] = nil
		self:_notify(player, "WorkAnchor が見つからないためスタッフになれませんでした。")
		return
	end

	self:_sendStatus(player)
	self:_notify(player, "チョコバナナ屋台のスタッフになりました。")
end

function ChocolateBananaService:_resign(player: Player, sendMessage: boolean)
	local state = self._stateByPlayer[player]
	if not state then
		return
	end

	self:_clearHeld(state)
	for _, object in state.lockObjects do
		if object.Parent then
			object:Destroy()
		end
	end

	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if humanoid then
		humanoid.WalkSpeed = state.originalMovement.walkSpeed
		humanoid.JumpPower = state.originalMovement.jumpPower
		humanoid.JumpHeight = state.originalMovement.jumpHeight
		humanoid.AutoRotate = state.originalMovement.autoRotate
	end

	self:_clearCurrentDisplay(state.stallId)
	self._staffByStall[state.stallId] = nil
	self._stateByPlayer[player] = nil
	self._pendingJoin[player] = nil
	self:_sendStatus(player)
	if sendMessage then
		self:_notify(player, "屋台スタッフを辞任しました。")
	end
end

function ChocolateBananaService:_playAnimation(player: Player, animationId: string, duration: number)
	if animationId == "" then
		return
	end

	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if not humanoid then
		return
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = if string.find(animationId, "rbxassetid://")
		then animationId
		else `rbxassetid://{animationId}`
	local success, track = pcall(function()
		return (animator :: Animator):LoadAnimation(animation)
	end)
	animation:Destroy()

	if success and track then
		track:Play(0.15)
		task.delay(duration, function()
			track:Stop(0.15)
			track:Destroy()
		end)
	end
end

function ChocolateBananaService:_facePart(player: Player, part: BasePart): AlignOrientation?
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not root or not root:IsA("BasePart") then
		return nil
	end

	local direction = Vector3.new(part.Position.X - root.Position.X, 0, part.Position.Z - root.Position.Z)
	if direction.Magnitude < 0.01 then
		direction = Vector3.new(part.CFrame.LookVector.X, 0, part.CFrame.LookVector.Z)
	end
	if direction.Magnitude < 0.01 then
		return nil
	end

	local attachment = root:FindFirstChild("ChocolateBananaPositionAttachment")
	if not attachment or not attachment:IsA("Attachment") then
		return nil
	end

	root.CFrame = CFrame.lookAt(root.Position, root.Position + direction.Unit)
	local orientation = Instance.new("AlignOrientation")
	orientation.Name = "ChocolateBananaFacingLock"
	orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	orientation.Attachment0 = attachment
	orientation.CFrame = CFrame.lookAt(Vector3.zero, direction.Unit)
	orientation.RigidityEnabled = true
	orientation.Parent = root
	return orientation
end

function ChocolateBananaService:_startBusyAction(
	player: Player,
	expectedStep: string,
	duration: number,
	animationId: string,
	facePart: BasePart?,
	onComplete: (StaffState) -> ()
)
	local state = self._stateByPlayer[player]
	if not state or state.busy or state.step ~= expectedStep then
		return
	end

	state.busy = true
	local stallId = state.stallId
	local orientation = if facePart then self:_facePart(player, facePart) else nil
	self:_sendStatus(player)
	self:_playAnimation(player, animationId, duration)

	task.delay(duration, function()
		local current = self._stateByPlayer[player]
		if not current or current ~= state or current.stallId ~= stallId then
			if orientation and orientation.Parent then
				orientation:Destroy()
			end
			return
		end

		if orientation and orientation.Parent then
			orientation:Destroy()
		end
		onComplete(current)
		current.busy = false
		self:_sendStatus(player)
	end)
end

function ChocolateBananaService:_addToppingEffect(state: StaffState)
	local held = state.held[1]
	local root = if held then getRoot(held) else nil
	if not root then
		return
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "ChocolateBananaToppingEffect"
	attachment.Position = Vector3.new(0, -0.8, 0)
	attachment.Parent = root

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "ToppingParticles"
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 90)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 225, 80)),
		ColorSequenceKeypoint.new(0.66, Color3.fromRGB(115, 210, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	emitter.Lifetime = NumberRange.new(0.6, 1)
	emitter.Rate = 45
	emitter.Speed = NumberRange.new(2, 4)
	emitter.EmissionDirection = Enum.NormalId.Bottom
	emitter.SpreadAngle = Vector2.new(20, 20)
	emitter.Acceleration = Vector3.new(0, -10, 0)
	emitter.Enabled = true
	emitter.Parent = attachment

	task.delay(3, function()
		emitter.Enabled = false
	end)
	Debris:AddItem(attachment, 4)
end

function ChocolateBananaService:_takeBanana(player: Player, stallId: string)
	local state = self._stateByPlayer[player]
	if not state or state.stallId ~= stallId or state.busy then
		return
	end
	if state.step ~= "Empty" then
		self:_notify(player, "今の工程ではバナナを取れません。")
		return
	end

	if self:_attachItem(player, state, "LeftHand", "Banana") then
		state.step = "Banana"
		self:_sendStatus(player)
	end
end

function ChocolateBananaService:_takeStick(player: Player, stallId: string)
	local state = self._stateByPlayer[player]
	if not state or state.stallId ~= stallId or state.busy then
		return
	end
	if state.step ~= "Banana" then
		self:_notify(player, "先にバナナを取ってください。")
		return
	end

	if self:_attachItem(player, state, "RightHand", "Stick") then
		state.step = "Ingredients"
		self:_sendStatus(player)
	end
end

function ChocolateBananaService:_skewer(player: Player)
	self:_startBusyAction(
		player,
		"Ingredients",
		self._config.ActionDurations.Skewer,
		self._config.AnimationIds.Skewer,
		nil,
		function(state)
			if self:_replaceHeld(player, state, "RightHand", "SkeweredBanana") then
				state.step = "Skewered"
			end
		end
	)
end

function ChocolateBananaService:_dip(player: Player, stallId: string, vat: BasePart)
	local state = self._stateByPlayer[player]
	if not state or state.stallId ~= stallId then
		return
	end

	self:_startBusyAction(
		player,
		"Skewered",
		self._config.ActionDurations.Dip,
		self._config.AnimationIds.Dip,
		vat,
		function(current)
			if self:_replaceHeld(player, current, "RightHand", "DippedBanana") then
				current.step = "Dipped"
			end
		end
	)
end

function ChocolateBananaService:_top(player: Player, stallId: string, container: BasePart)
	local state = self._stateByPlayer[player]
	if not state or state.stallId ~= stallId or state.step ~= "Dipped" or state.busy then
		return
	end

	task.delay(1, function()
		local current = self._stateByPlayer[player]
		if current == state and current.busy and current.step == "Dipped" then
			self:_addToppingEffect(current)
		end
	end)

	self:_startBusyAction(
		player,
		"Dipped",
		self._config.ActionDurations.Topping,
		self._config.AnimationIds.Topping,
		container,
		function(current)
			if self:_replaceHeld(player, current, "RightHand", "FinishedBanana") then
				current.step = "Finished"
			end
		end
	)
end

function ChocolateBananaService:_buy(player: Player, stallId: string)
	local display = self._displayByStall[stallId]
	if not display or not display.instance.Parent or not display.prompt.Enabled then
		return
	end
	local displayRoot = getRoot(display.instance)
	if not displayRoot or not self:_isNear(player, displayRoot) then
		return
	end
	if self._stateByPlayer[player] then
		self:_notify(player, "スタッフは販売中の商品を購入できません。")
		return
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		self:_notify(
			player,
			"購入アイテムを受け取れませんでした。もう一度試してください。"
		)
		return
	end

	display.prompt.Enabled = false
	if not self._moneyService:TrySpend(player, self._config.ProductPrice) then
		display.prompt.Enabled = true
		self:_notify(player, `お金が足りません（{self._config.ProductPrice}円）。`)
		return
	end

	self._assets:CreatePurchasedTool().Parent = backpack
	display.instance:Destroy()
	self._displayByStall[stallId] = nil
	self:_notify(player, `チョコバナナを{self._config.ProductPrice}円で購入しました。`)
end

function ChocolateBananaService:_sell(player: Player, stallId: string)
	local state = self._stateByPlayer[player]
	if not state or state.stallId ~= stallId or state.busy then
		return
	end
	if state.step ~= "Finished" then
		self:_notify(player, "チョコバナナを完成させてください。")
		return
	end
	if self._displayByStall[stallId] then
		self:_notify(player, "販売台の商品が購入されるまで待ってください。")
		return
	end

	local displayPoint = self:_findTaggedPart(self._config.Tags.DisplayPoint, stallId)
	if not displayPoint then
		self:_notify(player, "DisplayPoint が見つかりません。")
		return
	end

	local item = self._assets:Place("FinishedBanana", displayPoint.CFrame, workspace)
	local root = if item then getRoot(item) else nil
	if not item or not root then
		self:_notify(player, "商品を販売台に置けませんでした。")
		return
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ChocolateBananaBuyPrompt"
	prompt.ActionText = self._config.PromptText.Buy
	prompt.ObjectText = `チョコバナナ {self._config.ProductPrice}円`
	prompt.MaxActivationDistance = self._config.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	prompt.Triggered:Connect(function(customer)
		self:_buy(customer, stallId)
	end)

	self._displayByStall[stallId] = {
		instance = item,
		prompt = prompt,
	}
	self:_clearHeld(state)
	state.step = "Empty"
	self:_sendStatus(player)
	self:_notify(player, "チョコバナナを販売台に置きました。")
end

function ChocolateBananaService:_ensurePrompt(
	instance: Instance,
	promptName: string,
	actionText: string
): ProximityPrompt?
	local root = getRoot(instance)
	if not root then
		warn(`{instance:GetFullName()} must be a BasePart or a Model containing a BasePart`)
		return nil
	end

	local existing = root:FindFirstChild(promptName)
	if existing and existing:IsA("ProximityPrompt") then
		return existing
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = promptName
	prompt.ActionText = actionText
	prompt.ObjectText = "チョコバナナ屋台"
	prompt.MaxActivationDistance = self._config.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	return prompt
end

function ChocolateBananaService:_bindJoinBlock(instance: Instance)
	if self._bound[instance] then
		return
	end
	self._bound[instance] = true

	local root = getRoot(instance)
	local stallId = getStallId(instance)
	if not root or not stallId then
		warn(`StaffJoinBlock requires a BasePart and StallId: {instance:GetFullName()}`)
		return
	end

	root.Touched:Connect(function(hit)
		local player = getCharacterPlayer(hit)
		if not player or self._stateByPlayer[player] then
			return
		end

		local now = os.clock()
		if now - (self._touchTimes[player] or 0) < self._config.TouchDebounceSeconds then
			return
		end
		self._touchTimes[player] = now

		if self._staffByStall[stallId] then
			self:_notify(player, "この屋台にはすでにスタッフがいます。")
			return
		end

		self._pendingJoin[player] = {
			stallId = stallId,
			expiresAt = now + self._config.JoinRequestLifetime,
		}
		self._remotes.StaffRequest:FireClient(player, stallId)
	end)
end

function ChocolateBananaService:_bindPromptTag(
	tag: string,
	actionText: string,
	callback: (Player, string, BasePart) -> ()
)
	local function bind(instance: Instance)
		if self._bound[instance] then
			return
		end
		self._bound[instance] = true

		local stallId = getStallId(instance)
		local root = getRoot(instance)
		if not stallId or not root then
			warn(`Tagged interaction requires a BasePart and StallId: {instance:GetFullName()}`)
			return
		end

		local prompt = self:_ensurePrompt(instance, `CB_{tag}`, actionText)
		if prompt then
			prompt.Triggered:Connect(function(player)
				if not self:_isNear(player, root) then
					return
				end
				callback(player, stallId, root)
			end)
		end
	end

	for _, instance in CollectionService:GetTagged(tag) do
		bind(instance)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(bind)
end

function ChocolateBananaService:_handleRemote(player: Player, action: unknown)
	if type(action) ~= "string" then
		return
	end

	if action == "AcceptStaff" then
		local pending = self._pendingJoin[player]
		self._pendingJoin[player] = nil
		if not pending or os.clock() > pending.expiresAt then
			self:_notify(player, "スタッフ確認の有効時間が切れました。")
			return
		end
		self:_join(player, pending.stallId)
	elseif action == "DeclineStaff" then
		self._pendingJoin[player] = nil
	elseif action == "Resign" then
		self:_resign(player, true)
	elseif action == "Skewer" then
		self:_skewer(player)
	end
end

function ChocolateBananaService:Start()
	for _, instance in CollectionService:GetTagged(self._config.Tags.StaffJoinBlock) do
		self:_bindJoinBlock(instance)
	end
	CollectionService:GetInstanceAddedSignal(self._config.Tags.StaffJoinBlock):Connect(function(instance)
		self:_bindJoinBlock(instance)
	end)

	self:_bindPromptTag(self._config.Tags.BananaSource, self._config.PromptText.Banana, function(player, stallId)
		self:_takeBanana(player, stallId)
	end)
	self:_bindPromptTag(self._config.Tags.StickSource, self._config.PromptText.Stick, function(player, stallId)
		self:_takeStick(player, stallId)
	end)
	self:_bindPromptTag(self._config.Tags.ChocolateVat, self._config.PromptText.Dip, function(player, stallId, root)
		self:_dip(player, stallId, root)
	end)
	self:_bindPromptTag(
		self._config.Tags.ToppingContainer,
		self._config.PromptText.Topping,
		function(player, stallId, root)
			self:_top(player, stallId, root)
		end
	)
	self:_bindPromptTag(self._config.Tags.SellBlock, self._config.PromptText.Sell, function(player, stallId)
		self:_sell(player, stallId)
	end)

	self._remotes.Action.OnServerEvent:Connect(function(player, action)
		self:_handleRemote(player, action)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:_resign(player, false)
		self._pendingJoin[player] = nil
		self._touchTimes[player] = nil
	end)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			if self._stateByPlayer[player] then
				self:_resign(player, false)
			end
		end)
	end)

	for _, player in Players:GetPlayers() do
		player.CharacterAdded:Connect(function()
			if self._stateByPlayer[player] then
				self:_resign(player, false)
			end
		end)
		self:_sendStatus(player)
	end
	Players.PlayerAdded:Connect(function(player)
		self:_sendStatus(player)
	end)
end

return ChocolateBananaService
