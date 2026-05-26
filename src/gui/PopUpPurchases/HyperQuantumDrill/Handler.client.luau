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

applyHoverEffect(script.Parent.BuyRobux)
applyHoverEffect(script.Parent.Claim)

script.Parent.BuyRobux.MouseButton1Click:Connect(function()
	script.Parent.BuyRobux.Click:Play()
	game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3339897363)
end)

script.Parent.Claim.MouseButton1Click:Connect(function()
	script.Parent.Claim.Click:Play()
	Events.ClaimReward:FireServer("Hyperquantum")
end)

ProximityPromptService.PromptShown:Connect(function(promptInstance)
	if promptInstance.Name == "HyperquantumDrill" then
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
	if promptInstance.Name == "HyperquantumDrill" then
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

local Requirements = script.Parent.Requirements

while wait(5) do
	if not string.find(Events.Get:InvokeServer({ "ClaimedRewards" }).ClaimedRewards,"Hyperquantum Drill") then
		
		local SecondsSpent = Events.Get:InvokeServer({ "SecondsSpentIngame" }).SecondsSpentIngame
		local MinutesSpent = math.floor(SecondsSpent / 60)
		
		if MinutesSpent < 180 then
			Requirements.BG.Bar.Size = UDim2.new(MinutesSpent / 30, 0, 1, 0)
			Requirements.BG.Amount.Text = MinutesSpent.."/180"
		else
			if script.Parent.Claim:FindFirstChild("Locked") then
				script.Parent.Claim:FindFirstChild("Locked"):Destroy()
			end
			Requirements.BG.Bar.Size = UDim2.new(30 / 30, 0, 1, 0)
			Requirements.BG.Amount.Text = "180/180"
		end
			
	else
		if script.Parent.Claim:FindFirstChild("Locked") then
			script.Parent.Claim:FindFirstChild("Locked"):Destroy()
		end
		
		script.Parent.Claim.Main.Home.Text = "Claimed"
		Requirements.BG.Bar.Size = UDim2.new(30 / 30, 0, 1, 0)
		Requirements.BG.Amount.Text = "180/180"
	end
end