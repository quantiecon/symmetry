local Players  = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Destroy default baseplate
local bp = workspace:FindFirstChild("Baseplate")
if bp then bp:Destroy() end

local world = Instance.new("Folder")
world.Name  = "World"
world.Parent = workspace

-- Town centre offset
local TC = Vector3.new(0, 0, 300)
local function T(x, y, z) return TC + Vector3.new(x, y, z) end

local function part(parent, size, pos, color, material, transparency)
	local p             = Instance.new("Part")
	p.Size              = size
	p.Position          = pos
	p.Anchored          = true
	p.Material          = material or Enum.Material.SmoothPlastic
	p.Color             = color
	p.CastShadow        = true
	p.Transparency      = transparency or 0
	p.TopSurface        = Enum.SurfaceType.Smooth
	p.BottomSurface     = Enum.SurfaceType.Smooth
	p.Parent            = parent
	return p
end

local function wedge(parent, size, pos, color, material)
	local p             = Instance.new("WedgePart")
	p.Size              = size
	p.Position          = pos
	p.Anchored          = true
	p.Material          = material or Enum.Material.SmoothPlastic
	p.Color             = color
	p.TopSurface        = Enum.SurfaceType.Smooth
	p.BottomSurface     = Enum.SurfaceType.Smooth
	p.Parent            = parent
	return p
end

-- ── Ground plane ────────────────────────────────────────────────────────────
local COBBLE  = Color3.fromRGB(140, 130, 118)
local STONE   = Color3.fromRGB(110, 104, 96)
local CREAM   = Color3.fromRGB(237, 224, 200)
local TERRACOTTA = Color3.fromRGB(190, 98, 60)
local SHUTTER = Color3.fromRGB(72, 108, 72)
local WOOD    = Color3.fromRGB(130, 90, 55)
local DARK    = Color3.fromRGB(40, 36, 32)

-- Ground covers town + path to mine entrance (Z 300→-168 in world = 468 studs)
part(world, Vector3.new(280, 2, 520), Vector3.new(0, -1, 96), COBBLE, Enum.Material.Cobblestone)

-- ── Piazza (town square) ──────────────────────────────────────────────────
local piazza = Instance.new("Folder"); piazza.Name = "Piazza"; piazza.Parent = world

-- Base square
part(piazza, Vector3.new(82, 0.6, 82), T(0, 0.3, 0), Color3.fromRGB(160, 150, 136), Enum.Material.Cobblestone)

-- Cross path lighter stone
part(piazza, Vector3.new(14, 0.7, 82), T(0, 0.35, 0), Color3.fromRGB(185, 175, 160), Enum.Material.SmoothPlastic)
part(piazza, Vector3.new(82, 0.7, 14), T(0, 0.35, 0), Color3.fromRGB(185, 175, 160), Enum.Material.SmoothPlastic)

-- Corner accent stones
for _, cx in {-30, 30} do
	for _, cz in {-30, 30} do
		part(piazza, Vector3.new(16, 0.8, 16), T(cx, 0.4, cz), Color3.fromRGB(195, 182, 165), Enum.Material.Cobblestone)
	end
end

-- ── Fountain ──────────────────────────────────────────────────────────────
local fountain = Instance.new("Folder"); fountain.Name = "Fountain"; fountain.Parent = world

-- Outer pool ring
part(fountain, Vector3.new(14, 1.4, 14), T(0, 0.7, 0), STONE, Enum.Material.Marble)
part(fountain, Vector3.new(10, 1.5, 10), T(0, 0.75, 0), Color3.fromRGB(150, 195, 215), Enum.Material.Neon, 0.6) -- water

-- Centre pillar
part(fountain, Vector3.new(2, 4.5, 2), T(0, 2.25, 0), STONE, Enum.Material.Marble)

-- Upper basin
part(fountain, Vector3.new(7, 0.8, 7), T(0, 4.8, 0), STONE, Enum.Material.Marble)
part(fountain, Vector3.new(4, 0.5, 4), T(0, 5.2, 0), Color3.fromRGB(150, 195, 215), Enum.Material.Neon, 0.5)

-- Spire top
part(fountain, Vector3.new(0.6, 1.8, 0.6), T(0, 6.4, 0), STONE, Enum.Material.Marble)

