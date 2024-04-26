local THIS = script.Parent
local DATA_REMOTE = THIS:WaitForChild('DATA_REMOTE')

function DATA_REMOTE.OnServerInvoke(USER, PROTOCOL, PARAMS)
	if (not _G.CORTEX_RC_WHITELIST[tostring(USER.UserId)]) then return end
	if (PROTOCOL == 'GET_ELEVATOR_STORAGE') then
		return _G.CortexElevatorStorage
	elseif (PROTOCOL == 'GET_ELEVATOR_OUTPUT_STORAGE') then
		return _G.Elevator_Output_Storage_GLOBAL
	elseif (PROTOCOL == 'CORTEX_API_FIRE') then
		if (not PARAMS.ELEVATOR) then return end
		PARAMS.ELEVATOR.Cortex_API:Fire(PARAMS.PROTOCOL, PARAMS.PARAMS)
	end
end