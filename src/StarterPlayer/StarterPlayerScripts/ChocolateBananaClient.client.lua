--!strict

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local packageFolder = ReplicatedStorage:WaitForChild("ChocolateBanana")
local Config = require(packageFolder:WaitForChild("Config"))
local remotes = packageFolder:WaitForChild("Remotes")
local staffRequest = remotes:WaitForChild("StaffRequest") :: RemoteEvent
local staffStatus = remotes:WaitForChild("StaffStatus") :: RemoteEvent
local notifyRemote = remotes:WaitForChild("Notify") :: RemoteEvent
local actionRemote = remotes:WaitForChild("Action") :: RemoteEvent

local COLORS = {
	brown = Color3.fromRGB(88, 48, 28),
	chocolate = Color3.fromRGB(122, 66, 38),
	cream = Color3.fromRGB(255, 243, 214),
	yellow = Color3.fromRGB(255, 211, 66),
	red = Color3.fromRGB(220, 73, 63),
	green = Color3.fromRGB(58, 157, 95),
	dark = Color3.fromRGB(45, 31, 23),
}

local STEP_TEXT = {
	Empty = "① バナナを取る",
	Banana = "② 棒を取る",
	Ingredients = "③ 「バナナを刺す」を押す",
	Skewered = "④ チョコの筒に漬ける",
	Dipped = "⑤ トッピング容器を選ぶ",
	Finished = "⑥ 販売ブロックを選ぶ",
}

local ACTION_DURATION_BY_STEP = {
	Ingredients = Config.ActionDurations.Skewer,
	Skewered = Config.ActionDurations.Dip,
	Dipped = Config.ActionDurations.Topping,
}

local DISPLAY_ASSET_BY_STEP = {
	Ingredients = "PeeledBanana",
	Skewered = "SkeweredBanana",
	Dipped = "DippedBanana",
}

local ACTION_COLOR_BY_STEP = {
	Ingredients = COLORS.green,
	Skewered = COLORS.chocolate,
	Dipped = COLORS.yellow,
}

