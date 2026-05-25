local Players = game:GetService("Players")

local bp = workspace:FindFirstChild("Baseplate")
if bp then bp:Destroy() end

local world = Instance.new("Folder")
world.Name  = "World"
world.Parent = workspace

local TC = Vector3.new(0, 0, 300)
local function T(x, y, z) return TC + Vector3.new(x, y, z) end

local function part(parent, size, pos, color, material, transparency)
	local p = Instance.new("Part")
	p.Size = size; p.Position = pos; p.Anchored = true
	p.Material = material or Enum.Material.SmoothPlastic; p.Color = color
	p.Transparency = transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function wedge(parent, size, pos, color, material)
	local p = Instance.new("WedgePart")
	p.Size = size; p.Position = pos; p.Anchored = true
	p.Material = material or Enum.Material.SmoothPlastic; p.Color = color
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local COBBLE     = Color3.fromRGB(140, 130, 118)
local STONE      = Color3.fromRGB(110, 104, 96)
local CREAM      = Color3.fromRGB(237, 224, 200)
local TERRACOTTA = Color3.fromRGB(190, 98, 60)
local SHUTTER    = Color3.fromRGB(72, 108, 72)
local WOOD       = Color3.fromRGB(130, 90, 55)
local DARK       = Color3.fromRGB(40, 36, 32)
local ARCH_COLOR = Color3.fromRGB(80, 75, 68)
local ROCK       = Color3.fromRGB(68, 62, 56)

-- Ground covers town + road + aligns with mine floor
part(world, Vector3.new(280, 2, 560), Vector3.new(0, -1, 76), COBBLE, Enum.Material.Cobblestone)

-- ── Piazza ────────────────────────────────────────────────────────────────
local piazza = Instance.new("Folder"); piazza.Name = "Piazza"; piazza.Parent = world
part(piazza, Vector3.new(82, 0.6, 82), T(0, 0.3, 0), Color3.fromRGB(160, 150, 136), Enum.Material.Cobblestone)
part(piazza, Vector3.new(14, 0.7, 82), T(0, 0.35, 0), Color3.fromRGB(185, 175, 160), Enum.Material.SmoothPlastic)
part(piazza, Vector3.new(82, 0.7, 14), T(0, 0.35, 0), Color3.fromRGB(185, 175, 160), Enum.Material.SmoothPlastic)
for _, cx in {-30, 30} do
	for _, cz in {-30, 30} do
		part(piazza, Vector3.new(16, 0.8, 16), T(cx, 0.4, cz), Color3.fromRGB(195, 182, 165), Enum.Material.Cobblestone)
	end
end

-- ── Fountain ──────────────────────────────────────────────────────────────
local fountain = Instance.new("Folder"); fountain.Name = "Fountain"; fountain.Parent = world
part(fountain, Vector3.new(14, 1.4, 14), T(0, 0.7, 0), STONE, Enum.Material.Marble)
part(fountain, Vector3.new(10, 1.5, 10), T(0, 0.75, 0), Color3.fromRGB(150, 195, 215), Enum.Material.Neon, 0.6)
part(fountain, Vector3.new(2, 4.5, 2),   T(0, 2.25, 0), STONE, Enum.Material.Marble)
part(fountain, Vector3.new(7, 0.8, 7),   T(0, 4.8, 0),  STONE, Enum.Material.Marble)
part(fountain, Vector3.new(4, 0.5, 4),   T(0, 5.2, 0),  Color3.fromRGB(150, 195, 215), Enum.Material.Neon, 0.5)
part(fountain, Vector3.new(0.6, 1.8, 0.6), T(0, 6.4, 0), STONE, Enum.Material.Marble)

