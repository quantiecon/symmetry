local Events = game.ReplicatedStorage.Events
local ViewportModel = require(game.ReplicatedStorage.Modules.ViewportModel)
local WorkerInfo = require(game.ReplicatedStorage.Modules.WorkerInfo)

local Player = game.Players.LocalPlayer
local SideBar = script.Parent.SideBar

local equippedData = {}
local collectedData = {}

local function applyHoverEffect(button, scaleAmount, tweenTime)
	-- Default values if none provided
	scaleAmount = scaleAmount or 1.1
	tweenTime = tweenTime or 0.2

	local originalSize = button.Size
	local hoverSize = UDim2.new(
		originalSize.X.Scale * scaleAmount,
		originalSize.X.Offset * scaleAmount,
		originalSize.Y.Scale * scaleAmount,
		originalSize.Y.Offset * scaleAmount
	)

	local enlargeTween = game:GetService("TweenService"):Create(button, TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = hoverSize
	})
	local shrinkTween = game:GetService("TweenService"):Create(button, TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = originalSize
	})

	button.MouseEnter:Connect(function()
		enlargeTween:Play()
	end)

	button.MouseLeave:Connect(function()
		shrinkTween:Play()
	end)
end

-- Parses "Name:Count,Name2:Count2" into a table
local function parseWorkerString(str)
	local result = {}
	local total = 0
	for _, entry in ipairs(string.split(str, ",")) do
		local parts = string.split(entry, ":")
		if #parts == 2 then
			local name = parts[1]
			local count = tonumber(parts[2]) or 0
			if name and count > 0 then
				result[name] = count
				total += count
			end
		end
	end
	return result, total
end

-- Create one UI card per instance (i.e., Dusty Dan:2 = 2 cards)
local function createWorkerUI(name, isEquipped)
	local count = isEquipped and equippedData[name] or collectedData[name]
	for i = 1, count do
		local Placeholder = script.Placeholder:Clone()
		Placeholder.Name = name
		Placeholder.Parent = script.Parent.Container
		Placeholder.Equipped.Visible = isEquipped
		Placeholder.WorkerName.Text = name
		if isEquipped then
			Placeholder.LayoutOrder = -1
		else
			Placeholder.LayoutOrder = WorkerInfo[name].LayoutOrder
		end
		if WorkerInfo[name].Rarity == "Common" then
			Placeholder.WorkerName.UIGradient.Color = ColorSequence.new(Color3.new(0.607843, 1, 0.764706),Color3.new(0.603922, 1, 0.388235))
			Placeholder.Button.UIGradient.Color = ColorSequence.new(Color3.new(0.607843, 1, 0.764706),Color3.new(0.603922, 1, 0.388235))
		elseif WorkerInfo[name].Rarity == "Rare" then
			Placeholder.WorkerName.UIGradient.Color = ColorSequence.new(Color3.new(0.576471, 0.921569, 1),Color3.new(0.333333, 0.635294, 1))
			Placeholder.Button.UIGradient.Color = ColorSequence.new(Color3.new(0.576471, 0.921569, 1),Color3.new(0.333333, 0.635294, 1))
		elseif WorkerInfo[name].Rarity == "Epic" then
			Placeholder.WorkerName.UIGradient.Color = ColorSequence.new(Color3.new(0.878431, 0.596078, 1),Color3.new(0.678431, 0.309804, 1))
			Placeholder.Button.UIGradient.Color = ColorSequence.new(Color3.new(0.878431, 0.596078, 1),Color3.new(0.678431, 0.309804, 1))
		elseif WorkerInfo[name].Rarity == "Legendary" then
			Placeholder.WorkerName.UIGradient.Color = ColorSequence.new(Color3.new(1, 0.862745, 0.513725),Color3.new(1, 0.576471, 0.27451))
			Placeholder.Button.UIGradient.Color = ColorSequence.new(Color3.new(1, 0.862745, 0.513725),Color3.new(1, 0.576471, 0.27451))
		elseif WorkerInfo[name].Rarity == "Mythical" then
			Placeholder.WorkerName.UIGradient.Color = ColorSequence.new(Color3.new(1, 0.494118, 0.501961),Color3.new(1, 0.203922, 0.215686))
			Placeholder.Button.UIGradient.Color = ColorSequence.new(Color3.new(1, 0.494118, 0.501961),Color3.new(1, 0.203922, 0.215686))
		end

		-- Viewport
		local viewport = Placeholder.Viewport
		local model = game.ReplicatedStorage.Workers:FindFirstChild(name):Clone()

		local camera = Instance.new("Camera")
		camera.FieldOfView = 70
		camera.Parent = viewport

		model.Parent = viewport
		viewport.CurrentCamera = camera

		local vpfModel = ViewportModel.new(viewport, camera)
		local cf, size = model:GetBoundingBox()

		vpfModel:SetModel(model)
		local orientation = CFrame.fromEulerAnglesYXZ(math.rad(-20), math.rad(180), 0)
		local distance = vpfModel:GetFitDistance(cf.Position)
		camera.CFrame = CFrame.new(cf.Position) * orientation * CFrame.new(0, 0, distance)

		applyHoverEffect(Placeholder)

		-- Sidebar Setup
		Placeholder.Button.MouseButton1Click:Connect(function()
			Placeholder.Button.Click:Play()
			SideBar.WorkerName.Text = name

			for _, v in pairs(SideBar.DisplayFrame:GetChildren()) do
				if not v:IsA("UIAspectRatioConstraint") then
					v:Destroy()
				end
			end
			
			if WorkerInfo[name].Rarity == "Common" then
				SideBar.UIGradient.Color = ColorSequence.new(Color3.new(0.607843, 1, 0.764706),Color3.new(0.603922, 1, 0.388235))
			elseif WorkerInfo[name].Rarity == "Rare" then
				SideBar.UIGradient.Color = ColorSequence.new(Color3.new(0.576471, 0.921569, 1),Color3.new(0.333333, 0.635294, 1))
			elseif WorkerInfo[name].Rarity == "Epic" then
				SideBar.UIGradient.Color = ColorSequence.new(Color3.new(0.878431, 0.596078, 1),Color3.new(0.678431, 0.309804, 1))
			elseif WorkerInfo[name].Rarity == "Legendary" then
				SideBar.UIGradient.Color = ColorSequence.new(Color3.new(1, 0.862745, 0.513725),Color3.new(1, 0.576471, 0.27451))
			elseif WorkerInfo[name].Rarity == "Mythical" then
				SideBar.UIGradient.Color = ColorSequence.new(Color3.new(1, 0.494118, 0.501961),Color3.new(1, 0.203922, 0.215686))
			end

			local Display = viewport:Clone()
			Display.Parent = SideBar.DisplayFrame
			Display.Size = UDim2.new(1, 0, 1, 0)

			SideBar.Equip.Visible = true
			SideBar.Fire.Visible = true
			SideBar.Equip.Main.Home.Text = isEquipped and "Unequip" or "Equip"
			SideBar.WorkerValue.Value = name
			SideBar.Equipped.Value = isEquipped
			SideBar.WorkerDescription.Text = "Description: "..WorkerInfo[name].Description
		end)
	end
