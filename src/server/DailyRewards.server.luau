local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local PlayerDataFolder = ServerStorage:WaitForChild("PlayerData")
local Events = game.ReplicatedStorage.Events

local function giveReward(player, day)
	-- Customize rewards per day (1–7)
	local rewards = {
		"100 Coins",
		"10 Gems",
		"500 Coins",
		"Worker Contract",
		"1000 Coins",
		"2500 Coins",
		"Legendary Drill+Gems",
	}
	local reward = rewards[math.clamp(day, 1, #rewards)]
	print(player.Name .. " received: " .. reward)
	
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
	if PlayerData then
		PlayerData.DailySpinTickets.Value += 1
		Events.Alert:FireClient(player,"+1 Daily Spin Ticket")
		
		if PlayerData.VIP.Value == true then
			PlayerData.DailySpinTickets.Value += 1
			Events.Alert:FireClient(player,"+1 Daily Spin Ticket")
		end
		
		if reward == "100 Coins" then
			PlayerData.Coins.Value += 10000
			Events.Profit:FireClient(player,10000)
		elseif reward == "10 Gems" then
			local collection = {}
			for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end
			collection["Impulse Driver Drill"] = (collection["Impulse Driver Drill"] or 0) + 1

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.Collection.Value = newCollection

			-- Trigger UI/effect if needed
			Events.NewDrill:FireClient(player, "Impulse Driver Drill", 1)
		elseif reward == "500 Coins" then
			PlayerData.Coins.Value += 100000
			Events.Profit:FireClient(player,100000)
		elseif reward == "Worker Contract" then
			local collection = {}
			for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end
			collection["Worker Contract"] = (collection["Worker Contract"] or 0) + 1

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.Collection.Value = newCollection

			-- Trigger UI/effect if needed
			Events.NewDrill:FireClient(player, "Worker Contract", 1)
		elseif reward == "1000 Coins" then
			PlayerData.Coins.Value += 5000000
			Events.Profit:FireClient(player,5000000)
		elseif reward == "2500 Coins" then
			PlayerData.Coins.Value += 10000000
			Events.Profit:FireClient(player,10000000)
		elseif reward == "Legendary Drill+Gems" then
			PlayerData.Diamonds.Value += 50
			
			local collection = {}
			for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end
			collection["Aether Drill"] = (collection["Aether Drill"] or 0) + 1

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.Collection.Value = newCollection

			-- Trigger UI/effect if needed
			Events.NewDrill:FireClient(player, "Aether Drill", 1)
		end
	end
end

local function setupPlayerRewardData(player)
	local folder = PlayerDataFolder:FindFirstChild(player.Name.."Data")
	if not folder then
		repeat task.wait()
			folder = PlayerDataFolder:FindFirstChild(player.Name.."Data")
		until folder
	end

	if folder then
		local currentTime = os.time()

		local lastClaimed = folder:FindFirstChild("LastClaimedTimestamp")
		local rewardStreak = folder:FindFirstChild("RewardStreak")
		local canClaimDaily = folder:FindFirstChild("CanClaimDaily")

		local secondsInDay = 86400
		local timeSinceLastClaim = currentTime - lastClaimed.Value

		if lastClaimed.Value == 0 then
			-- First ever claim
			canClaimDaily.Value = true
		elseif timeSinceLastClaim >= secondsInDay then
			-- It's a new day, but wait for claim to increment streak
			canClaimDaily.Value = true
		else
			-- Already claimed today
			canClaimDaily.Value = false
		end

		Events.UpdateDailyRewardUI:FireClient(player, {
			CanClaim = canClaimDaily.Value,
			Streak = rewardStreak.Value
		})
	end
end

-- Hook into player joining (or wherever you check for rewards)
Players.PlayerAdded:Connect(function(player)
	local folder = PlayerDataFolder:FindFirstChild(player.Name.."Data")
	if not folder then
		repeat wait()
			folder = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		until folder
	end --Repeat find PlayerData process until it is found. 

	if folder then
		task.wait(1)
		setupPlayerRewardData(player)
	end
end)

Events.ClaimDailyReward.OnServerEvent:Connect(function(player)
	local folder = PlayerDataFolder:FindFirstChild(player.Name.."Data")
	if not folder then return end

	local canClaim = folder:FindFirstChild("CanClaimDaily")
	local rewardStreak = folder:FindFirstChild("RewardStreak")
	local lastClaimed = folder:FindFirstChild("LastClaimedTimestamp")

	if canClaim and canClaim.Value and rewardStreak and lastClaimed then
		-- Only now increment the streak\
		Events.UpdateDailyRewardUI:FireClient(player, {
			CanClaim = false,
			Streak = rewardStreak.Value
		})
		
		rewardStreak.Value += 1
		if rewardStreak.Value > 7 then
			rewardStreak.Value = 1
		end

		-- Give reward
		giveReward(player, rewardStreak.Value)

		-- Update claim values
		canClaim.Value = false
		lastClaimed.Value = os.time()

		-- Refresh UI
	else
		warn(player.Name .. " tried to claim daily reward too soon.")
	end
end)