-- Particle spray
local sprayPart     = Instance.new("Part")
sprayPart.Size      = Vector3.new(0.1, 0.1, 0.1)
sprayPart.Position  = T(0, 7, 0)
sprayPart.Anchored  = true
sprayPart.Transparency = 1
sprayPart.CanCollide = false
sprayPart.Parent    = fountain

local att = Instance.new("Attachment"); att.Parent = sprayPart
local pe              = Instance.new("ParticleEmitter")
pe.Color              = ColorSequence.new(Color3.fromRGB(180, 220, 255))
pe.LightEmission      = 0.6
pe.Size               = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.12),
	NumberSequenceKeypoint.new(1, 0),
})
pe.Speed              = NumberRange.new(8, 14)
pe.Rate               = 60
pe.Lifetime           = NumberRange.new(0.8, 1.5)
pe.SpreadAngle        = Vector2.new(25, 25)
pe.Rotation           = NumberRange.new(0, 360)
pe.RotSpeed           = NumberRange.new(-90, 90)
pe.Parent             = att

local waterLight      = Instance.new("PointLight")
waterLight.Range      = 14
waterLight.Brightness = 1.2
waterLight.Color      = Color3.fromRGB(140, 200, 255)
waterLight.Parent     = sprayPart

-- ── Buildings ─────────────────────────────────────────────────────────────
local function building(cx, cz, w, d, h)
	local folder = Instance.new("Folder"); folder.Name = "Building"; folder.Parent = world
	local bx, bz = T(cx, h/2 + 0.6, cz).X, T(cx, h/2 + 0.6, cz).Z
	local by = h/2 + 0.6

	-- Body
	part(folder, Vector3.new(w, h, d), Vector3.new(bx, by, bz), CREAM, Enum.Material.SmoothPlastic)

	-- Terracotta roof (wedge pair)
	local rh = 3.5
	local r1 = wedge(folder, Vector3.new(w, rh, d/2), Vector3.new(bx, h + 0.6 + rh/2, bz - d/4), TERRACOTTA, Enum.Material.SmoothPlastic)
	r1.CFrame = CFrame.new(r1.Position) * CFrame.Angles(0, 0, 0)
	local r2 = wedge(folder, Vector3.new(w, rh, d/2), Vector3.new(bx, h + 0.6 + rh/2, bz + d/4), TERRACOTTA, Enum.Material.SmoothPlastic)
	r2.CFrame = CFrame.new(r2.Position) * CFrame.Angles(0, math.pi, 0)

	-- Windows (2 per front/back face)
	local winColor = Color3.fromRGB(180, 210, 230)
	for _, fz in {cz - d/2 - 0.05, cz + d/2 + 0.05} do
		local wy = TC.Y + h * 0.6 + 0.6
		for _, wx in {cx - w/4, cx + w/4} do
			local wp = part(folder, Vector3.new(2.2, 2.8, 0.18), Vector3.new(TC.X + wx, wy, TC.Z + fz), winColor, Enum.Material.Glass)
			wp.Transparency = 0.5

			-- shutters
			part(folder, Vector3.new(0.9, 2.8, 0.22), Vector3.new(TC.X + wx - 1.6, wy, TC.Z + fz), SHUTTER, Enum.Material.Wood)
			part(folder, Vector3.new(0.9, 2.8, 0.22), Vector3.new(TC.X + wx + 1.6, wy, TC.Z + fz), SHUTTER, Enum.Material.Wood)
		end
	end

	-- Arched door (front face toward piazza, so face with smaller Z)
	local doorFaceZ = cz - d/2 - 0.1
	part(folder, Vector3.new(2.4, 3.8, 0.22), Vector3.new(TC.X + cx, TC.Y + 2.5, TC.Z + doorFaceZ), DARK, Enum.Material.Wood)

	-- Door lamp
	local lamp = part(folder, Vector3.new(0.3, 0.3, 0.3), Vector3.new(TC.X + cx, TC.Y + 5, TC.Z + doorFaceZ - 0.3), Color3.fromRGB(255, 220, 140), Enum.Material.Neon)
	lamp.Transparency = 0.2
	local dl = Instance.new("PointLight"); dl.Range = 12; dl.Brightness = 1.5
	dl.Color = Color3.fromRGB(255, 210, 130); dl.Parent = lamp
end

