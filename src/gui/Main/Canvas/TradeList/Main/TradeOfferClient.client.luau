local Events = game.ReplicatedStorage.Events

local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local LocalPlayer = game.Players.LocalPlayer

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

local function CreateListing(Player)
	if Player.Name == game.Players.LocalPlayer.Name then return end
	local Placeholder = script.Placeholder:Clone()
	Placeholder.Parent = script.Parent.Container
	Placeholder.Name = Player.Name
	Placeholder.PlayerName.Text = Player.Name

	applyHoverEffect(Placeholder.Trade)

	Placeholder.Trade.MouseButton1Click:Connect(function()
		Events.RequestTrade:FireServer(Player)
	end)
end

for i,v in pairs(game.Players:GetChildren()) do
	if v:IsA("Player") then
		CreateListing(v)
		
		v.ChildRemoved:Connect(function(Child)
			if Child.Name == "TradeOff" then
				if not script.Parent.Container:FindFirstChild(v.Name) then
					CreateListing(v)
				end
			end
		end)

		v.ChildAdded:Connect(function(Child)
			if Child.Name == "TradeOff" then
				if script.Parent.Container:FindFirstChild(v.Name) then
					script.Parent.Container[v.Name]:Destroy()
				end
			end
		end)
	end
end

script.Parent.TradeOn.MouseButton1Click:Connect(function()
	if script.Parent.TradeOn.Main.Home.Text == "Trade Requests: On" then
		script.Parent.TradeOn.Main.Home.Text = "Trade Requests: Off"
		Events.TradeRequestsChange:FireServer("Off")
	else
		script.Parent.TradeOn.Main.Home.Text = "Trade Requests: On"
		Events.TradeRequestsChange:FireServer("On")
	end
end)

game.Players.PlayerAdded:Connect(function(player)
	if not script.Parent.Container:FindFirstChild(player.Name) then
		CreateListing(player)
	end
	
	player.ChildRemoved:Connect(function(Child)
		if Child.Name == "TradeOff" then
			if not script.Parent.Container:FindFirstChild(player.Name) then
				CreateListing(player)
			end
		end
	end)

	player.ChildAdded:Connect(function(Child)
		if Child.Name == "TradeOff" then
			if script.Parent.Container:FindFirstChild(player.Name) then
				script.Parent.Container[player.Name]:Destroy()
			end
		end
	end)
end)

game.Players.PlayerRemoving:Connect(function(player)
	if script.Parent.Container:FindFirstChild(player.Name) then
		script.Parent.Container[player.Name]:Destroy()
	end
end)