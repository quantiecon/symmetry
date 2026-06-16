local Events = game.ReplicatedStorage.Events
local QuestInfo = require(game.ReplicatedStorage.Modules.QuestInfo)

local QUEST_CHAIN = {
	"Discover Crafting",
	"Make Money",
	"Mine a Legendary",
	"Expand Your Plot",
	"Grand Craftsman",
	"The Rich",
	"Legend Hunter",
	"Dedicated Miner",
}

local function GetRandomDailyQuest(info)
	local dailyQuests = {}
	for questName, questData in pairs(info) do
		if questData.Daily == true then
			table.insert(dailyQuests, questName)
		end
	end
	if #dailyQuests > 0 then
		return dailyQuests[math.random(1, #dailyQuests)]
	end
	return nil
end

local function AssignNewDailyQuest(playerData)
	local questName = GetRandomDailyQuest(QuestInfo)
	if questName then
		local goal = QuestInfo[questName].Goal or 0
		playerData.DailyQuests.Value = string.format("%s:%d,%d", questName, 0, goal)
	end
end

local function ClaimQuest(Player, playerData, QuestName)
	local QuestData = QuestInfo[QuestName]
	if not QuestData then return end

	if QuestData.Reward == "Coins" then
		if QuestData.Amount then
			playerData.Coins.Value += QuestData.Amount
			Events.Profit:FireClient(Player, QuestData.Amount)
		end
	elseif QuestData.Reward == "Gems" then
		if QuestData.Amount then
			playerData.Diamonds.Value += QuestData.Amount
			Events.GemsChanged:FireClient(Player)
		end
	else
		-- Item reward
		local collection = {}
		for name, amount in string.gmatch(playerData.Collection.Value or ",", "([^:,]+):(%d+),") do
			collection[name] = tonumber(amount)
		end
		collection[QuestData.Reward] = (collection[QuestData.Reward] or 0) + 1
		local newCollection = ""
		for name, amount in pairs(collection) do
			newCollection ..= name .. ":" .. amount .. ","
		end
		playerData.Collection.Value = newCollection
		Events.NewDrill:FireClient(Player, QuestData.Reward, 1)
	end

	local Properties = {
		Type = "Quest Complete";
		Specifics1 = Player.Character;
	}
	Events.ClientFX:FireClient(Player, Properties)
end

local function getNextChainQuest(currentQuestName)
	for i, name in ipairs(QUEST_CHAIN) do
		if name == currentQuestName then
			return QUEST_CHAIN[i + 1]
		end
	end
	return nil
end

game.Players.PlayerAdded:Connect(function(Player)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	if not PlayerData then
		repeat wait() until game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
		PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	end

	if not PlayerData then return end
	if not PlayerData:FindFirstChild("DailyQuests") then return end

	-- Assign daily quest if empty
	if PlayerData.DailyQuests.Value == "" then
		AssignNewDailyQuest(PlayerData)
		Events.UpdateQuests:FireClient(Player)
	end

	-- Assign first main quest if empty
	if PlayerData.OneTimeQuests.Value == "" then
		local firstQuest = QUEST_CHAIN[1]
		local goal = QuestInfo[firstQuest].Goal or 0
		PlayerData.OneTimeQuests.Value = string.format("%s:%d,%d", firstQuest, 0, goal)
		Events.UpdateQuests:FireClient(Player)
	end

	Events.UpdateQuests:FireClient(Player)

	-- Watch daily quest
	PlayerData.DailyQuests.Changed:Connect(function()
		local value = PlayerData.DailyQuests.Value
		if value == "" then return end

		local questName, progress, goal = string.match(value, "^(.-):(%d+),(%d+)$")
		progress, goal = tonumber(progress), tonumber(goal)

		if questName and progress and goal and progress >= goal then
			ClaimQuest(Player, PlayerData, questName)
			AssignNewDailyQuest(PlayerData)
		end

		Events.UpdateQuests:FireClient(Player)
	end)

	-- Watch main quest chain
	PlayerData.OneTimeQuests.Changed:Connect(function()
		local value = PlayerData.OneTimeQuests.Value
		if value == "" or value == "Completed" then return end

		local questName, progress, goal = string.match(value, "^(.-):(%d+),(%d+)$")
		progress, goal = tonumber(progress), tonumber(goal)

		if questName and progress and goal and progress >= goal then
			ClaimQuest(Player, PlayerData, questName)

			local nextQuest = getNextChainQuest(questName)
			if nextQuest then
				local nextGoal = QuestInfo[nextQuest].Goal or 0
				PlayerData.OneTimeQuests.Value = string.format("%s:%d,%d", nextQuest, 0, nextGoal)
			else
				PlayerData.OneTimeQuests.Value = "Completed"
			end
		end

		Events.UpdateQuests:FireClient(Player)
	end)
end)
