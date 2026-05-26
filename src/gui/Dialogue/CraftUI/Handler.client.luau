 local Events = game.ReplicatedStorage.Events
local ItemInfo = require(game.ReplicatedStorage.Modules.ItemInfo)
local CraftInfo = require(game.ReplicatedStorage.Modules.CraftingRecipes)
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

local Collection = Events.Get:InvokeServer({"Collection"}).Collection

-- Parse player's collection once
local collectionTable = {}
for name, amount in string.gmatch(Collection or ",", "([^:,]+):(%d+),") do
	collectionTable[name] = tonumber(amount)
end

for i, v in pairs(CraftInfo) do
	if not v.Event and not v.VoidEvent and not v.NatureEvent then
		local Placeholder = script.Placeholder:Clone()
		Placeholder.Parent = ListFrame
		Placeholder.Main.ItemName.Text = i
		Placeholder.Main.ItemDescription.Text = v.Description
		applyHoverEffect(Placeholder.Main.Craft)

		if ItemInfo[i].Rarity == "Common" then
			Placeholder.Main.UIGradient.Color = ColorSequence.new(Color3.new(0.607843, 1, 0.764706),Color3.new(0.603922, 1, 0.388235))
			Placeholder.LayoutOrder = 1
		elseif ItemInfo[i].Rarity == "Rare" then
			Placeholder.Main.UIGradient.Color = ColorSequence.new(Color3.new(0.576471, 0.921569, 1),Color3.new(0.333333, 0.635294, 1))
			Placeholder.LayoutOrder = 2
		elseif ItemInfo[i].Rarity == "Epic" then
			Placeholder.Main.UIGradient.Color = ColorSequence.new(Color3.new(0.878431, 0.596078, 1),Color3.new(0.678431, 0.309804, 1))
			Placeholder.LayoutOrder = 3
		elseif ItemInfo[i].Rarity == "Legendary" then
			Placeholder.Main.UIGradient.Color = ColorSequence.new(Color3.new(1, 0.862745, 0.513725),Color3.new(1, 0.576471, 0.27451))
			Placeholder.LayoutOrder = 4
		elseif ItemInfo[i].Rarity == "Mythical" then
			Placeholder.Main.UIGradient.Color = ColorSequence.new(Color3.new(1, 0.494118, 0.501961),Color3.new(1, 0.203922, 0.215686))
			Placeholder.LayoutOrder = 5
		elseif ItemInfo[i].Rarity == "Celestial" then
			Placeholder.Main.UIGradient.Color = ColorSequence.new(Color3.new(1, 1, 0.635294),Color3.new(1, 0.8, 0.294118))
			Placeholder.LayoutOrder = 6
		end

		if game.ReplicatedStorage.System.Parts:FindFirstChild(i) then
			local model = game.ReplicatedStorage.System.Parts:FindFirstChild(i):Clone()

			local camera = Instance.new("Camera")
			camera.FieldOfView = 70
			camera.Parent = Placeholder.Main.DrillView

			model.Parent = Placeholder.Main.DrillView
			Placeholder.Main.DrillView.CurrentCamera = camera

			local vpfModel = ViewportModel.new(Placeholder.Main.DrillView, camera)
			local cf, size = model:GetBoundingBox()

			vpfModel:SetModel(model)

			local theta = 0
			local orientation = CFrame.new()
			local distance = vpfModel:GetFitDistance(cf.Position)

			task.spawn(function()
				game:GetService("RunService").RenderStepped:Connect(function(dt)
					theta = theta + math.rad(20 * dt)
					orientation = CFrame.fromEulerAnglesYXZ(math.rad(-20), theta, 0)
					camera.CFrame = CFrame.new(cf.Position) * orientation * CFrame.new(0, 0, distance)
				end)
			end)
		elseif game.ReplicatedStorage.ToolDisplay:FindFirstChild(i) then
			local model = game.ReplicatedStorage.ToolDisplay:FindFirstChild(i):Clone()

			local camera = Instance.new("Camera")
			camera.FieldOfView = 70
			camera.Parent = Placeholder.Main.DrillView

			model.Parent = Placeholder.Main.DrillView
			Placeholder.Main.DrillView.CurrentCamera = camera

			local vpfModel = ViewportModel.new(Placeholder.Main.DrillView, camera)
			local cf, size = model:GetBoundingBox()

			vpfModel:SetModel(model)

			local theta = 0
			local orientation = CFrame.new()
			local distance = vpfModel:GetFitDistance(cf.Position)

			task.spawn(function()
				game:GetService("RunService").RenderStepped:Connect(function(dt)
					theta = theta + math.rad(20 * dt)
					orientation = CFrame.fromEulerAnglesYXZ(math.rad(-20), theta, 0)
					camera.CFrame = CFrame.new(cf.Position) * orientation * CFrame.new(0, 0, distance)
				end)
			end)
		end
		
		for k = 1, v.IngredientCount do
			local IngredientAndAmount = string.split(v["Ingredient"..k], ":")
			local ingredientName = IngredientAndAmount[1]
			local requiredAmount = tonumber(IngredientAndAmount[2])

			local IngredientText = Placeholder.Ingredients:FindFirstChild("Ingredient"..k)
			IngredientText.Visible = true
			IngredientText.Text = requiredAmount .. "x " .. ingredientName

			local ownedAmount = collectionTable[ingredientName] or 0
			if ownedAmount < requiredAmount then
				IngredientText.TextColor3 = Color3.fromRGB(255, 60, 60) -- red
			else
				IngredientText.TextColor3 = Color3.fromRGB(255, 255, 255) -- white (or your default color)
			end
		end
		
		Placeholder.Main.Craft.MouseButton1Click:Connect(function()
			Placeholder.Main.Craft.Click:Play()
			Events.Craft:FireServer(i)
		end)
	end
end


ProximityPromptService.PromptShown:Connect(function(promptInstance)
	if promptInstance.Name == "Crafting" then
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
	if promptInstance.Name == "Crafting" then
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

local function updateIngredientColors()
	local Collection = Events.Get:InvokeServer({ "Collection" }).Collection

	-- Rebuild collection table
	local collectionTable = {}
	for name, amount in string.gmatch(Collection or ",", "([^:,]+):(%d+),") do
		collectionTable[name] = tonumber(amount)
	end

	for _, placeholder in pairs(ListFrame:GetChildren()) do
		if placeholder:IsA("Frame") and placeholder:FindFirstChild("Ingredients") then
			for i = 1, 4 do -- Adjust max ingredient count if needed
				local ingredientLabel = placeholder.Ingredients:FindFirstChild("Ingredient" .. i)
				if ingredientLabel and ingredientLabel.Visible then
					local text = ingredientLabel.Text
					local requiredAmount, name = string.match(text, "(%d+)x%s*(.+)")
					requiredAmount = tonumber(requiredAmount)

					local ownedAmount = collectionTable[name] or 0
					if ownedAmount < requiredAmount then
						ingredientLabel.TextColor3 = Color3.fromRGB(255, 60, 60) -- red
					else
						ingredientLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- white/default
					end
				end
			end
		end
	end
end

Events.UpdateSellUI.OnClientEvent:Connect(function()
	updateIngredientColors()
end)