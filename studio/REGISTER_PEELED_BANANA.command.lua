-- Roblox Studioで皮なしバナナのMeshPart／Part／Modelを1つ選択してから、
-- 「表示 > コマンドバー」へこのファイル全体を貼り付けて実行してください。
--
-- ServerStorage/ChocolateBananaAssets/PeeledBanana を登録または差し替えます。
-- 既存のPeeledBananaはPeeledBanana_Backupとして残るため、元に戻せます。

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
local ServerStorage = game:GetService("ServerStorage")

local function usableAsset(instance)
	if instance:IsA("Model") or instance:IsA("BasePart") then
		return instance
	end
	if instance:IsA("DataModelMesh") and instance.Parent and instance.Parent:IsA("BasePart") then
		return instance.Parent
	end
	return nil
end

local selected = Selection:Get()
assert(#selected == 1, `皮なしバナナを1個だけ選択してください。現在の選択数: {#selected}個。`)

local source = usableAsset(selected[1])
assert(source, "選択対象はMeshPart、Part、Model、またはPart内のSpecialMeshにしてください。")

local recording
pcall(function()
	recording = ChangeHistoryService:TryBeginRecording("Register peeled banana mesh")
end)

local ok, result = xpcall(function()
	local assets = ServerStorage:FindFirstChild("ChocolateBananaAssets")
	if not assets then
		assets = Instance.new("Folder")
		assets.Name = "ChocolateBananaAssets"
		assets.Parent = ServerStorage
	end

	local old = assets:FindFirstChild("PeeledBanana")
	if old then
		local backupName = "PeeledBanana_Backup"
		local suffix = 1
		while assets:FindFirstChild(backupName) do
			suffix += 1
			backupName = `PeeledBanana_Backup_{suffix}`
		end
		old.Name = backupName
	end

	local clone = source:Clone()
	clone.Name = "PeeledBanana"
	if clone:IsA("Model") and not clone.PrimaryPart then
		clone.PrimaryPart = clone:FindFirstChildWhichIsA("BasePart", true)
	end
	clone.Parent = assets

	Selection:Set({ clone })
	print("登録完了: PeeledBanana")
	print(`PeeledBanana <- {source:GetFullName()}`)
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
		ChangeHistoryService:SetWaypoint("Register peeled banana mesh")
	end)
end

if not ok then
	error(result)
end
