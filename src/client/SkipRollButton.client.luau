-- Shows a "Skip" button while the wheel-spin animation is playing.
-- Pressing it fires SkipWheelRoll so the server awards the reward immediately,
-- and the client fast-forwards the roll animation to finish in 0.25 s.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Events        = ReplicatedStorage:WaitForChild("Events")
local WheelSpin     = Events:WaitForChild("WheelSpin")
local SkipWheelRoll = Events:WaitForChild("SkipWheelRoll")
local SpinComplete  = Events:WaitForChild("SpinComplete")   -- client fires this to fast-forward

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Build a simple skip button
local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "SkipRollGui"
screenGui.ResetOnSpawn    = false
screenGui.DisplayOrder    = 99
screenGui.IgnoreGuiInset  = true
screenGui.Parent          = playerGui

local btn = Instance.new("TextButton")
btn.Name              = "SkipBtn"
btn.Size              = UDim2.new(0, 160, 0, 50)
btn.AnchorPoint       = Vector2.new(0.5, 1)
btn.Position          = UDim2.new(0.5, 0, 1, -100)
btn.BackgroundColor3  = Color3.fromRGB(30, 30, 30)
btn.BackgroundTransparency = 0.2
btn.BorderSizePixel   = 0
btn.Text              = "Skip  ▶▶"
btn.TextColor3        = Color3.new(1, 1, 1)
btn.TextSize          = 20
btn.Font              = Enum.Font.GothamBold
btn.Visible           = false
btn.Parent            = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent       = btn

local spinning = false

local function showSkip()
	spinning  = true
	btn.Visible = true
end

local function hideSkip()
	spinning  = false
	btn.Visible = false
end

btn.MouseButton1Click:Connect(function()
	if not spinning then return end
	hideSkip()
	SkipWheelRoll:FireServer()
	-- Signal the wheel animation client-side to finish in 0.25 s
	SpinComplete:Fire()
end)

-- Listen for spin start/end via the existing SpinComplete BindableEvent or
-- a RemoteEvent fired from the wheel UI script.  The wheel client script should
-- fire SpinComplete when the animation ends naturally too.
SpinComplete.Event:Connect(hideSkip)

-- Hook into WheelSpin being invoked — the wheel UI LocalScript calls
-- WheelSpin:InvokeServer(), so we can't intercept that directly.
-- Instead, expose a BindableEvent so the wheel UI can call SkipRollButton.ShowSkip().
local showEvent = Instance.new("BindableEvent")
showEvent.Name   = "ShowSkipButton"
showEvent.Parent = screenGui

showEvent.Event:Connect(showSkip)
