-- Roblox Studioの「表示 > コマンドバー」へ、このファイル全体を貼り付けて実行してください。
--
-- 実行前:
--   1. Explorerで「銃 → 弾 → 景品10個」の順に、合計12個のアセットを選択します。
--   2. 名前に Gun/銃、Bullet/弾 が含まれる場合は自動判別するため、選択順は問いません。
--   3. GALLERY_ORIGIN を射的を作りたい位置へ変更できます。
--
-- 実行後:
--   - Workspace/ShootingGallerySystem をModelごと移動できます。
--   - TargetPositions内の10個のPartが景品の候補位置です。好きな位置へ移動してください。
--   - PrizeGetLineより下へ落ちた景品が獲得扱いになります。
--   - 景品ごとのToolは ServerStorage/ShootingGalleryAssets/PrizeTools に作成されます。

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Selection = game:GetService("Selection")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local GALLERY_ORIGIN = CFrame.new(0, 0, 0)
local SHOTS_PER_GAME = 8
local DEFAULT_REWARD_YEN = 30

local selected = Selection:Get()
if #selected < 12 then
	error("銃、弾、景品10個の合計12個を選択してから実行してください。")
end

local function lowerName(instance)
	return string.lower(instance.Name)
end

local function nameLooksLikeGun(instance)
	local name = lowerName(instance)
	return string.find(name, "gun", 1, true)
		or string.find(name, "rifle", 1, true)
		or string.find(name, "pistol", 1, true)
		or string.find(instance.Name, "銃", 1, true)
end

local function nameLooksLikeBullet(instance)
	local name = lowerName(instance)
	return string.find(name, "bullet", 1, true)
		or string.find(name, "ammo", 1, true)
		or string.find(instance.Name, "弾", 1, true)
end

local gunSource
local bulletSource
for _, instance in selected do
	if not gunSource and nameLooksLikeGun(instance) then
		gunSource = instance
	elseif not bulletSource and nameLooksLikeBullet(instance) then
		bulletSource = instance
	end
end
gunSource = gunSource or selected[1]
bulletSource = bulletSource or (selected[2] ~= gunSource and selected[2] or selected[3])

local prizeSources = {}
for _, instance in selected do
	if instance ~= gunSource and instance ~= bulletSource and #prizeSources < 10 then
		table.insert(prizeSources, instance)
	end
end
if #prizeSources < 10 then
	error("銃と弾を除いて、景品を10個選択してください。")
end

local function getRoot(instance)
	if instance:IsA("BasePart") then
		return instance
	end
	return instance:FindFirstChildWhichIsA("BasePart", true)
end

local function removeScripts(instance)
	if instance:IsA("LuaSourceContainer") then
		instance:Destroy()
		return
	end
	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("LuaSourceContainer") then
			descendant:Destroy()
		end
	end
end

local function weldToRoot(container, root)
	for _, descendant in container:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.Massless = descendant ~= root
			if descendant ~= root then
				local weld = Instance.new("WeldConstraint")
				weld.Name = "ShootingGalleryWeld"
				weld.Part0 = root
				weld.Part1 = descendant
				weld.Parent = descendant
			end
		end
	end
end

local function makeToolFromAsset(source, toolName)
	local sourceClone = source:Clone()
	removeScripts(sourceClone)

	local tool
	if sourceClone:IsA("Tool") then
		tool = sourceClone
		tool.Name = toolName
	else
		tool = Instance.new("Tool")
		tool.Name = toolName
		sourceClone.Parent = tool
	end

	tool.CanBeDropped = false
	tool.RequiresHandle = true

	local handle = tool:FindFirstChild("Handle")
	if not (handle and handle:IsA("BasePart")) then
		handle = getRoot(tool)
		if handle then
			handle.Name = "Handle"
			handle.Parent = tool
		else
			handle = Instance.new("Part")
			handle.Name = "Handle"
			handle.Size = Vector3.new(0.25, 0.25, 0.25)
			handle.Transparency = 1
			handle.Parent = tool
		end
	end

	handle.Anchored = false
	handle.CanCollide = false
	handle.Massless = false
	weldToRoot(tool, handle)
	return tool
end

local function makeVisualTemplate(source, templateName)
	local clone = source:Clone()
	removeScripts(clone)

	if clone:IsA("Tool") or clone:IsA("Accessory") then
		local model = Instance.new("Model")
		model.Name = templateName
		local parts = {}
		if clone:IsA("BasePart") then
			table.insert(parts, clone)
		end
		for _, descendant in clone:GetDescendants() do
			if descendant:IsA("BasePart") then
				table.insert(parts, descendant)
			end
		end
		for _, part in parts do
			part.Parent = model
		end
		clone:Destroy()
		clone = model
	end

	clone.Name = templateName
	return clone
