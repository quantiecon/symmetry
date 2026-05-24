local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local mouse     = player:GetMouse()
local Remotes   = ReplicatedStorage:WaitForChild("Remotes")

local character = player.Character or player.CharacterAdded:Wait()
local rootPart  = character:WaitForChild("HumanoidRootPart")

local currentTarget = nil
local crackActive   = {}
local isFlying      = false
local orbitAngle    = 0

local ORBIT_RADIUS = 3.2
local ORBIT_SPEED  = 2.2
local ORBIT_HEIGHT = 1.5

-- Placeholder pickaxe (elongated Part)
local pickaxe        = Instance.new("Part")
pickaxe.Name         = "MagePickaxe"
pickaxe.Size         = Vector3.new(0.3, 0.3, 2.5)
pickaxe.Anchored     = true
pickaxe.CanCollide   = false
pickaxe.Material     = Enum.Material.Metal
pickaxe.Color        = Color3.fromRGB(200, 200, 220)
pickaxe.CastShadow   = false
pickaxe.Parent       = workspace

local glow           = Instance.new("PointLight")
glow.Range           = 8
glow.Brightness      = 1
glow.Color           = Color3.fromRGB(140, 200, 255)
glow.Parent          = pickaxe

RunService.RenderStepped:Connect(function(dt)
	if isFlying then return end
	orbitAngle += ORBIT_SPEED * dt
	local p = rootPart.Position
	pickaxe.CFrame = CFrame.new(
		p.X + math.cos(orbitAngle) * ORBIT_RADIUS,
		p.Y + ORBIT_HEIGHT,
		p.Z + math.sin(orbitAngle) * ORBIT_RADIUS
	) * CFrame.Angles(0, -orbitAngle, math.pi / 4)
end)

local function FlyTo(targetPart)
	isFlying  = true
	local dest = targetPart.Position + Vector3.new(0, 0.5, 0)

	TweenService:Create(pickaxe, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = CFrame.new(dest) * CFrame.Angles(math.pi / 2, 0, 0),
	}):Play()
	task.wait(0.27)

	local home = rootPart.Position + Vector3.new(
		math.cos(orbitAngle) * ORBIT_RADIUS,
		ORBIT_HEIGHT,
		math.sin(orbitAngle) * ORBIT_RADIUS
	)
	TweenService:Create(pickaxe, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		CFrame = CFrame.new(home),
	}):Play()
	task.wait(0.18)
	isFlying = false
end

local function ShowCrack(node, duration)
	local main = node:FindFirstChild("Main")
	if not main then return end

	local sel                  = Instance.new("SelectionBox")
	sel.Adornee                = main
	sel.Color3                 = Color3.fromRGB(255, 215, 0)
	sel.LineThickness          = 0.06
	sel.SurfaceTransparency    = 0.65
	sel.Parent                 = main
	crackActive[node]          = sel

	task.spawn(function()
		while sel.Parent and crackActive[node] do
			TweenService:Create(sel, TweenInfo.new(0.35), { SurfaceTransparency = 0.25 }):Play()
			task.wait(0.35)
			TweenService:Create(sel, TweenInfo.new(0.35), { SurfaceTransparency = 0.65 }):Play()
			task.wait(0.35)
		end
	end)

	task.delay(duration, function()
		if crackActive[node] == sel then
			crackActive[node] = nil
			sel:Destroy()
		end
	end)
end

local function HideCrack(node)
	local sel = crackActive[node]
	if sel then
		crackActive[node] = nil
		sel:Destroy()
	end
end

local function YieldPop(amount, targetPart)
	if not targetPart or not targetPart.Parent then return end
	local bb               = Instance.new("BillboardGui")
	bb.Size                = UDim2.new(0, 70, 0, 28)
	bb.StudsOffset         = Vector3.new(math.random(-2, 2), 5 + math.random(0, 2), 0)
	bb.AlwaysOnTop         = false
	bb.Parent              = targetPart

	local lbl              = Instance.new("TextLabel")
	lbl.Size               = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3         = Color3.fromRGB(255, 220, 60)
	lbl.Text               = "+" .. tostring(amount)
	lbl.Font               = Enum.Font.GothamBold
	lbl.TextSize           = 18
	lbl.TextStrokeTransparency = 0.3
	lbl.Parent             = bb

	TweenService:Create(lbl, TweenInfo.new(1.2, Enum.EasingStyle.Quad), { TextTransparency = 1 }):Play()
	task.delay(1.2, function() bb:Destroy() end)
