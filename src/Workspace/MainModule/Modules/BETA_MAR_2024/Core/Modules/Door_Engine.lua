local doorEngineClass = {}

local heartbeat =_G.Cortex_SERVER.EVENTS.RUNTIME_EVENT.EVENT

doorEngineClass.className = 'doorEngineClass'

doorEngineClass.isPluginModule = true

doorEngineClass.config = nil
doorEngineClass.elevator = nil

local core = require(script.Parent.Parent)
local coreFunctions = core.coreFunctions
local coreFunctionsModule = require(script.Parent.Core_Functions)
local signal = require(script.Parent.Signal)
local legacyEasing = require(script.Parent.Legacy_Easing)

function doorEngineClass.new(doorSet, dataTable)
	local self = setmetatable({}, doorEngineClass)
	if (doorSet.Name == 'Doors') then doorSet.Name = 'Front_Doors' end
	self.side = string.split(doorSet.Name, 'Doors')[2] and string.split(doorSet.Name, 'Doors')[1]
	if (not self.side) then return end
	self.side = string.split(self.side, '_')[1]
	if (self.side == '') then self.side = 'Front' end
	self.sideJoin = `{self.side == '' and '' or `{self.side}_`}`
	self.state = 'Closed'
	self.isEnabled = true
	self.nudging = false
	self.doorSet = doorSet
	self.velocity = {
		['Inner'] = 0,
		['Outer'] = 0,
	}
	self.alpha = {
		['Inner'] = 0,
		['Outer'] = 0,
	}
	self.currentStage = {
		['Opening'] = {
			['Inner'] = 1,
			['Outer'] = 1,
		},
		['Closing'] = {
			['Inner'] = 1,
			['Outer'] = 1,
		}
	}

	self.sensorLEDs = {}

	self.openingThread,self.closingThread = nil,nil

	self.Opened = signal.new()
	self.Closed = signal.new()
	self.LanternsReset = signal.new()

	self.openingThreads = {}
	self.closingThreads = {}

	self.doorTimestamp = 0
	self.nudgeTimestamp = 0

	self.lanternsReset = false

	local elevator = doorEngineClass.elevator
	local car = elevator.Car
	local carLevel = elevator.Car:FindFirstChild('Level') or elevator.Car:FindFirstChild('Platform')
	local cabRegion = elevator.Car:WaitForChild('Cab_Region')
	self.doorSensorPart = elevator.Car:WaitForChild('Door_Sensor_Parts'):FindFirstChild(`{self.sideJoin}Sensor`)

	for i, v in pairs(doorSet:GetDescendants()) do
		if (not v:IsA('BasePart') or v.Name ~= 'Sensor_LED') then continue end
		table.insert(self.sensorLEDs, v)
		v.Color = doorEngineClass.config.Doors.Sensor_LED_Data.Opening_Color.Inactive.Color
		v.Material = doorEngineClass.config.Doors.Sensor_LED_Data.Opening_Color.Inactive.Material
	end

	if (doorEngineClass.config.Sound_Database.Doors.Open_Sound) then
		self.doorOpenSound = coreFunctions.addSound(self.doorSensorPart, 'Door_Open_Sound', doorEngineClass.config.Sound_Database.Doors.Open_Sound, false, 4, 25)
	end
	if (doorEngineClass.config.Sound_Database.Doors.Close_Sound) then
		self.doorCloseSound = coreFunctions.addSound(self.doorSensorPart, 'Door_Close_Sound', doorEngineClass.config.Sound_Database.Doors.Close_Sound, false, 4, 25)
	end

	for i, v in pairs(core.registeredFloors) do
		if (typeof(doorEngineClass.config.Sound_Database.Doors.Floors) ~= 'table') then continue end
		local floorDoorSoundConfig = doorEngineClass.config.Sound_Database.Doors.Floors[tostring(v.floorNumber)]
		if (typeof(doorEngineClass.config.Sound_Database.Doors.Floors) ~= 'table' or (not floorDoorSoundConfig)) then continue end
		self[`doorOpenSoundFloor{v.floorNumber}`] = coreFunctions.addSound(self.doorSensorPart, `Door_Open_Sound_Floor_{v.floorNumber}`, floorDoorSoundConfig.Open_Sound, false, 4, 25)
		self[`doorCloseSoundFloor{v.floorNumber}`] = coreFunctions.addSound(self.doorSensorPart, `Door_Close_Sound_Floor_{v.floorNumber}`, floorDoorSoundConfig.Close_Sound, false, 4, 25)
	end

	self.obstructionSignal = coreFunctions.addSound(self.doorSensorPart, 'Obstruction_Signal', doorEngineClass.config.Sound_Database.Others.Door_Obstruction_Signal, true, 2, 15)

	function self:Open(floor)

		local startingState = self.state

		local registeredFloor = coreFunctions.findRegisteredFloor(floor)
		if (not registeredFloor) then return end
		local carWelds, floorWelds = car.Door_Engine_Welds:FindFirstChild(self.side), registeredFloor.floorInstance.Door_Engine_Welds:FindFirstChild(self.side)
		if ((not carWelds) or (not floorWelds)) then return end

		for i, v in pairs(self.closingThreads) do
			pcall(task.cancel, v)
			self.closingThreads[i] = nil
		end
		self.Closed:Destroy()
		self.state = 'Opening'
		core.statValues[`{self.sideJoin}Door_State`] = self.state
		task.spawn(coreFunctions.updateStatValues)

		local distanceFactor = 0
		for i, v in pairs(carWelds:GetChildren()) do
			local dist = ((v:GetAttribute('openPoint').Position-v.C0.Position).Magnitude/(v:GetAttribute('openPoint').Position-v:GetAttribute('closedPoint').Position).Magnitude)/#carWelds:GetChildren()
			distanceFactor += dist
		end
		local openSound, closeSound = self[`doorOpenSoundFloor{floor}`] or self.doorOpenSound, self[`doorCloseSoundFloor{floor}`] or self.doorCloseSound
		closeSound:Stop()
		coroutine.wrap(function()
			if (startingState == 'Closed') then
				local hasPassed = coreFunctionsModule.conditionalWait(doorEngineClass.config.Doors.Door_Open_Sound_Delay, function() return {self.state == 'Opening'} end)
				if (not hasPassed) then return end
			end
			openSound.TimePosition = openSound.TimeLength*(1-distanceFactor)
			task.wait()
			openSound:Play()
		end)()
		if (startingState == 'Closed') then
			local hasPassed = coreFunctionsModule.conditionalWait(doorEngineClass.config.Doors.Open_Delay, function() return {self.state == 'Opening'} end)
			if (not hasPassed) then return end
		end

		local function runDoor(set)
			local velocityConfig = doorEngineClass.config.Doors.Custom_Door_Operator_Config[set].Opening
			if ((set ~= 'Inner' and set ~= 'Outer') or (velocityConfig.Enable and set == 'Outer' and doorEngineClass.config.Doors.New_Attachment_Doors_Config.Enable)) then return end
			local doorWelds = set == 'Inner' and car.Door_Engine_Welds:FindFirstChild(self.side) or floorWelds
			if (not doorWelds) then return end

			local landingDoors = registeredFloor.floorInstance:FindFirstChild(`{self.sideJoin}Doors`)
			if (not landingDoors) then return end
			local direction = (select(1, landingDoors:GetBoundingBox()).Position-select(1, doorSet:GetBoundingBox()).Position)

			local duration = doorEngineClass.config.Doors.Door_Open_Speed

			local masterWeld,dist = nil,math.huge
			for _, v in pairs(doorWelds:GetChildren()) do
				local distance = (v:GetAttribute('openPoint').Position-v:GetAttribute('closedPoint').Position).Magnitude
				if (distance < dist and distance > 0) then
					masterWeld = v
					dist = distance
				end
			end

			local function checkWelds(point, threshold, includeFloorDoors)
				for _, v in pairs(carWelds:GetChildren()) do
					if ((v:GetAttribute(point).Position-v.C0.Position).Magnitude > threshold) then return false end
				end
				if (includeFloorDoors == true) then
					for _, v in pairs(floorWelds:GetChildren()) do
						if ((v:GetAttribute(point).Position-v.C0.Position).Magnitude > threshold) then return false end
					end
				end
				return true
			end

			local reopenStartTime
			local reopenDelayCompleted = false

			if (velocityConfig.Enable) then
				if (startingState == 'Closed') then
					self.velocity[set] = 0
					self.currentStage.Opening[set] = 1
				else
					self.velocity[set] = -self.velocity[set]
				end
				local startVelocity = self.velocity[set]

				local startTime = os.clock()
				local startLerpTime
				local stageAccelTime,initialVelocity,stageSpeed
				local decelerating = false
				local lastVelocity = self.velocity[set]
				local delayTick

				local doorSpeed = dist/duration
				local lastDist

				local distOffset = math.clamp(velocityConfig.Deceleration_Offset, 0, math.huge)
				local minSpeed = math.clamp(velocityConfig.Minimum_Speed or .05, 0, doorSpeed)

				local dtTime = 0

				if (startingState == 'Closed' and doorEngineClass.config.Doors.New_Attachment_Doors_Config.Enable) then
					if (floorWelds) then
						local function getEngineWeld(part: BasePart?)
							for _,v in pairs(floorWelds:GetChildren()) do
								if (v.Part0 == part) then return v end
							end
							return nil
						end
						local params = RaycastParams.new()
						params.FilterType = Enum.RaycastFilterType.Include
						local list = {}
						for _,weld in pairs(floorWelds:GetChildren()) do
							table.insert(list, weld.Part0)
						end
						params.FilterDescendantsInstances = list
						for _,weld in pairs(carWelds:GetChildren()) do
							local result = workspace:Blockcast(CFrame.new(weld.Part0.CFrame.Position), Vector3.new(0, weld.Part0.Size.Y, 0), Vector3.new(direction.X, 0, direction.Z).Unit*5, params)
							if ((not result) or (not result.Instance)) then continue end
							local value = weld:FindFirstChild('Door_Weld') or Instance.new('ObjectValue')
							value.Name = 'Door_Weld'
							value.Value = getEngineWeld(result.Instance)
							value.Parent = weld
						end
					end
				end

				local function getFloorWeldFromCarWeld(weld)
					for i, v in pairs(floorWelds:GetChildren()) do
						if (v == weld) then return v end
					end
					return nil
				end

				local parent = self.doorSet:IsDescendantOf(car) and elevator:WaitForChild('Legacy') or self.doorSet.Parent
				local doorSpeedValue = parent:FindFirstChild(`{self.sideJoin}Door_Speed`)

				while (self.alpha[set] < 1 and (self.state == 'Opening' or self.state == 'Open')) do
					local thisConfig = typeof(velocityConfig.Custom_Acceleration_Stages) == 'table' and velocityConfig.Custom_Acceleration_Stages or {}
					local currentStage = thisConfig[self.currentStage.Opening[set]]

					local thisDist = (masterWeld:GetAttribute('openPoint').Position-masterWeld.C0.Position).Magnitude
					local thisDistCheck = thisDist/dist <= velocityConfig.Deceleration_Distance*(math.clamp((self.velocity[set])/doorSpeed, 0, 1))

					for i, v in pairs(self.sensorLEDs) do
						v.Color = doorEngineClass.config.Doors.Sensor_LED_Data.Opening_Color.Active.Color
						v.Material = doorEngineClass.config.Doors.Sensor_LED_Data.Opening_Color.Active.Material
					end

					if (startVelocity < 0 and self.velocity[set] >= 0) then
						if (not reopenStartTime) then
							reopenStartTime = os.clock()
						else
							if ((os.clock()-reopenStartTime)/doorEngineClass.config.Doors.Reopen_Delay < 1) then heartbeat:Wait() continue end
							if (not reopenDelayCompleted) then
								reopenDelayCompleted = true
								startLerpTime += (os.clock()-reopenStartTime)
								startLerpTime = nil
							end
						end
					end

					if (not thisDistCheck) then
						if (not decelerating) then
							if (currentStage) then
								if (not startLerpTime) then
									startLerpTime = os.clock()
									initialVelocity = self.velocity[set]
									stageSpeed = math.clamp(currentStage.Speed, 0, doorSpeed)
									stageAccelTime = (startingState == 'Closing' and self.state == 'Opening' and self.velocity[set] < 0) and coreFunctionsModule.getAccelerationTime(initialVelocity, stageSpeed, .2) or coreFunctionsModule.getAccelerationTime(initialVelocity, stageSpeed, if (currentStage.Acceleration == 'USE_ACCELERATION') then velocityConfig.Acceleration else currentStage.Acceleration)
								else
									local alpha = math.min((os.clock()-startLerpTime)/stageAccelTime, 1)
									self.velocity[set] = coreFunctionsModule.lerp(initialVelocity, stageSpeed, alpha)
									if (alpha >= 1 and thisConfig[self.currentStage.Opening[set]+1]) then
										if (not delayTick) then
											delayTick = os.clock()
										elseif ((os.clock()-delayTick)/currentStage.Delay_Before_Next_Stage >= 1) then
											self.currentStage.Opening[set] = math.min(self.currentStage.Opening[set]+1, #thisConfig)
											startLerpTime = nil
										end
									end
								end
							else
								if (not startLerpTime) then
									startLerpTime = os.clock()
									initialVelocity = self.velocity[set]
									stageAccelTime = coreFunctionsModule.getAccelerationTime(initialVelocity, doorSpeed, velocityConfig.Acceleration)
								else
									local alpha = math.min((os.clock()-startLerpTime)/stageAccelTime, 1)
									self.velocity[set] = coreFunctionsModule.lerp(initialVelocity, doorSpeed, alpha)
								end
							end
						end
					else
						if (not decelerating) then
							decelerating = true
							lastDist = thisDist
							lastVelocity = self.velocity[set]
						end
						if (velocityConfig.Deceleration_Rate == 'Constant') then
							local distOff = thisDist-distOffset
							local currentSpeed = self.velocity[set]
							local deceleration = currentSpeed^2/(2*math.max(.001, distOff))
							local SPEED = math.max(0, currentSpeed-deceleration*dtTime)
							self.velocity[set] = math.max(minSpeed, SPEED)
						end
					end

					self.alpha[set] = math.clamp(self.alpha[set]+((self.velocity[set]/doorSpeed)/duration)*dtTime, 0, 1)
					doorSpeedValue.Value = math.abs(self.velocity[set])

					if (doorEngineClass.config.Doors.New_Attachment_Doors_Config.Enable) then
						for _,weld in pairs(carWelds:GetChildren()) do
							weld.C0 = weld:GetAttribute('closedPoint'):Lerp(weld:GetAttribute('openPoint'), self.alpha[set])
							if (weld:FindFirstChild('Door_Weld')) then
								local data = getFloorWeldFromCarWeld(weld.Door_Weld.Value)
								if (data) then
									local goal = CFrame.new((weld:GetAttribute('closedPoint').Position-weld:GetAttribute('openPoint').Position).Unit*doorEngineClass.config.Doors.New_Attachment_Doors_Config.Attachment_Threshold)*(weld:GetAttribute('closedPoint'):Lerp(weld:GetAttribute('openPoint'), self.alpha[set]))
									weld.Door_Weld.Value.C0 = CFrame.new(
										math.clamp(goal.X,data:GetAttribute('openPoint').X >= data:GetAttribute('closedPoint').X and data:GetAttribute('closedPoint').X or data:GetAttribute('openPoint').X,data:GetAttribute('openPoint').X <= data:GetAttribute('closedPoint').X and data:GetAttribute('closedPoint').X or data:GetAttribute('openPoint').X),
										math.clamp(goal.Y,data:GetAttribute('openPoint').Y >= data:GetAttribute('closedPoint').Y and data:GetAttribute('closedPoint').Y or data:GetAttribute('openPoint').Y,data:GetAttribute('openPoint').Y <= data:GetAttribute('closedPoint').Y and data:GetAttribute('closedPoint').Y or data:GetAttribute('openPoint').Y),
										math.clamp(goal.Z,data:GetAttribute('openPoint').Z >= data:GetAttribute('closedPoint').Z and data:GetAttribute('closedPoint').Z or data:GetAttribute('openPoint').Z,data:GetAttribute('openPoint').Z <= data:GetAttribute('closedPoint').Z and data:GetAttribute('closedPoint').Z or data:GetAttribute('openPoint').Z)
									)
								end
							end
						end
					else
						for i, v in pairs(doorWelds:GetChildren()) do
							v.C0 = v:GetAttribute('closedPoint'):Lerp(v.C1, self.alpha[set])
						end
					end

					if (checkWelds('openPoint', 0, false) and self.state == 'Opening') then
						self.state = 'Open'
						core.statValues[`{self.sideJoin}Door_State`] = self.state
						task.spawn(coreFunctions.updateStatValues)
						self.Opened:Fire()
					end

					dtTime = heartbeat:Wait()

				end
				if (self.state ~= 'Opening') then return end
				self.velocity[set] = 0
				doorSpeedValue.Value = 0
				if (checkWelds('openPoint', 0, false) and self.state == 'Opening') then
					self.state = 'Open'
					core.statValues[`{self.sideJoin}Door_State`] = self.state
					task.spawn(coreFunctions.updateStatValues)
					self.Opened:Fire()
				end

			else
				for i, v in pairs(doorWelds:GetChildren()) do
					local newThread = task.spawn(function()
						local innerDoorsData, outerDoorsData = doorEngineClass.config.Doors.Realistic_Doors_Data, doorEngineClass.config.Doors.Realistic_Outer_Doors_Data
						local data = doorEngineClass.config.Doors[set == 'Inner' and 'Realistic_Doors_Data' or 'Realistic_Outer_Doors_Data']
						if (startingState == 'Closed' and data.Enable_Open) then
							local hasCompleted = legacyEasing.interpolate(v, v:GetAttribute('interlockOpenPoint'), data.Open_Easing_Style, data.Open_Time, function() return {self.state ~= 'Opening'} end)
							if (not hasCompleted) then return end
						end
						if (startingState == 'Closed') then
							if (set == 'Inner' and outerDoorsData.Enable_Open) then
								local hasCompleted = coreFunctionsModule.conditionalWait(outerDoorsData.Open_Time, function() return {self.state == 'Opening'} end)
								if (not hasCompleted) then return end
							elseif (set == 'Outer' and innerDoorsData.Enable_Open) then
								local hasCompleted = coreFunctionsModule.conditionalWait(innerDoorsData.Open_Time, function() return {self.state == 'Opening'} end)
								if (not hasCompleted) then return end
							end
						end
						legacyEasing.interpolate(v, v:GetAttribute('openPoint'), doorEngineClass.config.Doors.Open_Easing_Style, duration*distanceFactor, function() return {self.state ~= 'Opening'} end)
						if (self.state ~= 'Opening') then return end
						if (checkWelds('openPoint', 0, false) and self.state == 'Opening') then
							self.state = 'Open'
							core.statValues[`{self.sideJoin}Door_State`] = self.state
							task.spawn(coreFunctions.updateStatValues)
							self.Opened:Fire()
						end
					end)
					table.insert(self.openingThreads, newThread)
				end
			end
		end

		if (doorEngineClass.config.Doors.Door_Delay_Sequence_Config.Opening.Enable) then
			if (self.state ~= 'Opening') then return end
			task.spawn(function()
				for i, part in ipairs(doorEngineClass.config.Doors.Door_Delay_Sequence_Config.Opening.Sequence_Order) do
					local thread = task.spawn(runDoor, part)
					table.insert(self.openingThreads, thread)
					
					local hasCompleted = coreFunctionsModule.conditionalWait(doorEngineClass.config.Doors.Door_Delay_Sequence_Config.Opening.Delay, function()
						return {self.state == 'Opening'}
					end)
					
					if (not hasCompleted) then return end
				end
			end)
		else
			for _, v in pairs({'Inner', 'Outer'}) do
				local thread = task.spawn(runDoor, v)
				table.insert(self.openingThreads, thread)
			end
		end
	end
	
	function self:Close(floor)

		local startingState = self.state
		if (self.state ~= 'Open' and self.state ~= 'Opening' and self.state ~= 'Stopped') then return end
		self.closingThread = task.spawn(function()
			for _, v in pairs(self.openingThreads) do
				pcall(task.cancel, v)
			end
			self.Opened:Destroy()
			self.state = 'Closing'
			self.lanternsReset = false
			core.statValues[`{self.sideJoin}Door_State`] = self.state
			task.spawn(coreFunctions.updateStatValues)

			local registeredFloor = coreFunctions.findRegisteredFloor(floor)
			if (not registeredFloor) then return end
			local carWelds, floorWelds = car.Door_Engine_Welds:FindFirstChild(self.side), registeredFloor.floorInstance.Door_Engine_Welds:FindFirstChild(self.side)
			local distanceFactor = 0
			for i, v in pairs(carWelds:GetChildren()) do
				local dist = ((v:GetAttribute('closedPoint').Position-v.C0.Position).Magnitude/(v:GetAttribute('closedPoint').Position-v:GetAttribute('openPoint').Position).Magnitude)/#carWelds:GetChildren()
				distanceFactor += dist
			end
			local openSound, closeSound = self[`doorOpenSoundFloor{floor}`] or self.doorOpenSound, self[`doorCloseSoundFloor{floor}`] or self.doorCloseSound
			openSound:Stop()
			coroutine.wrap(function()
				if (startingState == 'Open') then
					local hasPassed = coreFunctionsModule.conditionalWait(doorEngineClass.config.Doors.Door_Close_Sound_Delay, function() return {self.state == 'Closing'} end)
					if (not hasPassed) then return end
				end
				closeSound.TimePosition = closeSound.TimeLength*(1-distanceFactor)
				task.wait()
				closeSound:Play()
			end)()
			if (startingState == 'Open') then
				local hasPassed = coreFunctionsModule.conditionalWait(doorEngineClass.config.Doors.Close_Delay, function() return {self.state == 'Closing'} end)
				if (not hasPassed) then return end
			end

			local function runDoor(set)
				local velocityConfig = doorEngineClass.config.Doors.Custom_Door_Operator_Config[set].Closing
				if ((set ~= 'Inner' and set ~= 'Outer') or (velocityConfig.Enable and set == 'Outer' and doorEngineClass.config.Doors.New_Attachment_Doors_Config.Enable)) then return end
				local doorWelds = set == 'Inner' and car.Door_Engine_Welds:FindFirstChild(self.side) or floorWelds
				if (not doorWelds) then return end

				local direction = (registeredFloor.level.Position-carLevel.Position)

				local duration = self.nudging and doorEngineClass.config.Doors.Nudge_Speed or doorEngineClass.config.Doors.Door_Close_Speed

				local masterWeld,dist = nil,math.huge
				for _, v in pairs(doorWelds:GetChildren()) do
					local distance = (v:GetAttribute('openPoint').Position-v:GetAttribute('closedPoint').Position).Magnitude
					if (distance < dist and distance > 0) then
						masterWeld = v
						dist = distance
					end
				end

				local function checkWelds(point, threshold, includeFloorDoors)
					for _, v in pairs(carWelds:GetChildren()) do
						if ((v:GetAttribute(point).Position-v.C0.Position).Magnitude > threshold) then return false end
					end
					if (includeFloorDoors == true) then
						for _, v in pairs(floorWelds:GetChildren()) do
							if ((v:GetAttribute(point).Position-v.C0.Position).Magnitude > threshold) then return false end
						end
					end
					return true
				end

				local lastSLEDTick = tick()
				local startSLEDTick = tick()

				for i, v in pairs({'Interior', 'Exterior'}) do
					if (not doorEngineClass.config.Color_Database.Lanterns[v].Reset_After_Door_Close) then
						self.lanternsReset = true
						self.LanternsReset:Fire({v})
					end
				end

				if (velocityConfig.Enable) then
					if (startingState == 'Open') then
						self.velocity[set] = 0
						self.currentStage.Closing[set] = 1
					else
						self.velocity[set] = -self.velocity[set]
					end

					local startTime = os.clock()
					local startLerpTime
					local stageAccelTime,initialVelocity,stageSpeed
					local decelerating = false
					local lastVelocity = self.velocity[set]
					local delayTick

					local doorSpeed = dist/duration
					local lastDist

					local distOffset = math.clamp(velocityConfig.Deceleration_Offset, 0, math.huge)
					local minSpeed = math.clamp(velocityConfig.Minimum_Speed or .05, 0, doorSpeed)

					local dtTime = 0

					local function getFloorWeldFromCarWeld(weld)
						for i, v in pairs(floorWelds:GetChildren()) do
							if (v == weld) then return v end
						end
						return nil
					end
					
					local bounceFactor = 1
					local bounceVel = 0

					local parent = self.doorSet:IsDescendantOf(car) and elevator:WaitForChild('Legacy') or self.doorSet.Parent
					local doorSpeedValue = parent:FindFirstChild(`{self.sideJoin}Door_Speed`)

					while (self.alpha[set] > 0 and (self.state == 'Closing' or self.state == 'Closed')) do
						local thisConfig = typeof(velocityConfig.Custom_Acceleration_Stages) == 'table' and velocityConfig.Custom_Acceleration_Stages or {}
						local currentStage = thisConfig[self.currentStage.Closing[set]]

						local thisDist = (masterWeld:GetAttribute('closedPoint').Position-masterWeld.C0.Position).Magnitude
						local thisDistCheck = thisDist/dist <= velocityConfig.Deceleration_Distance*(math.clamp((self.velocity[set])/doorSpeed, 0, 1))

						local data = doorEngineClass.config.Doors.Sensor_LED_Data.Closing_Color
						if (self.state == 'Closing') then
							if ((tick()-startSLEDTick)/data.Delay > 1) then
								local cfg = (tick()-lastSLEDTick)/data.Flash_Time < 1 and data.Active or data.Inactive
								if ((tick()-lastSLEDTick)/data.Flash_Time/2 > 1) then
									lastSLEDTick = tick()
								end
								for i, v in pairs(self.sensorLEDs) do
									v.Color = cfg.Color
									v.Material = cfg.Material
								end
							else
								lastSLEDTick = tick()
								for i, v in pairs(self.sensorLEDs) do
									v.Color = data.Active.Color
									v.Material = data.Active.Material
								end
							end
						end

						if (not thisDistCheck) then
							if (not decelerating) then
								if (currentStage) then
									if (not startLerpTime) then
										startLerpTime = os.clock()
										initialVelocity = self.velocity[set]
										stageSpeed = math.clamp(currentStage.Speed, 0, doorSpeed)
										stageAccelTime = coreFunctionsModule.getAccelerationTime(initialVelocity, stageSpeed, if (currentStage.Acceleration == 'USE_ACCELERATION') then velocityConfig.Acceleration else currentStage.Acceleration)
									else
										local alpha = math.min((os.clock()-startLerpTime)/stageAccelTime, 1)
										self.velocity[set] = coreFunctionsModule.lerp(initialVelocity, stageSpeed, alpha)
										if (alpha >= 1 and thisConfig[self.currentStage.Closing[set]+1]) then
											if (not delayTick) then
												delayTick = os.clock()
											elseif ((os.clock()-delayTick)/currentStage.Delay_Before_Next_Stage >= 1) then
												self.currentStage.Closing[set] = math.max(1, self.currentStage.Closing[set]+1)
												startLerpTime = nil
											end
										end
									end
								else
									if (not startLerpTime) then
										startLerpTime = os.clock()
										initialVelocity = self.velocity[set]
										stageAccelTime = coreFunctionsModule.getAccelerationTime(initialVelocity, doorSpeed, velocityConfig.Acceleration)
									else
										local alpha = math.min((os.clock()-startLerpTime)/stageAccelTime, 1)
										self.velocity[set] = coreFunctionsModule.lerp(initialVelocity, doorSpeed, alpha)
									end
								end
							end
						else
							if (not decelerating) then
								decelerating = true
								lastDist = thisDist
								lastVelocity = self.velocity[set]
							end
							if (velocityConfig.Deceleration_Rate == 'Constant') then
								local distOff = thisDist-distOffset
								local currentSpeed = self.velocity[set]
								local deceleration = currentSpeed^2/(2*math.max(.001, distOff))
								local SPEED = math.max(0, currentSpeed-deceleration*dtTime)
								self.velocity[set] = math.max(minSpeed, SPEED)
							end
						end

						self.alpha[set] = math.clamp(self.alpha[set]-((self.velocity[set]/doorSpeed)/duration)*dtTime, 0, 1)
						
						doorSpeedValue.Value = -math.abs(self.velocity[set])

						if (doorEngineClass.config.Doors.New_Attachment_Doors_Config.Enable) then
							for _,weld in pairs(carWelds:GetChildren()) do
								weld.C0 = weld:GetAttribute('closedPoint'):Lerp(weld:GetAttribute('openPoint'), self.alpha[set])
								if (weld:FindFirstChild('Door_Weld')) then
									local data = getFloorWeldFromCarWeld(weld.Door_Weld.Value)
									if (data) then
										local goal = CFrame.new((weld:GetAttribute('closedPoint').Position-weld:GetAttribute('openPoint').Position).Unit*(doorEngineClass.config.Doors.New_Attachment_Doors_Config.Attachment_Threshold))*(weld:GetAttribute('closedPoint'):Lerp(weld:GetAttribute('openPoint'), self.alpha[set]))
										weld.Door_Weld.Value.C0 = CFrame.new(
											math.clamp(goal.X,data:GetAttribute('openPoint').X >= data:GetAttribute('closedPoint').X and data:GetAttribute('closedPoint').X or data:GetAttribute('openPoint').X,data:GetAttribute('openPoint').X <= data:GetAttribute('closedPoint').X and data:GetAttribute('closedPoint').X or data:GetAttribute('openPoint').X),
											math.clamp(goal.Y,data:GetAttribute('openPoint').Y >= data:GetAttribute('closedPoint').Y and data:GetAttribute('closedPoint').Y or data:GetAttribute('openPoint').Y,data:GetAttribute('openPoint').Y <= data:GetAttribute('closedPoint').Y and data:GetAttribute('closedPoint').Y or data:GetAttribute('openPoint').Y),
											math.clamp(goal.Z,data:GetAttribute('openPoint').Z >= data:GetAttribute('closedPoint').Z and data:GetAttribute('closedPoint').Z or data:GetAttribute('openPoint').Z,data:GetAttribute('openPoint').Z <= data:GetAttribute('closedPoint').Z and data:GetAttribute('closedPoint').Z or data:GetAttribute('openPoint').Z)
										)
									end
								end
							end
						else
							for i, v in pairs(doorWelds:GetChildren()) do
								v.C0 = v:GetAttribute('closedPoint'):Lerp(v.C1, self.alpha[set])
							end
						end

						-- // Check distance for lanterns reset ratio // --
						if ((thisDist/dist) <= doorEngineClass.config.Color_Database.Lanterns.Door_Distance_Reset_Ratio and (not self.lanternsReset)) then
							self.lanternsReset = true
							self.LanternsReset:Fire({'Interior', 'Exterior'})
						end

						if (checkWelds('closedPoint', doorEngineClass.config.Doors.New_Attachment_Doors_Config.Closing_Min_Threshold, true) and self.state == 'Closing') then
							self.state = 'Closed'
							core.statValues[`{self.sideJoin}Door_State`] = self.state
							task.spawn(coreFunctions.updateStatValues)
							if (not self.lanternsReset) then
								self.lanternsReset = true
								self.LanternsReset:Fire({'Interior', 'Exterior'})
								for i, v in pairs(self.sensorLEDs) do
									v.Color = doorEngineClass.config.Doors.Sensor_LED_Data.Opening_Color.Inactive.Color
									v.Material = doorEngineClass.config.Doors.Sensor_LED_Data.Opening_Color.Inactive.Material
								end
							end
							self.Closed:Fire()
						end

						dtTime = heartbeat:Wait()

					end
					if (self.state ~= 'Closing') then return end
					self.velocity[set] = 0
					doorSpeedValue.Value = 0
					if (checkWelds('closedPoint', 0, true) and self.state == 'Closing') then
						self.state = 'Closed'
						core.statValues[`{self.sideJoin}Door_State`] = self.state
						task.spawn(coreFunctions.updateStatValues)
						if (not self.lanternsReset) then
							self.lanternsReset = true
							self.LanternsReset:Fire({'Interior', 'Exterior'})
							for i, v in pairs(self.sensorLEDs) do
								v.Color = doorEngineClass.config.Doors.Sensor_LED_Data.Opening_Color.Inactive.Color
								v.Material = doorEngineClass.config.Doors.Sensor_LED_Data.Opening_Color.Inactive.Material
							end
						end
						self.Closed:Fire()
					end
				else
					local newThread = task.spawn(function()
						while (self.state == 'Closing') do
							local data = doorEngineClass.config.Doors.Sensor_LED_Data.Closing_Color
							local cfg = (tick()-lastSLEDTick)/data.Flash_Time < 1 and data.Active or data.Inactive
							if ((tick()-lastSLEDTick)/data.Flash_Time/2 > 1) then
								lastSLEDTick = tick()
							end
							for i, v in pairs(self.sensorLEDs) do
								v.Color = cfg.Color
								v.Material = cfg.Material
							end
							heartbeat:Wait()
						end
					end)
					table.insert(self.openingThreads, newThread)
					for i, v in pairs(doorWelds:GetChildren()) do
						local newThread = task.spawn(function()
							local innerDoorsData, outerDoorsData = doorEngineClass.config.Doors.Realistic_Doors_Data, doorEngineClass.config.Doors.Realistic_Outer_Doors_Data
							local data = doorEngineClass.config.Doors[set == 'Inner' and 'Realistic_Doors_Data' or 'Realistic_Outer_Doors_Data']
							local hasCompleted = legacyEasing.interpolate(v, v:GetAttribute(data.Enable_Close and 'interlockClosedPoint' or 'closedPoint'), doorEngineClass.config.Doors.Close_Easing_Style, duration*distanceFactor, function() return {self.state ~= 'Closing'} end)
							if (not hasCompleted) then return end
							if (data.Enable_Close) then
								local hasCompleted = legacyEasing.interpolate(v, v:GetAttribute('closedPoint'), data.Close_Easing_Style, data.Close_Time, function()
									if (checkWelds('closedPoint', doorEngineClass.config.Doors.New_Attachment_Doors_Config.Closing_Min_Threshold, true) and self.state == 'Closing') then
										self.state = 'Closed'
										core.statValues[`{self.sideJoin}Door_State`] = self.state
										task.spawn(coreFunctions.updateStatValues)
										if (not self.lanternsReset) then
											self.lanternsReset = true
											self.LanternsReset:Fire({'Interior', 'Exterior'})
										end
										self.Closed:Fire()
									end
									return {} end)
								if (not hasCompleted) then return end
							end
							if (self.state ~= 'Closing') then return end
							if (checkWelds('closedPoint', 0, true) and self.state == 'Closing') then
								if (not self.lanternsReset) then
									self.lanternsReset = true
									self.LanternsReset:Fire({'Interior', 'Exterior'})
								end
								self.state = 'Closed'
								core.statValues[`{self.sideJoin}Door_State`] = self.state
								task.spawn(coreFunctions.updateStatValues)
								self.Closed:Fire()
							end
						end)
						table.insert(self.openingThreads, newThread)
					end
				end
			end
			
			if (doorEngineClass.config.Doors.Door_Delay_Sequence_Config.Closing.Enable) then
				if (self.state ~= 'Closing') then return end
				task.spawn(function()
					for i, part in ipairs(doorEngineClass.config.Doors.Door_Delay_Sequence_Config.Closing.Sequence_Order) do
						local thread = task.spawn(runDoor, part)
						table.insert(self.openingThreads, thread)
						self.openingThreads[i] = nil
						local hasCompleted = coreFunctionsModule.conditionalWait(doorEngineClass.config.Doors.Door_Delay_Sequence_Config.Closing.Delay, function()
							return {self.state == 'Closing'}
						end)
						if (not hasCompleted) then return end
					end
				end)
			else
				for i, v in pairs({'Inner', 'Outer'}) do
					local thread = task.spawn(runDoor, v)
					table.insert(self.openingThreads, thread)
					self.openingThreads[i] = nil
				end
			end
		end)
	end
	function self:IsValid(floor)
		local registeredFloor = coreFunctions.findRegisteredFloor(floor)
		if (not registeredFloor) then return false end
		local carWelds, floorWelds = car.Door_Engine_Welds:FindFirstChild(self.side), registeredFloor.floorInstance.Door_Engine_Welds:FindFirstChild(self.side)
		if ((not carWelds) or (not floorWelds)) then return false end
		return true
	end
	return self
end

function doorEngineClass.setUp(doorSet)
	if (doorSet.Name == 'Doors') then doorSet.Name = 'Front_Doors' end
	local side = string.split(doorSet.Name, 'Doors')[2] and string.split(doorSet.Name, 'Doors')[1]
	if (not side) then return end
	side = string.split(side, '_')[1]
	if (side == '') then side = 'Front' end
	local sideJoin = `{side == '' and '' or `{side}_`}`
	local parent = doorSet.Parent
	local elevator = doorEngineClass.elevator
	local car = elevator:FindFirstChild('Car')
	local platform = car:FindFirstChild('Platform')
	local level = parent:FindFirstChild('Level')
	local carLevel = car:FindFirstChild('Level') or platform
	local doorWeldsFolder = coreFunctions.createInstance(parent, `{sideJoin}Door_Welds`, 'Folder', true)
	local doorEngineWeldsFolder = coreFunctions.createInstance(parent, 'Door_Engine_Welds', 'Folder', true)
	local doorEngineWeldsFolder_Side = coreFunctions.createInstance(doorEngineWeldsFolder, side, 'Folder', true)

	local doorSpeedValue = coreFunctions.createInstance(doorSet:IsDescendantOf(car) and elevator:WaitForChild('Legacy') or parent, `{sideJoin}Door_Speed`, 'NumberValue', true)

	if (doorSet:IsDescendantOf(car)) then
		local boundsCf, boundsSize = doorSet:GetBoundingBox()
		local doorSensorPartsFolder = coreFunctions.createInstance(car, 'Door_Sensor_Parts', 'Folder', true)
		local doorSensorPart = coreFunctions.createInstance(doorSensorPartsFolder, `{sideJoin}Sensor`, 'Part', true, {
			Anchored = false,
			CanCollide = false,
			CanQuery = false,
			Transparency = 1,
			CFrame = boundsCf,
			Size = boundsSize,
		})
		coreFunctions.weldParts(doorSensorPart, doorSensorPart, platform, true, false)
	end

	for _,v in pairs(doorSet:GetChildren()) do
		local scaler = v:FindFirstChild('Scaler')
		if (not scaler) then continue end
		local open = scaler:FindFirstChild('Open')
		if (not open) then
			open = Instance.new('Part')
			open.Name = 'Open'
			open.Size = scaler.Size
			open.CanCollide = false
			open.Color = scaler.Color
			local cf = scaler.CFrame:ToWorldSpace(CFrame.new(0, 0, -((scaler.Parent.Name:sub(2,2) == 'R' and 1 or scaler.Parent.Name:sub(2,2) == 'L' and -1 or 0)*scaler.Size.Magnitude*.9)*scaler.Parent.Name:sub(3)))
			open.CFrame = cf
			open.Transparency = 1
			open.Parent = scaler
		end
		coreFunctions.weldParts(doorWeldsFolder, open, level, true, false)
		local engineWeld = coreFunctions.weldParts(doorEngineWeldsFolder_Side, scaler, open, true, false)
		engineWeld.Name = 'Door_Engine_Weld'
		engineWeld:SetAttribute('closedPoint', engineWeld.C0)
		engineWeld:SetAttribute('openPoint', engineWeld.C1)
		local x, y, z = engineWeld.C1:ToEulerAnglesXYZ()
		local data = doorEngineClass.config.Doors[engineWeld:IsDescendantOf(doorSet) and 'Realistic_Doors_Data' or 'Realistic_Outer_Doors_Data']
		local rotOpen = Vector3.new(x, y, z)/data.Open_Ratio
		local rotClosed = Vector3.new(x, y, z)/data.Close_Ratio
		engineWeld:SetAttribute('interlockOpenPoint', CFrame.new(engineWeld.C1.Position-(engineWeld.C1.Position/data.Open_Ratio))*CFrame.Angles(rotOpen.X, rotOpen.Y, rotOpen.Z))
		engineWeld:SetAttribute('interlockClosedPoint', CFrame.new(engineWeld.C1.Position-(engineWeld.C1.Position/data.Close_Ratio))*CFrame.Angles(rotClosed.X, rotClosed.Y, rotClosed.Z))
		coreFunctions.weldModel(v, scaler, {open}, doorWeldsFolder)
		scaler.Anchored = false
		scaler.CanQuery = true
		open.Anchored = false
	end
end

return doorEngineClass