end

local function backupExisting()
	local backupRoot = ServerStorage:FindFirstChild("CommandBarBackups")
	if not backupRoot then
		backupRoot = Instance.new("Folder")
		backupRoot.Name = "CommandBarBackups"
		backupRoot.Parent = ServerStorage
	end

	local backup = Instance.new("Folder")
	backup.Name = "ShootingGallery_" .. os.date("!%Y%m%d_%H%M%S")
	backup.Parent = backupRoot

	local targets = {
		workspace:FindFirstChild("ShootingGallerySystem"),
		ServerStorage:FindFirstChild("ShootingGalleryAssets"),
		ReplicatedStorage:FindFirstChild("ShootingGallery"),
		ServerScriptService:FindFirstChild("ShootingGalleryServer"),
		StarterPlayer.StarterPlayerScripts:FindFirstChild("ShootingGalleryClient"),
	}
	for _, target in targets do
		if target then
			if target:IsA("BaseScript") then
				target.Disabled = true
			end
			target.Parent = backup
		end
	end

	if #backup:GetChildren() == 0 then
		backup:Destroy()
	end
end

local function makePart(parent, options)
	local part = Instance.new("Part")
	part.Name = options.name
	part.Anchored = true
	part.CanCollide = options.canCollide == true
	part.CanTouch = options.canTouch == true
	part.CanQuery = options.canQuery ~= false
	part.Size = options.size
	part.Color = options.color or Color3.fromRGB(255, 255, 255)
	part.Material = options.material or Enum.Material.SmoothPlastic
	part.Transparency = options.transparency or 0
	part.CFrame = GALLERY_ORIGIN * options.offset
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local SERVER_SOURCE = [==[
--!strict

local Debris = game:GetService("Debris")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local SHOTS_PER_GAME = 8
local DEFAULT_REWARD_YEN = 30
local OFFER_LIFETIME = 12
local FIRE_INTERVAL = 0.22
local MAX_DISTANCE = 220
local BULLET_SPEED = 260

local system = ReplicatedStorage:WaitForChild("ShootingGallery")
local remotes = system:WaitForChild("Remotes")
local offerRemote = remotes:WaitForChild("Offer") :: RemoteEvent
local actionRemote = remotes:WaitForChild("Action") :: RemoteEvent
local stateRemote = remotes:WaitForChild("State") :: RemoteEvent
local notifyRemote = remotes:WaitForChild("Notify") :: RemoteEvent

local assets = ServerStorage:WaitForChild("ShootingGalleryAssets")
local gunTemplate = assets:WaitForChild("Gun") :: Tool
local bulletTemplate = assets:WaitForChild("Bullet")
local prizeTemplates = assets:WaitForChild("Prizes")
local prizeTools = assets:WaitForChild("PrizeTools")

local gallery = workspace:WaitForChild("ShootingGallerySystem")
local startZone = gallery:WaitForChild("StartZone") :: BasePart
local playerAnchor = gallery:WaitForChild("PlayerAnchor") :: BasePart
local exitPoint = gallery:WaitForChild("ExitPoint") :: BasePart
local getLine = gallery:WaitForChild("PrizeGetLine") :: BasePart
local positionFolder = gallery:WaitForChild("TargetPositions")
local activeFolder = gallery:WaitForChild("ActivePrizes")
local bulletFolder = gallery:WaitForChild("ActiveBullets")

local GROUP_PLAYER = "ShootingGalleryPlayer"
local GROUP_PRIZE = "ShootingGalleryPrize"
local GROUP_BULLET = "ShootingGalleryBullet"

for _, groupName in { GROUP_PLAYER, GROUP_PRIZE, GROUP_BULLET } do
	pcall(function()
		PhysicsService:RegisterCollisionGroup(groupName)
	end)
end
for _, groupInfo in PhysicsService:GetRegisteredCollisionGroups() do
	PhysicsService:CollisionGroupSetCollidable(
		GROUP_PRIZE,
		groupInfo.name,
		groupInfo.name == GROUP_BULLET
	)
end
PhysicsService:CollisionGroupSetCollidable(GROUP_BULLET, GROUP_PLAYER, false)

type Session = {
	ammo: number,
	claimed: number,
	lastShot: number,
	ending: boolean,
	original: {
		walkSpeed: number,
		jumpPower: number,
		jumpHeight: number,
		autoRotate: boolean,
		rootAnchored: boolean,
	},
}

type PrizeState = {
	instance: Instance,
	root: BasePart,
	owner: Player,
	prizeId: string,
	displayName: string,
	reward: number,
	hit: boolean,
	claimed: boolean,
}

local activePlayer: Player? = nil
local sessions: { [Player]: Session } = {}
local pending: { [Player]: number } = {}
local touchTimes: { [Player]: number } = {}
local prizes: { [Instance]: PrizeState } = {}

local function notify(player: Player, message: string)
	notifyRemote:FireClient(player, message)
end

local function getCharacterPlayer(hit: BasePart): Player?
	local character = hit:FindFirstAncestorOfClass("Model")
	return if character then Players:GetPlayerFromCharacter(character) else nil
end

local function getRoot(instance: Instance): BasePart?
	if instance:IsA("BasePart") then
		return instance
	end
	if instance:IsA("Model") then
		return instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true)
	end
	return instance:FindFirstChildWhichIsA("BasePart", true)
end

local function pivot(instance: Instance, target: CFrame)
	if instance:IsA("Model") then
		instance:PivotTo(target)
	elseif instance:IsA("BasePart") then
		instance.CFrame = target
	else
		local root = getRoot(instance)
		if root then
			root.CFrame = target
		end
	end
end

local function setCharacterCollisionGroup(character: Model)
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = GROUP_PLAYER
		end
	end
	character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = GROUP_PLAYER
		end
	end)
