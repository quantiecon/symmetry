local Player = game.Players.LocalPlayer
local Events = game.ReplicatedStorage.Events

local PlaytimeRewardTimer = Player:WaitForChild("PlaytimeRewardTimer")
local Rewards = script.Parent.Rewards

local TweenService = game:GetService("TweenService")

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


for _, v in pairs(Rewards:GetChildren()) do
	if v:IsA("ImageButton") then
		applyHoverEffect(v)
		
		v.MouseButton1Down:Connect(function()
			script.Parent.Click:Play()
			Events.CollectPlaytime:FireServer(v.Name)
			
			local PlaytimeRewardTimer = Player:FindFirstChild("PlaytimeRewardTimer")
			local GiftTime = tonumber(v.Name) * 300

			if PlaytimeRewardTimer.Value >= GiftTime and not Player:FindFirstChild("Claimed"..v.Name) then
				script.Parent.Reward:Play()
			end
		end)
	end
end

while true do
	wait(0.5)

	for _, v in pairs(Rewards:GetChildren()) do
		if v:IsA("ImageButton") then
			local titleLabel = v:FindFirstChild("Title")
			if not titleLabel then continue end

			if Player:FindFirstChild("Claimed" .. v.Name) then
				titleLabel.Text = '<stroke thickness="2">Claimed!</stroke>'
				titleLabel.TextColor3 = Color3.new(0.533333, 0.556863, 0.564706)
			else
				local timeRequired = tonumber(v.Name) * 300
				local timeLeft = timeRequired - PlaytimeRewardTimer.Value

				if timeLeft <= 0 then
					titleLabel.Text = '<stroke thickness="2">Claim!</stroke>'
					titleLabel.TextColor3 = Color3.new(0.498039, 1, 0.313725)
				else
					local minutes = math.floor(timeLeft / 60)
					local seconds = timeLeft % 60
					titleLabel.Text = '<stroke thickness="2">'.. string.format("%d:%02d", minutes, seconds) .. '</stroke>'
					titleLabel.TextColor3 = Color3.new(1, 1, 1)
				end
			end
		end
	end
end