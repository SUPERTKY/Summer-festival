--!strict

local ServerStorage = game:GetService("ServerStorage")

local AssetFactory = {}
AssetFactory.__index = AssetFactory

type AssetFactory = typeof(setmetatable(
	{} :: {
		_config: any,
		_assetFolder: Folder,
	},
	AssetFactory
))

local PLACEHOLDER_COLORS = {
	Banana = Color3.fromRGB(255, 221, 48),
	Stick = Color3.fromRGB(139, 90, 43),
	SkeweredBanana = Color3.fromRGB(255, 221, 48),
	DippedBanana = Color3.fromRGB(91, 50, 30),
	FinishedBanana = Color3.fromRGB(111, 59, 32),
}

local function getRoot(instance: Instance): BasePart?
	if instance:IsA("BasePart") then
		return instance
	end
	if instance:IsA("Model") then
		return instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function setPartProperties(instance: Instance, anchored: boolean)
	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = anchored
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.Massless = not anchored
		end
	end
	if instance:IsA("BasePart") then
		instance.Anchored = anchored
		instance.CanCollide = false
		instance.CanQuery = false
		instance.Massless = not anchored
	end
end

local function pivotInstance(instance: Instance, target: CFrame)
	if instance:IsA("Model") then
		instance:PivotTo(target)
	elseif instance:IsA("BasePart") then
		instance.CFrame = target
	end
end

local function tintParts(instance: Instance, color: Color3)
	if instance:IsA("BasePart") then
		instance.Color = color
		instance.Material = Enum.Material.SmoothPlastic
	end
	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Color = color
			descendant.Material = Enum.Material.SmoothPlastic
		end
	end
end

local function weldModelToRoot(instance: Instance, root: BasePart)
	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("BasePart") and descendant ~= root then
			local weld = Instance.new("WeldConstraint")
			weld.Name = "ChocolateBananaItemWeld"
			weld.Part0 = root
			weld.Part1 = descendant
			weld.Parent = descendant
		end
	end
end

function AssetFactory.new(config: any): AssetFactory
	local folder = ServerStorage:FindFirstChild("ChocolateBananaAssets")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "ChocolateBananaAssets"
		folder.Parent = ServerStorage
	end

	return setmetatable({
		_config = config,
		_assetFolder = folder :: Folder,
	}, AssetFactory)
end

function AssetFactory:_placeholder(name: string): Model
	local model = Instance.new("Model")
	model.Name = name

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Color = PLACEHOLDER_COLORS[name] or Color3.fromRGB(255, 255, 255)
	handle.Material = if name == "Stick" then Enum.Material.Wood else Enum.Material.SmoothPlastic
	handle.Size = if name == "Stick" then Vector3.new(0.12, 1.8, 0.12) else Vector3.new(0.45, 1.7, 0.45)
	handle.Shape = if name == "Stick" then Enum.PartType.Block else Enum.PartType.Cylinder
	handle.Parent = model
	model.PrimaryPart = handle

	if name == "DippedBanana" or name == "FinishedBanana" then
		local tip = Instance.new("Part")
		tip.Name = "Chocolate"
		tip.Color = Color3.fromRGB(73, 38, 22)
		tip.Material = Enum.Material.SmoothPlastic
		tip.Size = Vector3.new(0.5, 1.15, 0.5)
		tip.Shape = Enum.PartType.Cylinder
		tip.CFrame = handle.CFrame * CFrame.new(0, 0.2, 0)
		tip.Parent = model

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = tip
		weld.Parent = tip
	end

	return model
end

