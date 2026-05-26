local Events = game.ReplicatedStorage.Events
local ItemInfo = require(game.ReplicatedStorage.Modules.ItemInfo)
local ViewportModel = require(game.ReplicatedStorage.Modules.ViewportModel)

local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local GUI = script.Parent
local ListFrame = GUI:WaitForChild("List")

function formatnumber(number)
	local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
	int = int:reverse():gsub("(%d%d%d)", "%1,")
	return minus .. int:reverse():gsub("^,", "") .. fraction
end

local function applyClickTween(button: GuiButton)
	local downTween = TweenService:Create(button, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = button.Position + UDim2.new(0, 0, 0.02, 0)
	})

	local upTween = TweenService:Create(button, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = button.Position
	})

	button.MouseButton1Click:Connect(function()
		downTween:Play()
		downTween.Completed:Wait()
		upTween:Play()
	end)
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

local SplitInventory: table = string.split(Events.Get:InvokeServer({"Collection"}).Collection, ",")
for i,v in pairs(SplitInventory) do
	if v ~= "" then
		local ItemAndAmount: table = string.split(v, ":")
		if ItemInfo[ItemAndAmount[1]] and ItemInfo[ItemAndAmount[1]].Price then
			local Placeholder = script.Placeholder:Clone()
			Placeholder.Parent = ListFrame
			Placeholder.Name = ItemAndAmount[1]
			Placeholder.ItemPrice.Text = formatnumber(tonumber(ItemAndAmount[2]) * ItemInfo[ItemAndAmount[1]].Price).."$"
			Placeholder.ItemName.Text = formatnumber(ItemAndAmount[2]).." "..ItemAndAmount[1]

			if ItemInfo[ItemAndAmount[1]].Rarity == "Common" then
				Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(0.607843, 1, 0.764706),Color3.new(0.603922, 1, 0.388235))
				Placeholder.LayoutOrder = 1
			elseif ItemInfo[ItemAndAmount[1]].Rarity == "Rare" then
				Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(0.576471, 0.921569, 1),Color3.new(0.333333, 0.635294, 1))
				Placeholder.LayoutOrder = 2
			elseif ItemInfo[ItemAndAmount[1]].Rarity == "Epic" then
				Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(0.878431, 0.596078, 1),Color3.new(0.678431, 0.309804, 1))
				Placeholder.LayoutOrder = 3
			elseif ItemInfo[ItemAndAmount[1]].Rarity == "Legendary" then
				Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(1, 0.862745, 0.513725),Color3.new(1, 0.576471, 0.27451))
				Placeholder.LayoutOrder = 4
			elseif ItemInfo[ItemAndAmount[1]].Rarity == "Mythical" then
				Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(1, 0.494118, 0.501961),Color3.new(1, 0.203922, 0.215686))
				Placeholder.LayoutOrder = 5
			elseif ItemInfo[ItemAndAmount[1]].Rarity == "Celestial" then
				Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(1, 1, 0.556863),Color3.new(1, 0.796078, 0.32549))
				Placeholder.LayoutOrder = 6
			elseif ItemInfo[ItemAndAmount[1]].Rarity == "Secret" then
				Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(0, 0, 0),Color3.new(1, 1, 1))
				Placeholder.LayoutOrder = 7
			end

			applyHoverEffect(Placeholder.Sell)

			Placeholder.Sell.MouseButton1Down:Connect(function()
				Placeholder.Sell.Click:Play()
				Events.Sell:FireServer(ItemAndAmount[1])
			end)
		elseif ItemInfo[ItemAndAmount[1]] and ItemInfo[ItemAndAmount[1]].Coins then
			local Placeholder = script.Placeholder:Clone()
			Placeholder.Parent = ListFrame
			Placeholder.Name = ItemAndAmount[1]
			Placeholder.ItemPrice.Text = formatnumber(tonumber(ItemAndAmount[2]) * ItemInfo[ItemAndAmount[1]].Coins).."$"
			Placeholder.ItemName.Text = formatnumber(ItemAndAmount[2]).." "..ItemAndAmount[1]

			applyHoverEffect(Placeholder.Sell)

			if ItemInfo[ItemAndAmount[1]].Rarity == "Common" then
				Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(0.607843, 1, 0.764706),Color3.new(0.603922, 1, 0.388235))
				Placeholder.LayoutOrder = -7
			elseif ItemInfo[ItemAndAmount[1]].Rarity == "Rare" then
				Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(0.576471, 0.921569, 1),Color3.new(0.333333, 0.635294, 1))
				Placeholder.LayoutOrder = -6
			elseif ItemInfo[ItemAndAmount[1]].Rarity == "Epic" then
				Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(0.878431, 0.596078, 1),Color3.new(0.678431, 0.309804, 1))
				Placeholder.LayoutOrder = -5
			elseif ItemInfo[ItemAndAmount[1]].Rarity == "Legendary" then
				Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(1, 0.862745, 0.513725),Color3.new(1, 0.576471, 0.27451))
				Placeholder.LayoutOrder = -4
			elseif ItemInfo[ItemAndAmount[1]].Rarity == "Mythical" then
				Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(1, 0.494118, 0.501961),Color3.new(1, 0.203922, 0.215686))
				Placeholder.LayoutOrder = -3
			elseif ItemInfo[ItemAndAmount[1]].Rarity == "Celestial" then
				Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(1, 1, 0.556863),Color3.new(1, 0.796078, 0.32549))
				Placeholder.LayoutOrder = -2
			elseif ItemInfo[ItemAndAmount[1]].Rarity == "Secret" then
				Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(0, 0, 0),Color3.new(1, 1, 1))
				Placeholder.LayoutOrder = -1
			end

			Placeholder.Sell.MouseButton1Down:Connect(function()
				Placeholder.Sell.Click:Play()
				Events.Sell:FireServer(ItemAndAmount[1])
			end)
		end
	end
