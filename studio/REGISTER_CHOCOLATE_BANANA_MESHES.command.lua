-- Roblox Studioで次の4つのメッシュ／Modelを選択してから、
-- 「表示 > コマンドバー」へこのファイル全体を貼り付けて実行してください。
--
-- 選ぶオブジェクトの名前には次のどれかを含めてください。
-- バナナ: Banana / banana / バナナ
-- 棒: Stick / stick / Skewer / skewer / 棒
-- チョコ後: DippedBanana / dipped / チョコ後
-- 完成品: FinishedBanana / finished / 完成

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

local selected = Selection:Get()
local sources = {}
for _, instance in selected do
	local assetName = classify(instance)
	if assetName then
		sources[assetName] = instance
	end
end

assert(
	sources.Banana,
	"名前に Banana または バナナを含むメッシュ／Modelを選択してください。"
)
assert(
	sources.Stick,
	"名前に Stick、Skewer、または 棒を含むメッシュ／Modelを選択してください。"
)
assert(
	sources.DippedBanana,
	"チョコ後の名前に DippedBanana、dipped、または チョコ後を含めて選択してください。"
)
assert(
	sources.FinishedBanana,
	"完成品の名前に FinishedBanana、finished、または 完成を含めて選択してください。"
)

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
