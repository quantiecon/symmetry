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

local currentTarget    = nil
local crackActive      = {}   -- [node] = { sel, light, bb }
local crackHoverActive = false
local isFlying         = false
local flyCount         = 0
local orbitAngle       = 0

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

local glow           = Instance.new("PointLight")
glow.Range           = 8
glow.Brightness      = 1
glow.Color           = Color3.fromRGB(140, 200, 255)
glow.Parent          = pickaxe

RunService.RenderStepped:Connect(function(dt)
	-- During crack window: lerp pickaxe toward hovering position near node
	if crackHoverActive and currentTarget and currentTarget.Parent then
		local main = currentTarget:FindFirstChild("Main")
		if main then
			local hoverCF = CFrame.new(main.Position + Vector3.new(0, 3.5, -4))
				* CFrame.Angles(math.pi / 4, 0, 0)
			pickaxe.CFrame = pickaxe.CFrame:Lerp(hoverCF, math.min(1, dt * 9))
		end
		return
	end
	if isFlying then return end
	orbitAngle += ORBIT_SPEED * dt
	local p = rootPart.Position
	pickaxe.CFrame = CFrame.new(
		p.X + math.cos(orbitAngle) * ORBIT_RADIUS,
		p.Y + ORBIT_HEIGHT,
		p.Z + math.sin(orbitAngle) * ORBIT_RADIUS
	) * CFrame.Angles(0, -orbitAngle, math.pi / 4)
end)

-- FlyTo: flyCount lets the latest call always win; no call is skipped
local function FlyTo(targetPart, grandSlam)
	if not targetPart or not targetPart.Parent then return end
	crackHoverActive = false
	flyCount += 1
	local myCount = flyCount
	isFlying = true

	if grandSlam then
		-- Rise behind the node, then slam into it
		local riseCF = CFrame.new(targetPart.Position + Vector3.new(0, 5.5, -3))
			* CFrame.Angles(math.pi / 3, 0, 0)
		TweenService:Create(pickaxe, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = riseCF,
		}):Play()
		task.delay(0.14, function()
			if flyCount ~= myCount then return end
			local slamCF = CFrame.new(targetPart.Position + Vector3.new(0, 0.2, 0))
				* CFrame.Angles(math.pi / 2, 0, 0)
			TweenService:Create(pickaxe, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				CFrame = slamCF,
			}):Play()
			task.delay(0.12, function()
				if flyCount == myCount then isFlying = false end
			end)
		end)
	else
		-- Quick dart to node and return to orbit
		local dest = targetPart.Position + Vector3.new(0, 0.5, 0)
		TweenService:Create(pickaxe, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = CFrame.new(dest) * CFrame.Angles(math.pi / 2, 0, 0),
		}):Play()
		task.delay(0.28, function()
			if flyCount == myCount then isFlying = false end
		end)
	end
end

-- Show crack visual — persists on node until depleted
local function ShowCrack(node)
	local main = node:FindFirstChild("Main")
	if not main then return end

	if not crackActive[node] then
		local sel               = Instance.new("SelectionBox")
		sel.Adornee             = main
		sel.Color3              = Color3.fromRGB(255, 215, 0)
		sel.LineThickness       = 0.12
		sel.SurfaceTransparency = 0.5
		sel.Parent              = main

		local light             = Instance.new("PointLight")
		light.Range             = 20
		light.Brightness        = 2.5
		light.Color             = Color3.fromRGB(255, 200, 0)
		light.Parent            = main

		local bb                = Instance.new("BillboardGui")
		bb.Size                 = UDim2.new(0, 56, 0, 56)
		bb.StudsOffset          = Vector3.new(0, 5.5, 0)
		bb.AlwaysOnTop          = false
		bb.Parent               = main

		local lbl               = Instance.new("TextLabel")
		lbl.Size                = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3          = Color3.fromRGB(255, 230, 40)
		lbl.Text                = "⚡"
		lbl.Font                = Enum.Font.GothamBold
		lbl.TextScaled          = true
		lbl.TextStrokeTransparency = 0.2
		lbl.Parent              = bb

		local entry = { sel = sel, light = light, bb = bb, lbl = lbl }
		crackActive[node] = entry

		-- Pulse loop until node depleted
		task.spawn(function()
			while crackActive[node] == entry and sel.Parent do
				TweenService:Create(sel, TweenInfo.new(0.35), { SurfaceTransparency = 0.08 }):Play()
				TweenService:Create(lbl, TweenInfo.new(0.35), { TextTransparency = 0 }):Play()
				task.wait(0.35)
				TweenService:Create(sel, TweenInfo.new(0.35), { SurfaceTransparency = 0.55 }):Play()
				TweenService:Create(lbl, TweenInfo.new(0.35), { TextTransparency = 0.5 }):Play()
				task.wait(0.35)
			end
		end)
	end

	-- Brief white flash
	local origColor = main.Color
	main.Color = Color3.fromRGB(255, 255, 255)
	task.delay(0.15, function()
		if main.Parent then main.Color = origColor end
	end)
