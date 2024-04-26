local module = {}
local doorEngineClass = {}
doorEngineClass.__index = doorEngineClass
doorEngineClass.ClassName = 'doorEngineClass'

local HEARTBEAT = _G.Cortex_SERVER.EVENTS.RUNTIME_EVENT.EVENT

function module:INITIATE_PLUGIN_INTERNAL(CORE, SOURCE)
	local storage = require(CORE.Core_Modules_INTERNAL:WaitForChild('Storage'))
	local signal = require(CORE.Core_Modules_INTERNAL:WaitForChild('Signal'))
	local coreFunctions = require(CORE.Core_Modules_INTERNAL:WaitForChild('Core_Functions'))
	local legacyEasing = require(CORE.Core_Modules_INTERNAL:WaitForChild('Legacy_Easing'))

	local runService = game:GetService('RunService')
	local collectionService = game:GetService('CollectionService')

	module.INTERNAL_STORAGE = {} --DO NOT TOUCH! INTERNAL STORAGE FOR THE MODULE

	--IMPORTING CORE FUNCTIONS FOR SHARED USE--
	local function getAccelerationTime(...)
		return coreFunctions:getAccelerationTime(...)
	end
	local function getDecelerationRate(...)
		return coreFunctions:getDecelerationRate(...)
	end
	local function lerp(...)
		return coreFunctions:lerp(...)
	end
	local function conditionalStepWait(...)
		return coreFunctions:conditionalStepWait(...)
	end
	local function getTableLength(...)
		return coreFunctions:getTableLength(...)
	end

	function module.new(side, data)
		local self = setmetatable({}, doorEngineClass)
		----------------------------------------------------
		self.doorTimerTick = 0
		self.nudgeTimerTick = 0
		self.nudgeTick = 0
		self.state = 'Closed'
		self.stopped = false
		self.isKeyed = false
		self.side = side
		self.delaying = false
		self.nudging = false
		self.doorHold = false
		self.valueInstances = {
			doorStateValue = data.values.doorStateValue,
			doorSpeedValue = data.values.doorSpeedValue
		}
		self.sounds = {
			doorMotorSound = data.sounds.doorMotorSound,
			doorOpenSound = data.sounds.doorOpenSound,
			doorCloseSound = data.sounds.doorCloseSound
		}
		self.isObstructed = false
		self.nudgeStop = false
		self.engineWelds = {car={},floors={}}
		self.doorTimerLength = {}
		self.config = data.config
		self.sensorLEDs = {}
		self.alpha = {inner=0,outer=0}
		self.velocity = {inner=0,outer=0}
		self.currentStage = {inner=1,outer=1}
		self.masterWeld = {inner={},outer={}}
		self.decelerating = {inner=false,outer=false}
		self.startTick = {inner=nil,outer=nil}
		self.decelTime = {inner=nil,outer=nil}
		self.prevSpeed = {inner=nil,outer=nil}
		self.prevDist = {inner=nil,outer=nil}
		self.lastVel = {inner=nil,outer=nil}
		self.delayTick = {inner=nil,outer=nil}
		self.doorSensorPart = data.doorSensorPart
		self.lanternsReset = false
		self.doorSet = data.doorSet

		--Door event listeners--
		self.Opening = signal.new()
		self.Opened = signal.new()

		self.Closing = signal.new()
		self.Closed = signal.new()
		self.LanternsReset = signal.new()

		--Door state internal functions--
		function self.updateDoorState(state)
			self.valueInstances.doorStateValue.Value = state
			self.state = state
		end
		function self.getDoorState()
			return self.state
		end
		function self.checkWelds(floor: number, target: string, threshold: number, checkFloorWelds: boolean?)
			for i,v in next,self.engineWelds do
				for i,w in next,(i == 'car' and self.engineWelds.car or (checkFloorWelds and self.engineWelds.floors[tostring(floor)]) or {}) do
					for i,w2 in next,w do
						if ((w2[target].Position-w2.instance.C0.Position).Magnitude > threshold) then return false end
					end
				end
			end
			return true
		end
		----------------------------------------------------

		self.statisticValues = storage:get('mainElevatorData', 'legacy')
		self.getAccelerationTime = storage:get('mainElevatorData', 'getAccelerationTime')
		self.findFloor = storage:get('mainElevatorData', 'findFloor')
		self.car = storage:get('mainElevatorData', 'car')

		function self:Open(floor: number, onOpened: (any?) -> any?)
			local startingState = self.state
			local rawFloor = floor
			local thisFloor = self.findFloor(rawFloor)
			--if ((startingState ~= 'Closed' and startingState ~= 'Closing' and startingState ~= 'Stopped') or ((not car:FindFirstChild(`{self.side == '' and '' or `{self.side}_`}Doors`)) or (not thisFloor:FindFirstChild(`{self.side == '' and '' or `{self.side}_`}Doors`)))) then return end
			self.Opening:Fire()
			self.updateDoorState('Opening')

			local duration = self.config.Doors.Door_Open_Speed
			if (not thisFloor) then return warn(`Floor not found! {rawFloor}`) end
			local distanceFactor = 0
			for i,w in next,self.engineWelds do
				local newTable = (i == 'car' and self.engineWelds.car[self.side] or {})
				for i,weld in next,newTable do
					distanceFactor = math.clamp(distanceFactor+((weld:getCurrentDistance()/weld.distanceFromOpenPosition)/(getTableLength(self.engineWelds)*getTableLength(newTable))*2), .15, 1)
				end
			end
			---
			self.sounds.doorCloseSound:Stop()
			task.spawn(function()
				if (startingState == 'Closed') then
					local isCompleted = conditionalStepWait(self.config.Doors.Door_Open_Sound_Delay, function()
						return {self.state ~= 'Opening'}
					end)
					if (not isCompleted) then return end
				end
				self.sounds.doorOpenSound.TimePosition = (self.sounds.doorOpenSound.TimeLength*(1-distanceFactor))
				task.wait()
				self.sounds.doorOpenSound:Play()
			end)
			---
			local isCompleted = conditionalStepWait(startingState == 'Closed' and self.config.Doors.Open_Delay or startingState == 'Closing' and self.config.Doors.Reopen_Delay or 0, function()
				return {self.state ~= 'Opening'}
			end)
			if (not isCompleted) then return end

			local function runDoor(_types: {string})
				for i,doorType in pairs(typeof(_types) == 'table' and _types or {}) do
					for i,w in next,self.engineWelds do
						local newIndex = i == 'car' and 'Inner' or 'Outer'
						if (newIndex == doorType) then
							if (newIndex == 'Inner' or (newIndex == 'Outer' and (not self.config.Doors.New_Attachment_Doors_Config.Enable))) then
								local indexLower = string.lower(newIndex)
								local newWeldsList = (i == 'car' and self.engineWelds.car[self.side] or self.engineWelds.floors[tostring(rawFloor)] and self.engineWelds.floors[tostring(rawFloor)][self.side] or {})
								local floorWelds = self.engineWelds.floors[tostring(rawFloor)] and self.engineWelds.floors[tostring(rawFloor)][self.side]
								local setupConfig = self.config.Doors.Custom_Door_Operator_Config[newIndex].Opening
								if (setupConfig and setupConfig.Enable) then
									task.spawn(function()
										local distance = 0
										for i,v in next,newWeldsList do
											if ((v.openPosition.Position-v.closedPosition.Position).Magnitude >= distance and v.side == self.side and ((newIndex == 'Inner' and v.instance:IsDescendantOf(self.car)) or (newIndex == 'Outer' and v.instance:IsDescendantOf(thisFloor)))) then
												self.masterWeld[indexLower] = v
												distance = (v.openPosition.Position-v.closedPosition.Position).Magnitude
											end
										end
										if (not self.masterWeld[indexLower]) then return end
										local targetPosition = self.masterWeld[indexLower].openPosition
										local startTime = os.clock()
										local startC0 = self.masterWeld[indexLower].closedPosition

										local speed = math.clamp((distance/duration), 1, math.huge)
										local minSpeed = math.clamp(setupConfig.Minimum_Speed or .05, 0, speed)

										if (startingState == 'Closed' and self.config.Doors.New_Attachment_Doors_Config.Enable) then
											if (typeof(floorWelds) == 'table') then
												local function getEngineWeld(part: BasePart?)
													for _,v in pairs(floorWelds) do
														if (v.instance.Part0 == part) then return v end
													end
													return nil
												end
												local params = RaycastParams.new()
												params.FilterType = Enum.RaycastFilterType.Include
												local list = {}
												for _,weld in pairs(floorWelds) do
													table.insert(list, weld.instance.Part0)
												end
												params.FilterDescendantsInstances = list
												for _,weld in pairs(self.engineWelds.car[self.side]) do
													local result = workspace:Blockcast(CFrame.new(weld.instance.Part0.CFrame.Position), Vector3.new(0, weld.instance.Part0.Size.Y, 0), (thisFloor.Level.Position-self.car.Level.Position).Unit*5, params)
													if ((not result) or (not result.Instance)) then continue end
													weld.floorDoorWeld = getEngineWeld(result.Instance)
												end
											end
										end

										local accelerationTime = self.getAccelerationTime(self.velocity[indexLower], speed, setupConfig.Acceleration)
										local stageAccelTime
										local startLerpTime = os.clock()
										local lastStageTick = startLerpTime
										local distOffset = math.clamp(setupConfig.Deceleration_Offset, 0, math.huge)

										self.decelerating[indexLower] = false
										self.velocity[indexLower] = -self.velocity[indexLower]
										self.lastVel[indexLower] = nil
										self.delayTick[indexLower] = nil
										local startVelocity = self.velocity[indexLower]
										if (startingState ~= 'Closed') then
											self.currentStage[indexLower] = typeof(setupConfig.Custom_Acceleration_Stages) == 'table' and #setupConfig.Custom_Acceleration_Stages
										end

										local lastTick,delta = os.clock(),0
										local multi,multi2 = 0,0
										local reachedMinSpeed = false
										local function updateDoorSpeed()
											if (indexLower == 'inner') then
												self.valueInstances.doorSpeedValue.Value = math.abs(self.velocity[indexLower])
											elseif (indexLower == 'outer') then
												local doorSpeed = thisFloor:FindFirstChild(`{side ~= '' and `{side}_` or ''}Door_Speed`)
												if (doorSpeed) then
													doorSpeed.Value = math.abs(self.velocity[indexLower])
												end
											end
										end
										
										local delta = 0
										while (self.alpha[indexLower] < 1 and self.masterWeld[indexLower].instance) do
											local thisDist = (targetPosition.Position-self.masterWeld[indexLower].instance.C0.Position).Magnitude
											local thisDistCheck = (thisDist/distance) <= setupConfig.Deceleration_Distance*(math.clamp((self.velocity[indexLower])/speed, 0, 1))
											local thisStage = typeof(setupConfig.Custom_Acceleration_Stages) == 'table' and setupConfig.Custom_Acceleration_Stages[self.currentStage[indexLower]]
											if ((not thisDistCheck) and (not self.decelerating[indexLower])) then
												if (thisStage) then
													local thisAcceleration = thisStage.Acceleration == 'USE_ACCELERATION' and setupConfig.Acceleration or thisStage.Acceleration
													if (not stageAccelTime) then
														self.lastVel[indexLower] = self.velocity[indexLower]
														self.delayTick[indexLower] = os.clock()
														stageAccelTime = self.getAccelerationTime(self.lastVel[indexLower], math.clamp(thisStage.Speed, 0, speed), thisAcceleration)
														multi = 0
													end
													if ((not self.lastVel[indexLower]) or (not self.delayTick[indexLower]) or (not stageAccelTime)) then continue end
													local stageSpeed = math.clamp(thisStage.Speed, 0, speed)
													if (stageAccelTime) then
														if ((not thisStage.Acceleration_Rate) or (not thisStage.Acceleration_Rate.Rate) or thisStage.Acceleration_Rate.Rate == 'Constant') then
															self.velocity[indexLower] = lerp(self.lastVel[indexLower],stageSpeed, math.clamp((os.clock()-lastStageTick)/stageAccelTime, 0, 1))
														elseif (thisStage.Acceleration_Rate.Rate == 'Gradual') then
															local rate = 1/math.deg(thisStage.Acceleration_Rate.Gradual_Duration)
															multi = math.clamp(multi+rate*math.deg(delta), 0, 1)
															self.velocity[indexLower] = math.clamp(self.velocity[indexLower]+thisAcceleration*multi*math.deg(delta), -stageSpeed, stageSpeed)
														end
													end
													if (stageAccelTime and math.clamp((os.clock()-lastStageTick)/stageAccelTime, 0, 1) < 1 and (not thisStage.Ignore_Acceleration_Duration)) then
														self.delayTick[indexLower] = os.clock()
													elseif (self.delayTick[indexLower] and (os.clock()-self.delayTick[indexLower])/thisStage.Delay_Before_Next_Stage >= 1 and typeof(setupConfig.Custom_Acceleration_Stages) == 'table' and setupConfig.Custom_Acceleration_Stages[self.currentStage[indexLower]+1]) then
														lastStageTick = os.clock()
														self.currentStage[indexLower] = math.clamp(self.currentStage[indexLower]+1, 1, math.huge)
														stageAccelTime = nil
													end
													self.currentStage[indexLower] = math.clamp(self.currentStage[indexLower], 0, typeof(setupConfig.Custom_Acceleration_Stages) == 'table' and #setupConfig.Custom_Acceleration_Stages or math.huge)
												else
													if (((not setupConfig.Acceleration_Rate) or (not setupConfig.Acceleration_Rate.Rate) or setupConfig.Acceleration_Rate.Rate == 'Constant')) then
														self.velocity[indexLower] = lerp(self.lastVel[indexLower] or startVelocity, speed, math.clamp((os.clock()-startLerpTime)/accelerationTime, 0, 1))
													elseif (setupConfig.Acceleration_Rate.Rate == 'Gradual') then
														local rate = 1/math.deg(thisStage.Acceleration_Rate.Gradual_Duration)
														multi2 = math.clamp(multi2+rate*math.deg(delta), 0, 1)
														self.velocity[indexLower] = math.clamp(self.velocity[indexLower]+setupConfig.Acceleration*multi2*math.deg(delta), -speed, speed)
													end
												end
												self.velocity[indexLower] = math.clamp(self.velocity[indexLower], -speed, speed)
											end
											if (thisDistCheck or self.decelerating[indexLower] and (not reachedMinSpeed)) then
												local distOff = thisDist-distOffset
												if (not self.decelerating[indexLower]) then
													self.decelerating[indexLower] = true
													self.prevDist[indexLower] = distOff
													self.prevSpeed[indexLower] = math.abs(self.velocity[indexLower])
													self.startTick[indexLower] = os.clock()
												end
												if (setupConfig.Deceleration_Rate == 'Exponential') then
													self.velocity[indexLower] = math.clamp((self.prevSpeed[indexLower]/self.prevDist[indexLower])*distOff, minSpeed, speed)
												elseif (setupConfig.Deceleration_Rate == 'Constant') then
													local currentSpeed = self.velocity[indexLower]
													local deceleration = currentSpeed^2/(2*math.max(.001, distOff))
													local SPEED = math.max(0, currentSpeed-deceleration*delta)
													self.velocity[indexLower] = math.max(minSpeed, SPEED)
												end
												if (self.velocity[indexLower] <= minSpeed) then reachedMinSpeed = true end
											end
											self.alpha[indexLower] = math.min(1, self.alpha[indexLower]+(((self.velocity[indexLower]/speed)/duration))*delta)
											if (self.config.Doors.New_Attachment_Doors_Config.Enable) then
												for _,weld in pairs(self.engineWelds.car[self.side]) do
													_.C0 = weld.closedPosition:Lerp(weld.openPosition, self.alpha[indexLower])
													if (weld.floorDoorWeld) then
														local data = floorWelds[weld.floorDoorWeld.instance]
														if (data) then
															local goal = CFrame.new(self.config.Doors.New_Attachment_Doors_Config.Attachment_Threshold,0,0)*(data.closedPosition:Lerp(data.openPosition, self.alpha[indexLower]))
															weld.floorDoorWeld.instance.C0 = CFrame.new(
																math.clamp(goal.X,data.openPosition.X >= data.closedPosition.X and data.closedPosition.X or data.openPosition.X,data.openPosition.X <= data.closedPosition.X and data.closedPosition.X or data.openPosition.X),
																math.clamp(goal.Y,data.openPosition.Y >= data.closedPosition.Y and data.closedPosition.Y or data.openPosition.Y,data.openPosition.Y <= data.closedPosition.Y and data.closedPosition.Y or data.openPosition.Y),
																math.clamp(goal.Z,data.openPosition.Z >= data.closedPosition.Z and data.closedPosition.Z or data.openPosition.Z,data.openPosition.Z <= data.closedPosition.Z and data.closedPosition.Z or data.openPosition.Z)
															)
														end
													end
												end
											else
												for i,weld in next,newWeldsList do
													if ((indexLower == 'inner' and weld.instance:IsDescendantOf(self.car)) or (indexLower == 'outer' and weld.instance:IsDescendantOf(thisFloor))) then
														weld.instance.C0 = weld.closedPosition:Lerp(weld.openPosition, math.clamp(self.alpha[indexLower], 0, 1))
													end
												end
											end
											if (self.state ~= 'Opening' and self.state ~= 'Open') then
												self.velocity[indexLower] = 0
												self.sounds.doorOpenSound:Stop()
												self.sounds.doorCloseSound:Stop()
												task.spawn(updateDoorSpeed)
												break
											end
											task.spawn(updateDoorSpeed)
											if (self.checkWelds(rawFloor, 'openPosition', .05) and self.state == 'Opening') then
												self.updateDoorState('Open')
												if (typeof(onOpened) == 'function') then task.spawn(onOpened) end
												self.Opened:Fire()
											end
											delta = HEARTBEAT:Wait()
										end
										task.wait()
										if (self.checkWelds(rawFloor, 'openPosition', .05) and self.state == 'Opening') then
											self.updateDoorState('Open')
											if (typeof(onOpened) == 'function') then task.spawn(onOpened) end
											self.Opened:Fire()
										end
										if (self.state ~= 'Open') then return end
										self.valueInstances.doorSpeedValue.Value = 0
										for i,v in next,self.velocity do
											self.velocity[i] = 0
											self.decelerating[i] = false
										end
										task.spawn(updateDoorSpeed)
									end)
								end
							end
						end
					end
				end
			end
			if (self.config.Doors.Door_Delay_Sequence_Config.Opening.Enable) then
				if (self.state ~= 'Opening') then return end
				task.spawn(function()
					for i,part in ipairs(self.config.Doors.Door_Delay_Sequence_Config.Opening.Sequence_Order) do
						runDoor({part})
						local hasCompleted = conditionalStepWait(self.config.Doors.Door_Delay_Sequence_Config.Opening.Delay, function()
							return {self.state ~= 'Opening'}
						end)
						if (not hasCompleted) then return end
					end
				end)
			else
				runDoor({'Inner','Outer'})
			end
		end

		function self:Close(floor: number, NUDGE: boolean?, onClosed: (any?) -> any?)
			local startingState = self.state
			local rawFloor = floor
			local thisFloor = self.findFloor(rawFloor)
			if (not thisFloor) then return warn(`Floor not found! {rawFloor}`) end
			--if ((startingState ~= 'Open' and startingState ~= 'Stopped') or ((not self.car:FindFirstChild(`{self.side == '' and '' or `{self.side}_`}Doors`)) or (not thisFloor:FindFirstChild(`{self.side == '' and '' or `{self.side}_`}Doors`)))) then return end
			self.Closing:Fire()
			self.updateDoorState('Closing')
			---
			self.sounds.doorOpenSound:Stop()
			task.spawn(function()
				local isCompleted = conditionalStepWait(self.config.Doors.Door_Close_Sound_Delay, function()
					return {self.state ~= 'Closing'}
				end)
				if (not isCompleted) then return end
				self.sounds.doorCloseSound:Play()
			end)
			---
			for i,w in next,self.engineWelds do
				local newIndex = i == 'car' and 'Interior' or 'Exterior'
				if (self.config.Color_Database.Lanterns[newIndex] and (not self.config.Color_Database.Lanterns[newIndex].Reset_After_Door_Close)) then
					self.lanternsReset = true
					self.LanternsReset:Fire()
				end
			end
			local duration = NUDGE and (self.config.Doors.Nudge_Speed or self.config.Doors.Door_Close_Speed*1.5) or self.config.Doors.Door_Close_Speed
			local distanceFactor = 0
			for i,w in next,self.engineWelds do
				local newTable = (i == 'car' and self.engineWelds.car[self.side] or {})
				for i,weld in next,newTable do
					distanceFactor = math.clamp(distanceFactor+(((weld.closedPosition.Position-weld.instance.C0.Position).Magnitude/weld.distanceFromOpenPosition)/(getTableLength(self.engineWelds)*getTableLength(newTable))*2), .15, 1)
				end
			end
			--duration = duration*(tonumber(distanceFactor) or 1)
			local isCompleted = conditionalStepWait(self.config.Doors.Close_Delay, function()
				return {self.state ~= 'Closing'}
			end)
			if (not isCompleted) then return end
			self.lanternsReset = false
			local function runDoor(_types: {string})
				for i,doorType in pairs(typeof(_types) == 'table' and _types or {}) do
					for i,w in next,self.engineWelds do
						local newIndex = i == 'car' and 'Inner' or 'Outer'
						if (newIndex == doorType and (newIndex == 'Inner' or (newIndex == 'Outer' and (not self.config.Doors.New_Attachment_Doors_Config.Enable)))) then
							local indexLower = string.lower(newIndex)
							local newWeldsList = (i == 'car' and self.engineWelds.car[self.side] or self.engineWelds.floors[tostring(rawFloor)] and self.engineWelds.floors[tostring(rawFloor)][self.side] or {})
							local floorWelds = self.engineWelds.floors[tostring(rawFloor)] and self.engineWelds.floors[tostring(rawFloor)][self.side]
							local setupConfig = self.config.Doors.Custom_Door_Operator_Config[newIndex].Closing
							if (setupConfig and setupConfig.Enable) then
								task.spawn(function()
									local distance = 0
									for i,v in next,newWeldsList do
										if ((v.openPosition.Position-v.closedPosition.Position).Magnitude >= distance and v.side == v.side and (newIndex == 'Inner' and v.instance:IsDescendantOf(self.car) or newIndex == 'Outer' and v.instance:IsDescendantOf(thisFloor))) then
											self.masterWeld[indexLower] = v
											distance = (v.openPosition.Position-v.closedPosition.Position).Magnitude
										end
									end
									local targetPosition = self.masterWeld[indexLower].closedPosition
									local startTime = os.clock()
									local startC0 = self.masterWeld[indexLower].openPosition

									local speed = math.clamp((distance/duration), 1, math.huge)
									local minSpeed = math.clamp(setupConfig.Minimum_Speed or .05, 0, speed)

									local accelerationTime = self.getAccelerationTime(self.velocity[indexLower], speed, setupConfig.Acceleration)
									local stageAccelTime
									local startLerpTime = os.clock()
									local lastStageTick = startLerpTime
									local distOffset = math.clamp(setupConfig.Deceleration_Offset, 0, math.huge)

									self.decelerating[indexLower] = false
									self.velocity[indexLower] = -self.velocity[indexLower]
									self.lastVel[indexLower] = nil
									self.delayTick[indexLower] = nil
									local startVelocity = self.velocity[indexLower]
									if (startingState == 'Open') then
										self.currentStage[indexLower] = typeof(setupConfig.Custom_Acceleration_Stages) == 'table' and #setupConfig.Custom_Acceleration_Stages or 0
									end

									local lastTick,delta = os.clock(),0
									local multi,multi2 = 0,0
									local reachedMinSpeed = false
									local function updateDoorSpeed()
										if (indexLower == 'inner') then
											self.valueInstances.doorSpeedValue.Value = -math.abs(self.velocity[indexLower])
										elseif (indexLower == 'outer') then
											local doorSpeed = thisFloor:FindFirstChild(`{side ~= '' and `{side}_` or ''}Door_Speed`)
											if (doorSpeed) then
												doorSpeed.Value = -math.abs(self.velocity[indexLower])
											end
										end
									end
									
									local delta = 0
									while (self.alpha[indexLower] > 0 and self.masterWeld[indexLower].instance) do
										local thisDist = (targetPosition.Position-self.masterWeld[indexLower].instance.C0.Position).Magnitude
										local thisDistCheck = (thisDist/distance) <= setupConfig.Deceleration_Distance*(math.clamp((self.velocity[indexLower])/speed, 0, 1))
										local thisStage = typeof(setupConfig.Custom_Acceleration_Stages) == 'table' and setupConfig.Custom_Acceleration_Stages[#setupConfig.Custom_Acceleration_Stages-(self.currentStage[indexLower]-1)]
										if ((not thisDistCheck) and (not self.decelerating[indexLower])) then
											if (thisStage) then
												local thisAcceleration = thisStage.Acceleration == 'USE_ACCELERATION' and setupConfig.Acceleration or thisStage.Acceleration
												if (not stageAccelTime) then
													self.lastVel[indexLower] = self.velocity[indexLower]
													self.delayTick[indexLower] = os.clock()
													stageAccelTime = self.getAccelerationTime(self.lastVel[indexLower], math.clamp(thisStage.Speed, 0, speed), thisStage.Acceleration == 'USE_ACCELERATION' and setupConfig.Acceleration or thisStage.Acceleration)
													multi = 0
												end
												if ((not self.lastVel[indexLower]) or (not self.delayTick[indexLower]) or (not stageAccelTime)) then continue end
												local stageSpeed = math.clamp(thisStage.Speed, 0, speed)
												if (stageAccelTime and ((not thisStage.Acceleration_Rate) or (not thisStage.Acceleration_Rate.Rate) or thisStage.Acceleration_Rate.Rate == 'Constant')) then
													self.velocity[indexLower] = lerp(self.lastVel[indexLower], math.clamp(thisStage.Speed, 0, speed), math.clamp((os.clock()-lastStageTick)/stageAccelTime, 0, 1))
												elseif (thisStage.Acceleration_Rate.Rate == 'Gradual') then
													local rate = 1/math.deg(thisStage.Acceleration_Rate.Gradual_Duration)
													multi = math.clamp(multi+rate*math.deg(delta), 0, 1)
													self.velocity[indexLower] = math.clamp(self.velocity[indexLower]+thisAcceleration*multi*math.deg(delta), -stageSpeed, stageSpeed)
												end
												if (stageAccelTime and math.clamp((os.clock()-lastStageTick)/stageAccelTime, 0, 1) < 1 and (not thisStage.Ignore_Acceleration_Duration)) then
													self.delayTick[indexLower] = os.clock()
												elseif (self.delayTick[indexLower] and (os.clock()-self.delayTick[indexLower])/thisStage.Delay_Before_Next_Stage >= 1 and typeof(setupConfig.Custom_Acceleration_Stages) == 'table' and setupConfig.Custom_Acceleration_Stages[self.currentStage[indexLower]-1]) then
													lastStageTick = os.clock()
													self.currentStage[indexLower] = math.clamp(self.currentStage[indexLower]-1, 1, math.huge)
													stageAccelTime = nil
												end
												self.currentStage[indexLower] = math.clamp(self.currentStage[indexLower], 0, typeof(setupConfig.Custom_Acceleration_Stages) == 'table' and #setupConfig.Custom_Acceleration_Stages or math.huge)
											else
												if (((not setupConfig.Acceleration_Rate) or (not setupConfig.Acceleration_Rate.Rate) or setupConfig.Acceleration_Rate.Rate == 'Constant')) then
													self.velocity[indexLower] = lerp(self.lastVel[indexLower] or startVelocity, speed, math.clamp((os.clock()-startLerpTime)/accelerationTime, 0, 1))
												elseif (setupConfig.Acceleration_Rate.Rate == 'Gradual') then
													local rate = 1/math.deg(thisStage.Acceleration_Rate.Gradual_Duration)
													multi2 = math.clamp(multi2+rate*math.deg(delta), 0, 1)
													self.velocity[indexLower] = math.clamp(self.velocity[indexLower]+setupConfig.Acceleration*multi2*math.deg(delta), -speed, speed)
												end
											end
											self.velocity[indexLower] = math.clamp(self.velocity[indexLower], -speed, speed)
										end
										if (thisDistCheck or self.decelerating[indexLower] and (not reachedMinSpeed)) then
											local distOff = thisDist-distOffset
											if (not self.decelerating[indexLower]) then
												self.decelerating[indexLower] = true
												self.prevDist[indexLower] = distOff
												self.prevSpeed[indexLower] = math.abs(self.velocity[indexLower])
												self.startTick[indexLower] = os.clock()
												self.decelTime[indexLower] = self.getAccelerationTime(self.prevSpeed[indexLower], minSpeed, getDecelerationRate(self.prevSpeed[indexLower], minSpeed, self.prevDist[indexLower]))
											end
											if (setupConfig.Deceleration_Rate == 'Exponential') then
												self.velocity[indexLower] = math.clamp((self.prevSpeed[indexLower]/self.prevDist[indexLower])*distOff, minSpeed, speed)
											elseif (setupConfig.Deceleration_Rate == 'Constant') then
												local currentSpeed = self.velocity[indexLower]
												local deceleration = currentSpeed^2/(2*math.max(.001, distOff))
												local SPEED = math.max(0, currentSpeed-deceleration*delta)
												self.velocity[indexLower] = math.max(minSpeed, SPEED)
											end
											if (self.velocity[indexLower] <= minSpeed) then reachedMinSpeed = true end
										end
										--RESET LANTERNS BASED ON RATIO--
										if ((thisDist/distance) <= self.config.Color_Database.Lanterns.Door_Distance_Reset_Ratio and (not self.lanternsReset)) then
											self.lanternsReset = true
											self.LanternsReset:Fire()
										end
										self.alpha[indexLower] = math.max(0, self.alpha[indexLower]-(((self.velocity[indexLower]/speed)/duration))*delta)
										if (self.config.Doors.New_Attachment_Doors_Config.Enable) then
											for _,weld in pairs(self.engineWelds.car[self.side]) do
												_.C0 = weld.closedPosition:Lerp(weld.openPosition, self.alpha[indexLower])
												if (weld.floorDoorWeld) then
													local data = floorWelds[weld.floorDoorWeld.instance]
													if (data) then
														local goal = CFrame.new(self.config.Doors.New_Attachment_Doors_Config.Attachment_Threshold,0,0)*(data.closedPosition:Lerp(data.openPosition, self.alpha[indexLower]))
														weld.floorDoorWeld.instance.C0 = CFrame.new(
															math.clamp(goal.X,data.openPosition.X >= data.closedPosition.X and data.closedPosition.X or data.openPosition.X,data.openPosition.X <= data.closedPosition.X and data.closedPosition.X or data.openPosition.X),
															math.clamp(goal.Y,data.openPosition.Y >= data.closedPosition.Y and data.closedPosition.Y or data.openPosition.Y,data.openPosition.Y <= data.closedPosition.Y and data.closedPosition.Y or data.openPosition.Y),
															math.clamp(goal.Z,data.openPosition.Z >= data.closedPosition.Z and data.closedPosition.Z or data.openPosition.Z,data.openPosition.Z <= data.closedPosition.Z and data.closedPosition.Z or data.openPosition.Z)
														)
													end
												end
											end
										else
											for i,weld in next,newWeldsList do
												if ((indexLower == 'inner' and weld.instance:IsDescendantOf(self.car)) or (indexLower == 'outer' and weld.instance:IsDescendantOf(thisFloor))) then
													weld.instance.C0 = weld.closedPosition:Lerp(weld.openPosition, math.clamp(self.alpha[indexLower], 0, 1))
												end
											end
										end
										if (self.state ~= 'Closing' and self.state ~= 'Closed') then
											self.velocity[indexLower] = 0
											self.sounds.doorOpenSound:Stop()
											self.sounds.doorCloseSound:Stop()
											task.spawn(updateDoorSpeed)
											break
										end
										task.spawn(updateDoorSpeed)
										if (self.checkWelds(rawFloor, 'closedPosition', self.config.Doors.New_Attachment_Doors_Config.Closing_Min_Threshold, true) and self.state == 'Closing') then
											self.updateDoorState('Closed')
											self.nudging = false
											if (typeof(onClosed) == 'function') then task.spawn(onClosed) end
											task.spawn(function()
												if (not self.lanternsReset) then
													self.LanternsReset:Fire()
												end
												self.Closed:Fire()
											end)
										end
										delta = HEARTBEAT:Wait()
									end
									task.wait()
									if (self.checkWelds(rawFloor, 'closedPosition', self.config.Doors.New_Attachment_Doors_Config.Closing_Min_Threshold, true) and self.state == 'Closing') then
										self.updateDoorState('Closed')
										self.nudging = false
										if (typeof(onClosed) == 'function') then task.spawn(onClosed) end
										task.spawn(function()
											if (not self.lanternsReset) then
												self.LanternsReset:Fire()
											end
											self.Closed:Fire()
										end)
									end
									if (self.state ~= 'Closed') then return end
									self.valueInstances.doorSpeedValue.Value = 0
									for i,v in next,self.velocity do
										self.velocity[i] = 0
										self.currentStage[i] = 1
									end
									task.spawn(updateDoorSpeed)
								end)
							end
						end
					end
				end
			end
			if (self.config.Doors.Door_Delay_Sequence_Config.Closing.Enable) then
				if (self.state ~= 'Closing') then return end
				task.spawn(function()
					for i,part in ipairs(self.config.Doors.Door_Delay_Sequence_Config.Closing.Sequence_Order) do
						runDoor({part})
						local hasCompleted = conditionalStepWait(self.config.Doors.Door_Delay_Sequence_Config.Closing.Delay, function()
							return {self.state ~= 'Closing'}
						end)
						if (not hasCompleted) then return end
					end
				end)
			else
				runDoor({'Inner','Outer'})
			end
		end

		function self:LegacyOpen(floor: number, onOpened: (any?) -> any?)
			local startingState = self.state
			local currentFloor = floor
			local thisFloor = self.findFloor(currentFloor)
			if ((startingState ~= 'Closed' and startingState ~= 'Closing') or ((not self.car:FindFirstChild(`{self.side == '' and '' or `{self.side}_`}Doors`)) or (not thisFloor:FindFirstChild(`{self.side == '' and '' or `{self.side}_`}Doors`)))) then return end
			self.Opening:Fire()
			self.updateDoorState('Opening')
			local duration = self.config.Doors.Door_Open_Speed
			if (not thisFloor) then return warn(`Floor not found! {currentFloor}`) end
			local distanceFactor = 0
			for i,w in next,self.engineWelds do
				local newTable = (i == 'car' and self.engineWelds.car[self.side] or {})
				for i,weld in next,newTable do
					distanceFactor = math.clamp(distanceFactor+((weld:getCurrentDistance()/weld.distanceFromOpenPosition)/(getTableLength(self.engineWelds)*getTableLength(newTable))*2), .15, 1)
				end
			end
			---
			self.sounds.doorCloseSound:Stop()
			task.spawn(function()
				local isCompleted = conditionalStepWait(startingState == 'Closed' and self.config.Doors.Door_Open_Sound_Delay or 0, function()
					return {self.state ~= 'Opening'}
				end)
				if (not isCompleted) then return end
				self.sounds.doorOpenSound.TimePosition = self.sounds.doorOpenSound.TimeLength*(1-distanceFactor)
				task.wait()
				self.sounds.doorOpenSound:Play()
			end)
			---
			duration = duration*distanceFactor
			local isCompleted = conditionalStepWait(startingState == 'Closed' and self.config.Doors.Open_Delay or startingState == 'Closing' and self.config.Doors.Reopen_Delay or 0, function()
				return {self.state ~= 'Opening'}
			end)
			if (not isCompleted) then return end
			local function runDoor(_types: {string})
				for i,doorType in pairs(typeof(_types) == 'table' and _types or {}) do
					for i,w in next,self.engineWelds do
						local newIndex = i == 'car' and 'Inner' or 'Outer'
						if (newIndex == doorType) then
							for i,w in next,self.engineWelds do
								local newIndex = i == 'car' and 'Inner' or 'Outer'
								local indexLower = string.lower(newIndex)
								local newWeldsList = (i == 'car' and self.engineWelds.car[self.side] or self.engineWelds.floors[tostring(currentFloor)] and self.engineWelds.floors[tostring(currentFloor)][self.side] or {})
								for i,weld in next,newWeldsList do
									if (typeof(self.currentStage[indexLower]) ~= 'table') then
										self.currentStage[indexLower] = {}
									end
									if (not self.currentStage[indexLower][i]) then
										self.currentStage[indexLower][i] = 1
									end
									task.spawn(function()
										local thisWeld = weld.instance
										local startTime = tick()
										local lastStage = self.currentStage[indexLower][i]
										local dataName = (indexLower == 'inner' and thisWeld:IsDescendantOf(self.car) and 'Realistic_Doors_Data') or (indexLower == 'outer' and thisWeld:IsDescendantOf(thisFloor) and 'Realistic_Outer_Doors_Data')
										if ((startingState == 'Closed' or (startingState == 'Closing' and lastStage == 1))) then
											self.currentStage[indexLower][i] += 1
											if (dataName and self.config.Doors[dataName].Enable_Open) then
												legacyEasing:interpolate(thisWeld, weld.interlockOpenPosition, thisWeld.C1, self.config.Doors[dataName].Open_Easing_Style, self.config.Doors[dataName].Open_Time, function()
													return {self.state ~= 'Opening'}
												end)
												if (math.abs(tick()-startTime) < self.config.Doors[dataName].Open_Time) then
													conditionalStepWait(self.config.Doors[dataName].Open_Time-math.abs(tick()-startTime), function()
														return {self.state ~= 'Opening'}
													end)
												end
											end
											if ((indexLower == 'outer' and ((not self.config.Doors[dataName]) or (not self.config.Doors[dataName].Enable_Open)))) then
												conditionalStepWait(self.config.Doors.Realistic_Doors_Data.Enable_Open and self.config.Doors.Realistic_Doors_Data.Open_Time or 0, function()
													return {self.state ~= 'Opening'}
												end)
												if (typeof(self.config.Doors.Realistic_Doors_Data.Open_Delay) == 'table' and self.config.Doors.Realistic_Doors_Data.Open_Delay.Enable) then
													conditionalStepWait(if (typeof(self.config.Doors.Realistic_Doors_Data.Open_Delay.Duration) == 'number') then self.config.Doors.Realistic_Doors_Data.Open_Delay.Duration else 0, function()
														return {self.state ~= 'Opening'}
													end)
												end
											elseif ((indexLower == 'inner' and ((not self.config.Doors[dataName]) or (not self.config.Doors[dataName].Enable_Open)))) then
												conditionalStepWait(self.config.Doors.Realistic_Outer_Doors_Data.Enable_Open and self.config.Doors.Realistic_Outer_Doors_Data.Open_Time or 0, function()
													return {self.state ~= 'Opening'}
												end)
												if (typeof(self.config.Doors.Realistic_Outer_Doors_Data.Open_Delay) == 'table' and self.config.Doors.Realistic_Outer_Doors_Data.Open_Delay.Enable) then
													conditionalStepWait(if (typeof(self.config.Doors.Realistic_Outer_Doors_Data.Open_Delay.Duration) == 'number') then self.config.Doors.Realistic_Outer_Doors_Data.Open_Delay.Duration else 0, function()
														return {self.state ~= 'Opening'}
													end)
												end
											end
										end
										local isCompleted = conditionalStepWait(startingState == 'Closed' and self.config.Doors[dataName].Open_Delay.Enable and self.config.Doors[dataName].Open_Delay.Duration or 0, function()
											return {self.state ~= 'Opening'}
										end)
										if (not isCompleted) then return end
										self.currentStage[indexLower][i] += 1
										local isCompleted = legacyEasing:interpolate(thisWeld, weld.openPosition, thisWeld.C1, self.config.Doors.Open_Easing_Style, duration, function()
											if (self.checkWelds(currentFloor, 'openPosition', .001) and self.state == 'Opening') then
												self.updateDoorState('Open')
												if (typeof(onOpened) == 'function') then task.spawn(onOpened) end
											end
											return {self.state ~= 'Opening' and self.state ~= 'Open'}
										end)
										if (not isCompleted) then return end
										task.wait()
										if (self.checkWelds(currentFloor, 'openPosition', .001) and self.state == 'Opening') then
											self.updateDoorState('Open')
											if (typeof(onOpened) == 'function') then task.spawn(onOpened) end
											self.Opened:Fire()
										end
									end)
								end
							end
						end
					end
				end
			end
			if (self.config.Doors.Door_Delay_Sequence_Config.Opening.Enable) then
				if (self.state ~= 'Opening') then return end
				task.spawn(function()
					for i,part in ipairs(self.config.Doors.Door_Delay_Sequence_Config.Opening.Sequence_Order) do
						runDoor({part})
						local hasCompleted = conditionalStepWait(self.config.Doors.Door_Delay_Sequence_Config.Opening.Delay, function()
							return {self.state ~= 'Opening'}
						end)
						if (not hasCompleted) then return end
					end
				end)
			else
				runDoor({'Inner','Outer'})
			end
		end

		function self:LegacyClose(floor: number, NUDGE: boolean?, onClosed: (any?) -> any?)
			local startingState = self.state
			local currentFloor = floor
			local thisFloor = self.findFloor(currentFloor)
			if (not thisFloor) then return warn(`Floor not found! {currentFloor}`) end
			if (startingState ~= 'Open' or ((not self.car:FindFirstChild(`{self.side == '' and '' or `{self.side}_`}Doors`)) or (not thisFloor:FindFirstChild(`{self.side == '' and '' or `{self.side}_`}Doors`)))) then return end
			self.Closing:Fire()
			self.updateDoorState('Closing')
			---
			self.sounds.doorOpenSound:Stop()
			task.spawn(function()
				local isCompleted = conditionalStepWait(self.config.Doors.Door_Close_Sound_Delay, function()
					return {self.state ~= 'Closing'}
				end)
				if (not isCompleted) then return end
				self.sounds.doorCloseSound:Play()
			end)
			---
			local duration = NUDGE and (self.config.Doors.Door_Nudge_Speed or self.config.Doors.Door_Close_Speed*1.5) or self.config.Doors.Door_Close_Speed
			local distanceFactor = 0
			for i,w in next,self.engineWelds do
				local newTable = (i == 'car' and self.engineWelds.car[self.side] or {})
				for i,weld in next,newTable do
					distanceFactor = math.clamp(distanceFactor+(((weld.closedPosition.Position-weld.instance.C0.Position).Magnitude/weld.distanceFromOpenPosition)/(getTableLength(self.engineWelds)*getTableLength(newTable))*2), .15, 1)
				end
			end
			duration = duration*distanceFactor
			local isCompleted = conditionalStepWait(self.config.Doors.Close_Delay, function()
				return {self.state ~= 'Closing'}
			end)
			self.lanternsReset = false
			local function runDoor(_types: {string})
				for i,doorType in pairs(typeof(_types) == 'table' and _types or {}) do
					for i,w in next,self.engineWelds do
						local newIndex = i == 'car' and 'Inner' or 'Outer'
						if (newIndex == doorType) then
							for i,w in next,self.engineWelds do
								local newIndex = i == 'car' and 'Inner' or 'Outer'
								local indexLower = string.lower(newIndex)
								local newWeldsList = (i == 'car' and self.engineWelds.car[self.side] or self.engineWelds.floors[tostring(currentFloor)] and self.engineWelds.floors[tostring(currentFloor)][self.side] or {})
								for i,weld in next,newWeldsList do
									local thisWeld = weld.instance
									local startTime = tick()
									task.spawn(function()
										local distance = (weld.openPosition.Position-weld.closedPosition.Position).Magnitude
										local lastStage = self.currentStage[indexLower][i]
										if ((startingState == 'Open' or (startingState == 'Opening' and lastStage == 0))) then
											self.currentStage[indexLower][i] -= 1
										end
										local dataName = (indexLower == 'inner' and thisWeld:IsDescendantOf(self.car) and 'Realistic_Doors_Data') or (indexLower == 'outer' and thisWeld:IsDescendantOf(thisFloor) and 'Realistic_Outer_Doors_Data')
										if (dataName) then
											local function handleLanternRatioCheck()
												local thisDist = (weld.closedPosition.Position-thisWeld.C0.Position).Magnitude
												if ((thisDist/distance) <= self.config.Color_Database.Lanterns.Door_Distance_Reset_Ratio and (not self.lanternsReset)) then
													self.lanternsReset = true
													self.LanternsReset:Fire()
												end
											end
											if ((startingState == 'Open' or (startingState == 'Opening' and lastStage == 2)) and (self.config.Doors[dataName] and self.config.Doors[dataName].Enable_Close)) then
												local isCompleted = legacyEasing:interpolate(thisWeld, weld.interlockClosePosition, thisWeld.C1, self.config.Doors.Close_Easing_Style, duration, function()
													task.spawn(handleLanternRatioCheck)
													return {self.state ~= 'Closing'}
												end)
												if (not isCompleted) then return end
												if (math.abs(tick()-startTime) < self.config.Doors[dataName].Close_Time) then
													conditionalStepWait(self.config.Doors[dataName].Close_Time-math.abs(tick()-startTime), function()
														return {self.state ~= 'Closing'}
													end)
												end
												local isCompleted = conditionalStepWait(startingState == 'Open' and self.config.Doors[dataName].Close_Delay.Enable and self.config.Doors[dataName].Close_Delay.Duration or 0, function()
													return {self.state ~= 'Closing'}
												end)
												if (not isCompleted) then return end
												self.currentStage[indexLower][i] -= 1
												local isCompleted = legacyEasing:interpolate(thisWeld, weld.closedPosition, thisWeld.C1, self.config.Doors[dataName].Close_Easing_Style, self.config.Doors[dataName].Close_Time, function()
													task.spawn(handleLanternRatioCheck)
													return {self.state ~= 'Closing'}
												end)
												if (not isCompleted) then return end
											else
												local isCompleted = legacyEasing:interpolate(thisWeld, weld.closedPosition, thisWeld.C1, self.config.Doors.Close_Easing_Style, duration, function()
													task.spawn(handleLanternRatioCheck)
													if (self.checkWelds(currentFloor, 'closedPosition', self.config.Doors.New_Attachment_Doors_Config.Closing_Min_Threshold, true) and self.state == 'Closing') then
														self.updateDoorState('Closed')
														if (not self.lanternsReset) then
															self.LanternsReset:Fire()
														end
														if (typeof(onClosed) == 'function') then task.spawn(onClosed) end
														self.Closed:Fire()
													end
													return {self.state ~= 'Closing' and self.state ~= 'Closed'}
												end)
												if (not isCompleted) then return end
											end
											task.wait()
											if (self.checkWelds(currentFloor, 'closedPosition', self.config.Doors.New_Attachment_Doors_Config.Closing_Min_Threshold, true) and self.state == 'Closing') then
												self.updateDoorState('Closed')
												if (not self.lanternsReset) then
													self.LanternsReset:Fire()
												end
												if (typeof(onClosed) == 'function') then task.spawn(onClosed) end
												self.Closed:Fire()
											end
										end
									end)
								end
							end
						end
					end
				end
			end
			if (self.config.Doors.Door_Delay_Sequence_Config.Closing.Enable) then
				if (self.state ~= 'Closing') then return end
				task.spawn(function()
					for i,part in ipairs(self.config.Doors.Door_Delay_Sequence_Config.Closing.Sequence_Order) do
						runDoor({part})
						local hasCompleted = conditionalStepWait(self.config.Doors.Door_Delay_Sequence_Config.Closing.Delay, function()
							return {self.state ~= 'Closing'}
						end)
						if (not hasCompleted) then return end
					end
				end)
			else
				runDoor({'Inner','Outer'})
			end
		end

		return self
	end
end
return module