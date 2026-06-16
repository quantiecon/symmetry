local Player = game.Players.LocalPlayer
local UIParent = script.Parent

-- Helper to update luck text label
local function updateLuckText(label, luckValue)
	label.Text = string.format("+%d%% luck increase.", math.round(luckValue * 100))
end

-- Connect MouseEnter/MouseLeave for a UI element
local function setupHoverDisplay(imageLabel)
	local main = imageLabel:FindFirstChild("Main")
	if not main then return end

	imageLabel.MouseEnter:Connect(function()
		main.Visible = true
	end)
	imageLabel.MouseLeave:Connect(function()
		main.Visible = false
	end)
end

-- Connect all existing Luck UI labels with hover behavior and update text
local function connectLuckDisplay(character)
	local Luck = character:WaitForChild("Luck")

	for _, v in pairs(UIParent:GetChildren()) do
		if v:IsA("ImageLabel") and v.Name == "Luck" then
			local label = v.Main and v.Main:FindFirstChild("Luck")
			if label then
				updateLuckText(label, Luck.Value)
				Luck:GetPropertyChangedSignal("Value"):Connect(function()
					updateLuckText(label, Luck.Value)
				end)
			end
		end
	end
end

local function formatHMS(seconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60
	return string.format("Ends in %02d:%02d:%02d", hours, minutes, secs)
end

local function createBoostUI(name, displayText)
	if UIParent:FindFirstChild(name) then return end -- avoid duplicates

	local boostUI = script.Luck:Clone()
	boostUI.Name = name
	boostUI.Parent = UIParent

	local main = boostUI:FindFirstChild("Main")
	local luckLabel = main and main:FindFirstChild("Luck")
	local timerLabel = main and main:FindFirstChild("Timer")

	-- Setup display text
	if luckLabel then
		luckLabel.Text = displayText
	end

	-- Start timer if this is a luck boost
	if (name == "Simple Luck Boost" or name == "Advanced Luck Boost" or name == "Mythical Luck Boost") and timerLabel then
		task.spawn(function()
			local boostFolder
			repeat
				boostFolder = Player:FindFirstChild(name)
				task.wait()
			until boostFolder

			local expiresAt
			repeat
				expiresAt = boostFolder:FindFirstChild("ExpiresAt")
				task.wait()
			until expiresAt and expiresAt.Value > 0


			print(expiresAt.Value - tick())
			-- Start updating timer
			local connection
			connection = game:GetService("RunService").RenderStepped:Connect(function()
				local timeLeft = math.max(0, expiresAt.Value - os.time())

				if timeLeft > 0 then
					timerLabel.Text = formatHMS(timeLeft)
				else
					timerLabel.Text = "Expired"
					if connection then
						connection:Disconnect()
					end
				end
			end)
		end)
	end

	setupHoverDisplay(boostUI)
end


local boostInfo = {
	["Simple Luck Boost"] = "50% luck increase",
	["Advanced Luck Boost"] = "100% luck increase",
	["Mythical Luck Boost"] = "300% luck increase",
}

Player.ChildAdded:Connect(function(child)
	if boostInfo[child.Name] then
		createBoostUI(child.Name, boostInfo[child.Name]) 
	end
end)

-- Remove UI element when boost is removed
Player.ChildRemoved:Connect(function(child)
	local uiElement = UIParent:FindFirstChild(child.Name)
	if uiElement then
		uiElement:Destroy()
	end
end)

-- Setup hover for all current ImageLabels under UIParent
for _, v in pairs(UIParent:GetChildren()) do
	if v:IsA("ImageLabel") then
		setupHoverDisplay(v)
	end
end

-- Initial connect for current character
if Player.Character then
	connectLuckDisplay(Player.Character)
end

-- Connect when character respawns
Player.CharacterAdded:Connect(connectLuckDisplay)