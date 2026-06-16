local Events = game.ReplicatedStorage.Events
local ListFrame = script.Parent.ListFrame

local QuestData = require(game.ReplicatedStorage.Modules.QuestInfo)

Events.UpdateQuests.OnClientEvent:Connect(function()
	local DailyQuests = Events.Get:InvokeServer({"DailyQuests"}).DailyQuests
	local OneTimeQuests = Events.Get:InvokeServer({"OneTimeQuests"}).OneTimeQuests

	local dailyQuestName, dailyProgress, dailyGoal = string.match(DailyQuests, "^(.-):(%d+),(%d+)$")
	local oneTimeQuestName, oneTimeProgress, oneTimeGoal = string.match(OneTimeQuests, "^(.-):(%d+),(%d+)$")

	-- Clear previous quest frames
	for _, v in pairs(ListFrame:GetChildren()) do
		if v:IsA("Frame") and v.Name ~= "First" then
			v:Destroy()
		end
	end

	-- Add Daily Quest
	if dailyQuestName then
		local Placeholder = script.Placeholder:Clone()
		Placeholder.Name = dailyQuestName
		Placeholder.QuestName.Text = "✨"..dailyQuestName.." [DAILY]"
		Placeholder.QuestProgress.Text = "("..dailyProgress.."/"..dailyGoal..")"
		if QuestData[dailyQuestName] then
			if QuestData[dailyQuestName].Reward == "Gems" then
				Placeholder.QuestProgress.Text = "("..dailyProgress.."/"..dailyGoal..")".." +"..QuestData[dailyQuestName].Amount.." "..QuestData[dailyQuestName].Reward
			else
				Placeholder.QuestProgress.Text = "("..dailyProgress.."/"..dailyGoal..")".." +"..QuestData[dailyQuestName].Reward
			end
		end
		Placeholder.Parent = ListFrame
		Placeholder.LayoutOrder = 2
	end

	-- Add One-Time Quest
	if oneTimeQuestName then
		local Placeholder = script.Placeholder:Clone()
		Placeholder.Name = oneTimeQuestName
		Placeholder.QuestName.Text = "✨"..oneTimeQuestName.." [MAIN]"
		Placeholder.QuestProgress.Text = "("..oneTimeProgress.."/"..oneTimeGoal..")"
		if QuestData[oneTimeQuestName] then
			if QuestData[oneTimeQuestName].Reward == "Gems" then
				Placeholder.QuestProgress.Text = "("..dailyProgress.."/"..dailyGoal..")".." +"..QuestData[oneTimeQuestName].Amount.." "..QuestData[oneTimeQuestName].Reward
			else
				Placeholder.QuestProgress.Text = "("..dailyProgress.."/"..dailyGoal..")".." +"..QuestData[oneTimeQuestName].Reward
			end
		end
		Placeholder.Parent = ListFrame
		Placeholder.LayoutOrder = 1
	end
end)

--[[local scrollingFrame = script.Parent.ListFrame
local layout = scrollingFrame:FindFirstChildOfClass("UIListLayout")

local function updateCanvasSize()
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
end

-- Listen for children being added or removed
scrollingFrame.ChildAdded:Connect(updateCanvasSize)
scrollingFrame.ChildRemoved:Connect(updateCanvasSize)

-- Watch for size changes in children (e.g. if a child resizes)
for _, child in pairs(scrollingFrame:GetChildren()) do
	if child:IsA("GuiObject") then
		child:GetPropertyChangedSignal("Size"):Connect(updateCanvasSize)
	end
end

-- Optional: Connect this dynamically for new children too
scrollingFrame.ChildAdded:Connect(function(child)
	if child:IsA("GuiObject") then
		child:GetPropertyChangedSignal("Size"):Connect(updateCanvasSize)
	end
end)

-- Initial setup
updateCanvasSize() --]]