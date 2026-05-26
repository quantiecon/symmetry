local Events = game.ReplicatedStorage.Events

local TradeOffers = {}

local function parseStringToTable(dataStr)
	local result = {}
	for name, amount in string.gmatch(dataStr, "([^:,]+):(%d+),") do
		result[name] = tonumber(amount)
	end
	return result
end


local function isNaN(value)
	return value ~= value
end

local function attachTradeValidation(player)
	local playerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
	if not playerData then return end

	local function validateTrade()
		local trade = TradeOffers[player.UserId]
		if not trade or not trade.Partner then return end

		local function parse(str)
			local result = {}
			for name, amount in string.gmatch(str, "([^:,]+):(%d+),") do
				result[name] = tonumber(amount)
			end
			return result
		end

		local collection = parse(playerData.Collection.Value)
		local workers = parse(playerData.CollectedWorkers.Value)
		local diamonds = playerData.Diamonds.Value

		local toRemove = {}

		for itemName, data in pairs(trade.Offers) do
			local tableRef = data.IsWorker and workers or collection
			local owned = tableRef[itemName] or 0
			if owned < data.Amount then
				table.insert(toRemove, itemName)
			end
		end

		if trade.Diamonds > diamonds then
			trade.Diamonds = 0
			Events.UpdateOwnTradeOffer:FireClient(player, {
				Item = "Diamonds",
				Amount = 0,
				IsDiamond = true
			})
			Events.UpdatePartnerTradeOffer:FireClient(trade.Partner, {
				Item = "Diamonds",
				Amount = 0,
				IsDiamond = true
			})
		end

		for _, itemName in ipairs(toRemove) do
			trade.Offers[itemName] = nil
			Events.UpdatePartnerTradeOffer:FireClient(trade.Partner, {
				Item = itemName,
				RemoveItem = true
			})
			Events.UpdateOwnTradeOffer:FireClient(player, {
				Item = itemName,
				RemoveItem = true
			})
		end

		if #toRemove > 0 or trade.Diamonds == 0 then
			trade.Accepted = false
			TradeOffers[trade.Partner.UserId].Accepted = false

			Events.UpdatePartnerTradeOffer:FireClient(trade.Partner, { Accepted = false })
			Events.UpdateOwnTradeOffer:FireClient(player, { Accepted = false })
		end
	end

	-- Store connections
	local connections = {}

	table.insert(connections, playerData.Collection.Changed:Connect(validateTrade))
	table.insert(connections, playerData.CollectedWorkers.Changed:Connect(validateTrade))
	table.insert(connections, playerData.Diamonds.Changed:Connect(validateTrade))

	-- Save to TradeOffers
	if TradeOffers[player.UserId] then
		TradeOffers[player.UserId].Connections = connections
	end
end

local function cleanupTrade(player)
	local trade = TradeOffers[player.UserId]
	if not trade then return end

	-- Disconnect validation connections
	if trade.Connections then
		for _, conn in ipairs(trade.Connections) do
			if typeof(conn) == "RBXScriptConnection" then
				conn:Disconnect()
			end
		end
		trade.Connections = nil
	end

	-- Clear trade state
	TradeOffers[player.UserId] = nil
end

game.Players.PlayerAdded:Connect(function(Player)
	TradeOffers[Player.UserId] = {
		SentOffers = {};
		Connections = {}
	}
	
	-- Policy check to disallow trading
	local success, policy = pcall(function()
		return game:GetService("PolicyService"):GetPolicyInfoForPlayerAsync(Player)
	end)

	if success and not policy.IsPaidItemTradingAllowed then
		local TradeOff = Instance.new("Folder")
		TradeOff.Name = "TradeOff"
		TradeOff.Parent = Player
	end
end)

game.Players.PlayerRemoving:Connect(function(Player)
	local trade = TradeOffers[Player.UserId]
	if not trade then return end

	local partner = trade.Partner

	-- Cleanup both players' trade data
	cleanupTrade(Player)
	if partner then cleanupTrade(partner) end

	-- Notify both players if partner is valid
	if partner then

		Events.CancelTrade:FireClient(partner)
	end
end)

