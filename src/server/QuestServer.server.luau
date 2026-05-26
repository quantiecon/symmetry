local Events = game.ReplicatedStorage.Events
local QuestInfo = require(game.ReplicatedStorage.Modules.QuestInfo)

-- Helper to get a random daily quest name
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

-- Helper to assign a new quest
local function AssignNewDailyQuest(playerData)
	local questName = GetRandomDailyQuest(QuestInfo)
	if questName then
		local goal = QuestInfo[questName].Goal or 0
		playerData.DailyQuests.Value = string.format("%s:%d,%d", questName, 0, goal)
	end
end

local function ClaimQuest(Player,playerData,QuestName)
	if QuestInfo[QuestName] then
		local QuestData = QuestInfo[QuestName]
		
		if QuestData.Reward ~= "Coins" and QuestData.Reward ~= "Gems" then
			local collection = {}
			for name, amount in string.gmatch(playerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end

			-- Add or increment drill count
			collection[QuestData.Reward] = (collection[QuestData.Reward] or 0) + 1

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			playerData.Collection.Value = newCollection

			-- Notify player of new drill
			Events.NewDrill:FireClient(Player, QuestData.Reward, 1)
		elseif QuestData.Reward == "Gems" then
			if QuestData.Amount then
				playerData.Diamonds.Value += QuestData.Amount
				Events.GemsChanged:FireClient(Player)
			end
		end
		
		local Properties = {
			Type = "Quest Complete";
			Specifics1 = Player.Character;
		}

		Events.ClientFX:FireClient(Player,Properties)
	end
end

game.Players.PlayerAdded:Connect(function(Player)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	if not PlayerData then
		repeat wait() until game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
		PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	end

	if PlayerData and PlayerData:FindFirstChild("DailyQuests") then

		-- First time assigning if empty
		if PlayerData.DailyQuests.Value == "" then
			AssignNewDailyQuest(PlayerData)
			Events.UpdateQuests:FireClient(Player)
		end
		
		if PlayerData.OneTimeQuests.Value == "" then
			local goal = QuestInfo["Discover Crafting"].Goal or 0
			PlayerData.OneTimeQuests.Value = string.format("%s:%d,%d", "Discover Crafting", 0, goal)
			Events.UpdateQuests:FireClient(Player)
		end

		Events.UpdateQuests:FireClient(Player)
		-- Check for completion and assign a new quest
		PlayerData.DailyQuests.Changed:Connect(function()
			local value = PlayerData.DailyQuests.Value
			if value == "" then return end

			local questName, progress, goal = string.match(value, "^(.-):(%d+),(%d+)$")
			progress, goal = tonumber(progress), tonumber(goal)

			if questName and progress and goal and progress >= goal then
				-- Quest completed, assign new one
				ClaimQuest(Player,PlayerData,questName)
				AssignNewDailyQuest(PlayerData)
			end
			
			Events.UpdateQuests:FireClient(Player)
		end) 
		
		PlayerData.OneTimeQuests.Changed:Connect(function()
			local value = PlayerData.OneTimeQuests.Value
			if value == "" or value == "Completed" then return end
			
			local questName, progress, goal = string.match(value, "^(.-):(%d+),(%d+)$")
			progress, goal = tonumber(progress), tonumber(goal)

			if questName and progress and goal and progress >= goal then
				-- Quest completed, assign new one
				ClaimQuest(Player,PlayerData,questName)
				
				if questName == "Discover Crafting" then
					local goal = QuestInfo["Make Money"].Goal or 0
					PlayerData.OneTimeQuests.Value = string.format("%s:%d,%d", "Make Money", 0, goal)
				elseif questName == "Make Money" then
					local goal = QuestInfo["Mine a Legendary"].Goal or 0
					PlayerData.OneTimeQuests.Value = string.format("%s:%d,%d", "Mine a Legendary", 0, goal)
				elseif questName == "Mine a Legendary" then
					if PlayerData.BoughtPlotExpansions.Value < 4 then
						local goal = QuestInfo["Expand Your Plot"].Goal or 0
						PlayerData.OneTimeQuests.Value = string.format("%s:%d,%d", "Expand Your Plot", 0, goal)
					else
						PlayerData.OneTimeQuests.Value = "Completed"
					end
				elseif questName == "Expand Your Plot" then
					PlayerData.OneTimeQuests.Value = "Completed"
				else
					local goal = QuestInfo["Discover Crafting"].Goal or 0
					PlayerData.OneTimeQuests.Value = string.format("%s:%d,%d", "Discover Crafting", 0, goal)
				end
			end
			
			Events.UpdateQuests:FireClient(Player)
		end)
	end
end)