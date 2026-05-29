local MemoryStoreService = game:GetService("MemoryStoreService")
local Workspace = game:GetService("Workspace")

local WEATHER_KEY = "GlobalWeather"
local WEATHER_LOCK = "GlobalWeatherLock"
local WEATHER_LIFETIME = 900 -- 15 minutes in seconds

local weatherTypes = {
	{"Normal", 1};
	{"Rain", 4};
	{"Nature", 7};
	{"Void", 15};
}

local function pickWeather(seed)
	local rng = Random.new(seed)

	-- Calculate total weight = sum of (1 / chance)
	local totalWeight = 0
	for _, weather in ipairs(weatherTypes) do
		local chance = weather[2]
		totalWeight += 1 / chance
	end

	-- Pick a random number between 0 and totalWeight
	local pick = rng:NextNumber() * totalWeight

	local cumulative = 0
	for _, weather in ipairs(weatherTypes) do
		local chance = weather[2]
		cumulative += 1 / chance
		if pick <= cumulative then
			return weather
		end
	end

	-- fallback (should never reach here)
	return weatherTypes[1]
end

-- Create or get a StringValue named 'weather' under Workspace
local weatherValue = Workspace:FindFirstChild("Weather")
if not weatherValue then
	weatherValue = Instance.new("StringValue")
	weatherValue.Name = "Weather"
	weatherValue.Parent = Workspace
end

local totemEffect = weatherValue:FindFirstChild("TotemEffect")
if not totemEffect then
	totemEffect = Instance.new("StringValue")
	totemEffect.Name = "TotemEffect"
	totemEffect.Value = "None"
	totemEffect.Parent = weatherValue
end


local function refreshWeather()
	local store = MemoryStoreService:GetSortedMap("WeatherMap")

	local success, gotLock = pcall(function()
		return store:UpdateAsync(WEATHER_LOCK, function(old)
			local now = os.time()
			if type(old) == "number" and (now - old) < WEATHER_LIFETIME then
				-- Lock is held and not expired
				return old
			else
				-- Acquire the lock by storing current timestamp
				return now
			end
		end, WEATHER_LIFETIME)
	end)

	if not success then
		print("[Weather] Failed to acquire lock due to error")
		return
	end

	if not gotLock or (gotLock and (os.time() - gotLock) >= WEATHER_LIFETIME) then
		-- If gotLock is nil or lock expired, do nothing
		print("[Weather] Lock is currently held by another server")
		return
	end

	-- We have the lock, do the weather refresh:
	local seed = os.time()
	local newWeather = pickWeather(seed)

	pcall(function()
		store:SetAsync(WEATHER_KEY, newWeather, WEATHER_LIFETIME)
		store:SetAsync("WeatherSeed", seed, WEATHER_LIFETIME)
	end)

	weatherValue.Value = newWeather[1]
	print("[Weather] Refreshed global weather to:", newWeather[1])
end

local function updateWeatherFromStore()
	local store = MemoryStoreService:GetSortedMap("WeatherMap")
	local success, storedWeather = pcall(function()
		return store:GetAsync(WEATHER_KEY)
	end)

	if success and storedWeather then
		weatherValue.Value = storedWeather[1]
	else
		refreshWeather()
	end
end

-- Initial setup
updateWeatherFromStore()

task.spawn(function()
	while true do
		local store = MemoryStoreService:GetSortedMap("WeatherMap")
		local success, lastRefresh = pcall(function()
			return store:GetAsync("WeatherSeed")
		end)

		local now = os.time()
		local needRefresh = true

		if success and lastRefresh then
			local elapsed = now - lastRefresh
			if elapsed < WEATHER_LIFETIME then
				-- timer still valid
				needRefresh = false
			elseif elapsed > WEATHER_LIFETIME then
				-- timer too far behind, reset it by refreshing weather
				needRefresh = true
			end

			-- If timestamp is too far in the future (unlikely, but possible due to clock skew)
			if lastRefresh - now > WEATHER_LIFETIME then
				-- Reset the timestamp so timer doesn't get stuck
				pcall(function()
					store:SetAsync("WeatherSeed", now, WEATHER_LIFETIME)
				end)
				needRefresh = true
			end
		end

		if weatherValue:FindFirstChild("TotemEffect") and weatherValue.TotemEffect.Value ~= "None" then
			weatherValue.Value = weatherValue.TotemEffect.Value
		else
			if needRefresh then
				refreshWeather()
			else
				updateWeatherFromStore()
			end
		end

		wait(5)
	end
end)