end

local function state(player: Player)
	local session = sessions[player]
	stateRemote:FireClient(player, {
		active = session ~= nil,
		ammo = if session then session.ammo else 0,
		claimed = if session then session.claimed else 0,
	})
end

local function clearActiveObjects()
	for _, child in activeFolder:GetChildren() do
		child:Destroy()
	end
	for _, child in bulletFolder:GetChildren() do
		child:Destroy()
	end
	table.clear(prizes)
end

local function removeGalleryGuns(player: Player)
	local containers = { player:FindFirstChildOfClass("Backpack"), player.Character }
	for _, container in containers do
		if container then
			for _, child in container:GetChildren() do
				if child:IsA("Tool") and child:GetAttribute("ShootingGalleryGun") == true then
					child:Destroy()
				end
			end
		end
	end
end

local function finishGame(player: Player, message: string?)
	local session = sessions[player]
	if not session then
		return
	end
	sessions[player] = nil
	if activePlayer == player then
		activePlayer = nil
	end

	removeGalleryGuns(player)
	clearActiveObjects()

	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if humanoid then
		humanoid.WalkSpeed = session.original.walkSpeed
		humanoid.JumpPower = session.original.jumpPower
		humanoid.JumpHeight = session.original.jumpHeight
		humanoid.AutoRotate = session.original.autoRotate
	end
	if root and root:IsA("BasePart") then
		root.Anchored = session.original.rootAnchored
		root.CFrame = exitPoint.CFrame
	end

	state(player)
	if message then
		notify(player, message)
	end
end

local function weldPrize(instance: Instance, root: BasePart)
	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = GROUP_PRIZE
			descendant.CanCollide = true
			descendant.CanTouch = false
			descendant.CanQuery = true
			descendant.Anchored = true
			descendant.Massless = descendant ~= root
			if descendant ~= root then
				local weld = Instance.new("WeldConstraint")
				weld.Name = "ShootingGalleryPrizeWeld"
				weld.Part0 = root
				weld.Part1 = descendant
				weld.Parent = descendant
			end
		end
	end
	if instance:IsA("BasePart") then
		instance.CollisionGroup = GROUP_PRIZE
		instance.CanCollide = true
		instance.CanTouch = false
		instance.CanQuery = true
		instance.Anchored = true
	end
end

local function shuffledChildren(folder: Instance): { Instance }
	local result = folder:GetChildren()
	for index = #result, 2, -1 do
		local other = math.random(1, index)
		result[index], result[other] = result[other], result[index]
	end
	return result
end

