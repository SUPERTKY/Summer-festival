--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local packageFolder = ReplicatedStorage:WaitForChild("ChocolateBanana")
local Config = require(packageFolder:WaitForChild("Config"))
local AssetFactory = require(script.Parent:WaitForChild("AssetFactory"))
local MoneyService = require(script.Parent:WaitForChild("MoneyService"))
local ChocolateBananaService = require(script.Parent:WaitForChild("ChocolateBananaService"))

local moneyService = MoneyService.new(Config)
moneyService:Start()

local assets = AssetFactory.new(Config)
local service = ChocolateBananaService.new(Config, moneyService, assets)
service:Start()