local COMPLETE_TEXT_BY_STEP = {
	Skewered = "串刺しできました！",
	Dipped = "チョコがきれいにつきました！",
	Finished = "チョコバナナ完成！",
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

local function makeLabel(parent: Instance, text: string, size: UDim2, position: UDim2): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = COLORS.dark
	label.TextScaled = true
	label.Parent = parent
	return label
end

local function makeButton(parent: Instance, text: string, size: UDim2, position: UDim2, color: Color3): TextButton
	local button = Instance.new("TextButton")
	button.AutoButtonColor = true
	button.BackgroundColor3 = color
	button.BackgroundTransparency = 0.12
	button.Size = size
	button.Position = position
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextScaled = true
	button.Parent = parent
	corner(button, 10)
	stroke(button, COLORS.brown, 2)
	return button
end

local gui = Instance.new("ScreenGui")
gui.Name = "ChocolateBananaUI"
gui.IgnoreGuiInset = false
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local moneyFrame = Instance.new("Frame")
moneyFrame.Name = "Money"
moneyFrame.AnchorPoint = Vector2.new(1, 0)
moneyFrame.Position = UDim2.new(1, -18, 0, 16)
moneyFrame.Size = UDim2.fromOffset(180, 52)
moneyFrame.BackgroundColor3 = COLORS.cream
moneyFrame.BackgroundTransparency = 0.14
moneyFrame.Parent = gui
corner(moneyFrame, 14)
stroke(moneyFrame, COLORS.brown, 3)

local moneyLabel = makeLabel(moneyFrame, "💰 100円", UDim2.new(1, -20, 1, -12), UDim2.fromOffset(10, 6))
moneyLabel.TextXAlignment = Enum.TextXAlignment.Right

local staffFrame = Instance.new("Frame")
staffFrame.Name = "StaffPanel"
staffFrame.AnchorPoint = Vector2.new(0.5, 1)
staffFrame.Position = UDim2.new(0.5, 0, 1, -24)
staffFrame.Size = UDim2.fromOffset(520, 154)
staffFrame.BackgroundColor3 = COLORS.cream
staffFrame.BackgroundTransparency = 0.14
staffFrame.Visible = false
staffFrame.Parent = gui
corner(staffFrame, 16)
stroke(staffFrame, COLORS.brown, 3)

local staffScale = Instance.new("UIScale")
staffScale.Scale = 1
staffScale.Parent = staffFrame

local staffTitle = makeLabel(
	staffFrame,
	"🍌 チョコバナナ屋台スタッフ",
	UDim2.new(1, -150, 0, 34),
	UDim2.fromOffset(14, 8)
)
staffTitle.TextXAlignment = Enum.TextXAlignment.Left

local resignButton = makeButton(staffFrame, "辞任", UDim2.fromOffset(112, 36), UDim2.new(1, -126, 0, 8), COLORS.red)
local stepLabel = makeLabel(staffFrame, "", UDim2.new(1, -28, 0, 34), UDim2.fromOffset(14, 48))
stepLabel.TextXAlignment = Enum.TextXAlignment.Left

local progressTrack = Instance.new("Frame")
progressTrack.Name = "ActionProgressTrack"
progressTrack.Position = UDim2.fromOffset(14, 86)
progressTrack.Size = UDim2.new(1, -28, 0, 7)
progressTrack.BackgroundColor3 = Color3.fromRGB(218, 198, 166)
progressTrack.BackgroundTransparency = 0.18
progressTrack.BorderSizePixel = 0
progressTrack.Visible = false
progressTrack.Parent = staffFrame
corner(progressTrack, 4)

local progressFill = Instance.new("Frame")
progressFill.Name = "Fill"
progressFill.Size = UDim2.fromScale(0, 1)
progressFill.BackgroundColor3 = COLORS.green
progressFill.BackgroundTransparency = 0.08
progressFill.BorderSizePixel = 0
progressFill.Parent = progressTrack
corner(progressFill, 4)

local actionButton =
	makeButton(staffFrame, "バナナを刺す", UDim2.fromOffset(190, 44), UDim2.new(0.5, -95, 1, -56), COLORS.green)
actionButton.Visible = false

local rotateLeft =
	makeButton(staffFrame, "↶ 左回転", UDim2.fromOffset(126, 42), UDim2.fromOffset(14, 98), COLORS.chocolate)
local rotateRight =
	makeButton(staffFrame, "右回転 ↷", UDim2.fromOffset(126, 42), UDim2.new(1, -140, 0, 98), COLORS.chocolate)

local modalShade = Instance.new("Frame")
modalShade.Name = "StaffQuestionShade"
modalShade.BackgroundColor3 = Color3.new(0, 0, 0)
modalShade.BackgroundTransparency = 0.45
modalShade.Size = UDim2.fromScale(1, 1)
modalShade.Visible = false
modalShade.ZIndex = 10
modalShade.Parent = gui

local modal = Instance.new("Frame")
modal.AnchorPoint = Vector2.new(0.5, 0.5)
modal.Position = UDim2.fromScale(0.5, 0.5)
modal.Size = UDim2.fromOffset(430, 230)
modal.BackgroundColor3 = COLORS.cream
modal.BackgroundTransparency = 0.12
modal.ZIndex = 11
modal.Parent = modalShade
corner(modal, 18)
stroke(modal, COLORS.brown, 4)

local modalTitle = makeLabel(modal, "屋台スタッフ", UDim2.new(1, -32, 0, 48), UDim2.fromOffset(16, 18))
modalTitle.ZIndex = 12
local modalText = makeLabel(
	modal,
	"チョコバナナ屋台のスタッフになりますか？\n1つの屋台につき1人までです。",
	UDim2.new(1, -40, 0, 76),
	UDim2.fromOffset(20, 72)
)
modalText.TextWrapped = true
modalText.ZIndex = 12

local acceptButton =
	makeButton(modal, "スタッフになる", UDim2.fromOffset(178, 48), UDim2.fromOffset(24, 164), COLORS.green)
acceptButton.ZIndex = 12
local declineButton =
	makeButton(modal, "やめておく", UDim2.fromOffset(178, 48), UDim2.new(1, -202, 0, 164), COLORS.red)
declineButton.ZIndex = 12

local toast = Instance.new("TextLabel")
toast.Name = "Notification"
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0, 82)
toast.Size = UDim2.fromOffset(460, 54)
toast.BackgroundColor3 = COLORS.dark
toast.BackgroundTransparency = 0.16
toast.Font = Enum.Font.GothamBold
toast.TextColor3 = Color3.new(1, 1, 1)
toast.TextScaled = true
toast.TextWrapped = true
toast.Visible = false
toast.Parent = gui
corner(toast, 14)