local function spawnPrizes(player: Player)
	clearActiveObjects()
	local templates = shuffledChildren(prizeTemplates)
	local positions = shuffledChildren(positionFolder)
	local count = math.min(10, #templates, #positions)

	for index = 1, count do
		local position = positions[index]
		if not position:IsA("BasePart") then
			continue
		end

		local template = templates[index]
		local clone = template:Clone()
		local root = getRoot(clone)
		if not root then
			clone:Destroy()
			continue
		end

		local prizeId = template:GetAttribute("PrizeId")
		if type(prizeId) ~= "string" then
			prizeId = template.Name
		end
		local displayName = template:GetAttribute("DisplayName")
		if type(displayName) ~= "string" then
			displayName = template.Name
		end
		local reward = template:GetAttribute("RewardYen")
		if type(reward) ~= "number" then
			reward = DEFAULT_REWARD_YEN
		end

		clone.Name = "Target_" .. prizeId
		clone:SetAttribute("ShootingPrizeId", prizeId)
		clone:SetAttribute("ShootingGalleryOwner", player.UserId)
		clone.Parent = activeFolder
		weldPrize(clone, root)
		pivot(clone, position.CFrame)

		prizes[clone] = {
			instance = clone,
			root = root,
			owner = player,
			prizeId = prizeId,
			displayName = displayName,
			reward = math.max(0, math.floor(reward)),
			hit = false,
			claimed = false,
		}
	end
end

local function startGame(player: Player)
	if activePlayer and activePlayer ~= player then
		notify(player, "ただいま射的はプレイ中です。少し待ってください。")
		return
	end
	if sessions[player] then
		return
	end

	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not character or not humanoid or not root or not root:IsA("BasePart") then
		notify(player, "キャラクターを読み込んでから、もう一度試してください。")
		return
	end

	activePlayer = player
	sessions[player] = {
		ammo = SHOTS_PER_GAME,
		claimed = 0,
		lastShot = 0,
		ending = false,
		original = {
			walkSpeed = humanoid.WalkSpeed,
			jumpPower = humanoid.JumpPower,
			jumpHeight = humanoid.JumpHeight,
			autoRotate = humanoid.AutoRotate,
			rootAnchored = root.Anchored,
		},
	}

	root.CFrame = playerAnchor.CFrame
	root.Anchored = true
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid.AutoRotate = false

	spawnPrizes(player)
	removeGalleryGuns(player)
	local gun = gunTemplate:Clone()
	gun.Name = "射的の銃"
	gun:SetAttribute("ShootingGalleryGun", true)
	gun.Parent = player:WaitForChild("Backpack")
	humanoid:EquipTool(gun)

	state(player)
	notify(player, "射的スタート！ 弾は8発です。")
end

local function getPrizeFromHit(hit: Instance): PrizeState?
	local current: Instance? = hit
	while current and current ~= activeFolder do
		local found = prizes[current]
		if found then
			return found
		end
		current = current.Parent
	end
	return nil
end

local function dropPrize(prize: PrizeState, direction: Vector3)
	if prize.hit or prize.claimed then
		return
	end
	prize.hit = true

	for _, descendant in prize.instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
		end
	end
	if prize.instance:IsA("BasePart") then
		prize.instance.Anchored = false
	end
	pcall(function()
		prize.root:SetNetworkOwner(nil)
	end)

	local horizontal = Vector3.new(direction.X, -0.12, direction.Z)
	if horizontal.Magnitude < 0.01 then
		horizontal = Vector3.new(0, -0.12, -1)
	end
	local impulse = (horizontal.Unit * 15 + Vector3.new(0, -3, 0)) * prize.root.AssemblyMass
	prize.root:ApplyImpulse(impulse)
	prize.root:ApplyAngularImpulse(Vector3.new(2, 4, 2) * prize.root.AssemblyMass)
end

local function prepareBulletVisual(instance: Instance)
	local function prepare(part: BasePart)
		part.Anchored = true
		part.CanCollide = true
		part.CanTouch = false
		part.CanQuery = false
		part.CollisionGroup = GROUP_BULLET
	end
	if instance:IsA("BasePart") then
		prepare(instance)
	end
	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			prepare(descendant)
		end
	end
end

local function animateBullet(origin: Vector3, finish: Vector3)
	local visual = bulletTemplate:Clone()
	local root = getRoot(visual)
	if not root then
		visual:Destroy()
		return
	end
	visual.Name = "ShootingBullet"
	visual.Parent = bulletFolder
	prepareBulletVisual(visual)

	local direction = finish - origin
	local distance = direction.Magnitude
	local startCFrame = CFrame.lookAt(origin, finish)
	local endCFrame = CFrame.lookAt(finish, finish + direction.Unit)
	pivot(visual, startCFrame)

	task.spawn(function()
		local duration = math.clamp(distance / BULLET_SPEED, 0.03, 0.45)
		local started = os.clock()
		while visual.Parent do
			local alpha = math.clamp((os.clock() - started) / duration, 0, 1)
			pivot(visual, startCFrame:Lerp(endCFrame, alpha))
			if alpha >= 1 then
				break
			end
			RunService.Heartbeat:Wait()
		end
		if visual.Parent then
			visual:Destroy()
		end
	end)
end

local function shoot(player: Player, target: unknown)
	local session = sessions[player]
	if not session or activePlayer ~= player or session.ammo <= 0 or typeof(target) ~= "Vector3" then
		return
	end
	if os.clock() - session.lastShot < FIRE_INTERVAL then
		return
	end
	session.lastShot = os.clock()

	local character = player.Character
	local gun = if character then character:FindFirstChild("射的の銃") else nil
	local handle = if gun and gun:IsA("Tool") then gun:FindFirstChild("Handle") else nil
	local head = if character then character:FindFirstChild("Head") else nil
	local originPart = if handle and handle:IsA("BasePart") then handle elseif head and head:IsA("BasePart") then head else nil
	if not originPart then
		return
	end

	local origin = originPart.Position
	local requestedDirection = (target :: Vector3) - origin
	if requestedDirection.Magnitude < 1 then
		return
	end
	local direction = requestedDirection.Unit * MAX_DISTANCE
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character :: Model, bulletFolder }
	params.IgnoreWater = true
	params.CollisionGroup = GROUP_BULLET

	local result = workspace:Raycast(origin, direction, params)
	local finish = if result then result.Position else origin + direction
	animateBullet(origin, finish)

	if result then
		local prize = getPrizeFromHit(result.Instance)
		if prize and prize.owner == player then
			dropPrize(prize, direction)
		end
	end

	session.ammo -= 1
	state(player)
	if session.ammo <= 0 and not session.ending then
		session.ending = true
		task.delay(5, function()
			if sessions[player] == session then
				finishGame(player, `終了！ 景品は{session.claimed}個です。`)
			end
		end)
	end
