local Events = game.ReplicatedStorage.Events
local Ores = game.ServerStorage.Ores
local random = Random.new()

local ItemInfo = require(game.ReplicatedStorage.Modules.ItemInfo)

-- Setup ore chances and colors
local BaseChances = {
	{"Stoneite", 2, Color3.fromRGB(157, 255, 121)},
	{"Copper", 3, Color3.fromRGB(157, 255, 121)},
	{"Iron", 5, Color3.fromRGB(157, 255, 121)},
	{"Coal", 7, Color3.fromRGB(157, 255, 121)},
	{"Tin", 10, Color3.fromRGB(157, 255, 121)},
	{"Claystone", 15, Color3.fromRGB(157, 255, 121)},
	{"Sandcrystal", 20, Color3.fromRGB(157, 255, 121)},
	{"Silver", 200, Color3.fromRGB(90, 178, 255)},
	{"Glimmerite", 500, Color3.fromRGB(90, 178, 255)},
	{"Gold", 800, Color3.fromRGB(90, 178, 255)},
--	{"Shade Remnant", 500, Color3.fromRGB(90, 178, 255)},
	{"Pyronite", 1200, Color3.fromRGB(90, 178, 255)},
	{"Shadowite", 5000, Color3.fromRGB(178, 115, 255)},
	{"Obscurite", 8000, Color3.fromRGB(178, 115, 255)},
	{"Cryozite", 12000, Color3.fromRGB(178, 115, 255)},
--	{"Abyssal Remnant", 10000, Color3.fromRGB(178, 115, 255)},
	{"Starstruck", 25000, Color3.fromRGB(178, 115, 255)},
	{"Gem", 9000, Color3.fromRGB(202, 128, 255)},
	{"Demonite", 50000, Color3.fromRGB(255, 171, 103)},
	{"Aethersteel", 100000, Color3.fromRGB(255, 171, 103)},
	{"Starcore", 1000000, Color3.fromRGB(255, 66, 69)},
	{"Blue Giant", 2500000, Color3.fromRGB(255, 66, 69)},
	{"Solaryte", 10000000, Color3.fromRGB(255, 249, 187)},
	{"Eclipsium", 25000000, Color3.fromRGB(255, 249, 187)},
	{"Starforged", 100000000, Color3.fromRGB(255, 249, 187)},
	{"Voidstar", 1000000000, Color3.fromRGB(0, 0, 0)},
	{"Hellcore", 10000000000, Color3.fromRGB(0, 0, 0)},
	
--	{"Pearl", 500, Color3.fromRGB(90, 178, 255)},
--	{"Coral", 2500, Color3.fromRGB(90, 178, 255)},
--	{"Seaswept Coral", 9500, Color3.fromRGB(178, 115, 255)},
--	{"Pearl of the Sea", 450000, Color3.fromRGB(255, 66, 69)},
--	{"Heart of the Sea", 15000000, Color3.fromRGB(255, 249, 187)},
}

local Chances = table.clone(BaseChances)

local RainOres = {
	{"Watercrystal", 20, Color3.fromRGB(157, 255, 121)},
	{"Miststeel", 700, Color3.fromRGB(90, 178, 255)},
	{"Stormvein", 75000, Color3.fromRGB(255, 171, 103)},
}

local ArcaneOres = {
	{"Runeglass", 50, Color3.fromRGB(157, 255, 121)},
	{"Atherite", 555, Color3.fromRGB(178, 115, 255)},
	{"Arcana", 55555, Color3.fromRGB(255, 171, 103)},
	{"Arcana Unbound", 250000, Color3.fromRGB(255, 66, 69)},
}

local NatureOres = {
	{"Mossrock", 250, Color3.fromRGB(157, 255, 121)},
	{"Rootcrystal", 2500, Color3.fromRGB(178, 115, 255)},
	{"Verdanite", 75000, Color3.fromRGB(255, 171, 103)},
	{"Gaia's Heart", 7500000, Color3.fromRGB(255, 66, 69)},
}

local VoidOres = {
	{"Gloomstone", 100, Color3.fromRGB(90, 178, 255)},
	{"Dustlode", 1500, Color3.fromRGB(90, 178, 255)},
	{"Abyssite", 99999, Color3.fromRGB(255, 171, 103)},
	{"Lodestar", 10000000, Color3.fromRGB(255, 249, 187)},
}


