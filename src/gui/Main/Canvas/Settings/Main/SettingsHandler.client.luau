local Player = game.Players.LocalPlayer

local Events = game.ReplicatedStorage.Events

Player.ChildAdded:Connect(function(child)
	if child.Name == "MusicOff" then
		local Music = game.Workspace:FindFirstChild("BG")
		Music.Playing = false
	end
end)

Player.ChildRemoved:Connect(function(child)
	if child.Name == "MusicOff" then
		local Music = game.Workspace:FindFirstChild("BG")
		Music.Playing = true
	end
end)

for i,v in pairs(script.Parent.Container:GetChildren()) do
	if v:IsA("Frame") then
		v:FindFirstChild("On").Main.Home.Text = tostring(Events.Get:InvokeServer({v.Name})[v.Name])
		
		if v:FindFirstChild("On").Main.Home.Text == "On" then
			v:FindFirstChild("On").Backing.BackgroundColor3 = Color3.new(0.0980392, 0.529412, 0.4)
			v:FindFirstChild("On").Main.UIGradient.Color = ColorSequence.new(Color3.new(0.176471, 0.980392, 0.819608),Color3.new(0.196078, 0.980392, 0.576471))
		else
			v:FindFirstChild("On").Backing.BackgroundColor3 = Color3.new(0.529412, 0.0862745, 0.0941176)
			v:FindFirstChild("On").Main.UIGradient.Color = ColorSequence.new(Color3.new(0.980392, 0.176471, 0.192157),Color3.new(0.980392, 0.203922, 0.203922))
		end
		
		v.On.MouseButton1Click:Connect(function()
			v.On.Click:Play()
			if v:FindFirstChild("On").Main.Home.Text == "On" then
				v:FindFirstChild("On").Main.Home.Text = "Off"
				
				v:FindFirstChild("On").Backing.BackgroundColor3 = Color3.new(0.529412, 0.0862745, 0.0941176)
				v:FindFirstChild("On").Main.UIGradient.Color = ColorSequence.new(Color3.new(0.980392, 0.176471, 0.192157),Color3.new(0.980392, 0.203922, 0.203922))
			else
				v:FindFirstChild("On").Main.Home.Text = "On"
			
				v:FindFirstChild("On").Backing.BackgroundColor3 = Color3.new(0.0980392, 0.529412, 0.4)
				v:FindFirstChild("On").Main.UIGradient.Color = ColorSequence.new(Color3.new(0.176471, 0.980392, 0.819608),Color3.new(0.196078, 0.980392, 0.576471))
			end
			
			Events.Settings:FireServer(v.Name)
		end)
	end
end

Events.LowGraphicsMode.OnClientEvent:Connect(function(Action)
	for _, p in ipairs(workspace:GetDescendants()) do
		if p:IsA("ParticleEmitter") then
			-- Store the original values ONCE
			if not p:GetAttribute("DefaultRate") and typeof(p.Rate) == "number" then
				p:SetAttribute("DefaultRate", p.Rate)
			end
			if not p:GetAttribute("DefaultLifetimeMin") and typeof(p.Lifetime) == "NumberRange" then
				p:SetAttribute("DefaultLifetimeMin", p.Lifetime.Min)
				p:SetAttribute("DefaultLifetimeMax", p.Lifetime.Max)
			end
		end
	end

	if Action == "On" then
		print("low graphics mode on")
		for _, p in ipairs(workspace:GetDescendants()) do
			if p:IsA("ParticleEmitter") then
				local defaultRate = p:GetAttribute("DefaultRate")
				local lifetimeMin = p:GetAttribute("DefaultLifetimeMin")
				local lifetimeMax = p:GetAttribute("DefaultLifetimeMax")

				if typeof(defaultRate) == "number" and typeof(lifetimeMin) == "number" and typeof(lifetimeMax) == "number" then
					p.Rate = defaultRate * 0.2
					p.Lifetime = NumberRange.new(lifetimeMin, lifetimeMax)
				end
			end
		end
	elseif Action == "Off" then
		print("low graphiocs off")
	
		for _, p in ipairs(workspace:GetDescendants()) do
			if p:IsA("ParticleEmitter") then
				local defaultRate = p:GetAttribute("DefaultRate")
				local lifetimeMin = p:GetAttribute("DefaultLifetimeMin")
				local lifetimeMax = p:GetAttribute("DefaultLifetimeMax")

				if typeof(defaultRate) == "number" and typeof(lifetimeMin) == "number" and typeof(lifetimeMax) == "number" then
					p.Rate = defaultRate
					p.Lifetime = NumberRange.new(lifetimeMin, lifetimeMax)
				end
			end
		end
	end
end)