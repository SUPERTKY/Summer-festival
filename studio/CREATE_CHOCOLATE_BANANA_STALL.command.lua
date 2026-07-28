-- Roblox Studioの「表示 > コマンドバー」へ、このファイル全体を貼り付けて実行してください。
-- 選択中のBasePartを床として使います。未選択の場合はワールド原点へ作成します。

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CollectionService = game:GetService("CollectionService")
local Selection = game:GetService("Selection")
local ServerStorage = game:GetService("ServerStorage")

local TAGS = {
	StaffJoinBlock = "ChocolateBananaStaffJoinBlock",
	WorkAnchor = "ChocolateBananaWorkAnchor",
	BananaSource = "ChocolateBananaBananaSource",
	StickSource = "ChocolateBananaStickSource",
	ChocolateVat = "ChocolateBananaChocolateVat",
	ToppingContainer = "ChocolateBananaToppingContainer",
	SellBlock = "ChocolateBananaSellBlock",
	DisplayPoint = "ChocolateBananaDisplayPoint",
}

local function nextStallNumber()
	local number = 1
	while workspace:FindFirstChild(string.format("ChocolateBananaStall_%02d", number)) do
		number += 1
	end
	return number
end

local function floorCFrame()
	local selected = Selection:Get()[1]
	if selected and selected:IsA("BasePart") then
		return selected.CFrame * CFrame.new(0, selected.Size.Y / 2, 0)
	end
	if selected and selected:IsA("Model") then
		local boxCFrame, boxSize = selected:GetBoundingBox()
		return boxCFrame * CFrame.new(0, boxSize.Y / 2, 0)
	end
	return CFrame.new(0, 0, 0)
end

local recording
pcall(function()
	recording = ChangeHistoryService:TryBeginRecording("Create chocolate banana stall")
end)