local sprayPart = Instance.new("Part")
sprayPart.Size = Vector3.new(0.1, 0.1, 0.1); sprayPart.Position = T(0, 7, 0)
sprayPart.Anchored = true; sprayPart.Transparency = 1; sprayPart.CanCollide = false
sprayPart.Parent = fountain
local att = Instance.new("Attachment"); att.Parent = sprayPart
local pe = Instance.new("ParticleEmitter")
pe.Color = ColorSequence.new(Color3.fromRGB(180, 220, 255)); pe.LightEmission = 0.6
pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.12), NumberSequenceKeypoint.new(1, 0) })
pe.Speed = NumberRange.new(8, 14); pe.Rate = 60; pe.Lifetime = NumberRange.new(0.8, 1.5)
pe.SpreadAngle = Vector2.new(25, 25); pe.RotSpeed = NumberRange.new(-90, 90); pe.Parent = att
local wl = Instance.new("PointLight")
wl.Range = 14; wl.Brightness = 1.2; wl.Color = Color3.fromRGB(140, 200, 255); wl.Parent = sprayPart

-- ── Buildings ─────────────────────────────────────────────────────────────
local function building(cx, cz, w, d, h)
	local folder = Instance.new("Folder"); folder.Name = "Building"; folder.Parent = world
	local bx, bz, by = TC.X + cx, TC.Z + cz, h / 2 + 0.6
	part(folder, Vector3.new(w, h, d), Vector3.new(bx, by, bz), CREAM, Enum.Material.SmoothPlastic)
	local rh = 3.5
	local r1 = wedge(folder, Vector3.new(w, rh, d/2), Vector3.new(bx, h+0.6+rh/2, bz-d/4), TERRACOTTA)
	r1.CFrame = CFrame.new(r1.Position)
	local r2 = wedge(folder, Vector3.new(w, rh, d/2), Vector3.new(bx, h+0.6+rh/2, bz+d/4), TERRACOTTA)
	r2.CFrame = CFrame.new(r2.Position) * CFrame.Angles(0, math.pi, 0)
	for _, fz in { cz - d/2 - 0.05, cz + d/2 + 0.05 } do
		local wy = TC.Y + h * 0.6 + 0.6
		for _, wx in { cx - w/4, cx + w/4 } do
			local wp = part(folder, Vector3.new(2.2, 2.8, 0.18), Vector3.new(TC.X+wx, wy, TC.Z+fz), Color3.fromRGB(180, 210, 230), Enum.Material.Glass)
			wp.Transparency = 0.5
			part(folder, Vector3.new(0.9, 2.8, 0.22), Vector3.new(TC.X+wx-1.6, wy, TC.Z+fz), SHUTTER, Enum.Material.Wood)
			part(folder, Vector3.new(0.9, 2.8, 0.22), Vector3.new(TC.X+wx+1.6, wy, TC.Z+fz), SHUTTER, Enum.Material.Wood)
		end
	end
	local doorZ = TC.Z + cz - d/2 - 0.1
	part(folder, Vector3.new(2.4, 3.8, 0.22), Vector3.new(TC.X+cx, TC.Y+2.5, doorZ), DARK, Enum.Material.Wood)
	local lamp = part(folder, Vector3.new(0.3, 0.3, 0.3), Vector3.new(TC.X+cx, TC.Y+5, doorZ-0.3), Color3.fromRGB(255, 220, 140), Enum.Material.Neon)
	lamp.Transparency = 0.2
	local dl = Instance.new("PointLight"); dl.Range = 12; dl.Brightness = 1.5; dl.Color = Color3.fromRGB(255, 210, 130); dl.Parent = lamp
end

building(-32, -24, 22, 18, 14); building( 32, -24, 22, 18, 14)
building(-32,  24, 22, 18, 12); building( 32,  24, 22, 18, 12)
building(-38,   0, 18, 16, 11); building( 38,   0, 18, 16, 11)

