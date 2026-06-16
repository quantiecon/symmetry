local Events = game.ReplicatedStorage.Events

local BuffManager = require(game.ReplicatedStorage.Modules.BuffManager)
local WorkerInfo = require(game.ReplicatedStorage.Modules.WorkerInfo)

local Chances = {
	{"Pickaxe Pete", 2, Color3.fromRGB(157, 255, 121)},
	{"Dusty Dana", 2, Color3.fromRGB(157, 255, 121)},
	{"Miner Mike", 2, Color3.fromRGB(157, 255, 121)},
	{"Sandy Sarah", 2, Color3.fromRGB(157, 255, 121)},
	{"Shovel Shane", 2, Color3.fromRGB(157, 255, 121)},

	-- Rare
	{"Rusty Ray", 5, Color3.fromRGB(121, 233, 255)},
	{"Tunnel Tina", 7, Color3.fromRGB(121, 233, 255)},

	-- Epic
	{"Cave Carla", 20, Color3.fromRGB(212, 121, 255)},

	-- Legendary
	{"Aetherborn", 70, Color3.fromRGB(255, 195, 84)},
	{"Frostborn Guard", 70, Color3.fromRGB(255, 195, 84)},
}

local PlayerChances = {
	-- Rare
	{"lil xxtension", 2, Color3.fromRGB(121, 233, 255)},
	{"yukki", 2, Color3.fromRGB(121, 233, 255)},

	-- Epic
	{"akuma", 10, Color3.fromRGB(212, 121, 255)},
	{"albert", 10, Color3.fromRGB(212, 121, 255)},
	{"cog", 10, Color3.fromRGB(212, 121, 255)},

	-- Legendary
	{"Mysterious Investor", 90, Color3.fromRGB(255, 33, 37)},
	{"sunny", 50, Color3.fromRGB(255, 33, 37)},
	{"bean", 50, Color3.fromRGB(255, 33, 37)},
}


local EasyChances = {
	"Pyronite",
	"Silver",
	"Gold",
}
local MediumChances = {
	"Shadowite",
	"Obscurite",
	"Cryozite",
}
local HardChances = {
	"Demonite",
	"Aethersteel",
}

