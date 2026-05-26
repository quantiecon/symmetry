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

for i,v in ItemInfo do
	if ItemInfo[i].Pack and ItemInfo[i].DiamondPrice then
		if not ItemInfo[i].NotForSale then
			local SystemDrill = game.ReplicatedStorage.ToolDisplay:FindFirstChild(i)

			local Placeholder = script.Placeholder:Clone()
			Placeholder.Parent = script.Parent.List
			Placeholder.Name = i
			Placeholder.ToolName.Text = i
			Placeholder.Description.Text = "Description: "..ItemInfo[i].Description
			Placeholder.Price.Main.Home.Text = formatnumber(ItemInfo[i].DiamondPrice).."💎"

			if ItemInfo[i].Rarity == "Common" then
				Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(0.607843, 1, 0.764706),Color3.new(0.603922, 1, 0.388235))
				Placeholder.LayoutOrder = 1
			elseif ItemInfo[i].Rarity == "Rare" then
				Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(0.576471, 0.921569, 1),Color3.new(0.333333, 0.635294, 1))
				Placeholder.LayoutOrder = 2
			elseif ItemInfo[i].Rarity == "Epic" then
				Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(0.878431, 0.596078, 1),Color3.new(0.678431, 0.309804, 1))
				Placeholder.LayoutOrder = 3
			elseif ItemInfo[i].Rarity == "Legendary" then
				Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(1, 0.862745, 0.513725),Color3.new(1, 0.576471, 0.27451))
				Placeholder.LayoutOrder = 4
			elseif ItemInfo[i].Rarity == "Mythical" then
				Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(1, 0.494118, 0.501961),Color3.new(1, 0.203922, 0.215686))
				Placeholder.LayoutOrder = 5
			end

			applyHoverEffect(Placeholder.Price)

			Placeholder.Price.MouseButton1Click:Connect(function()
				Placeholder.Price.Click:Play()
				Events.BuyWithDiamonds:FireServer(i)
			end)


			if game.ReplicatedStorage.ToolDisplay:FindFirstChild(i) then
				local model = game.ReplicatedStorage.ToolDisplay:FindFirstChild(i):Clone()

				local camera = Instance.new("Camera")
				camera.FieldOfView = 70
				camera.Parent = Placeholder.DrillView

				model.Parent = Placeholder.DrillView
				Placeholder.DrillView.CurrentCamera = camera

				local vpfModel = ViewportModel.new(Placeholder.DrillView, camera)
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
		end
	end
end

ProximityPromptService.PromptShown:Connect(function(promptInstance)
	if promptInstance.Name == "ToolShop" then
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
	if promptInstance.Name == "ToolShop" then
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