end

applyHoverEffect(script.Parent.SellAll)

script.Parent.SellAll.MouseButton1Click:Connect(function()
	script.Parent.SellAll.Click:Play()
	Events.Sell:FireServer("All")
end)

ProximityPromptService.PromptShown:Connect(function(promptInstance)
	if promptInstance.Name == "Dialogue" then
		local NPC = promptInstance.Parent
		local Camera = game.Workspace.CurrentCamera

		local BlurEffect = Instance.new("BlurEffect")
		BlurEffect.Size = 0
		BlurEffect.Parent = game.Lighting

		TweenService:Create(BlurEffect,TweenInfo.new(0.8),{Size = 24}):Play()
		TweenService:Create(Camera,TweenInfo.new(0.8),{FieldOfView = 50}):Play()

		script.Parent.Visible = true
	end
end)

ProximityPromptService.PromptHidden:Connect(function(promptInstance)
	if promptInstance.Name == "Dialogue" then
		local Camera = game.Workspace.CurrentCamera
		TweenService:Create(Camera,TweenInfo.new(0.8),{FieldOfView = 70}):Play()

		script.Parent.Visible =false

		for i,v in pairs(game.Lighting:GetChildren()) do
			if v:IsA("BlurEffect") then
				TweenService:Create(v,TweenInfo.new(0.8),{Size = 0}):Play()
				game:GetService("Debris"):AddItem(v,0.8)
			end
		end
	end
end)

