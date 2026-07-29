-- Roblox Studioでトッピング用ParticleEmitterを1つ選択してから、
-- 「表示 > コマンドバー」へこのファイル全体を貼り付けて実行してください。
--
-- ServerStorage/ChocolateBananaEffects/ToppingParticle へ複製します。
-- ParticleEmitterの位置と向きを、元モデルのルートPart基準で保存します。
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

	local sourceParent = source.Parent
	local sourceWorldCFrame: CFrame? = nil
	if sourceParent and sourceParent:IsA("Attachment") then
		sourceWorldCFrame = sourceParent.WorldCFrame
	elseif sourceParent and sourceParent:IsA("BasePart") then
		sourceWorldCFrame = sourceParent.CFrame
	end

	if sourceWorldCFrame then
		local sourceModel = source:FindFirstAncestorOfClass("Model")
		local referencePart: BasePart? = nil
		if sourceModel then
			referencePart = sourceModel.PrimaryPart or sourceModel:FindFirstChildWhichIsA("BasePart", true)
		end
		if not referencePart then
			referencePart = source:FindFirstAncestorWhichIsA("BasePart")
		end

		if referencePart then
			clone:SetAttribute(
				"AttachmentCFrame",
				referencePart.CFrame:ToObjectSpace(sourceWorldCFrame)
			)
		elseif sourceParent:IsA("Attachment") then
			clone:SetAttribute("AttachmentCFrame", sourceParent.CFrame)
		end
	end

	clone.Parent = effects
	Selection:Set({ clone })
	print("登録完了: ChocolateBananaEffects/ToppingParticle")
	if clone:GetAttribute("AttachmentCFrame") then
		print("元モデルのルートPartを基準に、エフェクト位置と向きを保存しました。")
	else
		print("位置と向きはConfig.EffectOffsetsを使用します。")
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