end

applyHoverEffect(script.Parent.SideBar.Equip)
applyHoverEffect(script.Parent.SideBar.Fire)

function rebuildUI(data)
	-- Parse server strings into tables
	equippedData, equippedCount = parseWorkerString(data.EquippedWorkers)
	collectedData, _ = parseWorkerString(data.CollectedWorkers)

	-- Clear UI
	for _, child in ipairs(script.Parent.Container:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Create UI from parsed data
	for name, _ in pairs(equippedData) do
		createWorkerUI(name, true)
	end
	for name, _ in pairs(collectedData) do
		createWorkerUI(name, false)
	end
end

-- Initial data fetch
local data = {
	EquippedWorkers = Events.Get:InvokeServer({"EquippedWorkers"}).EquippedWorkers,
	CollectedWorkers = Events.Get:InvokeServer({"CollectedWorkers"}).CollectedWorkers
}
rebuildUI(data)

-- Rebuild on server push
Events.RebuildWorkerUI.OnClientEvent:Connect(function()
	local data = {
		EquippedWorkers = Events.Get:InvokeServer({"EquippedWorkers"}).EquippedWorkers,
		CollectedWorkers = Events.Get:InvokeServer({"CollectedWorkers"}).CollectedWorkers
	}
	rebuildUI(data)
end)

-- Update capacity text
--[[Events.UpdateWorkerCapacity.OnClientEvent:Connect(function()
	local Capacity = Player:FindFirstChild("WorkerCapacity").Value
	script.Parent.Capacity.Text = "Capacity: " .. Capacity .. "/30"
end)--]]


local Capacity = Player:WaitForChild("WorkerCapacity")
script.Parent.Capacity.Text = "Capacity: " .. Capacity.Value .. "/30"

Capacity.Changed:Connect(function()
	script.Parent.Capacity.Text = "Capacity: " .. Capacity.Value .. "/30"
end)

-- Equip/Unequip Button Logic
SideBar.Equip.MouseButton1Click:Connect(function()
	SideBar.Equip.Click:Play()
	local workerName = SideBar.WorkerValue.Value
	local isEquipped = SideBar.Equipped.Value
	
	local EquipCapacity = 3
	local maxWorkers = 3
	if Events.Get:InvokeServer({"WorkerSlots"}).WorkerSlots == "Tier1" then
		maxWorkers = 4
	elseif Events.Get:InvokeServer({"WorkerSlots"}).WorkerSlots == "Tier2" then
		maxWorkers = 5
	end
	
	if not isEquipped then
		-- Check if already at capacity
		local totalEquipped = 0
		for _, count in pairs(equippedData) do
			totalEquipped += count
		end
		if totalEquipped >= maxWorkers then
			warn("Max worker limit reached.")
			-- Optionally show a GUI popup here
			return
		end
	end

	local action = isEquipped and "Unequip" or "Equip"
	Events.EquipWorker:FireServer(action, SideBar.WorkerValue.Value)
	
	SideBar.Equip.Visible = false
	SideBar.Fire.Visible = false
	SideBar.WorkerValue.Value = ""
	SideBar.Equipped.Value = false
	SideBar.WorkerName.Text = ""
	SideBar.WorkerDescription.Text = ""
	SideBar.UIGradient.Color = ColorSequence.new(Color3.new(1, 1, 1),Color3.new(1, 1, 1))
	
	for _, v in pairs(SideBar.DisplayFrame:GetChildren()) do
		if not v:IsA("UIAspectRatioConstraint") then
			v:Destroy()
		end
	end
end)

SideBar.Fire.MouseButton1Click:Connect(function()
	SideBar.Fire.Click:Play()
	local workerName = SideBar.WorkerValue.Value
	local isEquipped = SideBar.Equipped.Value
	
	if workerName then
		if WorkerInfo[workerName].Rarity == "Mythical" or WorkerInfo[workerName].Rarity == "Legendary"  then
			script.Parent.Confirmation.Visible = true
			script.Parent.Confirmation.Description.Text = "Are you sure you want to delete "..workerName.."?"
			
			local AcceptCon
			local RejectConn
			
			AcceptCon = script.Parent.Confirmation.Accept.MouseButton1Click:Connect(function()
				script.Parent.Confirmation.Accept.Click:Play()
				Events.FireWorker:FireServer(workerName,isEquipped)

				SideBar.Equip.Visible = false
				SideBar.Fire.Visible = false
				SideBar.WorkerValue.Value = ""
				SideBar.Equipped.Value = false
				SideBar.WorkerName.Text = ""
				SideBar.WorkerDescription.Text = ""
				SideBar.UIGradient.Color = ColorSequence.new(Color3.new(1, 1, 1),Color3.new(1, 1, 1))

				for _, v in pairs(SideBar.DisplayFrame:GetChildren()) do
					if not v:IsA("UIAspectRatioConstraint") then
						v:Destroy()
					end
				end
				
				script.Parent.Confirmation.Visible = false
				
				AcceptCon:Disconnect()
				if RejectConn then
					RejectConn:Disconnect()
				end
			end)
			
			RejectConn = script.Parent.Confirmation.Unsure.MouseButton1Click:Connect(function()
				script.Parent.Confirmation.Unsure.Click:Play()
				script.Parent.Confirmation.Visible = false
				
				RejectConn:Disconnect()
				if AcceptCon then
					AcceptCon:Disconnect()
				end
			end)
		else
			
			Events.FireWorker:FireServer(workerName,isEquipped)
			
			SideBar.Equip.Visible = false
			SideBar.Fire.Visible = false
			SideBar.WorkerValue.Value = ""
			SideBar.Equipped.Value = false
			SideBar.WorkerName.Text = ""
			SideBar.WorkerDescription.Text = ""
			SideBar.UIGradient.Color = ColorSequence.new(Color3.new(1, 1, 1),Color3.new(1, 1, 1))
			
			for _, v in pairs(SideBar.DisplayFrame:GetChildren()) do
				if not v:IsA("UIAspectRatioConstraint") then
					v:Destroy()
				end
			end
		end
	end
end)

