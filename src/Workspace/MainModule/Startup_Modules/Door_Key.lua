--[[

	This is a demo
		
	Task: The Cortex MainModule will boot, and you can cast any errors/plugins when initiating through this module
	
	Functions:
	init_start: Starts the module only once per require cache (will only run once)
	init_core: Starts the module each time the MainModule's internal function is called

]]--

local module = {}

function module.init_start()
	local players = game:GetService('Players')
	local function process(plr: Player)
		task.wait()
		local playerGui = plr:WaitForChild('PlayerGui')
		local handlerGui = playerGui:FindFirstChild('DOOR_KEY_HANDLER')
		if (not handlerGui) then
			handlerGui = Instance.new('ScreenGui')
			handlerGui.ResetOnSpawn = false
			handlerGui.Name = 'DOOR_KEY_HANDLER'
			handlerGui.Parent = playerGui
			local handlerScript = script.Parent.Parent.Dependencies.DOOR_KEY_HANDLER:Clone()
			handlerScript.Parent = handlerGui
		end
		local doorKeyUis = playerGui:FindFirstChild('DOOR_KEY_UIS')
		if (not doorKeyUis) then
			doorKeyUis = Instance.new('ScreenGui')
			doorKeyUis.Name = 'DOOR_KEY_UIS'
			doorKeyUis.ResetOnSpawn = false
			doorKeyUis.IgnoreGuiInset = false
			doorKeyUis.Parent = playerGui
		end
	end
	players.PlayerAdded:Connect(process)
	for i,v in pairs(players:GetChildren()) do
		task.spawn(process, v)
	end
end
function module.init_core()

end

return module