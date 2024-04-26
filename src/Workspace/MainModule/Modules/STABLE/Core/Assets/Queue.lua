local module = {}

module.Current_Queue = _G.Cortex_Elevator_Queue[script.Parent:GetAttribute('elevatorID')]
function module.checkQueueInDirection(floor: number, direction: string?)
	if (not floor) then return end
	local result = {}
	print(module.Current_Queue)
	for i,v in ipairs(module.Current_Queue) do
		if ((v >= floor and direction == 'U') or (v >= floor and direction == 'D') or typeof(direction) ~= 'string' or direction == 'N') then
			table.insert(result, v)
		end
	end
	return result
end

return module