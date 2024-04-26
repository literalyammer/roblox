--[[

CORTEX MULTIBAY - VER. 4
10/03/23

WRITTEN BY aaxtatious (540781721)

]]--

local module = {}
module.callFloorData = {}

return function(source)

	local collectionService = game:GetService('CollectionService')
	local replicatedStorage = game:GetService('ReplicatedStorage')

	local this = source.Parent
	local callButtons = this:FindFirstChild('Call_Buttons')
	if (not callButtons) then return warn(`Cortex Multibay // GroupCalling :: {this:GetFullName()} :: Missing required instance Call_Buttons`) end
	local elevators = this:FindFirstChild('Elevators')
	if (not callButtons) then return warn(`Cortex Multibay // GroupCalling :: {this:GetFullName()} :: Missing required instance Elevators`) end

	local allocator = require(script:WaitForChild('Allocator'))

	local configAvailable = source:FindFirstChild('Settings') ~= nil
	local config = configAvailable and require(source.Settings)

	local function setButton(button: Model, config: any, state: string, includeAllButtonsInFloorGroup: boolean?)
		print(debug.traceback())
		if (typeof(config) ~= 'table') then return end
		local cfg = config[state]
		if (not cfg) then return end
		for _,v in pairs((includeAllButtonsInFloorGroup == true and button.Parent or button):GetDescendants()) do
			if ((includeAllButtonsInFloorGroup and v.Name == button.Name) or (not includeAllButtonsInFloorGroup)) then
				for _,light in pairs(v:GetDescendants()) do
					if ((not light:IsA('BasePart')) or light.Name ~= 'Light') then continue end
					light.Color = cfg.Color
					light.Material = cfg.Material
				end
			end
		end
	end

	for _,v in pairs(callButtons:GetChildren()) do
		local floorName = tonumber(string.split(v.Name, 'Floor_')[2]) or tonumber(string.split(v.Name, 'Floor')[2]) or tonumber(v.Name)
		if (not floorName) then continue end
		if (not module.callFloorData[tostring(floorName)]) then
			module.callFloorData[tostring(floorName)] = {}
		end
		for _,btnModel in pairs(v:GetDescendants()) do
			if (btnModel.Name ~= 'Up' and btnModel.Name ~= 'Down') then continue end
			local buttonPart: Part
			for _,v in pairs(btnModel:GetChildren()) do
				if ((not v:IsA('BasePart')) or v.Name ~= 'Button') then continue end
				buttonPart = v
				break
			end
			if (not buttonPart) then continue end
			buttonPart:SetAttribute('isACortexElevButton', true)
			buttonPart.CollisionGroup = 'elevatorCollisionGroup'
			if (not module.callFloorData[tostring(floorName)][btnModel.Name]) then
				module.callFloorData[tostring(floorName)][btnModel.Name] = {
					elevator = nil,
					arrivalConnection = nil,
					otherConnections = {}
				}
			end
			if (config) then
				setButton(btnModel, config.Color_Config[btnModel.Name], 'Neutral_State', false)
			else
				local function getElevatorSettings(index)
					local elev = elevators:GetChildren()[index]
					if (((not elev) or (not elev:FindFirstChild('Settings'))) and elevators:GetChildren()[index+1]) then return getElevatorSettings(index+1) end
					return require(elev.Settings)
				end
				local newConfig = getElevatorSettings(1)
				if (not newConfig) then continue end
				setButton(btnModel, newConfig.Color_Database.Floor[btnModel.Name], 'Neautral_State', false)
			end
		end
	end

	local function addSound(append: Instance, name: string, soundId: number, volume: number, pitch: number, looped: boolean?, minDistance: number?, maxDistance: number?, playOnRemove: boolean?)
		if (typeof(append) ~= 'Instance') then return end
		local result = append:FindFirstChild(name)
		if (not result) then
			result = Instance.new('Sound')
			result.Name = name
			result.SoundId = `rbxassetid://{soundId}`
			result.Volume = volume
			result.PlaybackSpeed = pitch
			result.Looped = looped
			result.RollOffMinDistance = minDistance
			result.RollOffMaxDistance = maxDistance
			result.Parent = append
			if (playOnRemove == true) then
				result.PlayOnRemove = true
				result:Destroy()
			end
		end
		return result
	end

	local function handleButtonInput(user: Player? | any?, protocol: string, params: any)
		if (protocol ~= 'onButtonPressed' and protocol ~= 'onButtonReleased') then return end
		local button = params.button
		if (not button) then return end
		local buttonPart = button:FindFirstChild('Button')
		if (not buttonPart) then return end
		local callFloor = tonumber(string.split(button.Parent.Name, 'Floor_')[2]) or tonumber(string.split(button.Parent.Name, 'Floor')[2]) or tonumber(button.Parent.Name)
		if (not callFloor) then return end
		local callFloorData = module.callFloorData[tostring(callFloor)][button.Name]
		if (not callFloorData) then return end
		local callDirection = button.Name == 'Up' and 1 or button.Name == 'Down' and -1 or nil
		if (not callDirection) then return end

		if (protocol == 'onButtonPressed') then
			if (config) then
				setButton(button, config.Color_Config[button.Name], 'Active_State', true)
				addSound(buttonPart, 'Button_Click', config.Sound_Config.Click.Sound_Id, config.Sound_Config.Click.Volume, config.Sound_Config.Click.Pitch, false, config.Sound_Config.Click.Roll_Off.Min, config.Sound_Config.Click.Roll_Off.Max, true)
			end

			local elevator = params.elevator or allocator.findElevator(elevators:GetChildren(), callFloor, callDirection)
			if ((not config) and (elevator or callFloorData.elevator)) then
				-- // No config located in the script? Use the elevator's config // --
				local elevator = callFloorData.elevator or elevator
				local newConfig = require(elevator.Settings).Color_Database.Floor[button.Name]
				local soundConfig = require(elevator.Settings).Sound_Database.Others.Call_Button_Beep or require(elevator.Settings).Sound_Database.Others.Button_Beep
				addSound(buttonPart, 'Button_Click', soundConfig.Sound_Id, soundConfig.Volume, soundConfig.Pitch, false, 2, 50, true)
				setButton(button, newConfig, 'Lit_State', true)
			end

			if ((not elevator) or callFloorData.elevator) then return end
			if (not config) then
				-- // No config located in the script? Use the elevator's config // --
				local newConfig = require(elevator.Settings).Color_Database.Floor[button.Name]
				local soundConfig = require(elevator.Settings).Sound_Database.Others.Call_Button_Beep or require(elevator.Settings).Sound_Database.Others.Button_Beep
				addSound(buttonPart, 'Button_Click', soundConfig.Sound_Id, soundConfig.Volume, soundConfig.Pitch, false, 2, 50, true)
				setButton(button, newConfig, 'Lit_State', true)
			end
			callFloorData.elevator = elevator
			if (callFloorData.arrivalConnection) then return end
			local isIdle = (elevator.Legacy.Move_Value.Value == 0 or elevator.Legacy.Leveling.Value) and elevator.Legacy.Raw_Floor.Value == callFloor and (elevator.Legacy.Queue_Direction.Value == string.sub(button.Name, 1, 1) or elevator.Legacy.Queue_Direction.Value == 'N')
			if (not isIdle) then
				callFloorData.arrivalConnection = elevator.Cortex_API.Event:Connect(function(protocol, params)
					if (protocol ~= 'onCallRespond') then return end
					if (params.floor == callFloor and params.direction == string.sub(button.Name, 1, 1)) then
						for i, v in pairs(callFloorData.otherConnections) do
							callFloorData.otherConnections[i]:Disconnect()
							callFloorData.otherConnections[i] = nil
						end
						callFloorData.arrivalConnection:Disconnect()
						callFloorData.arrivalConnection = nil
						callFloorData.elevator = nil
						if (not config) then
							-- // No config located in the script? Use the elevator's config // --
							local newConfig = require(elevator.Settings).Color_Database.Floor[button.Name]
							setButton(button, newConfig, 'Neautral_State', true)
						else
							setButton(button, config.Color_Config[button.Name], 'Neutral_State', true)
						end
					end
				end)
			end

			for _, v in pairs(elevator.Legacy:GetChildren()) do
				if v.Name == 'Independent_Service' or v.Name == 'Fire_Service' or v.Name == 'Stop' or v.Name == 'Inspection' or v.Name == 'Out_Of_Service' then
					table.insert(callFloorData.otherConnections, v:GetPropertyChangedSignal('Value'):Connect(function()
						if v.Value then
							for i, v in pairs(callFloorData.otherConnections) do
								callFloorData.otherConnections[i]:Disconnect()
								callFloorData.otherConnections[i] = nil
							end
							callFloorData.arrivalConnection:Disconnect()
							callFloorData.arrivalConnection = nil
							callFloorData.elevator = nil
							if (not config) then
								-- // No config located in the script? Use the elevator's config // --
								local newConfig = require(elevator.Settings).Color_Database.Floor[button.Name]
								setButton(button, newConfig, 'Neautral_State', true)
							else
								setButton(button, config.Color_Config[button.Name], 'Neutral_State', true)
							end
						end
					end))
				end
			end

			elevator.Cortex_API:Fire('Add_Call', { ['call'] = callFloor, ['direction'] = callDirection })
		else
			local elevator = callFloorData.elevator
			if (not elevator) then
				local function getElevatorSettings(index)
					local elev = elevators:GetChildren()[index]
					if (((not elev) or (not elev:FindFirstChild('Settings'))) and elevators:GetChildren()[index+1]) then return getElevatorSettings(index+1) end
					return require(elev.Settings)
				end
				if config then
					setButton(button, config.Color_Config[button.Name], 'Neutral_State', true)
				else
					local newConfig = getElevatorSettings(1)
					if (not newConfig) then return end
					setButton(button, newConfig.Color_Database.Floor[button.Name], 'Neautral_State', false)
				end
				return
			end
			-- // Let's do an idle check, only reset the button and its values if this check passes // --
			local isIdle = (elevator.Legacy.Move_Value.Value == 0 or elevator.Legacy.Leveling.Value) and elevator.Legacy.Raw_Floor.Value == callFloor and (elevator.Legacy.Queue_Direction.Value == string.sub(button.Name, 1, 1) or elevator.Legacy.Queue_Direction.Value == 'N')
			if (isIdle) then
				for i, v in pairs(callFloorData.otherConnections) do
					callFloorData.otherConnections[i]:Disconnect()
					callFloorData.otherConnections[i] = nil
				end
				if (callFloorData.arrivalConnection) then
					callFloorData.arrivalConnection:Disconnect()
					callFloorData.arrivalConnection = nil
				end
				callFloorData.elevator = nil
				if (config) then
					setButton(button, config.Color_Config[button.Name], 'Neutral_State', true)
				else
					-- // No config located in the script? Use the elevator's config // --
					local newConfig = require(elevator.Settings).Color_Database.Floor[button.Name]
					setButton(button, newConfig, 'Neautral_State', true)
				end
			end
		end
	end

	local buttonAPI,buttonRemote,allocatorAPI = this:FindFirstChild('Button_API'),this:FindFirstChild('Button_Remote'),this:FindFirstChild('Cortex_Allocator_API')
	if (not buttonAPI) then
		buttonAPI = Instance.new('BindableEvent')
		buttonAPI.Name = 'Button_API'
		buttonAPI.Parent = this
	end
	if (not buttonRemote) then
		buttonRemote = Instance.new('RemoteEvent')
		buttonRemote.Name = 'Button_Remote'
		buttonRemote.Parent = this
	end
	if (not allocatorAPI) then
		allocatorAPI = Instance.new('BindableFunction')
		allocatorAPI.Name = 'Cortex_Allocator_API'
		allocatorAPI.Parent = this
		function allocatorAPI.OnInvoke(params)
			local elevator = allocator.findElevator(params.elevators, params.floor, params.direction)
			handleButtonInput(nil, 'onButtonPressed', {button = params.callButton, elevator = elevator})
			task.delay(.35, function()
				handleButtonInput(nil, 'onButtonReleased', {button = params.callButton})
			end)
			return elevator
		end
	end

	buttonAPI.Event:Connect(function(protocol, params)
		handleButtonInput(nil, protocol, params)
	end)
	buttonRemote.OnServerEvent:Connect(handleButtonInput)

end