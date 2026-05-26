local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- ── Dialog UI ─────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "DialogGui"; gui.ResetOnSpawn = false; gui.Enabled = false
gui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 520, 0, 148)
frame.Position = UDim2.new(0.5, -260, 1, -188)
frame.BackgroundColor3 = Color3.fromRGB(18, 14, 10)
frame.BackgroundTransparency = 0.08
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 12); corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(180, 150, 80); stroke.Thickness = 1.5
stroke.Transparency = 0.4; stroke.Parent = frame

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, -20, 0, 28); nameLabel.Position = UDim2.new(0, 12, 0, 10)
nameLabel.BackgroundTransparency = 1
nameLabel.TextColor3 = Color3.fromRGB(255, 210, 70)
nameLabel.Font = Enum.Font.GothamBold; nameLabel.TextSize = 17
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Parent = frame

local bodyLabel = Instance.new("TextLabel")
bodyLabel.Size = UDim2.new(1, -24, 0, 76); bodyLabel.Position = UDim2.new(0, 12, 0, 42)
bodyLabel.BackgroundTransparency = 1
bodyLabel.TextColor3 = Color3.fromRGB(232, 224, 210)
bodyLabel.Font = Enum.Font.Gotham; bodyLabel.TextSize = 15
bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
bodyLabel.TextWrapped = true; bodyLabel.Text = ""
bodyLabel.Parent = frame

local hintLabel = Instance.new("TextLabel")
hintLabel.Size = UDim2.new(1, -16, 0, 20); hintLabel.Position = UDim2.new(0, 8, 1, -26)
hintLabel.BackgroundTransparency = 1
hintLabel.TextColor3 = Color3.fromRGB(150, 140, 118)
hintLabel.Font = Enum.Font.Gotham; hintLabel.TextSize = 13
hintLabel.TextXAlignment = Enum.TextXAlignment.Right
hintLabel.Parent = frame

-- ── State ─────────────────────────────────────────────────────────────────
local activeNPC    = nil
local activePrompt = nil
local lineIndex    = 0

local function closeDialog()
	gui.Enabled = false
	if activePrompt then activePrompt.Enabled = true end
	activeNPC    = nil
	activePrompt = nil
	lineIndex    = 0
end

local function showLine(npc, index)
	local count = npc:GetAttribute("DialogCount") or 0
	if index > count then closeDialog(); return end
	nameLabel.Text = npc.Name
	bodyLabel.Text = npc:GetAttribute("Line_" .. index) or ""
	hintLabel.Text = index < count and "[E]  Continue" or "[E]  Close"
	gui.Enabled    = true
	lineIndex      = index
end

local function openDialog(npc, prompt)
	-- Re-enable any prompt from a previous conversation that got interrupted
	if activePrompt and activePrompt ~= prompt then
		activePrompt.Enabled = true
	end
	activeNPC    = npc
	activePrompt = prompt
	prompt.Enabled = false   -- hide the prompt bubble while talking
	showLine(npc, 1)
end

local function advance()
	if activeNPC then showLine(activeNPC, lineIndex + 1) end
end

-- ── Connect to ProximityPrompts ────────────────────────────────────────────
local function connectPrompt(prompt)
	-- Walk up to find the NPC model (prompt → Part → Model)
	local npc = prompt.Parent and prompt.Parent.Parent
	if not npc or not npc:IsA("Model") then return end
	if not npc:GetAttribute("DialogCount") then return end

	prompt.Triggered:Connect(function()
		if activeNPC == npc then
			advance()
		else
			openDialog(npc, prompt)
		end
	end)
end

-- Catch prompts already in workspace and any added later
local function scanDescendants(root)
	for _, d in root:GetDescendants() do
		if d:IsA("ProximityPrompt") then connectPrompt(d) end
	end
end

workspace.DescendantAdded:Connect(function(d)
	if d:IsA("ProximityPrompt") then connectPrompt(d) end
end)

scanDescendants(workspace)

-- E key advances dialog when it is open
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.E and activeNPC then advance() end
end)

-- Clicking the dialog frame also advances
frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then advance() end
end)