local isStaff = false
local isBusy = false
local currentStep = "None"
local rotateDirection = 0
local toastVersion = 0
local cameraBound = false
local savedCameraMode: Enum.CameraMode? = nil
local savedCameraType: Enum.CameraType? = nil
local savedMouseBehavior: Enum.MouseBehavior? = nil
local savedMouseIconEnabled: boolean? = nil
local hiddenParts: { [BasePart]: number } = {}

type ProceduralFeedbackState = {
	step: string,
	startedAt: number,
	duration: number,
}

local activeFeedback: ProceduralFeedbackState? = nil
local currentStallId: string? = nil
local feedbackDisplay: Instance? = nil
local feedbackDisplayBase: CFrame? = nil
local feedbackVersion = 0

local CAMERA_BIND_NAME = "ChocolateBananaFirstPersonCamera"

local function bindMoney()
	local leaderstats = player:WaitForChild("leaderstats")
	local yen = leaderstats:WaitForChild("Yen") :: IntValue
	local function update()
		moneyLabel.Text = `💰 {yen.Value}円`
	end
	yen.Changed:Connect(update)
	update()
end

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


local function getInstancePivot(instance: Instance): CFrame?
	if instance:IsA("Model") then
		return instance:GetPivot()
	end
	if instance:IsA("BasePart") then
		return instance.CFrame
	end
	return nil
end

local function setInstancePivot(instance: Instance, target: CFrame)
	if instance:IsA("Model") then
		instance:PivotTo(target)
	elseif instance:IsA("BasePart") then
		instance.CFrame = target
	end
end

local function findStepDisplay(assetName: string): Instance?
	local stallId = currentStallId
	if not stallId then
		return nil
	end
	for _, instance in workspace:GetDescendants() do
		if
			instance:GetAttribute("ChocolateBananaStallId") == stallId
			and instance:GetAttribute("ChocolateBananaDisplayAsset") == assetName
		then
			return instance
		end
	end
	return nil
end

local function restoreFeedbackDisplay()
	local display = feedbackDisplay
	local base = feedbackDisplayBase
	feedbackDisplay = nil
	feedbackDisplayBase = nil
	if display and display.Parent and base then
		setInstancePivot(display, base)
	end
end

local function captureFeedbackDisplay(step: string)
	if feedbackDisplay and feedbackDisplay.Parent and feedbackDisplayBase then
		return
	end
	local assetName = DISPLAY_ASSET_BY_STEP[step]
	local display = if assetName then findStepDisplay(assetName) else nil
	local base = if display then getInstancePivot(display) else nil
	if display and base then
		feedbackDisplay = display
		feedbackDisplayBase = base
	end
end

local function cancelProceduralFeedback()
	feedbackVersion += 1
	activeFeedback = nil
	progressTrack.Visible = false
	progressFill.Size = UDim2.fromScale(0, 1)
	restoreFeedbackDisplay()
end