-- ── Street lamps ──────────────────────────────────────────────────────────
local function streetLamp(px, pz)
	local lf = Instance.new("Folder"); lf.Name = "Lamp"; lf.Parent = world
	part(lf, Vector3.new(0.5, 7, 0.5), T(px, 3.6, pz), STONE, Enum.Material.SmoothPlastic)
	part(lf, Vector3.new(1, 0.6, 1),   T(px, 7.3, pz), DARK,  Enum.Material.SmoothPlastic)
	local glow = part(lf, Vector3.new(0.5, 0.5, 0.5), T(px, 7, pz), Color3.fromRGB(255, 220, 140), Enum.Material.Neon)
	glow.Transparency = 0.1
	local pl = Instance.new("PointLight"); pl.Range = 22; pl.Brightness = 1.8; pl.Color = Color3.fromRGB(255, 210, 130); pl.Parent = glow
end

streetLamp(-34, -34); streetLamp( 34, -34); streetLamp(-34,  34); streetLamp( 34,  34)
streetLamp( -8, -68); streetLamp(  8, -68); streetLamp( -8, -110); streetLamp(  8, -110)
streetLamp( -8, -148); streetLamp(  8, -148)

-- ── North road ────────────────────────────────────────────────────────────
part(world, Vector3.new(18, 1.2, 126), T(0, 0.6, -107), Color3.fromRGB(155, 145, 130), Enum.Material.Cobblestone)
part(world, Vector3.new(1.5, 1.4, 126), T(-9.75, 0.7, -107), STONE, Enum.Material.Cobblestone)
part(world, Vector3.new(1.5, 1.4, 126), T( 9.75, 0.7, -107), STONE, Enum.Material.Cobblestone)

-- ── Torch helper ─────────────────────────────────────────────────────────
-- torchAt uses absolute world coords; torch uses T() offsets
local function torchAt(parent, wx, wy, wz)
	local tf = Instance.new("Folder"); tf.Name = "Torch"; tf.Parent = parent
	part(tf, Vector3.new(0.4, 1.2, 0.4), Vector3.new(wx, wy, wz), WOOD, Enum.Material.Wood)
	local flame = part(tf, Vector3.new(0.3, 0.3, 0.3), Vector3.new(wx, wy + 0.8, wz), Color3.fromRGB(255, 160, 40), Enum.Material.Neon)
	flame.Transparency = 0.1
	local fl = Instance.new("PointLight"); fl.Range = 14; fl.Brightness = 1.8
	fl.Color = Color3.fromRGB(255, 160, 40); fl.Parent = flame
end
local function torch(parent, px, pz)
	local wp = T(px, 0, pz)
	torchAt(parent, wp.X, 5.5, wp.Z)
end

-- ── Cave entrance arch (world Z ≈ 132) ────────────────────────────────────
local cave = Instance.new("Folder"); cave.Name = "CaveEntrance"; cave.Parent = world
part(cave, Vector3.new(5, 16, 5), T(-9,  8, -168), ARCH_COLOR, Enum.Material.Slate)
part(cave, Vector3.new(5, 16, 5), T( 9,  8, -168), ARCH_COLOR, Enum.Material.Slate)
part(cave, Vector3.new(23, 4, 5), T( 0, 18, -168), ARCH_COLOR, Enum.Material.Slate)
part(cave, Vector3.new(5,  3, 5), T( 0, 16, -168), Color3.fromRGB(95, 88, 78), Enum.Material.Slate)

local signBoard = part(cave, Vector3.new(13, 2.5, 0.3), T(0, 22, -168), Color3.fromRGB(100, 65, 30), Enum.Material.Wood)
local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Front; sg.Parent = signBoard
local sl = Instance.new("TextLabel"); sl.Size = UDim2.new(1,0,1,0); sl.BackgroundTransparency = 1
sl.TextColor3 = Color3.fromRGB(255, 230, 140); sl.Text = "MINIERA"
sl.Font = Enum.Font.GothamBold; sl.TextScaled = true; sl.Parent = sg

torch(cave, -12, -165); torch(cave,  12, -165)
torch(cave, -12, -171); torch(cave,  12, -171)
for i = 1, 4 do
	local rz = -50 - i * 26
	torch(world, -11, rz); torch(world, 11, rz)
