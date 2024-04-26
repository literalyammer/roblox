--[[

	This is a demo
		
	Task: The Cortex MainModule will boot, and you can cast any errors/plugins when initiating through this module
	
	Functions:
	init_start: Starts the module only once per require cache (will only run once)
	init_core: Starts the module each time the MainModule's internal function is called

]]--

local module = {}

function module.init_start()
	
end
function module.init_core()

end

return module