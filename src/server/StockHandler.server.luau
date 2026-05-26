local Players = game:GetService("Players")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Events = ReplicatedStorage:WaitForChild("Events")
local ItemInfo = require(ReplicatedStorage.Modules.ItemInfo)

local stockLifetime = 180 -- 5 minutes (300 seconds)
local stockKey = "GlobalDrillLineup"
local playerStockKeyPrefix = "DrillLimit_"
local refreshTimestampKey = "NextDrillRefresh"

-- RemoteFunctions
local GlobalDrillStockRequest = Events:WaitForChild("GlobalDrillStockRequest")
local RequestRefreshTimer = Events:WaitForChild("RequestRefreshTimer")


-- Drill definitions
local drillList = {
	["Standard Drill"] = { Chance = 1 },
	["Reinforced Drill"] = { Chance = 1 },
	["Twin Drill"] = { Chance = 1 },
	["Compact Drill"] = { Chance = 1 },
	["Charged Drill"] = { Chance = 2 },
	["Surge Drill"] = { Chance = 3 },
	["Fusion Drill"] = { Chance = 5 },
	["Phase Drill"] = { Chance = 8 },
	["KinetiCore Drill"] = { Chance = 16 },
	["Aether Drill"] = { Chance = 20 },
	["Nebula Drill"] = { Chance = 25 },
	["Singularity Drill"] = { Chance = 25 },
	["Quantum Drill"] = { Chance = 60 },
	["OmniQuantum Drill"] = { Chance = 90 },
	["Eclipse Drill"] = { Chance = 125 },
	["Heavencaller Drill"] = { Chance = 125 },
}

local lastRefresh = os.time()

-- In-memory cache of player drill limits: player.UserId => { drillName = amount }
local playerDrillLimits = {}

local function refreshGlobalDrillLineup()
	local store = MemoryStoreService:GetSortedMap(stockKey)
	local lockKey = "DrillLineupLock"

	-- Attempt to acquire lock (so only one server refreshes)
	local success, gotLock = pcall(function()
		return store:UpdateAsync(lockKey, function(old)
			if old then return nil else return true end
		end, stockLifetime)
	end)

	if not success or not gotLock then
		print("Another server already refreshed the drill lineup.")
		return
	end

	print("This server is refreshing the global drill lineup.")

	-- when you acquire the lock
	local refreshSeed = os.time()  -- this is the one true seed
	local metaMap = MemoryStoreService:GetSortedMap("DrillMeta")

	-- write it immediately for everyone to read
	pcall(function()
		metaMap:SetAsync(refreshTimestampKey, refreshSeed, stockLifetime)
	end)

	-- now derive your RNG from that exact seed
	local rng = Random.new(refreshSeed)

	for drillName, drillData in pairs(drillList) do
		local appears = rng:NextInteger(1, drillData.Chance) == 1
		pcall(function()
			store:SetAsync(drillName, appears and 1 or 0, stockLifetime)
		end)
	end

	-- Save the refreshSeed globally for reference
	pcall(function()
		local metaMap = MemoryStoreService:GetSortedMap("DrillMeta")
		metaMap:SetAsync(refreshTimestampKey, refreshSeed, stockLifetime)
	end)

	-- Also store a global timestamp
	pcall(function()
		store:SetAsync("LastDrillRefresh", os.time(), stockLifetime)
	end)
	
	Events.MainAlert:FireAllClients("Drill shop has restocked!",Color3.new(0.384314, 1, 0.341176))
end

local function getNextRefreshTimestamp()
	local metaMap = MemoryStoreService:GetSortedMap("DrillMeta")
	local success, timestamp = pcall(function()
		return metaMap:GetAsync(refreshTimestampKey)
	end)
	return success and timestamp or nil
end

local function getCurrentGlobalLineup()
	local map = MemoryStoreService:GetSortedMap(stockKey)
	local available = {}
	for drillName in pairs(drillList) do
		local success, value = pcall(function()
			return map:GetAsync(drillName)
		end)
		if success and value == 1 then
			available[drillName] = true
		end
	end
	return available
end

local function setupPlayerDrillLimits(player)
	local key = playerStockKeyPrefix .. player.UserId
	local map = MemoryStoreService:GetSortedMap("DrillLimits")

	local currentSeed = getNextRefreshTimestamp() or os.time()
	local success, json = pcall(function()
		return map:GetAsync(key)
	end)

	if success and json then
		local savedLimits = HttpService:JSONDecode(json)

		-- ✅ If seed matches, do NOT regenerate — use saved limits directly
		if savedLimits._seed == currentSeed then
			playerDrillLimits[player.UserId] = savedLimits
			return
		end
	end

	-- ❗ Otherwise, regenerate for new refresh
	local lineup = getCurrentGlobalLineup()
	local rng = Random.new(currentSeed)
	local newLimits = {}

	for drillName in pairs(lineup) do
		newLimits[drillName] = (drillList[drillName].Chance > 900) and 1 or rng:NextInteger(3, 5)
	end
	newLimits._seed = currentSeed

	playerDrillLimits[player.UserId] = newLimits

	local encoded = HttpService:JSONEncode(newLimits)
	pcall(function()
		map:SetAsync(key, encoded, stockLifetime)
	end)
