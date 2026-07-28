-- Roblox Studio の Edit モードで実行してください。
-- 1) 屋台 Model に StallId 属性があることを確認します。
-- 2) Explorer で「屋台 Model」と、今回用意した未コーティングの串バナナを選択します。
--    串バナナの名前は SkeweredBanana にしてください。
-- 3) FinishedBanana が ServerStorage/ChocolateBananaAssets にまだ無い場合だけ、
--    現在のチョコバナナも FinishedBanana という名前で一緒に選択します。
-- 4) このファイル全体を Command Bar へ貼り付けて実行します。
--
-- BOARD_OFFSET は屋台の Pivot から見た板の位置です。既存 DisplayPoint がある場合は、
-- その真下へ板を作るので BOARD_OFFSET は使いません。

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CollectionService = game:GetService("CollectionService")
local Selection = game:GetService("Selection")
local ServerStorage = game:GetService("ServerStorage")

local BOARD_NAME = "ChocolateBananaDisplayBoard"
local DISPLAY_POINT_NAME = "ChocolateBananaDisplayPoint"
local DISPLAY_TAG = "ChocolateBananaDisplayPoint"
local BOARD_SIZE = Vector3.new(7, 0.3, 2.2)
local BOARD_OFFSET = CFrame.new(0, 3.7, -4)
local SAMPLE_X = {
	FinishedBanana = -2.15,
	SkeweredBanana = 0,
}
local SALE_X = 2.15

local selected = Selection:Get()

local function isInside(instance, ancestor)
	return instance == ancestor or instance:IsDescendantOf(ancestor)
end

local function modelWithStallId(instance)
	local current = instance
	while current and current ~= workspace do
		if current:IsA("Model") and type(current:GetAttribute("StallId")) == "string" then
			return current
		end
		current = current.Parent
	end
	return nil
end

local stall
for _, instance in selected do
	stall = modelWithStallId(instance)
	if stall then
		break
	end
end

assert(stall, "StallId 属性を持つ屋台 Model を選択してください。")
assert((stall:GetAttribute("StallId") or "") ~= "", "屋台 Model の StallId を空でない文字列にしてください。")

local assets = ServerStorage:FindFirstChild("ChocolateBananaAssets")
if not assets then
	assets = Instance.new("Folder")
	assets.Name = "ChocolateBananaAssets"
	assets.Parent = ServerStorage
end

local function assetCandidate(instance)
	if isInside(instance, stall) then
		return nil
	end
	if instance:IsA("Model") or instance:IsA("BasePart") then
		return instance
	end
	return instance:FindFirstAncestorWhichIsA("Model")
end

local candidates = {}
for _, instance in selected do
	local candidate = assetCandidate(instance)
	if candidate and not table.find(candidates, candidate) then
		table.insert(candidates, candidate)
	end
end

local function findSelectedAsset(assetName)
	for _, instance in candidates do
		if string.lower(instance.Name) == string.lower(assetName) then
			return instance
		end
	end
	return nil
end

local selectedFinished = findSelectedAsset("FinishedBanana")
local selectedSkewered = findSelectedAsset("SkeweredBanana")

-- FinishedBanana がすでに登録済みで、屋台以外に未判定の選択が1個だけなら、
-- それを今回用意した SkeweredBanana として扱います。
if not selectedSkewered and assets:FindFirstChild("FinishedBanana") then
	local unknown = {}
	for _, instance in candidates do
		if instance ~= selectedFinished then
			table.insert(unknown, instance)
		end
	end
	if #unknown == 1 then
		selectedSkewered = unknown[1]
	end
end

local function ensurePrimaryPart(instance)
	if instance:IsA("Model") and not instance.PrimaryPart then
		local root = instance:FindFirstChildWhichIsA("BasePart", true)
		assert(root, instance.Name .. " に BasePart または MeshPart がありません。")
		instance.PrimaryPart = root
	end
end

local function installAsset(assetName, source)
	local existing = assets:FindFirstChild(assetName)
	if source and source ~= existing then
		if existing then
			local backups = assets:FindFirstChild("CommandBarBackups")
			if not backups then
				backups = Instance.new("Folder")
				backups.Name = "CommandBarBackups"
				backups.Parent = assets
			end
			local backup = existing:Clone()
			backup.Name = assetName .. "_Previous_" .. os.date("%Y%m%d_%H%M%S")
			backup.Parent = backups
			existing:Destroy()
		end

		existing = source:Clone()
		existing.Name = assetName
		existing.Parent = assets
	end

	assert(existing, assetName .. " がありません。Explorer で選択してから再実行してください。")
	assert(existing:IsA("Model") or existing:IsA("BasePart"), assetName .. " は Model / MeshPart / BasePart にしてください。")
	ensurePrimaryPart(existing)
	return existing
