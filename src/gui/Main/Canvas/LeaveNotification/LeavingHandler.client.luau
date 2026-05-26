local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local textLabel = script.Parent

local PlaytimeRewardTimer = Player:WaitForChild("PlaytimeRewardTimer")

textLabel.Visible = false

local Conn
local UpdateLoop

local function updateText()
	local timeLeft = 300 - (PlaytimeRewardTimer.Value % 300)

	if timeLeft == 300 then
		textLabel.Text = 'Are you sure you want to <font color="rgb(255,0,0)">leave</font>? You can claim your <font color="rgb(255,255,0)">lucky box!</font>'
	else
		local minutes = math.floor(timeLeft / 60)
		local seconds = timeLeft % 60
		textLabel.Text = string.format(
			'Are you sure you want to <font color="rgb(255,0,0)">leave</font>? You have <font color="rgb(255,255,0)">%d:%02d minutes</font> until you can claim your <font color="rgb(255,255,0)">lucky box</font>!',
			minutes, seconds
		)
	end
end

GuiService.MenuOpened:Connect(function()
	textLabel.Visible = true

	updateText()

	-- Start live updating
	UpdateLoop = game:GetService("RunService").RenderStepped:Connect(updateText)
end)

GuiService.MenuClosed:Connect(function()
	textLabel.Visible = false

	if UpdateLoop then
		UpdateLoop:Disconnect()
		UpdateLoop = nil
	end
end)