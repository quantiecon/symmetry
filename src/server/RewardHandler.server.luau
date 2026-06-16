local Events = game.ReplicatedStorage.Events

Events.ClaimReward.OnServerEvent:Connect(function(Player,Reward)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	if PlayerData then
		local SecondsSpent = PlayerData.SecondsSpentIngame.Value
		local MinutesSpent = math.floor(SecondsSpent / 60)
		
		if Reward == "ImpulseDriver" then
			if not string.find(PlayerData.ClaimedRewards.Value, "ImpulseDriver") then
				if MinutesSpent >= 30 then
					PlayerData.ClaimedRewards.Value = PlayerData.ClaimedRewards.Value..",".."ImpulseDriver"
					
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
					Events.NewDrill:FireClient(Player, "Impulse Driver Drill", 1)
				else
					Events.Alert:FireClient(Player,"You need to play for 30 minutes to claim this!")
				end
			end
		elseif Reward == "Hyperquantum" then
			if not string.find(PlayerData.ClaimedRewards.Value, "Hyperquantum Drill") then
				if MinutesSpent >= 180 then
					PlayerData.ClaimedRewards.Value = PlayerData.ClaimedRewards.Value..",".."Hyperquantum Drill"

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
					Events.NewDrill:FireClient(Player, "HyperQuantum Drill", 1)
				else
					Events.Alert:FireClient(Player,"You need to play for 180 minutes to claim this!")
				end
			end
		elseif Reward == "DominusDane" then
			if not string.find(PlayerData.ClaimedRewards.Value, "Dominus Dane") then
				if MinutesSpent >= 120 then
					PlayerData.ClaimedRewards.Value = PlayerData.ClaimedRewards.Value..",".."Dominus Dane"

					local collection = {}
					for name, amount in string.gmatch(PlayerData.CollectedWorkers.Value or ",", "([^:,]+):(%d+),") do
						collection[name] = tonumber(amount)
					end

					if Player:FindFirstChild("WorkerCapacity") then
						Player.WorkerCapacity.Value += 1
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
					Events.Alert:FireClient(Player, "+1 Dominus Dane")
					Events.RebuildWorkerUI:FireClient(Player, {
						EquippedWorkers = PlayerData.EquippedWorkers.Value,
						CollectedWorkers = PlayerData.CollectedWorkers.Value,
					})
				else
					Events.Alert:FireClient(Player,"You need to play for 120 minutes to claim this!")
				end
			end
		end
	end
end)