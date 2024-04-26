local players = game:GetService('Players')
local runService = game:GetService('RunService')
local replicatedStorage = game:GetService('ReplicatedStorage')

local player = players.LocalPlayer
player.CharacterAdded:Connect(function(char)

	local root = char:WaitForChild('HumanoidRootPart')
	local humanoid: Humanoid = char:WaitForChild('Humanoid')
	root.ChildAdded:Connect(function(child: Instance)
		task.wait()
		if (child.Name ~= 'Cortex_Elevator_Weld') then return end
		local platform = child.Part1
		local settings = select(2, pcall(require, platform.Parent.Parent:FindFirstChild('Settings')))
		if ((typeof(settings) ~= 'table' or settings.Movement.Enable_New_Player_Sticking ~= true)) then return end
		local yOffset = root.CFrame.Position.Y-platform.Position.Y
		local lastPosition = platform.CFrame.Position
		child.Enabled = false
		runService:BindToRenderStep('UpdateElevatorWeld', Enum.RenderPriority.Input.Value, function()
			local diff = platform.CFrame.Position-platform.CFrame.Position
			lastPosition = platform.CFrame.Position
			root.CFrame = CFrame.new(root.CFrame.Position.X+diff.X, platform.CFrame.Position.Y+yOffset, root.CFrame.Position.Z+diff.Z)*CFrame.fromOrientation(root.CFrame:ToOrientation())
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
		end)
	end)
	root.ChildRemoved:Connect(function(child: Instance)
		task.wait()
		if (child.Name ~= 'Cortex_Elevator_Weld') then return end
		runService:UnbindFromRenderStep('UpdateElevatorWeld')
	end)

end)