local function startProceduralFeedback(step: string)
	feedbackVersion += 1
	restoreFeedbackDisplay()

	activeFeedback = {
		step = step,
		startedAt = os.clock(),
		duration = math.max(ACTION_DURATION_BY_STEP[step] or 1, 0.05),
	}
	captureFeedbackDisplay(step)
	progressFill.Size = UDim2.fromScale(0, 1)
	progressFill.BackgroundColor3 = ACTION_COLOR_BY_STEP[step] or COLORS.green
	progressTrack.Visible = true
end

local function getStepDisplayRoot(assetName: string): BasePart?
	local item = findStepDisplay(assetName)
	if not item then
		return nil
	end
	if item:IsA("BasePart") then
		return item
	end
	if item:IsA("Model") then
		return item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function emitCompletionParticles(assetName: string, isFinal: boolean): boolean
	local root = getStepDisplayRoot(assetName)
	if not root then
		return false
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "ChocolateBananaCompletionEffect"
	attachment.Parent = root

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "CompletionSparkles"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 236, 120)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, if isFinal then 0.28 else 0.18),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Lifetime = NumberRange.new(0.35, 0.6)
	emitter.Speed = NumberRange.new(0.8, 1.8)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.LightEmission = 1
	emitter.Rate = 0
	emitter.Parent = attachment
	emitter:Emit(if isFinal then 26 else 12)
	Debris:AddItem(attachment, 1)
	return true
end

local function finishProceduralFeedback(completedStep: string)
	feedbackVersion += 1
	local version = feedbackVersion
	activeFeedback = nil
	restoreFeedbackDisplay()
	progressFill.Size = UDim2.fromScale(1, 1)

	local completionText = COMPLETE_TEXT_BY_STEP[completedStep]
	if completionText then
		showToast(completionText)
		local emitted = emitCompletionParticles(completedStep, completedStep == "Finished")
		if not emitted then
			task.delay(0.15, function()
				if feedbackVersion == version then
					emitCompletionParticles(completedStep, completedStep == "Finished")
				end
			end)
		end

		staffScale.Scale = 1
		local grow = TweenService:Create(
			staffScale,
			TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = if completedStep == "Finished" then 1.055 else 1.025 }
		)
		grow:Play()
		grow.Completed:Connect(function()
			if feedbackVersion == version then
				TweenService:Create(
					staffScale,
					TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Scale = 1 }
				):Play()
			end
		end)
	end

	task.delay(0.3, function()
		if feedbackVersion == version and not activeFeedback then
			progressTrack.Visible = false
			progressFill.Size = UDim2.fromScale(0, 1)
		end
	end)
end

local function updatePanel()
	staffFrame.Visible = isStaff
	if not isStaff then
		rotateDirection = 0
		return
	end

	stepLabel.Text = if isBusy then "作業中…" else (STEP_TEXT[currentStep] or "工程を確認中")

	local canSkewer = currentStep == "Ingredients" and not isBusy
	actionButton.Visible = true
	actionButton.Active = canSkewer
	actionButton.AutoButtonColor = canSkewer
	actionButton.Text = if isBusy
		then "調理中…"
		elseif canSkewer then "バナナを刺す"
		else "材料をそろえてください"
	actionButton.BackgroundTransparency = if canSkewer then 0.12 else 0.5

	rotateLeft.Active = not isBusy
	rotateRight.Active = not isBusy
	rotateLeft.BackgroundTransparency = if isBusy then 0.5 else 0.12
	rotateRight.BackgroundTransparency = if isBusy then 0.5 else 0.12
end

local function hideFirstPersonObstructions(character: Model)
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			local isHead = descendant.Name == "Head"
			local isAccessory = descendant:FindFirstAncestorWhichIsA("Accessory") ~= nil
			if (isHead or isAccessory) and hiddenParts[descendant] == nil then
				hiddenParts[descendant] = descendant.LocalTransparencyModifier
				descendant.LocalTransparencyModifier = 1
			end
		end
	end
end

