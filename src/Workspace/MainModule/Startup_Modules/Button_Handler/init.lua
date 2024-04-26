--[[

	This is a demo
		
	Task: The Cortex MainModule will boot, and you can cast any errors/plugins when initiating through this module
	
	Functions:
	init_start: Starts the module only once per require cache (will only run once)
	init_core: Starts the module each time the MainModule's internal function is called

]]--

local module = {}

function module.init_start()
	task.spawn(function()
		local players = game:GetService('Players')
		
		local function loadGui(player: Player)
			task.spawn(function()
				local src = player.PlayerGui:FindFirstChild('Cortex_Buttons_Handler')
				if (not src) then
					src = Instance.new('ScreenGui')
					src.Name = 'Cortex_Buttons_Handler'
					src.ResetOnSpawn = false
					src.Parent = player.PlayerGui
					local newS = script:WaitForChild('Client_Buttons_Loader'):Clone()
					script:WaitForChild('Button_Handler'):Clone().Parent = newS
					newS.Parent = src
				end
			end)
		end
		players.PlayerAdded:Connect(function(player: Player)
			task.wait()
			loadGui(player)
		end)
		for _,v in pairs(players:GetChildren()) do
			loadGui(v)
		end
		
		require(script:WaitForChild('Button_Handler'))()
		
	end)
end
function module.init_core()

end

return module