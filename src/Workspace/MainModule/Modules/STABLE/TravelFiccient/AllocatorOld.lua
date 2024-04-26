local module = {}

function module.allocateElevator(dest, callFloor, elevators)

	local dist = 324324324
	local chosenElevator
	
	local allocateDirection = (dest > callFloor and 'U' or dest < callFloor or 'D') or 'N'
	
	for i, elev in pairs(elevators) do
		if (elev.Legacy.Floor.Value == callFloor and (elev.Legacy.Move_Value.Value == 0 or elev.Legacy.Leveling.Value) and (not require(elev.Queue)[dest])) then
			chosenElevator = elev
			break
		elseif (((math.abs(elev.Legacy.Floor.Value-callFloor) <= dist) and ((((elev.Legacy.Floor.Value >= callFloor and ((elev.Legacy.Queue_Direction.Value == 'D' and elev.Legacy.Destination.Value <= callFloor) or elev.Legacy.Queue_Direction.Value == 'N')) or (elev.Legacy.Floor.Value <= callFloor and ((elev.Legacy.Queue_Direction.Value == 'U' and elev.Legacy.Destination.Value >= callFloor) or elev.Legacy.Queue_Direction.Value == 'N')))))) and ((not elev.Legacy.Out_Of_Service.Value) and (not elev.Legacy.Fire_Service.Value) and (not elev.Legacy.Inspection.Value))) then
			dist = math.abs(elev.Legacy.Floor.Value-callFloor)
			chosenElevator = elev
		end
	end
	
	--FALLBACK ELEVATOR ALLOCATOR
	if (not chosenElevator) then
		warn(':: Cortex EVO 4.3 :: Percise allocator failed, utilizing fallback allocator.')
	
		dist = 324324324
		for i, elev in pairs(elevators) do
			if (elev.Legacy.Floor.Value == callFloor and (elev.Legacy.Move_Value.Value == 0 or elev.Legacy.Leveling.Value) and (not require(elev.Queue)[dest])) then
				chosenElevator = elev
				break
			elseif (((math.abs(elev.Legacy.Floor.Value-callFloor) <= dist))) then
				dist = math.abs(elev.Legacy.Floor.Value-callFloor)
				chosenElevator = elev
			end
		end
	end
	
	return chosenElevator

end

return module