end

-- ── Tunnel corridor connecting arch to mine (world Z 60 → 132) ───────────
-- Open cross-section: 13 wide × 12 tall, matching the mine wall gap
local tunnel = Instance.new("Folder"); tunnel.Name = "Tunnel"; tunnel.Parent = world
-- length = 72 studs, centre Z = 96
part(tunnel, Vector3.new(13, 3, 72), Vector3.new(0, 13.5, 96), ROCK, Enum.Material.Slate)  -- ceiling
part(tunnel, Vector3.new(2, 12, 72), Vector3.new(-7.5, 6, 96), ROCK, Enum.Material.Slate)  -- left wall
part(tunnel, Vector3.new(2, 12, 72), Vector3.new( 7.5, 6, 96), ROCK, Enum.Material.Slate)  -- right wall

for _, wz in { 70, 86, 102, 118 } do
	torchAt(tunnel, -5.5, 7, wz)
	torchAt(tunnel,  5.5, 7, wz)
end

-- ── Exit arch inside mine (world Z = 62, framing the wall opening) ────────
local exitCave = Instance.new("Folder"); exitCave.Name = "MineExit"; exitCave.Parent = world
part(exitCave, Vector3.new(5, 16, 5), Vector3.new(-9,  8, 62), ARCH_COLOR, Enum.Material.Slate)
part(exitCave, Vector3.new(5, 16, 5), Vector3.new( 9,  8, 62), ARCH_COLOR, Enum.Material.Slate)
part(exitCave, Vector3.new(23, 4, 5), Vector3.new( 0, 18, 62), ARCH_COLOR, Enum.Material.Slate)
part(exitCave, Vector3.new(5,  3, 5), Vector3.new( 0, 16, 62), Color3.fromRGB(95, 88, 78), Enum.Material.Slate)

local exitSign = part(exitCave, Vector3.new(13, 2.2, 0.3), Vector3.new(0, 22, 62), Color3.fromRGB(100, 65, 30), Enum.Material.Wood)
local esg = Instance.new("SurfaceGui"); esg.Face = Enum.NormalId.Back; esg.Parent = exitSign
local esl = Instance.new("TextLabel"); esl.Size = UDim2.new(1,0,1,0); esl.BackgroundTransparency = 1
esl.TextColor3 = Color3.fromRGB(255, 230, 140); esl.Text = "↑ Veldmere"
esl.Font = Enum.Font.GothamBold; esl.TextScaled = true; esl.Parent = esg

-- ── SpawnLocation ─────────────────────────────────────────────────────────
local spawnLoc = Instance.new("SpawnLocation")
spawnLoc.Size = Vector3.new(8, 1, 8); spawnLoc.Position = T(0, 1.5, 32)
spawnLoc.Anchored = true; spawnLoc.Neutral = true; spawnLoc.Duration = 0
spawnLoc.Material = Enum.Material.Cobblestone; spawnLoc.Color = COBBLE; spawnLoc.Parent = world