Events.RequestTrade.OnServerEvent:Connect(function(Player, TargetPlayer)
	if not TargetPlayer or not TargetPlayer:IsDescendantOf(game.Players) then return end
	if Player:FindFirstChild("TradeOff") or TargetPlayer:FindFirstChild("TradeOff") then return end

	if not TradeOffers[Player.UserId] then
		TradeOffers[Player.UserId] = {
			SentOffers = {},
			Connections = {}
		}
	end

	local playerData = TradeOffers[Player.UserId]
	if not playerData then return end

	local sentToId = TargetPlayer.UserId

	-- Check if already sent
	if playerData.SentOffers[sentToId] then
		Events.Alert:FireClient(Player,"Wait before sending another trade request.")
		warn(Player.Name .. " already sent a trade request to " .. TargetPlayer.Name)
		return
	end

	-- Mark as sent
	playerData.SentOffers[sentToId] = true

	-- Send the request to the target player
	Events.RequestTrade:FireClient(TargetPlayer, Player)

	-- Set 10-second cooldown
	task.delay(10, function()
		if TradeOffers[Player.UserId] then
			TradeOffers[Player.UserId].SentOffers[sentToId] = nil
		end
	end)
end)

Events.AcceptTradeRequest.OnServerEvent:Connect(function(Player1,Player2)
	if Player1 and Player2 then
		if not TradeOffers[Player1.UserId] then
			TradeOffers[Player1.UserId] = {
				SentOffers = {};
				Connections = {};
			}
		end
		if not TradeOffers[Player2.UserId] then
			TradeOffers[Player2.UserId] = {
				SentOffers = {};
				Connections = {};
			}
		end
		
		local trade1 = TradeOffers[Player1.UserId]
		local trade2 = TradeOffers[Player2.UserId]

		if trade1 and trade2 and not trade1.Partner and not trade2.Partner then

			trade1.Partner = Player2
			trade1.Offers = {}
			trade1.Accepted = false
			trade1.Diamonds = 0

			trade2.Partner = Player1
			trade2.Offers = {}
			trade2.Accepted = false
			trade2.Diamonds = 0

			attachTradeValidation(Player1)
			attachTradeValidation(Player2)

			Events.StartTrade:FireClient(Player1, Player2)
			Events.StartTrade:FireClient(Player2, Player1)
		end
	end
end)

