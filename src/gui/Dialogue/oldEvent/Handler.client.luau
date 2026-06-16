local Events = game.ReplicatedStorage.Events
local ItemInfo = require(game.ReplicatedStorage.Modules.ItemInfo)
local ViewportModel = require(game.ReplicatedStorage.Modules.ViewportModel)

local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local GUI = script.Parent
local ListFrame = GUI:WaitForChild("List")
local RefreshLbl = GUI:WaitForChild("StockRefresh")

function formatnumber(number)
	local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
	int = int:reverse():gsub("(%d%d%d)", "%1,")
	return minus .. int:reverse():gsub("^,", "") .. fraction
end

Events.UpdateEventStock.OnClientEvent:Connect(function()
	
	for i,v in pairs(ListFrame:GetChildren()) do
		if v:IsA("Frame") and v.Name ~= "First" then
			v:Destroy()
		end
	end
	
	local NewStock = Events.Get:InvokeServer({"EventStock"}).EventStock
	local SplitInventory: table = string.split(NewStock, ",")
	for i,v in pairs(SplitInventory) do
		if v ~= "" then

			local OreAndAmount: table = string.split(v, ":")


			local Placeholder = script.Placeholder:Clone()
			Placeholder.Ore.Text = OreAndAmount[2].." "..OreAndAmount[1]
			Placeholder.Parent = ListFrame
			Placeholder.LayoutOrder = ItemInfo[OreAndAmount[1]].Price
			
			Placeholder.Trade.Button.MouseButton1Down:Connect(function()
				Events.EventTrade:FireServer(OreAndAmount[1])
			end)
		end
	end
end)

ProximityPromptService.PromptShown:Connect(function(promptInstance)
	if promptInstance.Name == "Event" then
		local NPC = promptInstance.Parent
		local Camera = game.Workspace.CurrentCamera

		local BlurEffect = Instance.new("BlurEffect")
		BlurEffect.Size = 0
		BlurEffect.Parent = game.Lighting

		TweenService:Create(BlurEffect,TweenInfo.new(0.8),{Size = 24}):Play()
		TweenService:Create(Camera,TweenInfo.new(0.8),{FieldOfView = 50}):Play()

		script.Parent.Visible = true
	end
end)

ProximityPromptService.PromptHidden:Connect(function(promptInstance)
	if promptInstance.Name == "Event" then
		local Camera = game.Workspace.CurrentCamera
		TweenService:Create(Camera,TweenInfo.new(0.8),{FieldOfView = 70}):Play()

		script.Parent.Visible =false

		for i,v in pairs(game.Lighting:GetChildren()) do
			if v:IsA("BlurEffect") then
				TweenService:Create(v,TweenInfo.new(0.8),{Size = 0}):Play()
				game:GetService("Debris"):AddItem(v,0.8)
			end
		end
	end
end)


-- Countdown & refresh loop
local function syncTimer()
	local timeLeft = Events.Get:InvokeServer({"EventRefresh"}).EventRefresh

	while timeLeft > 0 do
		local minutes = math.floor(timeLeft / 60)
		local seconds = timeLeft % 60
		script.Parent.StockRefresh.Text = string.format("Refreshes in: %d:%02d", minutes, seconds)
		wait(1)
		timeLeft -= 1
	end

	syncTimer()
end

syncTimer()