local function updateSellUI()
	local existingFrames = {}
	for _, child in ipairs(ListFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "First" then
			existingFrames[child.Name] = child
		end
	end

	local seen = {}
	local PlayerData = Events.Get:InvokeServer({"Collection", "LockedOres"})
	local SplitInventory: table = string.split(PlayerData.Collection, ",")

	local LockedOres = {}
	if PlayerData.LockedOres then
		for _, ore in ipairs(string.split(PlayerData.LockedOres, ",")) do
			LockedOres[ore] = true
		end
	end

	for _, entry in ipairs(SplitInventory) do
		if entry ~= "" then
			local itemName, amountStr = unpack(string.split(entry, ":"))
			local amount = tonumber(amountStr)
			local itemData = ItemInfo[itemName]

			if itemData then
				local isDrill = itemData.Coins ~= nil
				local valuePerItem = isDrill and itemData.Coins or itemData.Price
				local isLockedOre = not isDrill and LockedOres[itemName]

				if valuePerItem and not isLockedOre then
					local frame = existingFrames[itemName]

					local displayPrice = formatnumber(amount * valuePerItem) .. "$"
					local displayName = formatnumber(amount) .. " " .. itemName
					local layoutOrder = isDrill and 0 or amount * valuePerItem

					if isDrill then
						if itemData.Rarity == "Common" then
							layoutOrder = -7
						elseif itemData.Rarity == "Rare" then
							layoutOrder = -6
						elseif itemData.Rarity == "Epic" then
							layoutOrder = -5
						elseif itemData.Rarity == "Legendary" then
							layoutOrder = -4
						elseif itemData.Rarity == "Mythical" then
							layoutOrder = -3
						elseif itemData.Rarity == "Celestial" then
							layoutOrder = -2
						elseif itemData.Rarity == "Secret" then
							layoutOrder = -1
						end
					else
						if itemData.Rarity == "Common" then
							layoutOrder = 1
						elseif itemData.Rarity == "Rare" then
							layoutOrder = 2
						elseif itemData.Rarity == "Epic" then
							layoutOrder = 3
						elseif itemData.Rarity == "Legendary" then
							layoutOrder = 4
						elseif itemData.Rarity == "Mythical" then
							layoutOrder = 5
						elseif itemData.Rarity == "Celestial" then
							layoutOrder = 6
						elseif itemData.Rarity == "Secret" then
							layoutOrder = 7
						end
					end
					
					if frame then
						frame.ItemPrice.Text = displayPrice
						frame.ItemName.Text = displayName
						frame.LayoutOrder = layoutOrder
						existingFrames[itemName] = nil
					else
						local Placeholder = script.Placeholder:Clone()
						Placeholder.Name = itemName
						Placeholder.Parent = ListFrame
						Placeholder.ItemPrice.Text = displayPrice
						Placeholder.ItemName.Text = displayName
						Placeholder.LayoutOrder = layoutOrder

						--[[if isDrill then
							-- Drill color: Gold-ish or custom
							local drillColor = Color3.fromRGB(255, 203, 81)
							Placeholder.ItemName.TextColor3 = drillColor
							Placeholder.ItemPrice.TextColor3 = drillColor
						end--]]
						
						if ItemInfo[itemName].Rarity == "Common" then
							Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(0.607843, 1, 0.764706),Color3.new(0.603922, 1, 0.388235))
						elseif ItemInfo[itemName].Rarity == "Rare" then
							Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(0.576471, 0.921569, 1),Color3.new(0.333333, 0.635294, 1))
						elseif ItemInfo[itemName].Rarity == "Epic" then
							Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(0.878431, 0.596078, 1),Color3.new(0.678431, 0.309804, 1))
						elseif ItemInfo[itemName].Rarity == "Legendary" then
							Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(1, 0.862745, 0.513725),Color3.new(1, 0.576471, 0.27451))
						elseif ItemInfo[itemName].Rarity == "Mythical" then
							Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(1, 0.494118, 0.501961),Color3.new(1, 0.203922, 0.215686))
						elseif ItemInfo[itemName].Rarity == "Celestial" then
							Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(1, 1, 0.556863),Color3.new(1, 0.796078, 0.32549))
						end

						applyHoverEffect(Placeholder.Sell)

						Placeholder.Sell.MouseButton1Down:Connect(function()
							Placeholder.Sell.Click:Play()
							Events.Sell:FireServer(itemName)
						end)
					end

					seen[itemName] = true
				end
			end
		end
	end

	for itemName, frame in pairs(existingFrames) do
		frame:Destroy()
	end
end

updateSellUI()

Events.UpdateSellUI.OnClientEvent:Connect(updateSellUI)