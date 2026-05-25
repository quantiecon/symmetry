local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local NodeData = require(ReplicatedStorage.Shared.NodeData)
local Remotes  = ReplicatedStorage.Remotes

local ZONE_SIZE           = 120
local ZONE_HEIGHT         = 28
local NODE_AREA           = 75
local NODE_COUNT          = 11
local NODE_MIN_DIST       = 13
local RESPAWN_TIME        = 30
local HIT_INTERVAL_AUTO   = 1.5   -- auto-targeted (no click)
local HIT_INTERVAL_MANUAL = 1.0   -- manually clicked (50% faster)
local UNIVERSAL_COOLDOWN  = 0.75  -- min time between any damage for one player
local CRACK_DURATION      = 2.5
local TARGET_RANGE        = 55

local nodeHP        = {}
local nodeCracks    = {}
local playerTargets = {}
local playerLastHit = {}
local playerManual  = {}

local zoneFolder    = Instance.new("Folder")
zoneFolder.Name     = "Zone1"
zoneFolder.Parent   = workspace

local function makePart(size, pos, color, material)
	local p        = Instance.new("Part")
	p.Size         = size
	p.Position     = pos
	p.Anchored     = true
	p.Material     = material or Enum.Material.Slate
	p.Color        = color
	p.Parent       = zoneFolder
	return p
end

local function BuildCavern()
	local rock  = Color3.fromRGB(70, 65, 60)
	local floor = Color3.fromRGB(85, 78, 70)
	local half  = ZONE_SIZE / 2

	makePart(Vector3.new(ZONE_SIZE, 2, ZONE_SIZE), Vector3.new(0, -1, 0), floor, Enum.Material.Slate)

	makePart(Vector3.new(ZONE_SIZE, 2, ZONE_SIZE), Vector3.new(0, ZONE_HEIGHT + 1, 0), rock)
	makePart(Vector3.new(ZONE_SIZE, ZONE_HEIGHT, 2), Vector3.new(0, ZONE_HEIGHT/2, -half), rock)
	makePart(Vector3.new(ZONE_SIZE, ZONE_HEIGHT, 2), Vector3.new(0, ZONE_HEIGHT/2,  half), rock)
	makePart(Vector3.new(2, ZONE_HEIGHT, ZONE_SIZE), Vector3.new(-half, ZONE_HEIGHT/2, 0),  rock)
	makePart(Vector3.new(2, ZONE_HEIGHT, ZONE_SIZE), Vector3.new( half, ZONE_HEIGHT/2, 0),  rock)

	for i = 1, 18 do
		local angle  = (i / 18) * math.pi * 2
		local radius = half - 8 - math.random() * 8
		local x      = math.cos(angle) * radius + (math.random() - 0.5) * 8
		local z      = math.sin(angle) * radius + (math.random() - 0.5) * 8
		local sy     = math.random(3, 8)
		local boulder = makePart(
			Vector3.new(math.random(4, 9), sy, math.random(4, 9)),
			Vector3.new(x, sy / 2, z),
			Color3.fromRGB(75 + math.random(-8, 8), 70 + math.random(-8, 8), 65 + math.random(-8, 8))
		)
		boulder.Shape = Enum.PartType.Ball
		if math.random() < 0.25 then
			local pl      = Instance.new("PointLight")
			pl.Range      = 20
			pl.Brightness = 0.5
			pl.Color      = Color3.fromRGB(100, 160, 220)
			pl.Parent     = boulder
		end
	end

	for _ = 1, 8 do
		local lp         = Instance.new("Part")
		lp.Size          = Vector3.new(0.3, 0.3, 0.3)
		lp.Position      = Vector3.new((math.random() - 0.5) * 90, ZONE_HEIGHT - 1, (math.random() - 0.5) * 90)
		lp.Anchored      = true
		lp.Transparency  = 1
		lp.CanCollide    = false
		lp.Parent        = zoneFolder
		local pl         = Instance.new("PointLight")
		pl.Range         = 35
		pl.Brightness    = 0.6
		pl.Color         = Color3.fromRGB(110, 170, 230)
		pl.Parent        = lp
	end
end

