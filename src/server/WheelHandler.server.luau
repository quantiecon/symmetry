local Events = game.ReplicatedStorage.Events

local random = Random.new()

local Chances = {
	{"25000 Coins", 5},
	{"100000 Coins", 5},
	{"Worker Contract", 5},
	{"Legendary Drill", 40},
	{"30 Gems", 50},
}

-- Select ore by rolling from rarest to commonest with modifier
local function selectWeightedOre(modifier)
	for i = #Chances, 1, -1 do
		local oreChance = Chances[i][2]
		local roll = random:NextInteger(1, oreChance)
		if roll / modifier <= 1 then
			return i
		end
	end
	-- If no ore passed the check, return the most common ore
	return 1
end

function Events.WheelSpin.OnServerInvoke(Player)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	if PlayerData and PlayerData.DailySpinTickets.Value >= 1 then
		PlayerData.DailySpinTickets.Value -= 1
		
		Events.UpdateSpinAmount:FireClient(Player)
		
		local index = selectWeightedOre(1)
		local Selected = Chances[index][1]
		
		task.delay(9,function()
			if Selected == "25000 Coins" then
				PlayerData.Coins.Value += 25000
				Events.Profit:FireClient(Player,25000)
			elseif Selected == "30 Gems" then
				PlayerData.Diamonds.Value += 30
				Events.GemsChanged:FireClient(Player)
			elseif Selected == "100000 Coins" then
				PlayerData.Coins.Value += 100000
				Events.Profit:FireClient(Player,100000)
			elseif Selected == "Legendary Drill" then
				
				local collection = {}
				for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
					collection[name] = tonumber(amount)
				end
				-- Add or increment drill count
				collection["Aether Drill"] = (collection["Aether Drill"] or 0) + 1

				-- Rebuild collection string
				local newCollection = ""
				for name, amount in pairs(collection) do
					newCollection ..= name .. ":" .. amount .. ","
				end
				PlayerData.Collection.Value = newCollection

				-- Notify player of new drill
				Events.NewDrill:FireClient(Player, "Aether Drill", 1)
			elseif Selected == "Worker Contract" then

				local collection = {}
				for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
					collection[name] = tonumber(amount)
				end
				-- Add or increment drill count
				collection["Worker Contract"] = (collection["Worker Contract"] or 0) + 1

				-- Rebuild collection string
				local newCollection = ""
				for name, amount in pairs(collection) do
					newCollection ..= name .. ":" .. amount .. ","
				end
				PlayerData.Collection.Value = newCollection

				-- Notify player of new drill
				Events.NewDrill:FireClient(Player, "Worker Contract", 1)
			end
		end)
		return Selected
	end
end