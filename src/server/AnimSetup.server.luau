local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = Instance.new("Folder")
folder.Name  = "CharacterAnims"
folder.Parent = ReplicatedStorage

local function anim(name, id)
	local a = Instance.new("Animation")
	a.Name        = name
	a.AnimationId = "rbxassetid://" .. id
	a.Parent      = folder
end

anim("Walk",     "122235205002711")
anim("Run",      "100044344992725")
anim("SixSeven", "101861600822053")
