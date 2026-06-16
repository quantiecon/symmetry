local Speed = script.Parent.Speed.Value --this is a variable, it is calling the value of speed that you put

while true do 
	script.Parent.Velocity = script.Parent.CFrame.LookVector*Speed
	script.Parent.Beam.Width0 = script.Parent.Size.X
	script.Parent.Beam.Width1 = script.Parent.Size.X
	script.Parent.Beam.TextureLength = script.Parent.Size.X
	wait(0.1)
end

