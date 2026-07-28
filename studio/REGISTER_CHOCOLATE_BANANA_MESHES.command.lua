-- Roblox Studioで次の4つのメッシュ／Modelを選択してから、
-- 「表示 > コマンドバー」へこのファイル全体を貼り付けて実行してください。
--
-- 選ぶオブジェクトの名前には次のどれかを含めてください。
-- バナナ: Banana / banana / バナナ
-- 棒: Stick / stick / Skewer / skewer / 棒
-- チョコ後: DippedBanana / dipped / チョコ後
-- 完成品: FinishedBanana / finished / 完成
--
-- 名前が違う場合は、Explorerで次の順番にCtrlを押しながら4個を選択します。
-- 1. 皮付きバナナ
-- 2. 棒
-- 3. チョコ後
-- 4. 完成品

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
local ServerStorage = game:GetService("ServerStorage")

local function classify(instance)
	local name = string.lower(instance.Name)
	if string.find(name, "finished", 1, true) or string.find(instance.Name, "完成", 1, true) then
		return "FinishedBanana"
	end
	if string.find(name, "dipped", 1, true) or string.find(instance.Name, "チョコ後", 1, true) then
		return "DippedBanana"
	end
	if string.find(name, "banana", 1, true) or string.find(instance.Name, "バナナ", 1, true) then
		return "Banana"
	end
	if
		string.find(name, "stick", 1, true)
		or string.find(name, "skewer", 1, true)
		or string.find(instance.Name, "棒", 1, true)
	then
		return "Stick"
	end
	return nil
end

local function usableAsset(instance)
	if instance:IsA("Model") or instance:IsA("BasePart") then
		return instance
	end
	if instance:IsA("DataModelMesh") and instance.Parent and instance.Parent:IsA("BasePart") then
		return instance.Parent
	end
	return nil
end

local rawSelection = Selection:Get()
local selected = {}
for _, instance in rawSelection do
	local usable = usableAsset(instance)
	if usable and not table.find(selected, usable) then
		table.insert(selected, usable)
	end
end

local sources = {}
for _, rawInstance in rawSelection do
	local instance = usableAsset(rawInstance)
	local assetName = classify(rawInstance)
	if assetName and instance then
		sources[assetName] = instance
	end

	if not assetName and (rawInstance:IsA("Model") or rawInstance:IsA("Folder")) then
		for _, child in rawInstance:GetChildren() do
			local childAssetName = classify(child)
			local childUsable = usableAsset(child)
			if childAssetName and childUsable then
				sources[childAssetName] = childUsable
			end
		end
	end
end

local allNamed = sources.Banana and sources.Stick and sources.DippedBanana and sources.FinishedBanana
if not allNamed then
	assert(
		#selected == 4,
		`4個を選択してください。現在の有効な選択数: {#selected}個。`
			.. " 選択順は「皮付きバナナ → 棒 → チョコ後 → 完成品」です。"
	)
	sources.Banana = selected[1]
	sources.Stick = selected[2]
	sources.DippedBanana = selected[3]
	sources.FinishedBanana = selected[4]
	print("名前で判定できなかったため、Explorerで選択した順番を使用します。")
end

local recording
pcall(function()
	recording = ChangeHistoryService:TryBeginRecording("Register chocolate banana meshes")
end)

local ok, result = xpcall(function()
	local assets = ServerStorage:FindFirstChild("ChocolateBananaAssets")
	if not assets then
		assets = Instance.new("Folder")
		assets.Name = "ChocolateBananaAssets"
		assets.Parent = ServerStorage
	end

	local registered = {}
	for _, assetName in { "Banana", "Stick", "DippedBanana", "FinishedBanana" } do
		local old = assets:FindFirstChild(assetName)
		if old then
			local backupName = `{assetName}_Backup`
			local suffix = 1
			while assets:FindFirstChild(backupName) do
				suffix += 1
				backupName = `{assetName}_Backup_{suffix}`
			end
			old.Name = backupName
		end

		local clone = sources[assetName]:Clone()
		clone.Name = assetName
		if clone:IsA("Model") and not clone.PrimaryPart then
			clone.PrimaryPart = clone:FindFirstChildWhichIsA("BasePart", true)
		end
		clone.Parent = assets
		table.insert(registered, clone)
	end

	Selection:Set(registered)
	print("登録完了: Banana / Stick / DippedBanana / FinishedBanana")
	print(`Banana <- {sources.Banana:GetFullName()}`)
	print(`Stick <- {sources.Stick:GetFullName()}`)
	print(`DippedBanana <- {sources.DippedBanana:GetFullName()}`)
	print(`FinishedBanana <- {sources.FinishedBanana:GetFullName()}`)
	print("串付き状態だけは、皮付きバナナと棒のメッシュから自動合成されます。")
	return true
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
		ChangeHistoryService:SetWaypoint("Register chocolate banana meshes")
	end)
end

if not ok then
	error(result)
end
