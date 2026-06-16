local Events = game.ReplicatedStorage.Events
local Visuals = game.ReplicatedStorage.Visuals

local TweenService = game:GetService("TweenService")

local FirstTimePlaying = Events.Get:InvokeServer({"FirstTimePlaying"}).FirstTimePlaying
local Stage = script.Parent.Stage
local Instruction = script.Parent.Instruction

local Player = game.Players.LocalPlayer

local Arrows = {}

local currentTypingToken = nil

function TypewriterEffect(textLabel, fullText, charDelay)
	task.spawn(function()
		-- Invalidate any previous typing coroutine
		currentTypingToken = tick()
		local token = currentTypingToken

		textLabel:SetAttribute("Typing", true)
		textLabel.Text = ""

		for i = 1, #fullText do
			-- Cancel if a new token has been set
			if token ~= currentTypingToken then
				return
			end

			textLabel.Text = string.sub(fullText, 1, i)
			task.wait(charDelay or 0.05)
		end

		-- Only unset Typing if this is still the latest task
		if token == currentTypingToken then
			textLabel:SetAttribute("Typing", nil)
		end
	end)
end

function CreateArrow(Destination)
	local Arrow = Visuals.DestinationMarker:Clone()
	table.insert(Arrows, Arrow.PlayerPart)
	table.insert(Arrows, Arrow.DestinationPart)
	
	Arrow.PlayerPart.CFrame = Player.Character:FindFirstChild("HumanoidRootPart").CFrame

	local Weld = Instance.new("WeldConstraint")
	Weld.Parent = Arrow.PlayerPart
	Weld.Part0 = Player.Character:FindFirstChild("HumanoidRootPart")
	Weld.Part1 = Arrow.PlayerPart
	
	Arrow.PlayerPart.Parent = game.Workspace

	Arrow.DestinationPart.CFrame = Destination
	Arrow.DestinationPart.Anchored = true
	Arrow.DestinationPart.Parent = game.Workspace
	
	
	Arrow:Destroy()
end

function ClearArrows()
	for _, part in ipairs(Arrows) do
		if part and part.Parent then
			part:Destroy()
		end
	end
	table.clear(Arrows)
end

local function applyClickTween(button)
	local origPos = button.Position
	local down = TweenService:Create(button, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = origPos + UDim2.new(0, 0, 0.02, 0)
	})
	local up = TweenService:Create(button, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = origPos
	})
	button.MouseButton1Click:Connect(function()
		down:Play()
		down.Completed:Wait()
		up:Play()
	end)
	if button:FindFirstChild("Click") then button.Click:Play() end
end

local function applyHover(button, scale, time)
	scale = scale or 1.1
	time = time or 0.2
	if not button:IsA("GuiButton") then return end

	local origSize = button.Size
	local enlarged = UDim2.new(origSize.X.Scale * scale, origSize.X.Offset * scale, origSize.Y.Scale * scale, origSize.Y.Offset * scale)
	local enlarge = TweenService:Create(button, TweenInfo.new(time, Enum.EasingStyle.Quad), {Size = enlarged})
	local shrink = TweenService:Create(button, TweenInfo.new(time, Enum.EasingStyle.Quad), {Size = origSize})

	button.MouseEnter:Connect(function() enlarge:Play() end)
	button.MouseLeave:Connect(function() shrink:Play() end)
end

local function setupTween(originalSizeAttr)
	local function tweenOpen(frame)
		frame.Size = frame:GetAttribute(originalSizeAttr)
		frame.Position = UDim2.new(0.5, 0, 0.6, 0)
		frame.Visible = true
		TweenService:Create(frame, TweenInfo.new(0.2), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
	end

	local function tweenClose(frame)
		local originalSize = frame:GetAttribute(originalSizeAttr)
		if not originalSize then return end
		TweenService:Create(frame, TweenInfo.new(0.05), {Size = originalSize - UDim2.new(0.2, 0, 0.2, 0)}):Play()
		task.delay(0.05, function()
			frame.Size = originalSize
			frame.Visible = false
		end)
	end

	return tweenOpen, tweenClose
end

local panel = script.Parent.StarterBundle
panel:SetAttribute("OriginalSize", panel.Size)
local openTween, closeTween = setupTween("OriginalSize")

script.Parent.StarterBundle.Close.ImageButton.MouseButton1Down:Connect(function()
	closeTween(panel)
end)

applyHover(script.Parent.StarterBundle.Close)

Stage.Changed:Connect(function()
	ClearArrows()
	if Stage.Value == 1 then
		local Plot
		
		for i,v in pairs(game.Workspace.Plots:GetChildren()) do
			if v:FindFirstChild("Owner") and v:FindFirstChild("Owner").Value == Player.Name then
				Plot = v
			end
		end
		Instruction.Visible = true
		TypewriterEffect(Instruction,"Place a drill",0.07)
		
		CreateArrow(Plot.CFrame)
	elseif Stage.Value == 2 then
		local PlotDrills = game.Workspace:FindFirstChild(Player.Name.."Drills")
		
		if PlotDrills then
			local drills = PlotDrills:GetChildren()
			if #drills > 0 then
				local randomDrill = drills[math.random(1, #drills)]

				Instruction.Visible = true
				TypewriterEffect(Instruction,"Collect from your drill",0.07)
				
				CreateArrow(randomDrill:FindFirstChild("CollectPart").CFrame)
			end
		end
	elseif Stage.Value == 3 then
		Instruction.Visible = true
		TypewriterEffect(Instruction,"Sell your ores! You can teleport to the shop with the buttons above!",0.03)

		CreateArrow(game.Workspace.NPCs.Shop.CFrame)
	elseif Stage.Value == 4 then
		Instruction.Visible = true
		TypewriterEffect(Instruction,"Buy another drill, higher tier drills may not always be in stock! Look out for them!",0.03)

		CreateArrow(game.Workspace.NPCs.DrillShop.CFrame)
	elseif Stage.Value == 5 then
		Instruction.Visible = true
		TypewriterEffect(Instruction,"Welcome to Drill It!",0.07)
		Events.TutorialComplete:FireServer(Player)
		task.wait(3)
		Instruction.Visible = false
		openTween(panel)
		
		
	end
end)

Events.PlaceDrill.OnClientEvent:Connect(function()
	if Stage.Value == 1 then
		Stage.Value = 2
	end
end)

Events.NewItems.OnClientEvent:Connect(function()
	if Stage.Value == 2 then
		Stage.Value = 3
	end
end)

Events.Profit.OnClientEvent:Connect(function()
	if Stage.Value == 3 then
		Stage.Value = 4
	end
end)

Events.NewDrill.OnClientEvent:Connect(function()
	if Stage.Value == 4 then
		Stage.Value = 5
	end
end)


if FirstTimePlaying == true then
	Stage.Value = 1
end