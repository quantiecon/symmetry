local Events = game.ReplicatedStorage.Events

local TweenService = game:GetService("TweenService")

local Spin = script.Parent.Spin

script.Parent.TicketAmount.Text = Events.Get:InvokeServer({"DailySpinTickets"}).DailySpinTickets

debounce = false

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

applyClickTween(script.Parent.Spin)

Spin.MouseButton1Down:Connect(function()
	if debounce == true then return end
	debounce = true
	
	task.delay(9.4,function()
		debounce = false
	end)
	local Spin = Events.WheelSpin:InvokeServer()
	if Spin then
		
		script.Parent.SpinSFX:Play()
		
		local targetRotationAngle = 45
		if Spin == "25000 Coins" then
			targetRotationAngle = 330
		elseif Spin == "30 Gems" then
			targetRotationAngle = 225
		elseif Spin == "100000 Coins" then
			targetRotationAngle = 180
		elseif Spin == "Worker Contract" then
			targetRotationAngle = 100
		elseif Spin == "Legendary Drill" then
			targetRotationAngle = 45
		end
		local fullSpins = 16 
		local endRotation = (360 * fullSpins) + targetRotationAngle
		
		print(Spin)

		local tween = TweenService:Create(script.Parent.DailyWheel.Sections, TweenInfo.new(9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Rotation = endRotation
		})

		script.Parent.DailyWheel.Sections.Rotation = 0 -- reset this or else over time the angle won't be accurate.
		tween:Play() 
		
		tween.Completed:Wait()
		
		script.Parent.Reward:Play()
	end
end)

script.Parent.BuySpin.MouseButton1Down:Connect(function()
	game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3320663222)
end)

Events.UpdateSpinAmount.OnClientEvent:Connect(function()
	script.Parent.TicketAmount.Text = Events.Get:InvokeServer({"DailySpinTickets"}).DailySpinTickets
end)

local success, policyInfo = pcall(function()
	return game:GetService("PolicyService"):GetPolicyInfoForPlayerAsync(game.Players.LocalPlayer)
end)

if success and policyInfo and policyInfo.IsPaidRandomItemsAllowed == false then
	script.Parent.BuySpin.Visible = false
end