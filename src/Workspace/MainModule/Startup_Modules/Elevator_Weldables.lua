--[[

	This is a demo
		
	Task: The Cortex MainModule will boot, and you can cast any errors/plugins when initiating through this module
	
	Functions:
	init_start: Starts the module only once per require cache (will only run once)
	init_core: Starts the module each time the MainModule's internal function is called

]]--

local module = {}

function module.init_start()
	_G.ElevatorSensorHumanoids = _G.ElevatorSensorHumanoids or {}
	local function checkHuman(v)
		if (v:IsA('Humanoid') and v.Parent:FindFirstChild('HumanoidRootPart')) then v = v.Parent end
		if (v:FindFirstChildOfClass('Humanoid') and v:FindFirstChild('HumanoidRootPart') and (not table.find(_G.ElevatorSensorHumanoids, v))) then
			table.insert(_G.ElevatorSensorHumanoids, v.HumanoidRootPart)
		end
	end
	workspace.DescendantAdded:Connect(checkHuman)
	for i,v in pairs(workspace:GetDescendants()) do
		task.spawn(checkHuman, v)
	end
	workspace.DescendantRemoving:Connect(function(v)
		task.wait()
		local index = table.find(_G.ElevatorSensorHumanoids, v)
		if (index) then
			table.remove(_G.ElevatorSensorHumanoids, index)
		end
	end)
end
function module.init_core()

end

return module