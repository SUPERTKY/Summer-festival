--!strict

local Config = {
	InitialYen = 100,
	ProductPrice = 50,
	DataStoreName = "SummerFestivalYen_v1",
	SaveInStudio = false,

	PromptDistance = 10,
	JoinRequestLifetime = 12,
	TouchDebounceSeconds = 3,
	RotationSpeedDegrees = 100,

	AnimationIds = {
		Skewer = "",
		Dip = "",
		Topping = "",
	},

	ActionDurations = {
		Skewer = 1.6,
		Dip = 2.5,
		Topping = 4.2,
	},

	Tags = {
		StaffJoinBlock = "ChocolateBananaStaffJoinBlock",
		WorkAnchor = "ChocolateBananaWorkAnchor",
		BananaSource = "ChocolateBananaBananaSource",
		StickSource = "ChocolateBananaStickSource",
		ChocolateVat = "ChocolateBananaChocolateVat",
		ToppingContainer = "ChocolateBananaToppingContainer",
		SellBlock = "ChocolateBananaSellBlock",
		CurrentStepDisplayPoint = "ChocolateBananaCurrentStepDisplayPoint",
		DisplayPoint = "ChocolateBananaDisplayPoint",
	},

	PromptText = {
		Banana = "バナナを取る",
		Stick = "棒を取る",
		Dip = "チョコに漬ける",
		Topping = "トッピングする",
		Sell = "販売台に置く",
		Buy = "購入する",
	},

	ItemOffsets = {
		Banana = CFrame.new(0, -0.45, 0) * CFrame.Angles(0, 0, math.rad(90)),
		PeeledBanana = CFrame.new(0, -0.45, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Stick = CFrame.new(0, -0.55, 0) * CFrame.Angles(0, 0, 0),
		SkeweredBanana = CFrame.new(0, -0.55, 0) * CFrame.Angles(0, 0, 0),
		DippedBanana = CFrame.new(0, -0.55, 0) * CFrame.Angles(0, 0, 0),
		FinishedBanana = CFrame.new(0, -0.55, 0) * CFrame.Angles(0, 0, 0),
	},

	-- BananaとStickだけが登録されている場合に、後工程のモデルを合成する位置です。
	-- メッシュの向きに合わせてStudio上で微調整してください。
	CompositeOffsets = {
		Banana = CFrame.new(0, 0.35, 0),
		Stick = CFrame.new(0, -0.9, 0),
	},

	ActionVisuals = {
		-- 棒はCompositeOffsets.Stickの位置へ向かって、この相対位置から移動します。
		SkewerStickStartOffset = CFrame.new(0, -1.2, 0),
		-- チョコ筒の上面からどれだけ上で開始し、何スタッド沈めるかです。
		DipAboveVat = 0.8,
		DipDepth = 1.4,
		-- バナナ側の上下が逆の場合は、X/Y/Zの180度を切り替えて調整します。
		DipOrientationOffset = CFrame.Angles(math.rad(180), 0, 0),
	},

	EffectOffsets = {
		-- 登録コマンドで位置を取得できなかった場合のトッピング位置です。
		Topping = CFrame.new(0, -0.8, 0),
		-- 再登録後も放出方向が逆の場合だけ、X/Y/Zの180度を設定します。
		ToppingOrientationOffset = CFrame.identity,
	},

	ChocolateColor = Color3.fromRGB(91, 50, 30),
}

return table.freeze(Config)