local function restoreFirstPersonObstructions()
	for part, transparency in hiddenParts do
		if part.Parent then
			part.LocalTransparencyModifier = transparency
		end
	end
	table.clear(hiddenParts)
end

local function setFirstPersonEnabled(enabled: boolean)
	if enabled and not cameraBound then
		local camera = workspace.CurrentCamera
		cameraBound = true
		savedCameraMode = player.CameraMode
		savedCameraType = if camera then camera.CameraType else Enum.CameraType.Custom
		savedMouseBehavior = UserInputService.MouseBehavior
		savedMouseIconEnabled = UserInputService.MouseIconEnabled

		-- Scriptable camera keeps the first-person position without Roblox's
		-- LockFirstPerson cursor lock.
		player.CameraMode = Enum.CameraMode.Classic
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		if camera then
			camera.CameraType = Enum.CameraType.Scriptable
		end

		RunService:BindToRenderStep(CAMERA_BIND_NAME, Enum.RenderPriority.Camera.Value + 1, function()
			if not isStaff then
				return
			end

			local currentCamera = workspace.CurrentCamera
			local character = player.Character
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			local head = if character then character:FindFirstChild("Head") else nil
			if
				not currentCamera
				or not character
				or not root
				or not root:IsA("BasePart")
				or not head
				or not head:IsA("BasePart")
			then
				return
			end

			hideFirstPersonObstructions(character)
			currentCamera.CameraType = Enum.CameraType.Scriptable
			if UserInputService.MouseEnabled then
				UserInputService.MouseBehavior = Enum.MouseBehavior.Default
				UserInputService.MouseIconEnabled = true
			end

			local eyePosition = head.Position + root.CFrame.UpVector * 0.12
			currentCamera.CFrame = CFrame.new(eyePosition) * root.CFrame.Rotation
			currentCamera.Focus = currentCamera.CFrame * CFrame.new(0, 0, -12)
		end)
	elseif not enabled and cameraBound then
		RunService:UnbindFromRenderStep(CAMERA_BIND_NAME)
		cameraBound = false
		restoreFirstPersonObstructions()

		player.CameraMode = savedCameraMode or Enum.CameraMode.Classic
		if savedMouseBehavior then
			UserInputService.MouseBehavior = savedMouseBehavior
		end
		if savedMouseIconEnabled ~= nil then
			UserInputService.MouseIconEnabled = savedMouseIconEnabled
		end

		local camera = workspace.CurrentCamera
		local character = player.Character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		if camera then
			camera.CameraType = savedCameraType or Enum.CameraType.Custom
			if humanoid and camera.CameraType ~= Enum.CameraType.Scriptable then
				camera.CameraSubject = humanoid
			end
		end

		savedCameraMode = nil
		savedCameraType = nil
		savedMouseBehavior = nil
		savedMouseIconEnabled = nil
	end
end


RunService:BindToRenderStep(
	"ChocolateBananaProceduralFeedback",
	Enum.RenderPriority.Camera.Value + 2,
	function()
		local feedback = activeFeedback
		if not feedback or not isStaff then
			return
		end

		captureFeedbackDisplay(feedback.step)
		local progress = math.clamp((os.clock() - feedback.startedAt) / feedback.duration, 0, 1)
		local pulse = math.sin(progress * math.pi)
		progressFill.Size = UDim2.fromScale(progress, 1)

		local display = feedbackDisplay
		local base = feedbackDisplayBase
		if not display or not display.Parent or not base then
			return
		end

		if feedback.step == "Ingredients" then
			setInstancePivot(
				display,
				base
					* CFrame.new(0, 0.05 * pulse, -0.12 * pulse)
					* CFrame.Angles(0, 0, math.rad(-8) * pulse)
			)
		elseif feedback.step == "Skewered" then
			local dipAmount = math.sin(progress * math.pi)
			setInstancePivot(
				display,
				base
					* CFrame.new(0, -0.35 * dipAmount, 0)
					* CFrame.Angles(math.rad(6) * pulse, 0, 0)
			)
		elseif feedback.step == "Dipped" then
			local shake = math.sin(progress * math.pi * 10) * (1 - progress)
			setInstancePivot(
				display,
				base
					* CFrame.new(0, 0.04 * pulse, 0)
					* CFrame.Angles(0, math.rad(8) * shake, 0)
			)
		end
	end
)

