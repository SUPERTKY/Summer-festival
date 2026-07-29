-- Roblox Studioで次の6つのメッシュ／Modelを選択してから、
-- 「表示 > コマンドバー」へこのファイル全体を貼り付けて実行してください。
--
-- 選ぶオブジェクトの名前には次のどれかを含めてください。
-- 皮付きバナナ: Banana / banana / バナナ
-- 皮なしバナナ: PeeledBanana / peeled / skinless / 皮なし / 皮無し / むき
-- 棒: Stick / stick / 棒
-- 串刺し済み: SkeweredBanana / skewered / 串付き / 串刺し済み
-- チョコ後: DippedBanana / dipped / チョコ後
-- 完成品: FinishedBanana / finished / 完成
--
-- 名前が違う場合は、Explorerで次の順番にCtrlを押しながら6個を選択します。
-- 1. 皮付きバナナ
-- 2. 皮なしバナナ
-- 3. 棒
-- 4. 串刺し済み・チョコ前
-- 5. チョコ後
-- 6. 完成品

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
	if
		string.find(name, "skewered", 1, true)
		or string.find(instance.Name, "串付き", 1, true)
		or string.find(instance.Name, "串刺し済み", 1, true)
		or string.find(instance.Name, "刺した", 1, true)
	then
		return "SkeweredBanana"
	end
	if
		string.find(name, "peeled", 1, true)
		or string.find(name, "skinless", 1, true)
		or string.find(instance.Name, "皮なし", 1, true)
		or string.find(instance.Name, "皮無し", 1, true)
		or string.find(instance.Name, "むき", 1, true)
	then
		return "PeeledBanana"
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

local allNamed = sources.Banana
	and sources.PeeledBanana
	and sources.Stick
	and sources.SkeweredBanana
	and sources.DippedBanana
	and sources.FinishedBanana
if not allNamed then
	assert(
		#selected == 6,
		`6個を選択してください。現在の有効な選択数: {#selected}個。`
			.. " 選択順は「皮付きバナナ → 皮なしバナナ → 棒 → 串刺し済み・チョコ前 → チョコ後 → 完成品」です。"
	)
	sources.Banana = selected[1]
	sources.PeeledBanana = selected[2]
	sources.Stick = selected[3]
	sources.SkeweredBanana = selected[4]
	sources.DippedBanana = selected[5]
	sources.FinishedBanana = selected[6]
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
	for _, assetName in { "Banana", "PeeledBanana", "Stick", "SkeweredBanana", "DippedBanana", "FinishedBanana" } do
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
	print("登録完了: Banana / PeeledBanana / Stick / SkeweredBanana / DippedBanana / FinishedBanana")
	print(`Banana <- {sources.Banana:GetFullName()}`)
	print(`PeeledBanana <- {sources.PeeledBanana:GetFullName()}`)
	print(`Stick <- {sources.Stick:GetFullName()}`)
	print(`SkeweredBanana <- {sources.SkeweredBanana:GetFullName()}`)
	print(`DippedBanana <- {sources.DippedBanana:GetFullName()}`)
	print(`FinishedBanana <- {sources.FinishedBanana:GetFullName()}`)
	print("串刺し後は登録したSkeweredBananaを使用します。未登録時だけ皮なしバナナと棒から自動合成されます。")
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