local function CreateNode(basePos, rarity)
	local model      = Instance.new("Model")
	model.Name       = "Node_" .. rarity.name

	local main       = Instance.new("Part")
	main.Name        = "Main"
	main.Size        = Vector3.new(5, 5, 5)
	main.Position    = basePos + Vector3.new(0, 4, 0)
	main.Anchored    = true
	main.Material    = Enum.Material.Neon
	main.Color       = rarity.color
	main.Parent      = model

	-- Permanent black edge outline
	local outline              = Instance.new("SelectionBox")
	outline.Adornee            = main
	outline.Color3             = Color3.fromRGB(0, 0, 0)
	outline.LineThickness      = 0.04
	outline.SurfaceTransparency = 1
	outline.Parent             = model

	local bb         = Instance.new("BillboardGui")
	bb.Size          = UDim2.new(0, 90, 0, 22)
	bb.StudsOffset   = Vector3.new(0, 4, 0)
	bb.AlwaysOnTop   = false
	bb.Parent        = main

	local lbl        = Instance.new("TextLabel")
	lbl.Size         = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3   = rarity.color
	lbl.Text         = rarity.name
	lbl.Font         = Enum.Font.GothamBold
	lbl.TextSize     = 14
	lbl.TextStrokeTransparency = 0.2
	lbl.Parent       = bb

	if rarity.name == "Legendary" then
		local pl      = Instance.new("PointLight")
		pl.Range      = 14
		pl.Brightness = 1.2
		pl.Color      = rarity.color
		pl.Parent     = main
	end

	if rarity.aura then
		local pl      = Instance.new("PointLight")
		pl.Range      = 18
		pl.Brightness = 1.5
		pl.Color      = rarity.color
		pl.Parent     = main

		local att     = Instance.new("Attachment")
		att.Parent    = main

		local pe      = Instance.new("ParticleEmitter")
		pe.Color      = ColorSequence.new(rarity.color)
		pe.LightEmission = 0.9
		pe.Size       = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(1, 0),
		})
		pe.Speed      = NumberRange.new(2, 5)
		pe.Rate       = 35
		pe.Lifetime   = NumberRange.new(1, 2.5)
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.Parent     = att
	end

	model:SetAttribute("Rarity",  rarity.name)
	model:SetAttribute("MaxHP",   rarity.hp)
	model:SetAttribute("Active",  true)
	model:SetAttribute("BaseX",   basePos.X)
	model:SetAttribute("BaseZ",   basePos.Z)
	model.Parent = zoneFolder

	nodeHP[model]     = rarity.hp
	nodeCracks[model] = {
		open       = false,
		openedAt   = 0,
		thresholds = NodeData.CrackThresholds(rarity.hp),
	}

	return model
end

local function ScatterPositions(count)
	local positions = {}
	for _ = 1, count do
		local ok, attempts = false, 0
		while not ok and attempts < 200 do
			attempts += 1
			local candidate = Vector3.new(
				(math.random() - 0.5) * NODE_AREA,
				0,
				(math.random() - 0.5) * NODE_AREA
			)
			ok = true
			for _, p in positions do
				if (candidate - p).Magnitude < NODE_MIN_DIST then
					ok = false
					break
				end
			end
			if ok then table.insert(positions, candidate) end
		end
	end
	return positions
end

local function SpawnAllNodes()
	for _, pos in ScatterPositions(NODE_COUNT) do
		CreateNode(pos, NodeData.RollRarity())
	end
end

local function FindClosestNode(position)
	local closest, closestDist = nil, math.huge
	for _, child in zoneFolder:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("Active") then
			local main = child:FindFirstChild("Main")
			if main then
				local dist = (position - main.Position).Magnitude
				if dist < closestDist then
					closestDist = dist
					closest = child
				end
			end
		end
	end
	return closest
end