-- Select ore by rolling from rarest to commonest with modifier
local function selectWeightedOre(modifier)
	-- Calculate weights based on inverse chance (rarer ores have smaller chance, so weight is 1/chance)
	local weights = {}
	local totalWeight = 0
	for i, oreData in ipairs(Chances) do
		local oreChance = oreData[2]
		-- Apply modifier to oreChance (lower chance means higher rarity)
		local adjustedChance = math.max(1, oreChance / modifier)
		local weight = 1 / adjustedChance
		weights[i] = weight
		totalWeight += weight
	end

	-- Pick random number in [0, totalWeight)
	local pick = random:NextNumber() * totalWeight
	local cumulative = 0

	for i, weight in ipairs(weights) do
		cumulative += weight
		if pick <= cumulative then
			return i
		end
	end

	return 1 -- fallback to common ore
end
local function parseInventoryString(inventoryStr)
	local inventory = {}
	for name, amount in inventoryStr:gmatch("([^:,]+):(%d+),") do
		inventory[name] = tonumber(amount)
	end
	return inventory
end

local function buildInventoryString(inventory)
	local result = ""
	for name, amount in pairs(inventory) do
		result ..= name .. ":" .. amount .. ","
	end
	return result
end

local function addRolledOresToInventory(inventoryStr, RolledOres)
	local inventory = parseInventoryString(inventoryStr)
	for oreName, amount in pairs(RolledOres) do
		inventory[oreName] = (inventory[oreName] or 0) + amount
	end
	return buildInventoryString(inventory)
end

-- Processes collected ores with modifiers
local function processCollectedOres(count, DrillData, Player)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name .. "Data")
	if not PlayerData then return end

	local RolledGems = 0
	local RolledOres = {}
	local processed = 0
	local batchSize = 1000

	-- Get modifiers
	local OreYield = DrillData:FindFirstChild("OreYield") and DrillData.OreYield.Value or 1
	local Luck = (Player.Character and Player.Character:FindFirstChild("Luck") and Player.Character.Luck.Value) or 1
	if PlayerData.LuckMultiplier then
		Luck = Luck * PlayerData.LuckMultiplier.Value
	end
	local combinedModifier = Luck * OreYield
	
	if Player:FindFirstChild("Simple Luck Boost") then
		combinedModifier = combinedModifier * 1.5
	end
	if Player:FindFirstChild("Advanced Luck Boost") then
		combinedModifier = combinedModifier * 2
	end
	if Player:FindFirstChild("Mythical Luck Boost") then
		combinedModifier = combinedModifier * 4
	end
	
	if PlayerData.VIP.Value == true then
		combinedModifier = combinedModifier * 1.1
	end
	
	if PlayerData.LuckMultiplier then
		combinedModifier = combinedModifier * PlayerData.LuckMultiplier.Value
	end
	
	print(combinedModifier)
	
	if Player.Character:FindFirstChild("OreYield") and Player.Character:FindFirstChild("OreYield").Value > 1 then
		count = math.floor(count * Player.Character:FindFirstChild("OreYield").Value)
	end

	while processed < count do
		local currentBatch = math.min(batchSize, count - processed)
		for i = 1, currentBatch do
			local index = selectWeightedOre(combinedModifier)
			local oreName = Chances[index][1]
			if oreName == "Gem" then
				RolledGems += 1
			else
				RolledOres[oreName] = (RolledOres[oreName] or 0) + 1
			end
		end
		processed += currentBatch
		task.wait()
	end

	
	for oreName, amount in pairs(RolledOres) do
		local info = ItemInfo[oreName]
		local rarity = info and info.Rarity or "Unknown"

		if rarity == "Legendary" or rarity == "Celestial" or rarity == "Mythical" or rarity == "Secret" then
			if combinedModifier >= 6 and rarity == "Legendary" then 
				print("didnt display")
			else
				local oreColorHex
				local formattedChance = ""

				for _, data in ipairs(Chances) do
					if data[1] == oreName then
						local c = data[3]
						oreColorHex = string.format("#%02X%02X%02X", c.R * 255, c.G * 255, c.B * 255)
						formattedChance = data[2]
						break
					end
				end

				if oreColorHex then
					local messageData = {
						PlayerName = Player.Name,
						Amount = amount,
						OreName = oreName,
						FormattedChance = formattedChance,
						Color = oreColorHex,
					}
					Events:WaitForChild("BroadcastOreMessage"):FireAllClients(messageData)
				end
				
				if rarity == "Secret" then
					Events.Cutscene:FireClient(Player,"Secret")
				end
			end
			
			if rarity == "Legendary" then
				local OneTimeQuests = PlayerData:FindFirstChild("OneTimeQuests")
				if OneTimeQuests then
					local questName, progress, goal = string.match(OneTimeQuests.Value, "^(.-):(%d+),(%d+)$")
					if questName and (questName == "Mine a Legendary" or questName == "Legend Hunter") then
						if progress and goal then
							progress = math.min(tonumber(progress) + 1, tonumber(goal))
							OneTimeQuests.Value = string.format("%s:%d,%d", questName, progress, goal)
						end
					end
				end
			end
		end
	end
	Events.NewItems:FireClient(Player, RolledOres)
	if RolledGems ~= 0 then
		PlayerData.Diamonds.Value += RolledGems
		Events.GemsChanged:FireClient(Player)
	end
	
	local dailyQuest = PlayerData:FindFirstChild("DailyQuests")
	if dailyQuest and string.find(dailyQuest.Value, "Collect Ores") then
		local questName, progress, goal = string.match(dailyQuest.Value, "^(.-):(%d+),(%d+)$")
		if questName and progress and goal then
			progress = math.min(tonumber(progress) + processed, tonumber(goal))
			dailyQuest.Value = string.format("%s:%d,%d", questName, progress, goal)
		end
	end

	-- Main quest: Dedicated Miner (50,000 ores from drills)
	local oneTimeQuest = PlayerData:FindFirstChild("OneTimeQuests")
	if oneTimeQuest then
		local questName, progress, goal = string.match(oneTimeQuest.Value, "^(.-):(%d+),(%d+)$")
		if questName == "Dedicated Miner" and progress and goal then
			progress = math.min(tonumber(progress) + processed, tonumber(goal))
			oneTimeQuest.Value = string.format("%s:%d,%d", questName, progress, goal)
		end
	end
	
	if PlayerData:FindFirstChild("Collection") then
		local updatedInventory = addRolledOresToInventory(PlayerData.Collection.Value, RolledOres)
		PlayerData.Collection.Value = updatedInventory
	end
