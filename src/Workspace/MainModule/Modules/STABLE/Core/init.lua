--[[

	04/14/2023

	Cortex Classic- OFFICIAL CORE MODULE- BRANCH 'ALPHA'
	Version Begin: v5.2.6
	Version Overhaul Start: v8.4
	
	WRITTEN BY AAXTATIOUS (540781721) & IMFIRSTPLACE (79641334)
	
	© 2023 Cortex Elevator Co.
	
	REDISTRIBUTION OF THIS SOURCE IS ACCEPTABLE- PLEASE CREDIT DEVELOPER(S) & ACCEPT TERMS
	
	--// 08-13-2023 - CLASSIC V9.0 IS RELEASED! ENTAILS FULL CALL QUEUE SYSTEM REWRITE --//

]]--

local module = {}
module.MODULE_STORAGE = {
	sounds={},
	statValues={},
	miscValues={},
	queue={},
} --Storage for variables replacing locals

local _V = _G['Core_CurrentVersion']
local _VERSION = `Classic {_V}`
local elevatorID = math.random(0,1e5)

function module.Start(source, config, BUILD, mainModuleDependencies)

	local thread
	local function restartElevator()
		--source.Enabled = false
		--source.Enabled = true
		--return coroutine.yield(thread)
	end
	thread = coroutine.create(function()
		local dateTime = DateTime.now()
		print(`Cortex {_VERSION} :: {source:GetFullName()} | Elevator source controller '{BUILD.BUILD}' initiating...\nInitiation Timestamp: {dateTime:FormatLocalTime('LLL', 'en-us')}`)

		local cfgRan,cfgMsg = pcall(require, config)
		if (not cfgRan) then
			return error(`{_VERSION} ERROR WHILE REQUESTING ELEVATOR SETTINGS :: {cfgMsg}`, 5)
		else
			config = cfgMsg
		end

		local httpService: HttpService = game:GetService('HttpService')

		if (config.TYPE == 'PLUGIN_GENERATED') then
			local DATA = httpService:JSONDecode(config.EXPORTED_DATA)
			config = DATA
			local function checkColorValues(list)

				for i,v in pairs(list) do
					if (typeof(v) == 'table') then
						if (v.TYPE == 'COLOR3') then
							list[i] = Color3.fromRGB(v.R*255, v.G*255, v.B*255)
						elseif (v.ENUM_DATA) then
							list[i] = Enum[v.ENUM_DATA.ENUM_TYPE][v.ENUM_DATA.ENUM_NAME]
						else
							checkColorValues(v)
						end
					end
				end

				return list

			end

			config = checkColorValues(config)
		end

		local configFile = require(script.Assets.ConfigFile--[[13443177628]])(config, script) -- LOADS CONFIG TEMPLATE FOR ELEVATOR CONFIGURATION --

		local function debugWarn(message)
			if (not configFile.Debug) then return end
			return print(string.format('%s :: %s', _VERSION, message))
		end

		--local prevCfgEnabled = configFile.Sound_Database.Voice_Config and configFile.Sound_Database.Voice_Config.Enabled
		--if (configFile.Sound_Database.Voice_Config.Voice_Clips == 'STOCK') then configFile.Sound_Database.Voice_Config = require(script.Voice_Module.STOCK_VoiceModule) end
		--configFile.Sound_Database.Voice_Config.Enabled = prevCfgEnabled

		--local prevCfgEnabled = configFile.Sound_Database.Voice_Config and configFile.Sound_Database.Voice_Config.Enabled
		if (configFile.Sound_Database.Voice_Config.Voice_Clips == 'STOCK') then
			configFile.Sound_Database.Voice_Config.Voice_Clips = require(script.Voice_Module.DefaultVoiceModule)(require(script.Voice_Module.STOCK_VoiceModule), source)
		elseif typeof(configFile.Sound_Database.Voice_Config.Voice_Clips) == 'table' then
			configFile.Sound_Database.Voice_Config.Voice_Clips = require(script.Voice_Module.DefaultVoiceModule)(configFile.Sound_Database.Voice_Config.Voice_Clips, source)
		end

		--configFile.Sound_Database.Voice_Config.Enabled = prevCfgEnabled;

		local voiceConfig = configFile.Sound_Database.Voice_Config.Voice_Clips
		local voiceModule = require(script.Voice_Module).new(voiceConfig)

		local function handleConfigValue(path, index, value, fallbackValue, expectedType)
			if (path[index] == nil or (expectedType ~= nil and typeof(path[index]) ~= expectedType)) then
				path[index] = fallbackValue
			elseif (value ~= nil) then
				path[index] = value
			else
				path[index] = fallbackValue
			end
		end

		handleConfigValue(configFile.Movement, 'Floor_Pass_Chime_On_Stop_Config', config.Movement.Floor_Pass_Chime_On_Stop_Config, {['Enable']=false,['Delay']=0,['Play_On_Arrival_Floor']=true}, 'table')
		handleConfigValue(configFile.Doors, 'Reopen_When_Nudge_Obstruction', config.Doors.Reopen_When_Nudge_Obstruction, false, 'boolean')
		handleConfigValue(configFile.Doors, 'Use_Old_Door_Sensors', config.Doors.Use_Old_Door_Sensors, true, 'boolean')
		handleConfigValue(configFile.Sound_Database.Others, 'Door_Obstruction_Signal', config.Sound_Database.Others.Door_Obstruction_Signal, {['Sound_Id'] = 0, ['Volume'] = .5, ['Pitch'] = 1, ['Enable'] = false}, 'table')
		handleConfigValue(configFile.Doors, 'Door_Motor', config.Doors.Door_Motor, true, 'boolean')
		handleConfigValue(configFile.Sound_Database.Others, 'Door_Motor_Sound', config.Sound_Database.Others.Door_Motor_Sound, {
			['Enable'] = configFile.Doors.Door_Motor,
			['Sound_Id'] = 6420222939,
			['Open'] = {
				['BaseVolume'] = 0,
				['BasePitch'] = 0,
				['PeakVolume'] = 5,
				['PeakPitch'] = 1,
			},
			['Close'] = {
				['BaseVolume'] = 0,
				['BasePitch'] = 0,
				['PeakVolume'] = 5,
				['PeakPitch'] = .85,
			}
		}, 'table')
		handleConfigValue(configFile.Sound_Database.Others, 'Safety_Brake_Sound', config.Sound_Database.Others.Safety_Brake_Sound, {['Sound_Id'] = 6389151811, ['Volume'] = .5, ['Pitch'] = 1}, 'table')

		handleConfigValue(configFile.Doors, 'Stay_Open_When_Idle', config.Doors.Stay_Open_When_Idle, false, 'boolean')
		handleConfigValue(configFile.Doors, 'Close_On_Button_Press', config.Doors.Close_On_Button_Press, {
			['Enable'] = false,
			['Delay'] = 1,
		}, 'table')

		handleConfigValue(configFile.Movement, 'Stop_Delay', config.Movement.Stop_Delay, 0, 'number')
		handleConfigValue(configFile.Movement, 'Open_Doors_On_Stop', config.Movement.Open_Doors_On_Stop, true, 'boolean')
		handleConfigValue(configFile.Movement, 'Open_Doors_On_Call', config.Movement.Open_Doors_On_Call, true, 'boolean')

		handleConfigValue(configFile.Doors, 'Manual_Door_Controls', config.Doors.Manual_Door_Controls, {
			['Enable_Open'] = false,
			['Enable_Close'] = false,
		}, 'table')

		config.Color_Database.Lanterns.Exterior = configFile.Color_Database.Lanterns.Exterior
		config.Color_Database.Lanterns.Interior = configFile.Color_Database.Lanterns.Interior
		handleConfigValue(configFile.Color_Database.Lanterns.Exterior, 'Reset_After_Door_Close', config.Color_Database.Lanterns.Exterior.Reset_After_Door_Close, true, 'boolean')
		handleConfigValue(configFile.Color_Database.Lanterns.Interior, 'Reset_After_Door_Close', config.Color_Database.Lanterns.Interior.Reset_After_Door_Close, true, 'boolean')

		local tweenService = game:GetService('TweenService')
		local runService = game:GetService('RunService')
		local collectionService = game:GetService('CollectionService')
		local contentProvider: ContentProvider = game:GetService('ContentProvider')
		local physicsService: PhysicsService = game:GetService('PhysicsService')

		local HEARTBEAT = _G.Cortex_SERVER.EVENTS.RUNTIME_EVENT.EVENT

		local elevator = source.Parent
		elevator:SetAttribute('elevatorID', elevatorID)
		local car = elevator:FindFirstChild('Car')
		if (not car) then return warn(_VERSION..' :: FATAL INITIATION ERROR: No \'Car\' model found!') end
		local floors = elevator:FindFirstChild('Floors')
		if (not floors) then return warn(_VERSION..' :: FATAL INITIATION ERROR: No \'Floors\' model found!') end
		local platform = car:FindFirstChild('Platform')
		if (not platform) then return warn(_VERSION..' :: FATAL INITIATION ERROR: No \'Platform\' instance found in the car!') end
		local level = car:FindFirstChild('Level')
		if (not level) then level = platform warn(_VERSION..' :: Initiation warning: No \'Level\' instance found in the car! Defaulting to the \'Platform\' instance') end
		local carRegion = car:FindFirstChild('Cab_Region')
		if (not carRegion) then
			carRegion = Instance.new('Part')
			carRegion.Name = 'Cab_Region'
			local size = platform.Size+Vector3.new(0, 15, 0)
			carRegion.CFrame,carRegion.Size = CFrame.new(platform.Position.X, platform.Position.Y+size.Y/2, platform.Position.Z)*CFrame.Angles(platform.CFrame:ToEulerAnglesXYZ()),size
			carRegion.Parent = car
		end
		carRegion.Anchored = true
		carRegion.Transparency = 1
		carRegion.CanCollide = false
		carRegion.CanQuery = false
		local soundGroup = carRegion:FindFirstChildOfClass('SoundGroup') or Instance.new('SoundGroup')
		soundGroup.Parent = carRegion
		local equalizer = soundGroup:FindFirstChildOfClass('EqualizerSoundEffect') or Instance.new('EqualizerSoundEffect')
		equalizer.Name = 'Muffler'
		equalizer.Parent = soundGroup
		equalizer.HighGain = 0
		equalizer.LowGain = 0
		equalizer.MidGain = 0

		-- // NEWLY ADDED :: REGISTERED FLOOORING FOR ERROR PREVENTION //--
		local registeredFloors = {}
		for i,v in pairs(floors:GetChildren()) do
			local floorNumber,level = tonumber(string.split(v.Name,'Floor_')[2]),v:FindFirstChild('Level')
			if (floorNumber and level) then
				registeredFloors[floorNumber] = { ['floorInstance']=v,['floorNumber']=floorNumber,['exteriorCallDirections']={} }
			end
		end
		local function findRegisteredFloor(floor: number)
			return registeredFloors[tonumber(floor)]
		end

		function findFloor(floor)
			local result = floors:FindFirstChild('Floor_'..tostring(floor))
			if (result and result:FindFirstChild('Level')) then return result end
			return nil
		end
		function getFloorDistance(floor: number, absolute: boolean?)
			absolute = if (absolute == nil) then true else absolute
			if (not findFloor(floor)) then return 0 end
			local dist = level.Position.Y-findFloor(floor).Level.Position.Y
			return absolute and math.abs(dist) or dist
		end

		local counterweight = elevator:FindFirstChild('Counterweight')

		local function lerp(a, b, t)
			return a+(b-a)*t
		end
		local function getTableLength(table)
			local index = 0
			for i,v in pairs(table) do
				index += 1
			end
			return index
		end

		local function addSound(append, name, config, looped, autoRange, maxDist, minDist)
			if (not append) then return end
			local sound = append:FindFirstChild(name)
			if (not sound) then
				local assetId = `rbxassetid://{config.Sound_Id}`
				sound = Instance.new('Sound')
				sound.Name = name
				sound.SoundId = string.len(tostring(config.Sound_Id)) >= 6 and assetId or ''
				sound.Volume = typeof(config.Volume) == 'number' and config.Volume or 0
				sound.Pitch = typeof(config.Pitch) == 'number' and config.Pitch or 0
				sound.Looped = if (typeof(looped) == 'boolean') then looped elseif (typeof(config.Looped) == 'boolean') then config.Looped else false
				local thisSoundGroupPath = config.Sound_Group and string.split(config.Sound_Group, '.')[1] == 'Car' and car or nil
				sound.SoundGroup = thisSoundGroupPath and thisSoundGroupPath:FindFirstChild(string.split(config.Sound_Group, '.')[2], true) or append:IsDescendantOf(car) and soundGroup or nil
				sound.RollOffMaxDistance = autoRange and (append.Size+Vector3.new(0, 15, 0)).Magnitude or typeof(maxDist) == 'number' and maxDist or 0
				sound.RollOffMinDistance = autoRange and sound.RollOffMaxDistance/5 or typeof(minDist) == 'number' and minDist or 0
				sound.Parent = append
				if (config.Play_When_Added) then
					sound:Play()
				end
				if (config.On_Add_Event_Function and typeof(config.On_Add_Event_Function) == 'function') then
					config.On_Add_Event_Function(sound)
					--[[
					This new configuration plugin-in allows users to modify sounds directly
						from their insertion in the Settings rather than having to use
										third-party external scripts
					]]--
				end
			end
			return sound
		end
		local function addPlaySound(sound, part)
			if (not part) then return end
			local newSound: Sound = sound:Clone()
			newSound.Name = `{newSound.Name}_Playing`
			newSound.Parent = part
			newSound.SoundGroup = part:IsDescendantOf(car) and soundGroup or nil
			--if (not newSound.IsLoaded) then newSound.Loaded:Wait() end
			newSound:Play()
			game:GetService('Debris'):AddItem(newSound, newSound.TimeLength)
		end

		local function callTableRecursive(t: any, callback: any)
			if (typeof(t) == 'table') then
				for i,v in next,t do
					if (typeof(callback) == 'function') then
						callback(i, v)
					end
					callTableRecursive(v, callback)
				end
			end
		end

		--AUDIO IMPORTING--
		callTableRecursive(configFile.Sound_Database, function(i: any, t: any)
			if (typeof(t) == 'table' and t.Voice_ID) then t.Sound_Id = t.Voice_ID i = 'Voice_Audio' end
			if (typeof(t) == 'table' and t.Sound_Id and (not module.MODULE_STORAGE.sounds[i])) then
				module.MODULE_STORAGE.sounds[i] = addSound(t.Append or carRegion, i, t, i == 'Alarm' or i == 'Nudge_Buzzer' or (string.match(i, 'Motor_Run') ~= nil) or i == 'Traveling_Sound', true)
			end
		end)
		callTableRecursive(config.Sound_Database, function(i: any, t: any)
			if (typeof(t) == 'table' and t.Voice_ID) then t.Sound_Id = t.Voice_ID i = 'Voice_Audio' end
			if (typeof(t) == 'table' and t.Sound_Id and (not module.MODULE_STORAGE.sounds[i]) and (i ~= 'Start' and i ~= 'Run' and i ~= 'Stop' and i ~= 'Up_Chime' and i ~= 'Down_Chime')) then
				module.MODULE_STORAGE.sounds[i] = addSound(t.Append or carRegion, i, t, t.Looped, true)
			end
		end)

		module.MODULE_STORAGE.sounds.Voice_Audio = addSound(carRegion, 'Voice_Audio', {['Sound_Id'] = voiceConfig.SoundId, ['Volume'] = voiceConfig.Volume, ['Pitch'] = voiceConfig.Pitch}, false, true)
		module.MODULE_STORAGE.sounds.Traveling_Sound:Play()
		module.MODULE_STORAGE.sounds.Safety_Brake_Sound:SetAttribute('originalPitch', module.MODULE_STORAGE.sounds.Safety_Brake_Sound.PlaybackSpeed)
		module.MODULE_STORAGE.sounds.Safety_Brake_Sound:SetAttribute('newPitch', module.MODULE_STORAGE.sounds.Safety_Brake_Sound.PlaybackSpeed*2)

		-- Sounds that get initialized later
		local inspectionSwitchClick = nil
		local inspectionButtonClick = {}

		local pluginModules_INTERNAL = {}
		for i,t in next,{script.Core_Modules_INTERNAL:GetChildren(),source:FindFirstChild('Plugins_INTERNAL') and source.Plugins_INTERNAL:GetChildren() or {}} do
			for i,v in next,t do
				v = v:GetAttribute('overridable') and source:FindFirstChild('Plugins_INTERNAL') and source.Plugins_INTERNAL:FindFirstChild(v.Name) or v --If the plugin module's name can be found within the Plugins extension, replace internal with plugin module
				local ran,res = pcall(require, v)
				if (not ran) then return debugWarn(`INTERNAL PLUGIN MODULE '{v.Name}' SETUP FAILED :: {res}`) end
				local ran,res2 = pcall(function()
					return task.spawn(function() return res:INITIATE_PLUGIN_INTERNAL(script, source) end)
				end)
				if (not ran) then debugWarn(`INTERNAL PLUGIN MODULE '{v.Name}' INITIATION FAILED :: {res}`)
				else
					pluginModules_INTERNAL[v.Name] = {CONTENT=res,MODULE=v}
				end
			end
		end

		local startPosition = platform.CFrame
		local positionOffset = 0

		local api = elevator:FindFirstChild('Cortex_API') or Instance.new('BindableEvent')
		api.Name = 'Cortex_API'
		api.Parent = elevator
		local remote = elevator:FindFirstChild('Cortex_Remote') or Instance.new('RemoteEvent')
		remote.Name = 'Cortex_Remote'
		remote.Parent = elevator
		local globalRemote: RemoteEvent = game.ReplicatedStorage:FindFirstChild('Cortex_Remote_GLOBAL') or Instance.new('RemoteEvent', game.ReplicatedStorage)
		globalRemote.Name = 'Cortex_Remote_GLOBAL'
		pluginModules_INTERNAL.Storage.CONTENT:save('mainElevatorData', 'car', car)

		local function getAccelerationTime(...)
			return pluginModules_INTERNAL.Core_Functions.CONTENT:getAccelerationTime(...)
		end
		local function getDecelerationRate(...)
			return pluginModules_INTERNAL.Core_Functions.CONTENT:getDecelerationRate(...)
		end
		local function smoothstep(min: number, max: number, value: number)
			return pluginModules_INTERNAL.Core_Functions.CONTENT.smoothstep(min, max, value)
		end
		pluginModules_INTERNAL.Storage.CONTENT:save('mainElevatorData', 'getAccelerationTime', getAccelerationTime)

		_G.Elevator_Output_Storage_GLOBAL[elevator.Name] = {}
		local function outputElevMessage(msg: string?, type: string?)
			--Check the amount the table has. If it exceeds 200, begin clearing indexes from the beginning.
			if (runService:IsRunMode()) then
				--warn(msg)
			end
			local removed = false
			if (getTableLength(_G.Elevator_Output_Storage_GLOBAL[elevator.Name]) >= 200) then
				for i,v in pairs(_G.Elevator_Output_Storage_GLOBAL[elevator.Name]) do
					if (removed) then return end
					globalRemote:FireAllClients('Cortex_Output_Message_Removed', i)
					_G.Elevator_Output_Storage_GLOBAL[elevator.Name][i] = nil
					removed = true
					return
				end
			end
			local now = DateTime.fromUnixTimestamp(os.clock())
			local function generateRandomId()
				local randId = httpService:GenerateGUID()
				if (_G.Elevator_Output_Storage_GLOBAL[elevator.Name][tostring(randId)]) then
					return generateRandomId()
				end
				return randId
			end

			local colorDatabase = {
				['statuses'] = {
					['generic'] = {
						['debug']=Color3.new(0.870588, 0.870588, 0.870588),
						['warning']=Color3.new(1, 0.870588, 0.360784),
						['critical']=Color3.new(1, 0.32549, 0.32549),
						['bluecode']=Color3.new(0.376471, 0.709804, 1),
					}
				}
			}

			local messageId = generateRandomId()
			local data = {
				['elevator']=elevator,
				['message']={
					['content']=msg,
					['id']=messageId
				},
				['type']=type,
				['timestamp']=now,
				['color']=colorDatabase.statuses.generic[type]
			}
			_G.Elevator_Output_Storage_GLOBAL[elevator.Name][messageId] = data
			globalRemote:FireAllClients('Cortex_Output_Message_Broadcast', data)
		end

		for i,v in pairs(floors:GetChildren()) do
			if v:FindFirstChild('Level') then
				local sound = Instance.new('Sound')
				sound.Name = 'Drop_Key_Sound'
				sound.SoundId = 'rbxassetid://4496280365'
				sound.Volume = 1
				sound.RollOffMaxDistance = 200
				sound.RollOffMinDistance = 5
				sound.Pitch = 2.55/config.Doors.Door_Open_Speed
				sound.Parent = v.Level
			end
		end
		local sound = Instance.new('Sound')
		sound.Name = 'Drop_Key_Sound'
		sound.SoundId = 'rbxassetid://4496280365'
		sound.Volume = 1
		sound.RollOffMaxDistance = 200
		sound.RollOffMinDistance = 5
		sound.Pitch = 2.55/config.Doors.Door_Open_Speed
		sound.Parent = level

		module.MODULE_STORAGE.statValues.currentSpeed = 0
		module.MODULE_STORAGE.statValues.currentFloor = -100000
		module.MODULE_STORAGE.statValues.rawFloor = module.MODULE_STORAGE.statValues.currentFloor
		module.MODULE_STORAGE.statValues.arriveFloor = -100000
		module.MODULE_STORAGE.statValues.moveValue = 0
		module.MODULE_STORAGE.statValues.direction = 'N'
		module.MODULE_STORAGE.statValues.queueDirection = 'N'
		module.MODULE_STORAGE.statValues.arrowDirection = 'N'
		module.MODULE_STORAGE.statValues.moveDirection = 'N'
		module.MODULE_STORAGE.statValues.destination = module.MODULE_STORAGE.statValues.rawFloor
		module.MODULE_STORAGE.statValues.departFloor = module.MODULE_STORAGE.statValues.rawFloor
		module.MODULE_STORAGE.miscValues.nFloor = 0
		module.MODULE_STORAGE.miscValues.rawNFloor = 0
		module.MODULE_STORAGE.statValues.nudging = false
		module.MODULE_STORAGE.statValues.leveling = false
		module.MODULE_STORAGE.miscValues.leaving = false
		module.MODULE_STORAGE.miscValues.arrivingving = false
		module.MODULE_STORAGE.statValues.fireService = false
		module.MODULE_STORAGE.statValues.fireRecall = false
		module.MODULE_STORAGE.statValues.phase1 = false
		module.MODULE_STORAGE.statValues.phase2 = false
		module.MODULE_STORAGE.statValues.inspection = false
		module.MODULE_STORAGE.miscValues.inspectionCommonEnabled = false
		module.MODULE_STORAGE.statValues.parking = false
		inspectionLocked = false
		outOfService = false
		independentService = false
		safetyBraking = false
		moveBrake = false
		preDooring = false
		releveling = false
		bouncing = false
		stopElevator = false
		overshot = false
		fireRecallFloor = -100000
		preDirection = 'N'
		preChimeFloor = -1000
		lockedFloors = {}
		lockedHallFloors = {}
		directionalFloorCalls = {}
		departPreStarting = false
		chimingAfterOpen = {}
		doorStateValues = {}
		dropKeyCheckValues = {}
		switchingDirectionFromNeutral = false
		lock = false
		elevatorPosition = startPosition
		idleAnimations = {}
		playerWeldData = {}
		dropKeyHandlers = {}

		local function checkIndependentService()
			return (not module.MODULE_STORAGE.statValues.fireService and independentService)
		end

		local function checkPhase2()
			return (not module.MODULE_STORAGE.statValues.fireRecall and module.MODULE_STORAGE.statValues.fireService and module.MODULE_STORAGE.statValues.phase2)
		end

		module.MODULE_STORAGE.miscValues.clientRefreshHandlers = {}

		local function addClientRefreshToPlayer(player)
			local newGui = player:WaitForChild('PlayerGui'):FindFirstChild('Cortex_ClientRefresh') or mainModuleDependencies.Cortex_ClientRefresh:Clone()
			if (configFile.ClientRefresh_Movement_Config.Enable) then
				local wl = httpService:JSONDecode(newGui.WHITELIST_META.Value)
				wl[tostring(elevatorID)] = {ENABLE=true}
				newGui.WHITELIST_META.Value = httpService:JSONEncode(wl)
				module.MODULE_STORAGE.miscValues.clientRefreshHandlers[player] = newGui
			end
			newGui.Parent = player.PlayerGui
		end
		game.Players.PlayerAdded:Connect(addClientRefreshToPlayer)
		for i, player in pairs(game.Players:GetPlayers()) do
			addClientRefreshToPlayer(player)
		end
		collectionService:AddTag(elevator, 'cortexElevatorInstance')
		if (not table.find(_G.CortexElevatorStorage, elevator)) then
			table.insert(_G.CortexElevatorStorage, elevator)
		end

		local floorsArray = {}
		for i,v in pairs(floors:GetChildren()) do
			local floorNumber = tonumber(string.gsub(v.Name, '%D', ''))
			if (floorNumber and findFloor(floorNumber) and findFloor(floorNumber):FindFirstChild('Level')) then
				table.insert(floorsArray, floorNumber)
			end
		end

		local statisticsValues = {}
		local statisticsFolder = elevator:FindFirstChild('Legacy') or Instance.new('Folder', elevator)
		statisticsFolder.Name = 'Legacy'
		local playerWeldsFolder = platform:FindFirstChild('Player_Welds') or Instance.new('Folder', platform)
		playerWeldsFolder.Name = 'Player_Welds'
		pluginModules_INTERNAL.Storage.CONTENT:save('mainElevatorData', 'legacy', statisticsFolder)

		local queueTableJSON = pluginModules_INTERNAL.Core_Functions.CONTENT.addInstance(statisticsFolder, 'StringValue', 'Queue', false, {Value=''})
		queueTableJSON.Value = httpService:JSONEncode({})

		local function addStatisticValue(type, name, updateValueFunc)
			local val = statisticsFolder:FindFirstChild(name) or Instance.new(type, statisticsFolder)
			val.Name = name
			statisticsValues[name] = {
				['value']=val,
				['updateValue']=updateValueFunc
			}
			return val
		end

		local floorVal = addStatisticValue('NumberValue', 'Floor', function(value)
			value.Value = module.MODULE_STORAGE.statValues.currentFloor
		end)
		local rawFloorVal = addStatisticValue('NumberValue', 'Raw_Floor', function(value)
			value.Value = module.MODULE_STORAGE.statValues.rawFloor
		end)
		local moveVal = addStatisticValue('NumberValue', 'Move_Value', function(value)
			value.Value = module.MODULE_STORAGE.statValues.moveValue
		end)
		local arrowDirVal = addStatisticValue('StringValue', 'Arrow_Direction', function(value)
			value.Value = module.MODULE_STORAGE.statValues.arrowDirection
		end)
		local queueDirVal = addStatisticValue('StringValue', 'Queue_Direction', function(value)
			value.Value = module.MODULE_STORAGE.statValues.queueDirection
		end)
		local destVal = addStatisticValue('NumberValue', 'Destination', function(value)
			value.Value = module.MODULE_STORAGE.statValues.destination
		end)
		local remoteCallVal = addStatisticValue('NumberValue', 'Remote_Call')
		local FSVal = addStatisticValue('BoolValue', 'Fire_Service', function(value)
			value.Value = module.MODULE_STORAGE.statValues.fireService
		end)
		local phase1Val = addStatisticValue('BoolValue', 'Phase_1', function(value)
			value.Value = module.MODULE_STORAGE.statValues.phase1
		end)
		local phase2Val = addStatisticValue('BoolValue', 'Phase_2', function(value)
			value.Value = module.MODULE_STORAGE.statValues.phase2
		end)
		local insVal = addStatisticValue('BoolValue', 'Inspection', function(value)
			value.Value = module.MODULE_STORAGE.statValues.inspection
		end)
		local oosVal = addStatisticValue('BoolValue', 'Out_Of_Service', function(value)
			value.Value = outOfService
		end)
		local indVal = addStatisticValue('BoolValue', 'Independent_Service', function(value)
			value.Value = independentService
		end)
		local speedVal = addStatisticValue('NumberValue', 'Current_Speed', function(value)
			value.Value = math.rad(module.MODULE_STORAGE.statValues.currentSpeed)
		end)
		local velocityVal = addStatisticValue('NumberValue', 'Velocity', function(value)
			value.Value = module.MODULE_STORAGE.statValues.currentSpeed
		end)
		local arriveFloorVal = addStatisticValue('NumberValue', 'Arrive_Floor', function(value)
			value.Value = module.MODULE_STORAGE.statValues.arriveFloor
		end)
		local levelingVal = addStatisticValue('BoolValue', 'Leveling', function(value)
			value.Value = module.MODULE_STORAGE.statValues.leveling
		end)
		local nudgeVal = addStatisticValue('BoolValue', 'Nudge', function(value)
			value.Value = module.MODULE_STORAGE.statValues.nudging
		end)
		local stopVal = addStatisticValue('BoolValue', 'Stop', function(value)
			value.Value = stopElevator
		end)
		local moveDirVal = addStatisticValue('StringValue', 'Move_Direction', function(value)
			value.Value = module.MODULE_STORAGE.statValues.moveDirection
		end)
		local preDirVal = addStatisticValue('StringValue', 'Pre_Direction', function(value)
			value.Value = preDirection
		end)

		local cabOccupancyValue = car:FindFirstChild('Occupancy') or Instance.new('NumberValue', car)
		cabOccupancyValue.Name = 'Occupancy'

		local function getDistance(target, origin, absolute)
			return absolute and math.abs(target-origin) or target-origin
		end

		pluginModules_INTERNAL.Storage.CONTENT:save('mainElevatorData', 'findFloor', findFloor)
		pluginModules_INTERNAL.Storage.CONTENT:save('mainElevatorData', 'getFloorDistance', getFloorDistance)

		--Set up top and bottom floors--
		local bottomFloor,topFloor
		local lastPos1,lastPos2 = math.huge,-math.huge
		for i,v in pairs(floors:GetChildren()) do
			local isAFloor = tonumber(string.split(v.Name, 'Floor_')[2])
			local level = v:FindFirstChild('Level')
			if ((isAFloor and level)) then
				local yPos = level.Position.Y
				if (level.Position.Y <= lastPos1) then
					bottomFloor = isAFloor
					lastPos1 = yPos
				end
				if (level.Position.Y >= lastPos2) then
					topFloor = isAFloor
					lastPos2 = yPos
				end
			end
		end

		local function getDoorState(side)

			if (not pluginModules_INTERNAL.Storage.CONTENT:getContentInBranch('masterDoorData')[side]) then return assert(_V..': Get Door State function with argument '..tostring(side)..' set error: Index not found in door states dictionary') end
			return pluginModules_INTERNAL.Storage.CONTENT:getContentInBranch('masterDoorData')[side]

		end

		remoteCallVal:GetPropertyChangedSignal('Value'):Connect(function()
			if (findFloor(remoteCallVal.Value)) then
				addCall(remoteCallVal.Value)
			end
		end)

		function isDropKeyOnElevator()
			for i,v in pairs(dropKeyCheckValues) do
				if (v.Value) then return false end
			end
			return true
		end

		local function conditionalStepWait(...)
			return pluginModules_INTERNAL.Core_Functions.CONTENT:conditionalStepWait(...)
		end

		local function isLevel()
			local regFloor = findRegisteredFloor(module.MODULE_STORAGE.statValues.rawFloor)
			if (not regFloor) then return end
			return ((regFloor.floorInstance.Level.Position.Y-level.Position.Y) <= .35) and true or false
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

		local function doDropKey(params)
			local doorSide = string.split(string.split(params.Name, 'Doors')[1], '_')[1]
			local function getWelds()
				local welds = {}
				local floorNumber = tonumber(string.gsub(params.Parent.Name, '%D', ''))
				for i,v in next,pluginModules_INTERNAL.Storage.CONTENT:getContentInBranch('masterDoorData') do
					for i,w in next,(params:IsDescendantOf(car) and v.engineWelds.car[doorSide] or v.engineWelds.floors[tostring(floorNumber)] and v.engineWelds.floors[tostring(floorNumber)][doorSide] or {}) do
						table.insert(welds, w)
					end
				end
				return welds

			end
			local landingLevel = findAncestor(params, 'Level')
			if (not landingLevel) then return end

			if ((landingLevel.Parent == car and getDoorState(doorSide).state == 'Closed') or (landingLevel.Parent ~= car and (((getDoorState(doorSide).state == 'Closed' and tonumber(landingLevel.Parent.Name:sub(7)) == module.MODULE_STORAGE.statValues.rawFloor) or tonumber(landingLevel.Parent.Name:sub(7)) ~= module.MODULE_STORAGE.statValues.rawFloor)))) then
				for i,weld in pairs(getWelds()) do
					if (weld.instance.C0 == weld.closedPosition) then
						landingLevel.Drop_Key_Sound:Play()
						task.spawn(function()
							pluginModules_INTERNAL.Legacy_Easing.CONTENT:interpolate(weld.instance,weld.openPosition,weld.instance.C1,'Out_Bounce',configFile.Doors.Door_Open_Speed*1.3)
						end)
						if module.MODULE_STORAGE.statValues.moveValue ~= 0 and isDropKeyOnElevator() then
							module.MODULE_STORAGE.sounds.Safety_Brake_Sound.PlaybackSpeed = module.MODULE_STORAGE.sounds.Safety_Brake_Sound:GetAttribute('originalPitch')
							safetyBrake()
						else
							moveBrake = true
						end
						outOfService = true
						params.Drop_Key_Open.Value = true
						getDoorData(doorSide).IsDropKey = true
						updateCore()
					elseif (weld.instance.C0 == weld.openPosition) then
						landingLevel.Drop_Key_Sound:Play()
						task.spawn(function()
							pluginModules_INTERNAL.Legacy_Easing.CONTENT:interpolate(weld.instance,weld.closedPosition,weld.instance.C1,'Out_Sine',configFile.Doors.Door_Open_Speed*1.3)
							params.Drop_Key_Open.Value = false
							getDoorData(doorSide).IsDropKey = false
							moveBrake = not isDropKeyOnElevator()
							outOfService = not isDropKeyOnElevator()
							preDooring = false
							releveling = false
							updateCore()
						end)
					end
				end
			end
		end

		local dropKeyUpdaters = {}

		local function dismountDropKeyClient(user,params)

			local doorSet = params
			if (not collectionService:HasTag(doorSet, 'IsInUse')) then return end
			local thisFloorName = doorSet:IsDescendantOf(floors) and string.split(doorSet.Parent.Name, 'Floor_')[2]
			local landingLevel = doorSet.Parent.Level
			local sideIndex = doorSet.Name:split('Doors')[1]:split('_')[1]
			local fullSideName = (sideIndex == '' and 'Front' or sideIndex)

			for i,v in pairs(dropKeyUpdaters[doorSet]) do
				v:Disconnect()
			end
			local index = table.find(dropKeyHandlers,user)
			if (index) then
				table.remove(dropKeyHandlers,index)
			end
			local doorBounds = doorSet:FindFirstChild('Door_Bounds')
			if (doorBounds) then doorBounds:Destroy() end
			dropKeyUpdaters[doorSet] = nil

			local welds = {}
			local data = pluginModules_INTERNAL.Storage.CONTENT:get('masterDoorData', sideIndex)
			for i,v in next,data and (doorSet:IsDescendantOf(car) and data.engineWelds.car[sideIndex] or data.engineWelds.floors[tostring(thisFloorName)][sideIndex]) or {} do
				table.insert(welds, v)
			end

			local function checkIfDoorIsClosed()
				for i,v in pairs(welds) do
					if (v.instance.C0 ~= v.closedPosition) then return false end
				end
				return true
			end

			local isClosed = checkIfDoorIsClosed()
			local function check()
				doorSet.Drop_Key_Open.Value = false
				moveBrake = not isDropKeyOnElevator()
				outOfService = not isDropKeyOnElevator()
				preDooring = false
				releveling = false
				api:Fire('onElevDoorKey',{doorSet=doorSet,status='release'})
				task.spawn(updateCore)
				task.spawn(function()
					local isCompleted = conditionalStepWait(1, function() return {moveBrake} end)
					if (not isCompleted) then return end
					task.spawn(safeCheckRelevel)
				end)
			end
			addPlaySound(addSound(landingLevel, 'Interlock_Click', {
				Sound_Id = 9116323848,
				Volume = 1,
				Pitch = 1.65
			}, false, false, 40, 3), landingLevel)
			if (not isClosed) then
				local connection: RBXScriptConnection
				local i = 0
				for _,v in pairs(welds) do
					v.startPosition = v.instance.C0
					v.alpha = 0
				end
				connection = HEARTBEAT:Connect(function(dtTime)
					i += .025*dtTime
					for _,v in pairs(welds) do
						v.alpha += i
						v.instance.C0 = v.startPosition:Lerp(v.closedPosition, math.min(v.alpha,1))
					end
					if (dropKeyUpdaters[doorSet]) then return connection:Disconnect() end
					if (checkIfDoorIsClosed()) then connection:Disconnect() return check() end
				end)
			end
			collectionService:RemoveTag(doorSet, 'IsInUse')

		end

		local chimeDebounce = false
		local isDown,isMoving,stopping = false,false,false
		local inspectionMoveDebounce = false

		local function stopInspection(params)
			if (stopping) then return end
			isDown = false
			local dir = params == 'Up' and 1 or params == 'Down' and -1
			if params ~= 'N' then -- bug fix to elevator being stuck when inspection is turned on and off when the elevator is idle
				stopping = true
			end
			if (not configFile.Movement.Motor_Stop_On_Open) then
				module.MODULE_STORAGE.statValues.leveling = true
			end
			moveBrake = false
			while (isMoving) do
				local delta = updateCore()
				module.MODULE_STORAGE.statValues.currentSpeed -= configFile.Movement.Inspection_Config.Deceleration_Rate
				if (module.MODULE_STORAGE.statValues.currentSpeed <= .1) then break end
				if (not stopping) then
					isMoving = false
					inspectionMoveDebounce = false
					return
				end
			end
			if (configFile.Movement.Motor_Stop_On_Open) then
				module.MODULE_STORAGE.statValues.leveling = true
			end
			removePlayerWelds()
			if (not isMoving) then inspectionMoveDebounce = false return end
			isMoving = false
			module.MODULE_STORAGE.statValues.leveling = false
			module.MODULE_STORAGE.statValues.moveValue = 0
			module.MODULE_STORAGE.statValues.currentSpeed = 0
			inspectionMoveDebounce = false
			task.spawn(updateCore)

		end

		local function playVoiceProtocol(clip, pauseThread)

			if (not configFile.Sound_Database.Voice_Config.Enabled) then return end
			voiceModule:PlayClip(module.MODULE_STORAGE.sounds.Voice_Audio, clip, pauseThread)

		end

		local function playVoiceSequenceProtocol(clipSequence, pauseThread)

			if (not configFile.Sound_Database.Voice_Config.Enabled) then return end
			local function run()
				for index,item in pairs(clipSequence) do
					voiceModule:PlayClip(module.MODULE_STORAGE.sounds.Voice_Audio, voiceConfig.Voice_Clips[item[1]], true)
					conditionalStepWait(item.Delay)
				end
			end
			if (pauseThread) then
				run()
			else
				task.spawn(function()
					run()
				end)
			end

		end

		local voiceSequenceQueue = {}
		local index = 0

		local function playVoiceSequenceProtocolWithQueue(clipSequence, pauseThread)
			if (not configFile.Sound_Database.Voice_Config.Enabled) then return end
			local length = #voiceSequenceQueue
			if (not table.find(voiceSequenceQueue, clipSequence)) then table.insert(voiceSequenceQueue, clipSequence) end
			if (length <= 0) then
				local function run()
					while (#voiceSequenceQueue > 0) do
						index += 1
						local sequence = voiceSequenceQueue[index]
						for index,item in pairs(sequence) do
							voiceModule:PlayClip(module.MODULE_STORAGE.sounds.Voice_Audio, voiceConfig.Voice_Clips[item[1]], true)
							conditionalStepWait(item.Delay)
						end
						local tindex = table.find(voiceSequenceQueue, sequence)
						if (tindex) then table.remove(voiceSequenceQueue, tindex) index -= 1 end
					end
					index = 0
				end
				if (pauseThread) then
					run()
				else
					task.spawn(run)
				end
			end

		end

		local platformPos = platform.Position

		local function doModelWeld(model, weldPart, ignoreList, append)
			local welds = {}
			for i,v in pairs(model:GetDescendants()) do
				if (v:IsA('BasePart')) then
					if (not weldPart) then
						weldPart = v
					end
					if ((typeof(ignoreList) ~= 'table' or (not table.find(ignoreList, v)))) then

						if (v ~= weldPart) then
							local weld = Instance.new('Weld')
							weld.Name = `{v.Name}_Weld`
							weld.Part0 = v
							weld.C0 = CFrame.new()
							weld.C1 = weldPart.CFrame:ToObjectSpace(v.CFrame)
							weld.Part1 = weldPart
							weld.Parent = append or weldPart
							table.insert(welds, weld)
						end
						v.Anchored = false
					end

				end
			end
			return welds
		end

		function weldTogether(part0, part1, joinInPlace, animatable)
			local weld = animatable and Instance.new('Motor6D') or Instance.new('Weld')
			weld.Part0 = part0
			if (joinInPlace) then
				weld.C0 = CFrame.new()
				weld.C1 = part1.CFrame:ToObjectSpace(part0.CFrame)
			end
			weld.Part1 = part1
			part0.Anchored = false
			weld.Parent = part0
			return weld
		end

		function getDoorData(side)
			local data = pluginModules_INTERNAL.Storage.CONTENT:get('masterDoorData', side)
			if (not data) then return end
			return data
		end

		local doorSensorsFolder = car:FindFirstChild('Door_Sensor_Parts') or Instance.new('Folder', car)
		doorSensorsFolder.Name = 'Door_Sensor_Parts'
		local carDoors = {}

		local doorWelds = {}
		local function doDoorWeld(model, weldPart)
			for i,v in pairs(model:GetChildren()) do
				if (string.match(v.Name:lower(), 'doors') and v:IsA('Model')) then
					if (v:IsDescendantOf(car)) then table.insert(carDoors, v) end

					local compactedSideName = v.Name:split('Doors')[1]
					local sideIndex = v.Name:split('Doors')[1]:split('_')[1]
					local fullSideName = (sideIndex == '' and 'Front' or sideIndex)
					local isOpen = v:FindFirstChild('Is_Open') or Instance.new('BoolValue', v)
					isOpen.Name = 'Is_Open'
					local dropOpen = v:FindFirstChild('Drop_Key_Open') or Instance.new('BoolValue', v)
					dropOpen.Name = 'Drop_Key_Open'
					table.insert(dropKeyCheckValues, dropOpen)
					local weldsModel = model:FindFirstChild(v.Name..'_Welds') or Instance.new('Folder', model)
					weldsModel.Name = `{v.Name}_Welds`

					local sensorPart,doorObstructionSignalAudio,doorOpenSound,doorCloseSound
					if (v:IsDescendantOf(car)) then
						local doorCFrame,doorSize = v:GetBoundingBox()
						sensorPart = Instance.new('Part')
						sensorPart.Name = string.format('%s_Sensor', sideIndex)
						sensorPart.Transparency = 1
						sensorPart.CanCollide = false
						sensorPart.CanTouch = false
						sensorPart.CanQuery = false
						--sensorPart.Massless = true
						local range = doorSize.Magnitude
						doorOpenSound = addSound(sensorPart, `{fullSideName}_Door_Open_Sound`, configFile.Sound_Database.Doors.Open_Sound, false, false, range*3.4, range/2)
						doorCloseSound = addSound(sensorPart, `{fullSideName}_Door_Close_Sound`, configFile.Sound_Database.Doors.Close_Sound, false, false, range*3.4, range/2)
						doorObstructionSignalAudio = addSound(sensorPart, 'Obstruction_Signal', configFile.Sound_Database.Others.Door_Obstruction_Signal, true, false, 60, 3)
						sensorPart.CFrame,sensorPart.Size = doorCFrame,doorSize+Vector3.new(0,0,1)
						weldTogether(sensorPart, platform, true)
						sensorPart.Anchored = false
						sensorPart.Parent = doorSensorsFolder
					end

					local doorStateValue = addStatisticValue('StringValue', `{fullSideName}_Door_State`, function(value)
						local data = pluginModules_INTERNAL.Storage.CONTENT:get('masterDoorData', sideIndex)
						if (data) then
							value.Value = data.state
						end
					end)
					local doorHoldValue = addStatisticValue('BoolValue', `{fullSideName}_Door_Hold`, function(value)
						local data = pluginModules_INTERNAL.Storage.CONTENT:get('masterDoorData', sideIndex)
						if (data) then
							value.Value = data.doorHold
						end
					end)

					local doorNudgingValue = addStatisticValue('BoolValue', `{fullSideName}_Door_Nudging`, function(value)
						local data = pluginModules_INTERNAL.Storage.CONTENT:get('masterDoorData', sideIndex)
						if (data) then
							value.Value = data.nudging
						end
					end)

					local doorMotorSound = addSound(weldPart, 'Door_Motor', configFile.Sound_Database.Others.Door_Motor_Sound, true, false, 60, 3)
					local multiplierValue = doorMotorSound:FindFirstChild('Multiplier') or Instance.new('NumberValue', doorMotorSound)
					multiplierValue.Name = 'Multiplier'
					multiplierValue.Value = doorMotorSound:FindFirstChild('Multiplier') and multiplierValue.Value or 1

					local doorSpeedValue = weldPart.Parent:FindFirstChild(`{compactedSideName}Door_Speed`) or Instance.new('NumberValue')
					doorSpeedValue.Parent = v:IsDescendantOf(car) and statisticsFolder or weldPart.Parent
					doorSpeedValue.Name = `{compactedSideName}Door_Speed`

					local doorData = pluginModules_INTERNAL.Storage.CONTENT:get('masterDoorData', sideIndex) or pluginModules_INTERNAL.Door_Engine.CONTENT.new(sideIndex, {sounds={
						doorOpenSound=doorOpenSound,
						doorCloseSound=doorCloseSound,
						doorMotorSound=doorMotorSound
					}, values={
						doorStateValue=doorStateValue,
						doorSpeedValue=doorSpeedValue
					}, config=configFile, doorSensorPart=sensorPart,doorSet=v})
					local floorNumber = tonumber(string.split(model.Name, 'Floor_')[2])

					local touchDebounce = false
					for i,door in pairs(v:GetChildren()) do

						local scaler = door:FindFirstChild('Scaler')
						if (scaler) then

							--Creates the new 'Closed' part inside the Scaler part to enhance safety if the weld disconnects
							local closedPart = scaler:FindFirstChild('Closed') or Instance.new('Part', scaler)
							closedPart.Parent = scaler
							closedPart.Size = scaler.Size
							closedPart.CFrame = scaler.CFrame
							closedPart.Name = 'Closed'
							closedPart.Transparency = 1
							closedPart.CanCollide = false
							closedPart.CanTouch = false
							closedPart.CanQuery = false
							weldTogether(closedPart, weldPart, true)
							doModelWeld(door, scaler, scaler:GetDescendants())

							local open = scaler:FindFirstChild('Open')
							if (not open) then
								open = Instance.new('Part')
								open.Name = 'Open'
								open.Parent = scaler
								open.Size = scaler.Size
								open.CanCollide = false
								open.Color = scaler.Color
								local cf = scaler.CFrame:ToWorldSpace(CFrame.new(0, 0, -((scaler.Parent.Name:sub(2,2) == 'R' and 1 or scaler.Parent.Name:sub(2,2) == 'L' and -1 or 0)*scaler.Size.Magnitude*.9)*scaler.Parent.Name:sub(3)))
								open.CFrame = cf
								open.Transparency = 1
							end
							weldTogether(open, weldPart, true, false)
							open.Anchored = false
							scaler.CanQuery = true

							local engineWeld = weldTogether(scaler, open, true, false)
							engineWeld.Name = 'Door_Engine_Weld'
							engineWeld.Parent = weldsModel

							local doorsDataIndex = scaler:IsDescendantOf(car) and 'Realistic_Doors_Data' or 'Realistic_Outer_Doors_Data'
							local openDiv,closeDiv = configFile.Doors.Realistic_Doors_Data and (configFile.Doors[doorsDataIndex].Open_Ratio or configFile.Doors.Realistic_Doors_Data.Open_Ratio) or 1.03,configFile.Doors.Realistic_Doors_Data and (configFile.Doors[doorsDataIndex].Close_Ratio or configFile.Doors.Realistic_Doors_Data.Close_Ratio) or 1.03
							local rx, ry, rz = engineWeld.C1:ToOrientation()
							local openCf = Vector3.new(rz, rx, ry)-Vector3.new(rz, rx, ry)/openDiv
							local closeCf = Vector3.new(rz, rx, ry)-Vector3.new(rz, rx, ry)/closeDiv
							local data = {
								['instance']=engineWeld,
								['openPosition']=engineWeld.C1,
								['closedPosition']=engineWeld.C0,
								['interlockOpenPosition'] = CFrame.new((engineWeld.C1.Position)-(engineWeld.C1.Position)/openDiv)*CFrame.Angles(openCf.X, openCf.Y, openCf.Y),
								['interlockClosePosition'] = CFrame.new((engineWeld.C1.Position)-(engineWeld.C1.Position)/closeDiv)*CFrame.Angles(openCf.X, openCf.Y, openCf.Y),
								['distanceFromOpenPosition']=(engineWeld.C1.Position-engineWeld.C0.Position).Magnitude,
								['side'] = sideIndex,
							}
							function data:getCurrentDistance()
								return (engineWeld.C1.Position-engineWeld.C0.Position).Magnitude
							end
							function data:getDistanceFromOpenPosition()
								return (data.closedPosition.Position-engineWeld.C0.Position).Magnitude
							end
							if (engineWeld:IsDescendantOf(car) and sideIndex) then
								if (not doorData.engineWelds.car[sideIndex]) then
									doorData.engineWelds.car[sideIndex] = {}
								end
								doorData.engineWelds.car[sideIndex][engineWeld] = data
							elseif (engineWeld:IsDescendantOf(floors) and floorNumber and sideIndex) then
								if (not doorData.engineWelds.floors[tostring(floorNumber)]) then
									doorData.engineWelds.floors[tostring(floorNumber)] = {}
								end
								if (not doorData.engineWelds.floors[tostring(floorNumber)][sideIndex]) then
									doorData.engineWelds.floors[tostring(floorNumber)][sideIndex] = {}
								end
								doorData.engineWelds.floors[tostring(floorNumber)][sideIndex][engineWeld] = data
							end

							if (scaler:IsDescendantOf(car)) then
								for i,part in pairs(door:GetDescendants()) do
									if (part:IsA('BasePart') and part.Name == 'Sensor_LED') then
										table.insert(doorData.sensorLEDs, part)
									end
								end
							end
						end
					end
					pluginModules_INTERNAL.Storage.CONTENT:save('masterDoorData', sideIndex, doorData, {OVERWRITE=false})
				end
			end
		end

		doDoorWeld(car, level)
		for i,v in pairs(registeredFloors) do
			doDoorWeld(v.floorInstance, v.floorInstance.Level)
		end

		local carWeldsFolder = car:FindFirstChild('Car_Welds') or Instance.new('Folder')
		carWeldsFolder.Name = 'Car_Welds'
		carWeldsFolder.Parent = car
		carWeldsFolder:ClearAllChildren()

		local doorParts = {}
		for i,v in pairs(carDoors) do
			for i,b in pairs(v:GetDescendants()) do
				if (b:IsA('BasePart')) then
					table.insert(doorParts, b)
				end
			end
		end

		local modelWelds = doModelWeld(car, platform, doorParts, carWeldsFolder)
		for i,v in pairs(modelWelds) do
			v.Parent = carWeldsFolder
		end

		local cwStart,cwOffset
		if (counterweight and counterweight:FindFirstChild('Main')) then
			for i,v in pairs(counterweight:GetDescendants()) do
				if (string.match(v.ClassName, 'Weld') or v:IsA('Sound') or (string.match(v.ClassName, 'Script') and v.Parent == counterweight)) then
					v:Destroy()
				end
			end
			doModelWeld(counterweight, counterweight.Main, {})
			local travelingSound = addSound(counterweight.Main, 'Traveling_Sound', {Sound_Id=6003695467,Volume=0,Pitch=1.15}, true, false, 50, .2)
			local equalizer: EqualizerSoundEffect = travelingSound:FindFirstChildOfClass('EqualizerSoundEffect') or Instance.new('EqualizerSoundEffect')
			equalizer.HighGain = -8
			equalizer.LowGain = 7
			equalizer.MidGain = -2
			equalizer.Parent = travelingSound
			travelingSound:Play()
			counterweight.Main.Anchored = true

			local cwPos = counterweight.Main.CFrame.Y+(findFloor(bottomFloor).Level.Position.Y-level.Position.Y)
			local oriX,oriY,oriZ = counterweight.Main.CFrame:ToOrientation()
			--counterweight.Main.CFrame = CFrame.new(counterweight.Main.CFrame.X, cwPos, counterweight.Main.CFrame.Z)*CFrame.Angles(oriX, oriY, oriZ)
			cwStart = counterweight.Main.CFrame
			cwOffset = counterweight.Main.Position
		end
		local elevatorHeight = math.abs(findFloor(topFloor).Level.Position.Y-findFloor(bottomFloor).Level.Position.Y)

		local attachmentPart = {}
		function attachmentPart:Create()

			self.attachmentPart = elevator:FindFirstChild('Physics_Attachment') or Instance.new('Part', elevator)
			self.attachmentPart.Name = 'Physics_Attachment'
			self.attachmentPart.Anchored = true
			self.attachmentPart.Archivable = false
			self.attachmentPart.CFrame = platform.CFrame
			self.attachmentPart.Size = Vector3.new(1, 1, 1)*1
			self.attachmentPart.CanCollide = false
			self.attachmentPart.Transparency = 1
			self.attachmentPart.Position = Vector3.new(platformPos.X, findFloor(bottomFloor).Level.Position.Y, platformPos.Z)
			return self

		end

		local cables = {}

		if (configFile.Movement.Movement_Type == 2) then

			local attachmentPart = attachmentPart:Create().attachmentPart
			local att0,att1 = Instance.new('Attachment', platform),Instance.new('Attachment', attachmentPart)
			att0.Orientation,att1.Orientation = Vector3.new(0, 0, 90),Vector3.new(0, 0, 90)
			local att0,att1 = Instance.new('Attachment', platform),Instance.new('Attachment', attachmentPart)
			local alignPos: AlignPosition = Instance.new('AlignPosition', platform)
			alignPos.Attachment0,alignPos.Attachment1 = att0,att1
			alignPos.MaxForce = math.huge
			alignPos.MaxVelocity = 0
			alignPos.Responsiveness = 200
			--alignPos.ApplyAtCenterOfMass = true
			--alignPos.RigidityEnabled = true
			local alignOri = Instance.new('AlignOrientation', platform)
			alignOri.Attachment0,alignOri.Attachment1 = att0,att1
			alignOri.MaxTorque = math.huge
			alignOri.MaxAngularVelocity = math.huge
			alignOri.Responsiveness = 200
			--alignOri.RigidityEnabled = true

		elseif (configFile.Movement.Movement_Type == 3) then

			local attachmentPart = attachmentPart:Create().attachmentPart
			local att0,att1 = Instance.new('Attachment', platform),Instance.new('Attachment', attachmentPart)
			att0.Orientation,att1.Orientation = Vector3.new(0, 0, 90),Vector3.new(0, 0, 90)
			local pris: PrismaticConstraint = Instance.new('PrismaticConstraint', attachmentPart)
			pris.Name = 'Prismatic'
			pris.Attachment0,pris.Attachment1 = att1,att0
			pris.ActuatorType = Enum.ActuatorType.Motor
			pris.Velocity = 0
			pris.MotorMaxForce = 100000000
			pris.MotorMaxAcceleration = 100000000

		elseif (configFile.Movement.Movement_Type == 4) then

			local attachmentPart = attachmentPart:Create().attachmentPart
			local att0,att1 = Instance.new('Attachment', platform),Instance.new('Attachment', attachmentPart)
			att0.Orientation,att1.Orientation = Vector3.new(0, 0, 90),Vector3.new(0, 0, 90)
			--Holds the car in place for the hoisting system--
			local pris: PrismaticConstraint = Instance.new('PrismaticConstraint', attachmentPart)
			pris.Attachment0,pris.Attachment1 = att1,att0

		end

		if (elevator:FindFirstChild('Physics_Attachment')) then
			for i,v in pairs(elevator:GetDescendants()) do
				if ((v:IsA('RopeConstraint') or v:IsA('RodConstraint')) and ((v.Attachment0 and v.Attachment0:IsDescendantOf(car)) or (v.Attachment1 and v.Attachment1:IsDescendantOf(car)))) then
					if (configFile.Movement.Movement_Type ~= 4 or v.Name ~= 'Elevator_Cable') then
						v.Enabled = false
					else

						local carAttachment = (v.Attachment0:IsDescendantOf(car) and v.Attachment0 or v.Attachment1:IsDescendantOf(car) and v.Attachment1)
						local hoistwayAttachment = ((not v.Attachment0:IsDescendantOf(car)) and v.Attachment0 or (not v.Attachment1:IsDescendantOf(car)) and v.Attachment1)

						--Replace any valid RodConstraints with RopeConstraints--
						local rope: RopeConstraint = Instance.new('RopeConstraint')
						rope.Name = v.Name
						rope.Attachment0,rope.Attachment1 = carAttachment,hoistwayAttachment
						rope.Color = v.Color
						rope.Thickness = v.Thickness
						rope.Visible = v.Visible
						rope.Length = rope.CurrentDistance
						rope.WinchEnabled = true
						rope.WinchForce = math.huge
						rope.WinchResponsiveness = 200
						rope.WinchSpeed = 0
						rope.WinchTarget = rope.CurrentDistance
						rope.Enabled = true
						rope.Parent = v.Parent
						v:Destroy()
						v = rope
						cables[v] = {cable=v,carAttachment=carAttachment,hoistwayAttachment=hoistwayAttachment}

					end
				end
			end
		end

		local elevatorCollisionGroup = 'elevatorCollisionGroup'
		local elevatorButtonsCollisionGroup = 'elevatorButtonsCollisionGroup'
		physicsService:RegisterCollisionGroup(elevatorCollisionGroup)
		physicsService:RegisterCollisionGroup(elevatorButtonsCollisionGroup)

		platform.Anchored = true--elevator:FindFirstChild('Physics_Attachment') == nil
		physicsService:CollisionGroupSetCollidable(elevatorCollisionGroup, elevatorCollisionGroup, false)

		for i,v in pairs(elevator:GetDescendants()) do
			if (v:IsA('BasePart')) then
				--if (configFile.Movement.Movement_Type ~= 1) then
				v.CollisionGroup = elevatorCollisionGroup
				--end
			end
		end

		local oversped = false
		local previousFloor = module.MODULE_STORAGE.statValues.currentFloor

		local function updateFloor()

			--Floor selector--
			local moveValue = module.MODULE_STORAGE.statValues.moveValue
			local nDist = math.huge
			local nRawDist = nDist
			for i,g in pairs(floors:GetChildren()) do
				if g:FindFirstChild('Level') then
					local lvl = g.Level
					local offset = (module.MODULE_STORAGE.statValues.moveValue == 1 and configFile.Sensors.Up_Level_Offset or module.MODULE_STORAGE.statValues.moveValue == -1 and configFile.Sensors.Down_Level_Offset or 0)
					local thisDist = math.abs((level.Position.Y+(module.MODULE_STORAGE.statValues.moveValue*(configFile.Sensors.Floor_Position_Offset*module.MODULE_STORAGE.statValues.currentSpeed))+(offset*math.rad(module.MODULE_STORAGE.statValues.moveValue*module.MODULE_STORAGE.statValues.currentSpeed)*.7))-lvl.Position.Y)
					local min = moveValue == 0 and bottomFloor or moveValue == 1 and module.MODULE_STORAGE.statValues.rawFloor or bottomFloor
					local max = moveValue == 0 and topFloor or moveValue == -1 and module.MODULE_STORAGE.statValues.rawFloor or topFloor
					if (thisDist <= nDist) then
						nDist = thisDist
						module.MODULE_STORAGE.miscValues.nFloor = math.clamp(tonumber(string.split(g.Name, 'Floor_')[2]), min <= max and min or max, max >= min and max or min)
					end
					if (math.abs(lvl.Position.Y-level.Position.Y) <= nRawDist) then
						module.MODULE_STORAGE.miscValues.rawNFloor = tonumber(string.split(g.Name, 'Floor_')[2])
						nRawDist = math.abs(lvl.Position.Y-level.Position.Y)
					end
				end
			end
			if (module.MODULE_STORAGE.miscValues.nFloor ~= module.MODULE_STORAGE.statValues.currentFloor and (preChimeFloor ~= module.MODULE_STORAGE.miscValues.nFloor)) then
				module.MODULE_STORAGE.statValues.currentFloor = module.MODULE_STORAGE.miscValues.nFloor
				if ((not module.MODULE_STORAGE.statValues.fireService) and (not checkIndependentService()) and (((not configFile.Movement.Floor_Pass_Chime_On_Stop_Config.Play_On_Arrival_Floor) and module.MODULE_STORAGE.statValues.currentFloor ~= module.MODULE_STORAGE.statValues.destination) or configFile.Movement.Floor_Pass_Chime_On_Stop_Config.Play_On_Arrival_Floor)) then
					task.delay(configFile.Sound_Database.Floor_Pass_Chime_Delay, function()
						addPlaySound(module.MODULE_STORAGE.sounds.Floor_Pass_Chime, platform)
					end)
				end
			end
			if (module.MODULE_STORAGE.miscValues.rawNFloor ~= module.MODULE_STORAGE.statValues.rawFloor) then
				module.MODULE_STORAGE.statValues.rawFloor = module.MODULE_STORAGE.miscValues.rawNFloor
			end

		end

		local startingPlatformCF = platform.CFrame
		local signalFiring = false

		local lastTick = os.clock()
		local dtTime = 0
		local lastPlatformPosition = platform.Position

		local targetPointVal: CFrameValue = platform:FindFirstChild('TARGET_POSITION_FRAME') or Instance.new('CFrameValue')
		targetPointVal.Name = 'TARGET_POSITION_FRAME'
		targetPointVal.Parent = platform
		targetPointVal:GetPropertyChangedSignal('Value'):Connect(function()
			platform.CFrame = targetPointVal.Value
		end)

		local initialDirection = 0
		function updateCore()

			local dtTime = HEARTBEAT:Wait()
			local function applyForce()
				platform:ApplyImpulse(platform.CFrame.UpVector*(module.MODULE_STORAGE.statValues.moveValue*module.MODULE_STORAGE.statValues.currentSpeed))
				for i,v in pairs(playerWeldData) do
					if (v.position) then
						v.position.Position = platform.Position+Vector3.new(0, 1, 0)*v.position:GetAttribute('playerWeldHeight')
					end
				end
			end

			--Move the platform--
			if (elevator:FindFirstChild('Physics_Attachment')) then
				if (platform:FindFirstChild('AlignPosition')) then
					platform.AlignPosition.MaxVelocity = (module.MODULE_STORAGE.statValues.currentSpeed)
					elevator.Physics_Attachment.Position = Vector3.new(elevator.Physics_Attachment.Position.X, (module.MODULE_STORAGE.statValues.moveValue == 1 and findFloor(topFloor).Level.Position.Y or module.MODULE_STORAGE.statValues.moveValue == -1 and findFloor(bottomFloor).Level.Position.Y) or elevator.Physics_Attachment.Position.Y, elevator.Physics_Attachment.Position.Z)
				elseif (elevator.Physics_Attachment:FindFirstChild('Prismatic')) then
					elevator.Physics_Attachment.Prismatic.Velocity = (module.MODULE_STORAGE.statValues.moveValue*module.MODULE_STORAGE.statValues.currentSpeed)
				end
				platform.Anchored = module.MODULE_STORAGE.statValues.currentSpeed == 0
				for i: RopeConstraint,v: {} in pairs(cables) do
					i.WinchTarget = -module.MODULE_STORAGE.statValues.moveValue*1000000
					i.WinchSpeed = module.MODULE_STORAGE.statValues.currentSpeed
				end
			else
				local priorPositionFrame = startPosition*CFrame.new(0, positionOffset, 0)
				positionOffset += (module.MODULE_STORAGE.statValues.moveValue*module.MODULE_STORAGE.statValues.currentSpeed)*math.min(math.round(dtTime*1000)/1000, 2)
				elevatorPosition = startPosition*CFrame.new(0, positionOffset, 0)
				local regBottomFlr,regTopFlr = findRegisteredFloor(bottomFloor),findRegisteredFloor(topFloor)
				if (regBottomFlr and regTopFlr) then
					elevatorPosition = CFrame.new(elevatorPosition.X,--[[math.clamp(elevatorPosition.Y,regBottomFlr.floorInstance.Level.Position.Y-2,regTopFlr.floorInstance.Level.Position.Y+2)]]elevatorPosition.Y,elevatorPosition.Z)*CFrame.fromEulerAnglesXYZ(startPosition:ToEulerAnglesXYZ())
					targetPointVal.Value = elevatorPosition
					applyForce()
				end
			end

			local carSpeed = (platform.Position-lastPlatformPosition)

			local tSpeedFactor = configFile.Sound_Database.Others.Traveling_Sound.Speed_Factor*(module.MODULE_STORAGE.statValues.currentSpeed/configFile.Movement.Travel_Speed)
			local volumeConstraint = configFile.Sound_Database.Others.Traveling_Sound.Constraints.Volume
			local pitchConstraint = configFile.Sound_Database.Others.Traveling_Sound.Constraints.Pitch

			if (counterweight and cwStart) then
				cwOffset -= carSpeed
				local oriX,oriY,oriZ = cwStart:ToOrientation()
				counterweight.Main.CFrame = CFrame.new(cwOffset)*CFrame.Angles(oriX, oriY, oriZ)
				counterweight.Main.Traveling_Sound.Volume = math.clamp(math.abs(module.MODULE_STORAGE.statValues.currentSpeed)/15, 0, 2)
			end

			--Master Nudge Value--
			local masterNudge = false
			for i,v in pairs(pluginModules_INTERNAL.Storage.CONTENT:getContentInBranch('masterDoorData')) do
				if (v.nudging) then
					masterNudge = true
					break
				end
			end

			module.MODULE_STORAGE.statValues.nudging = masterNudge

			--Update statisticsFolder values--
			for i,value in pairs(statisticsValues) do
				if (value.updateValue and typeof(value.updateValue) == 'function') then
					value.updateValue(value.value)
				end
			end
			------
			if (module.MODULE_STORAGE.sounds.Traveling_Sound and configFile.Sound_Database.Others.Traveling_Sound.Enable) then
				local travelingSound = module.MODULE_STORAGE.sounds.Traveling_Sound
				travelingSound.Volume = configFile.Sound_Database.Others.Traveling_Sound.Factor_Type == 'Travel_Speed_Ratio' and ((volumeConstraint.Max-volumeConstraint.Min)*tSpeedFactor)+volumeConstraint.Min or math.abs(module.MODULE_STORAGE.statValues.currentSpeed)/30
				travelingSound.PlaybackSpeed = configFile.Sound_Database.Others.Traveling_Sound.Factor_Type == 'Travel_Speed_Ratio' and ((pitchConstraint.Max-pitchConstraint.Min)*tSpeedFactor)+pitchConstraint.Min or math.clamp(.5+math.abs(module.MODULE_STORAGE.statValues.currentSpeed)/30, pitchConstraint.Min, pitchConstraint.Max)
			end

			--Max limit--
			local absoluteDirection = carSpeed.Unit.Y > 0 and 1 or carSpeed.Unit.Y < 0 and -1 or 0
			local topRegFloor,bottomRegFloor = findRegisteredFloor(topFloor),findRegisteredFloor(bottomFloor)
			if (((topRegFloor and absoluteDirection == 1 and absoluteDirection*((topRegFloor.floorInstance.Level.Position.Y+1.5)-level.Position.Y) < 0) or (bottomRegFloor and absoluteDirection == -1 and absoluteDirection*((bottomRegFloor.floorInstance.Level.Position.Y-1.5)-level.Position.Y) < 0))) then
				if (not overshot) then
					initialDirection = absoluteDirection
					print('Elevator has over/undershot max limit')
					api:Fire('elevatorOvershoot')
					local isIdle = module.MODULE_STORAGE.statValues.currentSpeed < 0
					overshot = true
					if (not isIdle) then
						module.MODULE_STORAGE.sounds.Safety_Brake_Sound.PlaybackSpeed = module.MODULE_STORAGE.sounds.Safety_Brake_Sound:GetAttribute('newPitch')
						module.MODULE_STORAGE.sounds.Safety_Brake_Sound:Play()
						--safetyBrake()
					end
					moveBrake = true
					module.MODULE_STORAGE.statValues.currentSpeed = 0
					module.MODULE_STORAGE.statValues.moveValue = 0
					updateCore()
					local initialT = os.clock()
					--if (((topRegFloor and module.MODULE_STORAGE.statValues.moveValue == 1 and module.MODULE_STORAGE.statValues.moveValue*((topRegFloor.floorInstance.Level.Position.Y+1.5)-level.Position.Y) < 0) or (bottomRegFloor and module.MODULE_STORAGE.statValues.moveValue == -1 and module.MODULE_STORAGE.statValues.moveValue*((bottomRegFloor.floorInstance.Level.Position.Y-1.5)-level.Position.Y) < 0))) then
					--end
					if (not module.MODULE_STORAGE.statValues.inspection) then
						overshot = false
					end
					while ((os.clock()-initialT)/3 < 1 and (not overshot) and moveBrake and isDropKeyOnElevator() and (not module.MODULE_STORAGE.statValues.inspection)) do task.wait() end
					if ((os.clock()-initialT)/3 < 1) then return dtTime end
					releveling = false
					moveBrake = false
					safeCheckRelevel()
					return dtTime
				elseif (initialDirection == -absoluteDirection) then
					overshot = false
				end
			end

			if (module.MODULE_STORAGE.statValues.currentSpeed >= configFile.Movement.Travel_Speed+1 and (not oversped)) then
				oversped = true
				api:Fire('Overspeed_Trip')
				module.MODULE_STORAGE.sounds.Safety_Brake_Sound.PlaybackSpeed = module.MODULE_STORAGE.sounds.Safety_Brake_Sound:GetAttribute('originalPitch')
				safetyBrake()
				task.wait(2)
				if (isDropKeyOnElevator() and (not module.MODULE_STORAGE.statValues.inspection)) then
					moveBrake = false
					relevel()
				end
				oversped = false
			end

			if (lastPlatformPosition ~= platform.Position) then
				lastPlatformPosition = platform.Position
				updateFloor()
			end

			return dtTime,carSpeed.Unit.Y > 0 and 1 or carSpeed.Unit.Y < 0 and -1 or 0
		end
		updateFloor()

		function checkDoorStates(state, params)
			local thisFloor = findFloor(module.MODULE_STORAGE.statValues.rawFloor)
			local dontRequireAll = params and params.dontRequireAll or false
			local onlyPresentDoors = params and params.onlyPresentDoors or false
			local isAllStates = true
			for i,v in next,pluginModules_INTERNAL.Storage.CONTENT:getContentInBranch('masterDoorData') do
				if (not dontRequireAll) and v.state ~= state and (not onlyPresentDoors and true or thisFloor:FindFirstChild(`{v.side == '' and '' or `{v.side}_`}Doors`)) then
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
		end

		function setDoorState(side, state)
			if (not pluginModules_INTERNAL.Storage.CONTENT:getContentInBranch('masterDoorData')[side]) then return assert(_V..': Get Door State function with argument '..tostring(side)..' set error: Index not found in door states dictionary') end
			pluginModules_INTERNAL.Storage.CONTENT:getContentInBranch('masterDoorData')[side].state = state
			task.spawn(updateCore)
		end

		function setDirection(floor, forceDirection)
			if (forceDirection == 'N') then
				module.MODULE_STORAGE.statValues.queueDirection = forceDirection
				module.MODULE_STORAGE.statValues.arrowDirection = forceDirection
				preDirection = forceDirection
				task.spawn(updateCore)
				return
			end
			if (floor == topFloor) then
				module.MODULE_STORAGE.statValues.queueDirection = 'D'
				module.MODULE_STORAGE.statValues.arrowDirection = module.MODULE_STORAGE.statValues.queueDirection
				preDirection = module.MODULE_STORAGE.statValues.queueDirection
				task.spawn(updateCore)
				return
			elseif (floor == bottomFloor) then
				module.MODULE_STORAGE.statValues.queueDirection = 'U'
				module.MODULE_STORAGE.statValues.arrowDirection = module.MODULE_STORAGE.statValues.queueDirection
				preDirection = module.MODULE_STORAGE.statValues.queueDirection
				task.spawn(updateCore)
				return
			end
			if (forceDirection) then
				module.MODULE_STORAGE.statValues.queueDirection = forceDirection
				module.MODULE_STORAGE.statValues.arrowDirection = forceDirection
				preDirection = forceDirection
				task.spawn(updateCore)
				return
			end
			if (#module.MODULE_STORAGE.queue <= 0 or not floor) and (module.MODULE_STORAGE.statValues.rawFloor ~= topFloor and module.MODULE_STORAGE.statValues.rawFloor ~= bottomFloor) then
				module.MODULE_STORAGE.statValues.queueDirection = 'N'
				module.MODULE_STORAGE.statValues.arrowDirection = module.MODULE_STORAGE.statValues.queueDirection
				preDirection = module.MODULE_STORAGE.statValues.queueDirection
				task.spawn(updateCore)
				return
			end
			if (not module.MODULE_STORAGE.queue[1]) then return end
			if (module.MODULE_STORAGE.queue[1] > floor) then
				module.MODULE_STORAGE.statValues.queueDirection = 'U'
				module.MODULE_STORAGE.statValues.arrowDirection = module.MODULE_STORAGE.statValues.queueDirection
				preDirection = module.MODULE_STORAGE.statValues.queueDirection
				task.spawn(updateCore)
				return
			elseif (module.MODULE_STORAGE.queue[1] < floor) then
				module.MODULE_STORAGE.statValues.queueDirection = 'D'
				module.MODULE_STORAGE.statValues.arrowDirection = module.MODULE_STORAGE.statValues.queueDirection
				preDirection = module.MODULE_STORAGE.statValues.queueDirection
				task.spawn(updateCore)
				return
			end
		end

		local preparingParking = false
		local function parkTimer()
			if (not preparingParking) then
				task.spawn(function()
					if (configFile.Movement.Parking_Config.Enable and module.MODULE_STORAGE.statValues.rawFloor ~= configFile.Movement.Parking_Config.Park_Floor) then
						preparingParking = true
						local startTime = os.clock()
						while (os.clock()-startTime <= configFile.Movement.Parking_Config.Idle_Time) do
							task.wait(.5)
							if (module.MODULE_STORAGE.statValues.moveValue ~= 0 or (not checkDoorStates('Closed')) or (module.MODULE_STORAGE.statValues.fireService or checkIndependentService() or module.MODULE_STORAGE.statValues.inspection or outOfService)) then preparingParking = false return end
						end
						preparingParking = false
						if (not checkDoorStates('Closed')) then
							local connections = {}
							for i,v in pairs(doorStateValues) do
								connections[v] = v.Value:GetPropertyChangedSignal('Value'):Connect(function()
									if (not checkDoorStates('Closed')) then return end
									for i,v in pairs(connections) do
										v:Disconnect()
									end
									elevatorRun(configFile.Movement.Parking_Config.Park_Floor, true)
								end)
							end
						else
							elevatorRun(configFile.Movement.Parking_Config.Park_Floor, true)
						end
					end
				end)
			end
		end

		function bounceStop(bypass)

			local isEnabled = configFile.Movement.Bounce_Stop_Config.Enable or bypass

			if (isEnabled) then
				task.spawn(function()
					bouncing = true
					if (configFile.Movement.Bounce_Stop_Config.Stop_Sound.Enable) then
						local sound = addSound(platform, 'Bounce_Stop', configFile.Movement.Bounce_Stop_Config.Stop_Sound, false, true)
						sound.PlayOnRemove = true
						sound:Destroy()
					end
					local startTime = os.clock()
					local lastSpeed = module.MODULE_STORAGE.statValues.currentSpeed
					local div = 1
					local checked = false
					local min = .03
					local previousValue = module.MODULE_STORAGE.statValues.moveValue ~= 0 and module.MODULE_STORAGE.statValues.moveValue or 1
					preDooring = true
					while (bouncing) do

						updateCore()
						module.MODULE_STORAGE.statValues.moveValue = 1
						module.MODULE_STORAGE.statValues.currentSpeed = previousValue*(((math.sin(math.abs(os.clock()-startTime)*25))/div)*configFile.Movement.Bounce_Stop_Config.Amount)
						if (module.MODULE_STORAGE.statValues.currentSpeed ~= lastSpeed) then
							local diff = math.abs(lastSpeed-module.MODULE_STORAGE.statValues.currentSpeed)
							lastSpeed = module.MODULE_STORAGE.statValues.currentSpeed
							if (diff <= min and (not checked)) then
								checked = true
								div += 1/configFile.Movement.Bounce_Stop_Config.Times
							elseif (diff >= min) then
								checked = false
							end
							if (math.abs(lastSpeed) <= .005) then
								bouncing = false
							end
						end
						if (stopElevator or (not isDropKeyOnElevator()) or moveBrake) then
							break
						end

					end
					module.MODULE_STORAGE.statValues.moveValue = 0
					module.MODULE_STORAGE.statValues.currentSpeed = 0
					module.MODULE_STORAGE.statValues.leveling = false
					preDooring = false
					task.spawn(updateCore)
					--setDirection(module.MODULE_STORAGE.statValues.rawFloor)
				end)
			end
			return isEnabled

		end

		function removeAllCalls()
			for index,floor in pairs(registeredFloors) do
				removeCall(floor.floorNumber)
				pcall(function()
					resetLanterns(floor.floorNumber)
					resetButtons(floor.floorNumber)
				end)
			end
		end

		function safetyBrake()
			task.spawn(function()
				if (safetyBraking) then return end
				print(string.format('Elevator %s has safety broke!', elevator:GetFullName()))
				outputElevMessage(`Elevator has safety broke!`, 'critical')
				removeAllCalls()
				safetyBraking = true
				stopping = false
				releveling = false
				inspectionMoveDebounce = false
				isMoving = false
				module.MODULE_STORAGE.statValues.leveling = true
				module.MODULE_STORAGE.statValues.arrowDirection = 'N'
				for i,v in pairs(pluginModules_INTERNAL.Storage.CONTENT:getContentInBranch('masterDoorData')) do
					v.nudging = false
				end
				module.MODULE_STORAGE.statValues.nudging = false
				module.MODULE_STORAGE.statValues.queueDirection = 'N'
				module.MODULE_STORAGE.statValues.arrowDirection = module.MODULE_STORAGE.statValues.queueDirection
				preChimeFloor = nil
				lock = false
				local speed = module.MODULE_STORAGE.statValues.currentSpeed
				if (speed > 0) then
					module.MODULE_STORAGE.sounds.Safety_Brake_Sound:Play()
					module.MODULE_STORAGE.sounds.Safety_Brake_Sound.Volume = .75+speed/2
				end
				api:Fire('onSafetyBrake')
				local decelTime = getAccelerationTime(speed, 0, .85)
				local startTime = os.clock()
				while ((os.clock()-startTime)/decelTime < 1) do
					updateCore()
					module.MODULE_STORAGE.statValues.currentSpeed = lerp(speed, 0, (os.clock()-startTime)/decelTime)
				end
				module.MODULE_STORAGE.statValues.currentSpeed = 0
				module.MODULE_STORAGE.statValues.moveValue = 0
				module.MODULE_STORAGE.statValues.moveDirection = 'N'
				setDirection(module.MODULE_STORAGE.statValues.rawFloor, 'N')
				preDooring = false
				overshot = false
				module.MODULE_STORAGE.statValues.leveling = false
				safetyBraking = false
				updateCore()
				removePlayerWelds()
				if (speed > 0) then
					--bounceStop(false)
				end
			end)
		end

		local function checkObstruction(parts)

			for i,p in pairs(parts) do
				local human,root = p.Name == 'HumanoidRootPart' and p,(p.Parent:FindFirstChildOfClass('Humanoid') or p.Parent.Parent:FindFirstChildOfClass('Humanoid'))
				if (human and root) then
					return true
				end
			end
			return false

		end

		local function handleNudgeReclose(doorData)

			if (doorData.nudging) then
				if (doorData.state ~= 'Open' and doorData.state ~= 'Closed') then
					local connection
					connection = doorData.Door_State_Value:GetPropertyChangedSignal('Value'):Connect(function()
						if (doorData.Door_State_Value.Value == 'Open') then
							if (doorData.Is_Obstructed) then
								return handleNudgeReclose(doorData)
							end
							connection:Disconnect()
							local isCompleted = conditionalStepWait(.5, function() return {doorData.state ~= 'Open'} end)
							if (not isCompleted) then return end
							runDoorClose(module.MODULE_STORAGE.statValues.rawFloor, doorData.Side..'Doors', true)
						elseif (doorData.Door_State_Value == 'Closed') then
							connection:Disconnect()
						end
					end)
				elseif (not doorData.Is_Obstructed) then
					local isCompleted = conditionalStepWait(.5, function() return {doorData.state ~= 'Open'} end)
					if (not isCompleted) then return end
					return runDoorClose(module.MODULE_STORAGE.statValues.rawFloor, doorData.Side..'Doors', true)
				elseif (doorData.Region_Data.Is_Enabled and (not checkIndependentService()) and (not module.MODULE_STORAGE.statValues.fireService)) then
					local region = doorData.Region_Data.Create_Region()
					local parts = region:FindPartsInRegion3WithWhiteList(humans, 1)
					local isObstructedByHuman = checkObstruction(parts)

					local lastObstructed = doorData.Is_Obstructed
					doorData.Is_Obstructed = isObstructedByHuman
					if (lastObstructed ~= doorData.Is_Obstructed and doorData.Region_Data.Door_Obstruction_Signal_Audio) then
						if (doorData.Is_Obstructed) then
							if (configFile.Sound_Database.Others.Door_Obstruction_Signal.Enable) then
								doorData.Region_Data.Door_Obstruction_Signal_Audio.Playing = true
							end
						else
							doorData.Region_Data.Door_Obstruction_Signal_Audio.Playing = false
						end
					end
					if (isObstructedByHuman) then
						doorData.doorTimerTick = os.clock()
						if (doorData.state == 'Closing' and (((doorData.nudging and configFile.Doors.Reopen_When_Nudge_Obstruction)) or (not doorData.nudging))) then
							runDoorOpen(module.MODULE_STORAGE.statValues.rawFloor, doorData.Side, doorData.nudging)
						end
					end
				end
				task.wait()
				handleNudgeReclose(doorData)
			end

		end

		local doorSensorObstructions = {}
		function runDoorOpen(floor: number, side: string, bypassNudge: boolean?)
			local function runDoor(data)
				local ran,res = pcall(function()
					local startingState = data.state
					local thisFloor = findFloor(floor)
					local function checkDoor()
						for i,v in pairs(thisFloor:GetChildren()) do
							local side = string.split(string.split(v.Name,'Doors')[1],'_')[1]
							if (side == data.side and collectionService:HasTag(v, 'IsInUse')) then return v end
						end
						return
					end
					if (getFloorDistance(module.MODULE_STORAGE.statValues.rawFloor) > .35 or (lock and (not preDooring)) or outOfService or module.MODULE_STORAGE.statValues.inspection --[[or module.MODULE_STORAGE.statValues.fireService]]) then return print(`{data.side} doors unable to open`) end
					if ((not data.doorSet) or checkDoor() or collectionService:HasTag(data.doorSet, 'IsInUse')) then return nil,print(`{data.side} Doors are already unlocked by door key!`) end
					if ((startingState ~= 'Closed' and startingState ~= 'Closing' and startingState ~= 'Stopped') or ((not car:FindFirstChild(`{data.side == '' and '' or `{data.side}_`}Doors`)) or (not thisFloor:FindFirstChild(`{data.side == '' and '' or `{data.side}_`}Doors`)))) then return end
					if (data.nudging and (not bypassNudge)) then return end

					if (startingState == 'Closing') then task.wait() end

					local function onOpened()
						task.spawn(function()
							if (startingState == 'Closed' and module.MODULE_STORAGE.statValues.queueDirection ~= 'N' and voiceConfig.Settings.Directional_Announcements) then
								local clip = voiceConfig.Settings.Directional_Announcements[`{module.MODULE_STORAGE.statValues.queueDirection == 'U' and 'Up' or module.MODULE_STORAGE.statValues.queueDirection == 'D' and 'Down'}_Announcement`]
								if (not clip) then return end
								if (clip.Enabled) then
									playVoiceSequenceProtocolWithQueue(clip.Sequence, false)
								end
							end
						end)
						local params = OverlapParams.new()
						params.FilterType = Enum.RaycastFilterType.Include
						data.doorTimerTick = os.clock()
						api:Fire('doorStateChange', {state=data.state,side=data.side,floor=floor})
						if (startingState == 'Closed') then data.nudgeTimerTick = os.clock() end
						local startRelevelTick = os.clock()
						local isObstructed = data.isObstructed
						while ((os.clock()-data.doorTimerTick)/configFile.Doors.Door_Timer <= 1 and data.state == 'Open') do
							if (os.clock()-startRelevelTick >= .25 and getFloorDistance(module.MODULE_STORAGE.statValues.currentFloor) >= configFile.Movement.Relevel_Tolerance and (not releveling)) then
								preDooring = true
								startRelevelTick = os.clock()
								task.spawn(relevel)
							end

							params.FilterDescendantsInstances = _G.ElevatorSensorHumanoids
							local parts = workspace:GetPartBoundsInBox(data.doorSensorPart.CFrame, data.doorSensorPart.Size, params)
							data.isObstructed = #parts > 0
							if (data.isObstructed or checkIndependentService() or module.MODULE_STORAGE.statValues.fireService or configFile.Doors.Manual_Door_Controls.Enable_Close or data.doorHold) then
								data.doorTimerTick = os.clock()
							end
							if (checkIndependentService() or module.MODULE_STORAGE.statValues.fireService or configFile.Doors.Manual_Door_Controls.Enable_Close) then
								data.nudgeTimerTick = os.clock()
							end
							if (isObstructed ~= data.isObstructed) then
								data.doorSensorPart.Obstruction_Signal.Playing = data.isObstructed and configFile.Sound_Database.Others.Door_Obstruction_Signal.Enable
								api:Fire('doorObstructionStateChanged', {state=data.isObstructed,side=data.side})
							end
							isObstructed = data.isObstructed

							if ((os.clock()-data.nudgeTimerTick)/configFile.Doors.Nudge_Timer >= 1) then
								if (not data.nudging) then
									data.nudging = true
									module.MODULE_STORAGE.sounds.Nudge_Buzzer:Play()
								end
								task.spawn(runDoorClose, floor, data.side, true)
							end
							HEARTBEAT:Wait()
						end
						if (data.state == 'Open' and (not data.nudging) and (not checkIndependentService()) and (not module.MODULE_STORAGE.statValues.fireService) and (not configFile.Doors.Manual_Door_Controls.Enable_Close)) then
							task.spawn(runDoorClose, floor, data.side, data.nudging)
						end
					end

					task.spawn(function()
						if (configFile.Doors.Custom_Door_Operator_Config.Inner.Opening.Enable and configFile.Doors.Custom_Door_Operator_Config.Outer.Opening.Enable) then
							data:Open(floor, onOpened)
						else
							data:LegacyOpen(floor, onOpened)
						end
						api:Fire('onDoorOpen', {side=data.side,floor=floor})
						if (configFile.Sound_Database.Voice_Config.Enabled and voiceConfig.Settings.Door_Announcements.Open_Announcement.Enabled) then
							playVoiceSequenceProtocolWithQueue(voiceConfig.Settings.Door_Announcements.Open_Announcement.Sequence, false)
						end
						data.isObstructed = false
						data.doorSensorPart.Obstruction_Signal:Stop()
						api:Fire('doorObstructionStateChanged', {state=data.isObstructed,side=data.side})
					end)
				end)
				if (not ran) then return debugWarn(`Error occured whilst operating {side} doors :: {res}\n{debug.traceback()}`) end
			end

			local data = pluginModules_INTERNAL.Storage.CONTENT:get('masterDoorData', side)
			if (((not data) and side ~= 'ALL') or (stopElevator)) then return debugWarn(`Error occured whilst operating {side} doors :: No data found halting all functions & resetting states\n{debug.traceback()}`) end
			--if (isLevel() == false) then return task.spawn(relevel) end
			if (side ~= 'ALL') then return task.spawn(runDoor, data) end
			for i,v in next,pluginModules_INTERNAL.Storage.CONTENT:getContentInBranch('masterDoorData') do
				task.spawn(runDoor, v)
			end
		end

		function runDoorClose(floor: number, side: string, nudge: boolean?)
			local function runDoor(data)
				local ran,res = pcall(function()
					local startingState = data.state
					local thisFloor = findFloor(floor)
					if ((startingState ~= 'Open' and startingState ~= 'Stopped') and ((not checkIndependentService()) and ((not module.MODULE_STORAGE.statValues.fireService) or startingState == 'Closed')) or ((not car:FindFirstChild(`{data.side == '' and '' or `{data.side}_`}Doors`)) or (not thisFloor:FindFirstChild(`{data.side == '' and '' or `{data.side}_`}Doors`)))) then return end
					api:Fire('onDoorClose', {side=data.side,nudge=nudge,floor=floor})

					task.wait()

					local function onClosed()
						data.valueInstances.doorSpeedValue.Value = 0
						api:Fire('onDoorClosed', {side=data.side,nudge=nudge,floor=floor})

						local sensorPart: Part = data.doorSensorPart
						data.nudging = false
						data.isObstructed = false
						data.doorHold = false
						sensorPart.Obstruction_Signal.Playing = false

						if (not module.MODULE_STORAGE.statValues.fireService) then
							local function check()
								for _,v in pairs(pluginModules_INTERNAL.Storage.CONTENT:getContentInBranch('masterDoorData')) do
									if (v.side ~= data.side and v.nudging) then return false end
								end
								return true
							end
							if (check()) then module.MODULE_STORAGE.sounds.Nudge_Buzzer:Stop() end
						end

						if (not checkDoorStates('Closed')) then return end
						api:Fire('doorStateChange', {state=data.state,side=data.side,floor=floor})
						--Move the elevator
						parkTimer()
						local directionNum = module.MODULE_STORAGE.statValues.queueDirection == 'U' and 1 or module.MODULE_STORAGE.statValues.queueDirection == 'D' and -1 or 0
						local nextCall = checkCallInDirection(module.MODULE_STORAGE.statValues.rawFloor,directionNum) or module.MODULE_STORAGE.queue[1]
						local regFloor = findRegisteredFloor(module.MODULE_STORAGE.statValues.rawFloor)
						local function checkRun(call: any)
							if (not call) then return end
							local dir = call.directions[1]
							local regFloor = findRegisteredFloor(call.call)
							local index = table.find(regFloor.exteriorCallDirections,dir)
							if (index) then
								task.spawn(function()
									module.MODULE_STORAGE.statValues.queueDirection = dir == 1 and 'U' or dir == -1 and 'D' or 'N'
									module.MODULE_STORAGE.statValues.arrowDirection = module.MODULE_STORAGE.statValues.queueDirection
									api:Fire('onCallRespond', {floor=floor,direction=module.MODULE_STORAGE.statValues.queueDirection})
									task.spawn(updateCore)
									task.spawn(runDoorOpen,module.MODULE_STORAGE.statValues.rawFloor,'ALL')
									doLanterns(module.MODULE_STORAGE.statValues.rawFloor,configFile.Color_Database.Lanterns.Active_On_Exterior_Call,configFile.Color_Database.Lanterns.Active_After_Door_Open,dir)
									runChime(module.MODULE_STORAGE.statValues.rawFloor,configFile.Sound_Database.Chime_Events.Exterior_Call_Only,configFile.Sound_Database.Chime_Events.After_Open,dir)
									removeCall(call.call,dir)
								end)
							end
						end
						task.spawn(updateCore)
						if (not regFloor) then return end
						local index = table.find(regFloor.exteriorCallDirections,directionNum)
						if (index) then
							table.remove(regFloor.exteriorCallDirections,index)
						end
						if (module.MODULE_STORAGE.statValues.moveValue == 0 and nextCall and nextCall.call ~= module.MODULE_STORAGE.statValues.rawFloor) then
							local callDirection = nextCall.call > module.MODULE_STORAGE.statValues.rawFloor and 'U' or nextCall.call < module.MODULE_STORAGE.statValues.rawFloor and 'D' or 'N'
							if (callDirection ~= module.MODULE_STORAGE.statValues.queueDirection) then
								module.MODULE_STORAGE.statValues.queueDirection = 'N'
								task.spawn(updateCore)
								local hasCompleted = conditionalStepWait(1, function() return {module.MODULE_STORAGE.statValues.moveValue ~= 0} end)
								if (not hasCompleted) then return end
							end
							task.spawn(elevatorRun,nextCall.call,false)
						elseif (nextCall and nextCall.call == module.MODULE_STORAGE.statValues.rawFloor) then
							local hasCompleted = conditionalStepWait(1, function() return {module.MODULE_STORAGE.statValues.moveValue ~= 0} end)
							if (not hasCompleted) then return end
							checkRun(nextCall)
						else
							nextCall = checkCallInDirection(module.MODULE_STORAGE.statValues.rawFloor) or module.MODULE_STORAGE.queue[1]
							if (not nextCall) then return end
							local queueDir = nextCall.call > module.MODULE_STORAGE.statValues.rawFloor and 'U' or nextCall.call < module.MODULE_STORAGE.statValues.rawFloor and 'D' or 'N'
							if (queueDir ~= module.MODULE_STORAGE.statValues.queueDirection) then
								local hasCompleted = conditionalStepWait(1, function() return {module.MODULE_STORAGE.statValues.moveValue ~= 0} end)
								if (not hasCompleted) then return end
							end
							checkRun(nextCall)
						end
					end

					task.spawn(function()
						if ((not data.nudging) and nudge) then
							data.nudging = true
							module.MODULE_STORAGE.sounds.Nudge_Buzzer:Play()
						end
						for i,v in pairs(configFile.Color_Database.Lanterns) do
							if ((i == 'Interior' or i == 'Exterior') and (not configFile.Color_Database.Lanterns[i].Reset_After_Door_Close)) then
								resetLanterns(floor, {i})
							end
						end
						if (nudge) then
							if (configFile.Sound_Database.Voice_Config.Enabled and voiceConfig.Settings.Door_Announcements.Nudge_Announcement.Enabled) then
								playVoiceSequenceProtocolWithQueue(voiceConfig.Settings.Door_Announcements.Nudge_Announcement.Sequence, false)
							end
						else
							if (configFile.Sound_Database.Voice_Config.Enabled and voiceConfig.Settings.Door_Announcements.Close_Announcement.Enabled) then
								playVoiceSequenceProtocolWithQueue(voiceConfig.Settings.Door_Announcements.Close_Announcement.Sequence, false)
							end
						end
						if (configFile.Doors.Custom_Door_Operator_Config.Inner.Closing.Enable and configFile.Doors.Custom_Door_Operator_Config.Outer.Closing.Enable) then
							data:Close(floor, nudge, onClosed)
						else
							data:LegacyClose(floor, nudge, onClosed)
						end
					end)
					data.LanternsReset:Once(function()
						if (#module.MODULE_STORAGE.queue <= 0) then
							setDirection(module.MODULE_STORAGE.statValues.rawFloor, 'N')
						end
						if (configFile.Color_Database.Lanterns.Interior.Reset_After_Door_Close) then
							resetLanterns(module.MODULE_STORAGE.statValues.rawFloor, {'Interior'})
						end
						if (configFile.Color_Database.Lanterns.Exterior.Reset_After_Door_Close) then
							resetLanterns(module.MODULE_STORAGE.statValues.rawFloor, {'Exterior'})
						end
					end)
					task.spawn(function()
						local startingState = data.state
						--if (configFile.Sound_Database.Voice_Config.Options and configFile.Sound_Database.Voice_Config.Options.Door_Announcements.Close_Announcement.Enabled) then
						--	--playVoiceSequenceProtocolWithQueue(configFile.Sound_Database.Voice_Config.Options.Door_Announcements.Close_Announcement.Sequence, false)
						--end
						local isObstructed = data.isObstructed
						local sensorPart: Part = data.doorSensorPart
						local params = OverlapParams.new()
						params.FilterType = Enum.RaycastFilterType.Include
						while (data.state == 'Closing') do
							params.FilterDescendantsInstances = _G.ElevatorSensorHumanoids
							local parts = workspace:GetPartBoundsInBox(sensorPart.CFrame, sensorPart.Size, params)
							data.isObstructed = #parts > 0
							if (isObstructed ~= data.isObstructed and not (checkIndependentService() or module.MODULE_STORAGE.statValues.fireService or configFile.Doors.Manual_Door_Controls.Enable_Close) and ((data.nudging and configFile.Doors.Reopen_When_Nudge_Obstruction) or (not data.nudging))) then
								if (data.isObstructed) then task.spawn(runDoorOpen, floor, side, false) end
								sensorPart.Obstruction_Signal.Playing = data.isObstructed and configFile.Sound_Database.Others.Door_Obstruction_Signal.Enable
								api:Fire('doorObstructionStateChanged', {state=data.isObstructed,side=data.side})
							end
							isObstructed = data.isObstructed
							
							if (checkIndependentService() or module.MODULE_STORAGE.statValues.fireService or configFile.Doors.Manual_Door_Controls.Enable_Close) then
								data.nudgeTimerTick = os.clock()
							end

							if ((os.clock()-data.nudgeTimerTick)/configFile.Doors.Nudge_Timer >= 1) then
								if (not data.nudging) then
									data.nudging = true
									module.MODULE_STORAGE.sounds.Nudge_Buzzer:Play()
								end
							end
							HEARTBEAT:Wait()
						end
					end)
				end)
				if (not ran) then return debugWarn(`Error occured whilst operating {side} doors :: {res}\n{debug.traceback()}`) end
			end

			local data = pluginModules_INTERNAL.Storage.CONTENT:get('masterDoorData', side)
			if (((not data) and side ~= 'ALL') or (stopElevator)) then return debugWarn(`Error occured whilst operating {side} doors :: No data found halting all functions & resetting states\n{debug.traceback()}`) end
			if (side ~= 'ALL') then return task.spawn(runDoor, data) end
			for i,v in next,pluginModules_INTERNAL.Storage.CONTENT:getContentInBranch('masterDoorData') do
				task.spawn(runDoor, v)
			end
			task.spawn(updateCore)
		end

		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		function doPlayerWeld()
			params.FilterDescendantsInstances = _G.ElevatorSensorHumanoids
			local partsInBounds = workspace:GetPartBoundsInBox(carRegion.CFrame, carRegion.Size, params)
			for i,v in pairs(partsInBounds) do
				local root: BasePart,human: Humanoid = findAncestor(v.Parent, 'HumanoidRootPart'),(v.Parent:FindFirstChildOfClass('Humanoid') or v.Parent.Parent:FindFirstChildOfClass('Humanoid'))
				if (root and human and (not root:FindFirstChild('Welded_By_Elevator')) and (not playerWeldData[human])) then

					if (configFile.Movement.Disable_Jumping and config.Movement.Movement_Type ~= 1) then
						human:SetAttribute('jumpPower', human.JumpPower)
						human:SetAttribute('jumpHeight', human.JumpHeight)
						human.JumpHeight = 0
						human.JumpPower = 0
					end

					if (configFile.Movement.Weld_On_Move and (not configFile.Movement.Use_New_Welding)) then
						local weld = Instance.new('Weld')
						weld.Name = root.Parent.Name
						weld.Part0 = root
						weld.C0 = CFrame.new()
						weld.C1 = platform.CFrame:ToObjectSpace(root.CFrame)
						weld.Part1 = platform
						weld.Parent = playerWeldsFolder
						human.PlatformStand = true
						playerWeldData[human] = {
							root=root,
							weld
						}
					elseif (configFile.Movement.Use_New_Welding) then
						if config.Movement.Movement_Type ~= 1 then
							human:SetAttribute('jumpPower', human.JumpPower)
							human:SetAttribute('jumpHeight', human.JumpHeight)
							human.JumpHeight = 0
							human.JumpPower = 0
						end

						local folder: Folder = Instance.new('Folder')
						folder.Name = root.Parent.Name
						folder.Parent = playerWeldsFolder

						--Part0--
						local part0 = folder:FindFirstChild('Part0') or Instance.new('Part')
						part0.Name = 'Part0'
						part0.Size = Vector3.new(1, 1, 1)*.5
						part0.Transparency = 1
						part0.CFrame = platform.CFrame*CFrame.new(0, (root.CFrame.Position.Y-(platform.CFrame.Position.Y)), 0)
						part0.CanCollide = false
						part0.BrickColor = BrickColor.new('Lime green')
						part0.Parent = folder
						weldTogether(part0, platform, true)
						--Part1--
						local part1 = folder:FindFirstChild('Part1') or Instance.new('Part')
						part1.Name = 'Part1'
						part1.Size = Vector3.new(1, 1, 1)*.5
						part1.Transparency = 1
						part1.CFrame = part0.CFrame
						part1.CanCollide = false
						part1.BrickColor = BrickColor.new('Really blue')
						part1.Parent = folder
						--Hinge part--
						local part2 = folder:FindFirstChild('Part2') or Instance.new('Part')
						part2.Name = 'Part2'
						part2.Size = Vector3.new(1, 1, 1)*.5
						part2.Transparency = 1
						part2.CFrame = root.CFrame
						part2.CFrame = CFrame.lookAt(part2.CFrame.Position, part0.CFrame.Position)
						part2.CanCollide = false
						part2.BrickColor = BrickColor.new('Really blue')
						part2.Parent = folder

						part1.CFrame = CFrame.lookAt(part1.CFrame.Position, part2.CFrame.Position)*CFrame.Angles(0, math.rad(180), 0)

						local att0,att1,att2,att3,att4,att5 =
							(part0:FindFirstChild('Attachment0') or Instance.new('Attachment', part0)),
						(part1:FindFirstChild('Attachment1') or Instance.new('Attachment', part1)),
						(part1:FindFirstChild('Attachment2') or Instance.new('Attachment', part1)),
						(part2:FindFirstChild('Attachment3') or Instance.new('Attachment', part2)),
						(root:FindFirstChild('Attachment4') or Instance.new('Attachment', root)),
						(platform:FindFirstChild('Attachment5') or Instance.new('Attachment', platform))
						att0.Name = 'Attachment0'
						att1.Name = 'Attachment1'
						att2.Name = 'Attachment2'
						att3.Name = 'Attachment3'

						att0.Orientation = Vector3.new(0, 0, 1)*90
						att1.Orientation = att1.Orientation
						att2.Orientation = Vector3.new(0, 1, 0)*90
						att3.Orientation = att2.Orientation

						local ballSocket: BallSocketConstraint = (part1:FindFirstChild('BallSocket') or Instance.new('BallSocketConstraint', part1))
						ballSocket.Attachment0,ballSocket.Attachment1 = att3,att4
						local hinge: HingeConstraint = (part0:FindFirstChild('Hinge') or Instance.new('HingeConstraint', part0))
						hinge.Name = 'Hinge'
						hinge.Attachment0,hinge.Attachment1 = att0,att1
						local prismatic0: PrismaticConstraint = (part1:FindFirstChild('Prismatic0') or Instance.new('PrismaticConstraint', part1))
						prismatic0.Name = 'Prismatic0'
						prismatic0.Attachment0,prismatic0.Attachment1 = att2,att3
						local alignPos: AlignPosition = (part1:FindFirstChild('AlignPos') or Instance.new('AlignPosition', part1))
						alignPos.Attachment0,alignPos.Attachment1 = att0,att1
						alignPos.Name = 'AlignPos'
						alignPos.MaxForce = 1e-5
						alignPos.Responsiveness = 200
						alignPos.MaxVelocity = 1e-5
						alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment

						root:SetNetworkOwner(game.Players:GetPlayerFromCharacter(root.Parent))

						--local position: BodyPosition = (root:FindFirstChild('AlignPos') or Instance.new('BodyPosition', root))
						--position.Name = 'AlignPos'
						--position:SetAttribute('playerWeldHeight', (root.CFrame.Position.Y-platform.CFrame.Position.Y))
						--position.Position = platform.Position+Vector3.new(0, 1, 0)*position:GetAttribute('playerWeldHeight')
						--position.MaxForce = Vector3.new(0, 1, 0)*1e-5
						--position.D = 1

						playerWeldData[human] = {
							root=root,
							folder,
							att4,
							att5,
							position=position
						}

					end
					if (config.Movement.Weld_On_Move) then
						local val = Instance.new('ObjectValue')
						val.Name = 'Welded_By_Elevator'
						val.Value = elevator
						val.Parent = root
						human.Parent:SetAttribute('Is_On_Elevator', true)
						pcall(function()
							local charAnimate = human.Parent:FindFirstChild('Animate')
							if (charAnimate) then
								if (not idleAnimations[human]) then
									idleAnimations[human] = {}
								end
								local anims = {}
								local animSet = charAnimate:WaitForChild('idle')
								for i,v in pairs(animSet:GetChildren()) do
									if (v:IsA('Animation')) then
										local loadedAnim = human:LoadAnimation(v)
										if (not table.find(idleAnimations[human], loadedAnim)) then
											table.insert(idleAnimations[human], loadedAnim)
										end
									end
								end
								local anim = idleAnimations[human][math.random(1,#idleAnimations[human])]
								anim:Play()
							end
						end)
					end
				end
			end
		end
		function removePlayerWelds()
			for i,v in pairs(playerWeldData) do

				local human: Humanoid,root: BasePart = i,v.root
				if human and human.Parent then
					human.Parent:SetAttribute('Is_On_Elevator', nil)
				end
				if (configFile.Movement.Disable_Jumping and config.Movement.Movement_Type ~= 1) then
					human.JumpPower = human:GetAttribute('jumpPower')
					human.JumpHeight = human:GetAttribute('jumpHeight')
					human:SetAttribute('jumpPower', nil)
					human:SetAttribute('jumpHeight', nil)
				end
				if (root and root:FindFirstChild('Welded_By_Elevator')) then
					root.Welded_By_Elevator:Destroy()
				end
				if (idleAnimations[human]) then
					for i,v in pairs(idleAnimations[human]) do
						v:Stop()
					end
				end
				for _,n in pairs(v) do
					if (typeof(n) == 'Instance' and n ~= root) then
						n:Destroy()
					end
				end
				human.PlatformStand = false
				playerWeldData[i] = nil

			end
		end

		function doMotorSound()
			task.spawn(function()
				if module.MODULE_STORAGE.statValues.moveValue == 1 then
					module.MODULE_STORAGE.sounds.Motor_Start_Up:Play()
					module.MODULE_STORAGE.sounds.Motor_Run_Up:Stop()
					module.MODULE_STORAGE.sounds.Motor_Stop_Up:Stop()
					module.MODULE_STORAGE.sounds.Motor_Start_Down:Stop()
					module.MODULE_STORAGE.sounds.Motor_Run_Down:Stop()
					module.MODULE_STORAGE.sounds.Motor_Stop_Down:Stop()
					local function stop()
						module.MODULE_STORAGE.sounds.Motor_Start_Up:Stop()
						module.MODULE_STORAGE.sounds.Motor_Run_Up:Stop()
						module.MODULE_STORAGE.sounds.Motor_Stop_Up:Play()
						module.MODULE_STORAGE.sounds.Motor_Start_Down:Stop()
						module.MODULE_STORAGE.sounds.Motor_Run_Down:Stop()
						module.MODULE_STORAGE.sounds.Motor_Stop_Down:Stop()
					end
					local connect
					connect = levelingVal:GetPropertyChangedSignal('Value'):Connect(function()
						if (levelingVal.Value and not config.Movement.Motor_Stop_On_Open) then
							connect:Disconnect()
							stop()
						end
					end)
					local connect2
					connect2 = moveVal:GetPropertyChangedSignal('Value'):Connect(function()
						if (moveVal.Value == 0 and config.Movement.Motor_Stop_On_Open) then
							connect2:Disconnect()
							stop()
						end
					end)
					module.MODULE_STORAGE.sounds.Motor_Start_Up.Ended:Wait()
					if (module.MODULE_STORAGE.statValues.moveValue ~= 1 or module.MODULE_STORAGE.statValues.leveling) then connect:Disconnect() connect2:Disconnect() return end
					module.MODULE_STORAGE.sounds.Motor_Run_Up:Play()
				elseif module.MODULE_STORAGE.statValues.moveValue == -1 then
					module.MODULE_STORAGE.sounds.Motor_Start_Up:Stop()
					module.MODULE_STORAGE.sounds.Motor_Run_Up:Stop()
					module.MODULE_STORAGE.sounds.Motor_Stop_Up:Stop()
					module.MODULE_STORAGE.sounds.Motor_Start_Down:Play()
					module.MODULE_STORAGE.sounds.Motor_Run_Down:Stop()
					module.MODULE_STORAGE.sounds.Motor_Stop_Down:Stop()
					local function stop()
						module.MODULE_STORAGE.sounds.Motor_Start_Down:Stop()
						module.MODULE_STORAGE.sounds.Motor_Run_Down:Stop()
						module.MODULE_STORAGE.sounds.Motor_Stop_Down:Play()
						module.MODULE_STORAGE.sounds.Motor_Start_Up:Stop()
						module.MODULE_STORAGE.sounds.Motor_Run_Up:Stop()
						module.MODULE_STORAGE.sounds.Motor_Stop_Up:Stop()
					end
					local connect
					connect = levelingVal:GetPropertyChangedSignal('Value'):Connect(function()
						if (levelingVal.Value and not config.Movement.Motor_Stop_On_Open) then
							connect:Disconnect()
							stop()
						end
					end)
					local connect2
					connect2 = moveVal:GetPropertyChangedSignal('Value'):Connect(function()
						if (moveVal.Value == 0 and config.Movement.Motor_Stop_On_Open) then
							connect2:Disconnect()
							stop()
						end
					end)
					module.MODULE_STORAGE.sounds.Motor_Start_Down.Ended:Wait()
					if (module.MODULE_STORAGE.statValues.moveValue ~= -1 or module.MODULE_STORAGE.statValues.leveling) then connect:Disconnect() connect2:Disconnect() return end
					module.MODULE_STORAGE.sounds.Motor_Run_Down:Play()
				end
			end)
		end

		function relevel()
			local ran,msg = pcall(function()
				if (getFloorDistance(module.MODULE_STORAGE.statValues.rawFloor) < configFile.Movement.Relevel_Tolerance or module.MODULE_STORAGE.statValues.inspection or releveling or moveBrake or (not isDropKeyOnElevator()) or stopElevator) then return end
				print(`Releveling on {module.MODULE_STORAGE.statValues.rawFloor}`)
				outputElevMessage(`Releveling on floor {module.MODULE_STORAGE.statValues.rawFloor}`, 'debug')
				releveling = true
				isMoving = true
				local releveled = false
				local relevelingFloor = module.MODULE_STORAGE.statValues.rawFloor
				local landingLevel = findFloor(relevelingFloor):FindFirstChild('Level')
				module.MODULE_STORAGE.statValues.leveling = false
				local function checkPosition()
					if (level.Position.Y > landingLevel.Position.Y) then
						module.MODULE_STORAGE.statValues.moveValue = -1
						module.MODULE_STORAGE.statValues.arrowDirection = 'D'
						preDirection = 'D'
						module.MODULE_STORAGE.statValues.direction = 'D'
					elseif (level.Position.Y < landingLevel.Position.Y) then
						module.MODULE_STORAGE.statValues.moveValue = 1
						module.MODULE_STORAGE.statValues.arrowDirection = 'U'
						preDirection = 'U'
						module.MODULE_STORAGE.statValues.direction = 'U'
					end
				end

				local function getPastDirection()
					return level.Position.Y > landingLevel.Position.Y and -1 or level.Position.Y < landingLevel.Position.Y and 1 or 0
				end
				if (getFloorDistance(module.MODULE_STORAGE.statValues.rawFloor) > 1.5) then
					doPlayerWeld()
				end
				local lastSpeed = module.MODULE_STORAGE.statValues.currentSpeed
				--checkPosition()
				doMotorSound()
				updateCore()
				local lastDirection = module.MODULE_STORAGE.statValues.moveValue
				local lastPosition = platform.Position
				local relevelingSpeed = math.clamp(configFile.Movement.Releveling_Speed, .1, configFile.Movement.Travel_Speed/2)
				local stopping = false

				local previousDistanceChecked = false
				local reachedLevelingSpeed = false

				api:Fire('onRelevelStart', {direction=getPastDirection()})
				local thisLevelingStage = 1

				local pastDirection = getPastDirection()
				--module.MODULE_STORAGE.statValues.moveValue = pastDirection
				task.spawn(updateCore)

				while (not releveled) do

					if (moveBrake or module.MODULE_STORAGE.statValues.inspection or overshot or stopElevator or (not isDropKeyOnElevator()) or ((not checkDoorStates('Closed')) and (not preDooring))) then
						if (not safetyBraking) then
							module.MODULE_STORAGE.statValues.currentSpeed = 0
							module.MODULE_STORAGE.statValues.moveValue = 0
							module.MODULE_STORAGE.statValues.moveDirection = 'N'
							lock = false
							setDirection(module.MODULE_STORAGE.statValues.rawFloor, 'N')
							preDooring = false
							releveling = false
							overshot = false
							module.MODULE_STORAGE.statValues.leveling = false
							preChimeFloor = nil
							safetyBraking = false
							removePlayerWelds()
							updateCore()
						end
						return
					end

					local lastPos = level.Position.Y
					local diff = math.abs(lastPos-level.Position.Y)
					local pastDirection = getPastDirection()
					local distanceFromFloor = getFloorDistance(relevelingFloor, true)
					local directionString = module.MODULE_STORAGE.statValues.moveValue == 1 and '' or module.MODULE_STORAGE.statValues.moveValue == -1 and 'Down_' or ''
					local directionString2 = module.MODULE_STORAGE.statValues.moveValue == 1 and 'Up' or module.MODULE_STORAGE.statValues.moveValue == -1 and 'Down' or 'Up'
					if (module.MODULE_STORAGE.statValues.currentSpeed <= 0) then
						module.MODULE_STORAGE.statValues.moveValue = pastDirection
					end

					local deltaTime = os.clock()-lastTick
					local elevMoveDirection = (platform.Position-lastPosition).Unit.Y
					elevMoveDirection = elevMoveDirection > 0 and 1 or elevMoveDirection < 0 and -1 or 0

					if (getPastDirection() == module.MODULE_STORAGE.statValues.moveValue and distanceFromFloor <= (math.abs(module.MODULE_STORAGE.statValues.currentSpeed)*(configFile.Sensors[string.format('%s_Level_Offset', directionString2)]*configFile.Movement.Level_Offset_Ratio))) then
						if (not previousDistanceChecked) then
							previousDistanceChecked = true
						end
					else
						--previousDistanceChecked = false
					end

					if (not reachedLevelingSpeed) then
						if (previousDistanceChecked) then
							if (not stopping) then
								stopping = true
								elevatorProcessRunStop(module.MODULE_STORAGE.statValues.rawFloor)
								releveled = distanceFromFloor <= .005
							end
						elseif (getPastDirection() ~= module.MODULE_STORAGE.statValues.moveValue or distanceFromFloor >= (math.abs(module.MODULE_STORAGE.statValues.currentSpeed)*((configFile.Sensors[string.format('%s_Level_Offset', directionString2)]*configFile.Movement.Level_Offset_Ratio)+.5*module.MODULE_STORAGE.statValues.moveValue))) then
							module.MODULE_STORAGE.statValues.currentSpeed += (getPastDirection() ~= module.MODULE_STORAGE.statValues.moveValue and 1.35 or 1)*module.MODULE_STORAGE.statValues.moveValue*getPastDirection()*configFile.Movement[string.format('%sAcceleration', directionString)]
						end
					end
					local THRESHOLD = .25
					if (getPastDirection()*module.MODULE_STORAGE.statValues.moveValue*(landingLevel.Position.Y-level.Position.Y) <= -THRESHOLD) then
						--releveling = false
						--return relevel()
					end
					--module.MODULE_STORAGE.statValues.currentSpeed = math.clamp(module.MODULE_STORAGE.statValues.currentSpeed, -relevelingSpeed, configFile.Movement.Travel_Speed)

					releveled = distanceFromFloor <= .005
					updateCore()

				end
				module.MODULE_STORAGE.statValues.currentSpeed = 0
				module.MODULE_STORAGE.statValues.moveDirection = 'N'
				module.MODULE_STORAGE.statValues.direction = 'N'
				module.MODULE_STORAGE.statValues.leveling = false
				preDooring = false
				releveling = false
				module.MODULE_STORAGE.statValues.currentFloor = relevelingFloor
				resetButtons()
				removePlayerWelds()
				if ((not module.MODULE_STORAGE.statValues.fireService) and checkDoorStates('Closed')) then
					runChime(relevelingFloor, configFile.Sound_Database.Chime_Events.On_Open, configFile.Sound_Database.Chime_Events.After_Open, true)
					doLanterns(relevelingFloor, configFile.Color_Database.Lanterns.Active_On_Door_Open, configFile.Color_Database.Lanterns.Active_After_Door_Open)
				end
				module.MODULE_STORAGE.statValues.moveValue = 0
				lock = false

				if (((not module.MODULE_STORAGE.statValues.fireService) and (not checkPhase2())) or (module.MODULE_STORAGE.statValues.fireService and fireRecallFloor == module.MODULE_STORAGE.statValues.rawFloor and (not checkPhase2()))) then
					runDoorOpen(module.MODULE_STORAGE.statValues.rawFloor, 'ALL')
				end
				if (configFile.Movement.Floor_Pass_Chime_On_Stop_Config.Enable and (not checkPhase2()) and (not checkIndependentService())) then
					task.delay(configFile.Movement.Floor_Pass_Chime_On_Stop_Config.Delay, function()
						addPlaySound(module.MODULE_STORAGE.sounds.Floor_Pass_Chime, platform)
					end)
				end

				task.spawn(updateCore)
				task.spawn(parkTimer)
				return
			end)
			if (not ran) then
				print(`Elevator relevel failed due to an error, resetting`, msg)
				return restartElevator()
			end
		end

		function safeCheckRelevel()
			if (releveling or module.MODULE_STORAGE.statValues.inspection or overshot or preDooring or stopElevator or module.MODULE_STORAGE.statValues.moveValue ~= 0) then return end
			if (getFloorDistance(module.MODULE_STORAGE.statValues.rawFloor) > .35) then
				relevel()
			else -- Audit made so the elevator doesn't 'stall'
				for i,v in pairs(pluginModules_INTERNAL.Storage.CONTENT:getContentInBranch('masterDoorData')) do
					if (v.state == 'Closed' or v.state == 'Closing' or v.state == 'Stopped') then
						task.spawn(runDoorOpen,module.MODULE_STORAGE.statValues.rawFloor,v.side)
					end
				end
			end
		end

		function removePlayingSounds(obj)
			for i,v in pairs(obj:GetDescendants()) do
				if (v:IsA('Sound') and v.IsPlaying) then
					v:Destroy()
				end
			end
		end

		local chimeAfterOpenC = {}
		function runChime(flr, dataType, afterOpen, direction: any?, overrideDebounce: boolean?)

			local floor = findFloor(flr)
			if (not floor) then return end
			local regFloor = findRegisteredFloor(flr)
			if (not regFloor) then return end

			local function addChimeAudio(index, type, direction, debounceOverride: boolean?)

				local directionNum = string.sub(direction,1,1) == 'U' and 1 or string.sub(direction,1,1) == 'D' and -1 or 0
				index = `{string.upper(string.sub(index,1,1))}{string.lower(string.sub(index,2))}`
				local callOnlyMet = (type.Call_Only and (table.find(regFloor.exteriorCallDirections,directionNum) or checkCallInDirection(flr))) or (not type.Call_Only)
				if (callOnlyMet) then
					task.delay(type.Delay or 0, function()
						local lanternParts = {}
						for i,v in pairs((index == 'Exterior' and floor or index == 'Interior' and car):GetDescendants()) do
							if (v.Name == 'Lanterns') then
								for i,g in pairs(v:GetChildren()) do
									if (g.Name == direction or g.Name == 'Both') then
										for i,p in pairs(g:GetDescendants()) do
											if (p:IsA('BasePart') and p.Name == 'Light') then
												if (lanternParts[g]) then continue end
												lanternParts[g] = p
											end
										end
									end
								end
							end
						end
						if (getTableLength(lanternParts) == 0 and index == 'Interior') then
							lanternParts[1] = platform
						end
						if (not getTableLength(lanternParts)) then return end
						for _,lanternPart in pairs(lanternParts) do
							task.spawn(function()
								if (lanternPart:GetAttribute('hasSignaled') and (not debounceOverride)) then return end
								lanternPart:SetAttribute('hasSignaled', true)
								local name = `{index}_{direction}_Chime`
								local function checkLanternInstance()
									return lanternPart:FindFirstChild(`{name}_Playing`)
								end
								local chime = module.MODULE_STORAGE.sounds[name]
								if (not chime) then return end
								local function checkRecursive()
									if (not checkLanternInstance()) then
										return true
									else
										lanternPart.ChildRemoved:Wait()
										return checkRecursive()
									end
								end
								checkRecursive()
								addPlaySound(chime, lanternPart)
							end)
						end
					end)
				end
			end
			local lanternDirection = module.MODULE_STORAGE.statValues.queueDirection
			lanternDirection = lanternDirection == 'U' and 'Up' or lanternDirection == 'D' and 'Down' or nil
			if (not lanternDirection) then return end
			for index,type in pairs(typeof(dataType) == 'table' and dataType or {}) do
				if (type.Enable) then
					addChimeAudio(index, type, lanternDirection, overrideDebounce)
				end
				if (afterOpen[index] and afterOpen[index].Enable) then
					for i,v in next,pluginModules_INTERNAL.Storage.CONTENT:getContentInBranch('masterDoorData') do
						if (chimeAfterOpenC[v.side]) then continue end
						local connect
						connect = v.valueInstances.doorStateValue:GetPropertyChangedSignal('Value'):Connect(function()
							if (v.valueInstances.doorStateValue.Value == 'Open' or v.valueInstances.doorStateValue.Value == 'Closed') then
								for i,c in pairs(chimeAfterOpenC) do
									c:Disconnect()
									chimeAfterOpenC[i] = nil
								end
								if (v.valueInstances.doorStateValue.Value == 'Open') then
									addChimeAudio(index, afterOpen[index], lanternDirection, true)
								end
							end
						end)
						chimeAfterOpenC[v.side] = connect
					end
				end
			end
		end

		local lanternAfterOpenC = {}
		function doLanterns(floor, dataType, afterOpen, direction)
			task.spawn(function()
				local landing = findFloor(floor)
				if (not landing) then return end
				local regFloor = findRegisteredFloor(floor)
				if (not regFloor) then return end
				local lanternDirection = module.MODULE_STORAGE.statValues.queueDirection
				local ogDir = lanternDirection
				lanternDirection = lanternDirection == 'U' and 'Up' or lanternDirection == 'D' and 'Down' or nil
				if (not lanternDirection) then return end
				local directionNum = string.sub(lanternDirection,1,1) == 'U' and 1 or string.sub(lanternDirection,1,1) == 'D' and -1 or 0
				local function handle(index, _type)
					index = `{string.upper(string.sub(index,1,1))}{string.lower(string.sub(index,2))}`
					local callOnlyMet = (_type.Call_Only and (table.find(regFloor.exteriorCallDirections,directionNum) or checkCallInDirection(floor))) or (not _type.Call_Only)
					api:Fire('onElevatorLanternApi', {
						state='active',
						floor = floor,
						direction = ogDir,
						type = string.lower(index),
						eventData = _type,
						conditionMet = callOnlyMet
					})
					for i,v in pairs((index == 'Interior' and car or index == 'Exterior' and landing):GetChildren()) do
						if (v.Name == 'Lanterns') then
							for i,m in pairs(v:GetChildren()) do
								if (m.Name == lanternDirection or m.Name == 'Both') then
									if (m:GetAttribute('hasActivated')) then continue end
									m:SetAttribute('hasActivated', true)
									local function activate(state)
										for i,l in pairs(m:GetDescendants()) do
											if (l:IsA('BasePart') and l.Name == 'Light') then
												local config = configFile.Color_Database.Lanterns[index][lanternDirection][string.format('%s_State', state)]
												l.Color,l.Material = config.Color,config.Material
												for i,l2 in pairs(l:GetDescendants()) do
													if (l2.ClassName:match('Light')) then
														l2.Enabled = state == 'Lit'
													end
												end
											end
										end
									end
									if (callOnlyMet) then
										local config = configFile.Color_Database.Lanterns[index]
										if (config.Repeat_Data.Enable) then
											activate('Neautral')
										end
										task.delay(_type.Delay, function()
											activate('Lit')
											if (config.Repeat_Data.Enable and (config.Repeat_Data.Allowed_Directions and table.find(config.Repeat_Data.Allowed_Directions, string.sub(lanternDirection, 1, 1)))) then
												task.spawn(function()
													task.wait(config.Repeat_Data.Delay)
													for i=1,config.Repeat_Data.Times do
														activate('Neautral')
														task.wait(config.Repeat_Data.Delay)
														activate('Lit')
														if (config.Repeat_Data.Play_Chime_On_Light) then
															runChime(floor, {['Exterior']={['Type']='Arrival',['Enable']=true},['Interior']={['Type']='Normal',['Enable']=true}}, {['Exterior']={['Type']='Arrival',['Enable']=false},['Interior']={['Type']='Normal',['Enable']=false}}, overrideDebounce)
														end
													end
												end)
											end
										end)
									end
								end
							end
						end
					end
				end
				for index,_type in pairs(typeof(dataType) == 'table' and dataType or {}) do
					if (_type.Enable and (not afterOpen[index].Enable)) then
						handle(index, _type)
					elseif (afterOpen[index] and afterOpen[index].Enable) then
						for i,v in pairs(pluginModules_INTERNAL.Storage.CONTENT:getContentInBranch('masterDoorData')) do
							if (lanternAfterOpenC[v.side]) then continue end
							if (v.valueInstances.doorStateValue.Value ~= 'Open') then
								local connect
								connect = v.valueInstances.doorStateValue:GetPropertyChangedSignal('Value'):Connect(function()
									if (v.valueInstances.doorStateValue.Value == 'Open' or v.valueInstances.doorStateValue.Value == 'Closed') then
										for i,c in pairs(lanternAfterOpenC) do
											c:Disconnect()
											lanternAfterOpenC[i] = nil
										end
										if (v.valueInstances.doorStateValue.Value == 'Open') then
											handle(index, afterOpen[index])
										end
									end
								end)
								lanternAfterOpenC[v.side] = connect
							elseif (v.valueInstances.doorStateValue.Value == 'Open') then
								for i,c in pairs(lanternAfterOpenC) do
									if (not c.Connected) then continue end
									c:Disconnect()
								end
								handle(index, afterOpen[index])
							end
						end
					end
				end
			end)

		end
		function resetLanterns(floor, type)
			local flr = findFloor(floor)
			if (not flr) then return end
			for index,value in pairs(typeof(type) == 'table' and type or {'Interior','Exterior'}) do
				chimingAfterOpen[value] = false
				api:Fire('onElevatorLanternApi', {state = 'neutral', floor = floor, direction = module.MODULE_STORAGE.statValues.queueDirection, type = string.lower(value)})
				for i,v in pairs((value == 'Interior' and car or value == 'Exterior' and flr):GetChildren()) do
					if (v.Name == 'Lanterns') then
						for i,m in pairs(v:GetChildren()) do
							local direction = m.Name == 'Up' and 'U' or m.Name == 'Down' and 'D' or nil
							if (string.sub(m.Name, 1, 1) == direction or m.Name == 'Both') then
								for i,l in pairs(m:GetDescendants()) do
									if (l:GetAttribute('hasSignaled')) then
										l:SetAttribute('hasSignaled', nil)
									end
									if (l:IsA('BasePart') and l.Name == 'Light') then
										local config = configFile.Color_Database.Lanterns[value][m.Name ~= 'Both' and m.Name or 'Up'].Neautral_State
										l.Color,l.Material = config.Color,config.Material
										for i,l2 in pairs(l:GetDescendants()) do
											if (l2.ClassName:match('Light')) then
												l2.Enabled = false
											end
										end
									end
								end
								m:SetAttribute('hasActivated', nil)
								removePlayingSounds(m)
							end
						end
					end
				end
			end
		end

		function elevatorProcessRunStop(floor: number, relevelBypass: boolean?)

			local dest = module.MODULE_STORAGE.statValues.destination or floor
			local directionValue = dest > module.MODULE_STORAGE.statValues.rawFloor and 1 or dest < module.MODULE_STORAGE.statValues.rawFloor and -1 or 0
			local landingLevel = findFloor(floor):FindFirstChild('Level')
			local speed,dist = module.MODULE_STORAGE.statValues.currentSpeed,getFloorDistance(floor)
			local linearModeOffset = configFile.Movement.Braking_Data[module.MODULE_STORAGE.statValues.moveValue == 1 and 'Linear_Mode_Offset_Up' or module.MODULE_STORAGE.statValues.moveValue == -1 and 'Linear_Mode_Offset_Down' or '']*module.MODULE_STORAGE.statValues.moveValue
			local levelingStage = 0
			if (configFile.Movement.Braking_Data.Mode == 'Linear') then
				dist = math.abs((landingLevel.Position.Y+linearModeOffset)-level.Position.Y)
			end
			module.MODULE_STORAGE.statValues.leveling = true
			module.MODULE_STORAGE.miscValues.leaving = false
			module.MODULE_STORAGE.statValues.arriveFloor = floor

			local destVal = module.MODULE_STORAGE.statValues.destination
			local lastDirectionNum = module.MODULE_STORAGE.statValues.queueDirection == 'U' and 1 or module.MODULE_STORAGE.statValues.queueDirection == 'D' and -1 or 0
			local nextQueue = checkCallInDirection(floor,lastDirectionNum) --// Check for calls in current direction
			if (not nextQueue) then nextQueue = checkCallInDirection(floor,-lastDirectionNum) end --// Check for calls in opposite direction
			if (not nextQueue) then nextQueue = select(2, findCallInQueue(floor)) end --// Check for calls on current floor if no other calls can be found
			local regFloor = findRegisteredFloor(module.MODULE_STORAGE.statValues.arriveFloor)
			local thisQueue = select(2, findCallInQueue(floor))
			module.MODULE_STORAGE.statValues.queueDirection = (nextQueue and ((nextQueue.call > floor and 'U' or nextQueue.call < floor and 'D') or nextQueue.call == topFloor and 'D' or nextQueue.call == bottomFloor and 'U')) or (thisQueue and (thisQueue.directions[1] and (thisQueue.directions[1] == 1 and 'U' or thisQueue.directions[1] == -1 and 'D'))) or (floor == topFloor and 'D' or floor == bottomFloor and 'U') or 'N'
			module.MODULE_STORAGE.statValues.arrowDirection = module.MODULE_STORAGE.statValues.queueDirection
			module.MODULE_STORAGE.statValues.destination = destVal
			task.spawn(updateCore)
			api:Fire('onElevatorArrive', {floor=floor,direction=module.MODULE_STORAGE.statValues.queueDirection,parking=module.MODULE_STORAGE.statValues.parking})
			api:Fire('onCallRespond', {floor=floor,direction=module.MODULE_STORAGE.statValues.queueDirection,parking=module.MODULE_STORAGE.statValues.parking})

			if (voiceConfig.Settings.Floor_Announcements.Announce_Floor_On_Arrival and (not module.MODULE_STORAGE.statValues.parking) and (not module.MODULE_STORAGE.statValues.fireService) and (not checkIndependentService())) then
				task.spawn(function()

					playVoiceSequenceProtocolWithQueue(voiceConfig.Floor_Announcements[tostring(floor)] or {}, true)
					if (voiceConfig.Settings.Directional_Announcements.Announce_After_Floor_Announcement and module.MODULE_STORAGE.statValues.queueDirection ~= 'N') then
						local dir = module.MODULE_STORAGE.statValues.queueDirection == 'U' and 'Up' or module.MODULE_STORAGE.statValues.queueDirection == 'D' and 'Down'
						local clip = voiceConfig.Settings.Directional_Announcements[`{dir}_Announcement`]
						if (clip.Enabled) then
							playVoiceSequenceProtocolWithQueue(clip.Sequence, false)
						end
					end

				end)
			end

			if ((not module.MODULE_STORAGE.statValues.fireService) and (not checkIndependentService())) then
				task.spawn(runChime, module.MODULE_STORAGE.statValues.arriveFloor, configFile.Sound_Database.Chime_Events.On_Arrival, configFile.Sound_Database.Chime_Events.After_Open, true)
				task.spawn(doLanterns, module.MODULE_STORAGE.statValues.arriveFloor, configFile.Color_Database.Lanterns.Active_On_Arrival, configFile.Color_Database.Lanterns.Active_After_Door_Open, true)
			end
			task.spawn(removeCall, module.MODULE_STORAGE.statValues.arriveFloor,module.MODULE_STORAGE.statValues.queueDirection == 'U' and 1 or module.MODULE_STORAGE.statValues.queueDirection == 'D' and -1 or 0)

			local diff = 0
			local decelSpeedPoint = configFile.Movement.Braking_Data.Smart_Linear_Transition_Dist*(speed/(configFile.Movement.Travel_Speed/3))
			local lastStage,thisLevelingStage = nil,1
			local startTick = os.clock()
			local reachedLevelingSpeed = false
			local deltaTime,elevMoveDirection = 0,0
			local STOP_OFFSET = configFile.Sensors.Stop_Offset
			local stopTargetPosition = landingLevel.Position.Y
			local targetPosition = stopTargetPosition+(linearModeOffset+STOP_OFFSET)
			local STOP_THRESHOLD = 0
			local UNDER_THRESHOLD = false
			local SMOOTH_STOP_THRESHOLD = configFile.Movement.Smooth_Stop_Threshold

			-- NEW LINEAR LEVELING CONCEPT -- IMPLEMENTED BY aaxtatious 05/03/23
			local INITIAL_SPEED = module.MODULE_STORAGE.statValues.currentSpeed
			local MIN_SPEED = configFile.Movement.Level_Speed
			local DISTANCE_TO_DECELERATE = math.abs(targetPosition-level.Position.Y)
			local lastPosition = platform.Position
			local lastTick = os.clock()

			local function getElevatorDistance(target: any, offsetFromTarget: number?)
				return math.abs((target+(typeof(offsetFromTarget) == 'number' and offsetFromTarget or 0))-level.Position.Y)
			end
			----

			while isMoving do

				local deltaTime = updateCore()
				local currentMoveValue = module.MODULE_STORAGE.statValues.moveValue
				local elevMoveDirection = (platform.Position-lastPosition).Unit.Y
				elevMoveDirection = elevMoveDirection > 0 and 1 or elevMoveDirection < 0 and -1 or 0
				if (moveBrake or module.MODULE_STORAGE.statValues.inspection or overshot or stopElevator or (not isDropKeyOnElevator()) or ((not checkDoorStates('Closed')) and (not preDooring))) then
					if (not safetyBraking) then
						module.MODULE_STORAGE.statValues.currentSpeed = 0
						module.MODULE_STORAGE.statValues.moveValue = 0
						module.MODULE_STORAGE.statValues.moveDirection = 'N'
						lock = false
						setDirection(module.MODULE_STORAGE.statValues.rawFloor, 'N')
						preDooring = false
						releveling = false
						overshot = false
						module.MODULE_STORAGE.statValues.leveling = false
						preChimeFloor = nil
						safetyBraking = false
						removePlayerWelds()
						updateCore()
					end
					return
				end
				local lastStage
				local landingLevel = findFloor(module.MODULE_STORAGE.statValues.arriveFloor):FindFirstChild('Level')

				if (not UNDER_THRESHOLD) then
					UNDER_THRESHOLD = getElevatorDistance(targetPosition) <= SMOOTH_STOP_THRESHOLD
				end
				local distanceToFloor = currentMoveValue*(targetPosition-level.Position.Y)
				local stage1LvlDist = currentMoveValue*((targetPosition-(currentMoveValue*SMOOTH_STOP_THRESHOLD))-level.Position.Y)
				local absoluteDistanceToFloor = getElevatorDistance(stopTargetPosition)
				local displacement = module.MODULE_STORAGE.statValues.currentSpeed*deltaTime

				if (configFile.Movement.Braking_Data.Mode == 'Default') then
					module.MODULE_STORAGE.statValues.currentSpeed = math.max(MIN_SPEED, (speed/dist)*getFloorDistance(module.MODULE_STORAGE.statValues.arriveFloor))
				elseif (configFile.Movement.Braking_Data.Mode == 'Linear') then
					local currentSpeed = module.MODULE_STORAGE.statValues.currentSpeed
					local gradualDecelRatio = math.min(1, math.max(.1, ((distanceToFloor/(DISTANCE_TO_DECELERATE*configFile.Movement.Smooth_Stop_V2.Threshold)))/(currentSpeed/INITIAL_SPEED)))
					local deceleration = currentSpeed^2/(2*math.max(if (configFile.Movement.Enable_Smooth_Stop) then if (not UNDER_THRESHOLD) then stage1LvlDist else absoluteDistanceToFloor else distanceToFloor*(configFile.Movement.Smooth_Stop_V2.Enable and gradualDecelRatio or 1), .001))
					local SPEED = math.max(0, currentSpeed-deceleration*deltaTime)
					module.MODULE_STORAGE.statValues.currentSpeed = math.max(SPEED, ((not UNDER_THRESHOLD) and configFile.Movement.Enable_Smooth_Stop) and MIN_SPEED+((1.25*SMOOTH_STOP_THRESHOLD)) or if (configFile.Movement.Enable_Smooth_Stop) then .015 else MIN_SPEED)
				elseif (configFile.Movement.Braking_Data.Mode == 'Manual') then
					module.MODULE_STORAGE.statValues.currentSpeed = math.max(MIN_SPEED, module.MODULE_STORAGE.statValues.currentSpeed-configFile.Movement.Braking_Data.Increment*math.deg(deltaTime))
				elseif (configFile.Movement.Braking_Data.Mode == 'Advanced') then
					if (module.MODULE_STORAGE.statValues.currentSpeed > configFile.Movement.Braking_Data.Advanced_Leveling.Stage_1_Min_Speed and levelingStage ~= 2) then
						levelingStage = 1
						local currentSpeed = module.MODULE_STORAGE.statValues.currentSpeed
						local deceleration = currentSpeed^2/(2*math.max(if (configFile.Movement.Enable_Smooth_Stop) then if (not UNDER_THRESHOLD) then stage1LvlDist else absoluteDistanceToFloor else distanceToFloor, .001))
						local SPEED = math.max(0, currentSpeed-deceleration*deltaTime)
						module.MODULE_STORAGE.statValues.currentSpeed = math.max(SPEED, ((not UNDER_THRESHOLD) and configFile.Movement.Enable_Smooth_Stop) and MIN_SPEED+(1.25*SMOOTH_STOP_THRESHOLD)*math.min(absoluteDistanceToFloor/SMOOTH_STOP_THRESHOLD, 1) or .015)
					elseif (levelingStage == 1 and getFloorDistance(module.MODULE_STORAGE.statValues.arriveFloor) <= configFile.Movement.Braking_Data.Advanced_Leveling.Stage_2_Decel_Offset) then
						levelingStage = 2
						api:Fire('levelingStageChange', {brakingMode=configFile.Movement.Braking_Data.Mode,stage=levelingStage})
						speed,dist = module.MODULE_STORAGE.statValues.currentSpeed,getFloorDistance(module.MODULE_STORAGE.statValues.arriveFloor)
					elseif (levelingStage == 2) then
						local currentSpeed = module.MODULE_STORAGE.statValues.currentSpeed
						local deceleration = currentSpeed^2/(2*math.max(if (configFile.Movement.Enable_Smooth_Stop) then if (not UNDER_THRESHOLD) then stage1LvlDist else absoluteDistanceToFloor else distanceToFloor, .001))
						local SPEED = math.max(0, currentSpeed-deceleration*deltaTime)
						module.MODULE_STORAGE.statValues.currentSpeed = math.max(SPEED, ((not UNDER_THRESHOLD) and configFile.Movement.Enable_Smooth_Stop) and MIN_SPEED+(1.25*SMOOTH_STOP_THRESHOLD)*math.min(absoluteDistanceToFloor/SMOOTH_STOP_THRESHOLD, 1) or .015)
					end
				elseif (configFile.Movement.Braking_Data.Mode == 'SmartLinear') then
					if (getFloorDistance(module.MODULE_STORAGE.statValues.arriveFloor) > decelSpeedPoint and levelingStage ~= 2) then
						levelingStage = 1
						local currentSpeed = module.MODULE_STORAGE.statValues.currentSpeed
						local deceleration = currentSpeed^2/(2*math.max(if (configFile.Movement.Enable_Smooth_Stop) then if (not UNDER_THRESHOLD) then stage1LvlDist else absoluteDistanceToFloor else distanceToFloor, .001))
						local SPEED = math.max(0, currentSpeed-deceleration*deltaTime)
						module.MODULE_STORAGE.statValues.currentSpeed = math.max(SPEED, ((not UNDER_THRESHOLD) and configFile.Movement.Enable_Smooth_Stop) and MIN_SPEED+(1.25*SMOOTH_STOP_THRESHOLD)*math.min(absoluteDistanceToFloor/SMOOTH_STOP_THRESHOLD, 1) or .015)
					elseif (levelingStage == 1) then
						levelingStage = 2
						speed,dist = module.MODULE_STORAGE.statValues.currentSpeed,getFloorDistance(module.MODULE_STORAGE.statValues.arriveFloor)
						api:Fire('levelingStageChange', {brakingMode=configFile.Movement.Braking_Data.Mode,stage=levelingStage})
					elseif (levelingStage == 2) then
						module.MODULE_STORAGE.statValues.currentSpeed = math.clamp((speed/dist)*getFloorDistance(module.MODULE_STORAGE.statValues.arriveFloor), MIN_SPEED, if (speed) < MIN_SPEED then speed+MIN_SPEED else speed)
					end
				elseif (configFile.Movement.Braking_Data.Mode == 'Custom') then
					local currentLevelingStage,nextLevelingStage = configFile.Movement.Braking_Data.Custom_Leveling_Stages[thisLevelingStage],configFile.Movement.Braking_Data.Custom_Leveling_Stages[thisLevelingStage+1]
					if (currentLevelingStage) then
						if (nextLevelingStage and nextLevelingStage.Transition_Distance >= getFloorDistance(module.MODULE_STORAGE.statValues.arriveFloor)) then
							thisLevelingStage += 1
							speed = module.MODULE_STORAGE.statValues.currentSpeed
							dist = (math.abs((landingLevel.Position.Y+(module.MODULE_STORAGE.statValues.moveValue*currentLevelingStage.Offset))-level.Position.Y))
						end
						if (currentLevelingStage.Rate == 'Constant') then
							local currentSpeed = module.MODULE_STORAGE.statValues.currentSpeed
							local deceleration = currentSpeed^2/(2*math.max(if (configFile.Movement.Enable_Smooth_Stop) then if (not UNDER_THRESHOLD) then stage1LvlDist else absoluteDistanceToFloor else distanceToFloor, .001))
							local SPEED = math.max(0, currentSpeed-deceleration*deltaTime)
							module.MODULE_STORAGE.statValues.currentSpeed = math.max(SPEED, ((not UNDER_THRESHOLD) and configFile.Movement.Enable_Smooth_Stop) and MIN_SPEED+(1.25*SMOOTH_STOP_THRESHOLD)*math.min(absoluteDistanceToFloor/SMOOTH_STOP_THRESHOLD, 1) or .015)
						else
							module.MODULE_STORAGE.statValues.currentSpeed = math.clamp((speed/dist)*getFloorDistance(module.MODULE_STORAGE.statValues.arriveFloor), MIN_SPEED, if (speed) < MIN_SPEED then speed+MIN_SPEED else speed)
						end
					end
				end
				if (module.MODULE_STORAGE.statValues.currentSpeed <= configFile.Movement.Level_Speed and (not reachedLevelingSpeed)) then
					reachedLevelingSpeed = true
					task.spawn(removePlayerWelds)
				end
				local moveValue = module.MODULE_STORAGE.statValues.moveValue
				local THRESHOLD = .25
				if (moveValue*(stopTargetPosition-level.Position.Y) <= -THRESHOLD) then
					outputElevMessage(`Elevator has over/undershot during travel on floor {floor}, attempting to re-level`)
					releveling = false
					relevel()
					return
				end
				if (configFile.Sensors.Pre_Door_Data.Enable and ((not module.MODULE_STORAGE.statValues.parking) or (#module.MODULE_STORAGE.queue > 0 and floor ~= configFile.Movement.Parking_Config.Park_Floor)) and (configFile.Movement.Open_Doors_On_Stop) and (not checkIndependentService()) and module.MODULE_STORAGE.statValues.currentSpeed <= configFile.Movement.Level_Speed+1.5 and ((not preDooring)) and (not releveling) and ((not module.MODULE_STORAGE.statValues.fireService) and (not checkPhase2())) or (module.MODULE_STORAGE.statValues.fireService and fireRecallFloor == module.MODULE_STORAGE.statValues.rawFloor and (not checkPhase2()))) and getFloorDistance(module.MODULE_STORAGE.statValues.arriveFloor) <= configFile.Sensors.Pre_Door_Data.Offset then
					preDooring = true
					lock = false
					if (module.MODULE_STORAGE.statValues.parking) then
						setDirection(module.MODULE_STORAGE.statValues.arriveFloor, 'N')
					end
					if ((not module.MODULE_STORAGE.statValues.fireService) and (not checkIndependentService())) then
						runChime(dest or module.MODULE_STORAGE.statValues.rawFloor, configFile.Sound_Database.Chime_Events.On_Open, configFile.Sound_Database.Chime_Events.After_Open, true)
						doLanterns(dest or module.MODULE_STORAGE.statValues.rawFloor, configFile.Color_Database.Lanterns.Active_On_Door_Open, configFile.Color_Database.Lanterns.Active_After_Door_Open)
					end
					if (configFile.Sound_Database.Others.Elevator_Stop_Beep.Enable) then
						module.MODULE_STORAGE.sounds.Elevator_Stop_Beep:Play()
					end
					if (configFile.Movement.Floor_Pass_Chime_On_Stop_Config.Enable and (not checkIndependentService()) and (not module.MODULE_STORAGE.statValues.parking) and (not module.MODULE_STORAGE.statValues.fireService)) then
						task.delay(configFile.Movement.Floor_Pass_Chime_On_Stop_Config.Delay, function()
							addPlaySound(module.MODULE_STORAGE.sounds.Floor_Pass_Chime, platform)
						end)
					end
					module.MODULE_STORAGE.statValues.currentFloor = module.MODULE_STORAGE.statValues.arriveFloor
					runDoorOpen(module.MODULE_STORAGE.statValues.rawFloor, 'ALL')
				end
				if (moveValue*(stopTargetPosition-level.Position.Y) <= STOP_THRESHOLD+(moveValue*displacement) and reachedLevelingSpeed) then break end
				lastPosition = platform.Position
			end
			removePlayerWelds()
			local isEnabled = bounceStop(false)
			if (not isEnabled) then
				module.MODULE_STORAGE.statValues.currentSpeed = 0
				module.MODULE_STORAGE.statValues.moveValue = 0
				module.MODULE_STORAGE.statValues.moveDirection = 'N'
				module.MODULE_STORAGE.statValues.direction = 'N'
				module.MODULE_STORAGE.statValues.leveling = false
				preDooring = false
			end
			api:Fire('onCallRespond', {floor=floor,direction=module.MODULE_STORAGE.statValues.queueDirection,parking=module.MODULE_STORAGE.statValues.parking})
			api:Fire('onElevatorStop', {floor=module.MODULE_STORAGE.statValues.arriveFloor})
			if (not configFile.Sensors.Pre_Door_Data.Enable) then
				conditionalStepWait(configFile.Movement.Stop_Delay, function() return {} end)
				--if (module.MODULE_STORAGE.statValues.moveValue ~= 0) then return end
			end

			if (module.MODULE_STORAGE.statValues.parking) then
				setDirection(module.MODULE_STORAGE.statValues.arriveFloor, 'N')
			end
			lock = false
			if (checkDoorStates('Closed') and (not module.MODULE_STORAGE.statValues.fireService) and (not checkPhase2()) and ((not module.MODULE_STORAGE.statValues.parking) or (#module.MODULE_STORAGE.queue > 0 and floor ~= configFile.Movement.Parking_Config.Park_Floor)) and (not checkIndependentService())) then
				if (configFile.Sound_Database.Others.Elevator_Stop_Beep.Enable) then
					module.MODULE_STORAGE.sounds.Elevator_Stop_Beep:Play()
				end
				if (configFile.Movement.Floor_Pass_Chime_On_Stop_Config.Enable and (not checkIndependentService()) and (not module.MODULE_STORAGE.statValues.parking) and (not module.MODULE_STORAGE.statValues.fireService)) then
					task.delay(configFile.Movement.Floor_Pass_Chime_On_Stop_Config.Delay, function()
						addPlaySound(module.MODULE_STORAGE.sounds.Floor_Pass_Chime, carRegion)
					end)
				end
				runChime(dest or module.MODULE_STORAGE.statValues.rawFloor, configFile.Sound_Database.Chime_Events.On_Open, configFile.Sound_Database.Chime_Events.After_Open, true)
				doLanterns(dest or module.MODULE_STORAGE.statValues.rawFloor, configFile.Color_Database.Lanterns.Active_On_Door_Open, configFile.Color_Database.Lanterns.Active_After_Door_Open)
			end

			--if (configFile.Sound_Database.Voice_Config.Options.Floor_Announcements.Announce_Floor_On_Stop and ((not module.MODULE_STORAGE.statValues.parking) or (#module.MODULE_STORAGE.queue > 0 and floor ~= configFile.Movement.Parking_Config.Park_Floor)) and (not module.MODULE_STORAGE.statValues.fireService) and (not checkIndependentService())) then
			--	task.spawn(function()

			--		playVoiceSequenceProtocolWithQueue(voiceConfig.Voice_Config[tostring(floor)] or {}, true)
			--		if (configFile.Sound_Database.Voice_Config.Options.Directional_Announcements.Announce_After_Floor_Announcement and module.MODULE_STORAGE.statValues.queueDirection ~= 'N') then
			--			local dir = module.MODULE_STORAGE.statValues.queueDirection == 'U' and 'Up' or module.MODULE_STORAGE.statValues.queueDirection == 'D' and 'Down'
			--			local clip = configFile.Sound_Database.Voice_Config.Options.Directional_Announcements[dir..'_Announcement']
			--			if (clip.Enabled) then
			--				playVoiceSequenceProtocolWithQueue(clip.Sequence, false)
			--			end
			--		end

			--	end)
			--end

			module.MODULE_STORAGE.statValues.currentFloor = module.MODULE_STORAGE.statValues.arriveFloor
			isMoving = false
			releveling = false
			task.spawn(updateCore)
			if ((((not module.MODULE_STORAGE.statValues.fireService) and (configFile.Movement.Open_Doors_On_Stop) and (not checkPhase2()) or checkIndependentService()) or (module.MODULE_STORAGE.statValues.fireService and fireRecallFloor == module.MODULE_STORAGE.statValues.rawFloor and (not checkPhase2()))) and ((not module.MODULE_STORAGE.statValues.parking) or (#module.MODULE_STORAGE.queue > 0 and floor ~= configFile.Movement.Parking_Config.Park_Floor))) then
				task.spawn(runDoorOpen, module.MODULE_STORAGE.statValues.rawFloor, 'ALL')
			end
			task.spawn(parkTimer)
			task.spawn(updateCore)
			module.MODULE_STORAGE.statValues.parking = false
			task.spawn(function()
				local hasPassed = conditionalStepWait(2, function() return {module.MODULE_STORAGE.statValues.moveValue ~= 0 or (not checkDoorStates('Closed'))} end)
				if (not hasPassed) then return end
				local directionNum = module.MODULE_STORAGE.statValues.queueDirection == 'U' and 1 or module.MODULE_STORAGE.statValues.queueDirection == 'D' and -1 or 0
				local nextCall = checkCallInDirection(module.MODULE_STORAGE.statValues.rawFloor,directionNum) or module.MODULE_STORAGE.queue[1]
				local regFloor = findRegisteredFloor(module.MODULE_STORAGE.statValues.rawFloor)
				local function checkRun(call: any)
					if (not call) then return end
					local dir = call.directions[1]
					local regFloor = findRegisteredFloor(call.call)
					local index = table.find(regFloor.exteriorCallDirections,dir)
					if (index) then
						task.spawn(function()
							module.MODULE_STORAGE.statValues.queueDirection = dir == 1 and 'U' or dir == -1 and 'D' or 'N'
							module.MODULE_STORAGE.statValues.arrowDirection = module.MODULE_STORAGE.statValues.queueDirection
							api:Fire('onCallRespond', {floor=floor,direction=module.MODULE_STORAGE.statValues.queueDirection})
							task.spawn(updateCore)
							task.spawn(runDoorOpen,module.MODULE_STORAGE.statValues.rawFloor,'ALL')
							doLanterns(module.MODULE_STORAGE.statValues.rawFloor,configFile.Color_Database.Lanterns.Active_On_Exterior_Call,configFile.Color_Database.Lanterns.Active_After_Door_Open,dir)
							runChime(module.MODULE_STORAGE.statValues.rawFloor,configFile.Sound_Database.Chime_Events.Exterior_Call_Only,configFile.Sound_Database.Chime_Events.After_Open,dir, true)
							removeCall(call.call,dir)
						end)
					end
				end

				updateCore()

				if (not regFloor) then return end
				local index = table.find(regFloor.exteriorCallDirections,directionNum)
				if (index) then
					table.remove(regFloor.exteriorCallDirections,index)
				end
				if (module.MODULE_STORAGE.statValues.moveValue == 0 and nextCall and nextCall.call ~= module.MODULE_STORAGE.statValues.rawFloor) then
					task.spawn(elevatorRun,nextCall.call,false)
				elseif (nextCall and nextCall.call == module.MODULE_STORAGE.statValues.rawFloor) then
					local hasCompleted = conditionalStepWait(1, function() return {module.MODULE_STORAGE.statValues.moveValue ~= 0} end)
					if (not hasCompleted) then return end
					checkRun(nextCall)
				else
					nextCall = checkCallInDirection(module.MODULE_STORAGE.statValues.rawFloor) or module.MODULE_STORAGE.queue[1]
					if (not nextCall) then return end
					local queueDir = nextCall.call > module.MODULE_STORAGE.statValues.rawFloor and 'U' or nextCall.call < module.MODULE_STORAGE.statValues.rawFloor and 'D' or 'N'
					if (queueDir ~= module.MODULE_STORAGE.statValues.queueDirection) then
						local hasCompleted = conditionalStepWait(1, function() return {module.MODULE_STORAGE.statValues.moveValue ~= 0} end)
						if (not hasCompleted) then return end
					end
					checkRun(nextCall)
				end
			end)
			return
		end

		function elevatorRun(dest, park)
			if ((not findFloor(dest)) or (module.MODULE_STORAGE.statValues.moveValue ~= 0) or (moveBrake) or (lock) or (not isDropKeyOnElevator()) or (stopElevator) or module.MODULE_STORAGE.statValues.inspection or overshot or releveling) then return end
			module.MODULE_STORAGE.statValues.destination = dest
			local regFloor = findRegisteredFloor(dest)
			if (not regFloor) then return end
			if (dest == module.MODULE_STORAGE.statValues.rawFloor) then
				removeCall(dest)
				if (checkDoorStates('Closed')) then
					api:Fire('onElevatorCall', {Floor=dest})
					if ((not module.MODULE_STORAGE.statValues.fireService) and (not checkIndependentService())) then
						task.spawn(doLanterns, module.MODULE_STORAGE.statValues.rawFloor,configFile.Color_Database.Lanterns.Active_On_Door_Open,configFile.Color_Database.Lanterns.Active_After_Door_Open,module.MODULE_STORAGE.statValues.queueDirection)
						task.spawn(runChime, module.MODULE_STORAGE.statValues.rawFloor,configFile.Sound_Database.Chime_Events.On_Open,configFile.Sound_Database.Chime_Events.After_Open,module.MODULE_STORAGE.statValues.queueDirection, true)
						if (getTableLength(regFloor.exteriorCallDirections) > 0) then
							runChime(dest or module.MODULE_STORAGE.statValues.rawFloor, configFile.Sound_Database.Chime_Events.Exterior_Call_Only, configFile.Sound_Database.Chime_Events.After_Open, true)
							doLanterns(dest or module.MODULE_STORAGE.statValues.rawFloor, configFile.Color_Database.Lanterns.Active_On_Exterior_Call, configFile.Color_Database.Lanterns.Active_After_Door_Open)
						end
					end
					if (module.MODULE_STORAGE.statValues.moveValue == 0) then
						safeCheckRelevel()
					end
					if (configFile.Movement.Open_Doors_On_Call) then
						runDoorOpen(module.MODULE_STORAGE.statValues.rawFloor, 'ALL')
					end
				end
			else
				if ((not checkDoorStates('Closed') or lock or (module.MODULE_STORAGE.statValues.moveValue ~= 0 and (not preDooring))) or moveBrake or module.MODULE_STORAGE.statValues.inspection or overshot or stopElevator or (not isDropKeyOnElevator())) then coroutine.yield() end

				local directionString = dest > module.MODULE_STORAGE.statValues.rawFloor and 'U' or dest < module.MODULE_STORAGE.statValues.rawFloor and 'D' or 'N'
				local directionValue = dest > module.MODULE_STORAGE.statValues.rawFloor and 1 or dest < module.MODULE_STORAGE.statValues.rawFloor and -1 or 0

				lock = true
				isMoving = true
				module.MODULE_STORAGE.statValues.moveDirection = directionString
				module.MODULE_STORAGE.statValues.queueDirection = park and 'N' or directionString
				module.MODULE_STORAGE.statValues.arrowDirection = park and 'N' or directionString
				preDirection = 'N'
				module.MODULE_STORAGE.statValues.moveValue = directionValue
				module.MODULE_STORAGE.statValues.parking = park
				api:Fire('onDepartStart', { destination = dest, directionString = directionString, directionValue = directionValue })

				outputElevMessage(`Elevator is now departing from floor {module.MODULE_STORAGE.statValues.rawFloor} to {module.MODULE_STORAGE.statValues.destination}`, 'debug')

				task.spawn(updateCore)
				task.spawn(doPlayerWeld)
				if (moveBrake or module.MODULE_STORAGE.statValues.inspection or overshot or stopElevator or (not isDropKeyOnElevator()) or ((not checkDoorStates('Closed')) and (not preDooring))) then
					if (not safetyBraking) then
						module.MODULE_STORAGE.statValues.currentSpeed = 0
						module.MODULE_STORAGE.statValues.moveValue = 0
						module.MODULE_STORAGE.statValues.moveDirection = 'N'
						lock = false
						setDirection(module.MODULE_STORAGE.statValues.rawFloor, 'N')
						preDooring = false
						releveling = false
						overshot = false
						module.MODULE_STORAGE.statValues.leveling = false
						preChimeFloor = nil
						safetyBraking = false
						removePlayerWelds()
						updateCore()
					end
					return
				end

				task.delay(configFile.Movement.Motor_Start_Delay[module.MODULE_STORAGE.statValues.moveValue == 1 and 'Up' or module.MODULE_STORAGE.statValues.moveValue == -1 and 'Down'], function()
					if (moveBrake or module.MODULE_STORAGE.statValues.inspection or overshot or stopElevator or (not isDropKeyOnElevator()) or ((not checkDoorStates('Closed')) and (not preDooring))) then
						if (not safetyBraking) then
							module.MODULE_STORAGE.statValues.currentSpeed = 0
							module.MODULE_STORAGE.statValues.moveValue = 0
							module.MODULE_STORAGE.statValues.moveDirection = 'N'
							lock = false
							setDirection(module.MODULE_STORAGE.statValues.rawFloor, 'N')
							preDooring = false
							releveling = false
							overshot = false
							module.MODULE_STORAGE.statValues.leveling = false
							preChimeFloor = nil
							safetyBraking = false
							removePlayerWelds()
							updateCore()
						end
						return
					end
					doMotorSound()
				end)
				module.MODULE_STORAGE.miscValues.leaving = true
				module.MODULE_STORAGE.statValues.departFloor = module.MODULE_STORAGE.statValues.rawFloor
				if (configFile.Movement.Pre_Start_Data.Enabled) then
					task.spawn(function()
						local hasCompleted = conditionalStepWait(configFile.Movement.Pre_Start_Data.Floor_Change_Delay, function() return {moveBrake or module.MODULE_STORAGE.statValues.inspection or overshot or stopElevator or (not isDropKeyOnElevator()) or ((not checkDoorStates('Closed')) and (not preDooring))} end)
						if (not hasCompleted) then return end
						repeat
							if (moveBrake or module.MODULE_STORAGE.statValues.inspection or overshot or stopElevator or (not isDropKeyOnElevator()) or ((not checkDoorStates('Closed')) and (not preDooring))) then
								if (not safetyBraking) then
									module.MODULE_STORAGE.statValues.currentSpeed = 0
									module.MODULE_STORAGE.statValues.moveValue = 0
									module.MODULE_STORAGE.statValues.moveDirection = 'N'
									lock = false
									setDirection(module.MODULE_STORAGE.statValues.rawFloor, 'N')
									preDooring = false
									releveling = false
									overshot = false
									module.MODULE_STORAGE.statValues.leveling = false
									preChimeFloor = nil
									safetyBraking = false
									removePlayerWelds()
									updateCore()
								end
								return
							end
							preChimeFloor = module.MODULE_STORAGE.statValues.currentFloor
							module.MODULE_STORAGE.statValues.currentFloor += module.MODULE_STORAGE.statValues.moveValue
							updateCore()
						until (findFloor(module.MODULE_STORAGE.statValues.currentFloor))
						local hasCompleted = conditionalStepWait(configFile.Movement.Pre_Start_Data.Chime_Delay, function() return {moveBrake or module.MODULE_STORAGE.statValues.inspection or overshot or stopElevator or (not isDropKeyOnElevator()) or ((not checkDoorStates('Closed')) and (not preDooring))} end)
						if (not hasCompleted) then return end
						if (module.MODULE_STORAGE.statValues.currentFloor == module.MODULE_STORAGE.statValues.destination or moveBrake or module.MODULE_STORAGE.statValues.inspection or overshot or stopElevator or (not isDropKeyOnElevator()) or ((not checkDoorStates('Closed')) and (not preDooring)) or checkIndependentService() or module.MODULE_STORAGE.statValues.fireService) then return end
						addPlaySound(module.MODULE_STORAGE.sounds.Floor_Pass_Chime, platform)
					end)
				end
				conditionalStepWait(configFile.Movement.Jolt_Start_Data.Enable and configFile.Movement.Jolt_Start_Data.Start_Delay or 0, function() return {moveBrake or module.MODULE_STORAGE.statValues.inspection or overshot or stopElevator or (not isDropKeyOnElevator()) or ((not checkDoorStates('Closed')) and (not preDooring))} end)
				if (configFile.Movement.Jolt_Start_Data.Enable and (not departPreStarting)) then
					local done = false
					local checked = false
					local lastSpeed = module.MODULE_STORAGE.statValues.currentSpeed
					local startTime = os.clock()
					while (not checked) do
						local delta = updateCore()
						if (moveBrake or module.MODULE_STORAGE.statValues.inspection or overshot or stopElevator or (not isDropKeyOnElevator()) or ((not checkDoorStates('Closed')) and (not preDooring))) then
							if (not safetyBraking) then
								module.MODULE_STORAGE.statValues.currentSpeed = 0
								module.MODULE_STORAGE.statValues.moveValue = 0
								module.MODULE_STORAGE.statValues.moveDirection = 'N'
								lock = false
								setDirection(module.MODULE_STORAGE.statValues.rawFloor, 'N')
								preDooring = false
								releveling = false
								overshot = false
								module.MODULE_STORAGE.statValues.leveling = false
								preChimeFloor = nil
								safetyBraking = false
								removePlayerWelds()
								updateCore()
							end
							return
						end
						module.MODULE_STORAGE.statValues.currentSpeed = -(math.sin(math.abs(os.clock()-startTime)*math.pi*configFile.Movement.Jolt_Start_Data.Speed)*configFile.Movement.Jolt_Start_Data.Ratio)/(math.pi)
						local spd = module.MODULE_STORAGE.statValues.currentSpeed
						if ((lastSpeed-spd) > 0) then
							lastSpeed = spd
						elseif (spd >= 0) then
							checked = true
						end
					end
				end
				if (configFile.Movement.Depart_Pre_Start and configFile.Movement.Depart_Pre_Start.Enable and departPreStarting) then
					conditionalStepWait(configFile.Movement.Depart_Pre_Start.Delay, function()
						return {(moveBrake or module.MODULE_STORAGE.statValues.inspection or overshot or stopElevator or (not isDropKeyOnElevator()) or ((not checkDoorStates('Closed')) and (not preDooring)))}
					end)
				elseif ((not configFile.Movement.Depart_Pre_Start) or (not configFile.Movement.Depart_Pre_Start.Enable) or configFile.Movement.Depart_Pre_Start.Ignore_Start_Delay) then
					conditionalStepWait(module.MODULE_STORAGE.statValues.moveValue == 1 and (configFile.Movement.Start_Delay or 0) or module.MODULE_STORAGE.statValues.moveValue == -1 and configFile.Movement.Down_Start_Delay or 0, function()
						return {(moveBrake or module.MODULE_STORAGE.statValues.inspection or overshot or stopElevator or (not isDropKeyOnElevator()) or ((not checkDoorStates('Closed')) and (not preDooring)))}
					end)
				end
				if (moveBrake or module.MODULE_STORAGE.statValues.inspection or overshot or stopElevator or (not isDropKeyOnElevator()) or ((not checkDoorStates('Closed')) and (not preDooring))) then
					if (not safetyBraking) then
						module.MODULE_STORAGE.statValues.currentSpeed = 0
						module.MODULE_STORAGE.statValues.moveValue = 0
						module.MODULE_STORAGE.statValues.moveDirection = 'N'
						lock = false
						setDirection(module.MODULE_STORAGE.statValues.rawFloor, 'N')
						preDooring = false
						releveling = false
						overshot = false
						module.MODULE_STORAGE.statValues.leveling = false
						preChimeFloor = nil
						safetyBraking = false
						removePlayerWelds()
						updateCore()
					end
					return
				end
				departPreStarting = false
				api:Fire('onElevatorMoveBegin', {directionString=directionString,directionValue=directionValue})

				local topSpeed = configFile.Movement.Travel_Speed
				local offset = math.random(1,configFile.Movement.Overdrive_Chance_Max) == 1 and 1.1 or 0
				local startTick = os.clock()
				local startingSpeed = module.MODULE_STORAGE.statValues.currentSpeed
				local rate = (module.MODULE_STORAGE.statValues.moveValue == 1 and configFile.Movement.Acceleration or module.MODULE_STORAGE.statValues.moveValue == -1 and configFile.Movement.Down_Acceleration or 0)
				local lvlOffset = module.MODULE_STORAGE.statValues.moveValue == 1 and configFile.Sensors.Up_Level_Offset or module.MODULE_STORAGE.statValues.moveValue == -1 and configFile.Sensors.Down_Level_Offset or 0
				local dynamicAccelRate = 1/math.deg(configFile.Movement.Dynamic_Acceleration_Time)
				local startT = os.clock()
				local dynamicAccelValue = 0
				while (getFloorDistance(module.MODULE_STORAGE.statValues.destination or dest) > lvlOffset*(module.MODULE_STORAGE.statValues.currentSpeed*configFile.Movement.Level_Offset_Ratio)) do
					local deltaTime = updateCore()
					dynamicAccelValue = math.clamp(dynamicAccelValue+dynamicAccelRate*math.deg(deltaTime), 0, 1)
					module.MODULE_STORAGE.statValues.currentSpeed = math.clamp(module.MODULE_STORAGE.statValues.currentSpeed+rate*dynamicAccelValue*math.deg(deltaTime), 0, topSpeed)
					lvlOffset = module.MODULE_STORAGE.statValues.moveValue == 1 and configFile.Sensors.Up_Level_Offset or module.MODULE_STORAGE.statValues.moveValue == -1 and configFile.Sensors.Down_Level_Offset or 0
					if (moveBrake or module.MODULE_STORAGE.statValues.inspection or overshot or stopElevator or (not isDropKeyOnElevator()) or ((not checkDoorStates('Closed')) and (not preDooring))) then
						if (not safetyBraking) then
							module.MODULE_STORAGE.statValues.currentSpeed = 0
							module.MODULE_STORAGE.statValues.moveValue = 0
							module.MODULE_STORAGE.statValues.moveDirection = 'N'
							lock = false
							setDirection(module.MODULE_STORAGE.statValues.rawFloor, 'N')
							preDooring = false
							releveling = false
							overshot = false
							module.MODULE_STORAGE.statValues.leveling = false
							preChimeFloor = nil
							safetyBraking = false
							removePlayerWelds()
							updateCore()
						end
						return
					end
				end
				elevatorProcessRunStop(module.MODULE_STORAGE.statValues.destination or dest)
				return
			end
		end

		--// 8/04/2023 -- NEW QUEUE HANDLER REVAMP & DIRECTIONAL QUEUE //--
		function checkCallInDirection(call: number, direction: number?)
			local result,index,dist = nil,nil,math.huge
			for i,c in next,module.MODULE_STORAGE.queue do
				if (math.abs(c.call-call) <= dist and c.call ~= call and (((c.call > call and direction == 1) or (c.call < call and direction == -1)) or typeof(direction) ~= 'number' or direction == 0)) then
					index,result = i,c
					dist = math.abs(c.call-call)
				end
			end
			return result,index
		end
		function findCallInQueue(call: any, direction: any?) -- Returns the queue item if queue item's floor matches the given floor. If the direction is supplied, it only returns the queue if the direction matches. Otherwise, just return the queue item
			for i,v in pairs(module.MODULE_STORAGE.queue) do
				if (v.call == call and (typeof(direction) ~= 'number' or table.find(v.directions, direction) or #v.directions == 0)) then return i,v end
			end
			return nil
		end
		function addCall(call: number, direction: number?, bypassFireRecall: boolean?, callTypes: {car: boolean?, hall: boolean?}?)
			call = tonumber(call)
			local regFloor = findRegisteredFloor(call)
			if ((not regFloor) or (module.MODULE_STORAGE.statValues.fireRecall and not bypassFireRecall)) then return end
			local result,index = findCallInQueue(call, direction)
			if (result or index) then return end
			local queueItemIndex,queueItem = findCallInQueue(call)
			if (not queueItem) then
				queueItem = { ['call']=call,['directions']=queueItem and queueItem.directions or {},['isCarCall']=if (typeof(callTypes) == 'table' and typeof(callTypes.car) == 'boolean') then callTypes.car else false,['isHallCall']=if (typeof(callTypes) == 'table' and typeof(callTypes.hall) == 'boolean') then callTypes.hall else false }
			end
			if (typeof(direction) == 'number' and direction ~= 0 and (not table.find(queueItem.directions,direction))) then
				table.insert(queueItem.directions, direction)
			end
			if (not findCallInQueue(call)) then
				table.insert(module.MODULE_STORAGE.queue,queueItem)
				api:Fire('onCallEnter', call)
				api:Fire('onCallAdded', {call=call,direction=direction})
			end
			if ((not module.MODULE_STORAGE.statValues.destination) or (
				(module.MODULE_STORAGE.statValues.queueDirection == 'U' or module.MODULE_STORAGE.statValues.moveValue == 1) and
					call > module.MODULE_STORAGE.statValues.rawFloor and
					call <= module.MODULE_STORAGE.statValues.destination
				) or
					(
						(module.MODULE_STORAGE.statValues.queueDirection == 'D' or module.MODULE_STORAGE.statValues.moveValue == -1) and
						call < module.MODULE_STORAGE.statValues.rawFloor and
						call >= module.MODULE_STORAGE.statValues.destination
					)
				) then
				module.MODULE_STORAGE.statValues.destination = call
			end
			if (module.MODULE_STORAGE.statValues.queueDirection == 'N') then
				module.MODULE_STORAGE.statValues.queueDirection = call > module.MODULE_STORAGE.statValues.rawFloor and 'U' or call < module.MODULE_STORAGE.statValues.rawFloor and 'D' or typeof(direction) == 'number' and direction == 1 and 'U' or direction == -1 and 'D' or 'N'
				module.MODULE_STORAGE.statValues.arrowDirection = module.MODULE_STORAGE.statValues.queueDirection
			end
			queueTableJSON.Value = httpService:JSONEncode(module.MODULE_STORAGE.queue)
			task.spawn(updateCore)
			if (checkDoorStates('Closed') and module.MODULE_STORAGE.statValues.moveValue == 0) then
				task.spawn(elevatorRun,call,false)
			end
			return true --// Indicating that the call has been added successfully //--
		end
		function removeCall(call: number, direction: number?)
			local regFloor = findRegisteredFloor(call)
			if (not regFloor) then return end
			local index,queueItem = findCallInQueue(call, direction)
			if ((not index) or (not queueItem)) then return --[[ warn(`Failed to remove call from queue: No call for {floor} in current queue!`) ]] end
			for i,v in pairs(module.MODULE_STORAGE.queue) do
				if (v.call == call and ((not direction) or table.find(v.directions, direction) or #v.directions == 0)) then
					local removedDirectionalCall = false
					local dirIndex = typeof(direction) == 'number' and direction ~= 0 and table.find(v.directions, direction)
					if (dirIndex) then
						table.remove(v.directions,dirIndex)
						local d = table.find(regFloor.exteriorCallDirections, direction)
						if (d) then
							--table.remove(regFloor.exteriorCallDirections, d)
							removedDirectionalCall = true
						end
						resetButtons(call)
					end
					if ((not v.directions) or #v.directions == 0) then
						table.remove(module.MODULE_STORAGE.queue, i)
						api:Fire('onCallRemove', call)
						api:Fire('onCallRemoved', {call=call,direction=direction})
						resetButtons(call)
						if (#module.MODULE_STORAGE.queue == 0 and call ~= topFloor and call ~= bottomFloor and (not removedDirectionalCall)) then
							module.MODULE_STORAGE.statValues.queueDirection = 'N'
							module.MODULE_STORAGE.statValues.arrowDirection = module.MODULE_STORAGE.statValues.queueDirection
							task.spawn(updateCore)
						end
						queueTableJSON.Value = httpService:JSONEncode(module.MODULE_STORAGE.queue)
						--[[ warn(`Removed call from queue: Floor: {floor}`, v) ]]
						return true
					end
				end
			end
			return false -- warn('Queue: No calls removed')
		end
		queueTableJSON:GetPropertyChangedSignal('Value'):Connect(function()
			queueTableJSON.Value = httpService:JSONEncode(module.MODULE_STORAGE.queue)
		end)
		local function getAllCallsByTypesAsync(types: { car: boolean?, hall: boolean? })
			if (typeof(types) ~= 'table') then return end
			local calls = {}
			for _,v in pairs(module.MODULE_STORAGE.queue) do
				if ((types.car and v.isCarCall) or (types.hall and v.isHallCall)) then
					table.insert(calls, v)
				end
			end
			return calls
		end

		----

		function updateButton(button, config, state, from)
			if typeof(button) == 'string' then -- Adding string support
				button = {['Name'] = button, ['Parent'] = {['Parent'] = from}}
			end

			for i,v in pairs(button.Parent.Parent:GetDescendants()) do
				if (v.Name == 'Buttons' or v.Name == 'Call_Buttons') then
					for i,b in pairs(v:GetDescendants()) do
						if b.Name == button.Name then
							local config = config[state]
							local buttonFloor = tonumber(string.split(b.Name,'Floor')[2]) or tonumber(string.split(b.Name,'Floor_')[2])
							local colorConfig = buttonFloor and configFile.Color_Database.Car.Custom_Color_Data[buttonFloor] or configFile.Color_Database.Car.Custom_Color_Data[tostring(buttonFloor)]
							if (colorConfig) then
								config = { Color=colorConfig[state].Color,Material=colorConfig[state].Material }
							end
							for i,t in pairs(b:GetDescendants()) do
								if (t.Name == 'Light') then
									if (t:IsA('BasePart')) then
										t.Color = config.Color
										t.Material = config.Material
									elseif (t:IsA('TextButton')) then
										t.TextColor3 = config.Color
										local sgui = t:FindFirstAncestorOfClass('SurfaceGui')
										if (sgui) then
											sgui.LightInfluence = 0
											sgui.Brightness = 2
										end
									end
								end
							end
						end
					end
				end
			end
		end

		function resetButtons(floor)
			local direction = module.MODULE_STORAGE.statValues.queueDirection == 'U' and 'Up' or module.MODULE_STORAGE.statValues.queueDirection == 'D' and 'Down' or 'Neutral'
			for i,v in pairs(car:GetChildren()) do
				if v.Name == 'Buttons' then
					for i,t in pairs(v:GetChildren()) do
						local buttonFloor = tonumber(string.split(t.Name,'Floor')[2]) or tonumber(string.split(t.Name,'Floor_')[2])
						if (buttonFloor and buttonFloor == floor) then
							updateButton(t, configFile.Color_Database.Car.Floor_Button, 'Neautral_State')
						end
					end
				end
			end
			if (not findFloor(floor)) then return end
			for i,v in pairs(findFloor(floor):GetChildren()) do
				if v.Name == 'Call_Buttons' then
					for i,t in pairs(v:GetChildren()) do
						if (t.Name:sub(1,1) == module.MODULE_STORAGE.statValues.queueDirection) then
							updateButton(t, configFile.Color_Database.Floor[direction], 'Neautral_State')
						end
					end
				end
			end

		end

		function addGhostPart(part)
			local newPart = Instance.new('Part')
			part.Name = 'FakeButton'
			newPart.Name = 'Button'
			newPart.Transparency = 1
			newPart.CFrame = part.CFrame
			newPart.Size = part.Size*1.5
			newPart.CanCollide = false
			newPart.Anchored = true
			newPart.Parent = part.Parent
			local weld
			if (part:IsDescendantOf(car)) then
				for i,w in pairs(car:GetDescendants()) do
					if (w:IsA('Weld') and (w.Part0 == part or w.Part1 == part) and w.Name ~= 'NewWeld') then
						w:Destroy()
					end
				end
				car.DescendantAdded:Connect(function(w: Weld)
					task.wait()
					if (w:IsA('Weld') and (w.Part0 == part or w.Part1 == part) and w.Name ~= 'NewWeld') then
						w:Destroy()
					end
				end)
				weldTogether(newPart, platform, true)
			end
			local weld = weldTogether(part, newPart, false)
			weld.Name = 'NewWeld'
			weld.Parent = newPart
			return newPart, weld
		end

		for i,v in pairs(car:GetChildren()) do
			if (v.Name == 'Buttons') then
				for i,btn in pairs(v:GetChildren()) do

					local buttonPart = btn:FindFirstChild('Button')
					if (buttonPart) then
						buttonPart:SetAttribute('isACortexElevButton', true)
					end

					if (btn.Name:sub(1,5) == 'Floor' or btn.Name:sub(1,6) == 'Floor_') then
						updateButton(btn, configFile.Color_Database.Car.Floor_Button, 'Neautral_State')
					elseif (btn.Name:match('DoorHold')) then
						updateButton(btn, configFile.Color_Database.Car.Doors.Hold, 'Neutral')
					elseif (btn.Name == 'CallCancel' or btn.Name == 'Call_Cancel') then
						updateButton(btn, configFile.Color_Database.Car.Doors.Hold, 'Neutral')
					elseif (btn.Name:match('DoorOpen')) then
						updateButton(btn, configFile.Color_Database.Car.Doors.Open, 'Neutral')
					elseif (btn.Name:match('DoorClose')) then
						updateButton(btn, configFile.Color_Database.Car.Doors.Close, 'Neutral')
					elseif (btn.Name == 'Alarm') then
						updateButton(btn, configFile.Color_Database.Car.Alarm_Button, 'Neautral_State')
					end

				end
			end
			for i,f in pairs(floors:GetChildren()) do
				for i,v in pairs(f:GetChildren()) do
					if (string.match(v.Name, 'Call_Buttons')) then
						for i,btn in pairs(v:GetChildren()) do

							local buttonPart = btn:FindFirstChild('Button')
							if (buttonPart) then
								buttonPart:SetAttribute('isACortexElevButton', true)
							end

							if (btn.Name == 'Up' or btn.Name == 'Down') then
								updateButton(btn, configFile.Color_Database.Floor[btn.Name], 'Neautral_State')
							elseif (string.match(btn.Name, 'DoorOpen') or string.match(btn.Name, 'DoorClose')) then
								updateButton(btn, configFile.Color_Database.Car.Doors[string.match(btn.Name, 'DoorOpen') and 'Open' or string.match(btn.Name, 'DoorClose') and 'Close'], 'Neutral')
							elseif string.match(btn.Name, 'DoorStop') then
							end
						end
					end
				end
			end
		end

		for _, v in pairs(elevator:GetDescendants()) do
			if v:IsA('Model') and v.Name == 'Inspection_Controls' then
				for _, btn in pairs(v.Buttons:GetChildren()) do
					if (btn.Name ~= 'Inspection_Switch' and btn.Name ~= 'Up' and btn.Name ~= 'Down' and btn.Name ~= 'Common' and btn.Name ~= 'Enable' and btn.Name ~= 'Alarm' and btn.Name ~= 'Stop') then continue end
					if not btn:IsA('Model') then
						local model = Instance.new('Model')
						model.Name = btn.Name
						btn.Name = 'Button'
						model.Parent = btn.Parent
						btn.Parent = model
						btn = model
					elseif btn:IsA('Model') then
						if not btn:FindFirstChild('Button') then
							local foundPart = btn:FindFirstChildOfClass('BasePart') 
							if foundPart then
								foundPart.Name = 'Button'
							end
						end
					end

					local part, weld = addGhostPart(btn.Button)
					if btn.Name == 'Inspection_Switch' then
						local on,off = weld.C0*CFrame.Angles(0, 0, -math.rad(90)),weld.C0
						btn:SetAttribute('onCF', on)
						btn:SetAttribute('offCF', off)
						inspectionSwitchClick = addSound(part, 'Switch_Click', {
							Sound_Id = 9117028605,
							Volume = .5,
							Pitch = 1
						}, false, false, 40, 3)
					elseif (btn.Name == 'Up' or btn.Name == 'Down' or btn.Name == 'Common' or btn.Name == 'Enable' or btn.Name == 'Alarm' or btn.Name == 'Stop') then
						local down, up = weld.C0*CFrame.new(math.rad(1.5), 0, 0),weld.C0
						local btnSoundId = 9119719973
						local btnSoundVolume = .5

						if btn.Name == 'Stop' then
							down = weld.C0*CFrame.new(0, math.rad(1.5), 0)
							btnSoundId = 9117028605
							btnSoundVolume = .5
						end

						btn:SetAttribute('downCF', down)
						btn:SetAttribute('upCF', up)
						inspectionButtonClick[btn.Name] = addSound(part, 'Button_Click', {
							Sound_Id = btnSoundId,
							Volume = btnSoundVolume,
							Pitch = 1
						}, false, false, 40, 3)
					end
					btn.Button:SetAttribute('isACortexElevButton', true)
				end
			end
		end

		for i,v in pairs(floors:GetChildren()) do
			resetLanterns(tonumber(v.Name:sub(7)))
		end

		function findNearestFloor()
			local nFloor
			local dist = math.huge
			local carRecallPos = level.Position.Y+(module.MODULE_STORAGE.statValues.moveValue*((module.MODULE_STORAGE.statValues.currentSpeed+5)^1.5))
			for i,v in pairs(floors:GetChildren()) do

				local isAFloor = tonumber(string.split(v.Name, 'Floor_')[2])
				if (isAFloor) then
					local level = v:FindFirstChild('Level')
					if (level and math.abs(level.Position.Y-carRecallPos) <= dist) then
						dist = math.abs(level.Position.Y-carRecallPos)
						module.MODULE_STORAGE.miscValues.nFloor = isAFloor
					end
				end

			end

			return module.MODULE_STORAGE.miscValues.nFloor
		end

		--Fire recall--

		local allFireRecallEventListeners = {}

		function fireRecall(bool, floor)
			local regFloor = findRegisteredFloor(module.MODULE_STORAGE.statValues.rawFloor)
			if (not regFloor) then return end
			fireRecallFloor = floor
			module.MODULE_STORAGE.statValues.fireRecall = bool
			module.MODULE_STORAGE.statValues.fireService = bool
			module.MODULE_STORAGE.statValues.phase1 = bool
			task.spawn(updateCore)
			outputElevMessage(`Elevator has been placed {bool and 'into' or 'out of'} fire service to floor {floor}`, 'warning')
			if (bool) then

				local function handleDoors()
					if (checkDoorStates('Open', {dontRequireAll=true,onlyPresentDoors=false})) then
						module.MODULE_STORAGE.sounds.Nudge_Buzzer.Playing = false
						module.MODULE_STORAGE.statValues.fireRecall = false
						return
					end
					for _,doorData in pairs(pluginModules_INTERNAL.Storage.CONTENT:getContentInBranch('masterDoorData')) do
						if (not regFloor.floorInstance:FindFirstChild(`{doorData.side == '' and '' or `{doorData.side}_`}Doors`)) then continue end
						if (doorData.state ~= 'Open') then
							local connection: RBXScriptConnection
							connection = doorData.Opened:Connect(function()
								connection:Disconnect()
								if (not checkDoorStates('Open', {dontRequireAll=true,onlyPresentDoors=false})) then return end
								module.MODULE_STORAGE.sounds.Nudge_Buzzer.Playing = false
								module.MODULE_STORAGE.statValues.fireRecall = false
							end)
							table.insert(allFireRecallEventListeners, connection)
						end
					end
				end
				
				module.MODULE_STORAGE.statValues.queueDirection = 'N'
				task.spawn(updateCore)
				module.MODULE_STORAGE.sounds.Nudge_Buzzer.Playing = true
				for _,v in pairs(registeredFloors) do
					resetButtons(v.floorNumber)
					resetLanterns(v.floorNumber, {'Interior', 'Exterior'})
				end
				removeAllCalls()
				
				local isOnFloor = module.MODULE_STORAGE.statValues.rawFloor == floor and (module.MODULE_STORAGE.statValues.moveValue == 0 or module.MODULE_STORAGE.statValues.leveling)
				if (not isOnFloor) then -- // Not on floor, elevator must stop at nearest floor
					local direction = module.MODULE_STORAGE.statValues.moveValue
					local nearFloor,nearDist = nil,math.huge
					for _,flr in pairs(registeredFloors) do
						local thisDist = math.abs(flr.floorInstance.Level.Position.Y-level.Position.Y)
						if (thisDist < nearDist and ((direction == 1 and flr.floorNumber > module.MODULE_STORAGE.statValues.rawFloor) or (direction == -1 and flr.floorNumber < module.MODULE_STORAGE.statValues.rawFloor))) then
							nearDist = thisDist
							nearFloor = flr
						end
					end
					if (nearFloor and module.MODULE_STORAGE.statValues.moveValue ~= 0) then
						addCall(nearFloor.floorNumber, nil, true)
					end
					
					if module.MODULE_STORAGE.statValues.moveValue == 0 then
						task.spawn(runDoorClose, module.MODULE_STORAGE.statValues.rawFloor, 'ALL', true)
						addCall(floor, nil, true)
					end
					
					local connection: RBXScriptConnection
					connection = api.Event:Connect(function(protocol, params)
						if (protocol == 'onElevatorStop') then
							if (module.MODULE_STORAGE.statValues.rawFloor ~= floor) then
								addCall(floor, nil, true)
							else
								connection:Disconnect()
								handleDoors()
							end
						end
					end)
					table.insert(allFireRecallEventListeners, connection)
				else
					task.spawn(runDoorOpen, floor, 'ALL')
					handleDoors()
				end
			else
				for i,v in pairs(allFireRecallEventListeners) do
					v:Disconnect()
				end
				allFireRecallEventListeners = {}
			end
		end

		local prevValue = independentService
		local function setIndependentService(bool)
			independentService = bool
			outputElevMessage(`Elevator has been placed {bool and 'into' or 'out of'} independent service`, 'warning')
			if (prevValue ~= independentService) then
				prevValue = independentService
				removeAllCalls()
				updateCore()
				if (bool) then
					if (configFile.Sound_Database.Voice_Config.Enabled and voiceConfig.Settings.Door_Announcements.Open_Announcement.Enabled) then
						playVoiceSequenceProtocolWithQueue(voiceConfig.Settings.Door_Announcements.Open_Announcement.Sequence, false)
					end
					--If the elevator is already on the recall floor, open the doors (if closed or closing)
					for i,doorData in pairs(pluginModules_INTERNAL.Storage.CONTENT:getContentInBranch('masterDoorData')) do
						if (doorData.state == 'Closed' or doorData.state == 'Closing' or doorData.state == 'Stopped') then
							runDoorOpen(module.MODULE_STORAGE.statValues.rawFloor, doorData.side)
						end
					end
				end
			end
		end

		local pressDebounce,buttonPressHandlerDebounce = false,false --Soon to be replaced with collectionService tags
		local isAlarmPlaying = false --Soon to be replaced with collectionService tags


		local lastCarButtonPressed = os.clock()
		local function handleRemoteButtonInput(event: string, params: any)
			if (event ~= 'onButtonPressed' and event ~= 'onButtonReleased') then return end
			local btn = params.button
			if (not btn) then return end

			if (not btn:FindFirstAncestor('Inspection_Controls')) then
				if (event == 'onButtonPressed') then
					addPlaySound(btn:IsDescendantOf(car) and module.MODULE_STORAGE.sounds.Button_Beep or module.MODULE_STORAGE.sounds.Call_Button_Beep, btn.Button)
				end
				local buttonFloor = tonumber(string.split(btn.Name,'Floor_')[2]) or tonumber(string.split(btn.Name,'Floor')[2])
				if (buttonFloor) then
					lastCarButtonPressed = os.clock()
					local resetStatement = (not findFloor(buttonFloor))
						or (not isDropKeyOnElevator())
						or ((module.MODULE_STORAGE.statValues.rawFloor == buttonFloor or module.MODULE_STORAGE.statValues.arriveFloor == buttonFloor) and (module.MODULE_STORAGE.statValues.moveValue == 0 or module.MODULE_STORAGE.statValues.leveling))
						or (module.MODULE_STORAGE.statValues.inspection or stopElevator or (module.MODULE_STORAGE.statValues.phase1 and not checkPhase2()))
						or ((lockedFloors[tostring(buttonFloor)] and not checkPhase2()) and (not findCallInQueue(buttonFloor)))
						or (configFile.Locking.Lock_Opposite_Travel_Direction_Floors and ((module.MODULE_STORAGE.statValues.queueDirection == 'U' and (buttonFloor < module.MODULE_STORAGE.statValues.rawFloor) or (module.MODULE_STORAGE.statValues.queueDirection == 'D' and (buttonFloor > module.MODULE_STORAGE.statValues.rawFloor)) or buttonFloor == module.MODULE_STORAGE.statValues.rawFloor and checkDoorStates('Closed')))) 
						or ((not findCallInQueue(buttonFloor)) and (configFile.Call_Limiting.Enable and #getAllCallsByTypesAsync({ car = true })+1 > configFile.Call_Limiting.Max_Calls))
					if (event == 'onButtonPressed') then
						updateButton(btn, configFile.Color_Database.Car.Floor_Button, 'Lit_State')
						if (not resetStatement) then
							local inQueue = findCallInQueue(buttonFloor)
							if (not inQueue) then
								task.delay(configFile.Sound_Database.Others.Call_Recognition_Beep.Delay, function()
									if (buttonFloor == module.MODULE_STORAGE.statValues.rawFloor) then return end
									addPlaySound(module.MODULE_STORAGE.sounds.Call_Recognition_Beep, platform)
								end)
								for _,v in pairs(pluginModules_INTERNAL.Storage.CONTENT:getContentInBranch('masterDoorData')) do
									if (not configFile.Doors.Close_On_Button_Press.Enable) then continue end
									task.spawn(function()
										local hasPassed = conditionalStepWait(configFile.Doors.Close_On_Button_Press.Delay, function() return {v.side == 'Open'} end)
										if (not hasPassed) then return end
										task.spawn(runDoorClose, module.MODULE_STORAGE.statValues.rawFloor, v.side)
									end)
								end
							end

							addCall(buttonFloor, nil, nil, { car = true })
							if (checkDoorStates('Closed')) then return end
							task.spawn(doLanterns, module.MODULE_STORAGE.statValues.rawFloor,configFile.Color_Database.Lanterns.Active_On_Call_Enter,configFile.Color_Database.Lanterns.Active_After_Door_Open,module.MODULE_STORAGE.statValues.queueDirection)
							task.spawn(runChime, module.MODULE_STORAGE.statValues.rawFloor,configFile.Sound_Database.Chime_Events.New_Call_Input,configFile.Sound_Database.Chime_Events.After_Open,module.MODULE_STORAGE.statValues.queueDirection, true)
						elseif (buttonFloor == module.MODULE_STORAGE.statValues.rawFloor and module.MODULE_STORAGE.statValues.moveValue == 0 and not module.MODULE_STORAGE.statValues.fireService) then
							for i,v in pairs(pluginModules_INTERNAL.Storage.CONTENT:getContentInBranch('masterDoorData')) do
								if (v.state == 'Closing' or v.state == 'Closed') then
									task.spawn(runDoorOpen,module.MODULE_STORAGE.statValues.rawFloor,v.side)
								end
							end
						end
					elseif (resetStatement) then
						if (((not findCallInQueue(buttonFloor)) and (configFile.Call_Limiting.Enable and #getAllCallsByTypesAsync({ car = true })+1 > configFile.Call_Limiting.Max_Calls))) then
							api:Fire('Call_Limiter_Rejection', { ['Call'] = buttonFloor, ['CallLength'] = #getAllCallsByTypesAsync({ car = true })+1 })
						end
						while ((os.clock()-lastCarButtonPressed) <= configFile.Color_Database.Car.Lit_Delay) do task.wait() end
						updateButton(btn, configFile.Color_Database.Car.Floor_Button, 'Neautral_State')
					end
				elseif (string.match(btn.Name, 'DoorOpen')) then

					local isManual = configFile.Doors.Manual_Door_Controls.Enable_Open
					local sideIndex = string.split(btn.Name, 'DoorOpen')[1]
					if (event == 'onButtonPressed') then
						updateButton(btn, configFile.Color_Database.Car.Doors.Open, 'Active')
						if ((btn:IsDescendantOf(car) or (btn:IsDescendantOf(floors) and module.MODULE_STORAGE.statValues.currentFloor == tonumber(string.split(btn:FindFirstAncestor('Call_Buttons').Parent.Name,'Floor_')[2]))) and (not moveBrake) --[[and (not isManual)]] and ((not module.MODULE_STORAGE.statValues.fireService and not module.MODULE_STORAGE.statValues.phase1) or checkPhase2()) and (module.MODULE_STORAGE.statValues.moveValue == 0) and (not module.MODULE_STORAGE.statValues.inspection)
							and (not (configFile.Locking.Disable_Door_Open_On_Locked_Floor.Car.When_Doors_Closing and btn:IsDescendantOf(car) and (lockedFloors[tostring(module.MODULE_STORAGE.statValues.rawFloor)] and not checkPhase2()) and getDoorData(sideIndex).state == 'Closing'))
							and (not (configFile.Locking.Disable_Door_Open_On_Locked_Floor.Car.When_Doors_Closed and btn:IsDescendantOf(car) and (lockedFloors[tostring(module.MODULE_STORAGE.statValues.rawFloor)] and not checkPhase2()) and getDoorData(sideIndex).state == 'Closed'))
							and (not (configFile.Locking.Disable_Door_Open_On_Locked_Floor.Hall.When_Doors_Closing and btn:IsDescendantOf(floors) and lockedHallFloors[tostring(module.MODULE_STORAGE.statValues.rawFloor)] and getDoorData(sideIndex).state == 'Closing'))
							and (not (configFile.Locking.Disable_Door_Open_On_Locked_Floor.Hall.When_Doors_Closed and btn:IsDescendantOf(floors) and lockedHallFloors[tostring(module.MODULE_STORAGE.statValues.rawFloor)] and getDoorData(sideIndex).state == 'Closed'))
							)
						then
							if (stopElevator) then return end
							task.spawn(runDoorOpen,module.MODULE_STORAGE.statValues.rawFloor,sideIndex)
							btn:SetAttribute('Is_Down', true)
							local doorData = getDoorData(sideIndex)
							if (not doorData) then return end
							while (btn:GetAttribute('Is_Down')) do
								HEARTBEAT:Wait()
								doorData.doorTimerTick = os.clock()
							end
						end
					else
						task.delay(configFile.Color_Database.Car.Lit_Delay, function()
							updateButton(btn, configFile.Color_Database.Car.Doors.Open, 'Neutral')
						end)
						btn:SetAttribute('Is_Down', false)
						if (not (checkPhase2() --[[or isManual]])) then return end
						if ((btn:IsDescendantOf(car) or (btn:IsDescendantOf(floors) and module.MODULE_STORAGE.statValues.currentFloor == tonumber(string.split(btn:FindFirstAncestor('Call_Buttons').Parent.Name,'Floor_')[2]))) and (findFloor(module.MODULE_STORAGE.statValues.rawFloor) and findFloor(module.MODULE_STORAGE.statValues.rawFloor):FindFirstChild(sideIndex..(sideIndex == '' and '' or '_')..'Doors')) and getDoorState(sideIndex).state == 'Opening') then
							task.spawn(runDoorClose,module.MODULE_STORAGE.statValues.rawFloor,sideIndex)
						end
					end
				elseif (string.match(btn.Name, 'DoorClose')) then
					local isManual = configFile.Doors.Manual_Door_Controls.Enable_Close
					local sideIndex = string.split(btn.Name, 'DoorClose')[1]
					if (event == 'onButtonPressed') then
						updateButton(btn, configFile.Color_Database.Car.Doors.Close, 'Active')
						if ((btn:IsDescendantOf(car) or (btn:IsDescendantOf(floors) and module.MODULE_STORAGE.statValues.currentFloor == tonumber(string.split(btn:FindFirstAncestor('Call_Buttons').Parent.Name,'Floor_')[2]))) and (not moveBrake) --[[and (not isManual)]] and ((not module.MODULE_STORAGE.statValues.fireService and not module.MODULE_STORAGE.statValues.phase1) or checkPhase2() or checkIndependentService() or isManual) and (not module.MODULE_STORAGE.statValues.inspection) and (not getDoorState(sideIndex).Is_Obstructed) and (not stopElevator)) then
							if configFile.Doors.Disable_Door_Close and not (checkPhase2() or checkIndependentService() or isManual) then return end
							if not checkIndependentService() and not module.MODULE_STORAGE.statValues.fireService then
								local hasCompleted = conditionalStepWait(configFile.Doors.Door_Close_Button_Delay, function() return {getDoorState(sideIndex) == 'Open'} end)
								if (not hasCompleted) then return end
							end
							task.spawn(runDoorClose, module.MODULE_STORAGE.statValues.rawFloor, sideIndex)
						end
					else
						task.delay(configFile.Color_Database.Car.Lit_Delay, function()
							updateButton(btn, configFile.Color_Database.Car.Doors.Close, 'Neutral')
						end)
						if (not (checkPhase2() or checkIndependentService() or isManual)) then return end
						if ((btn:IsDescendantOf(car) or (btn:IsDescendantOf(floors) and module.MODULE_STORAGE.statValues.currentFloor == tonumber(string.split(btn:FindFirstAncestor('Call_Buttons').Parent.Name,'Floor_')[2]))) and (findFloor(module.MODULE_STORAGE.statValues.rawFloor) and findFloor(module.MODULE_STORAGE.statValues.rawFloor):FindFirstChild(sideIndex..(sideIndex == '' and '' or '_')..'Doors')) and getDoorState(sideIndex).state == 'Closing') then
							task.spawn(function()
								runDoorOpen(module.MODULE_STORAGE.statValues.rawFloor, sideIndex)
							end)
						end
					end

				elseif (btn.Name == 'Alarm') then

					if (event == 'onButtonPressed') then
						updateButton(btn, configFile.Color_Database.Car.Alarm_Button, 'Lit_State')
						if ((not configFile.Sound_Database.Others.Alarm.Pause_On_Release) or (not module.MODULE_STORAGE.sounds.Alarm.IsPlaying)) then
							module.MODULE_STORAGE.sounds.Alarm:Play()
						else
							module.MODULE_STORAGE.sounds.Alarm.Playing = true
						end
					else
						updateButton(btn, configFile.Color_Database.Car.Alarm_Button, 'Neautral_State')
						if (module.MODULE_STORAGE.sounds.Alarm.Playing) then
							module.MODULE_STORAGE.sounds.Alarm_Release:Play()
						end
						if (not configFile.Sound_Database.Others.Alarm.Pause_On_Release) then
							module.MODULE_STORAGE.sounds.Alarm:Stop()
						else
							module.MODULE_STORAGE.sounds.Alarm.Playing = false
						end
					end

				elseif (string.match(btn.Name, 'DoorHold')) then
					local isManual = configFile.Doors.Manual_Door_Controls.Enable_Close
					local sideIndex = string.split(btn.Name, 'DoorHold')[1]
					local doorData = getDoorData(sideIndex)
					if (not doorData) then return end
					if (event == 'onButtonPressed') then
						if (module.MODULE_STORAGE.statValues.moveValue ~= 0 and doorData.state == 'Closed') or (doorData.nudging) or (moveBrake) or (isManual) or (module.MODULE_STORAGE.statValues.phase1) or (module.MODULE_STORAGE.statValues.fireService) or (checkIndependentService()) or (checkPhase2()) or (module.MODULE_STORAGE.statValues.inspection) or (stopElevator) then return end
						doorData.doorHold = not doorData.doorHold
						task.spawn(updateCore)
						if (doorData.doorHold) then
							if ((not connection) or (not connection.Connected)) then
								connection = api.Event:Connect(function(protocol,params)
									if (protocol == 'onDoorClose' and params.side == sideIndex) then
										doorData.doorHold = false
										updateButton(btn, configFile.Color_Database.Car.Doors.Hold, 'Neutral')
										connection:Disconnect()
									end
								end)
							end
							doorData.doorTimerTick = os.clock()
							runDoorOpen(module.MODULE_STORAGE.statValues.rawFloor, sideIndex)
						else
							if (connection) then
								connection:Disconnect()
							end
						end
						updateButton(btn, configFile.Color_Database.Car.Doors.Hold, doorData.doorHold and 'Active' or 'Neutral')
					else
						if (not configFile.Color_Database.Car.Doors.Hold[doorData.doorHold and 'Active' or 'Neutral']) then return end
						updateButton(btn, configFile.Color_Database.Car.Doors.Hold, doorData.doorHold and 'Active' or 'Neutral')
					end
				elseif (string.match(btn.Name, 'DoorStop')) then
					local sideIndex = string.split(btn.Name, 'DoorStop')[1]
					local doorData = getDoorData(sideIndex)
					if (not doorData) then return end
					if (btn:IsDescendantOf(car) or (btn:IsDescendantOf(floors) and module.MODULE_STORAGE.statValues.currentFloor == tonumber(string.split(btn:FindFirstAncestor('Call_Buttons').Parent.Name,'Floor_')[2]))) then
						if (event == 'onButtonPressed') then
							if (doorData.nudging) then
								doorData.nudging = false
								module.MODULE_STORAGE.sounds.Nudge_Buzzer:Stop()
							end
							if (doorData.state == 'Opening' or doorData.state == 'Closing') then
								doorData.state = 'Stopped'
								HEARTBEAT:Wait()
								task.spawn(updateCore)
							end
						end
					end
				elseif (btn.Name == 'CallCancel' or btn.Name == 'Call_Cancel') then
					if (checkIndependentService() or checkPhase2()) then
						removeAllCalls()
						if (module.MODULE_STORAGE.statValues.moveValue == 1 or module.MODULE_STORAGE.statValues.moveValue == -1) then
							removeCall(module.MODULE_STORAGE.statValues.rawFloor)
						end
					end
				elseif (btn:IsDescendantOf(floors) and (btn.Name == 'Up' or btn.Name == 'Down')) then

					local floor = tonumber(string.split(btn.Parent.Parent.Name,'Floor_')[2])
					local direction = string.sub(btn.Name,1,1)
					local directionNumber = direction == 'U' and 1 or direction == 'D' and -1 or 0
					local regFloor = findRegisteredFloor(floor)
					if (not regFloor) then return end
					local isOnFloor = (floor == module.MODULE_STORAGE.statValues.rawFloor and (module.MODULE_STORAGE.statValues.moveValue == 0 or module.MODULE_STORAGE.statValues.leveling))

					if (event == 'onButtonPressed') then
						updateButton(btn, configFile.Color_Database.Floor[btn.Name], 'Lit_State', btn)

						if lockedHallFloors[tostring(floor)] or independentService or module.MODULE_STORAGE.statValues.fireService or stopElevator or outOfService then return end

						if (module.MODULE_STORAGE.statValues.rawFloor == floor and not module.MODULE_STORAGE.statValues.leveling) then
							if (configFile.Freight.Same_Floor_Call.With_Doors_Open.Enable and (checkDoorStates('Open', {dontRequireAll = true}) or checkDoorStates('Opening', {dontRequireAll = true}))) then
								if configFile.Freight.Same_Floor_Call.With_Doors_Open.Bell then
									btn:SetAttribute('AlarmRinging', true)
									module.MODULE_STORAGE.sounds.Alarm:Play()
								end
								if not configFile.Freight.Same_Floor_Call.With_Doors_Open.Call_Elevator then
									return btn:SetAttribute('NoCall', true)
								end
							elseif (configFile.Freight.Same_Floor_Call.With_Doors_Closed.Enable and (checkDoorStates('Closed') or checkDoorStates('Closing', {dontRequireAll = true}))) then
								if configFile.Freight.Same_Floor_Call.With_Doors_Closed.Bell then
									btn:SetAttribute('AlarmRinging', true)
									module.MODULE_STORAGE.sounds.Alarm:Play()
								end
								if not configFile.Freight.Same_Floor_Call.With_Doors_Closed.Call_Elevator then
									return btn:SetAttribute('NoCall', true)
								end
							end
						elseif (module.MODULE_STORAGE.statValues.rawFloor ~= floor or (module.MODULE_STORAGE.statValues.rawFloor == floor and module.MODULE_STORAGE.miscValues.leaving)) and not lockedHallFloors[tostring(floor)] then
							if (configFile.Freight.Other_Floor_Call.With_Doors_Open.Enable and (checkDoorStates('Open', {dontRequireAll = true}) or checkDoorStates('Opening', {dontRequireAll = true}))) then
								if configFile.Freight.Other_Floor_Call.With_Doors_Open.Bell then
									btn:SetAttribute('AlarmRinging', true)
									module.MODULE_STORAGE.sounds.Alarm:Play()
								end
								if not configFile.Freight.Other_Floor_Call.With_Doors_Open.Call_Elevator then
									return btn:SetAttribute('NoCall', true)
								end
							elseif (configFile.Freight.Other_Floor_Call.With_Doors_Closed.Enable and (checkDoorStates('Closed') or checkDoorStates('Closing', {dontRequireAll = true}))) then
								if configFile.Freight.Other_Floor_Call.With_Doors_Closed.Bell then
									btn:SetAttribute('AlarmRinging', true)
									module.MODULE_STORAGE.sounds.Alarm:Play()
								end
								if not configFile.Freight.Other_Floor_Call.With_Doors_Closed.Call_Elevator then
									return btn:SetAttribute('NoCall', true)
								end
							end
						end

						if (not isOnFloor) then
							addCall(floor,directionNumber,nil,{ hall = true })
							table.insert(regFloor.exteriorCallDirections,directionNumber)
						else
							if (direction == module.MODULE_STORAGE.statValues.queueDirection or module.MODULE_STORAGE.statValues.queueDirection == 'N') then
								module.MODULE_STORAGE.statValues.queueDirection = direction
								module.MODULE_STORAGE.statValues.arrowDirection = module.MODULE_STORAGE.statValues.queueDirection
								if (not table.find(regFloor.exteriorCallDirections,directionNumber)) then
									table.insert(regFloor.exteriorCallDirections,directionNumber)
								end
								task.spawn(updateCore)
								task.spawn(runDoorOpen,module.MODULE_STORAGE.statValues.rawFloor,'ALL')
								task.spawn(doLanterns, module.MODULE_STORAGE.statValues.rawFloor,configFile.Color_Database.Lanterns.Active_On_Exterior_Call,configFile.Color_Database.Lanterns.Active_After_Door_Open,direction)
								task.spawn(runChime, module.MODULE_STORAGE.statValues.rawFloor,configFile.Sound_Database.Chime_Events.Exterior_Call_Only,configFile.Sound_Database.Chime_Events.After_Open,direction)

								task.spawn(doLanterns, module.MODULE_STORAGE.statValues.rawFloor,configFile.Color_Database.Lanterns.Active_On_Door_Open,configFile.Color_Database.Lanterns.Active_After_Door_Open,direction)
								task.spawn(runChime, module.MODULE_STORAGE.statValues.rawFloor,configFile.Sound_Database.Chime_Events.On_Open,configFile.Sound_Database.Chime_Events.After_Open,direction)
							elseif (not table.find(regFloor.exteriorCallDirections,directionNumber)) then
								addCall(floor,directionNumber,nil,{ hall = true })
								table.insert(regFloor.exteriorCallDirections,directionNumber)
							end
						end
					else
						local resetStatement = ((isOnFloor and (direction == module.MODULE_STORAGE.statValues.queueDirection or module.MODULE_STORAGE.statValues.queueDirection == 'N'))
							or independentService
							or module.MODULE_STORAGE.statValues.inspection
							or module.MODULE_STORAGE.statValues.fireService
							or lockedHallFloors[tostring(floor)])
							and not findCallInQueue(floor, direction)


						if (btn:GetAttribute('AlarmRinging')) then
							btn:SetAttribute('AlarmRinging', nil)
							module.MODULE_STORAGE.sounds.Alarm:Stop()
							module.MODULE_STORAGE.sounds.Alarm_Release:Play()
						end
						if (resetStatement) then
							task.delay(configFile.Color_Database.Floor.Active_Duration, function()
								updateButton(btn, configFile.Color_Database.Floor[btn.Name], 'Neautral_State')
							end)
						end
					end
				end
			elseif (btn:FindFirstAncestor('Inspection_Controls')) then -- Added by ImFirstPlace
				if (inspectionLocked) then return end
				if (btn.Name == 'Inspection_Switch') then
					if (event == 'onButtonPressed') then
						module.MODULE_STORAGE.statValues.inspection = not module.MODULE_STORAGE.statValues.inspection
						api:Fire('setInspection', module.MODULE_STORAGE.statValues.inspection) -- Because it doesn't repeat code
						addPlaySound(inspectionSwitchClick, btn.Button)
						tweenService:Create(btn.Button.NewWeld, TweenInfo.new(.17, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {C0 = module.MODULE_STORAGE.statValues.inspection and btn:GetAttribute('onCF') or btn:GetAttribute('offCF')}):Play()
					end
				elseif btn.Name == 'Common' or btn.Name == 'Enable' then
					if (event == 'onButtonPressed') then
						module.MODULE_STORAGE.miscValues.inspectionCommonEnabled = not module.MODULE_STORAGE.miscValues.inspectionCommonEnabled
						addPlaySound(inspectionButtonClick[btn.Name], btn.Button)
						if module.MODULE_STORAGE.miscValues.inspectionCommonEnabled then
							tweenService:Create(btn.Button.NewWeld, TweenInfo.new(.08, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {C0 = btn:GetAttribute('downCF')}):Play()
						end
					elseif (not module.MODULE_STORAGE.miscValues.inspectionCommonEnabled) then
						tweenService:Create(btn.Button.NewWeld, TweenInfo.new(.08, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {C0 = btn:GetAttribute('upCF')}):Play()
					end
				elseif (btn.Name == 'Up' or btn.Name == 'Down') then
					if (event == 'onButtonPressed') then
						addPlaySound(inspectionButtonClick[btn.Name], btn.Button)
						tweenService:Create(btn.Button.NewWeld, TweenInfo.new(.08, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {C0 = btn:GetAttribute('downCF')}):Play()
						if (module.MODULE_STORAGE.miscValues.inspectionCommonEnabled) then
							api:Fire('inspectionMove', {btn.Name, configFile.Movement.Inspection_Config.Max_Speed})
						end
					else
						tweenService:Create(btn.Button.NewWeld, TweenInfo.new(.08, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {C0 = btn:GetAttribute('upCF')}):Play()
						if (module.MODULE_STORAGE.miscValues.inspectionCommonEnabled) then
							api:Fire('inspectionStop', btn.Name)
						end
					end
				elseif (btn.Name == 'Alarm') then
					if (event == 'onButtonPressed') then
						tweenService:Create(btn.Button.NewWeld, TweenInfo.new(.08, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {C0 = btn:GetAttribute('downCF')}):Play()
						if ((not configFile.Sound_Database.Others.Alarm.Pause_On_Release) or (not module.MODULE_STORAGE.sounds.Alarm.IsPlaying)) then
							module.MODULE_STORAGE.sounds.Alarm:Play()
						else
							module.MODULE_STORAGE.sounds.Alarm.Pitch = configFile.Sound_Database.Others.Alarm.Pitch
						end
						isAlarmPlaying = true
					else
						tweenService:Create(btn.Button.NewWeld, TweenInfo.new(.08, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {C0 = btn:GetAttribute('upCF')}):Play()
						if (not configFile.Sound_Database.Others.Alarm.Pause_On_Release) then
							module.MODULE_STORAGE.sounds.Alarm:Stop()
						else
							module.MODULE_STORAGE.sounds.Alarm.Pitch = 0
						end
						if (isAlarmPlaying) then
							module.MODULE_STORAGE.sounds.Alarm_Release:Play()
						end
						isAlarmPlaying = false
					end
				elseif (btn.Name == 'Stop') then
					if (event == 'onButtonPressed') then
						addPlaySound(inspectionButtonClick[btn.Name], btn.Button)
						api:Fire('Stop', not stopElevator)
						tweenService:Create(btn.Button.NewWeld, TweenInfo.new(.08, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {C0 = stopElevator and btn:GetAttribute('downCF') or btn:GetAttribute('upCF')}):Play()
					end
				end
			else
				local function lerp(weld, duration, startPoint, point)
					local newCode = math.random(0,100000000)
					weld:SetAttribute('LerpCode', newCode)
					local startTime = os.clock()

					local prevLerpCode = weld:GetAttribute('LerpCode')
					while ((os.clock()-startTime)/duration <= 1) do
						local alpha = math.clamp(((os.clock()-startTime)/duration), 0, 1)
						prevLerpCode = weld:GetAttribute('LerpCode')
						if (prevLerpCode ~= newCode) then return end
						weld.C0 = weld:GetAttribute('startPoint'):Lerp(weld:GetAttribute('endPoint'), point+(startPoint-point)*alpha)
						HEARTBEAT:Wait()
					end

				end

				if (collectionService:HasTag(btn.Button, 'isInsButtonMain')) then
					addPlaySound(btn.Button.Click, btn.Button)
					lerp(btn.Button.NewWeld, .05, 1, 0)
				end
			end
		end

		local setInspectionNudgeConnections = {}
		api.Event:Connect(function(event: string, params: any, optionalFireRecallBool: boolean?)

			if (event == 'inspectionMove' or event == 'Inspection_Service_Move') then
				if (stopElevator or moveBrake) then return end
				if (not inspectionMoveDebounce) then
					local direction,maxSpeed = unpack(params)
					local dir = direction == 'Up' and 1 or direction == 'Down' and -1
					isDown = true
					if ((not module.MODULE_STORAGE.statValues.inspection) or (not isDown) or (not checkDoorStates('Closed'))) then return end
					if (isMoving) then while (isMoving and isDown and (not overshot)) do task.wait() end end
					if (initialDirection == -dir) then
						overshot = false
					end
					if ((not isDown) or overshot) then return end
					inspectionMoveDebounce = true
					isMoving = true
					stopping = false
					module.MODULE_STORAGE.statValues.moveValue = dir
					updateCore()
					doMotorSound()
					conditionalStepWait(configFile.Movement.Inspection_Start_Delay[dir == 1 and 'Up' or dir == -1 and 'Down'], function()
						return {not isDown}
					end)
					doPlayerWeld()
					while (isDown and isMoving and (not stopping) and (not overshot)) do
						local delta = updateCore()
						if (math.abs(module.MODULE_STORAGE.statValues.currentSpeed) < configFile.Movement.Inspection_Config.Max_Speed) then
							module.MODULE_STORAGE.statValues.currentSpeed += (configFile.Movement.Inspection_Config.Accceleration_Rate)*math.deg(delta)
						end
					end
				end

			end
			if (event == 'inspectionStop' or event == 'Inspection_Service_Stop') then
				stopInspection(params)
			end
			if (event == 'inspectionLock' or event == 'Inspection_Service_Lock') then
				inspectionLocked = params
			end
			if (event == 'setInspection' or event == 'Inspection_Service') then
				module.MODULE_STORAGE.statValues.inspection = params
				outputElevMessage(`elevators inspection has been {module.MODULE_STORAGE.statValues.inspection and 'enabled' or 'disabled'} by Server`, 'warning')
				outOfService = params or (not isDropKeyOnElevator())
				if (module.MODULE_STORAGE.statValues.inspection) then
					releveling = false
					removeAllCalls()
					setDirection(module.MODULE_STORAGE.statValues.rawFloor, 'N')
					if (module.MODULE_STORAGE.statValues.moveValue ~= 0) then
						module.MODULE_STORAGE.sounds.Safety_Brake_Sound.PlaybackSpeed = module.MODULE_STORAGE.sounds.Safety_Brake_Sound:GetAttribute('originalPitch')
						task.spawn(safetyBrake)
					end
					if (not checkDoorStates('Closed')) then module.MODULE_STORAGE.sounds.Nudge_Buzzer:Play() end

					for i,v in pairs(pluginModules_INTERNAL.Storage.CONTENT:getContentInBranch('masterDoorData')) do
						local connection: RBXScriptConnection
						if (v.state ~= 'Closed' and v.state ~= 'Open') then
							v.nudging = true
							if ((not connection) or (not connection.Connected)) then
								connection = v.Opened:Connect(function()
									connection:Disconnect()
									task.spawn(function()
										local hasPassed = conditionalStepWait(1, function() return {v.state ~= 'Open'} end)
										if (not hasPassed) then return end
										task.spawn(runDoorClose, module.MODULE_STORAGE.statValues.rawFloor, v.side, true)
									end)
								end)
							end
						elseif (v.state == 'Open') then
							v.nudging = true
							if (connection) then connection:Disconnect() end
							task.spawn(function()
								local hasPassed = conditionalStepWait(1, function() return {v.state ~= 'Open'} end)
								if (not hasPassed) then return end
								task.spawn(runDoorClose, module.MODULE_STORAGE.statValues.rawFloor, v.side, true)
							end)
						end
					end
				else
					for i,v in pairs(setInspectionNudgeConnections) do
						v:Disconnect()
					end
					setInspectionNudgeConnections = {}
					stopInspection(module.MODULE_STORAGE.statValues.moveValue == 1 and 'U' or module.MODULE_STORAGE.statValues.moveValue == -1 and 'D' or 'N')
					overshot = false
					moveBrake = false
					task.spawn(safeCheckRelevel)
				end
				updateCore()
			elseif (event == 'setInspectionEnabled' or event == 'Inspection_Service_Common') then
				module.MODULE_STORAGE.miscValues.inspectionCommonEnabled = params
			end
			if (event == 'Lock_Floors') then
				if (typeof(params) ~= 'table') then return debugWarn(`{event} API :: Paramrters is not of type table`) end
				outputElevMessage(`Elevator floors locked with calls {table.concat(params, ', ')}`, 'debug')
				for i,v in pairs(params) do
					lockedFloors[tostring(v)] = true
				end
			elseif (event == 'Unlock_Floors') then
				if (typeof(params) ~= 'table') then return debugWarn(`{event} API :: Paramrters is not of type table`) end
				outputElevMessage(`Elevator floors unlocked with calls {table.concat(params, ', ')}`, 'debug')
				for i,v in pairs(params) do
					lockedFloors[tostring(v)] = false
				end
			end
			if (event == 'Lock_Hall_Floors') then
				if (typeof(params) ~= 'table') then return debugWarn(`{event} API :: Paramrters is not of type table`) end
				outputElevMessage(`Elevator floors hall locked with calls {table.concat(params, ', ')}`, 'debug')
				for i,v in pairs(params) do
					lockedHallFloors[tostring(v)] = true
				end
			elseif (event == 'Unlock_Hall_Floors') then
				if (typeof(params) ~= 'table') then return debugWarn(`{event} API :: Paramrters is not of type table`) end
				outputElevMessage(`Elevator floors hall unlocked with calls {table.concat(params, ', ')}`, 'debug')
				for i,v in pairs(params) do
					lockedHallFloors[tostring(v)] = false
				end
			end
			if (event == 'forceChimeOnCallEnter') then

				local call = params[1]
				for i,v in pairs(pluginModules_INTERNAL.Storage.CONTENT:getContentInBranch('masterDoorData')) do
					if (call == module.MODULE_STORAGE.statValues.rawFloor and v.state == 'Open') then
						local function runCallEnterHandler(data, fn)

							for index,v in pairs(data) do

								if (v.Enable) then
									task.delay(v.Delay, function()

										local direction = module.MODULE_STORAGE.statValues.queueDirection == 'U' and 'Up' or module.MODULE_STORAGE.statValues.queueDirection == 'D' and 'Down' or nil
										if (not module.MODULE_STORAGE.statValues.direction) then return end
										local name = string.format('%s_Chime%s', module.MODULE_STORAGE.statValues.direction, string.lower(v.Type) == 'arrival' and '_Arrival' or '')
										local chime = platform:FindFirstChild(name)
										if (not chime) then return end
										fn(module.MODULE_STORAGE.statValues.rawFloor, {[index]={['Type']=v.Type,['Enable']=v.Enable}}, {[index]={['Type']=v.Type,['Enable']=false}})

									end)
								end

							end

						end

						for i,v in pairs(pluginModules_INTERNAL.Storage.CONTENT:getContentInBranch('masterDoorData')) do
							if (call ~= module.MODULE_STORAGE.statValues.rawFloor and v.state == 'Open') then
								runCallEnterHandler(configFile.Sound_Database.Chime_Events.New_Call_Input, runChime)
								runCallEnterHandler(configFile.Color_Database.Lanterns.Active_On_Call_Enter, doLanterns)
							end
							break
						end
						break
					end
				end

			end
			if (event == 'Phase_2' or event == 'Fire_Service_Phase_2') then
				outputElevMessage(`{module.MODULE_STORAGE.statValues.phase1}, {module.MODULE_STORAGE.statValues.phase2}`, 'debug')
				module.MODULE_STORAGE.statValues.phase2 = params
				updateCore()
				if (module.MODULE_STORAGE.statValues.fireService and not module.MODULE_STORAGE.statValues.phase2) then
					local recallFloor = fireRecallFloor
					fireRecall(false, module.MODULE_STORAGE.statValues.rawFloor)
					fireRecall(true, recallFloor)
				end
			end
			if (event == 'dropKeyToggle') then
				doDropKey(params)
			end
			if (event == 'Door_Open') then
				runDoorOpen(module.MODULE_STORAGE.statValues.rawFloor, typeof(params) == 'table' and params or 'ALL')
			end
			if (event == 'Door_Close') then
				runDoorClose(module.MODULE_STORAGE.statValues.rawFloor, typeof(params) == 'table' and params or 'ALL')
			end
			if (event == 'Door_Nudge') then
				runDoorClose(module.MODULE_STORAGE.statValues.rawFloor, typeof(params) == 'table' and params or 'ALL', true)
			end
			if (event == 'Request_Call_F' or event == 'Add_Call') then
				--In this case, params[1] is the call
				local call = tonumber(params) or typeof(params) == 'table' and params.call
				local direction = typeof(params) == 'table' and params.direction and (params.direction == 1 and 'U' or params.direction == -1 and 'D' or if (typeof(params.direction) == 'string') then params.direction else nil) or nil
				local directionNumber = direction == 'U' and 1 or direction == 'D' and -1 or nil
				if (findCallInQueue(call, directionNumber)) then return end
				local regFloor = findRegisteredFloor(call)
				if (not regFloor) then return end
				local isOnFloor = (call == module.MODULE_STORAGE.statValues.rawFloor and (module.MODULE_STORAGE.statValues.moveValue == 0 or module.MODULE_STORAGE.statValues.leveling))
				if (not isOnFloor) then
					addCall(call,directionNumber)
					table.insert(regFloor.exteriorCallDirections,directionNumber)
				else
					if (direction and (direction == module.MODULE_STORAGE.statValues.queueDirection or module.MODULE_STORAGE.statValues.queueDirection == 'N')) then
						module.MODULE_STORAGE.statValues.queueDirection = direction
						module.MODULE_STORAGE.statValues.arrowDirection = module.MODULE_STORAGE.statValues.queueDirection
						api:Fire('onCallRespond', {floor=call,direction=module.MODULE_STORAGE.statValues.queueDirection})
						if (not table.find(regFloor.exteriorCallDirections,directionNumber)) then
							table.insert(regFloor.exteriorCallDirections,directionNumber)
							task.spawn(updateCore)
						end
						task.spawn(runDoorOpen,module.MODULE_STORAGE.statValues.rawFloor,'ALL')
						doLanterns(module.MODULE_STORAGE.statValues.rawFloor,configFile.Color_Database.Lanterns.Active_On_Exterior_Call,configFile.Color_Database.Lanterns.Active_After_Door_Open,direction)
						runChime(module.MODULE_STORAGE.statValues.rawFloor,configFile.Sound_Database.Chime_Events.Exterior_Call_Only,configFile.Sound_Database.Chime_Events.After_Open,direction)
						task.spawn(doLanterns, module.MODULE_STORAGE.statValues.rawFloor,configFile.Color_Database.Lanterns.Active_On_Door_Open,configFile.Color_Database.Lanterns.Active_After_Door_Open,direction)
						task.spawn(runChime, module.MODULE_STORAGE.statValues.rawFloor,configFile.Sound_Database.Chime_Events.On_Open,configFile.Sound_Database.Chime_Events.After_Open,direction)
					elseif (not direction) then
						local resetStatement = (not findFloor(call))
							or (not isDropKeyOnElevator())
							or ((module.MODULE_STORAGE.statValues.rawFloor == call or module.MODULE_STORAGE.statValues.arriveFloor == call) and (module.MODULE_STORAGE.statValues.moveValue == 0 or module.MODULE_STORAGE.statValues.leveling))
							or (module.MODULE_STORAGE.statValues.inspection or stopElevator or (module.MODULE_STORAGE.statValues.phase1 and not checkPhase2()))
							or (lockedFloors[tostring(call)] and (not findCallInQueue(call)))
							or (configFile.Locking.Lock_Opposite_Travel_Direction_Floors and ((module.MODULE_STORAGE.statValues.queueDirection == 'U' and (call < module.MODULE_STORAGE.statValues.rawFloor) or (module.MODULE_STORAGE.statValues.queueDirection == 'D' and (call > module.MODULE_STORAGE.statValues.rawFloor)) or call == module.MODULE_STORAGE.statValues.rawFloor and checkDoorStates('Closed'))))
						api:Fire('onCallRespond', {floor=call,direction=module.MODULE_STORAGE.statValues.queueDirection})
						task.spawn(function()
							if (not resetStatement) then
								local inQueue = findCallInQueue(call)
								if (not inQueue) then
									task.delay(configFile.Sound_Database.Others.Call_Recognition_Beep.Delay, function()
										if (call == module.MODULE_STORAGE.statValues.rawFloor) then return end
										addPlaySound(module.MODULE_STORAGE.sounds.Call_Recognition_Beep, platform)
									end)
								end
								addCall(call)
							elseif (call == module.MODULE_STORAGE.statValues.rawFloor and module.MODULE_STORAGE.statValues.moveValue == 0) then
								for i,v in pairs(pluginModules_INTERNAL.Storage.CONTENT:getContentInBranch('masterDoorData')) do
									if (v.state == 'Closing' or v.state == 'Closed') then
										runDoorOpen(module.MODULE_STORAGE.statValues.rawFloor, v.side)
									end
								end
							end
						end)
					elseif (not table.find(regFloor.exteriorCallDirections,directionNumber)) then
						addCall(call,directionNumber)
						table.insert(regFloor.exteriorCallDirections,directionNumber)
					end
				end

				local function handleDestinationPanelNumber(d)

					local floorChangeConnection,destroyedConnection
					local doorStateConnections = {}
					local isClosed = checkDoorStates('Closed')
					task.spawn(function()
						while (not isClosed) do
							if (isClosed or (not d)) then return end
							d.TextTransparency = 0
							task.wait(.9)
							if (isClosed or (not d)) then return end
							d.TextTransparency = 1
							task.wait(.9)
						end
					end)
					floorChangeConnection = statisticsFolder.Floor:GetPropertyChangedSignal('Value'):Connect(function()
						if (statisticsFolder.Floor.Value == call) then
							floorChangeConnection:Disconnect()
							d:Destroy()
							d = nil --Unassign the value so the loop stops properly
						end
					end)
					for i,v in pairs(doorStateValues) do
						local connection
						connection = v.Value:GetPropertyChangedSignal('Value'):Connect(function()
							if (v.Value.Value == 'Closed') then connection:Disconnect() end
							isClosed = checkDoorStates('Closed')
							tweenService:Create(d, TweenInfo.new(.45, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {TextTransparency=0}):Play()
						end)
						doorStateConnections[v.side] = connection
					end
					destroyedConnection = d:GetPropertyChangedSignal('Parent'):Connect(function()
						if (not d.Parent) then
							destroyedConnection:Disconnect()
							if (floorChangeConnection) then floorChangeConnection:Disconnect() end
							if (doorStateConnections) then
								for i,v in pairs(doorStateConnections) do
									v:Disconnect()
								end
							end
							d = nil
						end
					end)

				end

				if (call == module.MODULE_STORAGE.statValues.rawFloor) then return end
				if (not direction) then
					updateButton(string.format('Floor_%s', tostring(call)), configFile.Color_Database.Car.Floor_Button, 'Lit_State', car)
					updateButton(string.format('Floor%s', tostring(call)), configFile.Color_Database.Car.Floor_Button, 'Lit_State', car)
				end

				for i,v in pairs(car:GetDescendants()) do
					if (v.Name == 'Destination_Panels') then
						for _,h in pairs(v:GetDescendants()) do
							if (h.Name == 'Display') then
								local d = script.Assets.destinationPanelNumber:Clone()
								d.Parent = h.SurfaceGui.Frame
								local cfl = configFile['Custom_Floor_Label'][tostring(call)] or call
								d.Text = cfl
								d.Name = tostring(call)
								handleDestinationPanelNumber(d)
							end
						end
					end
				end
			end
			if (event == 'Fire_Recall' or event == 'Fire_Service_Phase_1') then
				if (typeof(params) ~= 'table') then
					params = {
						floor=optionalFireRecallBool,
						enable=params
					}
				end
				fireRecall(params.enable, params.floor)
			end
			if (event == 'Add_Directional_Call') then
				if (not floors:FindFirstChild(string.format('Floor_%s', tostring(params[1])))) then return end
				if (tonumber(params[1]) == module.MODULE_STORAGE.statValues.rawFloor and checkDoorStates('Closing')) then
					return runDoorOpen(module.MODULE_STORAGE.statValues.rawFloor, 'ALL', false)
				end
				addCall(params[1],params[2])
				local buttonDirection = params[2] == 'U' and 'Up' or params[2] == 'D' and 'Down'
				if (params[1] ~= module.MODULE_STORAGE.statValues.rawFloor) then 
					updateButton(buttonDirection, configFile.Color_Database.Floor[buttonDirection], 'Lit_State', floors:FindFirstChild(string.format('Floor_%s', tostring(params[1]))))
				end
			end
			if (event == 'Stop') then
				if (params) then
					stopElevator = true
					module.MODULE_STORAGE.sounds.Safety_Brake_Sound.PlaybackSpeed = module.MODULE_STORAGE.sounds.Safety_Brake_Sound:GetAttribute('originalPitch')
					task.spawn(safetyBrake)
					if (module.MODULE_STORAGE.statValues.nudging) then
						module.MODULE_STORAGE.statValues.nudging = false
						module.MODULE_STORAGE.sounds.Nudge_Buzzer:Stop()
					end
					for _, doorData in pairs(pluginModules_INTERNAL.Storage.CONTENT:getContentInBranch('masterDoorData')) do
						if (doorData.state == 'Opening' or doorData.state == 'Closing') then
							doorData.state = 'Stopped'
						end
					end
				else
					local prevStopCheck = stopElevator
					stopElevator = false
					if (prevStopCheck) then
						moveBrake = false
						task.spawn(safeCheckRelevel)
					end
				end
				task.spawn(updateCore)
			elseif (event == 'Set_Direction') then
				setDirection(params[1], params[2])
			elseif (event == 'invokeIndependentService' or event == 'invokeIS' or event == 'Independent_Service') then
				setIndependentService(params)
			elseif (event == 'addHallCall' or event == 'Add_Hall_Call') then
				if (typeof(params) ~= 'table' or (not params.floor) or (not params.direction)) then return end
				if (params.floor == module.MODULE_STORAGE.statValues.rawFloor) then
					for i,v in pairs(pluginModules_INTERNAL.Storage.CONTENT:getContentInBranch('masterDoorData')) do
						if (v.state == 'Closing' and (not v.nudging)) then
							runDoorOpen(module.MODULE_STORAGE.statValues.rawFloor, v.side, false)
						end
					end
				end
				if (findCallInQueue(params.floor)) then return end
				debugWarn(`Added hall call for {params.floor} with direction {params.direction}`)
				local call = params.floor
				local direction = params.direction
				local directionNumber = params.direction == 'U' and 1 or params.direction == 'D' and -1 or typeof(params.direction) == 'number' and params.direction or 0
				local regFloor = findRegisteredFloor(call)
				local isOnFloor = (call == module.MODULE_STORAGE.statValues.rawFloor and (module.MODULE_STORAGE.statValues.moveValue == 0 or module.MODULE_STORAGE.statValues.leveling))
				
				if (not isOnFloor) then
					addCall(call,directionNumber,nil,{ hall = true })
					table.insert(regFloor.exteriorCallDirections,directionNumber)
				else
					if (direction == module.MODULE_STORAGE.statValues.queueDirection or module.MODULE_STORAGE.statValues.queueDirection == 'N') then
						module.MODULE_STORAGE.statValues.queueDirection = direction
						module.MODULE_STORAGE.statValues.arrowDirection = module.MODULE_STORAGE.statValues.queueDirection
						if (not table.find(regFloor.exteriorCallDirections,directionNumber)) then
							table.insert(regFloor.exteriorCallDirections,directionNumber)
						end
						task.spawn(updateCore)
						task.spawn(runDoorOpen,module.MODULE_STORAGE.statValues.rawFloor,'ALL')
						task.spawn(doLanterns, module.MODULE_STORAGE.statValues.rawFloor,configFile.Color_Database.Lanterns.Active_On_Exterior_Call,configFile.Color_Database.Lanterns.Active_After_Door_Open,direction)
						task.spawn(runChime, module.MODULE_STORAGE.statValues.rawFloor,configFile.Sound_Database.Chime_Events.Exterior_Call_Only,configFile.Sound_Database.Chime_Events.After_Open,direction)

						task.spawn(doLanterns, module.MODULE_STORAGE.statValues.rawFloor,configFile.Color_Database.Lanterns.Active_On_Door_Open,configFile.Color_Database.Lanterns.Active_After_Door_Open,direction)
						task.spawn(runChime, module.MODULE_STORAGE.statValues.rawFloor,configFile.Sound_Database.Chime_Events.On_Open,configFile.Sound_Database.Chime_Events.After_Open,direction)
					elseif (not table.find(regFloor.exteriorCallDirections,directionNumber)) then
						addCall(call,directionNumber,nil,{ hall = true })
						table.insert(regFloor.exteriorCallDirections,directionNumber)
					end
				end
			elseif (event == 'Run_Chime') then
				if (typeof(params) ~= 'table' or typeof(params.types) ~= 'table') then return end
				for i,v in pairs(params.types) do
					if (v == 'interior' or v == 'exterior') then
						local data = {[v]={Enable=true,Call_Only=false,Delay=0}}
						local afterOpenData = typeof(params.afterOpen) == 'table' and {[params.afterOpen[i]]={Enable=true,Call_Only=false,Delay=0}} or {}
						runChime(tonumber(params.floor), data, typeof(params.afterOpen) ~= 'table' and {} or afterOpenData, params.direction)
					end
				end
			elseif (event == 'Activate_Lanterns') then
				if (typeof(params) ~= 'table' or typeof(params.types) ~= 'table') then return end
				for i,v in pairs(params.types) do
					if (v == 'interior' or v == 'exterior') then
						local data = {[v]={Enable=true,Call_Only=false,Delay=0}}
						local afterOpenData = typeof(params.afterOpen) == 'table' and {[params.afterOpen[i]]={Enable=true,Call_Only=false,Delay=0}} or {}
						doLanterns(tonumber(params.floor), data, typeof(params.afterOpen) ~= 'table' and {} or afterOpenData, params.direction)
					end
				end
			elseif (event == 'Fire_Button_Event') then
				handleRemoteButtonInput(params.protocol, { ['button'] = params.button })
			end
			handleRemoteButtonInput(event, params)
		end)

		remote.OnServerEvent:Connect(function(user, event, params)
			if (event == 'dropKeyToggle') then
				local isHoldingKey = user.Character and user.Character:FindFirstChild('Drop Key')
				if (not isHoldingKey) then return end
				doDropKey(params)
			elseif (event == 'addDropKeyGuiToPlayer') then
				local containsDropKey
				for i,v in pairs(user.Character:GetChildren()) do
					if (v.Name == 'Drop Key' or v:FindFirstChild('Cortex_Drop_Key')) then
						containsDropKey = v
						break
					end
				end
				local isHoldingKey = user.Character and containsDropKey
				if (not isHoldingKey) then return end
				if (not user.PlayerGui:FindFirstChild('DOOR_KEY_UI')) then

					local doorSet = params
					local thisFloorName = doorSet:IsDescendantOf(floors) and string.split(doorSet.Parent.Name, 'Floor_')[2]
					local landingLevel = doorSet.Parent.Level
					local sideIndex = doorSet.Name:split('Doors')[1]:split('_')[1]
					local fullSideName = (sideIndex == '' and 'Front' or sideIndex)
					if (collectionService:HasTag(doorSet, 'IsInUse') or table.find(dropKeyHandlers,user) or (not ((landingLevel:IsDescendantOf(car) and getDoorState(sideIndex).state == 'Closed') or ((not landingLevel:IsDescendantOf(car)) and ((getDoorState(sideIndex).state == 'Closed' and tonumber(landingLevel.Parent.Name:sub(7)) == module.MODULE_STORAGE.statValues.rawFloor) or tonumber(landingLevel.Parent.Name:sub(7)) ~= module.MODULE_STORAGE.statValues.rawFloor))))) then return end
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
						weldTogether(doorBounds, landingLevel, true, false)
						doorBounds.Anchored = false
						doorBounds.Parent = doorSet
					end
					local gui = script.Assets.DOOR_KEY_UI:Clone()
					gui.DOOR_SET.Value = doorSet
					gui.Adornee = doorBounds
					gui.Enabled = true
					gui.Parent = user.PlayerGui:WaitForChild('DOOR_KEY_UIS')
					collectionService:AddTag(gui,'ACTIVE')
					local function getOrientation(cf)
						return cf:ToOrientation()
					end
					local welds = {}
					local data = pluginModules_INTERNAL.Storage.CONTENT:get('masterDoorData', sideIndex)
					for i,v in next,data and (doorSet:IsDescendantOf(car) and data.engineWelds.car[sideIndex] or data.engineWelds.floors[thisFloorName][sideIndex]) or {} do
						table.insert(welds, v)
					end
					local function checkIfDoorIsClosed()
						for i,v in pairs(welds) do
							if (v.instance.C0 ~= v.closedPosition) then return false end
						end
						return true
					end
					addPlaySound(addSound(landingLevel, 'Interlock_Click', {
						Sound_Id = 9116323848,
						Volume = 1,
						Pitch = 1.35
					}, false, false, 40, 3), landingLevel)
					for i,v in pairs(pluginModules_INTERNAL.Storage.CONTENT:getContentInBranch('masterDoorData')) do
						v.nudging = false
					end
					module.MODULE_STORAGE.statValues.nudging = false
					task.spawn(updateCore)
					local val = gui:WaitForChild('RATIO')
					local hasStopped = false
					local lastChecked = checkIfDoorIsClosed()
					api:Fire('onElevDoorKey',{doorSet=doorSet,status='insert'})

					local update: RBXScriptConnection
					update = HEARTBEAT:Connect(function(dtTime)
						local value = val.Value
						for i,weld in pairs(welds) do
							weld.instance.C0 = weld.closedPosition:Lerp(weld.openPosition,value)
						end
						local checked = checkIfDoorIsClosed()
						if (lastChecked ~= checked) then
							lastChecked = checked
							doorSet.Drop_Key_Open.Value = not checked
							getDoorData(sideIndex).IsDropKey = not checked
							if (not checked) then
								if (not hasStopped) then
									hasStopped = true
									outOfService = true
									moveBrake = true
									module.MODULE_STORAGE.sounds.Safety_Brake_Sound.PlaybackSpeed = module.MODULE_STORAGE.sounds.Safety_Brake_Sound:GetAttribute('originalPitch')
									task.spawn(safetyBrake)
								end
							else
								hasStopped = false
								outOfService = not isDropKeyOnElevator()
								moveBrake = outOfService
								if (not outOfService) then
									task.spawn(function()
										local isCompleted = conditionalStepWait(1, function() return {moveBrake} end)
										if (not isCompleted) then return end
										task.spawn(safeCheckRelevel)
									end)
								end
								task.spawn(updateCore)
							end
						end
					end)
					if (not dropKeyUpdaters[doorSet]) then dropKeyUpdaters[doorSet] = {} end
					table.insert(dropKeyUpdaters[doorSet],update)

				end
			elseif (event == 'exit') then
				dismountDropKeyClient(user,params)
				for i,v in pairs(user.PlayerGui:WaitForChild('DOOR_KEY_UIS'):GetChildren()) do
					if (collectionService:HasTag(v,'ACTIVE')) then
						v:Destroy()
					end
				end
			end
			handleRemoteButtonInput(event, params)
		end)

		game.Players.PlayerRemoving:Connect(function(plr: Player)
			if (not table.find(dropKeyHandlers,plr)) then return end
			for i,v in pairs(collectionService:GetTagged('IsInUse')) do
				if (v:IsDescendantOf(elevator)) then
					dismountDropKeyClient(plr,v)
				end
			end
			if (module.MODULE_STORAGE.miscValues.clientRefreshHandlers[plr]) then
				module.MODULE_STORAGE.miscValues.clientRefreshHandlers[plr] = nil
			end
		end)


		api:Fire('Lock_Floors', (configFile.Locking.Locked_Floors) or {})
		api:Fire('Lock_Hall_Floors', (configFile.Locking.Locked_Hall_Floors) or {})

		--Start the elevator & set all of its values--
		updateFloor()
		module.MODULE_STORAGE.statValues.destination = module.MODULE_STORAGE.statValues.rawFloor
		updateCore()
		parkTimer()
	end)
	local ran,res = coroutine.resume(thread)
	if (not ran) then
		warn(`{_VERSION} :: FATAL ERROR | {res}`)
		--return restartElevator()
	end
end

return module