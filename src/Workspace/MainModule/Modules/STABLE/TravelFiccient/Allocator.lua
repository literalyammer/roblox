local module = {}

function module.allocateElevator(dest, callDirection, elevators)

	local dist = math.huge
	local chosenElevator
		
	for i, elev in pairs(elevators) do
		if (elev:FindFirstChild('Legacy')) then
			if (elev.Legacy.Floor.Value == dest and (elev.Legacy.Move_Value.Value == 0 or elev.Legacy.Leveling.Value) and (elev.Legacy.Queue_Direction.Value == callDirection or elev.Legacy.Queue_Direction.Value == 'N') and ((not elev.Legacy.Out_Of_Service.Value) and (not elev.Legacy.Fire_Service.Value) and (not elev.Legacy.Inspection.Value) and (not elev.Legacy.Independent_Service.Value))) then
				chosenElevator = elev
				break
			elseif (elev.Legacy.Floor.Value ~= dest and ((math.abs(elev.Legacy.Floor.Value-dest) <= dist) and ((((elev.Legacy.Floor.Value >= dest and ((callDirection == 'U' and elev.Legacy.Destination.Value <= dest) or elev.Legacy.Queue_Direction.Value == 'N')) or (elev.Legacy.Floor.Value <= dest and ((callDirection == 'D' and elev.Legacy.Destination.Value >= dest) or elev.Legacy.Queue_Direction.Value == 'N')))))) and ((not elev.Legacy.Out_Of_Service.Value) and (not elev.Legacy.Fire_Service.Value) and (not elev.Legacy.Inspection.Value) and (not elev.Legacy.Independent_Service.Value))) then
				dist = math.abs(elev.Legacy.Floor.Value-dest)
				chosenElevator = elev
			end
		end
	end
	
	--FALLBACK ELEVATOR ALLOCATOR
	if (not chosenElevator) then
		warn(':: Cortex Allocator :: Precise allocator failed, utilizing fallback allocator.')
		
		dist = math.huge
		for i, elev in pairs(elevators) do
			if (elev:FindFirstChild('Legacy')) then
				if (elev.Legacy.Floor.Value == dest and (elev.Legacy.Move_Value.Value == 0 or elev.Legacy.Leveling.Value) and ((not elev.Legacy.Out_Of_Service.Value) and (not elev.Legacy.Fire_Service.Value) and (not elev.Legacy.Inspection.Value) and (not elev.Legacy.Independent_Service.Value))) then
					chosenElevator = elev
					break
				elseif (elev.Legacy.Floor.Value ~= dest and ((math.abs(elev.Legacy.Floor.Value-dest) <= dist)) and ((not elev.Legacy.Out_Of_Service.Value) and (not elev.Legacy.Fire_Service.Value) and (not elev.Legacy.Inspection.Value) and (not elev.Legacy.Independent_Service.Value))) then
					dist = math.abs(elev.Legacy.Floor.Value-dest)
					chosenElevator = elev
				end
			end
		end
	end
	
	return chosenElevator

end

return module