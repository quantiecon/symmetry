-- LocalScript: roll button UI and result display
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AuraData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AuraData"))

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RollGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Roll button
local rollButton = Instance.new("TextButton")
rollButton.Size = UDim2.new(0, 200, 0, 60)
rollButton.Position = UDim2.new(0.5, -100, 1, -90)
rollButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
rollButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rollButton.Text = "Roll"
rollButton.Font = Enum.Font.GothamBold
rollButton.TextSize = 24
rollButton.BorderSizePixel = 0
rollButton.Parent = screenGui

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 10)
buttonCorner.Parent = rollButton

-- Result label (shows aura name + rarity after a roll)
local resultLabel = Instance.new("TextLabel")
resultLabel.Size = UDim2.new(0, 400, 0, 60)
resultLabel.Position = UDim2.new(0.5, -200, 0.5, -30)
resultLabel.BackgroundTransparency = 1
resultLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
resultLabel.Text = ""
resultLabel.Font = Enum.Font.GothamBold
resultLabel.TextSize = 32
resultLabel.TextStrokeTransparency = 0.4
resultLabel.Visible = false
resultLabel.Parent = screenGui

-- Button click → fire server
local onCooldown = false
rollButton.MouseButton1Click:Connect(function()
    if onCooldown then return end
    onCooldown = true
    rollButton.Text = "Rolling..."
    rollButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    Remotes.RollAura:FireServer()
    task.delay(1, function()
        onCooldown = false
        rollButton.Text = "Roll"
        rollButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end)
end)

-- Show result when server responds
local hideThread
Remotes.AuraResult.OnClientEvent:Connect(function(aura)
    local rarityColor = AuraData.RarityColors[aura.rarity] or Color3.fromRGB(255, 255, 255)
    resultLabel.Text = aura.name .. "  •  " .. aura.rarity
    resultLabel.TextColor3 = rarityColor
    resultLabel.Visible = true

    if hideThread then task.cancel(hideThread) end
    hideThread = task.delay(3, function()
        resultLabel.Visible = false
    end)
end)
