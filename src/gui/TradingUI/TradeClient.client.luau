local Events = game.ReplicatedStorage.Events

local TweenService = game:GetService("TweenService")

local ItemInfo = require(game.ReplicatedStorage.Modules.ItemInfo)
local WorkerInfo = require(game.ReplicatedStorage.Modules.WorkerInfo)
local ViewportModel = require(game.ReplicatedStorage.Modules.ViewportModel)

local LocalPlayer = game.Players.LocalPlayer

local currentAmountConn
local DiamondChangedConn
local RejectConn
local AcceptConn

local function isAllNumbers(str)
	return string.match(str, "^%d+$") ~= nil
end

local function applyHoverEffect(button, scaleAmount, tweenTime)
	-- Default values if none provided
	scaleAmount = scaleAmount or 1.1
	tweenTime = tweenTime or 0.2

	if not button:IsA("GuiButton") then
		warn("applyHoverEffect: argument is not a GuiButton")
		return
	end

	local originalSize = button.Size
	local hoverSize = UDim2.new(
		originalSize.X.Scale * scaleAmount,
		originalSize.X.Offset * scaleAmount,
		originalSize.Y.Scale * scaleAmount,
		originalSize.Y.Offset * scaleAmount
	)

	local enlargeTween = TweenService:Create(button, TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = hoverSize
	})
	local shrinkTween = TweenService:Create(button, TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = originalSize
	})

	button.MouseEnter:Connect(function()
		enlargeTween:Play()
	end)

	button.MouseLeave:Connect(function()
		shrinkTween:Play()
	end)
end

applyHoverEffect(script.Parent.TradeRequest.Decline)
applyHoverEffect(script.Parent.TradeRequest.Accept)

Events.RequestTrade.OnClientEvent:Connect(function(Player)
	if game.Players:FindFirstChild(Player.Name) then
		
		script.Parent.TradeRequest.Visible = true
		script.Parent.TradeRequest.TradeDescription.Text = Player.Name.." has requested a trade with you."

		script.Parent.TradeRequest.Decline.MouseButton1Click:Connect(function()
			script.Parent.TradeRequest.Visible = false
		end)
		script.Parent.TradeRequest.Accept.MouseButton1Click:Connect(function()
			script.Parent.TradeRequest.Visible = false
			Events.AcceptTradeRequest:FireServer(Player)
		end)
	end
end)

