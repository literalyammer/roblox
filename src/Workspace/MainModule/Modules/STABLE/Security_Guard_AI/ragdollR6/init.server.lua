function ragdoll(noob)

	local dead = Instance.new("VelocityMotor",noob)
	dead.Name = "Ragdolled"

	if noob:FindFirstChild('Head') then
		local socket = Instance.new("BallSocketConstraint",noob.Head)
		local acth1 = Instance.new("Attachment",noob.Head)
		acth1.Position = Vector3.new(0,-0.5,0)
		local acth2 = Instance.new("Attachment",noob.Torso)
		acth2.Position = Vector3.new(0,1,0)
		socket.Attachment0 = acth1
		socket.Attachment1 = acth2
	end

	if noob:FindFirstChild('Right Arm') then
		local socket2 = Instance.new("BallSocketConstraint",noob["Right Arm"])
		local acth3 = Instance.new("Attachment",noob["Right Arm"])
		acth3.Position = Vector3.new(0,0.5,0)
		local acth4 = Instance.new("Attachment",noob.Torso)
		acth4.Position = Vector3.new(1.5,0.5,0)
		socket2.Attachment0 = acth3
		socket2.Attachment1 = acth4
	end

	if noob:FindFirstChild('Left Arm') then
		local socket3 = Instance.new("BallSocketConstraint",noob["Left Arm"])
		local acth5 = Instance.new("Attachment",noob["Left Arm"])
		acth5.Position = Vector3.new(0,0.5,0)
		local acth6 = Instance.new("Attachment",noob.Torso)
		acth6.Position = Vector3.new(-1.5,0.5,0)
		socket3.Attachment0 = acth5
		socket3.Attachment1 = acth6
	end

	if noob:FindFirstChild('Right Leg') then
		local socket4 = Instance.new("BallSocketConstraint",noob["Right Leg"])
		local acth7 = Instance.new("Attachment",noob["Right Leg"])
		acth7.Position = Vector3.new(0,1,0)
		local acth8 = Instance.new("Attachment",noob.Torso)
		acth8.Position = Vector3.new(0.5,-1,0)
		socket4.Attachment0 = acth7
		socket4.Attachment1 = acth8
	end

	if noob:FindFirstChild('Left Leg') then
		local socket5 = Instance.new("BallSocketConstraint",noob["Left Leg"])
		local acth9 = Instance.new("Attachment",noob["Left Leg"])
		acth9.Position = Vector3.new(0,1,0)
		local acth10 = Instance.new("Attachment",noob.Torso)
		acth10.Position = Vector3.new(-0.5,-1,0)
		socket5.Attachment0 = acth9
		socket5.Attachment1 = acth10
	end
end

function ragdoll2(person)
	local RM = Instance.new("Model",workspace)
	for _, c in pairs(person:GetChildren()) do
		if (not c:IsA('LocalScript')) and (not c:IsA('Script')) and (not c:IsA('ModuleScript')) then
			c.Parent = RM
		end
	end
	ragdoll(RM)
	local RH2 = RM:FindFirstChildWhichIsA("Humanoid")
	RH2.DisplayDistanceType = 'None'
	local RH3 = RH2:Clone()
	RH3.Parent = RM
	RH3.Health = 100
	RH3.PlatformStand = true
	RH2:Destroy()

	for _, c in pairs(RM:GetChildren()) do
		if c:IsA("Part") or c:IsA("MeshPart") then
			local LC = c:Clone()
			LC.Parent = RM
			LC.Name = 'FakeLimb'
			LC.Size = c.Size - Vector3.new(0.3,0.3,0.3)
			LC.Transparency = 1
			LC.CanCollide = true
			local weld = Instance.new("Weld",c)
			weld.Part0 = c
			weld.Part1 = LC
			if c.Name == 'Head' then
				local camscript = script.CamAttach:Clone()
				camscript.Parent = script.Parent
				camscript.CamPart.Value = c
			end
		end
	end


	wait(4.5)
	RM:Destroy()

end

local Hum = script.Parent:WaitForChild('Humanoid')
if Hum then
	ragdoll2(script.Parent)
	script:Destroy()
end