local function ProcessHit(player, node, isCrackHit)
	if not node or not node.Parent then return end
	local hp = nodeHP[node]
	if not hp then return end

	local rarity = NodeData.RarityMap[node:GetAttribute("Rarity")]
	local crack  = nodeCracks[node]
	local yield  = rarity.yield

	if isCrackHit and crack and crack.open then
		yield      = math.floor(yield * rarity.bonus)
		crack.open = false
		Remotes.CrackClosed:FireAllClients(node)
	end

	local playerOre = (player:GetAttribute("Ore") or 0) + yield
	player:SetAttribute("Ore", playerOre)
	Remotes.OnYield:FireClient(player, yield, playerOre)

	hp -= 1
	nodeHP[node] = hp

	-- Check crack thresholds
	if crack and not crack.open and #crack.thresholds > 0 and hp <= crack.thresholds[1] then
		table.remove(crack.thresholds, 1)
		crack.open     = true
		crack.openedAt = os.clock()
		Remotes.CrackWindow:FireAllClients(node, CRACK_DURATION)

		task.delay(CRACK_DURATION, function()
			if crack and crack.open then
				crack.open = false
				Remotes.CrackClosed:FireAllClients(node)
			end
		end)
	end

	if hp <= 0 then
		nodeHP[node]     = nil
		nodeCracks[node] = nil
		node:SetAttribute("Active", false)

		-- Immediately disable hitbox and hide visuals
		local main = node:FindFirstChild("Main")
		if main then
			main.CanCollide  = false
			main.Transparency = 1
			local bb = main:FindFirstChildWhichIsA("BillboardGui")
			if bb then bb.Enabled = false end
		end

		-- Notify clients
		Remotes.NodeDepleted:FireAllClients(node)

		-- Clear targeting
		for p, t in playerTargets do
			if t == node then
				playerTargets[p] = nil
				playerManual[p]  = false
			end
		end

		local basePos    = Vector3.new(node:GetAttribute("BaseX"), 0, node:GetAttribute("BaseZ"))
		local nextRarity = NodeData.RollRarity()

		-- Destroy cleanly after clients have processed NodeDepleted
		task.delay(0.5, function()
			if node.Parent then node:Destroy() end
		end)

		task.delay(RESPAWN_TIME, function()
			CreateNode(basePos, nextRarity)
		end)
	else
		local ratio = hp / node:GetAttribute("MaxHP")
		node.Main.Transparency = (1 - ratio) * 0.25
		Remotes.NodeHit:FireAllClients(node, ratio)
	end
end

-- Main heartbeat: auto-targeting + hit loop
RunService.Heartbeat:Connect(function()
	local now = os.clock()

	for _, player in Players:GetPlayers() do
		local char = player.Character
		if not char then continue end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then continue end

		local target = playerTargets[player]

		-- Invalidate stale/dead target
		if target and (not target.Parent or not target:GetAttribute("Active")) then
			playerTargets[player] = nil
			playerManual[player]  = false
			Remotes.TargetCleared:FireClient(player)
			target = nil
		end

		-- Invalidate manual target if out of range
		if target and playerManual[player] then
			local main = target:FindFirstChild("Main")
			if main and (hrp.Position - main.Position).Magnitude > TARGET_RANGE then
				playerTargets[player] = nil
				playerManual[player]  = false
				Remotes.TargetCleared:FireClient(player)
				target = nil
			end
		end

		-- Auto mode: always use closest node (rechecks every frame)
		if not playerManual[player] then
			local closest = FindClosestNode(hrp.Position)
			if closest ~= target then
				target = closest
				playerTargets[player] = closest
				if closest then
					Remotes.TargetConfirmed:FireClient(player, closest)
				else
					Remotes.TargetCleared:FireClient(player)
				end
			end
		end

		if not target then continue end

		local interval = playerManual[player] and HIT_INTERVAL_MANUAL or HIT_INTERVAL_AUTO
		local last     = playerLastHit[player] or 0

		if now - last >= interval then
			playerLastHit[player] = now
			Remotes.OnHit:FireClient(player, target)
			ProcessHit(player, target, false)
		end
	end
end)

-- Player manually clicks a node to target it
Remotes.SetTarget.OnServerEvent:Connect(function(player, node)
	if typeof(node) ~= "Instance" or not node:IsA("Model") then return end
	if not node:GetAttribute("Active") then return end
	if node.Parent ~= zoneFolder then return end

	local char = player.Character
	if not char then return end
	local hrp  = char:FindFirstChild("HumanoidRootPart")
	local main = node:FindFirstChild("Main")
	if not hrp or not main then return end
	if (hrp.Position - main.Position).Magnitude > TARGET_RANGE then return end

	playerTargets[player] = node
	playerManual[player]  = true
	-- Don't reset playerLastHit — no instant hit on target switch
	Remotes.TargetConfirmed:FireClient(player, node)
end)

-- Crack bonus hit
Remotes.CrackHit.OnServerEvent:Connect(function(player, node)
	if typeof(node) ~= "Instance" then return end
	if playerTargets[player] ~= node then return end
	local crack = nodeCracks[node]
	if not crack or not crack.open then return end
	if os.clock() - crack.openedAt > CRACK_DURATION then return end

	local now = os.clock()
	if now - (playerLastHit[player] or 0) < UNIVERSAL_COOLDOWN then return end

	playerLastHit[player] = now
	ProcessHit(player, node, true)
end)

Players.PlayerRemoving:Connect(function(player)
	playerTargets[player] = nil
	playerLastHit[player] = nil
	playerManual[player]  = nil
end)

BuildCavern()
SpawnAllNodes()