Events.StartTrade.OnClientEvent:Connect(function(OtherPlayer)
	script.Parent.TradeRequest.Visible = false
	script.Parent.Trading.Visible = true
	script.Parent.Trading.PlayerOffer.PlayerName.Text = OtherPlayer.Name.."'s OFFER"

	local Collection = Events.Get:InvokeServer({"Collection"}).Collection
	local Workers = Events.Get:InvokeServer({"CollectedWorkers"}).CollectedWorkers

	local function parseStringToTable(dataStr)
		local result = {}
		for name, amount in string.gmatch(dataStr, "([^:,]+):(%d+),") do
			result[name] = tonumber(amount)
		end
		return result
	end

	local collectionTable = parseStringToTable(Collection)
	local workerTable = parseStringToTable(Workers)

	local OfferList = script.Parent.Trading.YourInventory.Container
	for _, item in pairs(OfferList:GetChildren()) do
		if item:IsA("Frame") and item.Name ~= "Template" then
			item:Destroy()
		end
	end
	
	RejectConn = script.Parent.Trading.Decline.MouseButton1Click:Connect(function()
		
		Events.CancelTrade:FireServer()
		RejectConn:Disconnect()
	end)
	
	AcceptConn = script.Parent.Trading.Accept.MouseButton1Click:Connect(function()
		
		Events.AcceptTrade:FireServer()
	end)
	
	DiamondChangedConn = script.Parent.Trading.YourInventory.DiamondBox.FocusLost:Connect(function()
		local amount = tonumber(script.Parent.Trading.YourInventory.DiamondBox.Text)

		-- ❌ Not a number
		if not amount then
			warn("Invalid input: not a number")
			script.Parent.Trading.YourInventory.DiamondBox.Text = "Invalid input: not a number"
			return
		end

		-- ❌ Not positive
		if amount <= 0 then
			warn("Invalid input: must be greater than 0")
			script.Parent.Trading.YourInventory.DiamondBox.Text = "Invalid input: must be greater than 0"
			return
		end

		if isAllNumbers(script.Parent.Trading.YourInventory.DiamondBox.Text) == false then
			warn("has to be all numbers")
			script.Parent.Trading.YourInventory.DiamondBox.Text = "Invalid input: not a number"
			return
		end
		
		-- ✅ Valid – fire to server
		Events.AddToTradeOffer:FireServer({
			Item = "Diamonds",
			Amount = amount,
			IsDiamond = true
		})
	end)

	local function createItem(name, amount, isWorker)
		if not isWorker and not ItemInfo[name] then return end
		if not isWorker and not ItemInfo[name].Drill then return end
		local newItem = script.Placeholder:Clone()
		newItem.Name = name
		newItem.Visible = true
		newItem.ItemName.Text = name
		newItem.ItemAmount.Text = "x"..amount
		if isWorker then
			if WorkerInfo[name].Rarity == "Common" then
				newItem.Button.UIGradient.Color = ColorSequence.new(Color3.new(0.607843, 1, 0.764706),Color3.new(0.603922, 1, 0.388235))
			elseif WorkerInfo[name].Rarity == "Rare" then
				newItem.Button.UIGradient.Color = ColorSequence.new(Color3.new(0.576471, 0.921569, 1),Color3.new(0.333333, 0.635294, 1))
			elseif WorkerInfo[name].Rarity == "Epic" then
				newItem.Button.UIGradient.Color = ColorSequence.new(Color3.new(0.878431, 0.596078, 1),Color3.new(0.678431, 0.309804, 1))
			elseif WorkerInfo[name].Rarity == "Legendary" then
				newItem.Button.UIGradient.Color = ColorSequence.new(Color3.new(1, 0.862745, 0.513725),Color3.new(1, 0.576471, 0.27451))
			elseif WorkerInfo[name].Rarity == "Mythical" then
				newItem.Button.UIGradient.Color = ColorSequence.new(Color3.new(1, 0.494118, 0.501961),Color3.new(1, 0.203922, 0.215686))
			elseif WorkerInfo[name].Rarity == "Celestial" then
				newItem.Button.UIGradient.Color = ColorSequence.new(Color3.new(1, 1, 0.501961),Color3.new(1, 0.858824, 0.160784))
			end
			-- Viewport
			local viewport = newItem.Viewport
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
		else
			if ItemInfo[name].Rarity == "Common" then
				newItem.Button.UIGradient.Color = ColorSequence.new(Color3.new(0.607843, 1, 0.764706),Color3.new(0.603922, 1, 0.388235))
			elseif ItemInfo[name].Rarity == "Rare" then
				newItem.Button.UIGradient.Color = ColorSequence.new(Color3.new(0.576471, 0.921569, 1),Color3.new(0.333333, 0.635294, 1))
			elseif ItemInfo[name].Rarity == "Epic" then
				newItem.Button.UIGradient.Color = ColorSequence.new(Color3.new(0.878431, 0.596078, 1),Color3.new(0.678431, 0.309804, 1))
			elseif ItemInfo[name].Rarity == "Legendary" then
				newItem.Button.UIGradient.Color = ColorSequence.new(Color3.new(1, 0.862745, 0.513725),Color3.new(1, 0.576471, 0.27451))
			elseif ItemInfo[name].Rarity == "Mythical" then
				newItem.Button.UIGradient.Color = ColorSequence.new(Color3.new(1, 0.494118, 0.501961),Color3.new(1, 0.203922, 0.215686))
			elseif ItemInfo[name].Rarity == "Celestial" then
				newItem.Button.UIGradient.Color = ColorSequence.new(Color3.new(1, 1, 0.501961),Color3.new(1, 0.858824, 0.160784))
			end
			local viewport = newItem.Viewport
			local model = game.ReplicatedStorage.System.Parts:FindFirstChild(name):Clone()

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
		end
		newItem.Parent = OfferList

		newItem.Button.MouseButton1Click:Connect(function()
			local TradeUI = script.Parent.Trading
			local AmountPrompt = TradeUI.Amount
			local AcceptButton = AmountPrompt.Accept
			local TextBox = AmountPrompt.TextBox
			local Description = AmountPrompt.Description
			
			if newItem.Offered.Value == true then
				-- Reset offered state
				newItem.Offered.Value = false

				-- Restore amount text to what player owns
				local ownedAmount = isWorker and workerTable[name] or collectionTable[name]
				newItem.ItemAmount.Text = "x"..ownedAmount
				newItem.ItemAmount.TextColor3 = Color3.new(1, 1, 1)

				-- Optionally: reset layout order
				newItem.LayoutOrder = 1

				-- (Optional) Notify server to remove the item from the offer list
				Events.RemoveFromTradeOffer:FireServer({
					Item = name,
					IsWorker = isWorker
				})

				return -- Exit early to avoid prompting again
			end

			-- Show prompt
			AmountPrompt.Visible = true
			Description.Text = "How many "..name.." are you offering?"
			TextBox.Text = ""

			-- Disconnect the previous connection if one exists
			if currentAmountConn then
				currentAmountConn:Disconnect()
				currentAmountConn = nil
			end

			-- Connect new one
			currentAmountConn = AcceptButton.MouseButton1Click:Connect(function()
				local inputAmount = tonumber(TextBox.Text)

				if not inputAmount or inputAmount <= 0 then
					warn("Invalid amount entered")
					return
				end

				local ownedAmount = isWorker and workerTable[name] or collectionTable[name]
				if inputAmount > ownedAmount then
					warn("Player does not have enough of this item")
					return
				end
				
				if isAllNumbers(TextBox.Text) == false then
					warn("has to be all numbers")
					return
				end

				print("✔ Player is offering:", inputAmount, name)

				Events.AddToTradeOffer:FireServer({
					Item = name,
					Amount = inputAmount,
					IsWorker = isWorker
				})

				AmountPrompt.Visible = false
				TextBox.Text = ""
			end)
		end)
	end

	for name, amount in pairs(collectionTable) do
		createItem(name, amount, false)
	end

	for name, amount in pairs(workerTable) do
		createItem(name, amount, true)
	end
end)