building(-32, -24, 22, 18, 14)
building( 32, -24, 22, 18, 14)
building(-32,  24, 22, 18, 12)
building( 32,  24, 22, 18, 12)
building(-38,   0, 18, 16, 11)
building( 38,   0, 18, 16, 11)

-- ── Street lamps ──────────────────────────────────────────────────────────
local function streetLamp(px, pz)
	local lf = Instance.new("Folder"); lf.Name = "Lamp"; lf.Parent = world
	part(lf, Vector3.new(0.5, 7, 0.5), T(px, 3.6, pz), STONE, Enum.Material.SmoothPlastic)
	local head = part(lf, Vector3.new(1, 0.6, 1), T(px, 7.3, pz), DARK, Enum.Material.SmoothPlastic)
	local glow = part(lf, Vector3.new(0.5, 0.5, 0.5), T(px, 7, pz), Color3.fromRGB(255, 220, 140), Enum.Material.Neon)
	glow.Transparency = 0.1
	local pl = Instance.new("PointLight"); pl.Range = 22; pl.Brightness = 1.8
	pl.Color = Color3.fromRGB(255, 210, 130); pl.Parent = glow
end

streetLamp(-34, -34)
streetLamp( 34, -34)
streetLamp(-34,  34)
streetLamp( 34,  34)
streetLamp( -8, -68)
streetLamp(  8, -68)
streetLamp( -8, -110)
streetLamp(  8, -110)
streetLamp( -8, -148)
streetLamp(  8, -148)

-- ── North road to mine ─────────────────────────────────────────────────────
-- Road runs from piazza south edge (world Z=255) to cave entrance (world Z=132)
-- In town-local coords: from cz=-45 to cz=-168
part(world, Vector3.new(18, 1.2, 126), T(0, 0.6, -107), Color3.fromRGB(155, 145, 130), Enum.Material.Cobblestone)

-- Road edges / kerb strips
part(world, Vector3.new(1.5, 1.4, 126), T(-9.75, 0.7, -107), STONE, Enum.Material.Cobblestone)
part(world, Vector3.new(1.5, 1.4, 126), T( 9.75, 0.7, -107), STONE, Enum.Material.Cobblestone)

-- ── Cave entrance arch ────────────────────────────────────────────────────
local cave = Instance.new("Folder"); cave.Name = "CaveEntrance"; cave.Parent = world

local archColor = Color3.fromRGB(80, 75, 68)
-- Left pillar
part(cave, Vector3.new(5, 16, 5), T(-9,  8, -168), archColor, Enum.Material.Slate)
-- Right pillar
part(cave, Vector3.new(5, 16, 5), T( 9,  8, -168), archColor, Enum.Material.Slate)
-- Top lintel
part(cave, Vector3.new(23, 4, 5), T( 0, 18, -168), archColor, Enum.Material.Slate)
-- Arch keystone accent
part(cave, Vector3.new(5, 3, 5), T(0, 16, -168), Color3.fromRGB(95, 88, 78), Enum.Material.Slate)

-- Dark cave void fill so it looks like a cave
part(cave, Vector3.new(13, 14, 4), T(0, 7.5, -170), Color3.fromRGB(8, 8, 10), Enum.Material.SmoothPlastic)

-- "MINIERA" sign
local signBoard = part(cave, Vector3.new(13, 2.5, 0.3), T(0, 22, -168), Color3.fromRGB(100, 65, 30), Enum.Material.Wood)
local sg        = Instance.new("SurfaceGui")
sg.Face         = Enum.NormalId.Front
sg.Parent       = signBoard
local sl        = Instance.new("TextLabel")
sl.Size         = UDim2.new(1, 0, 1, 0)
sl.BackgroundTransparency = 1
sl.TextColor3   = Color3.fromRGB(255, 230, 140)
sl.Text         = "MINIERA"
sl.Font         = Enum.Font.GothamBold
sl.TextScaled   = true
sl.Parent       = sg

-- Torches on pillars
local function torch(px, pz)
	local tf = Instance.new("Folder"); tf.Name = "Torch"; tf.Parent = cave
	part(tf, Vector3.new(0.4, 1.2, 0.4), T(px, 5.5, pz), WOOD, Enum.Material.Wood)
	local flame = part(tf, Vector3.new(0.3, 0.3, 0.3), T(px, 6.3, pz), Color3.fromRGB(255, 160, 40), Enum.Material.Neon)
	flame.Transparency = 0.1
	local fl = Instance.new("PointLight"); fl.Range = 16; fl.Brightness = 2
	fl.Color = Color3.fromRGB(255, 160, 40); fl.Parent = flame