if weatherValue.Value == "Normal" then
	game.Lighting.ClockTime = 12.6
	
	for i,v in pairs(game.Lighting:GetChildren()) do
		if not v:IsA("Folder") then
			v:Destroy()
		end
	end
	
	for i,v in pairs(game.Lighting:FindFirstChild("Normal"):GetChildren()) do
		local Copy = v:Clone()
		Copy.Parent = game.Lighting
	end
	
	for i,v in pairs(game.Workspace.WeatherEffects:GetDescendants()) do
		if v:IsA("ParticleEmitter") or v:IsA("Beam") then
			v.Enabled = false
		end
	end
elseif weatherValue.Value == "Nature" then
	game.Lighting.ClockTime = 12.6

	for i,v in pairs(game.Lighting:GetChildren()) do
		if not v:IsA("Folder") then
			v:Destroy()
		end
	end

	for i,v in pairs(game.Lighting:FindFirstChild("Normal"):GetChildren()) do
		local Copy = v:Clone()
		Copy.Parent = game.Lighting
	end

	for i,v in pairs(game.Workspace.WeatherEffects:GetDescendants()) do
		if v:IsA("ParticleEmitter") or v:IsA("Beam") then
			v.Enabled = false
		end
	end

	for i,v in pairs(game.Workspace.WeatherEffects.Nature:GetDescendants()) do
		if v:IsA("ParticleEmitter") or v:IsA("Beam") then
			v.Enabled = true
		end
	end
elseif weatherValue.Value == "Void" then
	game.Lighting.ClockTime = 12.6

	for i,v in pairs(game.Lighting:GetChildren()) do
		if not v:IsA("Folder") then
			v:Destroy()
		end
	end

	for i,v in pairs(game.Lighting:FindFirstChild("Normal"):GetChildren()) do
		local Copy = v:Clone()
		Copy.Parent = game.Lighting
	end

	for i,v in pairs(game.Workspace.WeatherEffects:GetDescendants()) do
		if v:IsA("ParticleEmitter") or v:IsA("Beam") then
			v.Enabled = false
		end
	end

	for i,v in pairs(game.Workspace.WeatherEffects.Void:GetDescendants()) do
		if v:IsA("ParticleEmitter") or v:IsA("Beam") then
			v.Enabled = true
		end
	end
elseif weatherValue.Value == "Rain" then
	game.Lighting.ClockTime = 12.6

	for i,v in pairs(game.Lighting:GetChildren()) do
		if not v:IsA("Folder") then
			v:Destroy()
		end
	end

	for i,v in pairs(game.Lighting:FindFirstChild("Normal"):GetChildren()) do
		local Copy = v:Clone()
		Copy.Parent = game.Lighting
	end

	for i,v in pairs(game.Workspace.WeatherEffects:GetDescendants()) do
		if v:IsA("ParticleEmitter") or v:IsA("Beam") then
			v.Enabled = false
		end
	end

	for i,v in pairs(game.Workspace.WeatherEffects.Rain:GetDescendants()) do
		if v:IsA("ParticleEmitter") or v:IsA("Beam") then
			v.Enabled = true
		end
	end
end

