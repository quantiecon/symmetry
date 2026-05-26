--[[

PLACEMENT SYSTEM CLIENT
Last Modified: 2/8/23 by TrentaFX

]]--

local Replicated = game:GetService("ReplicatedStorage")
local UserInput = game:GetService("UserInputService")
local PlayerService = game:GetService("Players")
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")

local PlaceServer = Replicated.System.Place
local Objects = Replicated.System.Parts

local Spring = require(script.SpringAnim)

local Player = PlayerService.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Mouse = Player:GetMouse()

local placeConn
local rotateConn
local placingInputconn
local LockConn

local ClientStatus = {
	['Placing'] = false,
}

local placingThroughUI = false

local function RoundToNearest(number: number, roundTo: number): number -- Handy function to remember
	local x = number + (roundTo / 2)
	return x - (x % roundTo)
end

local debounce = false

Character.ChildAdded:Connect(function(child)
	if child:IsA("Tool") and child:GetAttribute("Drill") then
		if ClientStatus.Placing == false then
			if debounce == true then return end
			debounce = true
			task.delay(0.1,function()
				debounce = false
			end)
			
			-- Cleanup existing placement if still active
			ClientStatus.Placing = false

			-- Disconnect previous connections
			if placeConn then placeConn:Disconnect() end
			if rotateConn then rotateConn:Disconnect() end
			if placingInputconn then placingInputconn:Disconnect() end

			-- Hide mobile UI (in case it was left visible)
			local drillUI = Player:WaitForChild("PlayerGui"):WaitForChild("MobileButtons")
			drillUI.Place.Visible = false
			drillUI.Rotate.Visible = false

			-- Remove previous ObjectClone
			for _, obj in ipairs(workspace:GetChildren()) do
				if obj:IsA("Model") and obj:FindFirstChild("DrillPreview") then
					obj:Destroy()
				end
			end
			
			ClientStatus.Placing = true
			
			for i,v in pairs(game.Workspace.Plots:GetChildren()) do
				if v:FindFirstChild("Owner") and v:FindFirstChild("Owner").Value == Player.Name then
					v:FindFirstChild("Texture").Transparency = 0
				end
			end
			
			local isMobile = UserInput.TouchEnabled and not UserInput.KeyboardEnabled
			local drillUI = Player:WaitForChild("PlayerGui"):WaitForChild("MobileButtons")
			local rotateButton = drillUI:WaitForChild("Rotate")
			local placeButton = drillUI:WaitForChild("Place")
			
			rotateButton.Visible = isMobile
			placeButton.Visible = isMobile

			local RotInt = 0
			local ObjectClone = Objects[child.Name]:Clone()
			local CanPlace = false
			--				local OrginColor = ObjectClone.Color or Color3.new(1, 1, 1)

			if ObjectClone:FindFirstChild("CollectPart") then
				ObjectClone:FindFirstChild("CollectPart"):Destroy()
			end
			local DrillPreview = Instance.new("Folder")
			DrillPreview.Parent = ObjectClone
			DrillPreview.Name = "DrillPreview"
			
			local Connection

			ObjectClone.Parent = workspace
			for i,v in pairs(ObjectClone:GetDescendants()) do
				if v:IsA("Part") or v:IsA("MeshPart") then
					v.CanCollide = false
				end
			end

			local CFrameOffset = CFrame.new(0, -2, -5)
			ObjectClone:PivotTo(Character.HumanoidRootPart.CFrame:ToWorldSpace(CFrameOffset))

			local overlapParams = OverlapParams.new()
			overlapParams.FilterType = Enum.RaycastFilterType.Include
			overlapParams.FilterDescendantsInstances = {game.Workspace.Barriers:GetChildren(),game.Workspace:FindFirstChild(Player.Name.."Drills"):GetDescendants()}

			local NewBox = Instance.new('SelectionBox', ObjectClone)
			NewBox.Adornee = ObjectClone NewBox.Color3 = Color3.fromRGB(113, 255, 61)
			NewBox.LineThickness = 0
			
			placingInputconn = placeButton.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
					placingThroughUI = true
					task.delay(0.1, function()
						placingThroughUI = false
					end)
				end
			end)
			
			local RenderSteppedConn
			RenderSteppedConn = RunService.RenderStepped:Connect(function()
				if placingThroughUI then return end

				local hrp = Character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end

				local drillSize = ObjectClone:GetExtentsSize()
				local spacing = 2
				local forwardOffset = (drillSize.Z / 2) + spacing
				local forwardPosition = hrp.Position + hrp.CFrame.LookVector * forwardOffset

				local posX = RoundToNearest(forwardPosition.X, 2)
				local posZ = RoundToNearest(forwardPosition.Z, 2)

				-- Get Y height from plot
				local plotY = 0
				for _, plot in pairs(workspace.Plots:GetChildren()) do
					if plot:FindFirstChild("Owner") and plot.Owner.Value == Player.Name then
						plotY = plot.Position.Y
						break
					end
				end

				local finalPos = Vector3.new(posX, plotY, posZ)
				local NewCFrame = CFrame.new(finalPos) * CFrame.Angles(0, math.rad(RotInt), 0)

				if ObjectClone:IsA("Model") then
					ObjectClone:PivotTo(NewCFrame)
				else
					ObjectClone.CFrame = NewCFrame
				end

				-- ✅ Your original Hit check logic
				local primary = ObjectClone.PrimaryPart
				local rayOrigin = finalPos + Vector3.new(0, 10, 0)
				local rayDirection = Vector3.new(0, -20, 0)
				local hit, _ = workspace:FindPartOnRayWithWhitelist(Ray.new(rayOrigin, rayDirection), workspace.Plots:GetDescendants())

				if hit and hit:IsA("Part") and hit.Parent == workspace.Plots and hit:FindFirstChild("Owner") and hit.Owner.Value == Player.Name and primary and #workspace:GetPartsInPart(primary, overlapParams) == 0 then
					CanPlace = true
					Spring.target(NewBox, 1, 2, {LineThickness = 0, Color3 = Color3.fromRGB(113, 255, 61)})
				else
					CanPlace = false
					Spring.target(NewBox, 1, 2.5, {LineThickness = 0.15, Color3 = Color3.fromRGB(255, 52, 55)})
				end

				if not ClientStatus.Placing then
					if Connection then Connection:Disconnect() end
					RenderSteppedConn:Disconnect()
					ObjectClone:Destroy()
					if placeConn then placeConn:Disconnect() end
					if rotateConn then rotateConn:Disconnect() end
					if placingInputconn then placingInputconn:Disconnect() end
				end
			end)

			rotateConn = rotateButton.MouseButton1Click:Connect(function()
				RotInt += 90
			end)

			placeConn = placeButton.MouseButton1Click:Connect(function()
				if ClientStatus.Placing and CanPlace == true then
					local SetCFrame = ObjectClone.PrimaryPart.CFrame
					local Response = Replicated.System['Place']:InvokeServer(ObjectClone.Name, SetCFrame, child)

					if Response == true and Response ~= nil then
						Connection:Disconnect()
						RenderSteppedConn:Disconnect()
						if placeConn then placeConn:Disconnect() end  -- 🔴 Disconnect here
						if rotateConn then rotateConn:Disconnect() end -- Optional: if you did the same for rotate
						ClientStatus.Placing = false
						ObjectClone:Destroy()
					end
				end
			end)

			local function InputBegan(Input)

				if Input.KeyCode == Enum.KeyCode.R then
					if ClientStatus.Placing then
						RotInt += 90
					end
				end

				if Input.UserInputType == Enum.UserInputType.MouseButton1 then
					if ClientStatus.Placing then

						if CanPlace == true then
							local SetCFrame = ObjectClone.PrimaryPart.CFrame
							local Response = Replicated.System['Place']:InvokeServer(ObjectClone.Name, SetCFrame,child)

							if Response == true and Response ~= nil then
								Connection:Disconnect()
								RenderSteppedConn:Disconnect()
								ClientStatus.Placing = false
								ObjectClone:Destroy()
							end
						end

					end
				end
			end

			Connection = UserInput.InputBegan:Connect(InputBegan)
			
			
		end
	elseif child:IsA("Tool") and child:GetAttribute("Ore") then
		local isMobile = UserInput.TouchEnabled and not UserInput.KeyboardEnabled
		local drillUI = Player:WaitForChild("PlayerGui"):WaitForChild("MobileButtons")
		drillUI.Place.Visible = false
		drillUI.Rotate.Visible = false
		drillUI.Lock.Visible = isMobile
		
		if isMobile then
			LockConn = drillUI.Lock.MouseButton1Click:Connect(function()
				game.ReplicatedStorage.Events.LockOre:FireServer(child.Name)
			end)
		end
	end