end

local function awardPrize(prize: PrizeState)
	if prize.claimed then
		return
	end
	prize.claimed = true
	local player = prize.owner
	local session = sessions[player]
	if not session then
		prize.instance:Destroy()
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local yen = if leaderstats then leaderstats:FindFirstChild("Yen") else nil
	if yen and yen:IsA("IntValue") and prize.reward > 0 then
		yen.Value += prize.reward
	end

	local toolTemplate = prizeTools:FindFirstChild(prize.prizeId)
	if toolTemplate and toolTemplate:IsA("Tool") then
		local tool = toolTemplate:Clone()
		tool.CanBeDropped = true
		tool.Parent = player:WaitForChild("Backpack")
	end

	session.claimed += 1
	state(player)
	notify(player, `{prize.displayName}をゲット！ +{prize.reward}円`)
	prizes[prize.instance] = nil
	prize.instance:Destroy()
end

RunService.Heartbeat:Connect(function()
	for instance, prize in prizes do
		if not instance.Parent then
			prizes[instance] = nil
		elseif prize.hit and not prize.claimed and prize.root.Position.Y <= getLine.Position.Y then
			awardPrize(prize)
		end
	end
end)

startZone.Touched:Connect(function(hit)
	local player = getCharacterPlayer(hit)
	if not player or sessions[player] then
		return
	end
	local now = os.clock()
	if now - (touchTimes[player] or 0) < 3 then
		return
	end
	touchTimes[player] = now
	pending[player] = now + OFFER_LIFETIME
	offerRemote:FireClient(player)
end)

actionRemote.OnServerEvent:Connect(function(player, action, payload)
	if action == "Accept" then
		local expiresAt = pending[player]
		pending[player] = nil
		if not expiresAt or os.clock() > expiresAt then
			notify(player, "確認の有効時間が切れました。開始場所へもう一度立ってください。")
			return
		end
		startGame(player)
	elseif action == "Decline" then
		pending[player] = nil
	elseif action == "Shoot" then
		shoot(player, payload)
	elseif action == "Quit" then
		finishGame(player, "射的を終了しました。")
	end
end)

local function onPlayer(player: Player)
	if player.Character then
		setCharacterCollisionGroup(player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		setCharacterCollisionGroup(character)
		if sessions[player] then
			finishGame(player)
		end
	end)
	state(player)
end

Players.PlayerAdded:Connect(onPlayer)
Players.PlayerRemoving:Connect(function(player)
	if sessions[player] then
		finishGame(player)
	end
	pending[player] = nil
	touchTimes[player] = nil
end)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayer, player)
end
]==]

