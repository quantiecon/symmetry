local Events = game.ReplicatedStorage.Events
local ItemInfo = require(game.ReplicatedStorage.Modules.ItemInfo)
local ViewportModel = require(game.ReplicatedStorage.Modules.ViewportModel)

local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local GUI = script.Parent

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

applyHoverEffect(script.Parent.Buy1)
applyHoverEffect(script.Parent.Buy3)
applyHoverEffect(script.Parent.Buy10)

script.Parent.Buy1.MouseButton1Click:Connect(function()
	script.Parent.Buy1.Click:Play()
	game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3357807556)
end)
script.Parent.Buy3.MouseButton1Click:Connect(function()
	script.Parent.Buy3.Click:Play()
	game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3357807700)
end)
script.Parent.Buy10.MouseButton1Click:Connect(function()
	script.Parent.Buy10.Click:Play()
	game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3357807911)
end)


ProximityPromptService.PromptShown:Connect(function(promptInstance)
	if promptInstance.Name == "VoidChest" then
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
	if promptInstance.Name == "VoidChest" then
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

for _,k in pairs(script.Parent:GetChildren()) do
	if k:FindFirstChildWhichIsA("ViewportFrame") and game.ReplicatedStorage.System.Parts:FindFirstChild(k.Name) then
		local viewport = k:FindFirstChild("Viewport")
		local model = game.ReplicatedStorage.System.Parts:FindFirstChild(k.Name):Clone()

		local camera = Instance.new("Camera")
		camera.FieldOfView = 70
		camera.Parent = viewport

		model.Parent = viewport
		viewport.CurrentCamera = camera

		local vpfModel = ViewportModel.new(viewport, camera)
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
	elseif k:FindFirstChildWhichIsA("ViewportFrame") and game.ReplicatedStorage.Workers:FindFirstChild(k.Name) then
		local viewport = k:FindFirstChild("Viewport")
		local model = game.ReplicatedStorage.Workers:FindFirstChild(k.Name):Clone()

		local camera = Instance.new("Camera")
		camera.FieldOfView = 70
		camera.Parent = viewport

		model.Parent = viewport
		viewport.CurrentCamera = camera

		local vpfModel = ViewportModel.new(viewport, camera)
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

local success, policyInfo = pcall(function()
	return game:GetService("PolicyService"):GetPolicyInfoForPlayerAsync(game.Players.LocalPlayer)
end)

if success and policyInfo and policyInfo.ArePaidRandomItemsRestricted == true then
	script.Enabled = false
end