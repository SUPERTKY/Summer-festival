-- Roblox StudioでChocolateVatのBasePartを1つ選択してから、
-- 「表示 > コマンドバー」へこのファイル全体を貼り付けて実行してください。
--
-- 選択した筒へ開始点 ChocolateBananaDipPoint と
-- 終点 ChocolateBananaDipEndPoint の2つのAttachmentを作成します。
-- 開始点はバナナの位置・向き、終点は沈み切る位置です。

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")

local DIP_POINT_NAME = "ChocolateBananaDipPoint"
local DIP_END_POINT_NAME = "ChocolateBananaDipEndPoint"
local DEFAULT_ABOVE_VAT = 0.8
local DEFAULT_DIP_DEPTH = 1.4
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
	local oldEnd = vat:FindFirstChild(DIP_END_POINT_NAME)
	if oldEnd then
		oldEnd:Destroy()
	end

	-- RobloxのCylinderはローカルX軸が筒の長軸です。
	local localOutwardAxis = Vector3.xAxis
	if vat.CFrame.RightVector:Dot(Vector3.yAxis) < 0 then
		localOutwardAxis = -localOutwardAxis
	end
	local startOffset = localOutwardAxis * (vat.Size.X / 2 + DEFAULT_ABOVE_VAT)
	local endOffset = startOffset - localOutwardAxis * DEFAULT_DIP_DEPTH

	local dipPoint = Instance.new("Attachment")
	dipPoint.Name = DIP_POINT_NAME
	dipPoint.CFrame = CFrame.new(startOffset) * DEFAULT_ORIENTATION
	dipPoint.Visible = true
	dipPoint.Parent = vat

	local dipEndPoint = Instance.new("Attachment")
	dipEndPoint.Name = DIP_END_POINT_NAME
	dipEndPoint.Position = endOffset
	dipEndPoint.Visible = true
	dipEndPoint.Parent = vat

	Selection:Set({ dipPoint, dipEndPoint })
	print(`作成完了: {vat:GetFullName()}/{DIP_POINT_NAME}, {DIP_END_POINT_NAME}`)
	print("開始点はバナナの位置・向き、終点は沈み切る位置です。2点間が実際の移動方向になります。")
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