Events.UpdateOwnTradeOffer.OnClientEvent:Connect(function(Data)
	
	if Data.Accepted and Data.Accepted == true then
		script.Parent.Trading.YourInventory.Accepted.Visible = true
		return
	elseif Data.Accepted == false then
		script.Parent.Trading.YourInventory.Accepted.Visible = false
		return
	end
	
	if Data.RemoveItem then
		local OfferList = script.Parent.Trading.YourInventory.Container
		for _, item in pairs(OfferList:GetChildren()) do
			if item.Name  == Data.Item then

				local Collection = Events.Get:InvokeServer({"Collection"}).Collection
				local Workers = Events.Get:InvokeServer({"CollectedWorkers"}).CollectedWorkers
				
				local function parseStringToTable(dataStr)
					local result = {}
					for name, amount in string.gmatch(dataStr, "([^:,]+):(%d+),") do
						result[name] = tonumber(amount)
					end
					return result
				end

				local collectionTable = parseStringToTable(Collection)
				local workerTable = parseStringToTable(Workers)
				-- Reset offered state
				item.Offered.Value = false

				-- Restore amount text to what player owns
				local ownedAmount 
				if workerTable[Data.Item] then
					ownedAmount = workerTable[Data.Item]
				else
					ownedAmount = collectionTable[Data.Item]
				end
				item.ItemAmount.Text = "x"..ownedAmount
				item.ItemAmount.TextColor3 = Color3.new(1, 1, 1)

				-- Optionally: reset layout order
				item.LayoutOrder = 1
			end
		end

		return -- Exit early to avoid prompting again
	end
	
	local Name = Data.Item
	local Amount = Data.Amount
	local IsWorker = Data.IsWorker
	
	local OfferList = script.Parent.Trading.YourInventory.Container
	for _, item in pairs(OfferList:GetChildren()) do
		if item.Name  == Name then
			item.LayoutOrder = 0
			
			item.ItemAmount.Text = "x"..Amount
			item.ItemAmount.TextColor3 = Color3.new(0.509804, 1, 0.423529)
			item.Offered.Value = true
		end
	end
end)

