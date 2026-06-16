local Events = game.ReplicatedStorage:WaitForChild("Events")

local tips = {
	"Place drills on your plot to start mining!",
	"Collect ores frequently so you don’t hit capacity.",
	"Upgrade to better drills for faster mining.",
	"Use Luck Potions to boost rare ore chances!",
	"You can lock ores to prevent accidentally selling them.",
	"Higher rarity workers boost your luck more!",
	"Keep an eye out for rare drills in the shop!",
	"You can buy plot expansions in the exclusive shop!",
}

local function broadcastRandomTip()
	local randomTip = tips[math.random(1, #tips)]
	Events.BroadcastTipMessage:FireAllClients(randomTip)
end

-- Broadcast every 60 seconds (for example)
while true do
	task.wait(60)
	broadcastRandomTip()
end