end

torch(-12, -165)
torch( 12, -165)
torch(-12, -171)
torch( 12, -171)

-- Torches along road
for i = 1, 4 do
	local rz = -50 - i * 26
	torch(-11, rz)
	torch( 11, rz)
end

-- ── Exit arch inside mine (world Z ≈ 54, mine-local Z=54) ─────────────────
local exitCave = Instance.new("Folder"); exitCave.Name = "MineExit"; exitCave.Parent = world

part(exitCave, Vector3.new(5, 16, 5), Vector3.new(-9,  8, 54), archColor, Enum.Material.Slate)
part(exitCave, Vector3.new(5, 16, 5), Vector3.new( 9,  8, 54), archColor, Enum.Material.Slate)
part(exitCave, Vector3.new(23, 4, 5), Vector3.new( 0, 18, 54), archColor, Enum.Material.Slate)
part(exitCave, Vector3.new(13, 14, 4), Vector3.new(0, 7.5, 55.5), Color3.fromRGB(8, 8, 10), Enum.Material.SmoothPlastic)

-- "↑ Veldmere" sign
local exitSign = part(exitCave, Vector3.new(13, 2.2, 0.3), Vector3.new(0, 22, 54), Color3.fromRGB(100, 65, 30), Enum.Material.Wood)
local esg      = Instance.new("SurfaceGui"); esg.Face = Enum.NormalId.Back; esg.Parent = exitSign
local esl      = Instance.new("TextLabel")
esl.Size       = UDim2.new(1, 0, 1, 0)
esl.BackgroundTransparency = 1
esl.TextColor3 = Color3.fromRGB(255, 230, 140)
esl.Text       = "↑ Veldmere"
esl.Font       = Enum.Font.GothamBold
esl.TextScaled = true
esl.Parent     = esg

-- ── SpawnLocation in piazza ───────────────────────────────────────────────
local spawnLoc          = Instance.new("SpawnLocation")
spawnLoc.Size           = Vector3.new(8, 1, 8)
spawnLoc.Position       = T(0, 1.5, 32)
spawnLoc.Anchored       = true
spawnLoc.Neutral        = true
spawnLoc.Duration       = 0
spawnLoc.Material       = Enum.Material.Cobblestone
spawnLoc.Color          = COBBLE
spawnLoc.Parent         = world

-- ── Teleporters ───────────────────────────────────────────────────────────
local cooldowns = {}

local function canTele(player)
	local last = cooldowns[player] or 0
	return os.clock() - last >= 3
end

-- Enter mine: invisible wall at cave mouth → send to mine interior
local enterTele         = Instance.new("Part")
enterTele.Name          = "EnterTele"
enterTele.Size          = Vector3.new(13, 16, 1)
enterTele.Position      = T(0, 8, -172)
enterTele.Anchored      = true
enterTele.Transparency  = 1
enterTele.CanCollide    = false
enterTele.Parent        = world

enterTele.Touched:Connect(function(hit)
	local char = hit.Parent
	if not char then return end
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	if not hum then return end
	local player = Players:GetPlayerFromCharacter(char)
	if not player then return end
	if not canTele(player) then return end
	cooldowns[player] = os.clock()
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then hrp.CFrame = CFrame.new(0, 4, 40) end
end)

-- Exit mine: invisible wall at exit arch → send back to town
local exitTele          = Instance.new("Part")
exitTele.Name           = "ExitTele"
exitTele.Size           = Vector3.new(13, 16, 1)
exitTele.Position       = Vector3.new(0, 8, 56)
exitTele.Anchored       = true
exitTele.Transparency   = 1
exitTele.CanCollide     = false
exitTele.Parent         = world

exitTele.Touched:Connect(function(hit)
	local char = hit.Parent
	if not char then return end
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	if not hum then return end
	local player = Players:GetPlayerFromCharacter(char)
	if not player then return end
	if not canTele(player) then return end
	cooldowns[player] = os.clock()
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then hrp.CFrame = CFrame.new(T(0, 4, -145).X, T(0, 4, -145).Y, T(0, 4, -145).Z) end
end)

Players.PlayerRemoving:Connect(function(player)
	cooldowns[player] = nil
end)