end

-- HUD
local gui              = Instance.new("ScreenGui")
gui.Name               = "MiningHUD"
gui.ResetOnSpawn       = false
gui.Parent             = player.PlayerGui

local oreFrame         = Instance.new("Frame")
oreFrame.Size          = UDim2.new(0, 160, 0, 44)
oreFrame.Position      = UDim2.new(0, 16, 0, 16)
oreFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
oreFrame.BackgroundTransparency = 0.4
oreFrame.BorderSizePixel = 0
oreFrame.Parent        = gui

local corner           = Instance.new("UICorner")
corner.CornerRadius    = UDim.new(0, 10)
corner.Parent          = oreFrame

local oreLabel         = Instance.new("TextLabel")
oreLabel.Size          = UDim2.new(1, 0, 1, 0)
oreLabel.BackgroundTransparency = 1
oreLabel.TextColor3    = Color3.fromRGB(255, 215, 80)
oreLabel.Text          = "Ore: 0"
oreLabel.Font          = Enum.Font.GothamBold
oreLabel.TextSize      = 20
oreLabel.Parent        = oreFrame

local hintLabel        = Instance.new("TextLabel")
hintLabel.Size         = UDim2.new(0, 300, 0, 30)
hintLabel.Position     = UDim2.new(0.5, -150, 1, -60)
hintLabel.BackgroundTransparency = 1
hintLabel.TextColor3   = Color3.fromRGB(255, 255, 255)
hintLabel.Text         = "Click a node to mine"
hintLabel.Font         = Enum.Font.Gotham
hintLabel.TextSize     = 16
hintLabel.TextTransparency = 0.3
hintLabel.Parent       = gui

local crackHint        = Instance.new("TextLabel")
crackHint.Size         = UDim2.new(0, 300, 0, 30)
crackHint.Position     = UDim2.new(0.5, -150, 1, -92)
crackHint.BackgroundTransparency = 1
crackHint.TextColor3   = Color3.fromRGB(255, 215, 0)
crackHint.Text         = "⚡ Click the node for a bonus!"
crackHint.Font         = Enum.Font.GothamBold
crackHint.TextSize     = 16
crackHint.Visible      = false
crackHint.Parent       = gui

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

	local hit = mouse.Target
	if not hit then return end
	local node = hit.Parent
	if not node or not node:GetAttribute("Active") then return end

	if crackActive[node] and node == currentTarget then
		Remotes.CrackHit:FireServer(node)
		return
	end

	Remotes.SetTarget:FireServer(node)
end)

Remotes.TargetConfirmed.OnClientEvent:Connect(function(node)
	currentTarget  = node
	hintLabel.Text = "Mining: " .. node:GetAttribute("Rarity")
end)

Remotes.TargetCleared.OnClientEvent:Connect(function()
	currentTarget      = nil
	hintLabel.Text     = "Click a node to mine"
	crackHint.Visible  = false
end)

Remotes.OnHit.OnClientEvent:Connect(function(node)
	local main = node and node:FindFirstChild("Main")
	if not main then return end
	task.spawn(FlyTo, main)
end)

Remotes.CrackWindow.OnClientEvent:Connect(function(node, duration)
	ShowCrack(node, duration)
	if node == currentTarget then
		crackHint.Visible = true
	end
end)

Remotes.CrackClosed.OnClientEvent:Connect(function(node)
	HideCrack(node)
	if node == currentTarget then
		crackHint.Visible = false
	end
end)

Remotes.NodeDepleted.OnClientEvent:Connect(function(node)
	HideCrack(node)
	if node == currentTarget then
		currentTarget     = nil
		hintLabel.Text    = "Click a node to mine"
		crackHint.Visible = false
	end
end)

Remotes.NodeHit.OnClientEvent:Connect(function(node, _ratio)
	local main = node and node:FindFirstChild("Main")
	if not main then return end
	local original = main.Color
	main.Color = Color3.fromRGB(255, 255, 255)
	task.delay(0.06, function()
		if main.Parent then main.Color = original end
	end)
end)

Remotes.OnYield.OnClientEvent:Connect(function(amount, total)
	oreLabel.Text = "Ore: " .. tostring(total)
	local main = currentTarget and currentTarget:FindFirstChild("Main")
	if main then YieldPop(amount, main) end
end)
