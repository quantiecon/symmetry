local Player = game.Players.LocalPlayer

local Events = game.ReplicatedStorage.Events

local UIS = game:GetService("UserInputService")

local debounce = false

UIS.InputBegan:Connect(function(input,isTyping)
	if isTyping then return end
	if debounce == true then return end
	debounce = true
	
	task.delay(0.1,function()
		debounce = false
	end)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local Character = Player.Character
		if Character:FindFirstChildWhichIsA("Tool") then
			local Tool = Character:FindFirstChildWhichIsA("Tool")
			Events.ToolUse:FireServer(Tool)
		end
	end
end)