Events.AddToTradeOffer.OnServerEvent:Connect(function(Player,data)
	local playerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	if data.IsDiamond then
		local amount = tonumber(data.Amount)
		if not amount or amount <= 0 then return end
		if isNaN(amount) == true then return end

		local diamondsOwned = playerData.Diamonds.Value
		if amount > diamondsOwned then return end

		TradeOffers[Player.UserId].Diamonds = data.Amount

		Events.UpdateOwnTradeOffer:FireClient(Player, {
			Item = "Diamonds",
			Amount = TradeOffers[Player.UserId].Diamonds,
			IsDiamond = true
		})

		Events.UpdatePartnerTradeOffer:FireClient(TradeOffers[Player.UserId].Partner, {
			Item = "Diamonds",
			Amount = TradeOffers[Player.UserId].Diamonds,
			IsDiamond = true
		})
		
		TradeOffers[Player.UserId].Accepted = false
		TradeOffers[TradeOffers[Player.UserId].Partner.UserId].Accepted = false

		Events.UpdatePartnerTradeOffer:FireClient(TradeOffers[Player.UserId].Partner, {
			Accepted = false,
		})
		Events.UpdatePartnerTradeOffer:FireClient(Player, {
			Accepted = false,
		})

		Events.UpdateOwnTradeOffer:FireClient(TradeOffers[Player.UserId].Partner,{
			Accepted = false,
		})

		Events.UpdateOwnTradeOffer:FireClient(Player,{
			Accepted = false,
		})

		return
	end

	local item = data.Item
	local amount = tonumber(data.Amount)
	local isWorker = data.IsWorker

	if isNaN(amount) == true then return end
	if not item or not amount or amount <= 0 then return end

	if not playerData then return end

	local rawStr = isWorker and playerData.CollectedWorkers.Value or playerData.Collection.Value
	local itemTable = parseStringToTable(rawStr)

	local ownedAmount = itemTable[item] or 0
	if ownedAmount < amount then
		warn(Player.Name.." tried to offer more "..item.." than owned")
		Events.Alert:FireClient(Player,"Insufficient amount.")
		return
	end

	-- Save their offer
	TradeOffers[Player.UserId] = TradeOffers[Player.UserId] or { Offers = {} }
	TradeOffers[Player.UserId].Offers[item] = {
		Amount = amount,
		IsWorker = isWorker
	}

	-- Optional: get the trade partner
	local partner = TradeOffers[Player.UserId].Partner
	if partner then
		-- Update both clients
		Events.UpdateOwnTradeOffer:FireClient(Player, {
			Item = item,
			Amount = amount,
			IsWorker = isWorker
		})

		-- Notify partner
		Events.UpdatePartnerTradeOffer:FireClient(partner, {
			Item = item,
			Amount = amount,
			IsWorker = isWorker
		})
		
		TradeOffers[Player.UserId].Accepted = false
		TradeOffers[TradeOffers[Player.UserId].Partner.UserId].Accepted = false

		Events.UpdatePartnerTradeOffer:FireClient(TradeOffers[Player.UserId].Partner, {
			Accepted = false,
		})
		Events.UpdatePartnerTradeOffer:FireClient(Player, {
			Accepted = false,
		})

		Events.UpdateOwnTradeOffer:FireClient(TradeOffers[Player.UserId].Partner,{
			Accepted = false,
		})

		Events.UpdateOwnTradeOffer:FireClient(Player,{
			Accepted = false,
		})
	end
end)

Events.RemoveFromTradeOffer.OnServerEvent:Connect(function(Player,Data)
	local trade = TradeOffers[Player.UserId]
	if not trade then return end

	local item = Data.Item
	local isWorker = Data.IsWorker

	if trade.Offers[item] then
		trade.Offers[item] = nil
	end

	-- Optional: notify both players
	local partnerPlayer = trade.Partner
	

	-- Fire update to trade partner to update their view
	if partnerPlayer then
		trade.Accepted = false
		TradeOffers[partnerPlayer.UserId].Accepted = false

		Events.UpdatePartnerTradeOffer:FireClient(partnerPlayer, {
			Accepted = false,
		})
		Events.UpdatePartnerTradeOffer:FireClient(Player, {
			Accepted = false,
		})

		Events.UpdateOwnTradeOffer:FireClient(partnerPlayer,{
			Accepted = false,
		})

		Events.UpdateOwnTradeOffer:FireClient(Player,{
			Accepted = false,
		})

		
		Events.UpdatePartnerTradeOffer:FireClient(partnerPlayer, {
			Item = item,
			RemoveItem = true,
			IsWorker = isWorker
		})
	end
end)

Events.CancelTrade.OnServerEvent:Connect(function(Player)
	local trade = TradeOffers[Player.UserId]
	if not trade then return end

	local partner = trade.Partner

	-- Notify both players if partner is valid
	if partner then
		Events.CancelTrade:FireClient(partner)
		cleanupTrade(partner)
	end
	cleanupTrade(Player)
	Events.CancelTrade:FireClient(Player)
end)