local function setRotationFromButton(direction: number, inputState: Enum.UserInputState)
	if inputState == Enum.UserInputState.Begin and isStaff and not isBusy then
		rotateDirection = direction
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		if rotateDirection == direction then
			rotateDirection = 0
		end
	end
end

local function bindRotationButton(button: TextButton, direction: number)
	button.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			setRotationFromButton(direction, Enum.UserInputState.Begin)
		end
	end)
	button.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			setRotationFromButton(direction, Enum.UserInputState.End)
		end
	end)
end

bindRotationButton(rotateLeft, -1)
bindRotationButton(rotateRight, 1)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or UserInputService:GetFocusedTextBox() or not isStaff or isBusy then
		return
	end
	if input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.Q then
		rotateDirection = -1
	elseif
		input.KeyCode == Enum.KeyCode.D
		or input.KeyCode == Enum.KeyCode.Right
		or input.KeyCode == Enum.KeyCode.E
	then
		rotateDirection = 1
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if
		input.KeyCode == Enum.KeyCode.A
		or input.KeyCode == Enum.KeyCode.Left
		or input.KeyCode == Enum.KeyCode.Q
		or input.KeyCode == Enum.KeyCode.D
		or input.KeyCode == Enum.KeyCode.Right
		or input.KeyCode == Enum.KeyCode.E
	then
		rotateDirection = 0
	end
end)

RunService.RenderStepped:Connect(function(deltaTime)
	if not isStaff or isBusy or rotateDirection == 0 then
		return
	end

	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if root and root:IsA("BasePart") then
		local radians = math.rad(Config.RotationSpeedDegrees * deltaTime * rotateDirection)
		root.CFrame *= CFrame.Angles(0, radians, 0)
	end
end)

staffRequest.OnClientEvent:Connect(function()
	modalShade.Visible = true
end)

staffStatus.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	local wasStaff = isStaff
	local wasBusy = isBusy
	isStaff = payload.isStaff == true
	currentStallId = if type(payload.stallId) == "string" then payload.stallId else nil
	isBusy = payload.busy == true
	currentStep = if type(payload.step) == "string" then payload.step else "None"
	if isStaff ~= wasStaff then
		setFirstPersonEnabled(isStaff)
	end
	if isBusy then
		rotateDirection = 0
	end
	if isBusy and not wasBusy and isStaff then
		startProceduralFeedback(currentStep)
	elseif not isBusy and wasBusy then
		if isStaff then
			finishProceduralFeedback(currentStep)
		else
			cancelProceduralFeedback()
		end
	elseif not isStaff then
		cancelProceduralFeedback()
	end
	updatePanel()
end)

notifyRemote.OnClientEvent:Connect(function(message)
	if type(message) == "string" then
		showToast(message)
	end
end)

acceptButton.Activated:Connect(function()
	modalShade.Visible = false
	actionRemote:FireServer("AcceptStaff")
end)

declineButton.Activated:Connect(function()
	modalShade.Visible = false
	actionRemote:FireServer("DeclineStaff")
end)

resignButton.Activated:Connect(function()
	actionRemote:FireServer("Resign")
end)

actionButton.Activated:Connect(function()
	if currentStep == "Ingredients" and not isBusy then
		actionRemote:FireServer("Skewer")
	end
end)

script.Destroying:Connect(function()
	RunService:UnbindFromRenderStep("ChocolateBananaProceduralFeedback")
	cancelProceduralFeedback()
	setFirstPersonEnabled(false)
end)

task.spawn(bindMoney)
updatePanel()