end

-- Cleanup player limits cache on leave
Players.PlayerRemoving:Connect(function(player)
	playerDrillLimits[player.UserId] = nil
end)

Players.PlayerAdded:Connect(setupPlayerDrillLimits)

-- Remote function: return player's drill limits table
GlobalDrillStockRequest.OnServerInvoke = function(player)
	local limits = playerDrillLimits[player.UserId]
	if not limits then return {} end
	return limits
end

RequestRefreshTimer.OnServerInvoke = function()
	local store = MemoryStoreService:GetSortedMap(stockKey)
	local success, last = pcall(function()
		return store:GetAsync("LastDrillRefresh")
	end)
	if success and last then
		local elapsed = os.time() - last
		return math.max(0, stockLifetime - elapsed)
	else
		return stockLifetime -- fallback
	end
end

Events.BuyDrillCoin.OnServerEvent:Connect(function(Player, DrillName)
	if not ItemInfo[DrillName] then return end

	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name .. "Data")
	if not PlayerData or PlayerData.Coins.Value < ItemInfo[DrillName].Coins then 
		Events.Alert:FireClient(Player,"Insufficient Funds!")
		return
	end

	local limits = playerDrillLimits[Player.UserId]
	if not limits or not limits[DrillName] or limits[DrillName] <= 0 then
		Events.Alert:FireClient(Player,"Drill is not in stock!")
		warn("Drill not in stock or limit reached for player:", DrillName)
		return
	end

	-- Deduct coins
	PlayerData.Coins.Value -= ItemInfo[DrillName].Coins

	-- Add drill to player's collection
	local collectionTable = {}
	for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
		collectionTable[name] = tonumber(amount)
	end
	collectionTable[DrillName] = (collectionTable[DrillName] or 0) + 1

	-- Update collection string
	local newCollection = ""
	for name, amount in pairs(collectionTable) do
		newCollection ..= name .. ":" .. amount .. ","
	end
	PlayerData.Collection.Value = newCollection

	-- Deduct 1 stock from the player's drill limit
	limits[DrillName] -= 1

	-- 🔒 Prepare a clean save table while preserving the _seed
	local saveTable = {}
	for name, value in pairs(limits) do
		saveTable[name] = value
	end

	-- ✅ Save updated limits (including the refresh _seed)
	local map = MemoryStoreService:GetSortedMap("DrillLimits")
	local key = playerStockKeyPrefix .. Player.UserId
	local encoded = HttpService:JSONEncode(saveTable)

	pcall(function()
		map:SetAsync(key, encoded, stockLifetime)
	end)

	-- Feedback to client
	print("Player bought drill:", DrillName)
	Events.NewDrill:FireClient(Player, DrillName, 1)
	Events.BuyDrillCoin:FireClient(Player)
end)

task.spawn(function()
	while true do
		local nextRefresh = getNextRefreshTimestamp()
		local now = os.time()

		if not nextRefresh or now >= nextRefresh then
			refreshGlobalDrillLineup()

			-- Refresh player drill limits like before
			local lineup = getCurrentGlobalLineup()
			local map = MemoryStoreService:GetSortedMap("DrillLimits")

			local seed = getNextRefreshTimestamp()
			if not seed then
				warn("No refresh seed found, defaulting to os.time()")
				seed = os.time()
			end

			for _, player in ipairs(Players:GetPlayers()) do
				local existing = playerDrillLimits[player.UserId]
				if existing and existing._seed == seed then
					-- 👍 Already using correct refresh, do not overwrite
					continue
				end

				local rng = Random.new(seed)
				local newLimits = {}
				for drillName in pairs(lineup) do
					newLimits[drillName] = (drillList[drillName].Chance > 900) and 1 or rng:NextInteger(3, 5)
				end
				newLimits._seed = seed

				playerDrillLimits[player.UserId] = newLimits
				local encoded = HttpService:JSONEncode(newLimits)
				pcall(function()
					map:SetAsync(playerStockKeyPrefix .. player.UserId, encoded, stockLifetime)
				end)

				Events.BuyDrillCoin:FireClient(player)
			end
		end

		task.wait(1)
	end
end)