-- Roblox Studioでトッピング用ParticleEmitterを1つ選択してから、
-- 「表示 > コマンドバー」へこのファイル全体を貼り付けて実行してください。
--
-- ServerStorage/ChocolateBananaEffects/ToppingParticle へ複製します。
-- ParticleEmitterがAttachment内にある場合、そのAttachmentの位置と向きも保存します。
-- 既存エフェクトはToppingParticle_Backupとして残るため、元に戻せます。

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
local ServerStorage = game:GetService("ServerStorage")

local selected = Selection:Get()
assert(#selected == 1, `ParticleEmitterを1個だけ選択してください。現在の選択数: {#selected}個。`)

local source = selected[1]
assert(source:IsA("ParticleEmitter"), "選択対象はParticleEmitterにしてください。")

local recording
pcall(function()
	recording = ChangeHistoryService:TryBeginRecording("Register chocolate banana topping effect")
end)

local ok, result = xpcall(function()
	local effects = ServerStorage:FindFirstChild("ChocolateBananaEffects")
	if not effects then
		effects = Instance.new("Folder")
		effects.Name = "ChocolateBananaEffects"
		effects.Parent = ServerStorage
	end

	local old = effects:FindFirstChild("ToppingParticle")
	if old then
		local backupName = "ToppingParticle_Backup"
		local suffix = 1
		while effects:FindFirstChild(backupName) do
			suffix += 1
			backupName = `ToppingParticle_Backup_{suffix}`
		end
		old.Name = backupName
	end

	local clone = source:Clone()
	clone.Name = "ToppingParticle"
	clone.Enabled = false

	local sourceAttachment = source.Parent
	if sourceAttachment and sourceAttachment:IsA("Attachment") then
		clone:SetAttribute("AttachmentCFrame", sourceAttachment.CFrame)
	end

	clone.Parent = effects
	Selection:Set({ clone })
	print("登録完了: ChocolateBananaEffects/ToppingParticle")
	if clone:GetAttribute("AttachmentCFrame") then
		print("元のAttachment位置と向きも保存しました。")
	else
		print("位置はConfig.EffectOffsets.Toppingを使用します。")
	end
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
		ChangeHistoryService:SetWaypoint("Register chocolate banana topping effect")
	end)
end

if not ok then
	error(result)
end