end

-- Event connection
Events.Collect.OnServerEvent:Connect(function(Player, Drill)
	local DrillData = Drill:FindFirstChild("Data")
	if not DrillData then return end
	if DrillData:FindFirstChild("Owner").Value ~= Player.Name then return end
	if DrillData:FindFirstChild("Collected").Value == 0 then return end

	local count = DrillData.Collected.Value
	DrillData.Collected.Value = 0

	task.spawn(function()
		processCollectedOres(count, DrillData, Player)
	end)
end)

local Weather = game.Workspace:WaitForChild("Weather")

Weather.Changed:Connect(function()
	if Weather.Value == "Rain" then
		Chances = table.clone(BaseChances)
		for _, rainOre in ipairs(RainOres) do
			table.insert(Chances, rainOre)
		end
		print("[Weather] Rain active - rain ores added to loot pool.")
	elseif Weather.Value == "Arcane" then
		Chances = table.clone(BaseChances)
		for _, arcaneOre in ipairs(ArcaneOres) do
			table.insert(Chances, arcaneOre)
		end
		print("[Weather] Arcane active - arcane ores added to loot pool.")
	elseif Weather.Value == "Nature" then
		Chances = table.clone(BaseChances)
		for _, natureOre in ipairs(NatureOres) do
			table.insert(Chances, natureOre)
		end
		print("[Weather] Nature active - nature ores added to loot pool.")
	elseif Weather.Value == "Void" then
		Chances = table.clone(BaseChances)
		for _, voidOre in ipairs(VoidOres) do
			table.insert(Chances, voidOre)
		end
		print("[Weather] Void active - void ores added to loot pool.")
	elseif Weather.Value == "Normal" then
		Chances = table.clone(BaseChances)
		print("[Weather] Non-rain weather - rain ores removed from loot pool.")
	end
end)