function AssetFactory:_composite(name: string): Model?
	local bananaTemplate = self._assetFolder:FindFirstChild("Banana")
	local stickTemplate = self._assetFolder:FindFirstChild("Stick")
	if not bananaTemplate or not stickTemplate then
		return nil
	end

	local model = Instance.new("Model")
	model.Name = name

	local root = Instance.new("Part")
	root.Name = "Handle"
	root.Size = Vector3.new(0.1, 0.1, 0.1)
	root.Transparency = 1
	root.CanCollide = false
	root.CanQuery = false
	root.Massless = true
	root.Parent = model
	model.PrimaryPart = root

	local banana = bananaTemplate:Clone()
	banana.Name = "BananaMesh"
	banana.Parent = model
	pivotInstance(banana, root.CFrame * self._config.CompositeOffsets.Banana)

	local stick = stickTemplate:Clone()
	stick.Name = "StickMesh"
	stick.Parent = model
	pivotInstance(stick, root.CFrame * self._config.CompositeOffsets.Stick)

	if name == "DippedBanana" or name == "FinishedBanana" then
		tintParts(banana, self._config.ChocolateColor)
	end

	if name == "FinishedBanana" then
		local toppingColors = {
			Color3.fromRGB(255, 92, 92),
			Color3.fromRGB(255, 222, 72),
			Color3.fromRGB(92, 190, 255),
			Color3.fromRGB(255, 255, 255),
		}
		for index = 1, 8 do
			local sprinkle = Instance.new("Part")
			sprinkle.Name = "Topping"
			sprinkle.Shape = Enum.PartType.Ball
			sprinkle.Size = Vector3.new(0.1, 0.1, 0.1)
			sprinkle.Color = toppingColors[((index - 1) % #toppingColors) + 1]
			sprinkle.Material = Enum.Material.Neon
			local angle = (index / 8) * math.pi * 2
			sprinkle.CFrame = root.CFrame
				* CFrame.new(math.cos(angle) * 0.28, 0.35 + ((index % 3) * 0.18), math.sin(angle) * 0.28)
			sprinkle.Parent = model
		end
	end

	return model
end

function AssetFactory:Clone(name: string): Instance
	local template = self._assetFolder:FindFirstChild(name)
	local composite = if not template
			and (name == "SkeweredBanana" or name == "DippedBanana" or name == "FinishedBanana")
		then self:_composite(name)
		else nil
	local clone = if template then template:Clone() elseif composite then composite else self:_placeholder(name)
	clone.Name = `CB_{name}`
	return clone
end

function AssetFactory:Attach(character: Model, handName: string, assetName: string): Instance?
	local hand = character:FindFirstChild(handName)
		or character:FindFirstChild(if handName == "LeftHand" then "Left Arm" else "Right Arm")
	if not hand or not hand:IsA("BasePart") then
		return nil
	end

	local clone = self:Clone(assetName)
	local root = getRoot(clone)
	if not root then
		clone:Destroy()
		return nil
	end

	setPartProperties(clone, false)
	weldModelToRoot(clone, root)
	clone.Parent = character

	local offset = self._config.ItemOffsets[assetName] or CFrame.new()
	if clone:IsA("Model") then
		clone:PivotTo(hand.CFrame * offset)
	else
		(clone :: BasePart).CFrame = hand.CFrame * offset
	end

	local weld = Instance.new("WeldConstraint")
	weld.Name = "ChocolateBananaGrip"
	weld.Part0 = hand
	weld.Part1 = root
	weld.Parent = root
	return clone
end

function AssetFactory:Place(assetName: string, target: CFrame, parent: Instance): Instance?
	local clone = self:Clone(assetName)
	local root = getRoot(clone)
	if not root then
		clone:Destroy()
		return nil
	end

	setPartProperties(clone, true)
	clone.Parent = parent
	if clone:IsA("Model") then
		clone:PivotTo(target)
	else
		(clone :: BasePart).CFrame = target
	end
	return clone
end

function AssetFactory:CreatePurchasedTool(): Tool
	local template = self._assetFolder:FindFirstChild("FinishedBananaTool")
	if template and template:IsA("Tool") then
		return template:Clone()
	end

	local tool = Instance.new("Tool")
	tool.Name = "チョコバナナ"
	tool.ToolTip = "夏祭りのチョコバナナ"

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.2, 0.2, 0.2)
	handle.Transparency = 1
	handle.CanCollide = false
	handle.CanQuery = false
	handle.Massless = true
	handle.Parent = tool

	local finished = self:Clone("FinishedBanana")
	setPartProperties(finished, false)
	finished.Parent = tool
	pivotInstance(finished, handle.CFrame)
	weldModelToRoot(finished, handle)

	return tool
end

return AssetFactory