weatherValue.Changed:Connect(function()
	if weatherValue.Value == "Normal" then
		game.Lighting.ClockTime = 12.6

		for i,v in pairs(game.Lighting:GetChildren()) do
			if not v:IsA("Folder") then
				v:Destroy()
			end
		end

		for i,v in pairs(game.Lighting:FindFirstChild("Normal"):GetChildren()) do
			local Copy = v:Clone()
			Copy.Parent = game.Lighting
		end

		for i,v in pairs(game.Workspace.WeatherEffects:GetDescendants()) do
			if v:IsA("ParticleEmitter") or v:IsA("Beam") then
				v.Enabled = false
			end
		end
	elseif weatherValue.Value == "Arcane" then
		game.Lighting.ClockTime = 12.6

		for i,v in pairs(game.Lighting:GetChildren()) do
			if not v:IsA("Folder") then
				v:Destroy()
			end
		end

		for i,v in pairs(game.Lighting:FindFirstChild("Arcane"):GetChildren()) do
			local Copy = v:Clone()
			Copy.Parent = game.Lighting
		end

		for i,v in pairs(game.Workspace.WeatherEffects:GetDescendants()) do
			if v:IsA("ParticleEmitter") or v:IsA("Beam") then
				v.Enabled = false
			end
		end

		for i,v in pairs(game.Workspace.WeatherEffects.Arcane:GetDescendants()) do
			if v:IsA("ParticleEmitter") or v:IsA("Beam") then
				v.Enabled = true
			end
		end
	elseif weatherValue.Value == "Nature" then
		game.Lighting.ClockTime = 12.6

		for i,v in pairs(game.Lighting:GetChildren()) do
			if not v:IsA("Folder") then
				v:Destroy()
			end
		end

		for i,v in pairs(game.Lighting:FindFirstChild("Normal"):GetChildren()) do
			local Copy = v:Clone()
			Copy.Parent = game.Lighting
		end

		for i,v in pairs(game.Workspace.WeatherEffects:GetDescendants()) do
			if v:IsA("ParticleEmitter") or v:IsA("Beam") then
				v.Enabled = false
			end
		end

		for i,v in pairs(game.Workspace.WeatherEffects.Nature:GetDescendants()) do
			if v:IsA("ParticleEmitter") or v:IsA("Beam") then
				v.Enabled = true
			end
		end
	elseif weatherValue.Value == "Void" then
		game.Lighting.ClockTime = 12.6

		for i,v in pairs(game.Lighting:GetChildren()) do
			if not v:IsA("Folder") then
				v:Destroy()
			end
		end

		for i,v in pairs(game.Lighting:FindFirstChild("Normal"):GetChildren()) do
			local Copy = v:Clone()
			Copy.Parent = game.Lighting
		end

		for i,v in pairs(game.Workspace.WeatherEffects:GetDescendants()) do
			if v:IsA("ParticleEmitter") or v:IsA("Beam") then
				v.Enabled = false
			end
		end

		for i,v in pairs(game.Workspace.WeatherEffects.Void:GetDescendants()) do
			if v:IsA("ParticleEmitter") or v:IsA("Beam") then
				v.Enabled = true
			end
		end
	elseif weatherValue.Value == "Rain" then
		game.Lighting.ClockTime = 12.6

		for i,v in pairs(game.Lighting:GetChildren()) do
			if not v:IsA("Folder") then
				v:Destroy()
			end
		end

		for i,v in pairs(game.Lighting:FindFirstChild("Normal"):GetChildren()) do
			local Copy = v:Clone()
			Copy.Parent = game.Lighting
		end

		for i,v in pairs(game.Workspace.WeatherEffects:GetDescendants()) do
			if v:IsA("ParticleEmitter") or v:IsA("Beam") then
				v.Enabled = false
			end
		end

		for i,v in pairs(game.Workspace.WeatherEffects.Rain:GetDescendants()) do
			if v:IsA("ParticleEmitter") or v:IsA("Beam") then
				v.Enabled = true
			end
		end
	end
end)

local totemTimerThread = nil

-- Handle TotemEffect changes
totemEffect.Changed:Connect(function()
	if totemEffect.Value ~= "None" then
		print("[Weather] TotemEffect triggered:", totemEffect.Value)
		weatherValue.Value = totemEffect.Value

		if totemTimerThread then
			task.cancel(totemTimerThread)
		end

		-- Start timer to reset TotemEffect after 5 minutes (300 seconds)
		totemTimerThread = task.delay(300, function()
			print("[Weather] TotemEffect expired, reverting.")
			totemEffect.Value = "None"
			updateWeatherFromStore()
		end)
	end
end)