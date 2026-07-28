-- Roblox Studio の Edit モードで実行してください。
-- 1) 屋台 Model に StallId 属性があることを確認します。
-- 2) Explorer で「屋台 Model」と、今回用意した未コーティングの串バナナを選択します。
--    串バナナの名前は SkeweredBanana にしてください。
-- 3) FinishedBanana が ServerStorage/ChocolateBananaAssets にまだ無い場合だけ、
--    現在の完成チョコバナナも FinishedBanana という名前で一緒に選択します。
-- 4) このファイル全体を Command Bar へ貼り付けて実行します。
--
-- 実行後、板の左側が工程中バナナ、右側が販売中の完成品です。
-- BOARD_OFFSET は屋台の Pivot から見た板の位置です。既存 DisplayPoint がある場合は、
-- その販売位置を維持するように板を作るので BOARD_OFFSET は使いません。

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CollectionService = game:GetService("CollectionService")
local Selection = game:GetService("Selection")
local ServerStorage = game:GetService("ServerStorage")

local BOARD_NAME = "ChocolateBananaDisplayBoard"
local CURRENT_POINT_NAME = "ChocolateBananaCurrentStepDisplayPoint"
local SALE_POINT_NAME = "ChocolateBananaDisplayPoint"
local CURRENT_POINT_TAG = "ChocolateBananaCurrentStepDisplayPoint"
local SALE_POINT_TAG = "ChocolateBananaDisplayPoint"

local BOARD_SIZE = Vector3.new(7, 0.3, 2.2)
local BOARD_OFFSET = CFrame.new(0, 3.7, -4)
local CURRENT_X = -1.7
local SALE_X = 1.7
local ITEM_HEIGHT = 0.45

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

-- FinishedBanana が登録済みで、屋台以外に未判定の選択が1個だけなら、
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

local function findTaggedPoint(tag)
	for _, instance in CollectionService:GetTagged(tag) do
		if instance:IsA("BasePart") and isInside(instance, stall) then
			return instance
		end
	end
	return nil
end

local function configurePoint(point, name, tag, localX)
	point.Name = name
	point.Anchored = true
	point.CanCollide = false
	point.CanQuery = false
	point.CanTouch = false
	point.Transparency = 1
	point.Size = Vector3.new(0.5, 0.5, 0.5)
	point.CFrame = board.CFrame * CFrame.new(localX, BOARD_SIZE.Y / 2 + ITEM_HEIGHT, 0)
	point.Parent = stall
	if not CollectionService:HasTag(point, tag) then
		CollectionService:AddTag(point, tag)
	end
end

ChangeHistoryService:SetWaypoint("Before chocolate banana display setup")

installAsset("FinishedBanana", selectedFinished)
installAsset("SkeweredBanana", selectedSkewered)

local oldSalePoint = findTaggedPoint(SALE_POINT_TAG)
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

if board:GetAttribute("ChocolateBananaConfigured") ~= true then
	if oldSalePoint then
		board.CFrame = oldSalePoint.CFrame
			* CFrame.new(-SALE_X, -(BOARD_SIZE.Y / 2 + ITEM_HEIGHT), 0)
	else
		board.CFrame = stall:GetPivot() * BOARD_OFFSET
	end
end
board:SetAttribute("ChocolateBananaConfigured", true)

local currentPoint = findTaggedPoint(CURRENT_POINT_TAG)
if not currentPoint then
	currentPoint = Instance.new("Part")
end
configurePoint(currentPoint, CURRENT_POINT_NAME, CURRENT_POINT_TAG, CURRENT_X)

local salePoint = oldSalePoint
if not salePoint then
	salePoint = Instance.new("Part")
end
configurePoint(salePoint, SALE_POINT_NAME, SALE_POINT_TAG, SALE_X)

-- 旧版コマンドで作った固定見本は削除します。
-- 工程中の商品はサーバースクリプトが currentPoint に1つだけ表示します。
local oldSamples = stall:FindFirstChild("ChocolateBananaDisplaySamples")
if oldSamples then
	oldSamples:Destroy()
end

Selection:Set({ board, currentPoint, salePoint })
ChangeHistoryService:SetWaypoint("Create current-step chocolate banana display")

print("完了: 左側に工程展示位置、右側に販売位置を設定しました。")
print("工程は Banana → SkeweredBanana → DippedBanana → FinishedBanana の順で自動更新されます。")
print("購入ツールにも ServerStorage/ChocolateBananaAssets/FinishedBanana が使われます。")
