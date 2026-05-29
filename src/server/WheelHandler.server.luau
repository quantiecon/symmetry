local Events = game.ReplicatedStorage.Events

local random = Random.new()

local Chances = {
	{"25000 Coins",       5},
	{"100000 Coins",      5},
	{"Worker Contract",   5},
	{"Legendary Drill",  40},
	{"30 Gems",          50},
}

local function selectWeightedOre()
	for i = #Chances, 1, -1 do
		local oreChance = Chances[i][2]
		local roll = random:NextInteger(1, oreChance)
		if roll <= 1 then
			return i
		end
	end
	return 1
end

-- Tracks pending rewards so the skip event can award early
-- { [userId] = { selected: string, thread: thread } }
local pendingRewards = {}

local function giveWheelReward(Player, selected)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	if not PlayerData then return end

	if selected == "25000 Coins" then
		PlayerData.Coins.Value += 25000
		Events.Profit:FireClient(Player, 25000)
	elseif selected == "100000 Coins" then
		PlayerData.Coins.Value += 100000
		Events.Profit:FireClient(Player, 100000)
	elseif selected == "30 Gems" then
		PlayerData.Diamonds.Value += 30
		Events.GemsChanged:FireClient(Player)
	elseif selected == "Legendary Drill" then
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
		Events.NewDrill:FireClient(Player, "Aether Drill", 1)
	elseif selected == "Worker Contract" then
		local collection = {}
		for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
			collection[name] = tonumber(amount)
		end
		collection["Worker Contract"] = (collection["Worker Contract"] or 0) + 1
		local newCollection = ""
		for name, amount in pairs(collection) do
			newCollection ..= name .. ":" .. amount .. ","
		end
		PlayerData.Collection.Value = newCollection
		Events.NewDrill:FireClient(Player, "Worker Contract", 1)
	end
end

-- OnServerInvoke: deduct ticket, return the result, schedule delayed reward
function Events.WheelSpin.OnServerInvoke(Player)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	if not (PlayerData and PlayerData.DailySpinTickets.Value >= 1) then return nil end

	PlayerData.DailySpinTickets.Value -= 1
	Events.UpdateSpinAmount:FireClient(Player)

	local index    = selectWeightedOre()
	local selected = Chances[index][1]

	-- Cancel any prior pending reward for this player
	local existing = pendingRewards[Player.UserId]
	if existing then
		task.cancel(existing.thread)
		pendingRewards[Player.UserId] = nil
	end

	-- Schedule the reward after 9 s (matches client animation length)
	local thread = task.delay(9, function()
		pendingRewards[Player.UserId] = nil
		giveWheelReward(Player, selected)
	end)

	pendingRewards[Player.UserId] = { selected = selected, thread = thread }

	return selected
end

-- SkipWheelRoll: client pressed skip — award immediately
Events.SkipWheelRoll.OnServerEvent:Connect(function(Player)
	local pending = pendingRewards[Player.UserId]
	if not pending then return end

	task.cancel(pending.thread)
	pendingRewards[Player.UserId] = nil
	giveWheelReward(Player, pending.selected)
end)

-- Clean up on player leave
game.Players.PlayerRemoving:Connect(function(player)
	local pending = pendingRewards[player.UserId]
	if pending then
		task.cancel(pending.thread)
		pendingRewards[player.UserId] = nil
	end
end)
