local Events = game.ReplicatedStorage.Events

--[[local Chances = {
	{"Pyronite", 10, Color3.fromRGB(90, 178, 255)},
	{"Shadowite", 20, Color3.fromRGB(178, 115, 255)},
	{"Obscurite", 20, Color3.fromRGB(178, 115, 255)},
	{"Cryozite", 30, Color3.fromRGB(178, 115, 255)},
	{"Demonite", 50, Color3.fromRGB(255, 171, 103)},
	{"Aethersteel", 50, Color3.fromRGB(255, 171, 103)},
} --]]

local EasyChances = {
	"Pyronite"
}
local MediumChances = {
	"Shadowite",
	"Obscurite",
	"Cryozite",
}
local HardChances = {
	"Demonite",
	"Aethersteel",
}



local Prices = {
	["Pyronite"] = 1,
	["Shadowite"] = 2,
	["Obscurite"] = 2,
	["Cryozite"] = 3,
	["Demonite"] = 5,
	["Aethersteel"] = 5,
}

local LootPool = {
	{"Reef Roberta", 2, "Worker"},
	{"Coral Drill", 3, "Drill"},
	{"Captain Brine", 10, "Worker"},
	{"Poseidon", 90, "Worker"},
	{"Tidecaller Drill", 200, "Drill"},
}

local function PickFromPool(Player)
	local totalWeight = 0
	local weights = {}

	local LuckObject = Player.Character and Player.Character:FindFirstChild("Luck")
	local Luck = (LuckObject and LuckObject.Value) or 1

	-- Calculate weights
	for _, data in ipairs(LootPool) do
		local chance = data[2]
		local weight = 1 / chance
		table.insert(weights, weight)
		totalWeight += weight
	end

	-- Pick a random point
	local randomPoint = math.random() * totalWeight
	local current = 0

	for i, weight in ipairs(weights) do
		current += weight
		if randomPoint <= current then
			return LootPool[i]
		end
	end
end

local function getOneFromEachDifficulty()
	local function pickRandom(list)
		return list[math.random(1, #list)]
	end

	local easyOre = pickRandom(EasyChances)
	local mediumOre = pickRandom(MediumChances)
	local hardOre = pickRandom(HardChances)

	local stock = {
		easyOre .. ":" .. math.random(8, 10),
		mediumOre .. ":" .. math.random(8, 10),
		hardOre .. ":" .. math.random(8, 10),
	}

	return table.concat(stock, ",") .. "," -- comma at end to match your parsing logic
end

game.Players.PlayerAdded:Connect(function(Player)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	if not PlayerData then
		repeat wait()
			PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
		until PlayerData
	end

	if PlayerData then
		-- Initial roll if needed
		if PlayerData.EventRefresh.Value <= 0 then
			PlayerData.EventRefresh.Value = 300
			PlayerData.EventStock.Value = getOneFromEachDifficulty()
			
			Events.UpdateEventStock:FireClient(Player)
		end
		
		Events.UpdateEventStock:FireClient(Player)
		

		
		-- Start refresh countdown
		task.spawn(function()
			while true do
				if not Player or not PlayerData then
					break
				end
				wait(1)
				PlayerData.EventRefresh.Value -= 1

				if PlayerData.EventRefresh.Value <= 0 then
					PlayerData.EventRefresh.Value = 300
					PlayerData.EventStock.Value = getOneFromEachDifficulty()
					
					Events.UpdateEventStock:FireClient(Player)
				end
			end
		end)
	end
end)

Events.EventTrade.OnServerEvent:Connect(function(Player, Ore)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	if not PlayerData then
		repeat wait()
			PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
		until PlayerData
	end

	if not PlayerData then return end

	local SplitStock = string.split(PlayerData.EventStock.Value, ",")
	for _, entry in ipairs(SplitStock) do
		if entry ~= "" then
			local OreName, RequiredAmount = unpack(string.split(entry, ":"))
			RequiredAmount = tonumber(RequiredAmount)

			if OreName == Ore then
				-- Parse current Collection
				local collection = {}
				for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
					collection[name] = tonumber(amount)
				end

				local ownedAmount = collection[Ore] or 0
				if ownedAmount >= RequiredAmount then
					-- Deduct ore
					collection[Ore] = ownedAmount - RequiredAmount
					if collection[Ore] <= 0 then
						collection[Ore] = nil
					end

					-- Add to Summer Pack
					collection["Summer Pack"] = (collection["Summer Pack"] or 0) + 1

					-- Rebuild collection string
					local newCollection = ""
					for name, amount in pairs(collection) do
						newCollection ..= name .. ":" .. amount .. ","
					end
					PlayerData.Collection.Value = newCollection
					
					-- Remove the purchased ore from EventStock
					local newStock = ""
					for _, otherEntry in ipairs(SplitStock) do
						if otherEntry ~= "" then
							local n, _ = unpack(string.split(otherEntry, ":"))
							if n ~= Ore then
								newStock ..= otherEntry .. ","
							end
						end
					end
					PlayerData.EventStock.Value = newStock
					
					Events.UpdateEventStock:FireClient(Player)

					-- Optional: fire UI update event if needed
					Events.NewDrill:FireClient(Player, "Summer Pack", 1)

					break -- Stop after match
				end
			end
		end
	end
end)

Events.OpenEventPack.Event:Connect(function(Player)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	if not PlayerData then return end

	local PullData = PickFromPool(Player)
	local itemName = PullData[1]
	local itemType = PullData[3]
	print(itemName)

	local Properties = {
		Type = "Summer Pack",
		Specifics1 = itemName,
	}
	Events.ClientFX:FireClient(Player, Properties)

	if itemType == "Worker" then
		local collectionTable = {}
		for name, amount in string.gmatch(PlayerData.CollectedWorkers.Value or ",", "([^:,]+):(%d+),") do
			collectionTable[name] = tonumber(amount)
		end
		collectionTable[itemName] = (collectionTable[itemName] or 0) + 1

		-- Update worker collection string
		local newCollection = ""
		for name, amount in pairs(collectionTable) do
			newCollection ..= name .. ":" .. amount .. ","
		end
		PlayerData.CollectedWorkers.Value = newCollection

		if Player:FindFirstChild("WorkerCapacity") then
			Player.WorkerCapacity.Value += 1
			Events.UpdateWorkerCapacity:FireClient(Player)
		end
		task.delay(2.2,function()
			Events.Alert:FireClient(Player,"You have rolled "..itemName..".")
		end)
		
		Events.RebuildWorkerUI:FireClient(Player, {
			EquippedWorkers = PlayerData.EquippedWorkers.Value,
			CollectedWorkers = PlayerData.CollectedWorkers.Value,
		})

	elseif itemType == "Drill" then
		-- Update drill collection
		local collection = {}
		for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
			collection[name] = tonumber(amount)
		end
		collection[itemName] = (collection[itemName] or 0) + 1

		-- Rebuild collection string
		local newCollection = ""
		for name, amount in pairs(collection) do
			newCollection ..= name .. ":" .. amount .. ","
		end
		PlayerData.Collection.Value = newCollection

		task.delay(3,function()
			-- Trigger UI/effect if needed
			Events.NewDrill:FireClient(Player, itemName, 1)
		end)

		local Properties = {
			Type = "Drill",
			Specifics1 = itemName,
		}
		Events.ClientFX:FireClient(Player, Properties)
	end
end)