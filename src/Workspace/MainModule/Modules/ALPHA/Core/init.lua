--[[

	CORTEX CLASSIC V10 // OCTOBER 2023 REWRITE
	START DATE: 10/09/2023
	
	WRITTEN BY: aaxtatious (540781721) & ImFirstPlace (79641334)
	
	© 2024 Cortex Elevator Company.

]]--

local module = {
	['doorData'] = {},
	['statValues'] = {
		['Floor'] = 1,
		['Raw_Floor'] = 1,
		['Arrive_Floor'] = 1,
		['Move_Value'] = 0,
		['Move_Direction'] = 'N',
		['Direction'] = 'N',
		['Leveling'] = false,
		['Arriving'] = false,
		['Destination'] = 1,
		['Queue_Direction'] = 'N',
		['Arrow_Direction'] = 'N',
		['Stop'] = false,
		['Inspection'] = false,
		['Independent_Service'] = false,
		['Out_Of_Service'] = false,
		['Fire_Service'] = false,
		['Fire_Recall'] = false,
		['Phase_1'] = false,
		['Phase_2'] = false,
		['Current_Speed'] = 0,
		['Velocity'] = 0,
		['Nudge'] = false,
	},
	['coreFunctions'] = {},
	['statFolderValues'] = {},
	['queue'] = {},
	['pluginModules'] = {},
	['sounds'] = {},
	['lockedCalls'] = {
		['car'] = {},
		['hall'] = {
			['up'] = {},
			['down'] = {}
		}
	},
	['safetyEnaged'] = true,
	['dropKeyCheckValues'] = {},
	['dropKeyHandlers'] = {}
}

local dependencies = script:WaitForChild('Dependencies')
local modules = script:WaitForChild('Modules')

local elevatorID = math.random(0, 1e5)

local heartbeat = _G.Cortex_SERVER.EVENTS.RUNTIME_EVENT.EVENT

local function checkIndependentService()
	return (not module.statValues.Fire_Service and module.statValues.Independent_Service)
end

local function checkFireServicePhase2()
	return (not module.statValues.Fire_Recall and module.statValues.Fire_Service and module.statValues.Phase_2)
end

local function weldModel(model, weldPart, ignoreList, append)
	if (typeof(model) ~= 'Instance') then return end
	local welds = {}
	for _,v in pairs(model:GetDescendants()) do
		if (not v:IsA('BasePart')) then continue end
		if (not weldPart) then weldPart = v end
		if (weldPart ~= v and (typeof(ignoreList) ~= 'table' or (not table.find(ignoreList, v)))) then
			local weld = Instance.new('Weld')
			weld.Name = `{v.Name}_To_{weldPart.Name}_Weld`
			weld.Part0, weld.Part1 = v, weldPart
			weld.C0, weld.C1 = CFrame.new(), weldPart.CFrame:ToObjectSpace(v.CFrame)
			weld.Parent = if (typeof(append) == 'Instance') then append else weldPart
			table.insert(welds, weld)
			v.Anchored = false
		end
	end
	return welds
end

local function weldParts(append, part0, part1, joinInPlace, animatable)
	if (typeof(append) ~= 'Instance') then append = part0 end
	local weld = Instance.new('Weld')
	weld.Name = `{part0.Name}_To_{part1.Name}_Weld`
	weld.Part0, weld.Part1 = part0, part1
	weld.C0, weld.C1 = CFrame.new(), part1.CFrame:ToObjectSpace(part0.CFrame)
	weld.Parent = if (typeof(append) == 'Instance') then append else part1
	return weld
end

module.coreFunctions.weldModel = weldModel
module.coreFunctions.weldParts = weldParts

local function createInstance(append, name, type, replaceByName, properties)
	if (typeof(append) ~= 'Instance') then return end
	if (typeof(name) ~= 'string') then return end
	local result = replaceByName == true and append:FindFirstChild(name)
	if (not result) then
		result = Instance.new(type)
		result.Name = name
		for property, value in if (typeof(properties) == 'table') then properties else {} do
			pcall(function()
				--if ((not result[property]) or typeof(result[property] ~= typeof(value))) then return end
				result[property] = value
			end)
		end
		result.Parent = append
	end
	return result
end

local function addSound(append, name, config, looped, minDistance, maxDistance)
	if (typeof(append) ~= 'Instance' or typeof(name) ~= 'string') then return end
	local newSound = append:FindFirstChild(name)
	if (not newSound) then
		newSound = createInstance(append, name, 'Sound', false, {
			SoundId = if (typeof(config.Sound_Id) == 'number' and config.Sound_Id ~= 0) then `rbxassetid://{config.Sound_Id}` else '',
			Volume = config.Volume,
			PlaybackSpeed = config.Pitch,
			Looped = if (typeof(config.Looped) == 'boolean') then config.Looped elseif (typeof(looped) == 'boolean') then looped else false,
			RollOffMinDistance = minDistance,
			RollOffMaxDistance = maxDistance
		})
	end
	return newSound
end

local function addPlayingSound(append, sound, pitchOffset)
	if (typeof(sound) ~= 'Instance' or (not sound:IsA('Sound'))) then return end
	local newSound = sound:Clone()
	newSound.Playing = true
	newSound.PlaybackSpeed = typeof(pitchOffset) == 'number' and newSound.PlaybackSpeed+pitchOffset or newSound.PlaybackSpeed
	newSound.Parent = append
	game:GetService('Debris'):AddItem(newSound, newSound.TimeLength + 0.1)
end

local function recursiveTable(t, callback)
	if (typeof(t) ~= 'table') then return end
	for i, v in pairs(t) do
		if (typeof(callback) == 'function') then callback(i, v) end
		if (typeof(v) == 'table') then recursiveTable(v, callback) end
	end
end

module.coreFunctions.recursiveTable = recursiveTable
module.coreFunctions.addSound = addSound
module.coreFunctions.addPlayingSound = addPlayingSound

module.coreFunctions.createInstance = createInstance

module.registeredFloors = {}

local function findRegisteredFloor(floor)
	floor = tostring(floor)
	return module.registeredFloors[floor]
end
module.coreFunctions.findRegisteredFloor = findRegisteredFloor

local coreFunctions = require(modules.Core_Functions)
local signal = require(modules.Signal)

local httpService = game:GetService('HttpService')
local runService = game:GetService('RunService')
local tweenService = game:GetService('TweenService')
local collectionService = game:GetService('CollectionService')
local players = game:GetService('Players')