-- ── NPC ───────────────────────────────────────────────────────────────────
local function createNPC(pos, npcName, lines)
	local model = Instance.new("Model"); model.Name = npcName; model.Parent = world

	local skinColor = Color3.fromRGB(255, 210, 160)
	local shirtColor = Color3.fromRGB(160, 100, 60)
	local pantColor  = Color3.fromRGB(70, 55, 40)

	-- Body parts (all anchored)
	part(model, Vector3.new(0.9, 1.5, 0.9), pos + Vector3.new(-0.5, 0.75, 0), pantColor,  Enum.Material.SmoothPlastic)
	part(model, Vector3.new(0.9, 1.5, 0.9), pos + Vector3.new( 0.5, 0.75, 0), pantColor,  Enum.Material.SmoothPlastic)
	local torso = part(model, Vector3.new(2, 2, 1), pos + Vector3.new(0, 2.5, 0), shirtColor, Enum.Material.SmoothPlastic)
	part(model, Vector3.new(0.8, 1.8, 0.8), pos + Vector3.new(-1.4, 2.4, 0), skinColor,  Enum.Material.SmoothPlastic)
	part(model, Vector3.new(0.8, 1.8, 0.8), pos + Vector3.new( 1.4, 2.4, 0), skinColor,  Enum.Material.SmoothPlastic)
	local head = part(model, Vector3.new(1.4, 1.4, 1.4), pos + Vector3.new(0, 4.2, 0), skinColor, Enum.Material.SmoothPlastic)
	local hm = Instance.new("SpecialMesh"); hm.MeshType = Enum.MeshType.Sphere; hm.Parent = head

	-- Dialog data
	model:SetAttribute("DialogCount", #lines)
	for i, line in ipairs(lines) do
		model:SetAttribute("Line_" .. i, line)
	end

	-- ProximityPrompt on the torso
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = npcName; prompt.ActionText = "Talk"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 8; prompt.HoldDuration = 0
	prompt.Parent = torso

	-- Floating name
	local bb = Instance.new("BillboardGui"); bb.Size = UDim2.new(0, 130, 0, 24)
	bb.StudsOffset = Vector3.new(0, 2.8, 0); bb.AlwaysOnTop = false; bb.Parent = head
	local nl = Instance.new("TextLabel"); nl.Size = UDim2.new(1, 0, 1, 0)
	nl.BackgroundTransparency = 1; nl.TextColor3 = Color3.fromRGB(255, 240, 200)
	nl.Text = npcName; nl.Font = Enum.Font.GothamBold; nl.TextSize = 14
	nl.TextStrokeTransparency = 0.3; nl.Parent = bb
end

-- Aldo stands on the road near the cave entrance — greets players heading to the mine
createNPC(T(14, 0, -140), "Aldo", {
	"Welcome to Veldmere! The mines behind me hold great riches.",
	"Walk through the arch and you'll find yourself in the tunnels.",
	"Click an ore node to focus your pickaxe — it strikes 50% faster when targeted.",
	"Rarer nodes glow brighter. Purple Mythic crystals are the rarest of all.",
	"Safe travels, miner. May your pockets grow heavy!",
})

-- ── Teleporters ───────────────────────────────────────────────────────────
local cooldowns = {}
local COOLDOWN  = 2

local function tryTeleport(hit, destination)
	local char = hit.Parent
	if not char or not char:FindFirstChildWhichIsA("Humanoid") then return end
	local player = Players:GetPlayerFromCharacter(char)
	if not player then return end
	local now = os.clock()
	if now - (cooldowns[player] or 0) < COOLDOWN then return end
	cooldowns[player] = now
	char:PivotTo(CFrame.new(destination))
end

-- Trigger sits at the arch face; player warps just inside the mine north wall
local enterTele = Instance.new("Part")
enterTele.Name = "EnterTele"; enterTele.Size = Vector3.new(13, 12, 4)
enterTele.Position = T(0, 6, -167)   -- world (0,6,133)
enterTele.Anchored = true; enterTele.Transparency = 1; enterTele.CanCollide = false
enterTele.Parent = world
enterTele.Touched:Connect(function(hit)
	tryTeleport(hit, Vector3.new(0, 4, 58))
end)

-- Trigger sits just inside the mine exit arch; warps to road beside cave entrance
local exitTele = Instance.new("Part")
exitTele.Name = "ExitTele"; exitTele.Size = Vector3.new(13, 12, 4)
exitTele.Position = Vector3.new(0, 6, 65)   -- just inside mine, past the exit arch
exitTele.Anchored = true; exitTele.Transparency = 1; exitTele.CanCollide = false
exitTele.Parent = world
exitTele.Touched:Connect(function(hit)
	tryTeleport(hit, T(0, 4, -148))   -- world (0,4,152)
end)

Players.PlayerRemoving:Connect(function(player)
	cooldowns[player] = nil
end)
