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
	local function handle(plr: Player)
		local plrGui = plr:WaitForChild('PlayerGui')
		if (not plrGui:FindFirstChild('Cortex_Client_Weld')) then
			local handler = script.Cortex_Client_Weld:Clone()
			handler.Parent = plrGui
		end
		if (not plrGui:FindFirstChild('Cortex_Camera_Effects')) then
			local handler = script.Cortex_Camera_Effects:Clone()
			handler.Parent = plrGui
		end
	end
	players.PlayerAdded:Connect(handle)
	for i, v in pairs(players:GetChildren()) do
		task.spawn(handle, v)
	end
end
function module.init_core()
	
end

return module