local CLIENT_SOURCE = [==[
--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local system = ReplicatedStorage:WaitForChild("ShootingGallery")
local remotes = system:WaitForChild("Remotes")
local offerRemote = remotes:WaitForChild("Offer") :: RemoteEvent
local actionRemote = remotes:WaitForChild("Action") :: RemoteEvent
local stateRemote = remotes:WaitForChild("State") :: RemoteEvent
local notifyRemote = remotes:WaitForChild("Notify") :: RemoteEvent

local COLORS = {
	dark = Color3.fromRGB(39, 32, 26),
	cream = Color3.fromRGB(255, 245, 218),
	red = Color3.fromRGB(210, 67, 61),
	green = Color3.fromRGB(50, 156, 91),
	orange = Color3.fromRGB(229, 130, 46),
	brown = Color3.fromRGB(104, 62, 37),
}

local function corner(parent: Instance, radius: number)
	local value = Instance.new("UICorner")
	value.CornerRadius = UDim.new(0, radius)
	value.Parent = parent
end

local function stroke(parent: Instance, color: Color3, thickness: number)
	local value = Instance.new("UIStroke")
	value.Color = color
	value.Thickness = thickness
	value.Parent = parent
end

local function label(parent: Instance, text: string, size: UDim2, position: UDim2): TextLabel
	local value = Instance.new("TextLabel")
	value.BackgroundTransparency = 1
	value.Size = size
	value.Position = position
	value.Font = Enum.Font.GothamBold
	value.Text = text
	value.TextColor3 = COLORS.dark
	value.TextScaled = true
	value.TextWrapped = true
	value.Parent = parent
	return value
end

local function button(parent: Instance, text: string, size: UDim2, position: UDim2, color: Color3): TextButton
	local value = Instance.new("TextButton")
	value.BackgroundColor3 = color
	value.Size = size
	value.Position = position
	value.Font = Enum.Font.GothamBold
	value.Text = text
	value.TextColor3 = Color3.new(1, 1, 1)
	value.TextScaled = true
	value.Parent = parent
	corner(value, 12)
	stroke(value, COLORS.brown, 2)
	return value
end

local gui = Instance.new("ScreenGui")
gui.Name = "ShootingGalleryUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local shade = Instance.new("Frame")
shade.Name = "OfferShade"
shade.Size = UDim2.fromScale(1, 1)
shade.BackgroundColor3 = Color3.new(0, 0, 0)
shade.BackgroundTransparency = 0.45
shade.Visible = false
shade.ZIndex = 20
shade.Parent = gui

local modal = Instance.new("Frame")
modal.AnchorPoint = Vector2.new(0.5, 0.5)
modal.Position = UDim2.fromScale(0.5, 0.5)
modal.Size = UDim2.fromOffset(460, 250)
modal.BackgroundColor3 = COLORS.cream
modal.ZIndex = 21
modal.Parent = shade
corner(modal, 18)
stroke(modal, COLORS.brown, 4)

local title = label(modal, "🎯 射的", UDim2.new(1, -36, 0, 52), UDim2.fromOffset(18, 16))
title.ZIndex = 22
local description = label(
	modal,
	"射的を始めますか？\n弾は8発。景品を落とすと景品Toolと30円がもらえます。",
	UDim2.new(1, -48, 0, 94),
	UDim2.fromOffset(24, 74)
)
description.ZIndex = 22
local accept = button(modal, "始める", UDim2.fromOffset(184, 50), UDim2.fromOffset(28, 182), COLORS.green)
accept.ZIndex = 22
local decline = button(modal, "やめておく", UDim2.fromOffset(184, 50), UDim2.new(1, -212, 0, 182), COLORS.red)
decline.ZIndex = 22

local hud = Instance.new("Frame")
hud.Name = "GameHud"
hud.AnchorPoint = Vector2.new(0.5, 0)
hud.Position = UDim2.new(0.5, 0, 0, 18)
hud.Size = UDim2.fromOffset(430, 78)
hud.BackgroundColor3 = COLORS.cream
hud.Visible = false
hud.Parent = gui
corner(hud, 16)
stroke(hud, COLORS.brown, 3)

local ammoLabel = label(hud, "残り 8発", UDim2.fromOffset(160, 52), UDim2.fromOffset(16, 13))
local prizeLabel = label(hud, "景品 0個", UDim2.fromOffset(130, 52), UDim2.fromOffset(164, 13))
local quit = button(hud, "終了", UDim2.fromOffset(106, 48), UDim2.new(1, -120, 0, 15), COLORS.red)

local shootButton = button(
	gui,
	"撃つ",
	UDim2.fromOffset(120, 120),
	UDim2.new(1, -150, 1, -150),
	COLORS.orange
)
shootButton.AnchorPoint = Vector2.new(0.5, 0.5)
shootButton.Visible = false

local crosshair = label(gui, "＋", UDim2.fromOffset(42, 42), UDim2.new(0.5, -21, 0.5, -21))
crosshair.TextColor3 = Color3.fromRGB(255, 80, 70)
crosshair.Visible = false

local toast = label(gui, "", UDim2.fromOffset(500, 60), UDim2.new(0.5, -250, 0, 108))
toast.BackgroundTransparency = 0.08
toast.BackgroundColor3 = COLORS.dark
toast.TextColor3 = Color3.new(1, 1, 1)
toast.Visible = false
corner(toast, 14)

local active = false
local toastVersion = 0
local originalCameraMode = player.CameraMode
local boundTools: { [Tool]: boolean } = {}

local function showToast(message: string)
	toastVersion += 1
	local version = toastVersion
	toast.Text = message
	toast.Visible = true
	task.delay(3, function()
		if toastVersion == version then
			toast.Visible = false
		end
	end)
end

local function shoot()
	if not active then
		return
	end
	actionRemote:FireServer("Shoot", mouse.Hit.Position)
end

local function bindTool(instance: Instance)
	if not instance:IsA("Tool") or instance:GetAttribute("ShootingGalleryGun") ~= true or boundTools[instance] then
		return
	end
	boundTools[instance] = true
	instance.Activated:Connect(shoot)
	instance.Destroying:Connect(function()
		boundTools[instance] = nil
	end)
end

local function watchContainer(container: Instance)
	for _, child in container:GetChildren() do
		bindTool(child)
	end
	container.ChildAdded:Connect(bindTool)
end

watchContainer(player:WaitForChild("Backpack"))
if player.Character then
	watchContainer(player.Character)
end
player.CharacterAdded:Connect(watchContainer)

offerRemote.OnClientEvent:Connect(function()
	if not active then
		shade.Visible = true
	end
end)

stateRemote.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	local wasActive = active
	active = payload.active == true
	local ammo = if type(payload.ammo) == "number" then payload.ammo else 0
	local claimed = if type(payload.claimed) == "number" then payload.claimed else 0
	ammoLabel.Text = `残り {ammo}発`
	prizeLabel.Text = `景品 {claimed}個`
	hud.Visible = active
	shootButton.Visible = active
	crosshair.Visible = active

	if active and not wasActive then
		originalCameraMode = player.CameraMode
		player.CameraMode = Enum.CameraMode.LockFirstPerson
	elseif not active and wasActive then
		player.CameraMode = originalCameraMode
	end
end)

notifyRemote.OnClientEvent:Connect(function(message)
	if type(message) == "string" then
		showToast(message)
	end
end)

accept.Activated:Connect(function()
	shade.Visible = false
	actionRemote:FireServer("Accept")
end)
decline.Activated:Connect(function()
	shade.Visible = false
	actionRemote:FireServer("Decline")
end)
quit.Activated:Connect(function()
	actionRemote:FireServer("Quit")
end)
shootButton.Activated:Connect(shoot)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not active or UserInputService:GetFocusedTextBox() then
		return
	end
	if input.KeyCode == Enum.KeyCode.Space then
		shoot()
	end
end)
]==]

