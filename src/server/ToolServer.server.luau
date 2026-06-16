local Events = game.ReplicatedStorage.Events

local TweenService = game:GetService("TweenService")

local CrateData = require(game.ReplicatedStorage.Modules.CrateChances)
local ItemInfo = require(game.ReplicatedStorage.Modules.ItemInfo)
local WorkerInfo = require(game.ReplicatedStorage.Modules.WorkerInfo)
local cooldowns = {}

function Roll(crateName, luck)
	luck = luck or 1

	local crate = CrateData[crateName]
	if not crate then return end

	-- Calculate total weight using 1/value
	local totalWeight = 0
	for _, value in pairs(crate) do
		if value > 0 then
			totalWeight += (1 / value) * luck
		end
	end

	-- Perform the weighted roll
	local roll = math.random() * totalWeight
	local currentWeight = 0

	for itemName, value in pairs(crate) do
		if value > 0 then
			currentWeight += (1 / value) * luck
			if roll <= currentWeight then
				return itemName
			end
		end
	end
end

Events.ToolUse.OnServerEvent:Connect(function(Player, Tool)

	if not cooldowns[Player.Name] then
		cooldowns[Player.Name] = true
		task.delay(0.5,function()
			cooldowns[Player.Name] = nil
		end)
		
		local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
		if not Tool:GetAttribute("Pack") then return end
		
		
		if Tool.Name == "Worker Contract" and Tool:GetAttribute("Pack") == true then
			if Player:FindFirstChild("WorkerCapacity").Value >= 30 then 
				Events.Alert:FireClient(Player,"You have reached maximum Worker Capacity.")
				Player.Character:FindFirstChild("Humanoid"):UnequipTools()
				return 
			end
			local Tool = Player.Character:FindFirstChild("Worker Contract")
			
			if PlayerData.Collection then

				local SplitInventory: table = string.split(PlayerData.Collection.Value, ",")
				for i,v in pairs(SplitInventory) do
					local ItemAndAmount: table = string.split(v, ":")

					if ItemAndAmount[1] == Tool.Name then
						print("Player has used "..Tool.Name)

						local NewAmount = tonumber(ItemAndAmount[2]) - 1

						print(ItemAndAmount[1]..":"..NewAmount..",")
						if NewAmount <= 0 then
							PlayerData.Collection.Value = string.gsub(PlayerData.Collection.Value,v..",","")
							Tool:Destroy()
						else
							PlayerData.Collection.Value = string.gsub(PlayerData.Collection.Value,v..",",ItemAndAmount[1]..":"..NewAmount..",")

							Tool:SetAttribute("Amount",NewAmount)
							Player.Character:FindFirstChild("Humanoid"):UnequipTools()
						end


					end
				end
			end
			
			Events.GetNewWorker:Fire(Player,"Worker Contract")
			
			
		end
		
		if (Tool.Name == "Chest" or Tool.Name == "Void Chest" or Tool.Name == "Abyssal Void Chest" or Tool.Name == "Forest Chest" or Tool.Name == "Boundless Depths Chest") and not Player:FindFirstChild("OpeningCase") and Tool:GetAttribute("Pack") == true then
			-- Check if player character exists and has humanoid
			if not Player.Character or not Player.Character:FindFirstChild("Humanoid") then
				return
			end

			if Player:FindFirstChild("WorkerCapacity") and Player:FindFirstChild("WorkerCapacity").Value >= 30 then 
				Events.Alert:FireClient(Player, "You have reached maximum Worker Capacity.")
				Player.Character:FindFirstChild("Humanoid"):UnequipTools()
				return 
			end

			-- Store reference to the tool in character
			local characterTool = Player.Character:FindFirstChild(Tool.Name)
			if not characterTool then
				return
			end

			if PlayerData.Collection then
				-- Create opening case lock
				local OpeningCase = Instance.new("Folder")
				OpeningCase.Name = "OpeningCase"
				OpeningCase.Parent = Player

				-- Use a more reliable cleanup method
				local cleanupConnection
				cleanupConnection = game:GetService("RunService").Heartbeat:Connect(function()
					if not OpeningCase or not OpeningCase.Parent then
						cleanupConnection:Disconnect()
					end
				end)
				delay(8, function()
					if OpeningCase and OpeningCase.Parent then
						OpeningCase:Destroy()
					end
					if cleanupConnection then
						cleanupConnection:Disconnect()
					end
				end)

				if CrateData[Tool.Name] then
					local RolledItem
					if PlayerData.PityPer50.Value == 50 then
						RolledItem = Roll(Tool.Name, 5)
						PlayerData.PityPer50.Value = 0
						PlayerData.PityPer10.Value = 0
						Events.MainAlert:FireClient(Player, "Deluxe lucky roll activated!", Color3.new(0.513725, 0.113725, 1))
					elseif PlayerData.PityPer10.Value == 10 then
						RolledItem = Roll(Tool.Name, 2)
						PlayerData.PityPer10.Value = 0
						Events.MainAlert:FireClient(Player, "Lucky roll activated!", Color3.new(1, 0.67451, 0.14902))
					else
						RolledItem = Roll(Tool.Name, 1)
						PlayerData.PityPer10.Value += 1
						PlayerData.PityPer50.Value += 1

						if PlayerData.PityPer50.Value == 50 then
							Events.MainAlert:FireClient(Player, "Deluxe lucky roll unlocked! Next roll will have 5x luck!", Color3.new(0.513725, 0.113725, 1))
						elseif PlayerData.PityPer10.Value == 10 then
							Events.MainAlert:FireClient(Player, "Lucky roll unlocked! Next roll will have 2x luck!", Color3.new(1, 0.752941, 0.129412))
						else
							Events.MainAlert:FireClient(Player, "Lucky roll "..PlayerData.PityPer10.Value.."/10", Color3.new(0.298039, 1, 0.615686))
							Events.MainAlert:FireClient(Player, "Deluxe lucky roll "..PlayerData.PityPer50.Value.."/50", Color3.new(0.662745, 0.254902, 1))
						end
					end

					-- Validate the rolled item
					if not RolledItem or (not ItemInfo[RolledItem] and not WorkerInfo[RolledItem]) then
						Events.Alert:FireClient(Player, "Error: Invalid item rolled. Please try again.")
						if OpeningCase then OpeningCase:Destroy() end
						return
					end

					local unboxTime = 7
					Events.OpenCrate:FireClient(Player, Tool.Name, RolledItem, unboxTime)

					-- Safely parse and update collection with error handling
					local success, err = pcall(function()
						local collection = {}
						-- Handle empty or malformed collection string
						local collectionValue = PlayerData.Collection.Value
						if collectionValue and collectionValue ~= "" then
							for name, amount in string.gmatch(collectionValue, "([^:,]+):(%d+),?") do
								if name and amount then
									collection[name] = tonumber(amount)
								end
							end
						end

						-- Decrement the crate count (ensure it doesn't go negative)
						collection[Tool.Name] = math.max((collection[Tool.Name] or 0) - 1, 0)

						-- Rebuild collection string
						local newCollection = ""
						for name, amount in pairs(collection) do
							if amount > 0 then
								newCollection = newCollection .. name .. ":" .. amount .. ","
							end
						end
						PlayerData.Collection.Value = newCollection
					end)

					if not success then
						warn("Error updating collection: " .. tostring(err))
						Events.Alert:FireClient(Player, "Error updating inventory. Please try again.")
						if OpeningCase then OpeningCase:Destroy() end
						return
					end

					-- Add the rolled item after delay with proper error handling
					task.delay(7, function()
						if not Player or not Player.Parent then return end -- Player left game

						local success, err = pcall(function()
							if RolledItem and ItemInfo[RolledItem] then
								local collection = {}
								local collectionValue = PlayerData.Collection.Value
								if collectionValue and collectionValue ~= "" then
									for name, amount in string.gmatch(collectionValue, "([^:,]+):(%d+),?") do
										if name and amount then
											collection[name] = tonumber(amount)
										end
									end
								end

								collection[RolledItem] = (collection[RolledItem] or 0) + 1

								local newCollection = ""
								for name, amount in pairs(collection) do
									if amount > 0 then
										newCollection = newCollection .. name .. ":" .. amount .. ","
									end
								end
								PlayerData.Collection.Value = newCollection

							elseif RolledItem and WorkerInfo[RolledItem] then
								if WorkerInfo[RolledItem].Rarity == "Common" and Player:FindFirstChild("AutoSellCommons") then
									task.delay(2.2, function()
										if Player and Player.Parent then
											Events.Alert:FireClient(Player, "Auto deleted "..RolledItem..".")
										end
									end)
									return
								end
								if WorkerInfo[RolledItem].Rarity == "Uncommon" and Player:FindFirstChild("AutoSellRares") then
									task.delay(2.2, function()
										if Player and Player.Parent then
											Events.Alert:FireClient(Player, "Auto deleted "..RolledItem..".")
										end
									end)
									return
								end

								local collectionTable = {}
								local workersValue = PlayerData.CollectedWorkers.Value
								if workersValue and workersValue ~= "" then
									for name, amount in string.gmatch(workersValue, "([^:,]+):(%d+),?") do
										if name and amount then
											collectionTable[name] = tonumber(amount)
										end
									end
								end

								collectionTable[RolledItem] = (collectionTable[RolledItem] or 0) + 1

								local newCollection = ""
								for name, amount in pairs(collectionTable) do
									newCollection = newCollection .. name .. ":" .. amount .. ","
								end
								PlayerData.CollectedWorkers.Value = newCollection

								if Player:FindFirstChild("WorkerCapacity") then
									Player.WorkerCapacity.Value = math.min(Player.WorkerCapacity.Value + 1, 30)
									Events.UpdateWorkerCapacity:FireClient(Player)
								end

								game.ReplicatedStorage.Events.RebuildWorkerUI:FireClient(Player, {
									EquippedWorkers = PlayerData.EquippedWorkers.Value,
									CollectedWorkers = PlayerData.CollectedWorkers.Value,
								})
							end
						end)

						if not success then
							warn("Error adding rolled item: " .. tostring(err))
							if Player and Player.Parent then
								Events.Alert:FireClient(Player, "Error adding item to inventory. Contact support.")
							end
						end
					end)
				end
			end
		end
		
		if Tool.Name == "Player Contract" and Tool:GetAttribute("Pack") == true then
			if Player:FindFirstChild("WorkerCapacity").Value >= 30 then 
				Events.Alert:FireClient(Player,"You have reached maximum Worker Capacity.")
				Player.Character:FindFirstChild("Humanoid"):UnequipTools()
				return 
			end
			local Tool = Player.Character:FindFirstChild("Player Contract")

			if PlayerData.Collection then

				local SplitInventory: table = string.split(PlayerData.Collection.Value, ",")
				for i,v in pairs(SplitInventory) do
					local ItemAndAmount: table = string.split(v, ":")

					if ItemAndAmount[1] == Tool.Name then
						print("Player has used "..Tool.Name)

						local NewAmount = tonumber(ItemAndAmount[2]) - 1

						print(ItemAndAmount[1]..":"..NewAmount..",")
						if NewAmount <= 0 then
							PlayerData.Collection.Value = string.gsub(PlayerData.Collection.Value,v..",","")
							Tool:Destroy()
						else
							PlayerData.Collection.Value = string.gsub(PlayerData.Collection.Value,v..",",ItemAndAmount[1]..":"..NewAmount..",")

							Tool:SetAttribute("Amount",NewAmount)
							Player.Character:FindFirstChild("Humanoid"):UnequipTools()
						end


					end
				end
			end

			Events.GetNewWorker:Fire(Player,"Player Contract")


		end
		
		if Tool.Name == "Summer Pack" and Tool:GetAttribute("Pack") == true then
			if Player:FindFirstChild("WorkerCapacity").Value >= 30 then 
				Events.Alert:FireClient(Player,"You have reached maximum Worker Capacity.")
				Player.Character:FindFirstChild("Humanoid"):UnequipTools()
				return 
			end
			local Tool = Player.Character:FindFirstChild("Summer Pack")

			if PlayerData.Collection then

				local SplitInventory: table = string.split(PlayerData.Collection.Value, ",")
				for i,v in pairs(SplitInventory) do
					local ItemAndAmount: table = string.split(v, ":")

					if ItemAndAmount[1] == Tool.Name then
						print("Player has used "..Tool.Name)

						local NewAmount = tonumber(ItemAndAmount[2]) - 1

						print(ItemAndAmount[1]..":"..NewAmount..",")
						if NewAmount <= 0 then
							PlayerData.Collection.Value = string.gsub(PlayerData.Collection.Value,v..",","")
							Tool:Destroy()
						else
							PlayerData.Collection.Value = string.gsub(PlayerData.Collection.Value,v..",",ItemAndAmount[1]..":"..NewAmount..",")

							Tool:SetAttribute("Amount",NewAmount)
							Player.Character:FindFirstChild("Humanoid"):UnequipTools()
						end


					end
				end
			end

			Events.OpenEventPack:Fire(Player)


		end
		
		if Tool.Name == "Rain Totem" and Tool:GetAttribute("Pack") == true then
			local Tool = Player.Character:FindFirstChild("Rain Totem")

			if PlayerData.Collection then

				local SplitInventory: table = string.split(PlayerData.Collection.Value, ",")
				for i,v in pairs(SplitInventory) do
					local ItemAndAmount: table = string.split(v, ":")

					if ItemAndAmount[1] == Tool.Name then
						print("Player has used "..Tool.Name)

						local NewAmount = tonumber(ItemAndAmount[2]) - 1

						print(ItemAndAmount[1]..":"..NewAmount..",")
						if NewAmount <= 0 then
							PlayerData.Collection.Value = string.gsub(PlayerData.Collection.Value,v..",","")
							Tool:Destroy()
						else
							PlayerData.Collection.Value = string.gsub(PlayerData.Collection.Value,v..",",ItemAndAmount[1]..":"..NewAmount..",")

							Tool:SetAttribute("Amount",NewAmount)
							Player.Character:FindFirstChild("Humanoid"):UnequipTools()
						end


					end
				end
			end
			
			local TotemEffect = game.Workspace:FindFirstChild("Weather"):FindFirstChild("TotemEffect")
			TotemEffect.Value = "Rain"
			
			Events.Alert:FireAllClients(Player.Name.." has used a "..Tool.Name)
		end
		
		if Tool.Name == "Arcane Totem" and Tool:GetAttribute("Pack") == true then
			local Tool = Player.Character:FindFirstChild("Arcane Totem")

			if PlayerData.Collection then

				local SplitInventory: table = string.split(PlayerData.Collection.Value, ",")
				for i,v in pairs(SplitInventory) do
					local ItemAndAmount: table = string.split(v, ":")

					if ItemAndAmount[1] == Tool.Name then
						print("Player has used "..Tool.Name)

						local NewAmount = tonumber(ItemAndAmount[2]) - 1

						print(ItemAndAmount[1]..":"..NewAmount..",")
						if NewAmount <= 0 then
							PlayerData.Collection.Value = string.gsub(PlayerData.Collection.Value,v..",","")
							Tool:Destroy()
						else
							PlayerData.Collection.Value = string.gsub(PlayerData.Collection.Value,v..",",ItemAndAmount[1]..":"..NewAmount..",")

							Tool:SetAttribute("Amount",NewAmount)
							Player.Character:FindFirstChild("Humanoid"):UnequipTools()
						end


					end
				end
			end

			local TotemEffect = game.Workspace:FindFirstChild("Weather"):FindFirstChild("TotemEffect")
			TotemEffect.Value = "Arcane"

			Events.Alert:FireAllClients(Player.Name.." has used a "..Tool.Name)
		end
		
		if Tool.Name == "Void Totem" and Tool:GetAttribute("Pack") == true then
			local Tool = Player.Character:FindFirstChild("Void Totem")

			if PlayerData.Collection then

				local SplitInventory: table = string.split(PlayerData.Collection.Value, ",")
				for i,v in pairs(SplitInventory) do
					local ItemAndAmount: table = string.split(v, ":")

					if ItemAndAmount[1] == Tool.Name then
						print("Player has used "..Tool.Name)

						local NewAmount = tonumber(ItemAndAmount[2]) - 1

						print(ItemAndAmount[1]..":"..NewAmount..",")
						if NewAmount <= 0 then
							PlayerData.Collection.Value = string.gsub(PlayerData.Collection.Value,v..",","")
							Tool:Destroy()
						else
							PlayerData.Collection.Value = string.gsub(PlayerData.Collection.Value,v..",",ItemAndAmount[1]..":"..NewAmount..",")

							Tool:SetAttribute("Amount",NewAmount)
							Player.Character:FindFirstChild("Humanoid"):UnequipTools()
						end


					end
				end
			end

			local TotemEffect = game.Workspace:FindFirstChild("Weather"):FindFirstChild("TotemEffect")
			TotemEffect.Value = "Void"

			Events.Alert:FireAllClients(Player.Name.." has used a "..Tool.Name)
		end
		if Tool.Name == "Nature Totem" and Tool:GetAttribute("Pack") == true then
			local Tool = Player.Character:FindFirstChild("Nature Totem")

			if PlayerData.Collection then

				local SplitInventory: table = string.split(PlayerData.Collection.Value, ",")
				for i,v in pairs(SplitInventory) do
					local ItemAndAmount: table = string.split(v, ":")

					if ItemAndAmount[1] == Tool.Name then
						print("Player has used "..Tool.Name)

						local NewAmount = tonumber(ItemAndAmount[2]) - 1

						print(ItemAndAmount[1]..":"..NewAmount..",")
						if NewAmount <= 0 then
							PlayerData.Collection.Value = string.gsub(PlayerData.Collection.Value,v..",","")
							Tool:Destroy()
						else
							PlayerData.Collection.Value = string.gsub(PlayerData.Collection.Value,v..",",ItemAndAmount[1]..":"..NewAmount..",")

							Tool:SetAttribute("Amount",NewAmount)
							Player.Character:FindFirstChild("Humanoid"):UnequipTools()
						end


					end
				end
			end

			local TotemEffect = game.Workspace:FindFirstChild("Weather"):FindFirstChild("TotemEffect")
			TotemEffect.Value = "Nature"

			Events.Alert:FireAllClients(Player.Name.." has used a "..Tool.Name)
		end
		
		local BoostDuration = 300 -- 5 minutes

		local function applyLuckBoost(Player, Tool, boostName)
			local existingBoost = Player:FindFirstChild(boostName)

			if existingBoost then
				local expiresAt = existingBoost:FindFirstChild("ExpiresAt")
				if expiresAt then
					local newExpireTime = math.max(expiresAt.Value, os.time()) + BoostDuration
					expiresAt.Value = newExpireTime
					Events.Alert:FireClient(Player, "Luck boost extended by 5 minutes!")
				end
			else
				-- Create new boost
				local LuckBoost = Instance.new("Folder")
				LuckBoost.Name = boostName
				LuckBoost.Parent = Player

				local ExpiresAt = Instance.new("NumberValue")
				ExpiresAt.Name = "ExpiresAt"
				ExpiresAt.Value = os.time() + BoostDuration
				ExpiresAt.Parent = LuckBoost

				-- Manually remove the boost after it expires
				task.spawn(function()
					while LuckBoost and LuckBoost.Parent do
						if os.time() >= ExpiresAt.Value then
							LuckBoost:Destroy()
							break
						end
						task.wait(1)
					end
				end)

				Events.Alert:FireClient(Player, "You have used " .. Tool.Name)
			end
		end

		-- Handle tool usage
		local toolName = Tool.Name
		local pack = Tool:GetAttribute("Pack")

		if (toolName == "Simple Luck Potion" or toolName == "Advanced Luck Potion" or toolName == "Mythical Luck Potion") and pack == true then
			local boostName = toolName:gsub("Potion", "Boost") -- "Simple Luck Potion" → "Simple Luck Boost"
			applyLuckBoost(Player, Tool, boostName)

			-- Update inventory
			if PlayerData.Collection then
				local SplitInventory: table = string.split(PlayerData.Collection.Value, ",")
				for i,v in pairs(SplitInventory) do
					local ItemAndAmount: table = string.split(v, ":")

					if ItemAndAmount[1] == Tool.Name then
						local NewAmount = tonumber(ItemAndAmount[2]) - 1
						if NewAmount <= 0 then
							PlayerData.Collection.Value = string.gsub(PlayerData.Collection.Value, v .. ",", "")
							Tool:Destroy()
						else
							PlayerData.Collection.Value = string.gsub(PlayerData.Collection.Value, v .. ",", ItemAndAmount[1] .. ":" .. NewAmount .. ",")
							Tool:SetAttribute("Amount", NewAmount)
							Player.Character:FindFirstChild("Humanoid"):UnequipTools()
						end
						break
					end
				end
			end
		end
		
		
		if (toolName == "Pickaxe" or toolName == "Dwarven Pickaxe" or toolName == "Reality Crusher") and pack == true then
			local Character = Player.Character
			local Humanoid = Character:FindFirstChild("Humanoid")
			if not Character or not Character:FindFirstChild("HumanoidRootPart") or not Humanoid then return end

			local root = Character.HumanoidRootPart
			local nearestOre = {}
			local shortestDist = 12
			
			local dmg = 1
			if toolName == "Pickaxe" then
				dmg = 1
			elseif toolName == "Dwarven Pickaxe" then
				dmg = 5
			elseif toolName == "Reality Crusher" then
				dmg = 25
			end

			if Character:FindFirstChild("Right Arm") then
				local Animation = Humanoid:LoadAnimation(game.ReplicatedStorage.Animations.PickaxeR6)
				Animation:Play()
			else
				local Animation = Humanoid:LoadAnimation(game.ReplicatedStorage.Animations.PickaxeR15)
				Animation:Play()
			end

			task.wait(0.3)
			-- Find nearest ore
			for _, ore in ipairs(workspace.Ores:GetChildren()) do
				if ore:IsA("Model") and ore:FindFirstChild("Health") and ore.Health:IsA("IntValue") then
					local orePos = ore:GetPivot().Position
					local dist = (root.Position - orePos).Magnitude
					if dist < shortestDist then
						table.insert(nearestOre,ore)
					end
				end
			end

			-- Reduce health
			if nearestOre and nearestOre[1] then
				game.ReplicatedStorage.Events.CameraShake:FireClient(Player,"Bump")
				for i,v in pairs(nearestOre) do
					local originalCFrame = v:GetPivot()
					local shakeOffset = CFrame.Angles(0, 0, math.rad(10)) -- small rotation

					local tween1 = TweenService:Create(v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart"),
						TweenInfo.new(0.05, Enum.EasingStyle.Linear),
						{CFrame = originalCFrame * shakeOffset}
					)

					local tween2 = TweenService:Create(v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart"),
						TweenInfo.new(0.05, Enum.EasingStyle.Linear),
						{CFrame = originalCFrame}
					)

					tween1:Play()
					tween1.Completed:Connect(function()
						tween2:Play()
					end)
					
					local health = v.Health
					health.Value -= dmg

					local Properties = {
						Type = "PickaxeHit";
						Specifics1 = v.PrimaryPart.Position;
					}

					Events.ClientFX:FireClient(Player,Properties)
					-- If destroyed
					if health.Value <= 0 then
						-- Example: Destroy the ore and maybe spawn loo
						
						local Properties = {
							Type = "PickaxeBreak";
							Specifics1 = v.PrimaryPart.Position;
						}

						Events.ClientFX:FireClient(Player,Properties)
						
						local collectionTable = {}
						for name, amount in string.gmatch(PlayerData.Collection.Value .. ",", "([^:,]+):(%d+),") do
							collectionTable[name] = tonumber(amount)
						end
						if v:FindFirstChild("Loot").Value == "Abyssal Void Chest" or v:FindFirstChild("Loot").Value == "Void Chest" then
							collectionTable[v:FindFirstChild("Loot").Value] = (collectionTable[v:FindFirstChild("Loot").Value] or 0) + 1
							local AlertTable = {
								[v:FindFirstChild("Loot").Value] = 1
							}
							Events.NewItems:FireClient(Player, AlertTable)
						else
							collectionTable[v:FindFirstChild("Loot").Value] = (collectionTable[v:FindFirstChild("Loot").Value] or 0) + 5
							local AlertTable = {
								[v:FindFirstChild("Loot").Value] = 5
							}
							Events.NewItems:FireClient(Player, AlertTable)

						end

						-- Update collection string
						local newCollection = ""
						for name, amount in pairs(collectionTable) do
							newCollection ..= name .. ":" .. amount .. ","
						end
						PlayerData.Collection.Value = newCollection
						
						v:Destroy()
					end
				end
			end
		end
		
	end
end)