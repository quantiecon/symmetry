local DataManager = require(game.ServerScriptService.DataHandler) 
local ItemInfo = require(game.ReplicatedStorage.Modules.ItemInfo)
local BuffManager = require(game.ReplicatedStorage.Modules.BuffManager)

local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Events = game.ReplicatedStorage.Events
local Plots = game.Workspace.Plots

local function parseCollectionString(str)
	local result = {}
	for pair in string.gmatch(str, "[^,]+") do
		local name, amount = string.match(pair, "([^:]+):(%d+)")
		if name and amount then
			result[name] = tonumber(amount)
		end
	end
	return result
end

local function ownsGamePass(player, gamePassId)
	local success, hasPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePassId)
	end)
	return success and hasPass
end

local function createNewTool(Player,ItemName,Amount)
	if not ItemInfo[ItemName] then return end
	local ToolData = ItemInfo[ItemName]

	local Item = script.Placeholder:Clone()
	Item.Name = ItemName
	Item:SetAttribute("Amount", Amount)
	Item:SetAttribute("Rarity",ToolData.Rarity)
	Item:SetAttribute("Drill",ToolData.Drill)
	Item.Parent = Player.Backpack
	if ToolData.Ore then
		Item:SetAttribute("Ore",true)
		Item.RequiresHandle = true
		
		if not game.ServerStorage.Ores:FindFirstChild(ItemName) then
			print(ItemName)
		end
		local Ore = game.ServerStorage.Ores:FindFirstChild(ItemName):Clone()
		Ore.Name = "Handle"
		Ore.Parent = Item
	end
	if ToolData.Pack then
		Item:SetAttribute("Pack",true)
		if game.ReplicatedStorage.ToolModels:FindFirstChild(ItemName) then
			local ToolModel = game.ReplicatedStorage.ToolModels:FindFirstChild(ItemName):Clone()
			ToolModel.Name = "Handle"
			ToolModel.Parent = Item
		end
	end
end
local function placeFence(position, directionVector, plot)
	local fenceClone = game.ServerStorage.Fence:Clone()
	local rotation = math.deg(math.atan2(directionVector.X, directionVector.Z))
	fenceClone.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(rotation), 0)
	fenceClone.Anchored = true
	fenceClone.Parent = plot
	fenceClone.Name = "Fence"
end

local function placeFencesAroundPlate(plate)
	-- Clear old fences
	for _, v in pairs(plate:GetChildren()) do
		if v.Name == "Fence" then
			v:Destroy()
		end
	end

	local plotSize = plate.Size
	local plotCFrame = plate.CFrame

	local fenceLength = 20
	local fenceHalf = fenceLength / 2

	local fencesPerX = math.floor(plotSize.X / fenceLength)
	local fencesPerZ = math.floor(plotSize.Z / fenceLength)

	local leftVector = -plotCFrame.RightVector
	local rightVector = plotCFrame.RightVector
	local forwardVector = plotCFrame.LookVector
	local backVector = -plotCFrame.LookVector

	-- RIGHT SIDE (with entrance)
	local bestSkip = {type = "single", index = math.floor(fencesPerZ / 2)}
	local minDistance = math.huge

	for i = 1, fencesPerZ do
		local centerZ = -plotSize.Z / 2 + i * fenceLength - fenceHalf
		local dist = math.abs(centerZ)
		if dist < minDistance then
			minDistance = dist
			bestSkip = {type = "single", index = i}
		end
	end

	for i = 1, fencesPerZ - 1 do
		local z1 = -plotSize.Z / 2 + i * fenceLength - fenceHalf
		local z2 = -plotSize.Z / 2 + (i + 1) * fenceLength - fenceHalf
		local midpoint = (z1 + z2) / 2
		local dist = math.abs(midpoint)
		if dist < minDistance then
			minDistance = dist
			bestSkip = {type = "double", index = i}
		end
	end

	for i = 1, fencesPerZ do
		local offsetZ = -plotSize.Z / 2 + i * fenceLength - fenceHalf

		local skip = false
		if bestSkip.type == "single" and i == bestSkip.index then
			skip = true
		elseif bestSkip.type == "double" and (i == bestSkip.index or i == bestSkip.index + 1) then
			skip = true
		end

		if not skip then
			local localOffset = rightVector * (plotSize.X / 2) + forwardVector * offsetZ
			local worldPos = plotCFrame.Position + localOffset
			placeFence(worldPos, rightVector, plate)
		end
	end

	-- LEFT SIDE (no entrance)
	for i = 1, fencesPerZ do
		local offsetZ = -plotSize.Z / 2 + i * fenceLength - fenceHalf
		local localOffset = leftVector * (plotSize.X / 2) + forwardVector * offsetZ
		local worldPos = plotCFrame.Position + localOffset
		placeFence(worldPos, leftVector, plate)
	end

	-- FRONT SIDE
	for i = 1, fencesPerX do
		local offsetX = -plotSize.X / 2 + i * fenceLength - fenceHalf
		local localOffset = forwardVector * (plotSize.Z / 2) + rightVector * offsetX
		local worldPos = plotCFrame.Position + localOffset
		placeFence(worldPos, forwardVector, plate)
	end

	-- BACK SIDE
	for i = 1, fencesPerX do
		local offsetX = -plotSize.X / 2 + i * fenceLength - fenceHalf
		local localOffset = backVector * (plotSize.Z / 2) + rightVector * offsetX
		local worldPos = plotCFrame.Position + localOffset
		placeFence(worldPos, backVector, plate)
	end
end
local function updateEdgeModel(Plot: Part, EdgeModel: Model)
	if not (Plot and EdgeModel and EdgeModel:IsA("Model")) then return end

	local size = Plot.Size
	local baseCF = Plot.CFrame

	-- Offset to a corner (this example uses front-right corner)
	local offset = Vector3.new(size.X / 2 +2, EdgeModel.PrimaryPart.Position.Y, size.Z / 2 - 5)

	-- Apply the offset relative to the Plot's CFrame
	local targetCF = baseCF * CFrame.new(offset)

	-- Move the model
	EdgeModel:PivotTo(targetCF)
