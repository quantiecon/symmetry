-- Optimized Drill Collect UI Script

local ProximityPromptService = game:GetService("ProximityPromptService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Events = game.ReplicatedStorage.Events
local Visuals = game.ReplicatedStorage.Visuals
local ItemInfo = require(game.ReplicatedStorage.Modules.ItemInfo)

local CollectUI = Player:WaitForChild("PlayerGui"):WaitForChild("CollectUI")

local Drill
local isOpen = false
local conn, uiConn

local haptic = Instance.new("HapticEffect")
haptic.Name = "JumpHaptic"
haptic.Type = Enum.HapticEffectType.UIClick
haptic.Looped = false
haptic.Parent = workspace

-- Place this once at the top of your script
local activeFlyingOres = {}

RunService.RenderStepped:Connect(function(dt)
	for i = #activeFlyingOres, 1, -1 do
		local oreData = activeFlyingOres[i]
		oreData.elapsed += dt
		local t = math.clamp(oreData.elapsed / oreData.duration, 0, 1)

		local a = (1 - t)^2
		local b = 2 * (1 - t) * t
		local c = t^2
		local pos = a * oreData.start + b * oreData.control + c * oreData.target.Position

		oreData.part.Position = pos

		if t >= 1 then
			local part = oreData.part
			part.Anchored = true
			part.Transparency = 1
			game.Debris:AddItem(part, 1)
			table.remove(activeFlyingOres, i)

			local rarity = oreData.rarity
			if rarity and oreData.target then
				
				local drillExplosion = Visuals.DrillExplosionReal:Clone()
				drillExplosion.Parent = workspace
				drillExplosion.CFrame = oreData.target.CFrame
				game.Debris:AddItem(drillExplosion, 3)

				if drillExplosion:FindFirstChild(rarity) then
					for _, v in ipairs(drillExplosion:FindFirstChild(rarity):GetChildren()) do
						if v:IsA("ParticleEmitter") then
							v:Emit(v:GetAttribute("EmitCount"))
						end
					end
				end
				
				pcall(function()
					haptic:Play()
				end)

				local sound = drillExplosion:FindFirstChild(rarity .. "SFX")
				if sound then sound:Play() end
			end
		end
	end
end)

-- Optimized flyOreToPlayer using the shared RenderStepped loop
local function flyOreToPlayer(startPosition, amount, rarity)
	local oreTemplate = Visuals:FindFirstChild(rarity .. "Orb") or Visuals.PlaceholderOre
	if not oreTemplate or not Player.Character then return end

	local target = Player.Character:FindFirstChild("HumanoidRootPart")
	if not target then return end

	local ore = oreTemplate:Clone()
	ore.Anchored = true
	ore.CanCollide = false
	ore.Position = startPosition
	ore.Parent = workspace

	local duration = 0.7 + math.random() * 0.2 -- slightly randomized timing
	local randomOffset = Vector3.new(math.random(-6, 6), 0, math.random(-6, 6))
	local controlPoint = startPosition:Lerp(target.Position, 0.5) + Vector3.new(0, 8, 0) + randomOffset

	table.insert(activeFlyingOres, {
		part = ore,
		start = startPosition,
		control = controlPoint,
		target = target,
		elapsed = 0,
		duration = duration,
		rarity = rarity
	})
end

-- UI Update Connection
local function connectDrillUI(Data)
	if uiConn then uiConn:Disconnect() end

	local function updateBar()
		local collected, max = Data.Collected.Value, Data.Max.Value
		TweenService:Create(CollectUI.MainFrame.BG.Bar, TweenInfo.new(0.2), {
			Size = UDim2.new(collected / max, 0, 1, 0)
		}):Play()

		if collected ~= max then
			CollectUI.MainFrame.BG.Bar.UIGradient.Color = ColorSequence.new(Color3.fromRGB(156,159,99), Color3.fromRGB(212,236,93))
			CollectUI.MainFrame.BG.Amount.Text = collected .. "/" .. max
		else
			CollectUI.MainFrame.BG.Bar.UIGradient.Color = ColorSequence.new(Color3.fromRGB(159,97,98), Color3.fromRGB(236,83,86))
			CollectUI.MainFrame.BG.Amount.Text = "MAX"
		end
	end

	updateBar()
	uiConn = Data.Collected:GetPropertyChangedSignal("Value"):Connect(updateBar)
end

-- Prompt shown
ProximityPromptService.PromptShown:Connect(function(promptInstance)
	if promptInstance.Name ~= "Collect" then return end

	isOpen = true
	Drill = promptInstance.Parent.Parent
	local CollectPart = Drill:FindFirstChild("CollectPart")
	local Data = Drill:FindFirstChild("Data")
	if not CollectPart or not Data then return end
	
	if UIS.TouchEnabled then
		CollectUI.MainFrame:FindFirstChild("Collect").Visible = false
		CollectUI.MainFrame:FindFirstChild("MobileCollect").Visible = true
	end

	CollectUI.Enabled = true
	CollectUI.Adornee = CollectPart
	TweenService:Create(CollectUI, TweenInfo.new(0.3), { StudsOffset = Vector3.new(0, 0, 0) }):Play()

	connectDrillUI(Data)

	local function handleCollect()
		if Data.Collected.Value > 0 then
			pcall(function()
				haptic:Play()
			end)
			Events.Collect:FireServer(Drill)
			TweenService:Create(CollectUI, TweenInfo.new(0.1), { StudsOffset = Vector3.new(0, -1, 0) }):Play()
			task.delay(0.3, function()
				TweenService:Create(CollectUI, TweenInfo.new(0.2), { StudsOffset = Vector3.new(0, 0, 0) }):Play()
			end)
		end
	end

	conn = CollectUI.MainFrame.CollectButton.MouseButton1Down:Connect(handleCollect)
end)

-- Prompt hidden
ProximityPromptService.PromptHidden:Connect(function(promptInstance)
	if promptInstance.Name ~= "Collect" then return end
	isOpen = false
	Drill = nil
	CollectUI.Enabled = false
	CollectUI.Adornee = nil

	if conn then conn:Disconnect() end
	if uiConn then uiConn:Disconnect() end
end)

-- Prompt triggered
ProximityPromptService.PromptTriggered:Connect(function(promptInstance)
	if promptInstance.Name == "Collect" then
		local DrillData = promptInstance.Parent.Parent:FindFirstChild("Data")
		if DrillData and DrillData.Collected.Value > 0 then
			Events.Collect:FireServer(promptInstance.Parent.Parent)
			pcall(function()
				haptic:Play()
			end)
			
			TweenService:Create(CollectUI, TweenInfo.new(0.1), { StudsOffset = Vector3.new(0, -1, 0) }):Play()
			task.delay(0.3, function()
				TweenService:Create(CollectUI, TweenInfo.new(0.2), { StudsOffset = Vector3.new(0, 0, 0) }):Play()
			end)
		end
	elseif promptInstance.Name == "Display" then
		Events.DisplayInteract:FireServer(promptInstance.Parent.Parent)
	end
end)

-- Animate collected items
Events.NewItems.OnClientEvent:Connect(function(NewItems)
	local rootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local click = game.ReplicatedStorage.SFX.CollectClick:Clone()
	click.Parent = Player.Character
	click:Play()
	game.Debris:AddItem(click, 1)

	local pop2 = game.ReplicatedStorage.SFX.Pop2:Clone()
	pop2.Parent = Player.Character
	pop2:Play()
	game.Debris:AddItem(pop2, 1)

	local sourcePosition = (Drill and Drill:FindFirstChild("PrimaryPart")) and Drill.PrimaryPart.Position + Vector3.new(0, 2, 0) or rootPart.Position + Vector3.new(0, 2, 0)
	local i = 0
	for itemName, _ in pairs(NewItems) do
		if ItemInfo[itemName] and not Player:FindFirstChild("DisableOrbs") then
			task.delay(i * 0.1, function()
				if ItemInfo[itemName].Rarity == "Common" and math.random(1,4) == 1 then
					flyOreToPlayer(sourcePosition, 1, ItemInfo[itemName].Rarity)
				elseif ItemInfo[itemName].Rarity == "Rare" and math.random(1,3) == 1 then
					flyOreToPlayer(sourcePosition, 1, ItemInfo[itemName].Rarity)
				else
					flyOreToPlayer(sourcePosition, 1, ItemInfo[itemName].Rarity)
				end
			end)
			i += 1
		end
	end
end)

local humanoid = Player.Character:WaitForChild("Humanoid")

humanoid.StateChanged:Connect(function(_, newState)
	if newState == Enum.HumanoidStateType.Jumping then
		pcall(function()
			haptic:Play()
		end)
	end
end)