function module.Start(source, config, buildData, moduleDependencies)

	local _VERSION = `Cortex Classic v{buildData.VERSION}`

	assert(typeof(source) == 'Instance', `{_VERSION} :: Source not valid for initiation`)

	local ran, config = pcall(require, config)
	assert(ran, `{_VERSION} :: {source.Parent:GetFullName()} :: Config not valid for initiation: {config}`)

	local configFile = require(dependencies.ConfigFile)(config, script)
	--assert(ran == true, `{_VERSION} :: {source.Parent:GetFullName()} :: ConfigFile not found | {configFile}`)

	if (configFile.Sound_Database.Voice_Config.Voice_Clips == 'STOCK') then
		configFile.Sound_Database.Voice_Config.Voice_Clips = require(script.Voice_Module.DefaultVoiceModule)(require(script.Voice_Module.STOCK_VoiceModule), source)
	elseif typeof(configFile.Sound_Database.Voice_Config.Voice_Clips) == 'table' then
		configFile.Sound_Database.Voice_Config.Voice_Clips = require(script.Voice_Module.DefaultVoiceModule)(configFile.Sound_Database.Voice_Config.Voice_Clips, source)
	end

	local voiceConfig = configFile.Sound_Database.Voice_Config.Voice_Clips
	local voiceModule = require(script.Voice_Module).new(voiceConfig)

	local elevator = source.Parent
	local car = elevator:FindFirstChild('Car')
	local floors = elevator:FindFirstChild('Floors')
	local platform = car:FindFirstChild('Platform')
	local level = car:FindFirstChild('Level') or platform

	local counterweight = elevator:FindFirstChild('Counterweight')

	local fireServiceRecallFloor = -99999

	local elevatorPosition = platform.CFrame

	local elevatorMovementThread
	local elevatorRelevelThread

	local pluginModuleData = {}
	for i, v in pairs(modules:GetChildren()) do
		task.spawn(function()
			local ran, res = pcall(require, v)
			if (not ran) then return end
			if (not res.isPluginModule) then return end
			res.config = configFile
			res.elevator = elevator
			pluginModuleData[v.Name] = { content=res, instance=v }
		end)
	end

	for i, v in pairs(source:FindFirstChild('Plugins_INTERNAL') and source.Plugins_INTERNAL:GetChildren() or {}) do
		local ran, res = pcall(require, v)
		if (not ran) then return print(`INTERNAL PLUGIN MODULE '{v.Name}' SETUP FAILED :: {res}`) end
		local ran, res2 = pcall(function()
			return task.spawn(function() return res:INITIATE_PLUGIN_INTERNAL(script, source) end)
		end)
		if (not ran) then print(`INTERNAL PLUGIN MODULE '{v.Name}' INITIATION FAILED :: {res}`)
		else
			module.pluginModules[v.Name] = { content = res, module = v }
		end
	end

	-- // Check for any floors being added/removed // --
	floors.ChildAdded:Connect(function(child)
		task.wait()
		local floorName = tonumber(string.split(child.Name, 'Floor_')[2])
		if (not floorName) then return end
		if (findRegisteredFloor(floorName)) then return end
		local level = child:FindFirstChild('Level')
		if (not level) then return end
		module.registeredFloors[floorName] = nil
	end)
	floors.ChildRemoved:Connect(function(child)
		task.wait()
		local floorName = tonumber(string.split(child.Name, 'Floor_')[2])
		if (not floorName) then return end
		if (not findRegisteredFloor(floorName)) then return end
		local level = child:FindFirstChild('Level')
		if (not level) then return end
		module.registeredFloors[floorName] = { floorNumber = floorName, floorInstance = child, level = level }
	end)

	elevator:SetAttribute('elevatorID', elevatorID)

	-- // Internal variables // --
	local doorEngine = pluginModuleData.Door_Engine.content
	local moveLock = false
	local preDooring = false
	local inspectionEnabled = false
	local inspectionLocked = false
	local releveling = false

	local inspectionMoving = false
	local inspectionStopping = false

	local inspectionMoveThread
	local inspectionStopThread

	local statValuesFolder = createInstance(elevator, 'Legacy', 'Folder', true)
	local valueTypes = {
		['boolean'] = 'Bool',
		['number'] = 'Number',
		['CFrame'] = 'CFrame',
		['string'] = 'String',
		['Vector3'] = 'Vector3',
	}

	local remoteCallValue = createInstance(statValuesFolder, 'Remote_Call', 'NumberValue', true)

	local api = createInstance(elevator, 'Cortex_API', 'BindableEvent', true)
	local remote = createInstance(elevator, 'Cortex_Remote', 'RemoteEvent', true)
	local elevatorSignal = createInstance(elevator, 'Cortex_Signal', 'BindableFunction', true)

	local carWeldsFolder = createInstance(car, 'Car_Welds', 'Folder', true)

	for i, v in pairs(floors:GetChildren()) do
		local floorNumber, level = tonumber(string.split(v.Name, 'Floor_')[2]), v:FindFirstChild('Level')
		if ((not floorNumber) or (not level)) then continue end
		module.registeredFloors[tostring(floorNumber)] = { floorNumber = floorNumber, floorInstance = v, level = level }
	end

	local startLoadTime = os.clock()

	-- // Cab region part // --
	local size = platform.Size+Vector3.new(0, 15, 0)
	local cabRegion = createInstance(car, 'Cab_Region', 'Part', true, {
		Anchored = false,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		Transparency = 1,
		CFrame = CFrame.new(platform.Position.X, platform.Position.Y+size.Y/2, platform.Position.Z)*CFrame.Angles(platform.CFrame:ToEulerAnglesXYZ()),
		Size = size,
	})
	weldParts(cabRegion, cabRegion, platform, true, false)
	local soundGroup = cabRegion:FindFirstChildOfClass('SoundGroup') or Instance.new('SoundGroup')
	soundGroup.Parent = cabRegion
	local equalizer = soundGroup:FindFirstChildOfClass('EqualizerSoundEffect') or Instance.new('EqualizerSoundEffect')
	equalizer.Name = 'Muffler'
	equalizer.Parent = soundGroup
	equalizer.HighGain = 0
	equalizer.LowGain = 0
	equalizer.MidGain = 0

	-- // Get bottom & top floor // --
	local bottomFloor, topFloor
	local bottomPoint, topPoint = math.huge, -math.huge
	for i, v in pairs(module.registeredFloors) do
		if (v.level.Position.Y > topPoint) then
			topPoint = v.level.Position.Y
			topFloor = v
		end
		if (v.level.Position.Y < bottomPoint) then
			bottomPoint = v.level.Position.Y
			bottomFloor = v
		end
	end

	local doorsIgnoreList = {}
	for i, v in pairs(car:GetChildren()) do
		local side = string.split(v.Name, 'Doors')[2] and string.split(v.Name, 'Doors')[1]
		if (not side) then continue end
		side = string.split(side, '_')[1]
		if (not side) then continue end
		if (side == '') then side = 'Front' end
		for i, v in pairs(v:GetDescendants()) do
			if (not v:IsA('BasePart')) then continue end
			table.insert(doorsIgnoreList, v)
		end
		doorEngine.setUp(v)
		local data = doorEngine.new(v)
		module.doorData[side] = data
	end

	for i, f in pairs(module.registeredFloors) do
		for i, v in pairs(f.floorInstance:GetChildren()) do
			local side = string.split(v.Name, 'Doors')[2] and string.split(v.Name, 'Doors')[1]
			if (not side) then continue end
			doorEngine.setUp(v)
		end
	end

	recursiveTable(configFile, function(i, v)
		if (typeof(v) == 'table' and v.Voice_ID) then v.Sound_Id = v.Voice_ID i = 'Voice_Audio' end
		if (typeof(v) == 'table' and v.Sound_Id and i ~= 'Door_Obstruction_Signal') then
			local newSound = addSound(cabRegion, i, v, i == 'Alarm' or i == 'Nudge_Buzzer' or (string.match(i, 'Motor_Run') ~= nil) or i == 'Traveling_Sound', 3, 25)
			newSound:SetAttribute('originalPitch', newSound.PlaybackSpeed)
			module.sounds[i] = newSound
		end
	end)

	module.sounds.Voice_Audio = addSound(cabRegion, 'Voice_Audio', {['Sound_Id'] = voiceConfig.SoundId, ['Volume'] = voiceConfig.Volume, ['Pitch'] = voiceConfig.Pitch}, false, 3, 25)

	for side, data in pairs(module.doorData) do
		local valueName = `{side == '' and '' or `{side}_`}Door_State`
		module.statValues[valueName] = data.state
		module.statValues[`{data.sideJoin}Door_Nudging`] = data.nudging
	end

	for i, v in pairs(module.statValues) do
		if (i == 'Queue_Direction' or i == 'Move_Direction' or i == 'Arrow_Direction' or i == 'Direction') then
			module.statValues[i] = 0
		end
		local val = createInstance(statValuesFolder, i, `{valueTypes[typeof(v)]}Value`, true, { Value = v })
		module.statFolderValues[i] = { value = val, update = function()
			if (i == 'Current_Speed') then
				val.Value = math.rad(module.statValues[i])
			elseif (i == 'Queue_Direction' or i == 'Move_Direction' or i == 'Arrow_Direction' or i == 'Direction') then
				val.Value = module.statValues[i] == 1 and 'U' or module.statValues[i] == -1 and 'D' or 'N'
			else
				val.Value = module.statValues[i]
			end
		end}
	end
	local queueValue = createInstance(statValuesFolder, 'Queue', 'StringValue', true)
	remoteCallValue:GetPropertyChangedSignal('Value'):Connect(function()
		if (not findRegisteredFloor(remoteCallValue.Value)) then return end
		task.spawn(addCall, {call = remoteCallValue.Value})
		remoteCallValue.Value = -math.huge
	end)

	local voiceSequenceQueue = {}
	local voiceSequenceIndex = 0

	local function playVoiceSequenceProtocolWithQueue(clipSequence, pauseThread, playCondition)
		if (not configFile.Sound_Database.Voice_Config.Enabled or not playCondition) then return end
		task.spawn(function()
			local length = #voiceSequenceQueue
			if (not table.find(voiceSequenceQueue, clipSequence)) then table.insert(voiceSequenceQueue, clipSequence) end
			if (length <= 0) then
				local function run()
					while (#voiceSequenceQueue > 0) do
						voiceSequenceIndex += 1
						local sequence = voiceSequenceQueue[voiceSequenceIndex]
						for index,item in pairs(sequence) do
							voiceModule:PlayClip(module.sounds.Voice_Audio, voiceConfig.Voice_Clips[item[1]], true)
							task.wait(item.Delay)
						end
						local tindex = table.find(voiceSequenceQueue, sequence)
						if (tindex) then table.remove(voiceSequenceQueue, tindex) voiceSequenceIndex -= 1 end
					end
					voiceSequenceIndex = 0
				end
				if (pauseThread) then
					run()
				else
					task.spawn(run)
				end
			end
		end)
	end

	function resetButtons(floor)
		for i, v in pairs(car:GetChildren()) do
			if (v.Name == 'Buttons') then
				for i, button in pairs(v:GetChildren()) do
					local buttonFloor = tonumber(string.split(button.Name, '_')[2]) or tonumber(string.split(button.Name, 'Floor')[2])
					if (buttonFloor and buttonFloor == floor) then
						setButton(button, configFile.Color_Database.Car.Floor_Button, 'Neautral_State', car)
					end
				end
			end
		end
		local registeredFloor = findRegisteredFloor(floor)
		if (not registeredFloor) then return end
		local direction = module.statValues.Queue_Direction == 1 and 'Up' or module.statValues.Queue_Direction == -1 and 'Down' or 'Neutral'
		for i, v in pairs(registeredFloor.floorInstance:GetChildren()) do
			if (v.Name == 'Call_Buttons') then
				for i, button in pairs(v:GetChildren()) do
					if (string.sub(button.Name, 1, 1) == (module.statValues.Queue_Direction == 1 and 'U' or module.statValues.Queue_Direction == -1 and 'D' or 0)) then
						setButton(button, configFile.Color_Database.Car.Floor_Button, 'Neautral_State', car)
						updateButton(button, configFile.Color_Database.Floor[direction], 'Neautral_State')
					end
				end
			end
		end
	end

	function removeAllCalls()
		for i, floor in pairs(module.registeredFloors) do
			removeCall(floor.floorNumber)
			pcall(function()
				resetLanterns(floor.floorNumber)
				resetButtons(floor.floorNumber)
			end)
		end
	end

	local function updateStatValues()
		module.statValues.Arrow_Direction = module.statValues.Queue_Direction
		for i, v in pairs(module.statFolderValues) do
			v.update()
		end
	end

	local function updateFloor()
		local nearFloor, nearRawFloor, dist = nil, nil, math.huge
		for i, floor in pairs(module.registeredFloors) do
			local distance = math.abs(floor.level.Position.Y-level.Position.Y)
			if (distance < dist) then
				dist = distance
				local min = (module.statValues.Move_Value == 1 or module.statValues.Move_Value == 0) and module.statValues.Raw_Floor or module.statValues.Destination
				local max = (module.statValues.Move_Value == 1 or module.statValues.Move_Value == 0) and module.statValues.Destination or module.statValues.Raw_Floor
				nearFloor = configFile.Movement.Accelerated_Floor_Config.Enabled and math.clamp(floor.floorNumber+(configFile.Movement.Accelerated_Floor_Config.Offset*module.statValues.Move_Value), min, max) or floor.floorNumber
				nearRawFloor = floor.floorNumber
			end
		end

		module.statValues.Raw_Floor = nearRawFloor

		if (nearFloor ~= module.statValues.Floor) then
			module.statValues.Floor = nearFloor
			if (configFile.Sound_Database.Others.Enable_Floor_Pass_Chime) then
				task.delay(configFile.Sound_Database.Others.Floor_Pass_Chime_Delay, function()
					module.sounds.Floor_Pass_Chime:Play()
				end)
			end
			task.spawn(updateStatValues)
		end
	end

	function findAncestor(model, name)
		if (not model or typeof(model) ~= 'Instance') then return end
		local result = model:FindFirstChild(name)
		if (result) then
			return result
		else
			return findAncestor(model.Parent, name)
		end
	end

	module.coreFunctions.updateStatValues = updateStatValues

	weldModel(car, platform, doorsIgnoreList, carWeldsFolder)

	local cwStart,cwOffset
	if (counterweight and counterweight:FindFirstChild('Main')) then
		for i,v in pairs(counterweight:GetDescendants()) do
			if (string.match(v.ClassName, 'Weld') or v:IsA('Sound') or (string.match(v.ClassName, 'Script') and v.Parent == counterweight)) then
				v:Destroy()
			end
		end
		weldModel(counterweight, counterweight.Main, {})
		local travelingSound = addSound(counterweight.Main, 'Traveling_Sound', {Sound_Id=6003695467,Volume=0,Pitch=1.15}, true, false, 50, .2)
		local equalizer: EqualizerSoundEffect = travelingSound:FindFirstChildOfClass('EqualizerSoundEffect') or Instance.new('EqualizerSoundEffect')
		equalizer.HighGain = -8
		equalizer.LowGain = 7
		equalizer.MidGain = -2
		equalizer.Parent = travelingSound
		travelingSound:Play()
		counterweight.Main.Anchored = true

		local cwPos = counterweight.Main.CFrame.Y+(topFloor.level.Position.Y-level.Position.Y)
		local oriX,oriY,oriZ = counterweight.Main.CFrame:ToOrientation()
		--counterweight.Main.CFrame = CFrame.new(counterweight.Main.CFrame.X, cwPos, counterweight.Main.CFrame.Z)*CFrame.Angles(oriX, oriY, oriZ)
		cwStart = counterweight.Main.CFrame
		cwOffset = counterweight.Main.Position
	end
	local elevatorHeight = math.abs(topFloor.level.Position.Y-bottomFloor.level.Position.Y)

	local endLoadTime = os.clock()
	print(`{_VERSION} :: {elevator:GetFullName()} :: Initiated in build {buildData.BUILD}, load time: {math.round((endLoadTime-startLoadTime)*1000)/1000}s`)

	local prevIndependentServiceValue = module.statValues.Independent_Service
	local function setIndependentService(bool)
		module.statValues.Independent_Service = bool
		--outputElevMessage(`Elevator has been placed {bool and 'into' or 'out of'} independent service`, 'warning')
		if (prevIndependentServiceValue ~= module.statValues.Independent_Service) then
			prevIndependentServiceValue = module.statValues.Independent_Service
			removeAllCalls()
			task.spawn(updateStatValues)
			if (bool) then
				playVoiceSequenceProtocolWithQueue(voiceConfig.Settings.Other_Announcements.Independent_Service_Announcement.Sequence, false, voiceConfig.Settings.Other_Announcements.Independent_Service_Announcement.Enabled)
				--If the elevator is already on the recall floor, open the doors (if closed or closing)
				for i, doorData in pairs(module.doorData) do
					if (doorData.state == 'Closed' or doorData.state == 'Closing' or doorData.state == 'Stopped') then
						task.spawn(runDoorOpen, module.statValues.Raw_Floor, doorData.side, true)
						if doorData.nudging and not module.statValues.Fire_Recall then
							module.sounds.Nudge_Buzzer.Playing = false
						end
					end
				end
			end
		end
	end

	-- // Safety core check // --
	function isElevatorSafe()
		if (module.statValues.Out_Of_Service or module.statValues.Stop or module.statValues.Inspection or (not checkDropKeyState())) then return false end
		return true
	end

	-- // Door handling // --
	local function checkAllNudge() -- // false - At least one set of doors are nudging, do not return true. true - No doors are nudging, all clear!
		for i, v in pairs(module.doorData) do
			if (v.nudging) then return false end
		end
		return true
	end

	local sensorParams = OverlapParams.new()
	sensorParams.FilterType = Enum.RaycastFilterType.Include
	function runDoorOpen(floor, side, doorTimer, bypassNudge)
		local registeredFloor = findRegisteredFloor(floor)
		if (not registeredFloor) then return end
		local function runDoor(data)
			if (not data:IsValid(floor)) then return end
			--if bypassNudge then
			--	data.nudging = false
			--end
			if ((data.nudging and (not bypassNudge)) or (data.state ~= 'Closed' and data.state ~= 'Closing' and data.state ~= 'Stopped')) then return end
			playVoiceSequenceProtocolWithQueue(voiceConfig.Settings.Door_Announcements.Open_Announcement.Sequence, false, voiceConfig.Settings.Door_Announcements.Open_Announcement.Enabled)
			data.obstructionSignal.Playing = false
			local isObstructed = false
			local startingState = data.state
			api:Fire('doorObstructionStateChanged', { ['side'] = data.side, ['isObstructed'] = isObstructed })
			api:Fire('onDoorOpening', { ['side'] = data.side, ['state'] = data.state })
			api:Fire('doorStateChange', { ['floor'] = module.statValues.Raw_Floor, ['side'] = data.side, ['state'] = 'Opening' })

			data.Opened:Once(function()
				data.doorTimestamp = os.clock()
				if (startingState == 'Closed') then
					data.nudgeTimestamp = os.clock()
					task.spawn(runChime, module.statValues.Floor, module.statValues.Queue_Direction, {'Exterior', 'Interior'}, configFile.Sound_Database.Chime_Events.After_Open)
					task.spawn(doLanterns, module.statValues.Floor, module.statValues.Queue_Direction, {'Exterior', 'Interior'}, configFile.Color_Database.Lanterns.Active_After_Door_Open)

					if module.statValues.Queue_Direction ~= 0 then
						local dir = module.statValues.Queue_Direction == 1 and 'Up' or module.statValues.Queue_Direction == -1 and 'Down'
						local clip = voiceConfig.Settings.Directional_Announcements[`{dir}_Announcement`]
						if clip then
							playVoiceSequenceProtocolWithQueue(clip.Sequence, false, clip.Enabled)
						end
					end
				end

				api:Fire('doorStateChange', { ['floor'] = module.statValues.Raw_Floor, ['side'] = data.side, ['state'] = data.state })
				api:Fire('onDoorOpened', { ['side'] = data.side, ['state'] = data.state, ['floor'] = module.statValues.Raw_Floor })
				api:Fire('onDoorOpen', { ['side'] = data.side, ['state'] = data.state, ['floor'] = module.statValues.Raw_Floor }) -- Depricated API

				if (data.nudging) then return task.spawn(runDoorClose, module.statValues.Raw_Floor, side) end

				while ((os.clock()-data.doorTimestamp)/(configFile.Doors.Door_Timers[doorTimer] or configFile.Doors.Door_Timers.Open_On_Stop) < 1 and data.state == 'Open') do
					sensorParams.FilterDescendantsInstances = _G.ElevatorSensorHumanoids
					local obstructed = #workspace:GetPartBoundsInBox(data.doorSensorPart.CFrame, data.doorSensorPart.Size, sensorParams) > 0
					if (obstructed ~= isObstructed) then
						isObstructed = obstructed
						data.obstructionSignal.Playing = obstructed
						api:Fire('doorObstructionStateChanged', { ['side'] = data.side, ['isObstructed'] = isObstructed })
					end
					if (data.buttonHold or obstructed or checkIndependentService() or module.statValues.Fire_Service) then
						data.doorTimestamp = os.clock()
						if (checkIndependentService() or module.statValues.Fire_Service) then
							data.nudgeTimestamp = os.clock()
						end
					end
					if ((os.clock()-data.nudgeTimestamp)/configFile.Doors.Nudge_Timer > 1 and (not data.nudging) and (not checkIndependentService())) then
						module.statValues.Nudge = true
						data.nudging = true
						module.statValues[`{data.sideJoin}Door_Nudging`] = data.nudging
						module.sounds.Nudge_Buzzer.Playing = true
						task.spawn(updateStatValues)
						task.spawn(runDoorClose, module.statValues.Raw_Floor, side)
					end
					heartbeat:Wait()
				end
				if (data.state ~= 'Open') then return end
				task.spawn(runDoorClose, module.statValues.Raw_Floor, side)
			end)
			data:Open(floor)
		end
		if ((moveLock and (not preDooring)) or (not isElevatorSafe())) then return end
		if (string.upper(side) == 'ALL') then
			for _, v in pairs(module.doorData) do
				task.spawn(runDoor, v)
			end
		else
			local data = module.doorData[side]
			if (not data) then return end
			task.spawn(runDoor, data)
		end
	end

	function runDoorClose(floor, side, nudge)
		local function runDoor(data)
			if (not data:IsValid(floor)) then return end
			if (data.state ~= 'Open' and data.state ~= 'Stopped' and not module.statValues.Fire_Recall and (not (data.state == 'Opening' and (checkIndependentService() or checkFireServicePhase2())))) then return end
			if nudge then
				playVoiceSequenceProtocolWithQueue(voiceConfig.Settings.Door_Announcements.Nudge_Announcement.Sequence, false, voiceConfig.Settings.Door_Announcements.Nudge_Announcement.Enabled)
			else
				playVoiceSequenceProtocolWithQueue(voiceConfig.Settings.Door_Announcements.Close_Announcement.Sequence, false, voiceConfig.Settings.Door_Announcements.Close_Announcement.Enabled)
			end

			local startingState = data.state
			if nudge and data.state ~= 'Closed' then
				module.statValues.Nudge = true
				data.nudging = true
				module.statValues[`{data.sideJoin}Door_Nudging`] = data.nudging
				module.sounds.Nudge_Buzzer.Playing = true
				task.spawn(updateStatValues)
			end
			local runTask
			data.obstructionSignal.Playing = false
			data.buttonHold = false
			local isObstructed = false
			local startingState = data.state
			api:Fire('doorObstructionStateChanged', { ['side'] = data.side, ['isObstructed'] = isObstructed })
			api:Fire('onDoorClosing', { ['side'] = data.side, ['state'] = data.state })
			api:Fire('doorStateChange', { ['floor'] = module.statValues.Raw_Floor, ['side'] = data.side, ['state'] = 'Closing' })
			data.Closed:Once(function()
				api:Fire('onDoorClosed', { ['side'] = data.side, ['state'] = data.state })
				api:Fire('doorStateChange', { ['floor'] = module.statValues.Raw_Floor, ['side'] = data.side, ['state'] = data.state })
				data.nudging = false
				if ((not checkDoorStates('Closed')) or moveLock) then return end
				pcall(task.cancel, runTask)
				module.statValues.Nudge = (not checkAllNudge())
				if (not module.statValues.Fire_Recall) then
					module.sounds.Nudge_Buzzer.Playing = module.statValues.Nudge
				end
				module.statValues[`{data.sideJoin}Door_Nudging`] = data.nudging
				data.obstructionSignal.Playing = false
				task.spawn(updateStatValues)
				local nextQueue = select(2, checkNearestCallInDirection(module.statValues.Raw_Floor, module.statValues.Queue_Direction))
				-- // No call in current direction? Check in the opposite direction
				if (not nextQueue) then nextQueue = select(2, checkNearestCallInDirection(module.statValues.Raw_Floor, -module.statValues.Queue_Direction)) end
				-- // Still no call? Check in any direction
				if (not nextQueue) then nextQueue = select(2, checkNearestCallInDirection(module.statValues.Raw_Floor, 0)) end
				-- // Yet still no call? Let's look for any calls on the current floor // --
				local thisCall = select(2, findCallInQueue(module.statValues.Raw_Floor, -module.statValues.Queue_Direction))
				if ((not select(2, checkNearestCallInDirection(module.statValues.Raw_Floor, module.statValues.Queue_Direction))) and thisCall) then
					module.statValues.Queue_Direction = 0
					task.spawn(updateStatValues)
					local hasCompleted = coreFunctions.conditionalWait(1, function() return {not moveLock} end)
					if (not hasCompleted) then return end
					module.statValues.Queue_Direction = thisCall.directions[1]
					api:Fire('onCallRespond', { floor = module.statValues.Raw_Floor, direction = module.statValues.Queue_Direction == 1 and 'U' or module.statValues.Queue_Direction == -1 and 'D' or 'N' })
					task.spawn(updateStatValues)

					if (getTotalDirectionSides(thisCall.sides, thisCall and thisCall.directions[1] or 0) == 0) then
						task.spawn(runDoorOpen, floor, 'all', thisCall and thisCall.directions[1] and 'Open_By_Call' or 'Open_On_Stop')
					else
						local callSidesCopy = table.clone(thisCall.sides)
						for _, side in pairs(callSidesCopy) do
							local dir = #thisCall.directions > 0 and thisCall.directions[1] or 0
							if dir then
								if tonumber(string.split(side, '_')[1]) == dir or tonumber(string.split(side, '_')[1]) == 0 then
									table.remove(module.queue[select(1, findCallInQueue(thisCall.call))].sides, table.find(module.queue[select(1, findCallInQueue(thisCall.call))].sides, side))
									task.spawn(runDoorOpen, floor, string.split(side, '_')[2], thisCall and thisCall.directions[1] and 'Open_By_Call' or 'Open_On_Stop')
								end
							end
						end
					end

					removeCall(module.statValues.Raw_Floor, module.statValues.Queue_Direction)
					return
				end
				if (not nextQueue) then
					module.statValues.Queue_Direction = 0
					task.spawn(updateStatValues)
					return
				end
				task.spawn(goToFloor, nextQueue.call)
			end)
			data.LanternsReset:Once(function(types)
				task.spawn(resetLanterns, module.statValues.Raw_Floor, module.statValues.Queue_Direction, types)
				local nextQueue = select(2, checkNearestCallInDirection(module.statValues.Raw_Floor, module.statValues.Queue_Direction))
				-- // No call in current direction? Check in the opposite direction
				if (not nextQueue) then nextQueue = select(2, checkNearestCallInDirection(module.statValues.Raw_Floor, -module.statValues.Queue_Direction)) end
				-- // Still no call? Check in any direction
				if (not nextQueue) then nextQueue = select(2, checkNearestCallInDirection(module.statValues.Raw_Floor, 0)) end
				if (not nextQueue) then
					module.statValues.Queue_Direction = 0
					task.spawn(updateStatValues)
					return
				end
			end)
			data:Close(floor)
			runTask = task.spawn(function()
				while (data.state == 'Closing') do
					sensorParams.FilterDescendantsInstances = _G.ElevatorSensorHumanoids
					local obstructed = #workspace:GetPartBoundsInBox(data.doorSensorPart.CFrame, data.doorSensorPart.Size, sensorParams) > 0
					if (obstructed ~= isObstructed) then
						isObstructed = obstructed
						api:Fire('doorObstructionStateChanged', { ['side'] = data.side, ['isObstructed'] = isObstructed })
						data.obstructionSignal.Playing = obstructed
						task.spawn(runDoorOpen, module.statValues.Raw_Floor, data.side, 'Open_No_Call')
					end
					if ((os.clock()-data.nudgeTimestamp)/configFile.Doors.Nudge_Timer > 1 and (not data.nudging) and data.state == 'Closing' and (not checkIndependentService()) and (not module.statValues.Fire_Service)) then
						module.statValues.Nudge = true
						data.nudging = true
						module.statValues[`{data.sideJoin}Door_Nudging`] = data.nudging
						module.sounds.Nudge_Buzzer.Playing = true
						task.spawn(updateStatValues)
					end
					heartbeat:Wait()
				end
			end)
		end
		if (module.statValues.Out_Of_Service or module.statValues.Stop) then return end
		if (string.upper(side) == 'ALL') then
			for _, v in pairs(module.doorData) do
				task.spawn(runDoor, v)
			end
		else
			local data = module.doorData[side]
			if (not data) then return end
			task.spawn(runDoor, data)
		end
	end

	function checkDoorStates(state, params)
		local thisFloor = findRegisteredFloor(module.statValues.Raw_Floor)
		if (not thisFloor) then return end
		local dontRequireAll = params and params.dontRequireAll or false
		local onlyPresentDoors = params and params.onlyPresentDoors or false
		local isAllStates = true

		for i, v in pairs(module.doorData) do
			if (not dontRequireAll) and v.state ~= state and ((not onlyPresentDoors) and true or thisFloor.floorInstance:FindFirstChild(`{v.side == '' and '' or `{v.side}_`}Doors`)) then
				isAllStates = false
				break
			elseif dontRequireAll and v.state == state then
				return true
			end
		end
		if (dontRequireAll) then
			return false
		elseif (not dontRequireAll) then
			return isAllStates
		end

		--for i, v in pairs(module.doorData) do
		--	if (v.state ~= state) then return false end
		--end
		--return true
	end

	-- // Queue handling // --

	function findCallInQueue(call, direction)
		for i, v in pairs(module.queue) do
			if (v.call == call and (typeof(direction) ~= 'number' or direction == 0 or table.find(v.directions, direction) or #v.directions == 0)) then return i, v end
		end

		return nil
	end
	function checkNearestCallInDirection(call, direction, requireDirectionInCall)
		local function checkForDirection(call, direction)
			for i, v in pairs(call.directions) do
				if (v == direction) then return true end
			end
			if (requireDirectionInCall == false) then return true end
			return false
		end

		local nearResult, nearDist = {}, math.huge
		for i, v in next, module.queue do
			if (math.abs(v.call-call) <= nearDist and (
				((v.call > call and direction == 1 and
					(checkForDirection(v, direction) or #module.queue <= 1 or #v.directions == 0 or v.call == topFloor.floorNumber or v.call == bottomFloor.floorNumber or v.isCarCall))
					or (v.call < call and direction == -1 and
						(checkForDirection(v, direction) or #module.queue <= 1 or #v.directions == 0 or v.call == topFloor.floorNumber or v.call == bottomFloor.floorNumber or v.isCarCall))) or
					(direction == 0 and v.call ~= call))) then
				nearResult = {i, v}
				nearDist = math.abs(v.call-call)
			end
		end
		return table.unpack(nearResult)
	end

	function getTotalDirectionSides(sides, direction)
		local count = 0
		for _, side in pairs(sides) do
			local sideDirection = tonumber(string.split(side, '_')[1])
			if sideDirection == direction or sideDirection == 0 then
				count += 1
			end
		end

		return count
	end

	function addCall(callParams)
		local callIndex, callExists = findCallInQueue(callParams.call)
		local direction = if (typeof(callParams.direction) == 'string') then callParams.direction == 'U' and 1 or callParams.direction == 'D' and -1 elseif (typeof(callParams.direction) == 'number') then callParams.direction else nil
		local newTemplate = {
			['call'] = callParams.call,
			['directions'] = {},
			['sides'] = {},
			['isCarCall'] = if (typeof(callParams.isCarCall) == 'boolean') then callParams.isCarCall else false
		}
		if (callExists) then
			if (callExists.isCarCall == nil or callExists.isCarCall == false) then
				callExists.isCarCall = if (typeof(callParams.isCarCall) == 'boolean') then callParams.isCarCall else false
			end

			if callParams.side and not table.find(callExists.sides, `{callParams.direction or 0}_{callParams.side}`) then
				table.insert(callExists.sides, `{callParams.direction or 0}_{callParams.side}`)
			end

			if not (table.find(callExists.directions, direction)) then
				table.insert(callExists.directions, direction)
			end

		else
			if callParams.side and not table.find(newTemplate.sides, `{callParams.direction or 0}_{callParams.side}`) then
				table.insert(newTemplate.sides, `{callParams.direction or 0}_{callParams.side}`)
			end
			if (not table.find(newTemplate.directions, direction)) then 
				table.insert(newTemplate.directions, direction)
			end
			table.insert(module.queue, newTemplate)
		end
		-- // Set queue direction if idle // --
		if (module.statValues.Queue_Direction == 0) then
			module.statValues.Queue_Direction = callParams.call > module.statValues.Raw_Floor and 1 or callParams.call < module.statValues.Raw_Floor and -1 or 0
			task.spawn(updateStatValues)
		end
		-- // Set the destination to call if within range // --
		if ((module.statValues.Queue_Direction == 1 and (callParams.direction == module.statValues.Queue_Direction or typeof(callParams.direction) ~= 'number') and callParams.call > module.statValues.Raw_Floor and callParams.call < module.statValues.Destination) or (module.statValues.Queue_Direction == -1 and (callParams.direction == module.statValues.Queue_Direction or typeof(callParams.direction) ~= 'number') and callParams.call < module.statValues.Raw_Floor and callParams.call > module.statValues.Destination) or module.statValues.Queue_Direction == 0) then
			module.statValues.Destination = callParams.call
			task.spawn(updateStatValues)
		end
		if (not moveLock) then
			task.spawn(goToFloor, callParams.call)
		end
		if (not callExists) then
			api:Fire('onCallAdded', { call = callParams.call, direction = callParams.direction })
		end
		queueValue.Value = httpService:JSONEncode(module.queue)
		return true
	end

	function removeCall(call, direction)
		local removed = false
		local q = module.queue
		for i, v in pairs(q) do
			if (v.call == call and ((direction == 0 or typeof(direction) ~= 'number') or table.find(v.directions, direction) or #v.directions == 0)) then
				local dirs = v.directions
				for i, d in pairs(dirs) do
					if (d ~= direction) then continue end
					table.remove(v.directions, i)
					removed = true
				end
				if (#v.directions == 0 or direction == 0) then
					table.remove(module.queue, i)
					removed = true
					api:Fire('onCallRemoved', { call = call, direction = direction })
				end
				for i, b in pairs(car:GetDescendants()) do
					local buttonFloor = tonumber(string.split(b.Name, '_')[2]) or tonumber(string.split(b.Name, 'Floor')[2])
					if ((not buttonFloor) or buttonFloor ~= call) then continue end
					setButton(b, configFile.Color_Database.Car.Floor_Button, 'Neautral_State', car)
				end
				local regFloor = findRegisteredFloor(call)
				if (not regFloor) then continue end
				for i, c in pairs(regFloor.floorInstance:GetChildren()) do
					if (c.Name ~= 'Call_Buttons') then continue end
					for _, b in pairs(c:GetDescendants()) do
						local buttonName = string.split(b.Name, '_')[1]
						if (buttonName ~= 'Up' and buttonName ~= 'Down') then continue end
						local buttonDirection = buttonName == 'Up' and 1 or buttonName == 'Down' and -1 or 0
						if (buttonDirection ~= direction) then continue end
						setButton(b, configFile.Color_Database.Floor[buttonName], 'Neautral_State', b.Parent)
					end
				end
			end
		end
		queueValue.Value = httpService:JSONEncode(module.queue)
		return removed
	end

	-- // Motor sound handling // --
	function doMotorSound()
		local dirIndex = module.statValues.Move_Value == 1 and 'Up' or module.statValues.Move_Value == -1 and 'Down' or nil
		if (not dirIndex) then return end
		for i, v in pairs(module.sounds) do
			if (string.match(v.Name, 'Motor_Start_')) then
				v.Playing = i == `Motor_Start_{dirIndex}`
			end
		end
		statValuesFolder.Leveling:GetPropertyChangedSignal('Value'):Once(function()
			if (not statValuesFolder.Leveling.Value) then return end
			module.sounds[`Motor_Start_{dirIndex}`]:Stop()
			module.sounds[`Motor_Run_{dirIndex}`]:Stop()
			module.sounds[`Motor_Stop_{dirIndex}`]:Play()
		end)
		local connection: RBXScriptConnection
		connection = api.Event:Connect(function(protocol)
			if (protocol ~= 'On_Safety_Brake') then return end
			connection:Disconnect()
			for i, v in pairs(module.sounds) do
				if (string.match(v.Name, 'Motor_')) then
					v:Stop()
				end
			end
		end)
		module.sounds[`Motor_Start_{dirIndex}`].Ended:Wait()
		if (statValuesFolder.Leveling.Value) then return end
		module.sounds[`Motor_Run_{dirIndex}`]:Play()
	end

	-- // Player welding // --
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	local elevatorPlayerWelds = {}
	function playerWeld(weld)
		if (weld) then
			if (configFile.Movement.Weld_On_Move) then
				params.FilterDescendantsInstances = _G.ElevatorSensorHumanoids
				local parts = workspace:GetPartBoundsInBox(cabRegion.CFrame, cabRegion.Size, params)
				for _, v in pairs(parts) do
					local humanoid,root = v.Parent:FindFirstChildOfClass('Humanoid'),v.Parent:FindFirstChild('HumanoidRootPart')
					if (not (humanoid and root) or root:FindFirstChild('Cortex_Elevator_Weld')) then continue end
					local weld = Instance.new('Weld')
					weld.Name = 'Cortex_Elevator_Weld'
					--weld.Part0, weld.Part1 = (not configFile.Movement.Enable_New_Player_Sticking) and root or nil, platform
					weld.Part0, weld.Part1 = root, platform
					weld.C0, weld.C1 = CFrame.new(), weld.Part0 and weld.Part1.CFrame:ToObjectSpace(weld.Part0.CFrame) or CFrame.new()
					humanoid.PlatformStand = not configFile.Movement.Enable_New_Player_Sticking
					weld.Parent = root
					local yOffset = math.abs(root.CFrame.Position.Y-platform.CFrame.Position.Y)
					--local att0, att1 = Instance.new('Attachment'), Instance.new('Attachment')
					--att0.Parent, att1.Parent = root, platform
					--att1.WorldPosition += Vector3.new(0, yOffset, 0)
					--local ap = Instance.new('AlignPosition')
					--ap.Attachment0, ap.Attachment1 = att0, att1
					--ap.Responsiveness = math.huge
					--ap.ForceLimitMode = Enum.ForceLimitMode.PerAxis
					--ap.MaxAxesForce = Vector3.new(0, 1, 0)*math.huge
					--ap.Parent = players:GetPlayerFromCharacter(root.Parent) and root or nil
					table.insert(elevatorPlayerWelds, { weld = weld, humanoid = humanoid, root = root, yOffset = yOffset, extras = { ap, att0, att1 }, jumpPower = humanoid.JumpPower, jumpHeight = humanoid.JumpHeight })
					--humanoid.JumpPower = 0
					--humanoid.JumpHeight = 0
				end
			end
		else
			for _, v in pairs(elevatorPlayerWelds) do
				for i, s in pairs(v.extras) do
					s:Destroy()
				end
				v.humanoid.PlatformStand = false
				v.weld:Destroy()
				--v.humanoid.JumpPower = v.jumpPower
				--v.humanoid.JumpHeight = v.jumpHeight
				elevatorPlayerWelds[_] = nil
			end
		end
	end

	local lastPlatformPosition = platform.CFrame.Position
	function moveElevator(dtTime)
		elevatorPosition *= CFrame.new(0, module.statValues.Move_Value*module.statValues.Current_Speed*dtTime, 0)
		platform.CFrame = elevatorPosition
		module.statValues.Velocity = module.statValues.Current_Speed

		local carSpeed = (platform.CFrame.Position-lastPlatformPosition)
		lastPlatformPosition = platform.CFrame.Position
		if (counterweight and cwStart) then
			cwOffset -= carSpeed
			local oriX,oriY,oriZ = cwStart:ToOrientation()
			counterweight.Main.CFrame = CFrame.new(cwOffset)*CFrame.Angles(oriX, oriY, oriZ)
			counterweight.Main.Traveling_Sound.Volume = math.clamp(math.abs(module.statValues.Current_Speed)/15, 0, 2)
		end

		local tSpeedFactor = configFile.Sound_Database.Others.Traveling_Sound.Speed_Factor*(module.statValues.Current_Speed/configFile.Movement.Travel_Speed)
		local volumeConstraint = configFile.Sound_Database.Others.Traveling_Sound.Constraints.Volume
		local pitchConstraint = configFile.Sound_Database.Others.Traveling_Sound.Constraints.Pitch
		if (not module.sounds.Traveling_Sound.Playing) then
			module.sounds.Traveling_Sound.Playing = true
		end
		module.sounds.Traveling_Sound.Volume = configFile.Sound_Database.Others.Traveling_Sound.Factor_Type == 'Travel_Speed_Ratio' and ((volumeConstraint.Max-volumeConstraint.Min)*tSpeedFactor)+volumeConstraint.Min or math.abs(module.statValues.Current_Speed)/30
		module.sounds.Traveling_Sound.PlaybackSpeed = configFile.Sound_Database.Others.Traveling_Sound.Factor_Type == 'Travel_Speed_Ratio' and ((pitchConstraint.Max-pitchConstraint.Min)*tSpeedFactor)+pitchConstraint.Min or math.clamp(.5+math.abs(module.statValues.Current_Speed)/30, pitchConstraint.Min, pitchConstraint.Max)
		task.spawn(updateStatValues)
		task.spawn(updateFloor)
		return dtTime, carSpeed.Y > 0 and 1 or carSpeed.Y < 0 and -1 or 0
	end

	-- // Safety brake // --
	local safetyBraking = false

	function safetyBrake()
		if (safetyBraking) then return end
		safetyBraking = true
		preDooring = false
		local initialSpeed = module.statValues.Current_Speed
		local rate = 1.35
		local dtTime = 0
		pcall(task.cancel, elevatorMovementThread)
		pcall(task.cancel, elevatorRelevelThread)
		if (module.statValues.Current_Speed > 0) then
			module.sounds.Safety_Brake_Sound:Play()
		end
		while (module.statValues.Current_Speed > 0 and safetyBraking) do
			module.statValues.Current_Speed = math.max(0, module.statValues.Current_Speed-rate*math.deg(dtTime))
			moveElevator(dtTime)
			dtTime = heartbeat:Wait()
		end
		if (initialSpeed > 0) then
			api:Fire('On_Safety_Brake')
			playVoiceSequenceProtocolWithQueue(voiceConfig.Settings.Other_Announcements.Safety_Brake_Announcement.Sequence, false, voiceConfig.Settings.Other_Announcements.Safety_Brake_Announcement.Enabled)
			local threshold = (initialSpeed/2)/rate^2
			local bounceThreshold = 1
			local dtTime = 0
			while (bounceThreshold > 0) do
				module.statValues.Current_Speed = math.sin(tick()*20)*bounceThreshold*threshold
				moveElevator(dtTime)
				bounceThreshold = math.max(0, bounceThreshold-.035*math.deg(dtTime))
				dtTime = heartbeat:Wait()
			end
		end
		module.statValues.Current_Speed = 0
		module.statValues.Move_Value = 0
		moveLock = false
		safetyBraking = false
		task.spawn(updateStatValues)
		releveling = false
	end

	local dropKeyUpdaters = {}

	-- // Drop key system // --
	function isDropKeyOnElevator()
		for i,v in pairs(module.dropKeyCheckValues) do
			if (v.Value) then return false end
		end
		return true
	end

	local function doDropKey(params) -- to rewrite soon
		--print(pluginModuleData)
		local doorSide = string.split(string.split(params.Name, 'Doors')[1], '_')[1]

		local function getWelds()
			local welds = {}
			local floorNumber = tonumber(string.gsub(params.Parent.Name, '%D', ''))

			for i, v in next, module.doorData do
				for i, w in next,(params:IsDescendantOf(car) and v.engineWelds.car[doorSide] or v.engineWelds.floors[tostring(floorNumber)] and v.engineWelds.floors[tostring(floorNumber)][doorSide] or {}) do
					table.insert(welds, w)
				end
			end

			return welds
		end

		local landingLevel = findAncestor(params, 'Level')
		if (not landingLevel) then return end

		if ((landingLevel.Parent == car and module.doorData[doorSide].state == 'Closed') or (landingLevel.Parent ~= car and (((module.doorData[doorSide].state == 'Closed' and tonumber(landingLevel.Parent.Name:sub(7)) == module.statValues.Raw_Floor) or tonumber(landingLevel.Parent.Name:sub(7)) ~= module.statValues.Raw_Floor)))) then
			for i,weld in pairs(getWelds()) do
				if (weld.instance.C0 == weld.closedPosition) then
					landingLevel.Drop_Key_Sound:Play()
					task.spawn(function()
						pluginModuleData.Legacy_Easing.CONTENT:interpolate(weld.instance,weld.openPosition,weld.instance.C1,'Out_Bounce',configFile.Doors.Door_Open_Speed*1.3)
					end)
					if module.statValues.moveValue ~= 0 and isDropKeyOnElevator() then
						module.sounds.Safety_Brake_Sound.PlaybackSpeed = module.sounds.Safety_Brake_Sound:GetAttribute('originalPitch')
						safetyBrake()
					else
						moveBrake = true
					end
					module.statValues.Out_Of_Service = true
					params.Drop_Key_Open.Value = true
					module.doorData[doorSide].IsDropKey = true
					task.spawn(updateStatValues)
				elseif (weld.instance.C0 == weld.openPosition) then
					landingLevel.Drop_Key_Sound:Play()
					task.spawn(function()
						pluginModuleData.Legacy_Easing.CONTENT:interpolate(weld.instance,weld.closedPosition,weld.instance.C1,'Out_Sine',configFile.Doors.Door_Open_Speed*1.3)
						params.Drop_Key_Open.Value = false
						module.doorData[doorSide].IsDropKey = false
						moveBrake = not isDropKeyOnElevator()
						module.statValues.Out_Of_Service = not isDropKeyOnElevator()
						preDooring = false
						releveling = false
						task.spawn(updateStatValues)
					end)
				end
			end
		end
	end

	local dropKeyHandlers = {}
	function checkDropKeyState()
		for i, v in pairs(module.doorData) do
			if (not v.isEnabled) then return false end
		end
		return true
	end

	local function dismountDropKeyClient(user,params)
		local doorSet = params
		if (not collectionService:HasTag(doorSet, 'IsInUse')) then return end
		local thisFloorName = doorSet:IsDescendantOf(floors) and string.split(doorSet.Parent.Name, 'Floor_')[2]
		local landingLevel = doorSet.Parent.Level
		local sideIndex = doorSet.Name:split('Doors')[1]:split('_')[1]
		local fullSideName = (sideIndex == '' and 'Front' or sideIndex)

		for i,v in pairs(dropKeyHandlers[doorSet] or {}) do
			v:Disconnect()
		end
		local index = table.find(dropKeyHandlers,user)
		if (index) then
			table.remove(dropKeyHandlers,index)
		end
		local doorBounds = doorSet:FindFirstChild('Door_Bounds')
		if (doorBounds) then doorBounds:Destroy() end
		dropKeyHandlers[doorSet] = nil

		local welds = {}
		local data = module.doorData[sideIndex]
		local welds = {}
		for i,v in next,data and (doorSet:IsDescendantOf(car) and car.Door_Engine_Welds:FindFirstChild(sideIndex):GetChildren() or findRegisteredFloor(thisFloorName).floorInstance:FindFirstChild('Door_Engine_Welds'):FindFirstChild(sideIndex):GetChildren()) or {} do
			table.insert(welds, { ['weld'] = v })
		end
		local function checkIfDoorIsClosed()
			for i,v in pairs(welds) do
				if (v.weld.C0 ~= v.weld:GetAttribute('closedPoint')) then return false end
			end
			return true
		end

		local isClosed = checkIfDoorIsClosed()

		local function check()
			module.statValues.Out_Of_Service = not checkDropKeyState()
			preDooring = false
			api:Fire('onElevDoorKey',{doorSet=doorSet,status='release'})
			task.spawn(updateStatValues)
			task.spawn(function()
				local isCompleted = coreFunctions.conditionalWait(1, function() return {not module.statValues.Out_Of_Service} end)
				if (not isCompleted) then return end
				task.spawn(relevel, module.statValues.Raw_Floor, .015)
			end)
		end
		addPlayingSound(landingLevel, addSound(landingLevel, 'Interlock_Click', {
			Sound_Id = 9116323848,
			Volume = 1,
			Pitch = 1.35
		}, false, 40, 3))
		if (isClosed) then
			check()
		elseif (not isClosed) then
			local hasCompleted = coreFunctions.conditionalWait(2, function() return {collectionService:HasTag(doorSet, 'IsInUse')} end)
			if (not hasCompleted) then return end
			local connection: RBXScriptConnection

			local i = 0
			for _,v in pairs(welds) do
				v.startPosition = v.weld.C0
				v.alpha = 0
			end

			connection = heartbeat:Connect(function(dtTime)
				i += .025*dtTime
				for _,v in pairs(welds) do
					v.alpha += i
					v.weld.C0 = v.startPosition:Lerp(v.weld:GetAttribute('closedPoint'), math.min(v.alpha,1))
				end
				if (dropKeyHandlers[doorSet]) then return connection:Disconnect() end

				if checkIfDoorIsClosed() then
					local doorSide = string.split(doorSet.Name, '_')[1]
					module.doorData[doorSide].isEnabled = true
				end

				if (checkIfDoorIsClosed()) then connection:Disconnect() return check() end
			end)
		end

		collectionService:RemoveTag(doorSet, 'IsInUse')
	end

	function stopAtFloor(floor, park)
		local regFloor = findRegisteredFloor(floor)
		if (not regFloor) then return end
		local direction = module.statValues.Move_Value
		local floorQueue

		local distanceToFloor = module.statValues.Move_Value*(regFloor.level.Position.Y-level.Position.Y)
		local offsetDistanceToFloor = module.statValues.Move_Value*((regFloor.level.Position.Y+direction*(configFile.Sensors.Stop_Offset+configFile.Movement.Braking_Data[`Linear_Mode_Offset_{direction == 1 and 'Up' or direction == -1 and 'Down'}`]))-level.Position.Y)
		local stopped = false
		local weldsRemoved = false
		local levelingStage = 0

		local INITIAL_SPEED, DISTANCE_TO_DECELERATE = module.statValues.Current_Speed, offsetDistanceToFloor

		local dtTime = 0

		while (not stopped) do
			distanceToFloor = module.statValues.Move_Value*(regFloor.level.Position.Y-level.Position.Y)
			offsetDistanceToFloor = module.statValues.Move_Value*((regFloor.level.Position.Y+direction*(configFile.Sensors.Stop_Offset+configFile.Movement.Braking_Data[`Linear_Mode_Offset_{direction == 1 and 'Up' or direction == -1 and 'Down'}`]))-level.Position.Y)
			if (not module.statValues.Leveling) then
				module.statValues.Leveling = true
				module.statValues.Arrive_Floor = floor

				-- // Get nearest call in direction
				local nextCall = select(2, checkNearestCallInDirection(module.statValues.Arrive_Floor, module.statValues.Queue_Direction))

				--// No calls? Check in the opposite direction
				if (not nextCall) then nextCall = select(2, checkNearestCallInDirection(module.statValues.Arrive_Floor, -module.statValues.Queue_Direction)) end

				-- // Still no calls? Check in any direction
				if (not nextCall) then nextCall = select(2, checkNearestCallInDirection(module.statValues.Arrive_Floor, 0)) end

				-- // Yet still no calls? Let's look for any directional calls on current floor
				local thisCall = select(2, findCallInQueue(module.statValues.Arrive_Floor))

				local callDirection
				for _, v in pairs(thisCall and thisCall.directions or {}) do
					if (v == module.statValues.Queue_Direction or (module.statValues.Arrive_Floor == topFloor.floorNumber or module.statValues.Arrive_Floor == bottomFloor.floorNumber) or #module.queue <= 1) then
						callDirection = v
						break
					end
				end

				module.statValues.Queue_Direction = callDirection or (nextCall and (nextCall.call > module.statValues.Arrive_Floor and 1 or nextCall.call < module.statValues.Arrive_Floor and -1)) or 0

				api:Fire('onCallRespond', { floor = module.statValues.Arrive_Floor, direction = module.statValues.Queue_Direction == 1 and 'U' or module.statValues.Queue_Direction == -1 and 'D' or 'N' })
				api:Fire('onElevatorArrive', { floor = module.statValues.Arrive_Floor, direction = module.statValues.Queue_Direction == 1 and 'U' or module.statValues.Queue_Direction == -1 and 'D' or 'N' })

				if (not park) and (not checkIndependentService()) and (not module.statValues.Fire_Service) then
					task.spawn(runChime, module.statValues.Arrive_Floor, module.statValues.Queue_Direction, {'Exterior', 'Interior'}, configFile.Sound_Database.Chime_Events.On_Arrival, true)
					task.spawn(doLanterns, module.statValues.Arrive_Floor, module.statValues.Queue_Direction, {'Exterior', 'Interior'}, configFile.Color_Database.Lanterns.Active_On_Arrival, true)

					playVoiceSequenceProtocolWithQueue(voiceConfig.Floor_Announcements[tostring(floor)] or {}, true, voiceConfig.Settings.Floor_Announcements.Announce_Floor_On_Arrival)

					if (voiceConfig.Settings.Directional_Announcements.Announce_After_Floor_Announcement and module.statValues.Queue_Direction ~= 0) then
						local dir = module.statValues.Queue_Direction == 1 and 'Up' or module.statValues.Queue_Direction == -1 and 'Down'
						local clip = voiceConfig.Settings.Directional_Announcements[`{dir}_Announcement`]
						if clip then
							playVoiceSequenceProtocolWithQueue(clip.Sequence, false, clip.Enabled)
						end
					end
				end
				--removeCall(module.statValues.Arrive_Floor, module.statValues.Queue_Direction)
			end
			if (module.statValues.Current_Speed > configFile.Movement.Level_Speed) then
				if (configFile.Movement.Braking_Data.Mode == 'Linear') then
					local currentSpeed = module.statValues.Current_Speed
					local gradualDecelRatio = math.min(1, math.max(.1, ((offsetDistanceToFloor/(DISTANCE_TO_DECELERATE*configFile.Movement.Smooth_Stop_V2.Threshold)))/(currentSpeed/INITIAL_SPEED)))
					local rate = currentSpeed^2/(2*offsetDistanceToFloor*(configFile.Movement.Smooth_Stop_V2.Enable and gradualDecelRatio or 1))
					local newSpeed = math.max(0, currentSpeed-rate*dtTime)
					module.statValues.Current_Speed = math.max(newSpeed, configFile.Movement.Level_Speed)
				elseif (configFile.Movement.Braking_Data.Mode == 'SmartLinear') then
					if (offsetDistanceToFloor > configFile.Movement.Braking_Data.Smart_Linear_Transition_Dist*(INITIAL_SPEED/(configFile.Movement.Travel_Speed/3)) and levelingStage ~= 2) then
						levelingStage = 1
						local currentSpeed = module.statValues.Current_Speed
						local currentSpeed = module.statValues.Current_Speed
						local gradualDecelRatio = math.min(1, math.max(.1, ((offsetDistanceToFloor/(DISTANCE_TO_DECELERATE*configFile.Movement.Smooth_Stop_V2.Threshold)))/(currentSpeed/INITIAL_SPEED)))
						local rate = currentSpeed^2/(2*offsetDistanceToFloor*(configFile.Movement.Smooth_Stop_V2.Enable and gradualDecelRatio or 1))
						local newSpeed = math.max(0, currentSpeed-rate*dtTime)
						module.statValues.Current_Speed = math.max(newSpeed, configFile.Movement.Level_Speed)
					elseif (levelingStage == 1) then
						levelingStage = 2
						INITIAL_SPEED,DISTANCE_TO_DECELERATE = module.statValues.Current_Speed,offsetDistanceToFloor
						api:Fire('levelingStageChange', { brakingMode = configFile.Movement.Braking_Data.Mode, stage=levelingStage })
					elseif (levelingStage == 2) then
						module.statValues.Current_Speed = math.clamp((INITIAL_SPEED/DISTANCE_TO_DECELERATE)*offsetDistanceToFloor, configFile.Movement.Level_Speed, if (INITIAL_SPEED) < configFile.Movement.Level_Speed then INITIAL_SPEED+configFile.Movement.Level_Speed else INITIAL_SPEED)
					end
				elseif (configFile.Movement.Braking_Data.Mode == 'Default') then
					module.statValues.Current_Speed = math.min(configFile.Movement.Level_Speed, (INITIAL_SPEED/DISTANCE_TO_DECELERATE)*distanceToFloor)
				elseif (configFile.Movement.Braking_Data.Mode == 'Manual') then
					module.statValues.Current_Speed = math.min(configFile.Movement.Level_Speed, module.statValues.Current_Speed-configFile.Movement.Braking_Data.Increment*math.deg(dtTime))
				end
			elseif (not weldsRemoved) then
				weldsRemoved = true
				playerWeld(false)
			end

			if (distanceToFloor <= configFile.Sensors.Pre_Door_Data.Offset and configFile.Sensors.Pre_Door_Data.Enable and (not preDooring)) then
				api:Fire('onElevatorOpen', {floor = module.statValues.Arrive_Floor})
				if (not park) then
					task.spawn(runChime, module.statValues.Arrive_Floor, module.statValues.Queue_Direction, {'Exterior', 'Interior'}, configFile.Sound_Database.Chime_Events.On_Open, true)
					task.spawn(doLanterns, module.statValues.Arrive_Floor, module.statValues.Queue_Direction, {'Exterior', 'Interior'}, configFile.Color_Database.Lanterns.Active_On_Door_Open, true)
				end
				local thisCall = select(2, findCallInQueue(module.statValues.Arrive_Floor))
				if ((((not module.statValues.Fire_Service) or (module.statValues.Fire_Recall and fireServiceRecallFloor == module.statValues.Raw_Floor))) and (not preDooring)) then
					preDooring = true
					if (getTotalDirectionSides(thisCall and thisCall.sides or {}, thisCall and thisCall.directions[1] or 0) == 0) then
						task.spawn(runDoorOpen, floor, 'all', thisCall and thisCall.directions[1] and 'Open_By_Call' or 'Open_On_Stop')
					else
						local callSidesCopy = table.clone(thisCall.sides)
						for _, side in pairs(callSidesCopy) do
							local dir = #thisCall.directions > 0 and thisCall.directions[1] or 0
							if dir then
								if tonumber(string.split(side, '_')[1]) == dir or tonumber(string.split(side, '_')[1]) == 0 then
									table.remove(module.queue[select(1, findCallInQueue(thisCall.call))].sides, table.find(module.queue[select(1, findCallInQueue(thisCall.call))].sides, side))
									task.spawn(runDoorOpen, floor, string.split(side, '_')[2], thisCall and thisCall.directions[1] and 'Open_By_Call' or 'Open_On_Stop')
								end
							end
						end
					end
				end

				removeCall(module.statValues.Arrive_Floor, module.statValues.Queue_Direction)
			end
			if (distanceToFloor <= 0) then
				stopped = true
				api:Fire('onCallRespond', {floor = floor, direction = module.statValues.Queue_Direction, parking = module.statValues.Parking})
				api:Fire('onElevatorStop', {floor = module.statValues.Arrive_Floor})
				break
			end
			moveElevator(dtTime)
			dtTime = heartbeat:Wait()
		end
		moveLock = false
		releveling = false
		module.statValues.Move_Value = 0
		module.statValues.Move_Direction = 0
		module.statValues.Velocity = 0
		module.statValues.Current_Speed = 0
		module.statValues.Leveling = false
		module.statValues.Arrow_Direction = 0
		task.spawn(updateStatValues)
		task.spawn(updateFloor)

		if voiceConfig.Settings.Floor_Announcements.Announce_Floor_On_Stop and (not park) and (not checkIndependentService()) and (module.statValues.Fire_Service) then
			playVoiceSequenceProtocolWithQueue(voiceConfig.Floor_Announcements[tostring(floor)] or {}, true, voiceConfig.Settings.Floor_Announcements.Announce_Floor_On_Stop)

			if (voiceConfig.Settings.Directional_Announcements.Announce_After_Floor_Announcement and module.statValues.Queue_Direction ~= 0) then
				local dir = module.statValues.Queue_Direction == 1 and 'Up' or module.statValues.Queue_Direction == -1 and 'Down'
				local clip = voiceConfig.Settings.Directional_Announcements[`{dir}_Announcement`]
				if clip then
					playVoiceSequenceProtocolWithQueue(clip.Sequence, false, clip.Enabled)
				end
			end
		end

		local thisCall = select(2, findCallInQueue(module.statValues.Arrive_Floor))
		local hasPassed = coreFunctions.conditionalWait(configFile.Movement.Stop_Delay, function() return {module.statValues.Move_Value == 0} end)
		if (not hasPassed) then return end
		if ((((not module.statValues.Fire_Service) or (module.statValues.Fire_Recall and fireServiceRecallFloor == module.statValues.Raw_Floor))) and (not preDooring)) then
			api:Fire('onElevatorOpen', {floor = module.statValues.Arrive_Floor})
			task.spawn(runChime, module.statValues.Arrive_Floor, module.statValues.Queue_Direction, {'Exterior', 'Interior'}, configFile.Sound_Database.Chime_Events.On_Open, true)
			task.spawn(doLanterns, module.statValues.Arrive_Floor, module.statValues.Queue_Direction, {'Exterior', 'Interior'}, configFile.Color_Database.Lanterns.Active_On_Door_Open, true)

			if (getTotalDirectionSides(thisCall.sides, thisCall and thisCall.directions[1] or 0) == 0) then
				task.spawn(runDoorOpen, floor, 'all', thisCall and thisCall.directions[1] and 'Open_By_Call' or 'Open_On_Stop')
			else
				local callSidesCopy = table.clone(thisCall.sides)
				for _, side in pairs(callSidesCopy) do
					local dir = #thisCall.directions > 0 and thisCall.directions[1] or 0
					if dir then
						if tonumber(string.split(side, '_')[1]) == dir or tonumber(string.split(side, '_')[1]) == 0 then
							table.remove(module.queue[select(1, findCallInQueue(thisCall.call))].sides, table.find(module.queue[select(1, findCallInQueue(thisCall.call))].sides, side))
							task.spawn(runDoorOpen, floor, string.split(side, '_')[2], thisCall and thisCall.directions[1] and 'Open_By_Call' or 'Open_On_Stop')
						end
					end
				end
			end

			removeCall(module.statValues.Arrive_Floor, module.statValues.Queue_Direction)
		end
		preDooring = false

		local hasPassed = coreFunctions.conditionalWait(2, function() return {module.statValues.Move_Value == 0 and checkDoorStates('Closed')} end)
		if (not hasPassed) then return end

		local nextQueue = select(2, checkNearestCallInDirection(module.statValues.Raw_Floor, module.statValues.Queue_Direction))

		-- // No call in current direction? Check in the opposite direction
		if (not nextQueue) then nextQueue = select(2, checkNearestCallInDirection(module.statValues.Raw_Floor, -module.statValues.Queue_Direction)) end

		-- // Still no call? Check in any direction
		if (not nextQueue) then nextQueue = select(2, checkNearestCallInDirection(module.statValues.Raw_Floor, 0)) end

		-- // Yet still no call? Let's look for any calls on the current floor // --
		local thisCall = select(2, findCallInQueue(module.statValues.Raw_Floor, -module.statValues.Queue_Direction))
		if ((not select(2, checkNearestCallInDirection(module.statValues.Raw_Floor, module.statValues.Queue_Direction))) and thisCall) then
			module.statValues.Queue_Direction = 0
			task.spawn(updateStatValues)
			local hasCompleted = coreFunctions.conditionalWait(1, function() return {not moveLock} end)
			if (not hasCompleted) then return end
			module.statValues.Queue_Direction = thisCall.directions[1]
			api:Fire('onCallRespond', { floor = module.statValues.Raw_Floor, direction = module.statValues.Queue_Direction == 1 and 'U' or module.statValues.Queue_Direction == -1 and 'D' or 'N' })
			task.spawn(updateStatValues)
			task.spawn(runDoorOpen, floor, 'all', 'Open_By_Call')
			removeCall(module.statValues.Raw_Floor, module.statValues.Queue_Direction)
			return
		end

		if (not nextQueue) then
			module.statValues.Queue_Direction = 0
			task.spawn(updateStatValues)
			return
		end

		task.spawn(goToFloor, nextQueue.call)
	end

	function goToFloor(floor, park)

		local ran,res = pcall(function()
			if (not isElevatorSafe()) then return { ['RUN_STATUS'] = false, ['RUN_CODE'] = 'MOVE_NOT_SAFE' } end
			local regFloor = findRegisteredFloor(floor)
			if (not regFloor) then return { ['RUN_STATUS'] = false, ['RUN_CODE'] = 'INVALID_FLOOR' } end
			if (floor == module.statValues.Raw_Floor or moveLock or (not checkDoorStates('Closed')) or module.statValues.Out_Of_Service or module.statValues.Stop) then return { ['RUN_STATUS'] = false, ['RUN_CODE'] = 'NOT_MOVE_SAFE' } end

			elevatorMovementThread = task.spawn(function()
				local direction = floor > module.statValues.Raw_Floor and 1 or floor < module.statValues.Raw_Floor and -1 or nil
				if (not direction) then return { ['RUN_STATUS'] = false, ['RUN_CODE'] = 'UNKNOWN_DIRECTION' } end
				module.statValues.Move_Value = direction
				module.statValues.Queue_Direction = direction
				module.statValues.Move_Direction = direction
				module.statValues.Current_Speed = 0
				module.statValues.Destination = floor
				module.statValues.Leveling = false
				preDooring = false
				moveLock = true
				playerWeld(true)
				task.spawn(updateStatValues)

				api:Fire('onElevatorMoveBegin', { directionString = direction == 1 and 'U' or direction == -1 and 'D' or nil, directionValue = direction })

				task.spawn(function()
					local hasPassed = coreFunctions.conditionalWait(configFile.Movement.Motor_Start_Delay[direction == 1 and 'Up' or direction == -1 and 'Down'], function() return {module.statValues.Move_Value == direction} end)
					if (not hasPassed) then return end
					doMotorSound()
				end)
				local hasCompleted = coreFunctions.conditionalWait(configFile.Movement[direction == 1 and 'Start_Delay' or direction == -1 and 'Down_Start_Delay'], function() return {module.statValues.Move_Value == direction} end)
				if (not hasCompleted) then return task.cancel(elevatorMovementThread) end

				api:Fire('onDepartStart', { directionString = direction == 1 and 'U' or direction == -1 and 'D' or nil, directionValue = direction })
				if (configFile.Movement.Jolt_Start_Data.Enable) then
					local hasPassed = coreFunctions.conditionalWait(configFile.Movement.Jolt_Start_Data.Start_Delay, function() return {module.statValues.Move_Value == direction} end)
					if (not hasPassed) then return end

					local done = false
					local checked = false
					local lastSpeed = module.statValues.Current_Speed
					local startTime = os.clock()
					local dtTime = 0
					while (not checked) do
						module.statValues.Current_Speed = -(math.sin(math.abs(os.clock()-startTime)*math.pi*configFile.Movement.Jolt_Start_Data.Speed)*configFile.Movement.Jolt_Start_Data.Ratio)/(math.pi)
						local spd = module.statValues.Current_Speed
						if ((lastSpeed-spd) > 0) then
							lastSpeed = spd
						elseif (spd >= 0) then
							checked = true
						end
						elevatorPosition *= CFrame.new(0, module.statValues.Move_Value*module.statValues.Current_Speed*dtTime, 0)
						platform.CFrame = elevatorPosition
						module.statValues.Velocity = module.statValues.Current_Speed
						task.spawn(updateStatValues)
						dtTime = heartbeat:Wait()
					end
				end

				local initialSpeed = module.statValues.Current_Speed
				local accelerationRate = configFile.Movement[direction == 1 and 'Acceleration' or direction == -1 and 'Down_Acceleration'] or configFile.Movement.Acceleration
				local accelTime = coreFunctions.getAccelerationTime(initialSpeed, configFile.Movement.Travel_Speed, accelerationRate)
				local startTime = os.clock()

				local dtTime = 0
				local lvlOffset = configFile.Sensors[module.statValues.Move_Value == 1 and 'Up_Level_Offset' or module.statValues.Move_Value == -1 and 'Down_Level_Offset']

				local dynamicAccelRate = 1/math.deg(configFile.Movement.Dynamic_Acceleration_Time)
				local dynamicAccelValue = 0

				while true do

					regFloor = findRegisteredFloor(module.statValues.Destination)
					if (not regFloor) then continue end
					local distanceToFloor = module.statValues.Move_Value*(regFloor.level.Position.Y-level.Position.Y)
					local offsetDistanceToFloor = module.statValues.Move_Value*((regFloor.level.Position.Y+direction*(configFile.Sensors.Stop_Offset+configFile.Movement.Braking_Data[`Linear_Mode_Offset_{direction == 1 and 'Up' or direction == -1 and 'Down'}`]))-level.Position.Y)
					if (not module.statValues.Leveling) then
						dynamicAccelValue = math.clamp(dynamicAccelValue+dynamicAccelRate*math.deg(dtTime), 0, 1)
						module.statValues.Current_Speed = coreFunctions.lerp(initialSpeed, configFile.Movement.Travel_Speed*dynamicAccelValue, math.min((os.clock()-startTime)/accelTime, 1))
					end

					if (distanceToFloor <= lvlOffset*(module.statValues.Current_Speed*configFile.Movement.Level_Offset_Ratio)) then
						return stopAtFloor(module.statValues.Destination, park)
					end

					local carMovementDirection = select(2, moveElevator(dtTime))
					if ((carMovementDirection == 1 and level.Position.Y >= topFloor.level.Position.Y+1.5) or (carMovementDirection == -1 and level.Position.Y <= bottomFloor.level.Position.Y-1.5)) then
						safetyBraking = false
						safetyBrake()
					end
					dtTime = heartbeat:Wait()
				end
			end)
		end)
		if (not ran) then return { ['RUN_STATUS'] = false, ['RUN_CODE'] = 'RUNTIME_ERROR', ['MESSAGE'] = res } end
		return { ['RUN_STATUS'] = true, ['RUN_CODE'] = 'RUNTIME_SUCCESS' }
	end

	-- // Relevel // --
	function relevel(floor, tolerance)
		if (not isElevatorSafe()) then return end

		if (typeof(tolerance) ~= 'number') then tolerance = 0 end
		local registeredFloor = findRegisteredFloor(floor)
		if (not registeredFloor) then return end
		if (releveling) then return end

		elevatorRelevelThread = task.spawn(function()
			local levelOffset = (registeredFloor.level.Position.Y-level.Position.Y)
			local directionToTravelTo = levelOffset < 0 and -1 or levelOffset > 0 and 1 or 0

			releveling = true
			module.statValues.Leveling = true
			task.spawn(updateStatValues)

			if (math.abs(levelOffset) <= tolerance) then
				for i, v in pairs(module.doorData) do
					task.spawn(runDoorOpen, module.statValues.Raw_Floor, v.side, 'Open_No_Call')
				end
				return
			end

			module.statValues.Move_Value = directionToTravelTo
			module.statValues.Move_Direction = directionToTravelTo
			moveLock = true
			task.spawn(updateStatValues)

			local dtTime = 0

			local lvlOffset = configFile.Sensors[directionToTravelTo == 1 and 'Up_Level_Offset' or directionToTravelTo == -1 and 'Down_Level_Offset']

			while true do
				local thisLevelOffset = (registeredFloor.level.Position.Y-level.Position.Y)
				local currentDirTravel = thisLevelOffset < 0 and -1 or thisLevelOffset > 0 and 1 or 0
				module.statValues.Current_Speed = math.min(configFile.Movement.Travel_Speed, module.statValues.Current_Speed+configFile.Movement[currentDirTravel == 1 and 'Acceleration' or 'Down_Acceleration'])
				local distanceToFloor = module.statValues.Move_Value*thisLevelOffset
				if (distanceToFloor <= lvlOffset*(module.statValues.Current_Speed*configFile.Movement.Level_Offset_Ratio)) then
					return stopAtFloor(floor, false)
				end
				moveElevator(dtTime)
				dtTime = heartbeat:Wait()
			end
		end)
	end

	-- // Fire Recall // --
	local allFireRecallEventListeners = {}

	function fireRecall(bool, recallFloor)
		local regFloor = findRegisteredFloor(recallFloor)
		if (not regFloor) then return end

		module.statValues.Phase_1 = bool
		task.spawn(updateStatValues)

		--outputElevMessage(`Elevator has been placed {bool and 'into' or 'out of'} fire service to floor {floor}`, 'warning')

		if (bool and not module.statValues.Fire_Service) then
			fireServiceRecallFloor = recallFloor
			module.statValues.Fire_Recall = true
			module.statValues.Fire_Service = true

			playVoiceSequenceProtocolWithQueue(voiceConfig.Settings.Other_Announcements.Fire_Recall_Announcement.Sequence, false, voiceConfig.Settings.Other_Announcements.Fire_Recall_Announcement.Enabled)

			local function handleDoors()
				if (checkDoorStates('Open', {dontRequireAll = true, onlyPresentDoors = false})) then
					module.sounds.Nudge_Buzzer.Playing = false
					module.statValues.Fire_Recall = false
					task.spawn(updateStatValues)
					return
				end

				for i, doorData in pairs(module.doorData) do
					if (not regFloor.floorInstance:FindFirstChild(`{doorData.side == '' and '' or `{doorData.side}_`}Doors`)) then continue end
					if (doorData.state ~= 'Open') then
						local connection: RBXScriptConnection
						connection = doorData.Opened:Connect(function()
							connection:Disconnect()
							if (not checkDoorStates('Open', {dontRequireAll = true, onlyPresentDoors = false})) then return end
							module.sounds.Nudge_Buzzer.Playing = false
							module.statValues.Fire_Recall = false
							task.spawn(updateStatValues)
						end)
						table.insert(allFireRecallEventListeners, connection)
					end
				end
			end

			module.statValues.Queue_Direction = 0
			task.spawn(updateStatValues)

			module.sounds.Nudge_Buzzer.Playing = true
			removeAllCalls()

			local isOnFloor = module.statValues.Raw_Floor == recallFloor and (module.statValues.Move_Value == 0 or module.statValues.Leveling)
			if (not isOnFloor) then -- // Not on floor, elevator must stop at nearest floor
				local direction = module.statValues.Move_Value
				local nearFloor, nearDist = nil, math.huge
				for _, floor in pairs(module.registeredFloors) do
					local thisDist = math.abs(floor.floorInstance.Level.Position.Y - level.Position.Y)
					if (thisDist < nearDist and ((direction == 1 and floor.floorNumber > module.statValues.Raw_Floor) or (direction == -1 and floor.floorNumber < module.statValues.Raw_Floor))) then
						nearDist = thisDist
						nearFloor = floor
					end
				end

				if (nearFloor and module.statValues.Move_Value ~= 0) then
					addCall({call = nearFloor.floorNumber, direction = nil, fireBypass = true})
				end

				if module.statValues.Move_Value == 0 or module.statValues.Leveling then
					task.spawn(runDoorClose, module.statValues.Raw_Floor, 'all', true)
					addCall({call = recallFloor, direction = nil, fireBypass = true})
				end

				local connection: RBXScriptConnection
				connection = api.Event:Connect(function(protocol, params)
					if (protocol == 'onElevatorStop') then
						if (module.statValues.Raw_Floor ~= recallFloor) then
							addCall({call = recallFloor, direction = nil, fireBypass = true})
						else
							connection:Disconnect()
							handleDoors()
						end
					end
				end)
				table.insert(allFireRecallEventListeners, connection)
			else
				task.spawn(runDoorOpen, recallFloor, 'all', 'Open_No_Call', true)
				handleDoors()
			end
		elseif (not bool and module.statValues.Fire_Service) then
			module.statValues.Fire_Recall = false
			module.statValues.Fire_Service = false
			for i, v in pairs(allFireRecallEventListeners) do
				v:Disconnect()
			end
			allFireRecallEventListeners = {}
		end
	end

	-- // Chime & Lantern Handling // --
	function runChime(floor, direction, indexes, cfg, requireCallOnlyParam)
		local regFloor = findRegisteredFloor(floor)
		if ((not regFloor) or (direction ~= 1 and direction ~= -1)) then return end
		for index, value in pairs(indexes) do
			local thisData = cfg[value]
			local thisCall = select(2, findCallInQueue(floor, direction))
			local callOnlyMet = (requireCallOnlyParam and thisData.Call_Only and (thisCall and table.find(thisCall.directions, direction))) or (not thisData.Call_Only) or (not requireCallOnlyParam)
			if ((not thisData) or (not thisData.Enable) or (not callOnlyMet)) then continue end
			local directionStr = direction == 1 and 'Up' or direction == -1 and 'Down' or nil

			local lanternPart
			for i, v in pairs((value == 'Exterior' and regFloor.floorInstance or car):GetChildren()) do
				if (v.Name ~= 'Lanterns') then continue end
				for _, l in pairs(v:GetChildren()) do
					if (l.Name ~= directionStr and l.Name ~= 'Both') then continue end
					for _, v in pairs(l:GetDescendants()) do
						if ((not v:IsA('BasePart')) or v.Name ~= 'Light') then continue end
						lanternPart = v
						break
					end
				end
				if ((not lanternPart) or lanternPart:GetAttribute('Is_Chiming')) then continue end
				lanternPart:SetAttribute('Is_Chiming', true)
				task.delay(thisData.Delay, addPlayingSound, lanternPart, module.sounds[`{value}_{directionStr}_Chime`], math.random(-10,10)/6000)
			end

		end
	end

	-- // Lantern handling // --
	function doLanterns(floor, direction, indexes, cfg, requireCallOnlyParam)
		local regFloor = findRegisteredFloor(floor)
		if ((not regFloor) or (direction ~= 1 and direction ~= -1)) then return end
		for index, value in pairs(indexes) do
			local thisData = cfg[value]
			local thisCall = select(2, findCallInQueue(floor, direction))
			local callOnlyMet = (requireCallOnlyParam and thisData.Call_Only and (thisCall and table.find(thisCall.directions, direction))) or (not thisData.Call_Only) or (not requireCallOnlyParam)
			if ((not thisData) or (not thisData.Enable) or (not callOnlyMet)) then continue end
			local directionStr = direction == 1 and 'Up' or direction == -1 and 'Down' or nil
			local lanternCfgOut = configFile.Color_Database.Lanterns[value]
			local lanternCfg = lanternCfgOut[directionStr]

			task.delay(thisData.Delay, function()
				api:Fire('onElevatorLanternApi', {
					['state'] = 'active',
					['floor'] = floor,
					['direction'] = string.sub(directionStr, 1, 1),
					['type'] = string.lower(value),
					['eventData'] = thisData,
					['conditionMet'] = callOnlyMet
				})
				for i, v in pairs((value == 'Exterior' and regFloor.floorInstance or car):GetChildren()) do
					if (v.Name ~= 'Lanterns') then continue end
					for _, l in pairs(v:GetChildren()) do
						if (l.Name ~= directionStr and l.Name ~= 'Both') then continue end
						for _, v in pairs(l:GetDescendants()) do
							if ((not v:IsA('BasePart')) or v.Name ~= 'Light') then continue end
							v.Color = lanternCfg.Lit_State.Color
							v.Material = lanternCfg.Lit_State.Material
							for i, l in pairs(v:GetDescendants()) do
								if (not string.match(l.ClassName, 'Light')) then continue end
								l.Enabled = true
							end

							if ((not lanternCfgOut.Repeat_Data.Enable) or (not table.find(lanternCfgOut.Repeat_Data.Allowed_Directions, string.sub(directionStr, 1, 1))) or v:GetAttribute('Active')) then continue end

							v:SetAttribute('Active', true)
							task.spawn(function()
								for i = 1, lanternCfgOut.Repeat_Data.Times do
									task.wait(lanternCfgOut.Repeat_Data.Delay)
									v.Color = lanternCfg.Neautral_State.Color
									v.Material = lanternCfg.Neautral_State.Material
									for i, l in pairs(v:GetDescendants()) do
										if (not string.match(l.ClassName, 'Light')) then continue end
										l.Enabled = false
									end

									task.wait(lanternCfgOut.Repeat_Data.Delay)
									if not v:GetAttribute('Active') then break end

									v.Color = lanternCfg.Lit_State.Color
									v.Material = lanternCfg.Lit_State.Material
									for i, l in pairs(v:GetDescendants()) do
										if (not string.match(l.ClassName, 'Light')) then continue end
										l.Enabled = true
									end
								end
							end)
						end
					end
				end
			end)

		end
	end

	function resetLanterns(floor, direction, indexes)
		local regFloor = findRegisteredFloor(floor)
		if ((not regFloor) or (direction ~= 1 and direction ~= -1)) then return end
		for index, value in pairs(indexes) do
			local directionStr = direction == 1 and 'Up' or direction == -1 and 'Down' or nil
			local lanternCfgOut = configFile.Color_Database.Lanterns[value]
			local lanternCfg = lanternCfgOut[directionStr]

			task.delay(configFile.Color_Database.Lanterns[value].Lantern_Reset_Delay, function()
				api:Fire('onElevatorLanternApi', {
					['state'] = 'neutral',
					['floor'] = floor,
					['direction'] = string.sub(directionStr, 1, 1),
					['type'] = string.lower(value)
				})

				for i, v in pairs((value == 'Exterior' and regFloor.floorInstance or car):GetChildren()) do
					if (v.Name ~= 'Lanterns') then continue end
					for _, l in pairs(v:GetChildren()) do
						if (l.Name ~= directionStr and l.Name ~= 'Both') then continue end
						for _, v in pairs(l:GetDescendants()) do
							if ((not v:IsA('BasePart')) or v.Name ~= 'Light') then continue end
							v.Color = lanternCfg.Neautral_State.Color
							v.Material = lanternCfg.Neautral_State.Material
							for i, l in pairs(v:GetDescendants()) do
								if (not string.match(l.ClassName, 'Light')) then continue end
								l.Enabled = false
							end
							v:SetAttribute('Active', false)
							v:SetAttribute('Is_Chiming', false)
						end
					end
				end
			end)

		end
	end

	for i, v in pairs(module.registeredFloors) do
		resetLanterns(v.floorNumber, 1, {'Exterior'})
		resetLanterns(v.floorNumber, -1, {'Exterior'})
	end
	resetLanterns(module.statValues.Raw_Floor, 1, {'Interior'})
	resetLanterns(module.statValues.Raw_Floor, -1, {'Interior'})

	-- // Button handling // --
	function setButton(button, config, state, from)
		local cfg = config[state]
		if (not cfg) then return end
		for i, v in pairs(from:GetDescendants()) do
			if (v.Name ~= button.Name) then continue end
			for _, led in pairs(v:GetDescendants()) do
				if ((not led:IsA('BasePart')) or led.Name ~= 'Light') then continue end
				led.Color = cfg.Color
				led.Material = cfg.Material
			end
		end
	end

	for _, button in pairs(elevator:GetDescendants()) do
		if (not button:FindFirstChild('Button')) then continue end
		button.Button:SetAttribute('isACortexElevButton', true)
		local buttonFloor = tonumber(string.split(button.Name, '_')[2]) or tonumber(string.split(button.Name, 'Floor')[2])
		if (buttonFloor) then
			setButton(button, configFile.Color_Database.Car.Floor_Button, 'Neautral_State', car)
		elseif (string.match(button.Name, 'DoorOpen') or string.match(button.Name, 'Door_Open')) then
			setButton(button, configFile.Color_Database.Car.Doors.Open, 'Neutral', car)
		elseif (string.match(button.Name, 'DoorClose') or string.match(button.Name, 'Door_Close')) then
			setButton(button, configFile.Color_Database.Car.Doors.Close, 'Neutral', car)
		elseif (button.Name == 'DoorHold' or button.Name == 'Door_Hold') then
			setButton(button, configFile.Color_Database.Car.Doors.Hold, 'Neautral_State', car)
		elseif (button.Name == 'Alarm') then
			setButton(button, configFile.Color_Database.Car.Alarm_Button, 'Neautral_State', car)
		elseif (button.Name == 'CallCancel' or button.Name == 'Call_Cancel') then
			setButton(button, configFile.Color_Database.Car.Floor_Button, 'Neautral_State', car)
		end
	end

	for i,v in pairs(module.registeredFloors) do
		for _, f in pairs(v.floorInstance:GetChildren()) do
			if (f.Name ~= 'Call_Buttons') then continue end
			for _, b in pairs(f:GetDescendants()) do
				local buttonName = string.split(b.Name, '_')[1]
				if (buttonName ~= 'Up' and buttonName ~= 'Down') then continue end
				setButton(b, configFile.Color_Database.Floor[buttonName], 'Neautral_State', b.Parent)
			end
		end
	end

	-- // Welding inspection control buttons // --
	for i,v in pairs(elevator:GetDescendants()) do
		if (v.Name ~= 'Inspection_Controls') then continue end
		for i, button in pairs(v:GetDescendants()) do
			if (button.Name ~= 'Up' and button.Name ~= 'Down' and button.Name ~= 'Stop' and button.Name ~= 'Inspection_Switch' and button.Name ~= 'Common' and button.Name ~= 'Enable' and button.Name ~= 'Alarm') then continue end
			if (button:IsA('BasePart')) then
				local model = Instance.new('Model')
				model.Name = button.Name
				model.Parent = button.Parent
				button.Name = 'Button'
				button.Parent = model
				button = model
			end
			local buttonPart
			for i, v in pairs(button:GetDescendants()) do
				if ((not v:IsA('BasePart')) or v.Name ~= 'Button') then continue end
				buttonPart = v
			end
			if (not buttonPart) then continue end

			buttonPart:SetAttribute('isACortexElevButton', true)
			for i, weld in pairs(carWeldsFolder:GetChildren()) do
				if (weld.Part0:IsDescendantOf(button)) then
					weld:Destroy()
				end
			end
			local buttonAttachment = buttonPart:FindFirstChild('Pressed_Point')
			if (not buttonAttachment) then
				buttonAttachment = Instance.new('Part')
				buttonAttachment.Name = 'Pressed_Point'
				buttonAttachment.CFrame, buttonAttachment.Size = if (button.Name == 'Inspection_Switch') then buttonPart.CFrame*CFrame.Angles(0, 0, math.rad(90)) else if (button.Name == 'Stop') then buttonPart.CFrame*CFrame.new(0, -.02, 0) else buttonPart.CFrame*CFrame.new(-.02, 0, 0), buttonPart.Size
				buttonAttachment.Transparency = 1
				buttonAttachment.CanCollide = false
				buttonAttachment.CanTouch = false
				buttonAttachment.CanQuery = false
				buttonAttachment.Parent = buttonPart

				local animWeld = weldParts(buttonAttachment, buttonAttachment, buttonPart, false, false)
				animWeld.Name = 'Button_Weld'
				animWeld:SetAttribute('down', animWeld.C1)
				animWeld:SetAttribute('up', animWeld.C0)
				weldModel(button, buttonPart, {buttonAttachment})
				weldParts(buttonAttachment, buttonAttachment, platform, true, false)
			end
		end
	end

	local function isButtonALockedFloor(tablePath, buttonFloor, buttonSide)
		for i, v in pairs(tablePath) do
			if (buttonSide and ((i == `{buttonFloor}_{buttonSide}` or i == buttonFloor) and v == true) or (not buttonSide and (string.split(i, '_')[1] == buttonFloor and v == true))) then
				return true
			end
		end

		return false
	end

	--local function isAllLockedFloorCallsInQueue(tablePath, floor, queue) -- WIP do not use
	--	for i, v in pairs(tablePath) do
	--		if string.split(i, "_")[1] == floor and not table.find(queue.sides, `0_{string.split(i, "_")[2]}`) then
	--			print("not all in queue")
	--			return false
	--		end
	--	end
	--end

	local lastButtonPressedtick = tick()

	local function btnDelay(button: any, duration: number, callback: any, bypassCheckInRecurse: boolean?)
		if (button:GetAttribute('litDelayCooldown') and bypassCheckInRecurse == false) then return end
		button:SetAttribute('litDelayCooldown', true) -- Prevents multiple loops from running per button
		task.delay(duration, function()
			if ((tick()-lastButtonPressedtick)/duration < 1) then return btnDelay(button, duration, callback, true) end
			if (typeof(callback) == 'function') then callback() end
			button:SetAttribute('litDelayCooldown', false)
		end)
	end

	local function handleButtonInput(user, protocol, params)
		if (protocol ~= 'onButtonPressed' and protocol ~= 'onButtonReleased') then return end

		local button = params.button
		if (not button) then return end

		local buttonPart = button:FindFirstChild('Button')
		if (not buttonPart) then return end

		if (protocol == 'onButtonPressed') then
			addPlayingSound(buttonPart, buttonPart:IsDescendantOf(car) and module.sounds.Button_Beep or module.sounds.Call_Button_Beep)
		end

		local buttonFloor = tonumber(string.split(button.Name, '_')[1] == 'Floor' and string.split(button.Name, '_')[2]) or tonumber(string.split(button.Name, 'Floor')[2])
		local buttonSide = string.split(button.Name, '_')[3]

		if (buttonFloor) then -- Car Floor buttons
			local isOnFloor = (buttonFloor == module.statValues.Raw_Floor and (module.statValues.Move_Value == 0 or module.statValues.Leveling))
			local callQueue = findCallInQueue(buttonFloor) and select(2, findCallInQueue(buttonFloor))
			local callFound = callQueue and (buttonSide and table.find(callQueue.sides, `0_{buttonSide}`) or (not buttonSide and callQueue)) -- This works but non floor side buttons will light up but wont open all doors due to the way the queue system is scripted, this will be improved soon.
			local lockResetStatement = (isButtonALockedFloor(module.lockedCalls.car, tostring(buttonFloor), buttonSide) and not checkFireServicePhase2() and not callFound --[[findCallInQueue(buttonFloor)]])
			local resetStatement = (lockResetStatement or (not findRegisteredFloor(buttonFloor)) or (module.statValues.Fire_Service and not module.statValues.Phase_2) or module.statValues.Fire_Recall or module.statValues.Inspection or module.statValues.Stop or module.statValues.Out_Of_Service)


			if (protocol == 'onButtonPressed') then
				lastButtonPressedtick = tick()
				setButton(button, configFile.Color_Database.Car.Floor_Button, 'Lit_State', car)
				if (resetStatement) then return end

				if (isOnFloor) then
					task.spawn(runDoorOpen, module.statValues.Raw_Floor, buttonSide or 'all', 'Open_No_Call')
				else
					local newCallAdded = addCall({call = buttonFloor, side = buttonSide, isCarCall = true})
					if ((not newCallAdded) or moveLock) then return end
					task.spawn(runChime, buttonFloor, module.statValues.Queue_Direction, {'Exterior', 'Interior'}, configFile.Sound_Database.Chime_Events.New_Call_Input)
					task.spawn(doLanterns, buttonFloor, module.statValues.Queue_Direction, {'Exterior', 'Interior'}, configFile.Color_Database.Lanterns.Active_On_Call_Enter)
				end
			elseif (resetStatement or isOnFloor) then
				btnDelay(button, configFile.Color_Database.Car.Lit_Delay, function() setButton(button, configFile.Color_Database.Car.Floor_Button, 'Neautral_State', car) end, false)
			end
		elseif (string.match(button.Name, 'DoorOpen') or string.match(button.Name, 'Door_Open')) then -- Door Open buttons
			local side = (string.split(button.Name, 'DoorOpen')[2] and string.split(button.Name, 'DoorOpen')[1]) or (string.split(button.Name, '_Door_Open')[2] and string.split(button.Name, '_Door_Open')[1])
			if button.Name == 'Door_Open' then side = '' end
			if (not side) then return end
			side = string.split(side, '_')[1]
			if (not side) then return end
			local rawSide = side
			if (side == '') then side = 'Front' end

			local doorData = module.doorData[side]

			local Disable_Door_Open_On_Locked_Floor = configFile.Locking.Disable_Door_Open_On_Locked_Floor

			local function checkLockedStatement(doorSide)
				local doorSideData = module.doorData[doorSide]
				return (Disable_Door_Open_On_Locked_Floor.Car.When_Doors_Closing and button:IsDescendantOf(car) and (module.lockedCalls.car[tostring(module.statValues.Raw_Floor)] or module.lockedCalls.car[`{module.statValues.Raw_Floor}_{doorSide}`]) and not checkFireServicePhase2() and doorSideData.state == 'Closing')
					or (Disable_Door_Open_On_Locked_Floor.Car.When_Doors_Closed and button:IsDescendantOf(car) and (module.lockedCalls.car[tostring(module.statValues.Raw_Floor)] or module.lockedCalls.car[`{module.statValues.Raw_Floor}_{doorSide}`]) and not checkFireServicePhase2() and doorSideData.state == 'Closed')
					or (Disable_Door_Open_On_Locked_Floor.Hall.When_Doors_Closing and button:IsDescendantOf(floors) and ((module.lockedCalls.hall.up[tostring(module.statValues.Raw_Floor)] or module.lockedCalls.hall.up[`{module.statValues.Raw_Floor}_{doorSide}`]) and (module.lockedCalls.hall.down[tostring(module.statValues.Raw_Floor)] or module.lockedCalls.hall.down[`{module.statValues.Raw_Floor}_{doorSide}`])) and doorSideData.state == 'Closing')
					or (Disable_Door_Open_On_Locked_Floor.Hall.When_Doors_Closed and button:IsDescendantOf(floors) and ((module.lockedCalls.hall.up[tostring(module.statValues.Raw_Floor)] or module.lockedCalls.hall.up[`{module.statValues.Raw_Floor}_{doorSide}`]) and (module.lockedCalls.hall.down[tostring(module.statValues.Raw_Floor)] or module.lockedCalls.hall.down[`{module.statValues.Raw_Floor}_{doorSide}`])) and doorSideData.state == 'Closed')
			end

			--local lockResetStatement = (
			--	(Disable_Door_Open_On_Locked_Floor.Car.When_Doors_Closing and button:IsDescendantOf(car) and (module.lockedCalls.car[tostring(module.statValues.Raw_Floor)] or module.lockedCalls.car[`{module.statValues.Raw_Floor}_{side}`]) and not checkFireServicePhase2() and doorData.state == 'Closing')
			--		or (Disable_Door_Open_On_Locked_Floor.Car.When_Doors_Closed and button:IsDescendantOf(car) and (module.lockedCalls.car[tostring(module.statValues.Raw_Floor)] or module.lockedCalls.car[`{module.statValues.Raw_Floor}_{side}`]) and not checkFireServicePhase2() and doorData.state == 'Closed')
			--		or (Disable_Door_Open_On_Locked_Floor.Hall.When_Doors_Closing and button:IsDescendantOf(floors) and ((module.lockedCalls.hall.up[tostring(module.statValues.Raw_Floor)] or module.lockedCalls.hall.up[`{module.statValues.Raw_Floor}_{side}`]) and (module.lockedCalls.hall.down[tostring(module.statValues.Raw_Floor)] or module.lockedCalls.hall.down[`{module.statValues.Raw_Floor}_{side}`])) and doorData.state == 'Closing')
			--		or (Disable_Door_Open_On_Locked_Floor.Hall.When_Doors_Closed and button:IsDescendantOf(floors) and ((module.lockedCalls.hall.up[tostring(module.statValues.Raw_Floor)] or module.lockedCalls.hall.up[`{module.statValues.Raw_Floor}_{side}`]) and (module.lockedCalls.hall.down[tostring(module.statValues.Raw_Floor)] or module.lockedCalls.hall.down[`{module.statValues.Raw_Floor}_{side}`])) and doorData.state == 'Closed')
			--)
			local resetStatement = (module.statValues.Inspection or module.statValues.Stop or module.statValues.Out_Of_Service)

			if (protocol == 'onButtonPressed') then
				lastButtonPressedtick = tick()
				setButton(button, configFile.Color_Database.Car.Doors.Open, 'Active', car)
				if resetStatement then return end

				doorData.buttonHold = true
				if rawSide == '' then
					for _, v in pairs(module.doorData) do
						if checkLockedStatement(v.side) then continue end
						task.spawn(runDoorOpen, module.statValues.Raw_Floor, v.side, 'Open_No_Call')
					end
				else
					if checkLockedStatement(side) then return end
					task.spawn(runDoorOpen, module.statValues.Raw_Floor, side, 'Open_No_Call')
				end
			else
				doorData.buttonHold = false
				btnDelay(button, configFile.Color_Database.Car.Lit_Delay, function() setButton(button, configFile.Color_Database.Car.Doors.Open, 'Neutral', car) end, false)
				if (checkFireServicePhase2() and doorData.state == 'Opening') then
					task.spawn(runDoorClose, module.statValues.Raw_Floor, side)
				end
			end
		elseif (string.match(button.Name, 'DoorClose') or string.match(button.Name, 'Door_Close')) then -- Door Close buttons
			local side = (string.split(button.Name, 'DoorClose')[2] and string.split(button.Name, 'DoorClose')[1]) or (string.split(button.Name, '_Door_Close')[2] and string.split(button.Name, '_Door_Close')[1])
			if button.Name == 'Door_Close' then side = '' end
			if (not side) then return end
			side = string.split(side, '_')[1]
			if (not side) then return end
			local rawSide = side
			if (side == '') then side = 'Front' end
			local doorData = module.doorData[side]

			local resetStatement = (module.statValues.Inspection or module.statValues.Stop or module.statValues.Out_Of_Service or (module.statValues.Fire_Service and not checkFireServicePhase2()))
			if (protocol == 'onButtonPressed') then
				lastButtonPressedtick = tick()
				setButton(button, configFile.Color_Database.Car.Doors.Close, 'Active', car)
				if resetStatement then return end
				if rawSide == '' then
					for _, v in pairs(module.doorData) do
						task.spawn(runDoorClose, module.statValues.Raw_Floor, v.side)
					end
				else
					task.spawn(runDoorClose, module.statValues.Raw_Floor, side)
				end
			else
				btnDelay(button, configFile.Color_Database.Car.Lit_Delay, function() setButton(button, configFile.Color_Database.Car.Doors.Close, 'Neutral', car) end, false)
				if ((checkIndependentService() or checkFireServicePhase2())) then
					if side == '' then
						for _, v in pairs(module.doorData) do
							if v.state == 'Closing' then
								task.spawn(runDoorOpen, module.statValues.Raw_Floor, side, 'Open_No_Call')
							end
						end
					else
						if doorData.state == 'Closing' then
							task.spawn(runDoorOpen, module.statValues.Raw_Floor, side, 'Open_No_Call')
						end
					end
				end
			end
		elseif (button.Name == 'Alarm') then
			if (protocol == 'onButtonPressed') then
				lastButtonPressedtick = tick()
				setButton(button, configFile.Color_Database.Car.Alarm_Button, 'Lit_State', car)
				module.sounds.Alarm.Playing = true
			else
				setButton(button, configFile.Color_Database.Car.Alarm_Button, 'Neautral_State', car)
				module.sounds.Alarm.Playing = false
			end
		elseif (button.Name == 'CallCancel' or button.Name == 'Call_Cancel') then
			if (checkIndependentService() or checkFireServicePhase2()) then
				removeAllCalls()
				if (module.statValues.Move_Value ~= 0) then
					removeCall(module.statValues.Raw_Floor)
				end
			end
		end

		if (button:IsDescendantOf(floors)) then -- Hall Call buttons
			local buttonFloor = tonumber(string.split(button.Parent.Parent.Name, '_')[2]) or tonumber(string.split(button.Parent.Parent.Name, 'Floor')[2])
			local buttonName = string.split(button.Name, '_')[1]
			local buttonDirection = string.sub(buttonName, 1, 1)
			local buttonSide = string.split(button.Name, '_')[2]

			if (not buttonFloor or (buttonDirection ~= 'U' and buttonDirection ~= 'D')) then return end

			buttonDirection = buttonDirection == 'U' and 1 or buttonDirection == 'D' and -1 or nil
			local isOnFloor = (buttonFloor == module.statValues.Raw_Floor and (module.statValues.Move_Value == 0 or module.statValues.Leveling) and (module.statValues.Queue_Direction == buttonDirection or module.statValues.Queue_Direction == 0))
			local lockResetStatement = isButtonALockedFloor(module.lockedCalls.hall[string.lower(buttonName)], tostring(buttonFloor), buttonSide) --[[module.lockedCalls.hall[string.lower(buttonName)][tostring(buttonFloor)]] and (not findCallInQueue(buttonFloor, buttonDirection))
			local resetStatement = (lockResetStatement or module.statValues.Fire_Service or module.statValues.Independent_Service or module.statValues.Inspection or module.statValues.Stop or module.statValues.Out_Of_Service)
			if (protocol == 'onButtonPressed') then
				lastButtonPressedtick = tick()
				setButton(button, configFile.Color_Database.Floor[buttonName], 'Lit_State', button.Parent)
				if (resetStatement) then return end
				if (isOnFloor) then
					task.spawn(runChime, buttonFloor, buttonDirection, {'Exterior', 'Interior'}, configFile.Sound_Database.Chime_Events.Exterior_Call_Only)
					task.spawn(doLanterns, buttonFloor, buttonDirection, {'Exterior', 'Interior'}, configFile.Color_Database.Lanterns.Active_On_Exterior_Call)
					for _, v in pairs(module.doorData) do
						if (not v:IsValid(module.statValues.Raw_Floor)) then continue end
						if buttonSide and buttonSide ~= v.side then continue end

						v.buttonHold = true
						if (module.statValues.Queue_Direction == 0) then
							module.statValues.Queue_Direction = buttonDirection
							task.spawn(updateStatValues)
						end

						task.spawn(runDoorOpen, module.statValues.Raw_Floor, v.side, 'Open_By_Call')
					end
				else
					local newCallAdded = addCall({call = buttonFloor, side = buttonSide, direction = buttonDirection})
				end
			elseif (resetStatement or isOnFloor) then
				for _, v in pairs(module.doorData) do
					if (not v:IsValid(module.statValues.Raw_Floor)) then continue end
					v.buttonHold = false
				end
				btnDelay(button, configFile.Color_Database.Floor.Active_Duration, function() setButton(button, configFile.Color_Database.Floor[buttonName], 'Neautral_State', button.Parent) end, false)
			end
		elseif (button:FindFirstAncestor('Inspection_Controls')) then
			if (inspectionLocked) then return end
			if (button.Name == 'Stop') then
				if (protocol == 'onButtonPressed') then
					local animWeld = buttonPart:FindFirstChild('Button_Weld', true)
					if (not animWeld) then return end
					tweenService:Create(animWeld, TweenInfo.new(.05, Enum.EasingStyle.Linear), {C0 = module.statValues.Stop and animWeld:GetAttribute('up') or animWeld:GetAttribute('down')}):Play()
					api:Fire('Stop', not module.statValues.Stop)
				end
			elseif (button.Name == 'Inspection_Switch') then
				if (protocol == 'onButtonPressed') then
					local animWeld = buttonPart:FindFirstChild('Button_Weld', true)
					if (not animWeld) then return end
					tweenService:Create(animWeld, TweenInfo.new(.15, Enum.EasingStyle.Linear), {C0 = module.statValues.Inspection and animWeld:GetAttribute('up') or animWeld:GetAttribute('down')}):Play()
					api:Fire('Inspection_Service', not module.statValues.Inspection)
				end
			elseif (button.Name == 'Alarm') then
				local animWeld = buttonPart:FindFirstChild('Button_Weld', true)
				if (not animWeld) then return end
				tweenService:Create(animWeld, TweenInfo.new(.05, Enum.EasingStyle.Linear), {C0 = protocol == 'onButtonPressed' and animWeld:GetAttribute('down') or animWeld:GetAttribute('up')}):Play()
				module.sounds.Alarm.Playing = protocol == 'onButtonPressed'
			elseif (button.Name == 'Enable' or button.Name == 'Common') then
				if (protocol == 'onButtonPressed') then
					local animWeld = buttonPart:FindFirstChild('Button_Weld', true)
					if (not animWeld) then return end
					inspectionEnabled = not inspectionEnabled
					tweenService:Create(animWeld, TweenInfo.new(.05, Enum.EasingStyle.Linear), {C0 = inspectionEnabled and animWeld:GetAttribute('down') or animWeld:GetAttribute('up')}):Play()
				end
			elseif (button.Name == 'Up' or button.Name == 'Down') then
				local animWeld = buttonPart:FindFirstChild('Button_Weld', true)
				if (not animWeld) then return end
				tweenService:Create(animWeld, TweenInfo.new(.05, Enum.EasingStyle.Linear), {C0 = protocol == 'onButtonPressed' and animWeld:GetAttribute('down') or animWeld:GetAttribute('up')}):Play()
				if (protocol == 'onButtonPressed') then
					api:Fire('Inspection_Service_Move', { ['direction'] = string.sub(button.Name, 1, 1), ['maxSpeed'] = configFile.Movement.Inspection_Config.Max_Speed })
				else
					api:Fire('Inspection_Service_Stop', true)
				end
			end
		end
	end

	local inspectionStopped = signal.new()

	api.Event:Connect(function(protocol, params, ...)
		handleButtonInput(nil, protocol, params)

		if (protocol == 'Add_Call' or protocol == 'Request_Call_F' or protocol == 'Add_Hall_Call' or protocol == 'addHallCall') then
			local call = typeof(params) == 'table' and (tonumber(params.call) or tonumber(params.floor)) or (typeof(params) == 'number') and params or nil
			if (not call) then return end
			--if params.floor and not params.call then params.call = params.floor end -- Legacy API support
			local direction = typeof(params) == 'table' and (if (typeof(params.direction) == 'string') then params.direction == 'U' and 1 or params.direction == 'D' and -1 or 0 else params.direction) or if (typeof(... and select(1, ...)) == 'number') then ... and select(1, ...) else nil

			local isOnFloor = (call == module.statValues.Raw_Floor and (module.statValues.Move_Value == 0 or module.statValues.Leveling) and (module.statValues.Queue_Direction == direction or module.statValues.Queue_Direction == 0 or (not direction)))
			if (isOnFloor) then
				task.spawn(runChime, call, direction, {'Exterior', 'Interior'}, configFile.Sound_Database.Chime_Events.Exterior_Call_Only)
				task.spawn(doLanterns, call, direction, {'Exterior', 'Interior'}, configFile.Color_Database.Lanterns.Active_On_Exterior_Call)

				task.spawn(runDoorOpen, module.statValues.Raw_Floor, typeof(params) == 'table' and params.side or 'all', 'Open_By_Call')
				module.statValues.Queue_Direction = direction or call > module.statValues.Raw_Floor and 1 or call < module.statValues.Raw_Floor and -1 or 0
				task.spawn(updateStatValues)
				api:Fire('onCallRespond', { floor = module.statValues.Raw_Floor, direction = module.statValues.Queue_Direction == 1 and 'U' or module.statValues.Queue_Direction == -1 and 'D' or 'N' })
			else
				addCall({call = call, direction = direction, side = typeof(params) == 'table' and params.side, isCarCall = typeof(params) == 'table' and params.isCarCall or (not direction)})
				if (typeof(params) == 'table' and params.activateCarButtons == true) then
					local carButton = car:FindFirstChild('Buttons') and (car.Buttons:FindFirstChild(`Floor{call}`) or car.Buttons:FindFirstChild(`Floor_{call}`))
					if (not carButton) then return end
					setButton(carButton, configFile.Color_Database.Car.Floor_Button, 'Lit_State', car)
				end
			end
		elseif (protocol == 'Independent_Service' or protocol == 'invokeIndependentService' or protocol == 'invokeIS') then
			setIndependentService(params)
		elseif (protocol == 'Fire_Recall' or protocol == 'Fire_Service_Phase_1') then
			if (typeof(params) ~= 'table') then
				params = {
					floor = ... and select(1, ...),
					enable = params
				}
			end
			fireRecall(params.enable, params.floor)
		elseif (protocol == 'Phase_2' or protocol == 'Fire_Service_Phase_2') then
			--outputElevMessage(`{module.MODULE_STORAGE.statValues.phase1}, {module.MODULE_STORAGE.statValues.phase2}`, 'debug')
			module.statValues.Phase_2 = params
			task.spawn(updateStatValues)
			if (module.statValues.Fire_Service and not module.statValues.Phase_2) then
				fireRecall(false, fireServiceRecallFloor)
				fireRecall(true, fireServiceRecallFloor)
			end
		elseif (protocol == 'Stop') then
			if (params) then
				removeAllCalls()
				module.statValues.Stop = true
				safetyBraking = false
				for i, v in pairs(module.doorData) do
					if (v.state == 'Opening' or v.state == 'Closing') then
						for _, vl in pairs(v.velocity) do
							v.velocity[_] = 0
						end
						v.state = 'Stopped'
						module.statValues[`{v.sideJoin}Door_State`] = v.state
					end
				end
				task.spawn(updateStatValues)
				safetyBrake()
				playerWeld(false)
				playVoiceSequenceProtocolWithQueue(voiceConfig.Settings.Other_Announcements.Out_Of_Service_Announcement.Sequence, false, voiceConfig.Settings.Other_Announcements.Out_Of_Service_Announcement.Enabled)
			else
				if (not module.statValues.Stop) then return end
				moveLock = false
				module.statValues.Stop = false
				while (safetyBraking) do task.wait() end
				task.spawn(relevel, module.statValues.Raw_Floor, .015)
				task.spawn(updateStatValues)
			end
		elseif (protocol == 'Inspection_Service' or protocol == 'setInspection') then
			if (params) then
				task.spawn(safetyBrake)
				playerWeld(false)
				module.statValues.Inspection = true
				if (not checkDoorStates('Closed', {dontRequireAll = false, onlyPresentDoors = true})) then
					module.statValues.Nudge = true
				end

				for i, v in pairs(module.doorData) do
					if (v.state == 'Closed') then continue end
					v.nudging = true
				end
				playVoiceSequenceProtocolWithQueue(voiceConfig.Settings.Other_Announcements.Inspection_Service_Announcement.Sequence, false, voiceConfig.Settings.Other_Announcements.Inspection_Service_Announcement.Enabled)
			else
				if (not module.statValues.Inspection) then return end
				module.statValues.Inspection = false
				moveLock = false
				while (safetyBraking) do task.wait() end
				task.spawn(relevel, module.statValues.Raw_Floor, .015)
			end
			task.spawn(updateStatValues)
		elseif (protocol == 'Inspection_Service_Lock' or protocol == 'inspectionLock') then
			inspectionLocked = params
		elseif (protocol == 'Inspection_Service_Common') then
			inspectionEnabled = params
		elseif (protocol == 'Inspection_Service_Move') then

			if ((not inspectionEnabled) or (not module.statValues.Inspection)) then return end -- // Inspection is not enabled! Do not run inspection
			local moveDir = params.direction == 'U' and 1 or params.direction == 'D' and -1 or nil

			pcall(task.cancel, inspectionStopThread)
			inspectionMoveThread = task.spawn(function()
				if (inspectionMoving and module.statValues.Move_Value ~= moveDir or inspectionStopping) then
					api:Fire('Inspection_Service_Stop')
					inspectionStopped:Wait()
				end
				if ((moveDir == 1 and level.Position.Y >= topFloor.level.Position.Y+1.5) or (moveDir == -1 and level.Position.Y <= bottomFloor.level.Position.Y-1.5)) then return end

				module.statValues.Move_Value = moveDir
				module.statValues.Move_Direction = moveDir
				updateStatValues()

				inspectionMoving = true

				local initialSpeed = module.statValues.Current_Speed
				local finalSpeed = params.maxSpeed or configFile.Movement.Inspection_Config.Max_Speed
				local duration = coreFunctions.getAccelerationTime(initialSpeed, finalSpeed, configFile.Movement.Inspection_Config.Accceleration_Rate)
				local startTime = os.clock()
				while (inspectionMoving) do
					module.statValues.Current_Speed = coreFunctions.lerp(initialSpeed, finalSpeed, math.min((os.clock()-startTime)/duration, 1))
					updateStatValues()
					local dtTime, carMovementDirection = moveElevator(heartbeat:Wait())
					if ((carMovementDirection == 1 and level.Position.Y >= topFloor.level.Position.Y+1.5) or (carMovementDirection == -1 and level.Position.Y <= bottomFloor.level.Position.Y-1.5)) then
						safetyBraking = false
						safetyBrake()
						playerWeld(false)
					end
				end
			end)

		elseif (protocol == 'Inspection_Service_Stop') then
			if ((not inspectionEnabled) or (not module.statValues.Inspection)) then return end -- // Inspection is not enabled! Do not run inspection
			pcall(task.cancel, inspectionMoveThread)
			inspectionStopThread = task.spawn(function()
				local initialSpeed = module.statValues.Current_Speed
				local duration = coreFunctions.getAccelerationTime(initialSpeed, 0, configFile.Movement.Inspection_Config.Deceleration_Rate)
				local startTime = os.clock()
				inspectionMoving = false
				inspectionStopping = true
				while ((os.clock()-startTime)/duration < 1) do
					module.statValues.Current_Speed = coreFunctions.lerp(initialSpeed, 0, math.min((os.clock()-startTime)/duration, 1))
					updateStatValues()
					moveElevator(heartbeat:Wait())
				end
				module.statValues.Move_Value = 0
				module.statValues.Current_Speed = 0
				updateStatValues()
				inspectionStopping = false
				inspectionStopped:Fire()
			end)

		elseif (protocol == 'Lock_Floors') then
			if (typeof(params) ~= 'table') then return --[[debugWarn(`{event} API :: Paramrters is not of type table`)]] end
			--outputElevMessage(`Elevator floors locked with calls {table.concat(params, ', ')}`, 'debug')
			for _, v in pairs(params) do
				module.lockedCalls.car[tostring(v)] = true
			end
		elseif (protocol == 'Unlock_Floors') then
			if (typeof(params) ~= 'table') then return --[[debugWarn(`{event} API :: Paramrters is not of type table`)]] end
			--outputElevMessage(`Elevator floors unlocked with calls {table.concat(params, ', ')}`, 'debug')
			for _, v in pairs(params) do
				module.lockedCalls.car[tostring(v)] = false
			end
		elseif (protocol == 'Lock_Hall_Floors') then
			--if (typeof(params) ~= 'table') then return debugWarn(`{event} API :: Paramrters is not of type table`) end
			--outputElevMessage(`Elevator floors hall locked with calls {table.concat(params, ', ')}`, 'debug')
			if params['up'] then
				for _, v in pairs(params.up) do
					module.lockedCalls.hall.up[tostring(v)] = true
				end
			end

			if params['down'] then
				for _, v in pairs(params.down) do
					module.lockedCalls.hall.down[tostring(v)] = true
				end
			end

			if not params['up'] and not params['down'] then
				for _, v in pairs(params) do
					if tonumber(v) then
						module.lockedCalls.hall.up[tostring(v)] = true
						module.lockedCalls.hall.down[tostring(v)] = true
					end
				end
			end
		elseif (protocol == 'Unlock_Hall_Floors') then
			--if (typeof(params) ~= 'table') then return debugWarn(`{event} API :: Paramrters is not of type table`) end
			--outputElevMessage(`Elevator floors hall locked with calls {table.concat(params, ', ')}`, 'debug')
			if (params['up']) then
				for _, v in pairs(params.up) do
					module.lockedCalls.hall.up[tostring(v)] = false
				end
			end
			if (params['down']) then
				for _, v in pairs(params.down) do
					module.lockedCalls.hall.down[tostring(v)] = false
				end
			end
			if ((not params['up']) and (not params['down'])) then
				for _, v in pairs(params) do
					if tonumber(v) then
						module.lockedCalls.hall.up[tostring(v)] = false
						module.lockedCalls.hall.down[tostring(v)] = false
					end
				end
			end
		elseif (protocol == 'Door_Open') then
			runDoorOpen(module.statValues.Raw_Floor, typeof(params) == 'table' and params or 'ALL')
		elseif (protocol == 'Door_Close') then
			runDoorClose(module.statValues.Raw_Floor, typeof(params) == 'table' and params or 'ALL')
		elseif (protocol == 'Door_Nudge') then
			runDoorClose(module.statValues.Raw_Floor, typeof(params) == 'table' and params or 'ALL', true)
		elseif (protocol == 'Fire_Button_Event') then
			handleButtonInput(nil, params.protocol, { ['button'] = params.button })
		elseif (protocol == 'Drop_Key_Toggle' or protocol == 'dropKeyToggle') then
			doDropKey(params)
		end
	end)



	remote.OnServerEvent:Connect(function(user, protocol, params)
		handleButtonInput(user, protocol, params)
		if (protocol == 'dropKeyToggle') then
			local isHoldingKey = user.Character and user.Character:FindFirstChild('Drop Key')
			if (not isHoldingKey) then return end
			doDropKey(params)
		elseif (protocol == 'addDropKeyGuiToPlayer') then
			local containsDropKey
			for i,v in pairs(user.Character:GetChildren()) do
				if (v.Name == 'Drop Key' or v:FindFirstChild('Cortex_Drop_Key')) then
					containsDropKey = v
					break
				end
			end
			local isHoldingKey = user.Character and containsDropKey
			if (not isHoldingKey) then return end
			if (user.PlayerGui:FindFirstChild('DOOR_KEY_UI')) then return end
			local doorSet = params
			local thisFloorName = doorSet:IsDescendantOf(floors) and string.split(doorSet.Parent.Name, 'Floor_')[2]
			local landingLevel = doorSet.Parent.Level
			local sideIndex = doorSet.Name:split('Doors')[1]:split('_')[1]
			local fullSideName = (sideIndex == '' and 'Front' or sideIndex)
			local data = module.doorData[sideIndex]
			if (collectionService:HasTag(doorSet, 'IsInUse') or table.find(dropKeyHandlers,user) or (not ((landingLevel:IsDescendantOf(car) and data.state == 'Closed') or ((not landingLevel:IsDescendantOf(car)) and ((data.state == 'Closed' and tonumber(landingLevel.Parent.Name:sub(7)) == module.statValues.Raw_Floor) or tonumber(landingLevel.Parent.Name:sub(7)) ~= module.statValues.Raw_Floor))))) then return end
			table.insert(dropKeyHandlers,user)
			collectionService:AddTag(doorSet, 'IsInUse')
			local boundsCFrame,boundsSize = doorSet:GetBoundingBox()
			local doorBounds = doorSet:FindFirstChild('Door_Bounds')
			if (not doorBounds) then
				doorBounds = Instance.new('Part')
				doorBounds.Name = 'Door_Bounds'
				doorBounds.CFrame,doorBounds.Size = boundsCFrame,boundsSize
				doorBounds.CanCollide = false
				doorBounds.CanTouch = false
				doorBounds.CanQuery = false
				doorBounds.Transparency = 1
				weldParts(doorBounds, doorBounds, landingLevel, true, false)
				doorBounds.Anchored = false
				doorBounds.Parent = doorSet
			end
			local gui = dependencies.DOOR_KEY_UI:Clone()
			gui.DOOR_SET.Value = doorSet
			gui.Adornee = doorBounds
			gui.Enabled = true
			gui.Parent = user.PlayerGui:WaitForChild('DOOR_KEY_UIS')
			collectionService:AddTag(gui,'ACTIVE')
			local function getOrientation(cf)
				return cf:ToOrientation()
			end
			local welds = {}
			for i,v in next,data and (doorSet:IsDescendantOf(car) and car.Door_Engine_Welds:FindFirstChild(sideIndex):GetChildren() or findRegisteredFloor(thisFloorName).floorInstance:FindFirstChild('Door_Engine_Welds'):FindFirstChild(sideIndex):GetChildren()) or {} do
				table.insert(welds, v)
			end
			local function checkIfDoorIsClosed()
				for i,v in pairs(welds) do
					if (v.C0 ~= v:GetAttribute('closedPoint')) then return false end
				end
				return true
			end
			addPlayingSound(landingLevel, addSound(landingLevel, 'Interlock_Click', {
				Sound_Id = 9116323848,
				Volume = 1,
				Pitch = 1.35
			}, false, 40, 3))
			for i,v in pairs(module.doorData) do
				v.nudging = false
			end
			module.statValues.Nudge = false
			task.spawn(updateStatValues)
			local val = gui:WaitForChild('RATIO')
			local hasStopped = false
			local lastChecked = checkIfDoorIsClosed()
			api:Fire('onElevDoorKey',{doorSet=doorSet,status='insert'})

			local update: RBXScriptConnection
			update = heartbeat:Connect(function(dtTime)
				local value = val.Value
				for i,weld in pairs(welds) do
					weld.C0 = weld:GetAttribute('closedPoint'):Lerp(weld:GetAttribute('openPoint'),value)
				end
				local checked = checkIfDoorIsClosed()
				if (lastChecked ~= checked) then
					lastChecked = checked
					data.isEnabled = checked
					if (not checked) then
						if (not hasStopped) then
							hasStopped = true
							module.statValues.Out_Of_Service = true
							module.sounds.Safety_Brake_Sound.PlaybackSpeed = module.sounds.Safety_Brake_Sound:GetAttribute('originalPitch')
							task.spawn(safetyBrake)
							playerWeld(false)
						end
					else
						hasStopped = false
						module.statValues.Out_Of_Service = not checkDropKeyState()
						if (not module.statValues.Out_Of_Service) then
							task.spawn(function()
								local isCompleted = coreFunctions.conditionalWait(1, function() return {module.statValues.Out_Of_Service} end)
								if (not isCompleted) then return end
								--task.spawn(safeCheckRelevel)
							end)
						end
						task.spawn(updateStatValues)
					end
				end
			end)
			if (not dropKeyHandlers[doorSet]) then dropKeyHandlers[doorSet] = {} end
			table.insert(dropKeyHandlers[doorSet], update)
		elseif (protocol == 'exit') then
			for i,v in pairs(user.PlayerGui:WaitForChild('DOOR_KEY_UIS'):GetChildren()) do
				if (collectionService:HasTag(v,'ACTIVE')) then
					v:Destroy()
				end
			end
			dismountDropKeyClient(user, params)
		end
	end)

	function elevatorSignal.OnInvoke(protocol, params)
		if (protocol == 'GET_ELEVATOR_WELDS') then
			return elevatorPlayerWelds
		end
	end

	players.PlayerRemoving:Connect(function(plr: Player)
		if (not table.find(dropKeyHandlers,plr)) then return end
		for i,v in pairs(collectionService:GetTagged('IsInUse')) do
			if (v:IsDescendantOf(elevator)) then
				dismountDropKeyClient(plr,v)
			end
		end
	end)

	api:Fire('Lock_Floors', (configFile.Locking.Locked_Floors) or {})
	api:Fire('Lock_Hall_Floors', (configFile.Locking.Locked_Hall_Floors) or {})

	task.spawn(updateFloor)
	task.spawn(updateStatValues)
end

return module