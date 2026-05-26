local Events = game.ReplicatedStorage.Events
local CraftInfo = require(game.ReplicatedStorage.Modules.CraftingRecipes)

Events.Craft.OnServerEvent:Connect(function(Player, ItemName)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	if not PlayerData then return end

	local ItemData = CraftInfo[ItemName]
	if not ItemData then return end

	-- Parse player's current collection
	local collection = {}
	for name, amount in string.gmatch(PlayerData.Collection.Value or "", "([^:,]+):(%d+)") do
		collection[name] = tonumber(amount)
	end

	-- Check if player has enough ingredients with rising requirement applied
	local canCraft = true
	for i = 1, ItemData.IngredientCount do
		local split = string.split(ItemData["Ingredient" .. i], ":")
		local ingredientName = split[1]
		local baseAmount = tonumber(split[2])
		local requiredAmount = baseAmount

		if (collection[ingredientName] or 0) < requiredAmount then
			canCraft = false
			break
		end
	end

	if not canCraft then return end

	-- Deduct ingredients
	for i = 1, ItemData.IngredientCount do
		local split = string.split(ItemData["Ingredient" .. i], ":")
		local ingredientName = split[1]
		local baseAmount = tonumber(split[2])
		local requiredAmount = baseAmount

		collection[ingredientName] = (collection[ingredientName] or 0) - requiredAmount
	end

	-- Add crafted item
	collection[ItemName] = (collection[ItemName] or 0) + 1

	-- Rebuild collection string
	local newCollection = ""
	for name, amount in pairs(collection) do
		if amount > 0 then
			newCollection ..= name .. ":" .. amount .. ","
		end
	end
	PlayerData.Collection.Value = newCollection

	-- Fire new item event
	Events.NewDrill:FireClient(Player, ItemName, 1)

	-- Daily Quest Update
	local dailyQuest = PlayerData:FindFirstChild("DailyQuests")
	if dailyQuest and string.find(dailyQuest.Value, "Craft an Item") then
		local questName, progress, goal = string.match(dailyQuest.Value, "^(.-):(%d+),(%d+)$")
		if questName and progress and goal then
			progress = math.min(tonumber(progress) + 1, tonumber(goal))
			dailyQuest.Value = string.format("%s:%d,%d", questName, progress, goal)
		end
	end

	-- One-Time Quest Update
	local oneTimeQuest = PlayerData:FindFirstChild("OneTimeQuests")
	if oneTimeQuest and string.find(oneTimeQuest.Value, "Discover Crafting") then
		local questName, progress, goal = string.match(oneTimeQuest.Value, "^(.-):(%d+),(%d+)$")
		if questName and progress and goal then
			progress = math.min(tonumber(progress) + 1, tonumber(goal))
			oneTimeQuest.Value = string.format("%s:%d,%d", questName, progress, goal)
		end
	end
end)