local module = {}

local function absoluteDifference(a, b)
	return math.abs(a-b)
end

local function checkElevatorStatValue(elevator, name)
	if (not elevator) then return nil end
	if ((not elevator:FindFirstChild('Legacy'))) then return nil end
	if (elevator.Legacy:FindFirstChild(name)) then return elevator.Legacy:FindFirstChild(name).Value end
	return nil
end

local function isElevatorOutOfService(elevator)
	return (checkElevatorStatValue(elevator, 'Independent_Service')
		or checkElevatorStatValue(elevator, 'Fire_Service')
		or checkElevatorStatValue(elevator, 'Stop')
		or checkElevatorStatValue(elevator, 'Inspection')
		or checkElevatorStatValue(elevator, 'Out_Of_Service')
	)
end

function module.findElevator(elevators: {}, callFloor: number, callDirection: number)
	local CALL_DIRECTION = callDirection
	local availableElevators = {}
	for i,v in pairs(elevators) do
		if isElevatorOutOfService(v) then continue end
		local floor,destination,moveDirection,queueDirection = checkElevatorStatValue(v,'Floor'),checkElevatorStatValue(v,'Destination'),checkElevatorStatValue(v,'Move_Value'),checkElevatorStatValue(v,'Queue_Direction')
		if ((not floor) or (not destination) or (not moveDirection) or (not queueDirection)) then continue end
		table.insert(availableElevators, v)
	end
	--table.sort(availableElevators, function(a,b)
	--	return a.Name < b.Name
	--end)
	local sortedElevators = {}
	local nearestElevator
	local minDistance = math.huge
	for _, elevator in ipairs(availableElevators) do
		if isElevatorOutOfService(elevator) then continue end
		local statValues = elevator.Legacy
		local floor,direction,queueDirection = statValues.Floor.Value,statValues.Move_Value.Value,statValues.Queue_Direction.Value
		queueDirection = queueDirection == 'U' and 1 or queueDirection == 'D' and -1 or 0 --// Correct queue direction
		local distance = math.abs(floor-callFloor)
		if (distance < minDistance) then
			-- // If elevator is idle on call floor
			if ((floor == callFloor and direction == 0) and (queueDirection == callDirection or queueDirection == 0)) then
				nearestElevator = elevator
				minDistance = distance
				--// Check for elevators in direction & check for their queue direction
			elseif ((callDirection == 1 and floor <= callFloor and (direction == -1 or direction == 0) and (queueDirection == 1 or queueDirection == 0)) or (callDirection == -1 and floor >= callFloor and (direction == 1 or direction == 0) and ((queueDirection == -1 or queueDirection == 0)))) then
				nearestElevator = elevator
				minDistance = distance
				-- // Check for any elevator that is idle on any floor
			elseif (direction == 0 and (queueDirection == callDirection or queueDirection == 0)) then
				nearestElevator = elevator
				minDistance = distance
			end
		end
	end
	if (not nearestElevator) then
		return availableElevators[1]
	end
	
	return nearestElevator
end

return module