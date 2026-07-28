--!strict

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MoneyService = {}
MoneyService.__index = MoneyService

type MoneyService = typeof(setmetatable(
	{} :: {
		_config: any,
		_store: GlobalDataStore,
		_values: { [Player]: IntValue },
	},
	MoneyService
))

function MoneyService.new(config: any): MoneyService
	return setmetatable({
		_config = config,
		_store = DataStoreService:GetDataStore(config.DataStoreName),
		_values = {},
	}, MoneyService)
end

function MoneyService:_canUseDataStore(): boolean
	return not RunService:IsStudio() or self._config.SaveInStudio
end

function MoneyService:_load(player: Player): number
	if not self:_canUseDataStore() then
		return self._config.InitialYen
	end

	local success, result = pcall(function()
		return self._store:GetAsync(`player_{player.UserId}`)
	end)

	if success and type(result) == "number" then
		return math.max(0, math.floor(result))
	end

	if not success then
		warn(`Could not load yen for {player.Name}: {result}`)
	end
	return self._config.InitialYen
end

function MoneyService:_createValue(player: Player, amount: number)
	if self._values[player] then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local existing = leaderstats:FindFirstChild("Yen")
	local yen: IntValue
	if existing and existing:IsA("IntValue") then
		yen = existing
	else
		yen = Instance.new("IntValue")
		yen.Name = "Yen"
		yen.Parent = leaderstats
	end
	yen.Value = amount

	player:SetAttribute("Yen", amount)
	yen.Changed:Connect(function(value)
		player:SetAttribute("Yen", value)
	end)
	self._values[player] = yen
end

function MoneyService:_save(player: Player)
	local value = self._values[player]
	if not value or not self:_canUseDataStore() then
		return
	end

	local amount = value.Value
	local success, err = pcall(function()
		self._store:UpdateAsync(`player_{player.UserId}`, function()
			return amount
		end)
	end)

	if not success then
		warn(`Could not save yen for {player.Name}: {err}`)
	end
end

function MoneyService:Get(player: Player): number
	local value = self._values[player]
	return if value then value.Value else 0
end

function MoneyService:TrySpend(player: Player, amount: number): boolean
	if amount <= 0 or amount ~= math.floor(amount) then
		return false
	end

	local value = self._values[player]
	if not value or value.Value < amount then
		return false
	end

	value.Value -= amount
	return true
end

function MoneyService:Add(player: Player, amount: number): boolean
	if amount <= 0 or amount ~= math.floor(amount) then
		return false
	end

	local value = self._values[player]
	if not value then
		return false
	end

	value.Value += amount
	return true
end

function MoneyService:Start()
	local function onPlayerAdded(player: Player)
		self:_createValue(player, self:_load(player))
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		self:_save(player)
		self._values[player] = nil
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			self:_save(player)
		end
	end)
end

return MoneyService
