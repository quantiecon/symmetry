local Events = game.ReplicatedStorage.Events
local Visuals = game.ReplicatedStorage.Visuals
local Player = game.Players.LocalPlayer

local ItemInfo = require(game.ReplicatedStorage.Modules.ItemInfo)
local AvatarEditorService = game:GetService("AvatarEditorService")

Events.ClientFX.OnClientEvent:Connect(function(Properties)
	local Character = Player.Character
	if Properties.Type == "Quest Complete" then
		local SkillVFX = Visuals.QuestCompletion:Clone()
		SkillVFX.Parent = game.Workspace
		SkillVFX.CFrame = Properties.Specifics1:FindFirstChild("HumanoidRootPart").CFrame
		game.Debris:AddItem(SkillVFX,5)
		
		SkillVFX.Complete:Play()

		for i,v in pairs(SkillVFX:GetDescendants()) do
			if v:IsA("ParticleEmitter") then
				v:Emit(v:GetAttribute("EmitCount"))
			end
		end
	end
	
	if Properties.Type == "Worker Contract" then
		local Opening = Visuals.OpeningEffect
		
		for i,v in pairs(Opening:GetChildren()) do
			local Clone = v:Clone()
			Clone.Parent = Character:FindFirstChild("HumanoidRootPart")
			
			if Clone.Name == "Enable" then
				for _,k in pairs(Clone:GetChildren()) do
					if k:IsA("ParticleEmitter") then
						k.Enabled = true
						
						task.delay(k:GetAttribute("EmitDuration"),function()
							k.Enabled = false
						end)
					end
				end
			elseif Clone.Name == "Emit" then
				for _,k in pairs(Clone:GetChildren()) do
					if k:IsA("ParticleEmitter") then
						task.delay(k:GetAttribute("EmitDelay"),function()
							k:Emit(k:GetAttribute("EmitCount"))
						end)
					end
				end
			end
			
			game.Debris:AddItem(Clone,4)
		end
	end
	
	if Properties.Type == "Summer Pack" then
		local Opening = Visuals.OpeningEffectSummer

		for i,v in pairs(Opening:GetChildren()) do
			local Clone = v:Clone()
			Clone.Parent = Character:FindFirstChild("HumanoidRootPart")

			if Clone.Name == "Enable" then
				for _,k in pairs(Clone:GetChildren()) do
					if k:IsA("ParticleEmitter") then
						k.Enabled = true

						task.delay(k:GetAttribute("EmitDuration"),function()
							k.Enabled = false
						end)
					end
				end
			elseif Clone.Name == "Emit" then
				for _,k in pairs(Clone:GetChildren()) do
					if k:IsA("ParticleEmitter") then
						task.delay(k:GetAttribute("EmitDelay"),function()
							k:Emit(k:GetAttribute("EmitCount"))
						end)
					end
				end
			end

			game.Debris:AddItem(Clone,4)
		end
	end
	
	if Properties.Type == "WorkerSkill" then
		local SkillVFX = Visuals.workerabilityVFX:Clone()
		SkillVFX.Parent = game.Workspace
		SkillVFX.CFrame = Properties.Specifics2:FindFirstChild("HumanoidRootPart").CFrame
		game.Debris:AddItem(SkillVFX,3)
		
		for i,v in pairs(SkillVFX:GetDescendants()) do
			if v:IsA("ParticleEmitter") then
				v:Emit(v:GetAttribute("EmitCount"))
			end
		end
	end
	if Properties.Type == "PickaxeHit" then
		local SkillVFX = Visuals.ParryVFX:Clone()
		SkillVFX.Parent = game.Workspace
		SkillVFX.Position = Properties.Specifics1 + Vector3.new(0,1,0)
		game.Debris:AddItem(SkillVFX,3)
		SkillVFX:FindFirstChild("Pickaxe Strike 0"..math.random(1,4)):Play()

		for i,v in pairs(SkillVFX:GetDescendants()) do
			if v:IsA("ParticleEmitter") then
				v:Emit(v:GetAttribute("EmitCount"))
			end
		end
	end
	if Properties.Type == "PickaxeBreak" then
		local SkillVFX = Visuals.PickaxeVFX:Clone()
		SkillVFX.Parent = game.Workspace
		SkillVFX.Position = Properties.Specifics1 + Vector3.new(0,1,0)
		game.Debris:AddItem(SkillVFX,3)
		SkillVFX.PickaxeMine:Play()

		for i,v in pairs(SkillVFX["1"]:GetDescendants()) do
			if v:IsA("ParticleEmitter") then
				v:Emit(v:GetAttribute("EmitCount"))
			end
		end
	end
	if Properties.Type == "OreSpawn" then
		local SkillVFX = Visuals.PickaxeVFX:Clone()
		SkillVFX.Parent = game.Workspace
		SkillVFX.Position = Properties.Specifics1 + Vector3.new(0,1,0)
		game.Debris:AddItem(SkillVFX,3)
		SkillVFX.PickaxeMine:Play()

		for i,v in pairs(SkillVFX.spawn:GetDescendants()) do
			if v:IsA("ParticleEmitter") then
				v:Emit(v:GetAttribute("EmitCount"))
			end
		end
	end
end)

