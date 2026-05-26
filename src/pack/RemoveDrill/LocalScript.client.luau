local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local tool = script.Parent
local Events = ReplicatedStorage:WaitForChild("Events")

-- Create reusable highlight
local highlight = Instance.new("Highlight")
highlight.FillColor = Color3.fromRGB(255, 0, 0)
highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
highlight.FillTransparency = 0.5
highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
highlight.Enabled = false
highlight.Parent = player:WaitForChild("PlayerGui") -- safer than CoreGui

local currentTarget = nil
local toolEquipped = false

-- Handle tool equipped
tool.Equipped:Connect(function()
	toolEquipped = true
end)

-- Handle tool unequipped
tool.Unequipped:Connect(function()
	toolEquipped = false
	currentTarget = nil
	highlight.Enabled = false
end)

-- Handle drill pickup
tool.Activated:Connect(function()
	if currentTarget then
		Events.PickUpDrill:FireServer(currentTarget)
	end
end)

-- Update highlight based on mouse hover
RunService.RenderStepped:Connect(function()
	if not toolEquipped then return end

	local target = mouse.Target
	if target and target.Parent then
		local drillModel = target:FindFirstAncestorWhichIsA("Model")
		local drillData = drillModel and drillModel:FindFirstChild("Data")

		if drillData and drillData:FindFirstChild("Owner") and drillData.Owner.Value == player.Name then
			if currentTarget ~= drillModel then
				currentTarget = drillModel
				highlight.Adornee = drillModel
				highlight.Enabled = true
			end
			return
		end
	end

	-- Not hovering over a valid drill
	currentTarget = nil
	highlight.Enabled = false
end)