Events.UpdatePartnerTradeOffer.OnClientEvent:Connect(function(Data)
	if Data.Accepted and Data.Accepted == true then
		script.Parent.Trading.PlayerOffer.Accepted.Visible = true
		return
	elseif Data.Accepted == false then
		script.Parent.Trading.PlayerOffer.Accepted.Visible = false
		return
	end
	
	if Data.IsDiamond then
		script.Parent.Trading.PlayerOffer.DiamondOffer.Text = Data.Amount.." Diamonds"
		return
	end
	
	if Data.RemoveItem then
		print("huh")
		for i,v in pairs(script.Parent.Trading.PlayerOffer.Container:GetChildren()) do
			if v.Name == Data.Item then
				v:Destroy()
			end
		end
		return
	end
	local Item = Data.Item
	local Amount = Data.Amount
	local IsWorker = Data.IsWorker
	
	local newItem = script.Placeholder:Clone()
	newItem.Name = Item
	newItem.Visible = true
	newItem.ItemName.Text = Item
	newItem.ItemAmount.Text = "x"..Amount
	if IsWorker then
		if WorkerInfo[Item].Rarity == "Common" then
			newItem.Button.UIGradient.Color = ColorSequence.new(Color3.new(0.607843, 1, 0.764706),Color3.new(0.603922, 1, 0.388235))
		elseif WorkerInfo[Item].Rarity == "Rare" then
			newItem.Button.UIGradient.Color = ColorSequence.new(Color3.new(0.576471, 0.921569, 1),Color3.new(0.333333, 0.635294, 1))
		elseif WorkerInfo[Item].Rarity == "Epic" then
			newItem.Button.UIGradient.Color = ColorSequence.new(Color3.new(0.878431, 0.596078, 1),Color3.new(0.678431, 0.309804, 1))
		elseif WorkerInfo[Item].Rarity == "Legendary" then
			newItem.Button.UIGradient.Color = ColorSequence.new(Color3.new(1, 0.862745, 0.513725),Color3.new(1, 0.576471, 0.27451))
		elseif WorkerInfo[Item].Rarity == "Mythical" then
			newItem.Button.UIGradient.Color = ColorSequence.new(Color3.new(1, 0.494118, 0.501961),Color3.new(1, 0.203922, 0.215686))
		elseif WorkerInfo[Item].Rarity == "Celestial" then
			newItem.Button.UIGradient.Color = ColorSequence.new(Color3.new(1, 1, 0.501961),Color3.new(1, 0.858824, 0.160784))
		end
		-- Viewport
		local viewport = newItem.Viewport
		local model = game.ReplicatedStorage.Workers:FindFirstChild(Item):Clone()

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
	else
		if ItemInfo[Item].Rarity == "Common" then
			newItem.Button.UIGradient.Color = ColorSequence.new(Color3.new(0.607843, 1, 0.764706),Color3.new(0.603922, 1, 0.388235))
		elseif ItemInfo[Item].Rarity == "Rare" then
			newItem.Button.UIGradient.Color = ColorSequence.new(Color3.new(0.576471, 0.921569, 1),Color3.new(0.333333, 0.635294, 1))
		elseif ItemInfo[Item].Rarity == "Epic" then
			newItem.Button.UIGradient.Color = ColorSequence.new(Color3.new(0.878431, 0.596078, 1),Color3.new(0.678431, 0.309804, 1))
		elseif ItemInfo[Item].Rarity == "Legendary" then
			newItem.Button.UIGradient.Color = ColorSequence.new(Color3.new(1, 0.862745, 0.513725),Color3.new(1, 0.576471, 0.27451))
		elseif ItemInfo[Item].Rarity == "Mythical" then
			newItem.Button.UIGradient.Color = ColorSequence.new(Color3.new(1, 0.494118, 0.501961),Color3.new(1, 0.203922, 0.215686))
		elseif ItemInfo[Item].Rarity == "Celestial" then
			newItem.Button.UIGradient.Color = ColorSequence.new(Color3.new(1, 1, 0.501961),Color3.new(1, 0.858824, 0.160784))
		end
		local viewport = newItem.Viewport
		local model = game.ReplicatedStorage.System.Parts:FindFirstChild(Item):Clone()

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
	end
	newItem.Parent = script.Parent.Trading.PlayerOffer.Container
end) 

Events.CancelTrade.OnClientEvent:Connect(function()
	script.Parent.Trading.Visible = false

	local OfferList = script.Parent.Trading.YourInventory.Container
	for _, item in pairs(OfferList:GetChildren()) do
		if item:IsA("Frame") and item.Name ~= "Template" then
			item:Destroy()
		end
	end

	local PartnerList = script.Parent.Trading.PlayerOffer.Container
	for _, item in pairs(PartnerList:GetChildren()) do
		if item:IsA("Frame") and item.Name ~= "Template" then
			item:Destroy()
		end
	end

	-- Optional: reset diamonds or other state if needed
	script.Parent.Trading.PlayerOffer.DiamondOffer.Text = ""
	script.Parent.Trading.PlayerOffer.Accepted.Visible = false
	script.Parent.Trading.YourInventory.DiamondBox.Text = ""
	script.Parent.Trading.YourInventory.Accepted.Visible = false
end)