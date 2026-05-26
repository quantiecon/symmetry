local Events = game.ReplicatedStorage:WaitForChild("Events")

-- Store connected buttons to prevent duplicate connections
local connectedButtons = {}

Events.UpdateDailyRewardUI.OnClientEvent:Connect(function(data)
	local claimedUntil = data.Streak or 0
	local canClaim = data.CanClaim

	print("Streak:", claimedUntil, "CanClaim:", canClaim)

	for _, frame in pairs(script.Parent:GetChildren()) do
		if frame:IsA("Frame") then
			local number = string.gsub(frame.Name, "%D", "")
			local dayNumber = tonumber(number)
			local button = frame:FindFirstChild("Buttons")

			if button and button:FindFirstChild("Claimed") then
				local claimedText = button.Claimed
				local gradient = button:FindFirstChild("UIGradient")

				if dayNumber <= claimedUntil then
					button.Visible = true

					if dayNumber < claimedUntil then
						claimedText.Text = "Claimed"
						if gradient then
							gradient.Color = ColorSequence.new(Color3.fromRGB(255, 41, 45), Color3.fromRGB(255, 84, 93))
						end
					elseif dayNumber == claimedUntil then
						claimedText.Text = canClaim and "Claim" or "Claimed"
						if gradient then
							if canClaim then
								gradient.Color = ColorSequence.new(Color3.fromRGB(119, 255, 117), Color3.fromRGB(161, 255, 180))
							else
								gradient.Color = ColorSequence.new(Color3.fromRGB(255, 41, 45), Color3.fromRGB(255, 84, 93))
							end
						end
					end

					-- Prevent reconnecting multiple times
					if not connectedButtons[button] then
						connectedButtons[button] = true
						claimedText.MouseButton1Down:Connect(function()
							if claimedText.Text == "Claim" then
								Events.ClaimDailyReward:FireServer()
								script.Parent.Reward:Play()
							end
						end)
					end
				else
					button.Visible = false
				end
			end
		end
	end
end)