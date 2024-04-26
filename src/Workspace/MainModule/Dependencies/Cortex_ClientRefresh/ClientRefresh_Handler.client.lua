--[[

	// This code was written to help smooth & butter out the Cortex elevator movements. \\\
	
	-- 
	The ideology of this is simply easing the elevators position from a given previous point and a target point,
	and moves within the time frame of the time between the last server runtime frame and the current server runtime frame.
	--

]]--

local function getService(service: string)
	return game:GetService(service)
end

local runService: RunService = getService('RunService')
local httpService: HttpService = getService('HttpService')
local collectionService: CollectionService = getService('CollectionService')
local eventRemote: RemoteEvent = game.ReplicatedStorage:WaitForChild('CORTEX_CLIENT_INSTANCES'):WaitForChild('RUNTIME_REMOTE_SIGNAL')
local whitelist = script.Parent.WHITELIST_META

local runningElevators = {}

local id = httpService:GenerateGUID() -- Randomized ID for runtime handling

local function createData(elevator: any)
	return {
		lastTick=tick(),
		elevator=elevator,
	}
end
local function initiateElevator(elevator: any)
	if (not elevator) then return end
	local elevatorID = elevator:GetAttribute('elevatorID')
	local data = runningElevators[tostring(elevatorID)]
	local platform = elevator.Car.Platform
	local startTick = tick()
	
end

eventRemote.OnClientEvent:Connect(function(dtTime)
	--print(dtTime)
	local startTick = tick()
	local alpha = 0
	while (alpha < 1) do
		alpha = math.clamp((tick()-startTick)/dtTime, 0, 1)
		for i,v in next,runningElevators do
			v.elevator.Car.Platform.CFrame = v.lastPosition:Lerp(v.elevator.Car.Platform.targetPoint.Value, alpha)
		end
		runService.PreRender:Wait()
	end
end)

local function getElevatorByIdInWL(id: any)
	local DATA_DECODED = httpService:JSONDecode(whitelist.Value)
	return typeof(DATA_DECODED) == 'table' and DATA_DECODED[tostring(id)] or nil
end

runService:BindToRenderStep('elevatorUpdate', Enum.RenderPriority.First.Value+1, function()

	for i,v in next,collectionService:GetTagged('cortexElevatorInstance') do
		local elevatorID = v:GetAttribute('elevatorID')
		if (getElevatorByIdInWL(elevatorID)) then
			if (not runningElevators[tostring(elevatorID)]) then
				runningElevators[tostring(elevatorID)] = createData(v)
				initiateElevator(v)
			end
		end
	end

end)