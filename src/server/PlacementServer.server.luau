--[[

PLACEMENT SYSTEM SERVER
Last Modified: 2/8/23 by TrentaFX

]]--

local Events = game.ReplicatedStorage.Events
local HttpService = game:GetService("HttpService")

local placingPlayers = {}

game.ReplicatedStorage.System.Place.OnServerInvoke = function(Player, ObjName, ObjCFrame,Tool)
	if placingPlayers[Player] then
		return false -- Reject if player is already placing
	end
	placingPlayers[Player] = true

	local ToReturn = false
	
	local succ,result = pcall(function()
		if game.Workspace:FindFirstChild(Player.Name.."Drills") then
			if not Tool or not Tool:IsDescendantOf(Player.Character) or not Tool:GetAttribute("Drill") then
				return false
			end
			
			local PlotDrills = game.Workspace:FindFirstChild(Player.Name.."Drills")
			
			if PlotDrills.Builds.Value + 1 > PlotDrills.BuildLimit.Value then 
				Events.Alert:FireClient(Player,"You have reached maximum Drill Capacity.")
				Player.Character:FindFirstChild("Humanoid"):UnequipTools()
				return 
			end 
			PlotDrills.Builds.Value += 1
			
			local overlapParams = OverlapParams.new()
			overlapParams.FilterType = Enum.RaycastFilterType.Include
			overlapParams.FilterDescendantsInstances = {game.Workspace.Barriers:GetChildren(),game.Workspace:FindFirstChild(Player.Name.."Drills"):GetDescendants()}

			local ObjClone = game.ReplicatedStorage.System['Parts']:FindFirstChild(tostring(ObjName)):Clone()
	
			if ObjClone:IsA("Model") then
				ObjClone:PivotTo(ObjCFrame)
				ObjClone.Parent = game:GetService('Workspace'):FindFirstChild(Player.Name.."Drills")
				
				if #workspace:GetPartsInPart(ObjClone.PrimaryPart, overlapParams) > 0 then
					print("Touching parts:")
					for _, part in ipairs(workspace:GetPartsInPart(ObjClone.PrimaryPart, overlapParams)) do
						print(part:GetFullName())
					end
					Events.Alert:FireClient(Player,"Error: Drills cannot be touching.")
					PlotDrills.Builds.Value -= 1
					ObjClone:Destroy()
					return
				end

				
				-- Generate a unique DrillID and set attribute
				local drillID = HttpService:GenerateGUID(false)
				ObjClone:SetAttribute("DrillID", drillID)
				
				local DrillData = ObjClone:FindFirstChild("Data")
				DrillData.Owner.Value = Player.Name
				
				Events.PlaceDrill:FireClient(Player,ObjClone,true)
			else
				ObjClone.CFrame = ObjCFrame ObjClone.Parent = game:GetService('Workspace'):FindFirstChild(Player.Name.."Drills")
			end
			
			

			local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
			if not PlayerData then
				repeat wait()
					PlayerData = game.ServerStorage.PlayerData:FindFirstChild(Player.Name.."Data")
				until PlayerData
			end --Repeat find PlayerData process until it is found. 

			if PlayerData then

				if PlayerData.Collection then

					local SplitInventory: table = string.split(PlayerData.Collection.Value, ",")
					for i,v in pairs(SplitInventory) do
						local ItemAndAmount: table = string.split(v, ":")

						if ItemAndAmount[1] == ObjName then
							print("Player has used "..ObjName)

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
			end
		end
		
		ToReturn = true
	end)
	
	if not succ then
		warn("Placement error for player", Player.Name, ":", result)
	end

	placingPlayers[Player] = nil
	return ToReturn
end