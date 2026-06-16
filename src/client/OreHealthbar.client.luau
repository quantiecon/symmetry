-- Optimized Drill Collect UI Script

local ProximityPromptService = game:GetService("ProximityPromptService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer


local CollectUI = Player:WaitForChild("PlayerGui"):WaitForChild("OreHealth")

local Drill
local isOpen = false
local conn, uiConn

-- UI Update Connection
local function connectDrillUI(Ore)
	if uiConn then uiConn:Disconnect() end

	local function updateBar()
		local collected, max = Ore.Health.Value, Ore.MaxHealth.Value
		TweenService:Create(CollectUI.MainFrame.BG.Bar, TweenInfo.new(0.2), {
			Size = UDim2.new(collected / max, 0, 1, 0)
		}):Play()

		CollectUI.MainFrame.BG.Amount.Text = collected .. "/" .. max
	end

	updateBar()
	uiConn = Ore.Health:GetPropertyChangedSignal("Value"):Connect(updateBar)
end

-- Prompt shown
ProximityPromptService.PromptShown:Connect(function(promptInstance)
	if promptInstance.Name ~= "Ore" then return end

	isOpen = true
	Drill = promptInstance.Parent
	local Data = Drill
	if not Data then return end

	CollectUI.Enabled = true
	CollectUI.Adornee = Drill.PrimaryPart
	TweenService:Create(CollectUI, TweenInfo.new(0.3), { StudsOffset = Vector3.new(0, 0, 0) }):Play()

	connectDrillUI(Data)
end)

-- Prompt hidden
ProximityPromptService.PromptHidden:Connect(function(promptInstance)
	if promptInstance.Name ~= "Ore" then return end
	isOpen = false
	Drill = nil
	CollectUI.Enabled = false
	CollectUI.Adornee = nil

	if uiConn then uiConn:Disconnect() end
end)
