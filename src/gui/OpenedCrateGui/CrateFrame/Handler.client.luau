local Events = game.ReplicatedStorage.Events

local CrateData = require(game.ReplicatedStorage.Modules.CrateChances)
local ViewportModel = require(game.ReplicatedStorage.Modules.ViewportModel)
local WorkerInfo = require(game.ReplicatedStorage.Modules.WorkerInfo)
local ItemInfo = require(game.ReplicatedStorage.Modules.ItemInfo)

local openedGui = script.Parent.Parent
local openedFrame = openedGui:WaitForChild("CrateFrame")
local closeOpenedBtn = openedFrame:WaitForChild("ContinueButton")
local openedItemsFrame = openedFrame:WaitForChild("ItemsFrame")

local openingCrateItemTemplate = script:WaitForChild("OpeningCrateItemFrame")

local rnd = Random.new()

closeOpenedBtn.MouseButton1Click:Connect(function()
	openedFrame.Visible = false
	openedGui.Enabled = false

	for _, child in pairs(openedItemsFrame.ItemsContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end)

--Unboxing crates
function lerp(a, b, t)
	return a + (b-a) * t
end

function tweenGraph(x, pow)
	x = math.clamp(x, 0, 1)
	return 1 - (1-x)^pow
end


Events.OpenCrate.OnClientEvent:Connect(function(crateName, itemChosen, unboxTime)
	local crateProperties = CrateData[crateName]

	local numItems = rnd:NextInteger(70, 80)
	local chosenPosition = rnd:NextInteger(60, numItems - 5)

	-- Generate scroll contents first
	local scrollItems = {}

	-- Convert 1-in-N odds to actual weights (higher = more common)
	local weights = {}
	local totalWeight = 0
	for item, inverseChance in pairs(crateProperties) do
		local weight = 1 / inverseChance
		weights[item] = weight
		totalWeight += weight
	end

	-- Fill the scroll with items based on real weight distribution
	for i = 1, numItems do
		local pick = rnd:NextNumber(0, totalWeight)
		local cumulative = 0
		for item, weight in pairs(weights) do
			cumulative += weight
			if pick <= cumulative then
				table.insert(scrollItems, item)
				break
			end
		end
	end

	-- Force the correct item at the chosen position
	scrollItems[chosenPosition] = itemChosen

	for i, itemName in ipairs(scrollItems) do
		local PickedData
		local randomItemChosen

		if WorkerInfo[itemName] then
			PickedData = WorkerInfo
			randomItemChosen = game.ReplicatedStorage.Workers:FindFirstChild(itemName)
		elseif ItemInfo[itemName] then
			PickedData = ItemInfo	
			randomItemChosen = game.ReplicatedStorage.System.Parts:FindFirstChild(itemName)
		end
		if not randomItemChosen and not PickedData then continue end -- just in case
		print(PickedData)

		local newItemFrame = openingCrateItemTemplate:Clone()
		newItemFrame.ItemName.Text = itemName
		

		if PickedData[itemName] then
			local EquipmentData = PickedData[itemName]
			local GradientColor = (function()
				if EquipmentData.Rarity == "Celestial" then
					return ColorSequence.new(Color3.new(0.960784, 1, 0.701961), Color3.new(1, 0.894118, 0.360784))
				elseif EquipmentData.Rarity == "Mythical" then
					return ColorSequence.new(Color3.new(0.658824, 0.168627, 0.192157), Color3.new(1, 0, 0.0156863))
				elseif EquipmentData.Rarity == "Legendary" then
					return ColorSequence.new(Color3.new(1, 0.701961, 0), Color3.new(1, 0.533333, 0.00392157))
				elseif EquipmentData.Rarity == "Epic" then
					return ColorSequence.new(Color3.new(0.807843, 0.423529, 1), Color3.new(0.670588, 0.105882, 0.784314))
				elseif EquipmentData.Rarity == "Rare" then
					return ColorSequence.new(Color3.new(0.486275, 0.752941, 1), Color3.new(0.286275, 0.596078, 1))
				elseif EquipmentData.Rarity == "Uncommon" then
					return ColorSequence.new(Color3.new(0.52549, 1, 0.603922), Color3.new(0.596078, 1, 0.160784))
				elseif EquipmentData.Rarity == "Common" then
					return ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
				else
					return ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
				end
			end)()

			newItemFrame.ItemName.UIGradient.Color = GradientColor
			newItemFrame.FrameIMG.UIGradient.Color = GradientColor
		end

	--[[	local itemModel = Instance.new("Model")
		for _, child in pairs(randomItemChosen:GetChildren()) do
			if not (child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript") or child:IsA("Sound")) then
				child:Clone().Parent = itemModel
			end
		end

		itemModel:PivotTo(CFrame.new(0, 0, -3) * CFrame.Angles(0, math.rad(180), 0))
		itemModel.Parent = newItemFrame.ItemImage

		local currentCamera = Instance.new("Camera")
		currentCamera.CFrame = CFrame.new()
		currentCamera.Parent = newItemFrame.ItemImage
		newItemFrame.ItemImage.CurrentCamera = currentCamera--]]
		local viewport = newItemFrame.ItemImage
		local model = randomItemChosen:Clone()

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

		newItemFrame.Parent = openedItemsFrame.ItemsContainer 
	end

	openedItemsFrame.ItemsContainer.Position = UDim2.new(0, 0, 0.5, 0)

	local cellSize = openingCrateItemTemplate.Size.X.Scale
	local padding = openedItemsFrame.ItemsContainer.UIListLayout.Padding.Scale
	local pos1 = 0.5 - cellSize/2
	local nextOffset = -cellSize - padding

	local posFinal = pos1 + (chosenPosition-1) * nextOffset
	local rndOffset = rnd:NextNumber(-cellSize/2, cellSize/2)
	posFinal += rndOffset

	local timeOpened = tick()

	openedFrame.CrateName.Text = crateName
	closeOpenedBtn.Visible = false
	openedFrame.Visible = true
	openedGui.Enabled = true

	local pow = rnd:NextNumber(2, 3)
	local lastSlot = 0

	while true do
		local timeSinceOpened = tick() - timeOpened
		local x = timeSinceOpened / unboxTime

		local t = tweenGraph(x, pow)
		local newXPos = lerp(0, posFinal, t)

		local currentSlot = math.abs(math.floor((newXPos+rndOffset)/cellSize))+1
		if currentSlot ~= lastSlot then
			script.TickSound:Play()
			lastSlot = currentSlot
		end

		openedItemsFrame.ItemsContainer.Position = UDim2.new(newXPos, 0, 0.5, 0)

		if x >= 1 then
			break
		end

		game:GetService("RunService").Heartbeat:Wait()
	end
	script.Reward:Play()
	closeOpenedBtn.Visible = true
end)

