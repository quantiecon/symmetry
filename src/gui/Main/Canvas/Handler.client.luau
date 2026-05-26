-- Optimized Side Buttons Script
local Events = game.ReplicatedStorage.Events
local Player = game.Players.LocalPlayer

local TweenService = game:GetService("TweenService")
local SocialService = game:GetService("SocialService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local SideButtons = script.Parent.SideButtons
local Teleport = script.Parent.Teleport
local function setupTween(button, originalSizeAttr)
	local function tweenOpen(frame)
		frame.Size = frame:GetAttribute(originalSizeAttr)
		frame.Position = UDim2.new(0.5, 0, 0.6, 0)
		frame.Visible = true
		TweenService:Create(frame, TweenInfo.new(0.2), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
	end

	local function tweenClose(frame)
		local originalSize = frame:GetAttribute(originalSizeAttr)
		if not originalSize then return end
		TweenService:Create(frame, TweenInfo.new(0.05), {Size = originalSize - UDim2.new(0.2, 0, 0.2, 0)}):Play()
		task.delay(0.05, function()
			frame.Size = originalSize
			frame.Visible = false
		end)
	end

	return tweenOpen, tweenClose
end

local function applyClickTween(button)
	local origPos = button.Position
	local down = TweenService:Create(button, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = origPos + UDim2.new(0, 0, 0.02, 0)
	})
	local up = TweenService:Create(button, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = origPos
	})
	button.MouseButton1Click:Connect(function()
		down:Play()
		down.Completed:Wait()
		up:Play()
	end)
	if button:FindFirstChild("Click") then button.Click:Play() end
end

local function applyHover(button, scale, time)
	scale = scale or 1.1
	time = time or 0.2
	if not button:IsA("GuiButton") then return end

	local origSize = button.Size
	local enlarged = UDim2.new(origSize.X.Scale * scale, origSize.X.Offset * scale, origSize.Y.Scale * scale, origSize.Y.Offset * scale)
	local enlarge = TweenService:Create(button, TweenInfo.new(time, Enum.EasingStyle.Quad), {Size = enlarged})
	local shrink = TweenService:Create(button, TweenInfo.new(time, Enum.EasingStyle.Quad), {Size = origSize})

	button.MouseEnter:Connect(function() enlarge:Play() end)
	button.MouseLeave:Connect(function() shrink:Play() end)
end

for _, button in ipairs({SideButtons.ShopButton, SideButtons.WorkerInventoryButton, SideButtons.DailyRewardsButton, SideButtons.DailySpinButton, SideButtons.TradeButton, SideButtons.SettingsButton, SideButtons.Invite, SideButtons.PlaytimeReward, Teleport.Home, Teleport.Shop}) do
	applyHover(button)
end

-- Panels with open/close logic
local Panels = {
	Settings = SideButtons.SettingsButton,
	GamepassShop = SideButtons.ShopButton,
	WorkerInventory = SideButtons.WorkerInventoryButton,
	DailyRewards = SideButtons.DailyRewardsButton,
	DailyWheel = SideButtons.DailySpinButton,
	TradeList = SideButtons.TradeButton,
	PlaytimeRewards = SideButtons.PlaytimeReward
}

for panelName, button in pairs(Panels) do
	local panel = script.Parent[panelName]
	panel:SetAttribute("OriginalSize", panel.Size)
	local openTween, closeTween = setupTween(button, "OriginalSize")

	button.MouseButton1Click:Connect(function()
		for otherName in pairs(Panels) do
			script.Parent[otherName].Visible = false
		end
		script.Parent.Settings.Visible = false
		openTween(panel)
		applyClickTween(button)
	end)

	panel.Close.ImageButton.MouseButton1Click:Connect(function()
		panel.Close.Click:Play()
		closeTween(panel)
	end)
	
	if panel.Name == "DailyRewards" and Events.Get:InvokeServer({"CanClaimDaily"}).CanClaimDaily == true then
		repeat wait(1)
			openTween(panel)
		until panel.Visible == true
	end
	
	if panel.Name == "GamepassShop" then
		ProximityPromptService.PromptShown:Connect(function(promptInstance)
			if promptInstance.Name == "ExclusiveShop" then
				for otherName in pairs(Panels) do
					script.Parent[otherName].Visible = false
				end
				script.Parent.Settings.Visible = false
				openTween(panel)
			end
		end)

		ProximityPromptService.PromptHidden:Connect(function(promptInstance)
			if promptInstance.Name == "ExclusiveShop" then
				panel.Close.Click:Play()
				closeTween(panel)
			end
		end)
	end
end


SideButtons.PlaytimeReward.MouseButton1Click:Connect(function()
	if Player:FindFirstChild("GiftReady") then
		Events.CollectPlaytime:FireServer()
		SideButtons.PlaytimeReward.Timer.Text = "CLAIMED"
	end
end)

Teleport.Home.MouseButton1Click:Connect(function()
	applyClickTween(Teleport.Home)
	Events.Teleport:FireServer("Home")
end)

Teleport.Shop.MouseButton1Click:Connect(function()
	applyClickTween(Teleport.Shop)
	Events.Teleport:FireServer("Shop")
end)

SideButtons.Invite.MouseButton1Click:Connect(function()
	SideButtons.Invite.Click:Play()
	local success, err = pcall(function()
		local ExperienceInviteOptions = Instance.new("ExperienceInviteOptions")
		ExperienceInviteOptions.PromptMessage  = "Invite a friend for a free Rare Drill!"
		SocialService:PromptGameInvite(Player, ExperienceInviteOptions)
	end)
	if not success then warn("Invite failed:", err) end
end)

local Weather = game.Workspace:WaitForChild("Weather")
script.Parent.WeatherIndication.Text = Weather.Value
Weather.Changed:Connect(function()
	script.Parent.WeatherIndication.Text = Weather.Value
end)

