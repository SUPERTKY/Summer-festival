-- Roblox StudioでChocolateVatのBasePartを1つ選択してから、
-- 「表示 > コマンドバー」へこのファイル全体を貼り付けて実行してください。
--
-- 選択した筒の上へ ChocolateBananaDipPoint Attachment を作成します。
-- 実行後にAttachmentが選択されるので、Studioの移動・回転ツールで
-- 串付きバナナを開始させたい位置と向きへ調整してください。

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")

local DIP_POINT_NAME = "ChocolateBananaDipPoint"
local DEFAULT_ABOVE_VAT = 0.8
local DEFAULT_ORIENTATION = CFrame.Angles(0, 0, math.rad(180))

local selected = Selection:Get()
assert(#selected == 1, `チョコ筒のBasePartを1個だけ選択してください。現在の選択数: {#selected}個。`)

local vat = selected[1]
assert(vat:IsA("BasePart"), "選択対象はChocolateVatのBasePartにしてください。")

local recording
pcall(function()
	recording = ChangeHistoryService:TryBeginRecording("Create chocolate banana dip point")
end)

local ok, result = xpcall(function()
	local old = vat:FindFirstChild(DIP_POINT_NAME)
	if old then
		old:Destroy()
	end

	local dipPoint = Instance.new("Attachment")
	dipPoint.Name = DIP_POINT_NAME
	dipPoint.CFrame = CFrame.new(0, vat.Size.Y / 2 + DEFAULT_ABOVE_VAT, 0)
	dipPoint.Visible = true
	dipPoint.Parent = vat

	Selection:Set({ dipPoint })
	print(`作成完了: {vat:GetFullName()}/{DIP_POINT_NAME}`)
	print("このAttachmentを移動・回転すると、チョコ漬け開始時のバナナも同じ位置・向きになります。")
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
		ChangeHistoryService:SetWaypoint("Create chocolate banana dip point")
	end)
end

if not ok then
	error(result)
end