end

local function RemoveCrackVisual(node)
	local entry = crackActive[node]
	if entry then
		crackActive[node] = nil
		if entry.sel   and entry.sel.Parent   then entry.sel:Destroy()   end
		if entry.light and entry.light.Parent then entry.light:Destroy() end
		if entry.bb    and entry.bb.Parent    then entry.bb:Destroy()    end
	end
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

local oreCorner        = Instance.new("UICorner")
oreCorner.CornerRadius = UDim.new(0, 10)
oreCorner.Parent       = oreFrame

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
hintLabel.TextColor3   = Color3.fromRGB(220, 220, 220)
hintLabel.Text         = "Auto-mining nearby node"
hintLabel.Font         = Enum.Font.Gotham
hintLabel.TextSize     = 16
hintLabel.TextTransparency = 0.3
hintLabel.Parent       = gui

local crackHint        = Instance.new("TextLabel")
crackHint.Size         = UDim2.new(0, 340, 0, 32)
crackHint.Position     = UDim2.new(0.5, -170, 1, -96)
crackHint.BackgroundTransparency = 1
crackHint.TextColor3   = Color3.fromRGB(255, 215, 0)
crackHint.Text         = "⚡ Click to shatter!"
crackHint.Font         = Enum.Font.GothamBold
crackHint.TextSize     = 18
crackHint.Visible      = false
crackHint.Parent       = gui

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

-- Click: set target OR trigger crack grand slam
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

	local hit = mouse.Target
	if not hit then return end
	local node = hit.Parent
	if not node or not node:GetAttribute("Active") then return end

	-- Crack grand slam: fire server + play slam animation
	if crackActive[node] and node == currentTarget then
		Remotes.CrackHit:FireServer(node)
		local main = node:FindFirstChild("Main")
		if main then task.spawn(FlyTo, main, true) end
		return
	end

	-- Set manual target (clicking again on already-targeted node is a no-op)
	if node ~= currentTarget then
		Remotes.SetTarget:FireServer(node)
	end
end)

Remotes.TargetConfirmed.OnClientEvent:Connect(function(node)
	currentTarget  = node
	local rarity   = node:GetAttribute("Rarity") or "Node"
	hintLabel.Text = "Mining: " .. rarity
	if crackActive[node] then
		crackHint.Visible = true
	end
end)

Remotes.TargetCleared.OnClientEvent:Connect(function()
	currentTarget      = nil
	crackHoverActive   = false
	hintLabel.Text     = "Auto-mining nearby node"
	crackHint.Visible  = false
end)

-- Normal auto-hit animation; skip dart if pickaxe is hovering for crack
Remotes.OnHit.OnClientEvent:Connect(function(node)
	local main = node and node:FindFirstChild("Main")
	if not main then return end
	if crackHoverActive and node == currentTarget then return end
	task.spawn(FlyTo, main, false)
end)

Remotes.CrackWindow.OnClientEvent:Connect(function(node)
	ShowCrack(node)
	if node == currentTarget then
		crackHint.Visible  = true
		crackHoverActive   = true
	end
end)

Remotes.CrackClosed.OnClientEvent:Connect(function(node)
	if node == currentTarget then
		crackHoverActive  = false
		crackHint.Visible = false
	end
end)

Remotes.NodeDepleted.OnClientEvent:Connect(function(node)
	RemoveCrackVisual(node)
	if node == currentTarget then
		currentTarget      = nil
		crackHoverActive   = false
		hintLabel.Text     = "Auto-mining nearby node"
		crackHint.Visible  = false
	end
end)

Remotes.NodeHit.OnClientEvent:Connect(function(node, _ratio)
	local main = node and node:FindFirstChild("Main")
	if not main then return end
	local original = main.Color
	main.Color = Color3.fromRGB(255, 255, 255)
	task.delay(0.05, function()
		if main.Parent then main.Color = original end
	end)
end)

Remotes.OnYield.OnClientEvent:Connect(function(amount, total)
	oreLabel.Text = "Ore: " .. tostring(total)
	local main = currentTarget and currentTarget:FindFirstChild("Main")
	if main then YieldPop(amount, main) end
end)
