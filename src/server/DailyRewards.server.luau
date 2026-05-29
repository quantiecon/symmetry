local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local PlayerDataFolder = ServerStorage:WaitForChild("PlayerData")
local Events = game.ReplicatedStorage.Events

-- Day 1-7 reward definitions.  label is sent to the client for display.
local REWARDS = {
	[1] = { label = "10,000 Coins",          action = "coins",  coins   = 10000 },
	[2] = { label = "Impulse Driver Drill",   action = "drill",  item    = "Impulse Driver Drill" },
	[3] = { label = "50,000 Coins",           action = "coins",  coins   = 50000 },
	[4] = { label = "Worker Contract",        action = "item",   item    = "Worker Contract" },
	[5] = { label = "200,000 Coins",          action = "coins",  coins   = 200000 },
	[6] = { label = "1,000,000 Coins",        action = "coins",  coins   = 1000000 },
	[7] = { label = "Aether Drill + 50 Gems", action = "special" },
}

local function giveReward(player, day)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
	if not PlayerData then return end

	-- Everyone gets a Daily Spin Ticket; VIP gets an extra one
	PlayerData.DailySpinTickets.Value += 1
	Events.Alert:FireClient(player, "+1 Daily Spin Ticket")
	if PlayerData.VIP.Value == true then
		PlayerData.DailySpinTickets.Value += 1
		Events.Alert:FireClient(player, "+1 Daily Spin Ticket (VIP bonus)")
	end

	local reward = REWARDS[math.clamp(day, 1, #REWARDS)]
	print(player.Name .. " day-" .. day .. " reward: " .. reward.label)

	if reward.action == "coins" then
		PlayerData.Coins.Value += reward.coins
		Events.Profit:FireClient(player, reward.coins)

	elseif reward.action == "drill" or reward.action == "item" then
		local collection = {}
		for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
			collection[name] = tonumber(amount)
		end
		collection[reward.item] = (collection[reward.item] or 0) + 1
		local newCollection = ""
		for name, amount in pairs(collection) do
			newCollection ..= name .. ":" .. amount .. ","
		end
		PlayerData.Collection.Value = newCollection
		Events.NewDrill:FireClient(player, reward.item, 1)

	elseif reward.action == "special" then
		-- Day 7: Aether Drill + 50 Gems
		PlayerData.Diamonds.Value += 50
		Events.GemsChanged:FireClient(player)

		local collection = {}
		for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
			collection[name] = tonumber(amount)
		end
		collection["Aether Drill"] = (collection["Aether Drill"] or 0) + 1
		local newCollection = ""
		for name, amount in pairs(collection) do
			newCollection ..= name .. ":" .. amount .. ","
		end
		PlayerData.Collection.Value = newCollection
		Events.NewDrill:FireClient(player, "Aether Drill", 1)
	end
end

local function setupPlayerRewardData(player)
	local folder = PlayerDataFolder:FindFirstChild(player.Name.."Data")
	if not folder then
		repeat task.wait()
			folder = PlayerDataFolder:FindFirstChild(player.Name.."Data")
		until folder
	end
	if not folder then return end

	local currentTime    = os.time()
	local lastClaimed    = folder:FindFirstChild("LastClaimedTimestamp")
	local rewardStreak   = folder:FindFirstChild("RewardStreak")
	local canClaimDaily  = folder:FindFirstChild("CanClaimDaily")
	if not (lastClaimed and rewardStreak and canClaimDaily) then return end

	local secondsInDay      = 86400
	local timeSinceLastClaim = currentTime - lastClaimed.Value

	if lastClaimed.Value == 0 then
		-- First-ever login
		canClaimDaily.Value = true
	elseif timeSinceLastClaim >= secondsInDay * 2 then
		-- Missed at least one day — reset streak
		rewardStreak.Value  = 0
		canClaimDaily.Value = true
	elseif timeSinceLastClaim >= secondsInDay then
		-- New day, streak intact
		canClaimDaily.Value = true
	else
		-- Already claimed today
		canClaimDaily.Value = false
	end

	Events.UpdateDailyRewardUI:FireClient(player, {
		CanClaim = canClaimDaily.Value,
		Streak   = rewardStreak.Value,
	})
end

Players.PlayerAdded:Connect(function(player)
	local folder = PlayerDataFolder:FindFirstChild(player.Name.."Data")
	if not folder then
		repeat wait()
			folder = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		until folder
	end
	if folder then
		task.wait(1)
		setupPlayerRewardData(player)
	end
end)

Events.ClaimDailyReward.OnServerEvent:Connect(function(player)
	local folder = PlayerDataFolder:FindFirstChild(player.Name.."Data")
	if not folder then return end

	local canClaim      = folder:FindFirstChild("CanClaimDaily")
	local rewardStreak  = folder:FindFirstChild("RewardStreak")
	local lastClaimed   = folder:FindFirstChild("LastClaimedTimestamp")
	if not (canClaim and canClaim.Value and rewardStreak and lastClaimed) then
		warn(player.Name .. " tried to claim daily reward too soon.")
		return
	end

	-- Advance streak (wraps 7 → 1)
	rewardStreak.Value += 1
	if rewardStreak.Value > 7 then
		rewardStreak.Value = 1
	end

	-- Send updated UI before giving the reward (so client sees streak change)
	Events.UpdateDailyRewardUI:FireClient(player, {
		CanClaim = false,
		Streak   = rewardStreak.Value,
	})

	giveReward(player, rewardStreak.Value)

	canClaim.Value     = false
	lastClaimed.Value  = os.time()
end)
