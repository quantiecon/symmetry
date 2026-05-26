local Events = game.ReplicatedStorage.Events

game.Players.PlayerAdded:Connect(function(player)
	local referrerUserId = player:GetJoinData().ReferrerUserId

	if referrerUserId and referrerUserId ~= 0 then
		print(player.Name .. " was invited by userId:", referrerUserId)

		local Referrer = game.Players:GetPlayerByUserId(referrerUserId)
		local ReffererData = game.ServerStorage.PlayerData:FindFirstChild(Referrer.Name.."Data")
		if ReffererData then
			local collection = {}
			for name, amount in string.gmatch(ReffererData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end

			-- Add or increment drill count
			collection["Phase Drill"] = (collection["Phase Drill"] or 0) + 1

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			ReffererData.Collection.Value = newCollection

			-- Notify player of new drill
			Events.NewDrill:FireClient(player, "Phase Drill", 1)
		end
	end
end)