end)

Character.ChildRemoved:Connect(function(child)
	if child:IsA("Tool") and child:GetAttribute("Drill") then
		ClientStatus.Placing = false
		if placeConn then placeConn:Disconnect() end  -- 🔴 Disconnect here
		if rotateConn then rotateConn:Disconnect() end -- Optional: if you did the same for rotate
		local drillUI = Player:WaitForChild("PlayerGui"):WaitForChild("MobileButtons")
		local rotateButton = drillUI:WaitForChild("Rotate")
		local placeButton = drillUI:WaitForChild("Place")
		rotateButton.Visible = false
		placeButton.Visible = false

		for i,v in pairs(game.Workspace.Plots:GetChildren()) do
			if v:FindFirstChild("Owner") and v:FindFirstChild("Owner").Value == Player.Name then
				v:FindFirstChild("Texture").Transparency = 1
			end
		end
	elseif child:IsA("Tool") and child:GetAttribute("Ore") then
		if placeConn then placeConn:Disconnect() end  -- 🔴 Disconnect here
		if rotateConn then rotateConn:Disconnect() end -- Optional: if you did the same for rotate
		if LockConn then LockConn:Disconnect() end  -- 🔴 Disconnect here
		local drillUI = Player:WaitForChild("PlayerGui"):WaitForChild("MobileButtons")
		local LockButton = drillUI:WaitForChild("Lock")
		LockButton.Visible = false
		

	end
end)