end

ChangeHistoryService:SetWaypoint("Before chocolate banana display setup")

local finishedAsset = installAsset("FinishedBanana", selectedFinished)
local skeweredAsset = installAsset("SkeweredBanana", selectedSkewered)

local oldDisplayPoint
for _, instance in CollectionService:GetTagged(DISPLAY_TAG) do
	if instance:IsA("BasePart") and isInside(instance, stall) then
		oldDisplayPoint = instance
		break
	end
end

local board = stall:FindFirstChild(BOARD_NAME)
if board and not board:IsA("BasePart") then
	error(BOARD_NAME .. " は BasePart である必要があります。")
end
if not board then
	board = Instance.new("Part")
	board.Name = BOARD_NAME
	board.Parent = stall
end

board.Anchored = true
board.CanCollide = true
board.CanQuery = true
board.CanTouch = true
board.Size = BOARD_SIZE
board.Color = Color3.fromRGB(116, 74, 45)
board.Material = Enum.Material.WoodPlanks
board.TopSurface = Enum.SurfaceType.Smooth
board.BottomSurface = Enum.SurfaceType.Smooth

if oldDisplayPoint then
	board.CFrame = oldDisplayPoint.CFrame * CFrame.new(0, -(BOARD_SIZE.Y / 2 + 0.12), 0)
elseif board:GetAttribute("ChocolateBananaConfigured") ~= true then
	board.CFrame = stall:GetPivot() * BOARD_OFFSET
end
board:SetAttribute("ChocolateBananaConfigured", true)

local displayPoint = oldDisplayPoint
if not displayPoint then
	displayPoint = Instance.new("Part")
	displayPoint.Name = DISPLAY_POINT_NAME
	displayPoint.Parent = stall
end

displayPoint.Name = DISPLAY_POINT_NAME
displayPoint.Anchored = true
displayPoint.CanCollide = false
displayPoint.CanQuery = false
displayPoint.CanTouch = false
displayPoint.Transparency = 1
displayPoint.Size = Vector3.new(0.5, 0.5, 0.5)
displayPoint.CFrame = board.CFrame * CFrame.new(SALE_X, BOARD_SIZE.Y / 2 + 0.3, 0)
displayPoint.Parent = stall
if not CollectionService:HasTag(displayPoint, DISPLAY_TAG) then
	CollectionService:AddTag(displayPoint, DISPLAY_TAG)
end

local samples = stall:FindFirstChild("ChocolateBananaDisplaySamples")
if not samples then
	samples = Instance.new("Folder")
	samples.Name = "ChocolateBananaDisplaySamples"
	samples.Parent = stall
end

local function prepareSample(instance)
	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
		elseif descendant:IsA("ProximityPrompt") or descendant:IsA("Script") or descendant:IsA("LocalScript") then
			descendant:Destroy()
		end
	end
	if instance:IsA("BasePart") then
		instance.Anchored = true
		instance.CanCollide = false
		instance.CanQuery = false
		instance.CanTouch = false
	end
end

local function getBounds(instance)
	if instance:IsA("Model") then
		return instance:GetBoundingBox()
	end
	return instance.CFrame, instance.Size
end

local function placeSample(asset, sampleName, x)
	local old = samples:FindFirstChild(sampleName)
	if old then
		old:Destroy()
	end

	local sample = asset:Clone()
	sample.Name = sampleName
	sample.Parent = samples
	prepareSample(sample)
	ensurePrimaryPart(sample)

	local boundsCF, boundsSize = getBounds(sample)
	local pivot = sample:GetPivot()
	local pivotToBounds = pivot:ToObjectSpace(boundsCF)
	local wantedBounds = board.CFrame * CFrame.new(x, BOARD_SIZE.Y / 2 + boundsSize.Y / 2 + 0.04, 0)
	sample:PivotTo(wantedBounds * pivotToBounds:Inverse())
	return sample
end

placeSample(finishedAsset, "FinishedBananaSample", SAMPLE_X.FinishedBanana)
placeSample(skeweredAsset, "SkeweredBananaSample", SAMPLE_X.SkeweredBanana)

Selection:Set({ board, displayPoint })
ChangeHistoryService:SetWaypoint("Create chocolate banana display board")

print("完了: 展示板、完成品サンプル、未コーティング串バナナ、販売用 DisplayPoint を設定しました。")
print("SkeweredBanana は作業工程の串刺し後メッシュとしても ServerStorage から使われます。")
