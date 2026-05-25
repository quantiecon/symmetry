local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local player  = Players.LocalPlayer
local mouse   = player:GetMouse()
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local character = player.Character or player.CharacterAdded:Wait()
local rootPart  = character:WaitForChild("HumanoidRootPart")

local currentTarget    = nil
local orbitAngle       = 0

-- pickaxeTargetCF: non-nil while flying to a node; nil resumes orbit
local pickaxeTargetCF  = nil
local flyId            = 0

local ORBIT_RADIUS = 3.2
local ORBIT_SPEED  = 2.2
local ORBIT_HEIGHT = 1.5

-- Placeholder pickaxe
local pickaxe        = Instance.new("Part")
pickaxe.Name         = "MagePickaxe"
pickaxe.Size         = Vector3.new(0.3, 0.3, 2.5)
pickaxe.Anchored     = true
pickaxe.CanCollide   = false
pickaxe.Material     = Enum.Material.Metal
pickaxe.Color        = Color3.fromRGB(200, 200, 220)
pickaxe.CastShadow   = false
pickaxe.Parent       = workspace

local glow       = Instance.new("PointLight")
glow.Range       = 8
glow.Brightness  = 1
glow.Color       = Color3.fromRGB(140, 200, 255)
glow.Parent      = pickaxe

-- All pickaxe movement goes through here — lerp handles every transition smoothly
RunService.RenderStepped:Connect(function(dt)
	local targetCF
	if pickaxeTargetCF then
		targetCF = pickaxeTargetCF
	else
		orbitAngle += ORBIT_SPEED * dt
		local p = rootPart.Position
		targetCF = CFrame.new(
			p.X + math.cos(orbitAngle) * ORBIT_RADIUS,
			p.Y + ORBIT_HEIGHT,
			p.Z + math.sin(orbitAngle) * ORBIT_RADIUS
		) * CFrame.Angles(0, -orbitAngle, math.pi / 4)
	end
	-- Lerp gives smooth dart-out and smooth return — no teleporting
	pickaxe.CFrame = pickaxe.CFrame:Lerp(targetCF, math.min(1, dt * 14))
end)

-- Dart to node on each hit; latest call wins, older ones just expire
local function FlyTo(targetPart)
	if not targetPart or not targetPart.Parent then return end
	flyId += 1
	local myId = flyId
	pickaxeTargetCF = CFrame.new(targetPart.Position + Vector3.new(0, 0.5, 0))
		* CFrame.Angles(math.pi / 2, 0, 0)
	-- Hold at node briefly then release so orbit resumes
	task.delay(0.35, function()
		if flyId == myId then
			pickaxeTargetCF = nil
		end
	end)
end

-- HUD
local gui     = Instance.new("ScreenGui")
gui.Name      = "MiningHUD"
gui.ResetOnSpawn = false
gui.Parent    = player.PlayerGui

local oreFrame = Instance.new("Frame")
oreFrame.Size  = UDim2.new(0, 160, 0, 44)
oreFrame.Position = UDim2.new(0, 16, 0, 16)
oreFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
oreFrame.BackgroundTransparency = 0.4
oreFrame.BorderSizePixel = 0
oreFrame.Parent = gui

local oreCorner = Instance.new("UICorner")
oreCorner.CornerRadius = UDim.new(0, 10)
oreCorner.Parent = oreFrame

local oreLabel = Instance.new("TextLabel")
oreLabel.Size  = UDim2.new(1, 0, 1, 0)
oreLabel.BackgroundTransparency = 1
oreLabel.TextColor3 = Color3.fromRGB(255, 215, 80)
oreLabel.Text  = "Ore: 0"
oreLabel.Font  = Enum.Font.GothamBold
oreLabel.TextSize = 20
oreLabel.Parent = oreFrame

local hintLabel = Instance.new("TextLabel")
hintLabel.Size  = UDim2.new(0, 300, 0, 30)
hintLabel.Position = UDim2.new(0.5, -150, 1, -60)
hintLabel.BackgroundTransparency = 1
hintLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
hintLabel.Text  = "Walk near a node to mine"
hintLabel.Font  = Enum.Font.Gotham
hintLabel.TextSize = 16
hintLabel.TextTransparency = 0.3
hintLabel.Parent = gui

local function YieldPop(amount, targetPart)
	if not targetPart or not targetPart.Parent then return end
	local bb = Instance.new("BillboardGui")
	bb.Size  = UDim2.new(0, 70, 0, 28)
	bb.StudsOffset = Vector3.new(math.random(-2, 2), 5 + math.random(0, 2), 0)
	bb.AlwaysOnTop = false
	bb.Parent = targetPart

	local lbl = Instance.new("TextLabel")
	lbl.Size  = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.fromRGB(255, 220, 60)
	lbl.Text  = "+" .. tostring(amount)
	lbl.Font  = Enum.Font.GothamBold
	lbl.TextSize = 18
	lbl.TextStrokeTransparency = 0.3
	lbl.Parent = bb

	TweenService:Create(lbl, TweenInfo.new(1.2, Enum.EasingStyle.Quad), { TextTransparency = 1 }):Play()
	task.delay(1.2, function() bb:Destroy() end)
end

-- Click to manually target a node
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	local hit = mouse.Target
	if not hit then return end
	local node = hit.Parent
	if not node or not node:GetAttribute("Active") then return end
	Remotes.SetTarget:FireServer(node)
end)

Remotes.TargetConfirmed.OnClientEvent:Connect(function(node)
	currentTarget  = node
	local rarity   = node:GetAttribute("Rarity") or "Node"
	hintLabel.Text = "Mining: " .. rarity
end)

Remotes.TargetCleared.OnClientEvent:Connect(function()
	currentTarget  = nil
	hintLabel.Text = "Walk near a node to mine"
end)

Remotes.OnHit.OnClientEvent:Connect(function(node)
	local main = node and node:FindFirstChild("Main")
	if not main then return end
	task.spawn(FlyTo, main)
end)

Remotes.NodeDepleted.OnClientEvent:Connect(function(node)
	if node == currentTarget then
		currentTarget  = nil
		hintLabel.Text = "Walk near a node to mine"
	end
end)

Remotes.OnYield.OnClientEvent:Connect(function(amount, total)
	oreLabel.Text = "Ore: " .. tostring(total)
	local main = currentTarget and currentTarget:FindFirstChild("Main")
	if main then YieldPop(amount, main) end
end)

-- Keep CrackWindow/CrackClosed/CrackHit/NodeHit connections alive so the
-- server's FireAllClients calls don't error, but do nothing client-side.
Remotes.CrackWindow.OnClientEvent:Connect(function() end)
Remotes.CrackClosed.OnClientEvent:Connect(function() end)
Remotes.NodeHit.OnClientEvent:Connect(function() end)