local recording
pcall(function()
	recording = ChangeHistoryService:TryBeginRecording("Create shooting gallery")
end)

local ok, result = xpcall(function()
	backupExisting()

	for _, groupName in { "ShootingGalleryPlayer", "ShootingGalleryPrize", "ShootingGalleryBullet" } do
		pcall(function()
			PhysicsService:RegisterCollisionGroup(groupName)
		end)
	end
	for _, groupInfo in PhysicsService:GetRegisteredCollisionGroups() do
		PhysicsService:CollisionGroupSetCollidable(
			"ShootingGalleryPrize",
			groupInfo.name,
			groupInfo.name == "ShootingGalleryBullet"
		)
	end

	local assets = Instance.new("Folder")
	assets.Name = "ShootingGalleryAssets"
	assets.Parent = ServerStorage

	local gun = makeToolFromAsset(gunSource, "Gun")
	gun.ToolTip = "射的用 / 8発"
	gun:SetAttribute("ShootingGalleryGun", true)
	gun.Parent = assets

	local bullet = makeVisualTemplate(bulletSource, "Bullet")
	bullet.Parent = assets

	local prizesFolder = Instance.new("Folder")
	prizesFolder.Name = "Prizes"
	prizesFolder.Parent = assets

	local toolsFolder = Instance.new("Folder")
	toolsFolder.Name = "PrizeTools"
	toolsFolder.Parent = assets

	for index, source in prizeSources do
		local prizeId = string.format("Prize%02d", index)
		local visual = makeVisualTemplate(source, prizeId)
		visual:SetAttribute("PrizeId", prizeId)
		visual:SetAttribute("DisplayName", source.Name)
		visual:SetAttribute("RewardYen", DEFAULT_REWARD_YEN)
		visual.Parent = prizesFolder

		local tool = makeToolFromAsset(source, prizeId)
		tool.Name = prizeId
		tool.ToolTip = "射的の景品: " .. source.Name
		tool:SetAttribute("DisplayName", source.Name)
		tool.Parent = toolsFolder
	end

	local replicated = Instance.new("Folder")
	replicated.Name = "ShootingGallery"
	replicated:SetAttribute("ShotsPerGame", SHOTS_PER_GAME)
	replicated:SetAttribute("DefaultRewardYen", DEFAULT_REWARD_YEN)
	replicated.Parent = ReplicatedStorage

	local remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = replicated
	for _, name in { "Offer", "Action", "State", "Notify" } do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remotes
	end

	local gallery = Instance.new("Model")
	gallery.Name = "ShootingGallerySystem"
	gallery.Parent = workspace

	local floor = makePart(gallery, {
		name = "BoothFloor",
		size = Vector3.new(22, 0.5, 32),
		color = Color3.fromRGB(112, 73, 44),
		material = Enum.Material.WoodPlanks,
		offset = CFrame.new(0, 0.25, -5),
		canCollide = true,
		canTouch = false,
	})
	gallery.PrimaryPart = floor

	makePart(gallery, {
		name = "BackWall",
		size = Vector3.new(22, 12, 0.6),
		color = Color3.fromRGB(205, 68, 58),
		material = Enum.Material.WoodPlanks,
		offset = CFrame.new(0, 6, -20),
		canCollide = true,
		canTouch = false,
	})

	local startZone = makePart(gallery, {
		name = "StartZone",
		size = Vector3.new(6, 0.35, 4),
		color = Color3.fromRGB(255, 208, 67),
		material = Enum.Material.Neon,
		offset = CFrame.new(0, 0.42, 9),
		canCollide = false,
		canTouch = true,
	})

	local zoneGui = Instance.new("BillboardGui")
	zoneGui.Name = "StartLabel"
	zoneGui.Size = UDim2.fromOffset(260, 64)
	zoneGui.StudsOffset = Vector3.new(0, 2.4, 0)
	zoneGui.AlwaysOnTop = true
	zoneGui.Parent = startZone
	local zoneText = Instance.new("TextLabel")
	zoneText.Size = UDim2.fromScale(1, 1)
	zoneText.BackgroundColor3 = Color3.fromRGB(255, 245, 210)
	zoneText.BackgroundTransparency = 0.1
	zoneText.Text = "ここに立って射的を開始"
	zoneText.TextColor3 = Color3.fromRGB(76, 45, 29)
	zoneText.TextScaled = true
	zoneText.Font = Enum.Font.GothamBold
	zoneText.Parent = zoneGui

	makePart(gallery, {
		name = "PlayerAnchor",
		size = Vector3.new(1, 1, 1),
		color = Color3.fromRGB(70, 200, 255),
		offset = CFrame.new(0, 3, 5),
		transparency = 1,
		canCollide = false,
		canTouch = false,
		canQuery = false,
	})
	makePart(gallery, {
		name = "ExitPoint",
		size = Vector3.new(1, 1, 1),
		color = Color3.fromRGB(70, 255, 150),
		offset = CFrame.new(8, 3, 8),
		transparency = 1,
		canCollide = false,
		canTouch = false,
		canQuery = false,
	})

	makePart(gallery, {
		name = "PrizeGetLine",
		size = Vector3.new(20, 0.2, 3),
		color = Color3.fromRGB(80, 255, 130),
		material = Enum.Material.Neon,
		offset = CFrame.new(0, 0.6, -17),
		transparency = 0.65,
		canCollide = false,
		canTouch = false,
		canQuery = false,
	})

	local positions = Instance.new("Folder")
	positions.Name = "TargetPositions"
	positions.Parent = gallery
	local positionIndex = 0
	for row, y in { 7.3, 4.3 } do
		for column, x in { -8, -4, 0, 4, 8 } do
			positionIndex += 1
			makePart(positions, {
				name = string.format("Target%02d", positionIndex),
				size = Vector3.new(0.65, 0.65, 0.65),
				color = if row == 1 then Color3.fromRGB(90, 210, 255) else Color3.fromRGB(255, 135, 210),
				material = Enum.Material.Neon,
				offset = CFrame.new(x, y, -18),
				transparency = 0.72,
				canCollide = false,
				canTouch = false,
				canQuery = false,
			})
		end
	end

	local activePrizes = Instance.new("Folder")
	activePrizes.Name = "ActivePrizes"
	activePrizes.Parent = gallery
	local activeBullets = Instance.new("Folder")
	activeBullets.Name = "ActiveBullets"
	activeBullets.Parent = gallery

	local server = Instance.new("Script")
	server.Name = "ShootingGalleryServer"
	server.Source = SERVER_SOURCE
	server.Parent = ServerScriptService

	local client = Instance.new("LocalScript")
	client.Name = "ShootingGalleryClient"
	client.Source = CLIENT_SOURCE
	client.Parent = StarterPlayer.StarterPlayerScripts

	Selection:Set({ gallery })
	print("射的システムを作成しました。")
	print("景品位置: Workspace > ShootingGallerySystem > TargetPositions")
	print("獲得ライン: Workspace > ShootingGallerySystem > PrizeGetLine")
	print("景品Tool: ServerStorage > ShootingGalleryAssets > PrizeTools")
	print("弾数: 8発 / 景品報酬: 30円")
	return gallery
end, debug.traceback)

if recording then
	pcall(function()
		ChangeHistoryService:FinishRecording(
			recording,
			if ok then Enum.FinishRecordingOperation.Commit else Enum.FinishRecordingOperation.Cancel
		)
	end)
else
	pcall(function()
		ChangeHistoryService:SetWaypoint("Create shooting gallery")
	end)
end

if not ok then
	error(result)
end