end
game.Players.PlayerAdded:Connect(function(Player) 
	local PlayerData
	Player.CharacterAdded:Connect(function(Character)
		PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
		if not PlayerData then
			repeat wait()
				PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
			until PlayerData
		end --Repeat find PlayerData process until it is found. 

		if PlayerData then
			
			local leaderstats = Instance.new("Folder")
			leaderstats.Name = "leaderstats"
			leaderstats.Parent = Player
			
			local Coins = Instance.new("IntValue")
			Coins.Parent = leaderstats
			Coins.Name = "Coins"
			Coins.Value = PlayerData.Coins.Value
			
			PlayerData.Coins.Changed:Connect(function()
				Coins.Value = PlayerData.Coins.Value
			end)
			
			if PlayerData.Collection then
				local SplitInventory: table = string.split(PlayerData.Collection.Value, ",")
				for i,v in pairs(SplitInventory) do
					if v ~= "" then

						local ItemAndAmount: table = string.split(v, ":")


						if ItemInfo[ItemAndAmount[1]] then
							createNewTool(Player,ItemAndAmount[1],ItemAndAmount[2])
						end
					end
				end
				
				PlayerData.Collection:GetPropertyChangedSignal("Value"):Connect(function()
					local newStr = PlayerData.Collection.Value
					local oldStr = PlayerData._lastCollection.Value or ""

					local newCollection = parseCollectionString(newStr)
					local oldCollection = parseCollectionString(oldStr)

					-- 1. Handle changes and removals
					for name, newAmount in pairs(newCollection) do
						local oldAmount = oldCollection[name]
						if oldAmount ~= newAmount then
							local tool = Player.Backpack:FindFirstChild(name)
							if not tool and Player.Character then
								tool = Player.Character:FindFirstChild(name)
							end
							if not tool then
								createNewTool(Player, name, newAmount)
							end

							if tool then
								if newAmount <= 0 then
									tool:Destroy()
								else
									tool:SetAttribute("Amount", newAmount)
								end
							end
						end
					end

					-- 2. Handle items removed from the collection entirely
					for name, _ in pairs(oldCollection) do
						if newCollection[name] == nil then
							local tool = Player.Backpack:FindFirstChild(name)
							if not tool and Player.Character then
								tool = Player.Character:FindFirstChild(name)
							end

							if tool then
								tool:Destroy()
							end
						end
					end

					-- 3. Save the new collection as the "old" for next comparison
					PlayerData:FindFirstChild("_lastCollection").Value = newStr
					Events.UpdateSellUI:FireClient(Player)
				end)
				
				if PlayerData.SpeedProduct.Value == true then
					if Character:FindFirstChild("Humanoid") then
						Character:FindFirstChild("Humanoid").WalkSpeed = 40
					end
				else
					if Character:FindFirstChild("Humanoid") then
						Character:FindFirstChild("Humanoid").WalkSpeed = 25
					end
				end
				
				PlayerData.SpeedProduct.Changed:Connect(function()
					if PlayerData.SpeedProduct.Value == true then
						if Character:FindFirstChild("Humanoid") then
							Character:FindFirstChild("Humanoid").WalkSpeed = 40
						end
					end
				end)
				
				for i,v in pairs(Plots:GetChildren()) do
					if v:FindFirstChild("Owner") and v:FindFirstChild("Owner").Value == Player.Name then
						Player.Character:PivotTo(v:FindFirstChild("Teleport").CFrame)
						break
					end
				end

			end
			
			
			
			if PlayerData.LockedOres then
				local lockedList = string.split(PlayerData.LockedOres.Value, ",")
				local lockedMap = {}

				for _, oreName in ipairs(lockedList) do
					lockedMap[oreName] = true
				end

				-- Go through all tools in the player's backpack and character
				for _, container in ipairs({Player.Backpack, Player.Character}) do
					for _, tool in ipairs(container:GetChildren()) do
						if tool:IsA("Tool") then
							if lockedMap[tool.Name] then
								tool:SetAttribute("Locked", true)
							else
								tool:SetAttribute("Locked", false)
							end
						end
					end
				end

				Events.LockOre:FireClient(Player, PlayerData.LockedOres.Value)
			end
			
			
		end
	end)
	
	PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	if not PlayerData then
		repeat wait()
			PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
		until PlayerData
	end --Repeat find PlayerData process until it is found. 

	if PlayerData then
		local PlotDrills = Instance.new("Folder")
		PlotDrills.Parent = game.Workspace
		PlotDrills.Name = Player.Name.."Drills"
		
		local BuildLimit = Instance.new("IntValue")
		BuildLimit.Name = "BuildLimit"
		BuildLimit.Parent = PlotDrills
		BuildLimit.Value = 20
		
		local Builds = Instance.new("IntValue")
		Builds.Name = "Builds"
		Builds.Parent = PlotDrills
		
		local PlaytimeRewardTimer = Instance.new("IntValue")
		PlaytimeRewardTimer.Parent = Player
		PlaytimeRewardTimer.Name = "PlaytimeRewardTimer"
		PlaytimeRewardTimer.Value = 0

		local Plot

		for i,v in pairs(Plots:GetChildren()) do
			if v:FindFirstChild("Owner") and v:FindFirstChild("Owner").Value == "" then
				Plot = v
				v:FindFirstChild("Owner").Value = Player.Name
				v:FindFirstChild("WorkerSpawner").Owner.Enabled = true
				v:FindFirstChild("WorkerSpawner").Owner.TextLabel.Text = Player.Name.."'s Plot"
				break
			end
		end
		
		local DisplayCase

		if PlayerData.PlotExpansion and Plot then
			local PlotBarrier = game.Workspace.Barriers:FindFirstChild(Plot.Name.."Barrier")
			if PlayerData.PlotExpansion.Value == "Tier1" then
				Plot.Size = Vector3.new(120,1,120)
				PlotBarrier.Size = Vector3.new(124, 4, 124)
			elseif PlayerData.PlotExpansion.Value == "Tier2" then
				Plot.Size = Vector3.new(140,1,140)
				PlotBarrier.Size = Vector3.new(144, 4, 144)
			elseif PlayerData.PlotExpansion.Value == "Tier3" then
				Plot.Size = Vector3.new(160,1,160)
				PlotBarrier.Size = Vector3.new(164, 4, 164)
			elseif PlayerData.PlotExpansion.Value == "Tier4" then
				Plot.Size = Vector3.new(180,1,180)
				PlotBarrier.Size = Vector3.new(184, 4, 184)
			elseif PlayerData.PlotExpansion.Value == "Tier5" then
				Plot.Size = Vector3.new(200,1,200)
				PlotBarrier.Size = Vector3.new(204, 4, 204)
			end
			
			DisplayCase = script.DisplayCase:Clone()
			DisplayCase.Parent = Plot
			updateEdgeModel(Plot,DisplayCase)
			placeFencesAroundPlate(Plot)
			
			PlayerData.PlotExpansion.Changed:Connect(function()
				if PlayerData.PlotExpansion.Value == "Tier1" then
					Plot.Size = Vector3.new(120,1,120)
					PlotBarrier.Size = Vector3.new(124, 4, 124)
					BuildLimit.Value = 30
				elseif PlayerData.PlotExpansion.Value == "Tier2" then
					Plot.Size = Vector3.new(140,1,140)
					PlotBarrier.Size = Vector3.new(144, 4, 144)
					BuildLimit.Value = 35
				elseif PlayerData.PlotExpansion.Value == "Tier3" then
					Plot.Size = Vector3.new(160,1,160)
					PlotBarrier.Size = Vector3.new(164, 4, 164)
					BuildLimit.Value = 40
				elseif PlayerData.PlotExpansion.Value == "Tier4" then
					Plot.Size = Vector3.new(180,1,180)
					PlotBarrier.Size = Vector3.new(184, 4, 184)
					BuildLimit.Value = 45
				elseif PlayerData.PlotExpansion.Value == "Tier5" then
					Plot.Size = Vector3.new(200,1,200)
					PlotBarrier.Size = Vector3.new(204, 4, 204)
					BuildLimit.Value = 50
				end
				
				updateEdgeModel(Plot,DisplayCase)
				placeFencesAroundPlate(Plot)
			end)
		end
		
		if PlayerData.FavouriteOre then
			if game.ServerStorage.Ores:FindFirstChild(PlayerData.FavouriteOre.Value) then
				local Ore = game.ServerStorage.Ores:FindFirstChild(PlayerData.FavouriteOre.Value):Clone()
				Ore.Anchored = true
				Ore.Parent = DisplayCase
				Ore.CFrame = DisplayCase:FindFirstChild("OreDisplay").CFrame
				Ore.Name = "DisplayOre"
				DisplayCase.Displaying.Value = true
			end
			
			PlayerData.FavouriteOre.Changed:Connect(function()
				if DisplayCase:FindFirstChild("DisplayOre") then
					DisplayCase:FindFirstChild("DisplayOre"):Destroy()
				end
				
				if game.ServerStorage.Ores:FindFirstChild(PlayerData.FavouriteOre.Value) then
					local Ore = game.ServerStorage.Ores:FindFirstChild(PlayerData.FavouriteOre.Value):Clone()
					Ore.Anchored = true
					Ore.Parent = DisplayCase
					Ore.CFrame = DisplayCase:FindFirstChild("OreDisplay").CFrame
					Ore.Name = "DisplayOre"
					DisplayCase.Displaying.Value = true

				end
			end)
			
		end
		
		if PlayerData.MaxDrills then
			if PlayerData.MaxDrills.Value == "Tier1" then
				BuildLimit.Value = 25
			elseif PlayerData.MaxDrills.Value == "Tier2" then
				BuildLimit.Value = 30
			elseif PlayerData.MaxDrills.Value == "Tier3" then
				BuildLimit.Value = 35
			elseif PlayerData.MaxDrills.Value == "Tier4" then
				BuildLimit.Value = 40
			elseif PlayerData.MaxDrills.Value == "Tier5" then
				BuildLimit.Value = 45
			elseif PlayerData.MaxDrills.Value == "Tier6" then
				BuildLimit.Value = 50
			end
			
			PlayerData.MaxDrills.Changed:Connect(function()
				if PlayerData.MaxDrills.Value == "Tier1" then
					BuildLimit.Value = 25
				elseif PlayerData.MaxDrills.Value == "Tier2" then
					BuildLimit.Value = 30
				elseif PlayerData.MaxDrills.Value == "Tier3" then
					BuildLimit.Value = 35
				elseif PlayerData.MaxDrills.Value == "Tier4" then
					BuildLimit.Value = 40
				elseif PlayerData.MaxDrills.Value == "Tier5" then
					BuildLimit.Value = 45
				elseif PlayerData.MaxDrills.Value == "Tier6" then
					BuildLimit.Value = 50
				end
			end)
		end
		

		if PlayerData.PlacedDrills then
			-- Remove any REMOVED drills first
			PlayerData.PlacedDrills.Value = string.gsub(PlayerData.PlacedDrills.Value, "[^,]*REMOVED[^,]*,?", "")

			local SplitInfo = string.split(PlayerData.PlacedDrills.Value, ",")
			local updatedDrills = {} -- We'll rebuild the saved string if needed

			for i, v in pairs(SplitInfo) do
				if v ~= "" then
					local CFData = string.split(v, ":")

					-- Check format: Either 5 parts (with drillID) or 4 parts (without drillID)
					-- Format with drillID: drillID:drillName:X:Z:Rotation
					-- Format without drillID (old): drillName:X:Z:Rotation

					local drillID, drillName, posX, posZ, rotY

					if #CFData == 5 then
						drillID, drillName, posX, posZ, rotY = CFData[1], CFData[2], CFData[3], CFData[4], CFData[5]
					elseif #CFData == 4 then
						-- No drillID present, generate one now
						drillID = HttpService:GenerateGUID(false)
						drillName, posX, posZ, rotY = CFData[1], CFData[2], CFData[3], CFData[4]
					else
						-- Malformed entry, skip it
						continue
					end

					-- Validate drill exists
					if game.ReplicatedStorage.System.Parts:FindFirstChild(drillName) then
						local position = CFrame.new(tonumber(posX), 0, tonumber(posZ))
						local Drill = game.ReplicatedStorage.System.Parts[drillName]:Clone()
						Drill.Parent = PlotDrills
						Drill:PivotTo(Plot.CFrame * position * CFrame.Angles(0, math.rad(tonumber(rotY)), 0))

						local DrillData = Drill:FindFirstChild("Data")
						DrillData.Owner.Value = Player.Name

						Events.PlaceDrill:FireClient(Player, Drill, false)

						Builds.Value += 1

						-- Assign drillID attribute
						Drill:SetAttribute("DrillID", drillID)

						-- Add to updatedDrills list for saving later
						table.insert(updatedDrills, string.format("%s:%s:%s:%s:%s", drillID, drillName, posX, posZ, rotY))
					end
				end
			end
			

			-- Save the updated drill list back (with newly generated drillIDs if any)
			PlayerData.PlacedDrills.Value = table.concat(updatedDrills, ",") .. ( #updatedDrills > 0 and "," or "" )
		end
		
		local Loaded = Instance.new("Folder")
		Loaded.Name = "Loaded"
		Loaded.Parent = PlotDrills
		
		PlayerData.Coins.Changed:Connect(function()
			Events.CoinChanged:FireClient(Player)
		end)
		
		local WorkerCapacity = Instance.new("IntValue")
		WorkerCapacity.Name = "WorkerCapacity"
		WorkerCapacity.Parent = Player
		WorkerCapacity.Value = 0
		
		local WorkerFolder = Instance.new("Folder")
		WorkerFolder.Parent = game.Workspace
		WorkerFolder.Name = Player.Name.."Workers"
		
		if PlayerData.EquippedWorkers then
			local SplitInventory: table = string.split(PlayerData.EquippedWorkers.Value, ",")
			for i,v in pairs(SplitInventory) do
				if v ~= "" then

					local ItemAndAmount: table = string.split(v, ":")
					
					WorkerCapacity.Value += tonumber(ItemAndAmount[2])

					for i=1,tonumber(ItemAndAmount[2]) do
						local Worker = game.ReplicatedStorage.Workers:FindFirstChild(ItemAndAmount[1]):Clone()
						Worker.Parent = WorkerFolder
						Worker.PrimaryPart.CFrame = Plot.WorkerSpawner.CFrame
						
						local Cooldown = Instance.new("Folder")
						Cooldown.Name = "Cooldown"
						Cooldown.Parent = Worker
						game.Debris:AddItem(Cooldown,10)
						
						task.spawn(function()
							local success, errorMessage = pcall(function()
								BuffManager:Passive(Player,Worker)
								
								while true do
									if not Worker or not Player or not Plot then
										break
									end
									local x = Plot.Position.X + math.random(-Plot.Size.X/2,Plot.Size.X/2)
									local y = Plot.Position.Y + math.random(-Plot.Size.Y/2,Plot.Size.Y/2)
									local z = Plot.Position.Z + math.random(-Plot.Size.Z/2,Plot.Size.Z/2)
									
									Worker:FindFirstChild("Humanoid"):MoveTo(Vector3.new(x,y,z))
									task.wait(30)
								end
							end)
							
							if not success then
								--lalalla its gonna error anyways when player leaves
							end
						end)
					end
				end
			end
		end
		
		if PlayerData.CollectedWorkers then
			local SplitInventory: table = string.split(PlayerData.CollectedWorkers.Value, ",")
			for i,v in pairs(SplitInventory) do
				if v ~= "" then

					local ItemAndAmount: table = string.split(v, ":")

					WorkerCapacity.Value += tonumber(ItemAndAmount[2])
				end
			end
		end
		
		Events.UpdateWorkerCapacity:FireClient(Player)
		
		if ownsGamePass(Player, 1283734238) and PlayerData.VIP.Value == false then
			PlayerData.VIP.Value = true
			Events.DevProductBought:FireClient(Player, "VIP")
		end
		
		if PlayerData.VIP then
			if PlayerData.VIP.Value == true then
				local VIP = Instance.new("Folder")
				VIP.Parent = Player
				VIP.Name = "VIP"
				
				if PlayerData.AlreadyGotVIPExpansion.Value == false then
					PlayerData.AlreadyGotVIPExpansion.Value = true
					local currentTier = PlayerData.PlotExpansion.Value

					local tiers = { "Tier1", "Tier2", "Tier3", "Tier4", "Tier5" }

					local function getNextTier(currentTier)
						for i, tier in ipairs(tiers) do
							if tier == currentTier and i < #tiers then
								return tiers[i + 1]
							end
						end
						return currentTier -- already at max tier or not found
					end

					PlayerData.PlotExpansion.Value = getNextTier(PlayerData.PlotExpansion.Value)
				end
			end

			PlayerData.VIP.Changed:Connect(function()
				if PlayerData.VIP.Value == true then
					local VIP = Instance.new("Folder")
					VIP.Parent = Player
					VIP.Name = "VIP"
					
					if PlayerData.AlreadyGotVIPExpansion.Value == false then
						PlayerData.AlreadyGotVIPExpansion.Value = true
						local currentTier = PlayerData.PlotExpansion.Value

						local tiers = { "Tier1", "Tier2", "Tier3", "Tier4", "Tier5" }

						local function getNextTier(currentTier)
							for i, tier in ipairs(tiers) do
								if tier == currentTier and i < #tiers then
									return tiers[i + 1]
								end
							end
							return currentTier -- already at max tier or not found
						end

						PlayerData.PlotExpansion.Value = getNextTier(PlayerData.PlotExpansion.Value)
					end
				end
			end)
		end

		PlayerData.LockedOres.Changed:Connect(function()
			local lockedList = string.split(PlayerData.LockedOres.Value, ",")
			local lockedMap = {}

			for _, oreName in ipairs(lockedList) do
				lockedMap[oreName] = true
			end

			-- Go through all tools in the player's backpack and character
			for _, container in ipairs({Player.Backpack, Player.Character}) do
				for _, tool in ipairs(container:GetChildren()) do
					if tool:IsA("Tool") then
						if lockedMap[tool.Name] then
							tool:SetAttribute("Locked", true)
						else
							tool:SetAttribute("Locked", false)
						end
					end
				end
			end

			Events.LockOre:FireClient(Player, PlayerData.LockedOres.Value)
		end)
		
		
		if PlayerData.LuckMultiplier.Value ~= 1 then
			task.spawn(function()
				while wait(1) do
					if not PlayerData then
						break
					end
					if PlayerData.LuckMultiplier.Value ~= 1 then
						PlayerData.TimeUntilLuckEnds.Value -= 1
						
						if PlayerData.TimeUntilLuckEnds.Value < 0 then
							PlayerData.LuckMultiplier.Value = 1
							
							Events.LuckBought:FireClient(Player)
						end
					end
				end
			end)
		end
		
		if PlayerData.LowGraphicsMode then
			Events.LowGraphicsMode:FireClient(Player,PlayerData.LowGraphicsMode.Value)
			
			PlayerData.LowGraphicsMode.Changed:Connect(function()
				Events.LowGraphicsMode:FireClient(Player,PlayerData.LowGraphicsMode.Value)
			end)
		end
		
		if PlayerData.Music.Value == "Off" then
			local MusicOff = Instance.new("Folder")
			MusicOff.Name = "MusicOff"
			MusicOff.Parent = Player
		end
		
		if PlayerData.OreAnnouncments.Value == "Off" then
			local DisableAnnouncments = Instance.new("Folder")
			DisableAnnouncments.Name = "DisableAnnouncments"
			DisableAnnouncments.Parent = Player
		end
		
		if PlayerData.DisableOrbs.Value == "On" then
			local DisableOrbs = Instance.new("Folder")
			DisableOrbs.Name = "DisableOrbs"
			DisableOrbs.Parent = Player
		end
		if PlayerData.AutoSellCommons.Value == "On" then
			local AutoSellCommons = Instance.new("Folder")
			AutoSellCommons.Name = "AutoSellCommons"
			AutoSellCommons.Parent = Player
		end
		if PlayerData.AutoSellRares.Value == "On" then
			local AutoSellRares = Instance.new("Folder")
			AutoSellRares.Name = "AutoSellRares"
			AutoSellRares.Parent = Player
		end
		if PlayerData.Tips.Value == "On" then
			local TipsOff = Instance.new("Folder")
			TipsOff.Name = "TipsOff"
			TipsOff.Parent = Player
		end
		
		if Player.Character then
			Player.Character:PivotTo(Plot:FindFirstChild("Teleport").CFrame)
		end
		
		while wait(1) do
			if not Player or not Plot then
				break
			end
			if PlaytimeRewardTimer then
				if not Player:FindFirstChild("GiftReady") then
					PlaytimeRewardTimer.Value += 1
					
					if PlaytimeRewardTimer.Value % 300 == 0 then
						Events.MainAlert:FireClient(Player,"Playtime gift is ready!",Color3.new(0.792157, 0.262745, 1))
					end
				end
			end
			
			if PlayerData.SecondsSpentIngame then
				PlayerData.SecondsSpentIngame.Value += 1
			end
			
			if not PlotDrills then
				break
			end
			for i,v in pairs(PlotDrills:GetChildren()) do
				if v:FindFirstChild("Data") then
					local DrillData = v:FindFirstChild("Data")

					if DrillData.Collected.Value < DrillData.Max.Value then

						if DrillData.Collected.Value + DrillData.Speed.Value >= DrillData.Max.Value then
							DrillData.Collected.Value = DrillData.Max.Value
						else
							DrillData.Collected.Value += DrillData.Speed.Value
						end
					end
				end
			end
		end
	end
end)

game.Players.PlayerRemoving:Connect(function(Player)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	local PlotDrills = game.Workspace:FindFirstChild(Player.Name.."Drills")
	local PlotWorkers = game.Workspace:FindFirstChild(Player.Name.."Workers")

	local Plot
	for _, plot in pairs(Plots:GetChildren()) do
		if plot:FindFirstChild("Owner") and plot.Owner.Value == Player.Name then
			Plot = plot
			plot.Owner.Value = ""
			if plot:FindFirstChild("DisplayCase") then
				plot:FindFirstChild("DisplayCase"):Destroy()
			end

			Plot:FindFirstChild("WorkerSpawner").Owner.Enabled = false
			local PlotBarrier = game.Workspace.Barriers:FindFirstChild(plot.Name.."Barrier")
			PlotBarrier.Size = Vector3.new(104, 4, 104)
			plot.Size = Vector3.new(100, 1, 100)
			
			placeFencesAroundPlate(Plot)
			break
		end
	end

	if PlayerData then
		print("Saving drills for", Player.Name)

		-- Backup old data in case of failure
		local oldPlacedDrills = PlayerData.PlacedDrills.Value

		-- Optional persistent backup
		local backup = PlayerData:FindFirstChild("_PlacedDrillsBackup")
		backup.Value = oldPlacedDrills

		-- Only save if we’re sure PlotDrills is valid and drills were loaded
		if PlotDrills and PlotDrills:FindFirstChild("Loaded") and #PlotDrills:GetChildren() > 1 and Plot then
			local newPlacedDrills = ""

			for _, drill in pairs(PlotDrills:GetChildren()) do
				if drill:IsA("Model") and drill:FindFirstChild("Data") and drill.PrimaryPart then
					local drillName = drill.Name
					local relativeCF = Plot.CFrame:ToObjectSpace(drill.PrimaryPart.CFrame)
					local X = relativeCF.X
					local Z = relativeCF.Z
					local RY = drill.PrimaryPart.Orientation.Y - Plot.Orientation.Y

					local drillID = drill:GetAttribute("DrillID") or HttpService:GenerateGUID(false)
					local combined = string.format("%s:%s:%.2f:%.2f:%.2f,", drillID, drillName, X, Z, RY)
					newPlacedDrills ..= combined
				end
			end

			if newPlacedDrills ~= "" then
				PlayerData.PlacedDrills.Value = newPlacedDrills
				print("Saved PlacedDrills for", Player.Name)
			else
				-- If rebuilding fails, keep backup
				PlayerData.PlacedDrills.Value = oldPlacedDrills
				warn("Drill data save failed for", Player.Name, "- using backup.")
			end
		else
			-- Skip save to avoid overwriting with empty string
			PlayerData.PlacedDrills.Value = oldPlacedDrills
			warn("Skipped saving PlacedDrills for", Player.Name, "- drills not properly loaded.")
		end
	end

	-- Always cleanup last
	if PlotDrills then
		PlotDrills:Destroy()
	end
	if PlotWorkers then
		PlotWorkers:Destroy()  
	end
	
	repeat
		local success = pcall(function()
			task.defer(Player.Destroy, Player)
		end)
		task.wait()
	until success
end)

Events.Sell.OnServerEvent:Connect(function(Player, Action)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	if not PlayerData then return end

	local LockedOres = {}
	if PlayerData:FindFirstChild("LockedOres") then
		for _, ore in ipairs(string.split(PlayerData.LockedOres.Value, ",")) do
			LockedOres[ore] = true
		end
	end

	if Action == "All" then
		local Profit = 0
		local SplitInventory = string.split(PlayerData.Collection.Value, ",")

		for _, v in ipairs(SplitInventory) do
			if v ~= "" then
				local ItemAndAmount = string.split(v, ":")
				local itemName = ItemAndAmount[1]
				local amount = tonumber(ItemAndAmount[2])

				if not LockedOres[itemName] and ItemInfo[itemName] and ItemInfo[itemName].Price then
					Profit += ItemInfo[itemName].Price * amount
					PlayerData.Collection.Value = string.gsub(PlayerData.Collection.Value, v .. ",", "")
				end
			end
		end

		PlayerData.Coins.Value += Profit

		if Profit > 0 then
			Events.Profit:FireClient(Player, Profit)
			Events.UpdateSellUI:FireClient(Player)
		else
			Events.Alert:FireClient(Player, "You have nothing to sell.")
		end

	elseif Action ~= "" and ItemInfo[Action] then
		local OreData = ItemInfo[Action]
		local Profit = 0

		if not LockedOres[Action] and OreData.Price then
			local SplitInventory = string.split(PlayerData.Collection.Value, ",")

			for _, v in ipairs(SplitInventory) do
				if v ~= "" then
					local ItemAndAmount = string.split(v, ":")
					local itemName = ItemAndAmount[1]
					local amount = tonumber(ItemAndAmount[2])

					if itemName == Action then
						Profit += OreData.Price * amount
						PlayerData.Collection.Value = string.gsub(PlayerData.Collection.Value, v .. ",", "")
						break -- only remove one item for specific sale
					end
				end
			end

			PlayerData.Coins.Value += Profit

			if Profit > 0 then
				local OneTimeQuests = PlayerData:FindFirstChild("OneTimeQuests") --if Collect Ore Quest is there
				if OneTimeQuests and string.find(OneTimeQuests.Value, "Make Money") then
					local questName, progress, goal = string.match(OneTimeQuests.Value, "^(.-):(%d+),(%d+)$")
					if questName and progress and goal then
						progress = tonumber(progress) + Profit
						goal = tonumber(goal)

						-- Clamp to goal
						if progress > goal then
							progress = goal
						end

						-- Update the quest string
						OneTimeQuests.Value = string.format("%s:%d,%d", questName, progress, goal)
					end
				end
				
				Events.Profit:FireClient(Player, Profit)
				Events.UpdateSellUI:FireClient(Player)
			end
		end
		
		if not LockedOres[Action] and OreData.Coins then
			local SplitInventory = string.split(PlayerData.Collection.Value, ",")

			for _, v in ipairs(SplitInventory) do
				if v ~= "" then
					local ItemAndAmount = string.split(v, ":")
					local itemName = ItemAndAmount[1]
					local amount = tonumber(ItemAndAmount[2])

					if itemName == Action then
						Profit += OreData.Coins * amount
						PlayerData.Collection.Value = string.gsub(PlayerData.Collection.Value, v .. ",", "")
						break -- only remove one item for specific sale
					end
				end
			end

			PlayerData.Coins.Value += Profit

			if Profit > 0 then
				local OneTimeQuests = PlayerData:FindFirstChild("OneTimeQuests") --if Collect Ore Quest is there
				if OneTimeQuests and string.find(OneTimeQuests.Value, "Make Money") then
					local questName, progress, goal = string.match(OneTimeQuests.Value, "^(.-):(%d+),(%d+)$")
					if questName and progress and goal then
						progress = tonumber(progress) + Profit
						goal = tonumber(goal)

						-- Clamp to goal
						if progress > goal then
							progress = goal
						end

						-- Update the quest string
						OneTimeQuests.Value = string.format("%s:%d,%d", questName, progress, goal)
					end
				end
				
				Events.Profit:FireClient(Player, Profit)
				Events.UpdateSellUI:FireClient(Player)
			end
		end
	end
end)

Events.PickUpDrill.OnServerEvent:Connect(function(Player,Drill)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	if PlayerData then
		if Drill:FindFirstChild("CollectPart") then
			
			local drillID = Drill:GetAttribute("DrillID")
			if drillID and PlayerData.PlacedDrills then
				PlayerData.PlacedDrills.Value = string.gsub(PlayerData.PlacedDrills.Value, drillID, "REMOVED")
			end
			
			local PlotDrills = Drill.Parent
			if PlotDrills:FindFirstChild("Builds") then
				PlotDrills:FindFirstChild("Builds").Value -= 1
			end
			
			Drill.Parent = nil
			
			local collection = {}
			for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end

			-- Add or increment drill count
			collection[Drill.Name] = (collection[Drill.Name] or 0) + 1

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				newCollection ..= name .. ":" .. amount .. ","
			end
			PlayerData.Collection.Value = newCollection
			Drill:FindFirstChild("CollectPart"):Destroy()
			for i,v in pairs(Drill:GetDescendants()) do
				if v:IsA("Part") or v:IsA("MeshPart") then
					v.Transparency = 1
					v.CanCollide = false
				elseif v:IsA("ParticleEmitter") or v:IsA("Beam") then
					v.Enabled = false
				elseif v.Name == "CollectPart" then
					v:Destroy()
				end
			end
			game.Debris:AddItem(Drill,1)
			
			Events.NewDrill:FireClient(Player,Drill.Name,1)
		end
	end
end)

Events.Teleport.OnServerEvent:Connect(function(Player,Destination)
	if Destination == "Shop" then
		Player.Character.HumanoidRootPart.CFrame = game.Workspace.PlayerTeleports.Shop.CFrame
	elseif Destination == "Home" then
		local Plot
		for _, plot in pairs(Plots:GetChildren()) do
			if plot:FindFirstChild("Owner") and plot.Owner.Value == Player.Name then
				Plot = plot
				break
			end
		end
		
		Player.Character.HumanoidRootPart.CFrame = Plot:FindFirstChild("Teleport").CFrame
	end
end)

Events.DisplayInteract.OnServerEvent:Connect(function(Player,DisplayCase)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	if PlayerData then
		local Plot = DisplayCase.Parent
		if Plot:FindFirstChild("Owner") and Plot:FindFirstChild("Owner").Value == Player.Name then
			if Player.Character:FindFirstChildWhichIsA("Tool") then
				local Tool = Player.Character:FindFirstChildWhichIsA("Tool")
				if Tool:GetAttribute("Ore") == true then
					local collection = {}
					for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
						collection[name] = tonumber(amount)
					end

					-- Add or increment drill count
					if PlayerData.FavouriteOre.Value ~= "" then
						collection[PlayerData.FavouriteOre.Value] = (collection[PlayerData.FavouriteOre.Value] or 0) + 1
						
						Events.NewDrill:FireClient(Player,PlayerData.FavouriteOre.Value,1)
					end
					collection[Tool.Name] = (collection[Tool.Name] or 0) - 1

					-- Rebuild collection string
					local newCollection = ""
					for name, amount in pairs(collection) do
						if amount > 0 then
							newCollection ..= name .. ":" .. amount .. ","
						end
					end
					
					
					PlayerData.Collection.Value = newCollection
					PlayerData.FavouriteOre.Value = Tool.Name
				end
			else
				if PlayerData.FavouriteOre.Value ~= "" then
					local collection = {}
					for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
						collection[name] = tonumber(amount)
					end


					collection[PlayerData.FavouriteOre.Value] = (collection[PlayerData.FavouriteOre.Value] or 0) + 1

					-- Rebuild collection string
					local newCollection = ""
					for name, amount in pairs(collection) do
						if amount > 0 then
							newCollection ..= name .. ":" .. amount .. ","
						end
					end

					Events.NewDrill:FireClient(Player,PlayerData.FavouriteOre.Value,1)

					PlayerData.Collection.Value = newCollection
					PlayerData.FavouriteOre.Value = ""
				end
			end
		end
	end
end)

Events.TutorialComplete.OnServerEvent:Connect(function(Player)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	if PlayerData then
		if PlayerData.FirstTimePlaying.Value == true then
			PlayerData.FirstTimePlaying.Value = false
		end
	end
end)

Events.LockOre.OnServerEvent:Connect(function(Player, OreName)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	if not PlayerData then return end

	local LockedOres = PlayerData:FindFirstChild("LockedOres")
	if not LockedOres then return end

	if ItemInfo[OreName].Ore then
		local lockedList = string.split(LockedOres.Value, ",")
		local found = false

		for i, ore in ipairs(lockedList) do
			if ore == OreName then
				table.remove(lockedList, i)
				found = true
				
				Events.Alert:FireClient(Player,OreName.." has been removed from lock.")
				break
			end
		end

		if not found then
			Events.Alert:FireClient(Player,OreName.." has been added to lock.")
			table.insert(lockedList, OreName)
		end

		-- Clean up empty strings and rebuild the value
		local cleanedList = {}
		for _, v in ipairs(lockedList) do
			if v ~= "" then
				table.insert(cleanedList, v)
			end
		end

		LockedOres.Value = table.concat(cleanedList, ",")
		Events.LockOre:FireClient(Player,LockedOres.Value)
		Events.UpdateSellUI:FireClient(Player)
	end
end)

Events.Settings.OnServerEvent:Connect(function(Player,Setting)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	if PlayerData then
		if PlayerData:FindFirstChild(Setting) then
			if PlayerData:FindFirstChild(Setting).Value == "On" then
				PlayerData:FindFirstChild(Setting).Value = "Off"
				
				if Setting == "Tips" then
					local TipsOff = Instance.new("Folder")
					TipsOff.Name = "TipsOff"
					TipsOff.Parent = Player
				elseif Setting == "OreAnnouncments" then
					local DisableAnnouncments = Instance.new("Folder")
					DisableAnnouncments.Name = "DisableAnnouncments"
					DisableAnnouncments.Parent = Player
				elseif Setting == "DisableOrbs" then
					for i,v in pairs(Player:GetChildren()) do
						if v.Name == "DisableOrbs" then
							v:Destroy()
						end
					end
				elseif Setting == "AutoSellCommons" then
					for i,v in pairs(Player:GetChildren()) do
						if v.Name == "AutoSellCommons" then
							v:Destroy()
						end
					end
				elseif Setting == "AutoSellRares" then
					for i,v in pairs(Player:GetChildren()) do
						if v.Name == "AutoSellRares" then
							v:Destroy()
						end
					end
				elseif Setting == "Music" then
					local MusicOff = Instance.new("Folder")
					MusicOff.Name = "MusicOff"
					MusicOff.Parent = Player
				end
			else
				PlayerData:FindFirstChild(Setting).Value = "On"
			
				if Setting == "Tips" then
					for i,v in pairs(Player:GetChildren()) do
						if v.Name == "TipsOff" then
							v:Destroy()
						end
					end
				elseif Setting == "OreAnnouncments" then
					for i,v in pairs(Player:GetChildren()) do
						if v.Name == "DisableAnnouncments" then
							v:Destroy()
						end
					end
				elseif Setting == "DisableOrbs" then
					local DisableOrbs = Instance.new("Folder")
					DisableOrbs.Name = "DisableOrbs"
					DisableOrbs.Parent = Player
				elseif Setting == "AutoSellCommons" then
					local AutoSellCommons = Instance.new("Folder")
					AutoSellCommons.Name = "AutoSellCommons"
					AutoSellCommons.Parent = Player
				elseif Setting == "AutoSellRares" then
					local AutoSellCommons = Instance.new("Folder")
					AutoSellCommons.Name = "AutoSellRares"
					AutoSellCommons.Parent = Player
				elseif Setting == "Music" then
					for i,v in pairs(Player:GetChildren()) do
						if v.Name == "MusicOff" then
							v:Destroy()
						end
					end
				end
			end
		end
	end
end)

local CommonLootTable = {
	["Standard Drill"]        = { Chance = 1 },
	["Reinforced Drill"]      = { Chance = 2 },
	["Twin Drill"]            = { Chance = 3 },
	["Compact Drill"]         = { Chance = 4 },
	["Worker Contract"]       = { Chance = 5 },
	["Player Contract"]       = { Chance = 6 },
	["Simple Luck Potion"]    = { Chance = 12 }, -- rarer
}
local RareLootTable = {
	["Charged Drill"]         = { Chance = 2 },
	["Surge Drill"]           = { Chance = 3 },
	["Fusion Drill"]          = { Chance = 4 },
	["Phase Drill"]           = { Chance = 6 },
	["Simple Luck Potion"]    = { Chance = 15 }, -- rarer
	["Advanced Luck Potion"]  = { Chance = 20 }, -- rarer
	["Rain Totem"]            = { Chance = 25 }, -- rarer
	["Worker Contract"]       = { Chance = 7 },
	["Player Contract"]       = { Chance = 8 },
}
local EpicLootTable = {
	["Phase Drill"]            = { Chance = 4 },
	["KinetiCore Drill"]       = { Chance = 6 },
	["Pulsebreaker Drill"]     = { Chance = 10 },
	["Stormcell Drill"]        = { Chance = 14 },
	["Advanced Luck Potion"]   = { Chance = 20 }, -- rarer
	["Mythical Luck Potion"]   = { Chance = 30 }, -- rarer
	["Rain Totem"]             = { Chance = 25 },
	["Arcane Totem"]           = { Chance = 35 },
	["Void Totem"]             = { Chance = 50 },
	["Worker Contract"]        = { Chance = 8 },
	["Player Contract"]        = { Chance = 10 },
}
local function pickRandomDrill(drillList)
	local weights = {}
	local totalWeight = 0

	for name, data in pairs(drillList) do
		local weight = 1 / data.Chance
		totalWeight += weight
		table.insert(weights, { Name = name, Weight = weight })
	end

	local rand = math.random() * totalWeight
	local cumulative = 0

	for _, item in ipairs(weights) do
		cumulative += item.Weight
		if rand <= cumulative then
			return item.Name
		end
	end

	return "Surge Drill" -- fallback
end

Events.CollectPlaytime.OnServerEvent:Connect(function(Player,GiftRequirement)
	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
	if PlayerData then
		
		local PlaytimeRewardTimer = Player:FindFirstChild("PlaytimeRewardTimer")
		local GiftTime = tonumber(GiftRequirement) * 300
		
		if PlaytimeRewardTimer.Value >= GiftTime and not Player:FindFirstChild("Claimed"..GiftRequirement) then
			local Claimed = Instance.new("Folder")
			Claimed.Name = "Claimed"..GiftRequirement
			Claimed.Parent = Player

			local collection = {}
			for name, amount in string.gmatch(PlayerData.Collection.Value or ",", "([^:,]+):(%d+),") do
				collection[name] = tonumber(amount)
			end

			local selectedDrill 
			if tonumber(GiftRequirement) <= 5 then
				selectedDrill = pickRandomDrill(CommonLootTable)
			elseif tonumber(GiftRequirement) <= 9 then
				selectedDrill = pickRandomDrill(RareLootTable)
			elseif tonumber(GiftRequirement) <= 12 then
				selectedDrill = pickRandomDrill(EpicLootTable)
			else
				selectedDrill = pickRandomDrill(CommonLootTable)
			end
			collection[selectedDrill] = (collection[selectedDrill] or 0) + 1

			-- Rebuild collection string
			local newCollection = ""
			for name, amount in pairs(collection) do
				if amount > 0 then
					newCollection ..= name .. ":" .. amount .. ","
				end
			end

			PlayerData.Collection.Value = newCollection
			Events.NewDrill:FireClient(Player, selectedDrill, 1)
		end
	end
end)