function formatnumber(number)
	local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
	int = int:reverse():gsub("(%d%d%d)", "%1,")
	return minus .. int:reverse():gsub("^,", "") .. fraction
end

Events.BroadcastOreMessage.OnClientEvent:Connect(function(data)
	if Player:FindFirstChild("DisableAnnouncments") then return end

	local formattedChance = "1 in " .. formatnumber(data.FormattedChance)

	local coloredPart = string.format(
		"<font color='%s'>%dx %s (%s)</font>",
		data.Color,
		data.Amount,
		data.OreName,
		formattedChance
	)

	local playerNameColored = string.format(
		"<font color='rgb(255,215,0)'>%s</font>",
		data.PlayerName
	)

	local fullMessage = string.format(
		"✨ %s has mined %s",
		playerNameColored,
		coloredPart
	)

	game:GetService("TextChatService").TextChannels.RBXSystem:DisplaySystemMessage(fullMessage)
end)

game:GetService("TextChatService").OnIncomingMessage = function(message)
	local props = Instance.new("TextChatMessageProperties")

	-- Check if the sender is a player
	if message.TextSource then
		local userId = message.TextSource.UserId
		local player = game.Players:GetPlayerByUserId(userId)

		if player and player:FindFirstChild("VIP")  then
			-- Append [VIP] in gold color to prefix
			local nameWithVIP = `<font color="rgb(255,215,0)">[VIP]</font> {message.PrefixText}`
			props.PrefixText = nameWithVIP
		end
	end

	-- Return the modified message properties
	return props
end

Events.BroadcastTipMessage.OnClientEvent:Connect(function(tipText)
	if Player:FindFirstChild("TipsOff") then return end
	game:GetService("TextChatService")
		:WaitForChild("TextChannels")
		:WaitForChild("RBXSystem")
		:DisplaySystemMessage("[TIP] " .. tipText)
end)

local CameraShaker = require(game.ReplicatedStorage.Modules:WaitForChild("CameraShaker"))

Events.CameraShake.OnClientEvent:Connect(function(Preset)
	local Camera = game.Workspace.CurrentCamera
	local function ShakeCamera(shakeCf)
		Camera.CFrame = Camera.CFrame * shakeCf
	end

	local renderPriority = Enum.RenderPriority.Camera.Value + 1
	local camShake = CameraShaker.new(renderPriority, ShakeCamera)

	camShake:Start()
	if Preset == "Bump" then
		camShake:Shake(CameraShaker.Presets.Bump)
	else 
		camShake:Shake(CameraShaker.Presets.Explosion)
	end
end)

task.delay(320,function()
	AvatarEditorService:PromptSetFavorite(123876394550834, Enum.AvatarItemType.Asset, true)
end)