Events.AcceptTrade.OnServerEvent:Connect(function(player)
	local trade = TradeOffers[player.UserId]
	if not trade then return end
	local partner = trade.Partner
	if not partner then return end

	print(trade)
	trade.Accepted = true

	Events.UpdatePartnerTradeOffer:FireClient(partner, {
		Accepted = true,
	})

	Events.UpdateOwnTradeOffer:FireClient(player,{
		Accepted = true,
	})

	-- Check if partner also accepted
	if TradeOffers[partner.UserId].Accepted then
		-- Both accepted! Start 3-second countdown before finalizing trade
		delay(3, function()
			-- Recheck both accepted before completing
			if TradeOffers[player.UserId].Accepted and TradeOffers[partner.UserId].Accepted then
				if not TradeOffers[player.UserId] or not TradeOffers[partner.UserId] then return end
				if not TradeOffers[player.UserId].Accepted or not TradeOffers[partner.UserId].Accepted then return end

				local trade1 = TradeOffers[player.UserId]
				local trade2 = TradeOffers[partner.UserId]

				local playerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
				local partnerData = game.ServerStorage.PlayerData:FindFirstChild(partner.Name.."Data")
				if not playerData or not partnerData then return end

				-- Helpers
				local function parse(str)
					local result = {}
					for name, amount in string.gmatch(str, "([^:,]+):(%d+),") do
						result[name] = tonumber(amount)
					end
					return result
				end

				local function encode(tbl)
					local parts = {}
					for name, amount in pairs(tbl) do
						table.insert(parts, name..":"..amount..",")
					end
					return table.concat(parts)
				end

				local function applyTrade(giver, receiver, giverData, receiverData, offer)
					local collectionKey = offer.IsWorker and "CollectedWorkers" or "Collection"

					local giverTable = parse(giverData[collectionKey].Value)
					local receiverTable = parse(receiverData[collectionKey].Value)

					for itemName, data in pairs(offer.Offers) do
						local amount = data.Amount
						local isWorker = data.IsWorker
						local key = isWorker and "CollectedWorkers" or "Collection"

						-- Take from giver
						local giverItems = parse(giverData[key].Value)
						if giverItems[itemName] then
							giverItems[itemName] = giverItems[itemName] - amount
							if giverItems[itemName] <= 0 then
								giverItems[itemName] = nil
							end
							giverData[key].Value = encode(giverItems)
						end

						-- Add to receiver
						local receiverItems = parse(receiverData[key].Value)
						receiverItems[itemName] = (receiverItems[itemName] or 0) + amount
						receiverData[key].Value = encode(receiverItems)
						
						if not isWorker then
							Events.NewDrill:FireClient(receiver, itemName, amount)
						else
							Events.Alert:FireClient(receiver,"+"..amount.." "..itemName)
						end
					end
				end

				-- Transfer items
				applyTrade(player, partner, playerData, partnerData, trade1)
				applyTrade(partner, player, partnerData, playerData, trade2)

				-- Transfer diamonds
				local diamonds1 = tonumber(trade1.Diamonds) or 0
				local diamonds2 = tonumber(trade2.Diamonds) or 0

				playerData.Diamonds.Value -= diamonds1
				partnerData.Diamonds.Value += diamonds1

				partnerData.Diamonds.Value -= diamonds2
				playerData.Diamonds.Value += diamonds2
				
				Events.GemsChanged:FireClient(player)
				Events.GemsChanged:FireClient(partner)

				Events.RebuildWorkerUI:FireClient(player, {
					EquippedWorkers = playerData.EquippedWorkers.Value,
					CollectedWorkers = playerData.CollectedWorkers.Value,
				})

				Events.RebuildWorkerUI:FireClient(partner, {
					EquippedWorkers = partnerData.EquippedWorkers.Value,
					CollectedWorkers = partnerData.CollectedWorkers.Value,
				})

				-- Notify clients (e.g. to close UI)
				Events.CancelTrade:FireClient(partner)
				Events.CancelTrade:FireClient(player)
				
				cleanupTrade(partner)
				cleanupTrade(player)
			end
		end)
	end
end)

Events.TradeRequestsChange.OnServerEvent:Connect(function(Player, Action)
	if Action == "Off" then
		local TradeOff = Instance.new("Folder")
		TradeOff.Name = "TradeOff"
		TradeOff.Parent = Player
	else
		local success, policy = pcall(function()
			return game:GetService("PolicyService"):GetPolicyInfoForPlayerAsync(Player)
		end)

		if success and policy.IsPaidItemTradingAllowed then
			if Player:FindFirstChild("TradeOff") then
				Player.TradeOff:Destroy()
			end
		else
			-- Send alert if trading is not allowed
			game.ReplicatedStorage.Events.Alert:FireClient(Player, "Trading isn't allowed for your account.")
		end
	end
end)