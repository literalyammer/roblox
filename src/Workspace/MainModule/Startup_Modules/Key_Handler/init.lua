--[[

	This is a demo
		
	Task: The Cortex MainModule will boot, and you can cast any errors/plugins when initiating through this module
	
	Functions:
	init_start: Starts the module only once per require cache (will only run once)
	init_core: Starts the module each time the MainModule's internal function is called

]]--

local module = {}
local players = game:GetService('Players')

function module.init_start()
	
	local function checkPlayer(player: Player)
		task.spawn(function()
			task.wait()
			local playerGui = player:WaitForChild('PlayerGui')
			local gui = playerGui:FindFirstChild('KEY_SWITCH_HANDLERS')
			if (not gui) then
				gui = Instance.new('ScreenGui')
				gui.Name = 'KEY_SWITCH_HANDLERS'
				gui.ResetOnSpawn = false
				local scr = script.KEY_CLIENT_CONTROL:Clone()
				scr.Parent = gui
				gui.Parent = playerGui
			end
		end)
	end
	players.PlayerAdded:Connect(checkPlayer)
	for _,v in pairs(players:GetChildren()) do
		checkPlayer(v)
	end
	
end
function module.init_core()

end

return module