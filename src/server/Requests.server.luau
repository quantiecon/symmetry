local ReplicatedStorage = game.ReplicatedStorage
local Requests = ReplicatedStorage.Events
local PlayerData = game.ServerStorage["PlayerData"]

local HttpService = game:GetService("HttpService")
local JsonEncode = HttpService.JSONEncode

function Requests.Get.OnServerInvoke(p,v1)
	local infotable = {}
	local plrstats = PlayerData:WaitForChild(p.Name.."Data")

	for _,v in pairs(plrstats:GetChildren())do
		if table.find(v1,v.Name)then
			infotable[v.Name] = v.Value
		end
	end
	return infotable
end