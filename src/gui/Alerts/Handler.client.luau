local Events = game.ReplicatedStorage.Events
local SFX = game.ReplicatedStorage.SFX
local TweenService = game:GetService("TweenService")
local Player = game.Players.LocalPlayer
local ItemInfo = require(game.ReplicatedStorage.Modules.ItemInfo)

local CoinText = script.Parent.Coins
local DiamondText = script.Parent.Diamonds

local RARITY_DATA = {
	Common    = { Color = Color3.new(1, 1, 1),               Order = 3, Lifetime = 2 },
	Rare      = { Color = Color3.fromRGB(114, 189, 255),     Order = 5, Lifetime = 2.5 },
	Epic      = { Color = Color3.fromRGB(186, 129, 255),     Order = 7, Lifetime = 3 },
	Legendary = { Color = Color3.fromRGB(255, 170, 96), Order = 8, Lifetime = 3.5 },
	Mythical  = { Color = Color3.fromRGB(255, 48, 51),       Order = 9, Lifetime = 4 },
	Celestial = { Color = Color3.fromRGB(243, 255, 138),     Order = 10, Lifetime = 5 },
	Secret = { Color = Color3.fromRGB(0, 0, 0),     Order = 11, Lifetime = 10 },
}

-- Helpers
local function formatnumber(number)
	local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
	int = int:reverse():gsub("(%d%d%d)", "%1,")
	return minus .. int:reverse():gsub("^,", "") .. fraction
end

local function playTextTween(alertText)
	alertText.Size = UDim2.new(1, 0, 0.03, 0)
	TweenService:Create(alertText, TweenInfo.new(0.4), {Size = UDim2.new(1, 0, 0.07, 0)}):Play()
	task.delay(0.4, function()
		TweenService:Create(alertText, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0.05, 0)}):Play()
	end)
end

local function fadeOutText(alertText, delayTime)
	task.delay(delayTime or 1, function()
		TweenService:Create(alertText, TweenInfo.new(1), {TextTransparency = 1}):Play()
		if alertText:FindFirstChild("UIStroke") then
			TweenService:Create(alertText.UIStroke, TweenInfo.new(1), {Transparency = 1}):Play()
		end
	end)
end

local function createAlert(text, color, order, lifetime)
	local alert = script.AlertText:Clone()
	alert.Text = text
	alert.TextColor3 = color or Color3.new(1, 1, 1)
	alert.LayoutOrder = order or 0
	alert.Parent = script.Parent.Alerts

	lifetime = lifetime or 2
	game.Debris:AddItem(alert, lifetime)

	playTextTween(alert)
	fadeOutText(alert, lifetime - 1)
end
-- Initial coin/diamond update
local initialData = Events.Get:InvokeServer({"Coins", "Diamonds"})
CoinText.Text = formatnumber(initialData.Coins) .. "$"
DiamondText.Text = formatnumber(initialData.Diamonds)

-- Currency listeners
Events.GemsChanged.OnClientEvent:Connect(function()
	local data = Events.Get:InvokeServer({"Diamonds"})
	DiamondText.Text = formatnumber(data.Diamonds)
end)

Events.CoinChanged.OnClientEvent:Connect(function()
	local data = Events.Get:InvokeServer({"Coins"})
	CoinText.Text = formatnumber(data.Coins) .. "$"
end)

-- New item alert
Events.NewItems.OnClientEvent:Connect(function(newItems)
	task.wait(1)
	for name, amount in newItems do
		local info = ItemInfo[name]
		local text = "+" .. amount .. " " .. name

		if info and info.RNG then
			text = text .. " (" .. info.RNG .. ")"
		end

		local rarity = info and RARITY_DATA[info.Rarity]
		createAlert(text, rarity and rarity.Color, rarity and rarity.Order, rarity and rarity.Lifetime)
		task.wait(0.1)
	end
end)

-- New drill alert
Events.NewDrill.OnClientEvent:Connect(function(name, amount)
	local info = ItemInfo[name]
	local rarity = info and RARITY_DATA[info.Rarity]
	local text = "+" .. amount .. " " .. name
	createAlert(text, rarity and rarity.Color, rarity and rarity.Order, rarity and rarity.Lifetime)
end)

-- Profit alert
Events.Profit.OnClientEvent:Connect(function(profit)
	local text, color
	if profit > 0 then
		text = "+" .. profit .. " Coins"
		color = Color3.fromRGB(98, 255, 137)
	else
		text = profit .. " Coins"
		color = Color3.fromRGB(255, 58, 61)
	end

	createAlert(text, color)

	local sound = SFX.Profit:Clone()
	sound.Parent = Player.Character
	sound:Play()
	game.Debris:AddItem(sound, 2)

	if profit > 0 then
		local fx = game.ReplicatedStorage.Visuals.Money:Clone()
		fx.CFrame = Player.Character:WaitForChild("HumanoidRootPart").CFrame
		fx.Parent = workspace
		game.Debris:AddItem(fx, 2)

		for _, v in fx:GetDescendants() do
			if v:IsA("ParticleEmitter") then
				v:Emit(v:GetAttribute("EmitCount"))
			end
		end
	end
end)

-- Alert message
Events.Alert.OnClientEvent:Connect(function(message)
	local alert = script.AlertText:Clone()
	alert.Text = message
	alert.TextColor3 = Color3.new(1, 1, 1)
	alert.Parent = script.Parent.Alerts
	game.Debris:AddItem(alert, 4)

	playTextTween(alert)
	fadeOutText(alert, 2)
end)

-- Alert message
Events.MainAlert.OnClientEvent:Connect(function(message,Color)
	local alert = script.MainAlert:Clone()
	alert.Text = message
	alert.TextColor3 = Color
	alert.Parent = script.Parent.MainAlerts
	game.Debris:AddItem(alert, 4)

	playTextTween(alert)
	fadeOutText(alert, 2)
	
	script.Parent.Alert:Play()
end)