local function getOneFromEachDifficulty()
	local function pickRandom(list)
		return list[math.random(1, #list)]
	end

	local easyOre = pickRandom(EasyChances)
	local mediumOre = pickRandom(MediumChances)
	local hardOre = pickRandom(HardChances)

	local stock = {
		easyOre .. ":" .. math.random(3, 5),
		mediumOre .. ":" .. math.random(3, 5),
		hardOre .. ":" .. math.random(3, 5),
	}

	return table.concat(stock, ",") .. "," -- comma at end to match your parsing logic
end


local function pickRandomCharacter(Player,LootPool)
	local totalWeight = 0
	local weights = {}

	local LuckObject = Player.Character and Player.Character:FindFirstChild("Luck")
	local Luck = (LuckObject and LuckObject.Value) or 1

	-- Calculate weights
	for _, data in ipairs(LootPool) do
		local chance = data[2]
		local weight = 1 / chance
		table.insert(weights, weight)
		totalWeight += weight
	end

	-- Pick a random point
	local randomPoint = math.random() * totalWeight
	local current = 0

	for i, weight in ipairs(weights) do
		current += weight
		if randomPoint <= current then
			return LootPool[i]
		end
	end
end

Events.GetNewWorker.Event:Connect(function(Player,LootPool)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	if PlayerData then
		if Player:FindFirstChild("WorkerCapacity").Value >= 30 then return end
		local characterData 
		if LootPool == "Worker Contract" then
			characterData = pickRandomCharacter(Player,Chances)
		elseif LootPool == "Player Contract" then
			characterData = pickRandomCharacter(Player,PlayerChances)
		else
			characterData = pickRandomCharacter(Player,Chances)
		end
		local CharacterName = characterData[1]

		if WorkerInfo[CharacterName].Rarity == "Common" and Player:FindFirstChild("AutoSellCommons") then
			task.delay(2.2,function()
				Events.Alert:FireClient(Player,"Auto deleted "..CharacterName..".")
			end)

			local Properties = {
				Type = "Worker Contract";
				Specifics1 = CharacterName;
			}

			Events.ClientFX:FireClient(Player,Properties)
			return
		end
		if WorkerInfo[CharacterName].Rarity == "Uncommon" and Player:FindFirstChild("AutoSellRares") then
			task.delay(2.2,function()
				Events.Alert:FireClient(Player,"Auto deleted "..CharacterName..".")
			end)

			local Properties = {
				Type = "Worker Contract";
				Specifics1 = CharacterName;
			}

			Events.ClientFX:FireClient(Player,Properties)
			return
		end
		
		local collectionTable = {}
		for name, amount in string.gmatch(PlayerData.CollectedWorkers.Value or ",", "([^:,]+):(%d+),") do
			collectionTable[name] = tonumber(amount)
		end
		collectionTable[CharacterName] = (collectionTable[CharacterName] or 0) + 1

		-- Update collection string
		local newCollection = ""
		for name, amount in pairs(collectionTable) do
			newCollection ..= name .. ":" .. amount .. ","
		end
		PlayerData.CollectedWorkers.Value = newCollection
		
		if Player:FindFirstChild("WorkerCapacity") then
			Player:FindFirstChild("WorkerCapacity").Value += 1
			Events.UpdateWorkerCapacity:FireClient(Player)
		end
		
		game.ReplicatedStorage.Events.RebuildWorkerUI:FireClient(Player, {
			EquippedWorkers = PlayerData.EquippedWorkers.Value,
			CollectedWorkers = PlayerData.CollectedWorkers.Value,
		})
		
		task.delay(2.2,function()
			Events.Alert:FireClient(Player,"You have rolled "..CharacterName..".")
		end)
		
		local Properties = {
			Type = "Worker Contract";
			Specifics1 = CharacterName;
		}
		
		Events.ClientFX:FireClient(Player,Properties)
	end
end)

local function parseWorkerString(workerStr)
	local result = {}
	for _, v in ipairs(string.split(workerStr, ",")) do
		if v ~= "" then
			local parts = string.split(v, ":")
			local name, count = parts[1], tonumber(parts[2])
			if name and count then
				result[name] = count
			end
		end
	end
	return result
end

local function serializeWorkerTable(workerTable)
	local strList = {}
	for name, count in pairs(workerTable) do
		if count > 0 then
			table.insert(strList, name .. ":" .. count)
		end
	end
	return table.concat(strList, ",")
end

game.ReplicatedStorage.Events.EquipWorker.OnServerEvent:Connect(function(player, action, workerValue)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
	local workerName = workerValue

	-- Retrieve and parse strings
	local maxWorkers = 3
	if PlayerData.WorkerSlots.Value == "Tier1" then
		maxWorkers = 4
	elseif PlayerData.WorkerSlots.Value == "Tier2" then
		maxWorkers = 5
	end
	local equippedStr = PlayerData.EquippedWorkers.Value or ""
	local collectedStr = PlayerData.CollectedWorkers.Value or ""

	local equipped = parseWorkerString(equippedStr)
	local collected = parseWorkerString(collectedStr)

	local totalEquipped = 0
	for _, count in pairs(equipped) do
		totalEquipped += count
	end

	if action == "Equip" then
		if totalEquipped >= maxWorkers then return end
		print(collected)
		print(workerName)
		if (collected[workerName] or 0) <= 0 then return end
		
		-- Proceed with transfer regardless of collected presence
		collected[workerName] = (collected[workerName] or 0) - 1
		if collected[workerName] <= 0 then
			collected[workerName] = nil
		end

		equipped[workerName] = (equipped[workerName] or 0) + 1
		
		local Plot
		for _, plot in pairs(game.Workspace.Plots:GetChildren()) do
			if plot:FindFirstChild("Owner") and plot.Owner.Value == player.Name then
				Plot = plot
				break
			end
		end
		
		local PlotWorkers = game.Workspace:FindFirstChild(player.Name.."Workers")
		if PlotWorkers then
			local Worker = game.ReplicatedStorage.Workers:FindFirstChild(workerName):Clone()
			Worker.Parent = PlotWorkers
			Worker.PrimaryPart.CFrame = Plot.WorkerSpawner.CFrame

			local Cooldown = Instance.new("Folder")
			Cooldown.Name = "Cooldown"
			Cooldown.Parent = Worker
			game.Debris:AddItem(Cooldown,10)

			task.spawn(function()
				BuffManager:Passive(player,Worker)

				while true do
					if not Worker or not player or not Plot then
						break
					end
					local x = Plot.Position.X + math.random(-Plot.Size.X/2,Plot.Size.X/2)
					local y = Plot.Position.Y + math.random(-Plot.Size.Y/2,Plot.Size.Y/2)
					local z = Plot.Position.Z + math.random(-Plot.Size.Z/2,Plot.Size.Z/2)

					Worker:FindFirstChild("Humanoid"):MoveTo(Vector3.new(x,y,z))
					task.wait(30)
				end
			end)
		end

	elseif action == "Unequip" then
		if (equipped[workerName] or 0) <= 0 then return end -- nothing to unequip
		
		local PlotWorkers = game.Workspace:FindFirstChild(player.Name.."Workers")
		if PlotWorkers then
			local Worker = PlotWorkers:FindFirstChild(workerName)
			Worker:Destroy()
		end
		
		-- Transfer from equipped to collected
		equipped[workerName] -= 1
		if equipped[workerName] <= 0 then
			equipped[workerName] = nil
		end

		collected[workerName] = (collected[workerName] or 0) + 1
	end

	-- Serialize and update
	local newEquippedStr = serializeWorkerTable(equipped)
	local newCollectedStr = serializeWorkerTable(collected)

	PlayerData.EquippedWorkers.Value = newEquippedStr
	PlayerData.CollectedWorkers.Value = newCollectedStr

	-- Update the UI on client
	game.ReplicatedStorage.Events.RebuildWorkerUI:FireClient(player, {
		EquippedWorkers = newEquippedStr,
		CollectedWorkers = newCollectedStr,
	})
end)

Events.FireWorker.OnServerEvent:Connect(function(Player,WorkerName,IsEquipped)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	local PlotWorkers = game.Workspace:FindFirstChild(Player.Name.."Workers")
	if PlayerData then
		if IsEquipped then
			local SplitInventory: table = string.split(PlayerData.EquippedWorkers.Value, ",")
			for i,v in pairs(SplitInventory) do
				local ItemAndAmount: table = string.split(v, ":")

				if ItemAndAmount[1] == WorkerName then

					local NewAmount = tonumber(ItemAndAmount[2]) - 1

					print(ItemAndAmount[1]..":"..NewAmount..",")
					if NewAmount <= 0 then
						PlayerData.EquippedWorkers.Value = string.gsub(PlayerData.EquippedWorkers.Value,v,"")
					else
						PlayerData.EquippedWorkers.Value = string.gsub(PlayerData.EquippedWorkers.Value,v,ItemAndAmount[1]..":"..NewAmount)
					end
				end
			end
			
			if PlotWorkers:FindFirstChild(WorkerName) then
				PlotWorkers:FindFirstChild(WorkerName):Destroy()
			end
		else
			local SplitInventory: table = string.split(PlayerData.CollectedWorkers.Value, ",")
			for i,v in pairs(SplitInventory) do
				local ItemAndAmount: table = string.split(v, ":")

				if ItemAndAmount[1] == WorkerName then

					local NewAmount = tonumber(ItemAndAmount[2]) - 1

					print(ItemAndAmount[1]..":"..NewAmount..",")
					if NewAmount <= 0 then
						PlayerData.CollectedWorkers.Value = string.gsub(PlayerData.CollectedWorkers.Value,v,"")
					else
						PlayerData.CollectedWorkers.Value = string.gsub(PlayerData.CollectedWorkers.Value,v,ItemAndAmount[1]..":"..NewAmount)
					end
				end
			end
		end
		
		if Player:FindFirstChild("WorkerCapacity") then
			Player:FindFirstChild("WorkerCapacity").Value -= 1
			Events.UpdateWorkerCapacity:FireClient(Player)
		end
		game.ReplicatedStorage.Events.RebuildWorkerUI:FireClient(Player, {
			EquippedWorkers = PlayerData.EquippedWorkers.Value,
			CollectedWorkers = PlayerData.CollectedWorkers.Value,
		})
	end
end)

game.Players.PlayerAdded:Connect(function(Player)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	if not PlayerData then
		repeat wait()
			PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
		until PlayerData
	end

	if PlayerData then
		-- Initial roll if needed
		if PlayerData.ContractRefresh.Value <= 0 then
			PlayerData.ContractRefresh.Value = 300
			PlayerData.ContractStock.Value = getOneFromEachDifficulty()

			Events.UpdateContractStock:FireClient(Player)
		end

		Events.UpdateContractStock:FireClient(Player)



		-- Start refresh countdown
		task.spawn(function()
			while true do
				if not Player or not PlayerData then
					break
				end
				wait(1)
				PlayerData.ContractRefresh.Value -= 1

				if PlayerData.ContractRefresh.Value <= 0 then
					PlayerData.ContractRefresh.Value = 300
					PlayerData.ContractStock.Value = getOneFromEachDifficulty()

					Events.UpdateContractStock:FireClient(Player)
				end
			end
		end)
	end
end)

Events.ContractTrade.OnServerEvent:Connect(function(Player, Ore)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	if not PlayerData then
		repeat wait()
			PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
		until PlayerData
	end

	if not PlayerData then return end

	local SplitStock = string.split(PlayerData.ContractStock.Value, ",")
	for _, entry in ipairs(SplitStock) do
		if entry ~= "" then
			local OreName, RequiredAmount = unpack(string.split(entry, ":"))
			RequiredAmount = tonumber(RequiredAmount)

			if OreName == Ore then
				-- Parse current Collection
				local collection = {}
				for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
					collection[name] = tonumber(amount)
				end

				local ownedAmount = collection[Ore] or 0
				if ownedAmount >= RequiredAmount then
					-- Deduct ore
					collection[Ore] = ownedAmount - RequiredAmount
					if collection[Ore] <= 0 then
						collection[Ore] = nil
					end

					-- Add to Summer Pack
					collection["Worker Contract"] = (collection["Worker Contract"] or 0) + 1

					-- Rebuild collection string
					local newCollection = ""
					for name, amount in pairs(collection) do
						newCollection ..= name .. ":" .. amount .. ","
					end
					PlayerData.Collection.Value = newCollection

					-- Remove the purchased ore from EventStock
					local newStock = ""
					for _, otherEntry in ipairs(SplitStock) do
						if otherEntry ~= "" then
							local n, _ = unpack(string.split(otherEntry, ":"))
							if n ~= Ore then
								newStock ..= otherEntry .. ","
							end
						end
					end
					PlayerData.ContractStock.Value = newStock

					Events.UpdateContractStock:FireClient(Player)

					-- Optional: fire UI update event if needed
					Events.NewDrill:FireClient(Player, "Worker Contract", 1)

					break -- Stop after match
				end
			end
		end
	end
end)