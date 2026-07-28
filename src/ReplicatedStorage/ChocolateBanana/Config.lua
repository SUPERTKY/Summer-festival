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

	ChocolateColor = Color3.fromRGB(91, 50, 30),
}

return table.freeze(Config)
