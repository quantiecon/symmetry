local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Events = game.ReplicatedStorage.Events
local ItemInfo = require(game.ReplicatedStorage.Modules.ItemInfo) -- assuming ItemInfo is a module

-- Handles direct Dev Product purchase requests
Events.BuyDrillRobux.OnServerEvent:Connect(function(player, drillName)
	local itemData = ItemInfo[drillName]
	if itemData and itemData.DevID then
		MarketplaceService:PromptProductPurchase(player, itemData.DevID)
	else
		warn("Missing DevID for drill:", drillName)
	end
end)

-- Developer product reward handlers (Gem Packs)
local ProductFunctions = {
	[3318480558] = function(player) -- LegendaryGemPack
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			PlayerData.Diamonds.Value += 7500
			Events.GemsChanged:FireClient(player)
		end
	end,
	[3318480818] = function(player) -- EpicGemPack
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			PlayerData.Diamonds.Value += 1250
			Events.GemsChanged:FireClient(player)
		end
	end,
	[3318481054] = function(player) -- RareGemPack
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			PlayerData.Diamonds.Value += 500
			Events.GemsChanged:FireClient(player)
		end
	end,
	[3318481270] = function(player) -- GemPack
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			PlayerData.Diamonds.Value += 100
			Events.GemsChanged:FireClient(player)
		end
	end,
	[3319216900] = function(player) -- StarterBundle
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			PlayerData.Diamonds.Value += 50
			PlayerData.DailySpinTickets.Value += 3
			Events.GemsChanged:FireClient(player)
			Events.UpdateSpinAmount:FireClient(player)
			
			for i=1,3 do
				local collection = {}
				for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
					collection[name] = tonumber(amount)
				end

				-- Add or increment drill count
				collection["Fusion Drill"] = (collection["Fusion Drill"] or 0) + 1

				-- Rebuild collection string
				local newCollection = ""
				for name, amount in pairs(collection) do
					newCollection ..= name .. ":" .. amount .. ","
				end
				PlayerData.Collection.Value = newCollection

				-- Notify player of new drill
				Events.NewDrill:FireClient(player, "Fusion Drill", 1)
			end
			
			local collection = {}
			for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end

			-- Add or increment drill count
			collection["Pulsebreaker Drill"] = (collection["Pulsebreaker Drill"] or 0) + 1

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.Collection.Value = newCollection

			-- Notify player of new drill
			Events.NewDrill:FireClient(player, "Pulsebreaker Drill", 1)
		end
	end,
	[3319297071] = function(player) -- Expand Plot
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if not PlayerData then return end

		local tierOrder = { "None", "Tier1", "Tier2", "Tier3", "Tier4", "Tier5" }
		local currentTier = PlayerData.PlotExpansion.Value

		-- Find current tier index
		local nextTier
		for i = 1, #tierOrder - 1 do
			if tierOrder[i] == currentTier then
				nextTier = tierOrder[i + 1]
				break
			end
		end

		if nextTier then
			PlayerData.PlotExpansion.Value = nextTier
			if PlayerData:FindFirstChild("BoughtPlotExpansions") then
				PlayerData.BoughtPlotExpansions.Value += 1
			end
			Events.PlotSizeChange:FireClient(player)
		end
		
		local OneTimeQuests = PlayerData:FindFirstChild("OneTimeQuests") --if Collect Ore Quest is there
		if OneTimeQuests and string.find(OneTimeQuests.Value, "Expand Your Plot") then
			local questName, progress, goal = string.match(OneTimeQuests.Value, "^(.-):(%d+),(%d+)$")
			if questName and progress and goal then
				progress = tonumber(progress) + 1
				goal = tonumber(goal)

				-- Clamp to goal
				if progress > goal then
					progress = goal
				end

				-- Update the quest string
				OneTimeQuests.Value = string.format("%s:%d,%d", questName, progress, goal)
			end
		end
	end,
	[3319316190] = function(player) -- +1 worker slot
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			if PlayerData.WorkerSlots.Value == "None" then
				PlayerData.WorkerSlots.Value = "Tier1"
			elseif PlayerData.WorkerSlots.Value == "Tier1" then
				PlayerData.WorkerSlots.Value = "Tier2"
			end

			Events.WorkerLimitChange:FireClient(player)
		end
	end,
	[3319325670] = function(player) -- Fill all
		local PlotDrills = game.Workspace:FindFirstChild(player.Name.."Drills")
		if PlotDrills then
			for i,v in pairs(PlotDrills:GetChildren()) do
				if v:FindFirstChild("Data") then
					v:FindFirstChild("Data").Collected.Value = v:FindFirstChild("Data").Max.Value
				end
			end
		end
	end,
	[3319337976] = function(player) -- 2x luck
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			PlayerData.LuckMultiplier.Value = 2
			PlayerData.TimeUntilLuckEnds.Value = 300

			Events.LuckBought:FireClient(player)
		end
	end,
	[3319344460] = function(player) -- 4x luck
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			PlayerData.LuckMultiplier.Value = 4
			PlayerData.TimeUntilLuckEnds.Value = 300

			Events.LuckBought:FireClient(player)
		end
	end,
	[3319344650] = function(player) -- 8x luck
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			PlayerData.LuckMultiplier.Value = 8
			PlayerData.TimeUntilLuckEnds.Value = 300

			Events.LuckBought:FireClient(player)
		end
	end,
	[3319345899] = function(player) -- 16x luck
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			PlayerData.LuckMultiplier.Value = 16
			PlayerData.TimeUntilLuckEnds.Value = 300

			Events.LuckBought:FireClient(player)
		end
	end,
	[3319346079] = function(player) -- 32x luck
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			PlayerData.LuckMultiplier.Value = 32
			PlayerData.TimeUntilLuckEnds.Value = 300

			Events.LuckBought:FireClient(player)
		end
	end,
	[3319346367] = function(player) -- 64x luck
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			PlayerData.LuckMultiplier.Value = 64
			PlayerData.TimeUntilLuckEnds.Value = 300

			Events.LuckBought:FireClient(player)
		end
	end,
	[3319346565] = function(player) -- 128x luck
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			PlayerData.LuckMultiplier.Value = 128
			PlayerData.TimeUntilLuckEnds.Value = 300

			Events.LuckBought:FireClient(player)
		end
	end,
	[3321053944] = function(player) -- 256x luck
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			PlayerData.LuckMultiplier.Value = 256
			PlayerData.TimeUntilLuckEnds.Value = 300

			Events.LuckBought:FireClient(player)
		end
	end,
	[3321054309] = function(player) -- 512x luck
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			PlayerData.LuckMultiplier.Value = 512
			PlayerData.TimeUntilLuckEnds.Value = 300

			Events.LuckBought:FireClient(player)
		end
	end,
	[3321054744] = function(player) -- 1024x luck
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			PlayerData.LuckMultiplier.Value = 1024
			PlayerData.TimeUntilLuckEnds.Value = 300

			Events.LuckBought:FireClient(player)
		end
	end,
	[3320033456] = function(player) -- Advanced Bundle
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			PlayerData.Diamonds.Value += 100
			PlayerData.DailySpinTickets.Value += 5
			Events.GemsChanged:FireClient(player)
			Events.UpdateSpinAmount:FireClient(player)
			Events.Alert:FireClient(player,"+5 Daily Spin Ticket")

			for i=1,3 do
				local collection = {}
				for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
					collection[name] = tonumber(amount)
				end

				-- Add or increment drill count
				collection["KinetiCore Drill"] = (collection["KinetiCore Drill"] or 0) + 1

				-- Rebuild collection string
				local newCollection = ""
				for name, amount in pairs(collection) do
					newCollection ..= name .. ":" .. amount .. ","
				end
				PlayerData.Collection.Value = newCollection

				-- Notify player of new drill
				Events.NewDrill:FireClient(player, "KinetiCore Drill", 1)
			end

			local collection = {}
			for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end

			-- Add or increment drill count
			collection["Quantum Drill"] = (collection["Quantum Drill"] or 0) + 1

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.Collection.Value = newCollection

			-- Notify player of new drill
			Events.NewDrill:FireClient(player, "Quantum Drill", 1)
		end
	end,
	[3320601586] = function(player) -- 2x walkspeed
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			PlayerData.SpeedProduct.Value = true

			Events.DevProductBought:FireClient(player,"SpeedMultiplier")
		end
	end,
	[3320593298] = function(player) -- +5 drill limit
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			if PlayerData.MaxDrills.Value == "None" then
				PlayerData.MaxDrills.Value = "Tier1"
			elseif PlayerData.MaxDrills.Value == "Tier1" then
				PlayerData.MaxDrills.Value = "Tier2"
			end

			Events.DevProductBought:FireClient(player,"DrillLimit")
		end
	end,
	[3320613614] = function(player) -- Summer Bundle
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			if string.find(PlayerData.OneTimePurchases.Value,"SummerBundle") then return end
			PlayerData.DailySpinTickets.Value += 10
			PlayerData.OneTimePurchases.Value = PlayerData.OneTimePurchases.Value.."SummerBundle,"
			Events.UpdateSpinAmount:FireClient(player)
			Events.Alert:FireClient(player,"+10 Daily Spin Ticket")

			local collection = {}
			for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end

			-- Add or increment drill count
			collection["Coral Drill"] = (collection["Coral Drill"] or 0) + 1
			collection["Summer Pack"] = (collection["Summer Pack"] or 0) + 3

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.Collection.Value = newCollection

			-- Notify player of new drill
			Events.NewDrill:FireClient(player, "Coral Drill", 1)
			Events.NewDrill:FireClient(player, "Summer Pack", 3)
			
			Events.DevProductBought:FireClient(player,"SummerBundle")
		end
	end,
	[3320623603] = function(player) -- Pro Summer Bundle
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			if string.find(PlayerData.OneTimePurchases.Value,"ProSummer") then return end
			PlayerData.DailySpinTickets.Value += 25
			PlayerData.OneTimePurchases.Value = PlayerData.OneTimePurchases.Value.."ProSummer,"
			Events.UpdateSpinAmount:FireClient(player)
			Events.Alert:FireClient(player,"+25 Daily Spin Ticket")

			local collection = {}
			for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end

			-- Add or increment drill count
			collection["Coral Drill"] = (collection["Coral Drill"] or 0) + 3
			collection["Summer Pack"] = (collection["Summer Pack"] or 0) + 5

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.Collection.Value = newCollection

			-- Notify player of new drill
			Events.NewDrill:FireClient(player, "Coral Drill", 3)
			Events.NewDrill:FireClient(player, "Summer Pack", 5)

			Events.DevProductBought:FireClient(player,"ProSummer")
		end
	end,
	[3320663222] = function(player) -- buy spin
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			PlayerData.DailySpinTickets.Value += 1
			Events.UpdateSpinAmount:FireClient(player)
			Events.Alert:FireClient(player,"+1 Daily Spin Ticket")
		end
	end,
	[3321025820] = function(player) -- 1 summer pack
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			local collection = {}
			for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end

			-- Add or increment drill count
			collection["Summer Pack"] = (collection["Summer Pack"] or 0) + 1

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.Collection.Value = newCollection

			-- Notify player of new drill
			Events.NewDrill:FireClient(player, "Summer Pack", 1)
		end
	end,
	[3321026170] = function(player) -- 3 summer pack
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			local collection = {}
			for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end

			-- Add or increment drill count
			collection["Summer Pack"] = (collection["Summer Pack"] or 0) + 3

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.Collection.Value = newCollection

			-- Notify player of new drill
			Events.NewDrill:FireClient(player, "Summer Pack", 3)
		end
	end,
	[3321026395] = function(player) -- 10 summer pack
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			local collection = {}
			for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end

			-- Add or increment drill count
			collection["Summer Pack"] = (collection["Summer Pack"] or 0) + 10

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.Collection.Value = newCollection

			-- Notify player of new drill
			Events.NewDrill:FireClient(player, "Summer Pack", 10)
		end
	end,
	[3371158418] = function(player) -- 1 boundless pack
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			local collection = {}
			for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end

			-- Add or increment drill count
			collection["Boundless Depths Chest"] = (collection["Boundless Depths Chest"] or 0) + 1

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.Collection.Value = newCollection

			-- Notify player of new drill
			Events.NewDrill:FireClient(player, "Boundless Depths Chest", 1)
		end
	end,
	[3371158662] = function(player) -- 3 boundless pack
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			local collection = {}
			for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end

			-- Add or increment drill count
			collection["Boundless Depths Chest"] = (collection["Boundless Depths Chest"] or 0) + 3

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.Collection.Value = newCollection

			-- Notify player of new drill
			Events.NewDrill:FireClient(player, "Boundless Depths Chest", 3)
		end
	end,
	[3371158877] = function(player) -- 10 boundless pack
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			local collection = {}
			for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end

			-- Add or increment drill count
			collection["Boundless Depths Chest"] = (collection["Boundless Depths Chest"] or 0) + 10

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.Collection.Value = newCollection

			-- Notify player of new drill
			Events.NewDrill:FireClient(player, "Boundless Depths Chest", 10)
		end
	end,
	[3379293736] = function(player) -- 1 forest pack
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			local collection = {}
			for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end

			-- Add or increment drill count
			collection["Forest Chest"] = (collection["Forest Chest"] or 0) + 1

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.Collection.Value = newCollection

			-- Notify player of new drill
			Events.NewDrill:FireClient(player, "Forest Chest", 1)
		end
	end,
	[3379293932] = function(player) -- 3 Forest pack
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			local collection = {}
			for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end

			-- Add or increment drill count
			collection["Forest Chest"] = (collection["Forest Chest"] or 0) + 3

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.Collection.Value = newCollection

			-- Notify player of new drill
			Events.NewDrill:FireClient(player, "Forest Chest", 3)
		end
	end,
	[3379294162] = function(player) -- 10 Forest pack
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			local collection = {}
			for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end

			-- Add or increment drill count
			collection["Forest Chest"] = (collection["Forest Chest"] or 0) + 10

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.Collection.Value = newCollection

			-- Notify player of new drill
			Events.NewDrill:FireClient(player, "Forest Chest", 10)
		end
	end,
	[3357800719] = function(player) -- 1 abyssal void
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			local collection = {}
			for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end

			-- Add or increment drill count
			collection["Abyssal Void Chest"] = (collection["Abyssal Void Chest"] or 0) + 1

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.Collection.Value = newCollection

			-- Notify player of new drill
			Events.NewDrill:FireClient(player, "Abyssal Void Chest", 1)
		end
	end,
	[3357800922] = function(player) -- 3 abyssal void
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			local collection = {}
			for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end

			-- Add or increment drill count
			collection["Abyssal Void Chest"] = (collection["Abyssal Void Chest"] or 0) + 3

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.Collection.Value = newCollection

			-- Notify player of new drill
			Events.NewDrill:FireClient(player, "Abyssal Void Chest", 3)
		end
	end,
	[3357801088] = function(player) -- 10 abyssal void
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			local collection = {}
			for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end

			-- Add or increment drill count
			collection["Abyssal Void Chest"] = (collection["Abyssal Void Chest"] or 0) + 10

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.Collection.Value = newCollection

			-- Notify player of new drill
			Events.NewDrill:FireClient(player, "Abyssal Void Chest", 10)
		end
	end,
	[3357807556] = function(player) -- 1 void
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			local collection = {}
			for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end

			-- Add or increment drill count
			collection["Void Chest"] = (collection["Void Chest"] or 0) + 1

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.Collection.Value = newCollection

			-- Notify player of new drill
			Events.NewDrill:FireClient(player, "Void Chest", 1)
		end
	end,
	[3357807700] = function(player) -- 3  void
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			local collection = {}
			for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end

			-- Add or increment drill count
			collection["Void Chest"] = (collection["Void Chest"] or 0) + 3

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.Collection.Value = newCollection

			-- Notify player of new drill
			Events.NewDrill:FireClient(player, "Void Chest", 3)
		end
	end,
	[3357807911] = function(player) -- 10 abyssal void
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			local collection = {}
			for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end

			-- Add or increment drill count
			collection["Void Chest"] = (collection["Void Chest"] or 0) + 10

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.Collection.Value = newCollection

			-- Notify player of new drill
			Events.NewDrill:FireClient(player, "Void Chest", 10)
		end
	end,
	[3334009155] = function(player) -- Impulse Driver Drill
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			local collection = {}
			for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end

			-- Add or increment drill count
			collection["Impulse Driver Drill"] = (collection["Impulse Driver Drill"] or 0) + 1

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.Collection.Value = newCollection

			-- Notify player of new drill
			Events.NewDrill:FireClient(player, "Impulse Driver Drill", 1)
		end
	end,
	[3339897363] = function(player) -- Hyperquantum Drill
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			local collection = {}
			for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end

			-- Add or increment drill count
			collection["HyperQuantum Drill"] = (collection["HyperQuantum Drill"] or 0) + 1

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.Collection.Value = newCollection

			-- Notify player of new drill
			Events.NewDrill:FireClient(player, "HyperQuantum Drill", 1)
		end
	end,
	[3327236909] = function(player) -- Dominus Dane
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			local collection = {}
			for name, amount in string.gmatch(PlayerData.CollectedWorkers.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end

			if player:FindFirstChild("WorkerCapacity") then
				player.WorkerCapacity.Value += 1
			end

			-- Add or increment drill count
			collection["Dominus Dane"] = (collection["Dominus Dane"] or 0) + 1

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.CollectedWorkers.Value = newCollection

			-- Notify player of new drill
			Events.Alert:FireClient(player, "+1 Dominus Dane")
			Events.RebuildWorkerUI:FireClient(player, {
				EquippedWorkers = PlayerData.EquippedWorkers.Value,
				CollectedWorkers = PlayerData.CollectedWorkers.Value,
			})
		end
	end,
	[3327237064] = function(player) -- Empreus
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			local collection = {}
			for name, amount in string.gmatch(PlayerData.CollectedWorkers.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end
			
			if player:FindFirstChild("WorkerCapacity") then
				player.WorkerCapacity.Value += 1
			end

			-- Add or increment drill count
			collection["Empyreus"] = (collection["Empyreus"] or 0) + 1

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.CollectedWorkers.Value = newCollection

			-- Notify player of new drill
			Events.Alert:FireClient(player, "+1 Empyreus")
			Events.RebuildWorkerUI:FireClient(player, {
				EquippedWorkers = PlayerData.EquippedWorkers.Value,
				CollectedWorkers = PlayerData.CollectedWorkers.Value,
			})
		end
	end,
}

-- Unified receipt processing for drills and gem packs
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productId = receiptInfo.ProductId

	-- If it's a gem pack, handle it here
	local gemPackHandler = ProductFunctions[productId]
	if gemPackHandler then
		gemPackHandler(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- Otherwise, check if it's a drill (via ItemInfo.DevID)
	local drillName = nil
	for name, data in pairs(ItemInfo) do
		if data.DevID == productId then
			drillName = name
			break
		end
	end

	if not drillName then
		warn("Unrecognized Dev Product ID:", productId)
		return Enum.ProductPurchaseDecision.PurchaseGranted -- avoid duplicate charges
	end

	-- Handle drill purchase
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name .. "Data")
	if not PlayerData then
		warn("No PlayerData for", player.Name)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Parse collection string
	local collection = {}
	for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
		collection[name] = tonumber(amount)
	end

	-- Add or increment drill count
	collection[drillName] = (collection[drillName] or 0) + 1

	-- Rebuild collection string
	local newCollection = ""
	for name, amount in pairs(collection) do
		newCollection ..= name .. ":" .. amount .. ","
	end
	PlayerData.Collection.Value = newCollection

	-- Notify player of new drill
	Events.NewDrill:FireClient(player, drillName, 1)
	print("Player", player.Name, "successfully purchased", drillName)

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

Events.BuyWithDiamonds.OnServerEvent:Connect(function(Player,Purchase)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	if PlayerData then
		if Purchase == "PlotExpansion" then
			if PlayerData.Diamonds.Value - 99 >= 0 then
				PlayerData.Diamonds.Value -= 99
				
				local tierOrder = { "None", "Tier1", "Tier2", "Tier3", "Tier4", "Tier5" }
				local currentTier = PlayerData.PlotExpansion.Value

				-- Find current tier index
				local nextTier
				for i = 1, #tierOrder - 1 do
					if tierOrder[i] == currentTier then
						nextTier = tierOrder[i + 1]
						break
					end
				end

				if nextTier then
					PlayerData.PlotExpansion.Value = nextTier
					if PlayerData:FindFirstChild("BoughtPlotExpansions") then
						PlayerData.BoughtPlotExpansions.Value += 1
					end
					Events.PlotSizeChange:FireClient(Player)
				end
				
				Events.GemsChanged:FireClient(Player)
				
				local OneTimeQuests = PlayerData:FindFirstChild("OneTimeQuests") --if Collect Ore Quest is there
				if OneTimeQuests and string.find(OneTimeQuests.Value, "Expand Your Plot") then
					local questName, progress, goal = string.match(OneTimeQuests.Value, "^(.-):(%d+),(%d+)$")
					if questName and progress and goal then
						progress = tonumber(progress) + 1
						goal = tonumber(goal)

						-- Clamp to goal
						if progress > goal then
							progress = goal
						end

						-- Update the quest string
						OneTimeQuests.Value = string.format("%s:%d,%d", questName, progress, goal)
					end
				end
			end
		elseif Purchase == "WorkersEquipped" then
			if PlayerData.Diamonds.Value - 49 >= 0 then
				PlayerData.Diamonds.Value -= 49

				if PlayerData.WorkerSlots.Value == "None" then
					PlayerData.WorkerSlots.Value = "Tier1"
				elseif PlayerData.WorkerSlots.Value == "Tier1" then
					PlayerData.WorkerSlots.Value = "Tier2"
				end

				Events.GemsChanged:FireClient(Player)
				Events.WorkerLimitChange:FireClient(Player)
			end
		elseif Purchase == "2xSpeed" then
			if PlayerData.Diamonds.Value - 39 >= 0 then
				PlayerData.Diamonds.Value -= 39

				PlayerData.SpeedProduct.Value = true

				Events.GemsChanged:FireClient(Player)

				Events.DevProductBought:FireClient(Player,"SpeedMultiplier")
			end
		elseif Purchase == "DrillLimit" then
			if PlayerData.Diamonds.Value - 79 >= 0 then
				PlayerData.Diamonds.Value -= 79

				if PlayerData.MaxDrills.Value == "None" then
					PlayerData.MaxDrills.Value = "Tier1"
				elseif PlayerData.MaxDrills.Value == "Tier1" then
					PlayerData.MaxDrills.Value = "Tier2"
				end

				Events.GemsChanged:FireClient(Player)
				Events.DevProductBought:FireClient(Player,"DrillLimit")
			end
		elseif Purchase == "VIP" then
			if PlayerData.Diamonds.Value - 399 >= 0 then
				PlayerData.Diamonds.Value -= 399

				PlayerData.VIP.Value = true
				Events.GemsChanged:FireClient(Player)
				Events.DevProductBought:FireClient(Player, "VIP")
			end
		elseif game.ReplicatedStorage.ToolModels:FindFirstChild(Purchase) then
			if ItemInfo[Purchase].VoidDiamondPrice then
				if PlayerData.Diamonds.Value - ItemInfo[Purchase].VoidDiamondPrice >= 0 then
					PlayerData.Diamonds.Value -= ItemInfo[Purchase].VoidDiamondPrice

					local collection = {}
					for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
						collection[name] = tonumber(amount)
					end

					-- Add or increment drill count
					collection[Purchase] = (collection[Purchase] or 0) + 1

					-- Rebuild collection string
					local newCollection = ""
					for name, amount in pairs(collection) do
						newCollection ..= name .. ":" .. amount .. ","
					end
					PlayerData.Collection.Value = newCollection

					-- Notify player of new drill
					Events.NewDrill:FireClient(Player, Purchase, 1)
					Events.GemsChanged:FireClient(Player)
				else
					game:GetService("MarketplaceService"):PromptProductPurchase(Player, 3318481054)
				end
				return
			end
			
			if PlayerData.Diamonds.Value - ItemInfo[Purchase].DiamondPrice >= 0 then
				PlayerData.Diamonds.Value -= ItemInfo[Purchase].DiamondPrice
				
				local collection = {}
				for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
					collection[name] = tonumber(amount)
				end

				-- Add or increment drill count
				collection[Purchase] = (collection[Purchase] or 0) + 1

				-- Rebuild collection string
				local newCollection = ""
				for name, amount in pairs(collection) do
					newCollection ..= name .. ":" .. amount .. ","
				end
				PlayerData.Collection.Value = newCollection

				-- Notify player of new drill
				Events.NewDrill:FireClient(Player, Purchase, 1)
				Events.GemsChanged:FireClient(Player)

			end
		end
	end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	if gamePassId == 1283734238 and wasPurchased then --VIP
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
		if PlayerData then
			PlayerData.VIP.Value = true
			Events.DevProductBought:FireClient(player, "VIP")
		end
	end
end)