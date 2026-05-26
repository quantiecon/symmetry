local Events = game.ReplicatedStorage.Events

local ItemInfo = require(game.ReplicatedStorage.Modules.ItemInfo)

local LootPool = {
	"Player Contract";
	"Worker Contract";
	"Aether Drill";
	"Nebula Drill";
	"Singularity Drill";
	"Void Drill";
	"Rain Totem";
	"Arcane Totem";
	"Void Totem";
	"Simple Luck Potion";
	"Advanced Luck Potion";
	"Mythical Luck Potion";
}

local function getThreeRandomLoot(pool)
	local shuffled = {}
	for i, item in ipairs(pool) do
		table.insert(shuffled, item)
	end
	-- Fisher-Yates shuffle
	for i = #shuffled, 2, -1 do
		local j = math.random(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	return table.concat({shuffled[1], shuffled[2], shuffled[3]}, ",")
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
		if PlayerData.MerchantRefresh.Value <= 0 then
			PlayerData.MerchantRefresh.Value = 1800
			PlayerData.MerchantStock.Value = getThreeRandomLoot(LootPool)
			
			Events.MerchantUpdate:FireClient(Player)
		end

		Events.MerchantUpdate:FireClient(Player)


		-- Start refresh countdown
		task.spawn(function()
			while true do
				if not Player or not PlayerData then
					break
				end
				wait(1)
				PlayerData.MerchantRefresh.Value -= 1

				if PlayerData.MerchantRefresh.Value <= 0 then
					PlayerData.MerchantRefresh.Value = 1800
					PlayerData.MerchantStock.Value =getThreeRandomLoot(LootPool)

					Events.MerchantUpdate:FireClient(Player)
				end
			end
		end)
	end
end)

Events.BuyFromMerchant.OnServerEvent:Connect(function(Player,ItemName)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	if PlayerData then
		if ItemInfo[ItemName].MerchantPrice and string.find(PlayerData.MerchantStock.Value,ItemName) then
			if PlayerData.Coins.Value >= ItemInfo[ItemName].MerchantPrice then
				PlayerData.Coins.Value -= ItemInfo[ItemName].MerchantPrice
				
				local collection = {}
				for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
					collection[name] = tonumber(amount)
				end

				-- Add or increment drill count
				collection[ItemName] = (collection[ItemName] or 0) + 1

				-- Rebuild collection string
				local newCollection = ""
				for name, amount in pairs(collection) do
					newCollection ..= name .. ":" .. amount .. ","
				end
				PlayerData.Collection.Value = newCollection

				-- Notify player of new drill
				Events.NewDrill:FireClient(Player, ItemName, 1)
				
				local dailyQuest = PlayerData:FindFirstChild("DailyQuests") --if Collect Ore Quest is there
				if dailyQuest and string.find(dailyQuest.Value, "Buy From Wandering Merchant") then
					local questName, progress, goal = string.match(dailyQuest.Value, "^(.-):(%d+),(%d+)$")
					if questName and progress and goal then
						progress = tonumber(progress) + 1
						goal = tonumber(goal)

						-- Clamp to goal
						if progress > goal then
							progress = goal
						end

						-- Update the quest string
						dailyQuest.Value = string.format("%s:%d,%d", questName, progress, goal)
					end
				end
			else
				Events.Alert:FireClient(Player,"Insufficient Funds")
			end
		end
	end
end)