local ok, result = xpcall(function()
	local stallNumber = nextStallNumber()
	local stallName = string.format("ChocolateBananaStall_%02d", stallNumber)
	local stallId = string.format("choco-banana-%02d", stallNumber)
	local origin = floorCFrame()

	local stall = Instance.new("Model")
	stall.Name = stallName
	stall:SetAttribute("StallId", stallId)
	stall.Parent = workspace

	local function makePart(options)
		local part = Instance.new("Part")
		part.Name = options.name
		part.Anchored = true
		part.CanCollide = options.canCollide ~= false
		part.CanTouch = options.canTouch ~= false
		part.CanQuery = true
		part.Size = options.size
		part.Color = options.color
		part.Material = options.material or Enum.Material.SmoothPlastic
		part.Transparency = options.transparency or 0
		part.CFrame = origin * options.offset
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		if options.shape then
			part.Shape = options.shape
		end
		part.Parent = stall
		if options.tag then
			CollectionService:AddTag(part, options.tag)
		end
		return part
	end

	makePart({
		name = "BoothFloor",
		size = Vector3.new(14, 0.4, 12),
		color = Color3.fromRGB(105, 68, 45),
		material = Enum.Material.WoodPlanks,
		offset = CFrame.new(0, 0.2, 0),
	})

	makePart({
		name = "Counter",
		size = Vector3.new(13, 1, 2),
		color = Color3.fromRGB(167, 103, 58),
		material = Enum.Material.WoodPlanks,
		offset = CFrame.new(0, 3, -4.4),
	})

	for _, position in
		{
			Vector3.new(-6.2, 4.2, -2.6),
			Vector3.new(6.2, 4.2, -2.6),
			Vector3.new(-6.2, 4.2, 2.6),
			Vector3.new(6.2, 4.2, 2.6),
		}
	do
		makePart({
			name = "RoofPost",
			size = Vector3.new(0.45, 8, 0.45),
			color = Color3.fromRGB(126, 77, 43),
			material = Enum.Material.Wood,
			offset = CFrame.new(position),
		})
	end

	makePart({
		name = "Roof",
		size = Vector3.new(14, 0.5, 7),
		color = Color3.fromRGB(222, 66, 59),
		material = Enum.Material.Fabric,
		offset = CFrame.new(0, 8.2, 0),
	})

	local sign = makePart({
		name = "Sign",
		size = Vector3.new(7, 1.8, 0.3),
		color = Color3.fromRGB(255, 224, 130),
		material = Enum.Material.Wood,
		offset = CFrame.new(0, 6.8, -3.55),
	})
	local surface = Instance.new("SurfaceGui")
	surface.Name = "SignGui"
	surface.Face = Enum.NormalId.Front
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 50
	surface.Parent = sign

	local signText = Instance.new("TextLabel")
	signText.BackgroundTransparency = 1
	signText.Size = UDim2.fromScale(1, 1)
	signText.Font = Enum.Font.GothamBold
	signText.Text = "チョコバナナ"
	signText.TextColor3 = Color3.fromRGB(91, 48, 28)
	signText.TextScaled = true
	signText.Parent = surface

	makePart({
		name = "StaffJoinBlock",
		size = Vector3.new(4, 0.4, 2.5),
		color = Color3.fromRGB(255, 211, 66),
		material = Enum.Material.Neon,
		offset = CFrame.new(0, 0.25, 4.5),
		tag = TAGS.StaffJoinBlock,
	})

	makePart({
		name = "WorkAnchor",
		size = Vector3.new(1, 1, 1),
		color = Color3.fromRGB(60, 200, 255),
		offset = CFrame.new(0, 3, 0),
		transparency = 1,
		canCollide = false,
		canTouch = false,
		tag = TAGS.WorkAnchor,
	})

	makePart({
		name = "BananaSource",
		size = Vector3.new(2.4, 0.45, 1.6),
		color = Color3.fromRGB(255, 221, 48),
		material = Enum.Material.SmoothPlastic,
		offset = CFrame.new(-4.7, 3.75, -3.25),
		tag = TAGS.BananaSource,
	})

	makePart({
		name = "StickSource",
		size = Vector3.new(2.4, 0.45, 1.6),
		color = Color3.fromRGB(139, 90, 43),
		material = Enum.Material.Wood,
		offset = CFrame.new(4.7, 3.75, -3.25),
		tag = TAGS.StickSource,
	})

	makePart({
		name = "ChocolateVat",
		size = Vector3.new(1.7, 2, 1.7),
		color = Color3.fromRGB(76, 40, 24),
		material = Enum.Material.Metal,
		offset = CFrame.new(-3.1, 4.35, -4.45) * CFrame.Angles(0, 0, math.rad(90)),
		shape = Enum.PartType.Cylinder,
		tag = TAGS.ChocolateVat,
	})

	makePart({
		name = "ToppingContainer",
		size = Vector3.new(2, 1.3, 1.7),
		color = Color3.fromRGB(255, 126, 148),
		material = Enum.Material.SmoothPlastic,
		offset = CFrame.new(0.3, 4.15, -4.45),
		tag = TAGS.ToppingContainer,
	})

	makePart({
		name = "SellBlock",
		size = Vector3.new(2.2, 0.65, 1.7),
		color = Color3.fromRGB(65, 184, 104),
		material = Enum.Material.Neon,
		offset = CFrame.new(3.5, 3.85, -4.45),
		tag = TAGS.SellBlock,
	})

	makePart({
		name = "DisplayStand",
		size = Vector3.new(3, 2.4, 2),
		color = Color3.fromRGB(255, 236, 190),
		material = Enum.Material.WoodPlanks,
		offset = CFrame.new(4, 1.4, -6.4),
	})

	makePart({
		name = "DisplayPoint",
		size = Vector3.new(0.5, 0.5, 0.5),
		color = Color3.fromRGB(60, 200, 255),
		offset = CFrame.new(4, 2.95, -6.4) * CFrame.Angles(0, math.rad(90), 0),
		transparency = 1,
		canCollide = false,
		canTouch = false,
		tag = TAGS.DisplayPoint,
	})

	local assets = ServerStorage:FindFirstChild("ChocolateBananaAssets")
	if not assets then
		assets = Instance.new("Folder")
		assets.Name = "ChocolateBananaAssets"
		assets.Parent = ServerStorage
	end

	stall.PrimaryPart = stall:FindFirstChild("BoothFloor")
	Selection:Set({ stall })
	print(string.format("作成完了: %s / StallId=%s", stallName, stallId))
	print("作成位置が違う場合は、選択された屋台Modelを移動してください。")
	print("商品モデルは ServerStorage > ChocolateBananaAssets に入れてください。")
	return stallName
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
		ChangeHistoryService:SetWaypoint("Create chocolate banana stall")
	end)
end

if not ok then
	error(result)
end
