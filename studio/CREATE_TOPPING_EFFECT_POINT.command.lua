-- Roblox Studioで工程表示用のCurrentStepDisplayPointを1つ選択してから、
-- 「表示 > コマンドバー」へこのファイル全体を貼り付けて実行してください。
--
-- 選択したPartへ ChocolateBananaToppingEffectPoint Attachment を作成します。
-- 実行後にAttachmentが選択されるので、移動・回転ツールで調整してください。
-- すでに存在する場合は削除せず、そのAttachmentを選択します。

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CollectionService = game:GetService("CollectionService")
local Selection = game:GetService("Selection")

local DISPLAY_TAG = "ChocolateBananaCurrentStepDisplayPoint"
local EFFECT_POINT_NAME = "ChocolateBananaToppingEffectPoint"
local DEFAULT_CFRAME = CFrame.new(0, -0.8, 0)

local selected = Selection:Get()
assert(#selected == 1, `CurrentStepDisplayPointを1個だけ選択してください。現在の選択数: {#selected}個。`)

local displayPoint = selected[1]
assert(displayPoint:IsA("BasePart"), "選択対象はCurrentStepDisplayPointのBasePartにしてください。")
assert(
	CollectionService:HasTag(displayPoint, DISPLAY_TAG),
	`選択したPartに {DISPLAY_TAG} タグがありません。`
)

local existing = displayPoint:FindFirstChild(EFFECT_POINT_NAME)
if existing then
	assert(existing:IsA("Attachment"), `{EFFECT_POINT_NAME} はAttachmentである必要があります。`)
	existing.Visible = true
	Selection:Set({ existing })
	print(`既存のEffectPointを選択しました: {existing:GetFullName()}`)
	return
end

local recording
pcall(function()
	recording = ChangeHistoryService:TryBeginRecording("Create chocolate banana topping effect point")
end)

local ok, result = xpcall(function()
	local effectPoint = Instance.new("Attachment")
	effectPoint.Name = EFFECT_POINT_NAME
	effectPoint.CFrame = DEFAULT_CFRAME
	effectPoint.Visible = true
	effectPoint.Parent = displayPoint

	Selection:Set({ effectPoint })
	print(`作成完了: {effectPoint:GetFullName()}`)
	print("このAttachmentの位置・向きが、ゲーム内のParticleEmitterへそのまま使われます。")
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
		ChangeHistoryService:SetWaypoint("Create chocolate banana topping effect point")
	end)
end

if not ok then
	error(result)
end
