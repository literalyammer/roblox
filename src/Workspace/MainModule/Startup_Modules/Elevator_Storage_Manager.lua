--[[

	This is a demo
		
	Task: The Cortex MainModule will boot, and you can cast any errors/plugins when initiating through this module
	
	Functions:
	init_start: Starts the module only once per require cache (will only run once)
	init_core: Starts the module each time the MainModule's internal function is called

]]--

local module = {}

local event = {} do
	event.__index = 'event'
	function event.new()
		local self = setmetatable({}, event)
		self.event = Instance.new('BindableEvent')
		return self
	end
end

function module.init_start()
	
	_G.ELEVATOR_BINDS = _G.ELEVATOR_BINDS or {}
	local addedEvent,removedEvent = event.new(),event.new()
	_G.ELEVATOR_BINDS.ElevatorAdded = addedEvent.Event
	_G.ELEVATOR_BINDS.ElevatorRemoved = removedEvent.Event
	
	local function processElevator(elev: Instance, action: string)
		task.spawn(function()
			task.wait()
			if (elev:FindFirstChild('Legacy') and elev:FindFirstChild('Cortex_API') and elev:FindFirstChild('Car') and elev:FindFirstChild('Floors')) then
				if (action == 'add') then
					_G.CortexElevatorStorage[elev] = elev
					addedEvent.event:Fire(elev)
				elseif (action == 'remove') then
					_G.CortexElevatorStorage[elev] = nil
					removedEvent.event:Fire(elev)
				end
			end
		end)
	end
	
	for _,v in pairs(workspace:GetDescendants()) do
		processElevator(v, 'add')
	end
	workspace.DescendantAdded:Connect(function(desc: Instance)
		processElevator(desc, 'add')
	end)
	workspace.DescendantRemoving:Connect(function(desc: Instance)
		processElevator(desc, 'remove')
	end)
	
end
function module.init_core()

end

return module