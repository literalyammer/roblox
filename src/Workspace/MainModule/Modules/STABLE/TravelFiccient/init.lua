local module = {}
return function(A, _Settings, _Voice_Module)
	local _Pad_Settings = require(A:WaitForChild('Settings'))
	local Model = _Settings.Parent
	local oriSettings = _Settings
	_Settings = require(_Settings)
	local _Display = A:WaitForChild('Screen'):FindFirstChild('Display') or script.Assets.Display:Clone()
	_Display.Parent = A:WaitForChild('Screen')
	local _Services = {
		['_Run_Service'] = game:GetService('RunService'),
		['_Tween_Service'] = game:GetService('TweenService')
	}
	local collectionService = game:GetService('CollectionService')
	local _Transitioning = false
	local _Input_Time = 0
	local _Keypad_Input_Time = 0
	local _Timeout_Locked = false
	local _Pad_Timeout = _Settings['Display']['Pad_Fade_Timeout']
	local _Input = ''
	local _Keypad_Enabled = true
	local _Elevator_Found
	local _Input_Locked = false
	local _Handicap_Locked = false
	local running = false
	local isScannerActivated = false
	local _Handicap = false
	local isFireRecall = false
	local lastFrame
	local thisFloor = tonumber(_Display.Parent.Parent.Parent.Name:sub(7))
	local screenTransitioning = false
	local _Highlighted_Group,_Highlighted_Button,_Group_Inactive,_Floor_Inactive
	local _Btn_Debounce = false
	local _Btn_Debounce_M = false
	local _Is_Handicap_Used = false
	local voiceModule = _Voice_Module;
	_Voice_Module = require(_Voice_Module);


	local voiceConfig = require(voiceModule.STOCK_VoiceModule);

	if (_Settings.Voice_Config and _Settings.Voice_Config.Enabled) then
		voiceConfig = _Settings.Voice_Config
	end

	local _Voice = Instance.new('Sound', _Display.Parent)
	_Voice.SoundId = 'rbxassetid://'..tostring(voiceConfig.Voice_ID)
	_Voice.MaxDistance = 30
	_Voice.EmitterSize = 3
	_Voice.Volume = voiceConfig.Volume
	_Voice.Name = 'Voice'
	local _Equalizer = Instance.new('EqualizerSoundEffect', _Voice)
	_Equalizer.HighGain = 0
	_Equalizer.LowGain = -80
	_Equalizer.MidGain = 0
	local _Voice_Labels = _Settings['Voice_Config']['Voice_Labels']

	local scannerReady = false
	local scannerActive = false
	local currentFrame
	local scannerLight = A.LED
	local scannerLogo = A.SCAN_LOGO
	local scannerTouchConnection
	local readerBeep = Instance.new('Sound', A.Screen)
	readerBeep.Name = 'Reader_Beep'
	readerBeep.SoundId = 'rbxassetid://3378132335'
	readerBeep.Volume = 2
	readerBeep.MaxDistance = 70
	readerBeep.EmitterSize = 3

	print('TravelFiccient v2.0 starting...')
	--//Pasted from the config
	local themeConfig = _Settings['Theme']

	local elevators = Model:WaitForChild('Elevators')
	
	function check(dest, elevs)
		return require(script.Allocator).allocateElevator(tonumber(dest), (tonumber(A.Parent.Name:sub(7)) or tonumber(A.Parent.Name)), elevs)
	end

	if not themeConfig then
		themeConfig = {['Theme'] = {
			['Theme_Type'] = 'Dark', --Default theme is Dark if this setting does not exist. If set to Custom, the panel will use the settings below.
			['Custom_Theme'] = {
				--//Type: Gradient, uses Start and End input color values. Type: Solid, only uses the Start input color value.
				['Background_Color'] = {['Type'] = {'Gradient', ['Start'] = Color3.fromRGB(0, 0, 0), ['End'] = Color3.fromRGB(0, 0, 0),
					['Rotation'] = 0,
					['Transparency'] = 0,
					['Offset'] = Vector2.new(0, 0) --First number resembles the X axis (horizontal), and the second number resembles the Y axis (vertical).
				}},
				['Text_Color'] = Color3.fromRGB(255, 255, 255),
				['Button_Config'] = {

					['Background'] = {
						['Neutral'] = Color3.fromRGB(0, 0, 0),
						['Active'] = Color3.fromRGB(255, 255, 255),
					},
					['Text'] = {
						['Neutral'] = Color3.fromRGB(255, 255, 255),
						['Active'] = Color3.fromRGB(0, 0, 0),
					},

				}
			}
		}}
	else
		if themeConfig.Theme_Type == 'Dark' then
			themeConfig = {['Theme'] = {
				['Theme_Type'] = themeConfig.Theme_Type, --Default theme is Dark if this setting does not exist. If set to Custom, the panel will use the settings below.
				['Custom_Theme'] = {
					--//Type: Gradient, uses Start and End input color values. Type: Solid, only uses the Start input color value.
					['Background_Color'] = {['Type'] = {'Solid', ['Start'] = Color3.fromRGB(0, 0, 0), ['End'] = Color3.fromRGB(0, 0, 0),
						['Rotation'] = 0,
						['Transparency'] = 0,
						['Offset'] = Vector2.new(0, 0) --First number resembles the X axis (horizontal), and the second number resembles the Y axis (vertical).
					}},
					['Text_Color'] = Color3.fromRGB(255, 255, 255),
					['Button_Config'] = {

						['Background'] = {
							['Neutral'] = Color3.fromRGB(0, 0, 0),
							['Active'] = Color3.fromRGB(255, 255, 255),
						},
						['Text'] = {
							['Neutral'] = Color3.fromRGB(255, 255, 255),
							['Active'] = Color3.fromRGB(0, 0, 0),
						},

					}
				}
			}}
		elseif themeConfig.Theme_Type == 'Light' then
			themeConfig = {['Theme'] = {
				['Theme_Type'] = themeConfig.Theme_Type, --Default theme is Dark if this setting does not exist. If set to Custom, the panel will use the settings below.
				['Custom_Theme'] = {
					--//Type: Gradient, uses Start and End input color values. Type: Solid, only uses the Start input color value.
					['Background_Color'] = {['Type'] = {'Solid', ['Start'] = Color3.fromRGB(255, 255, 255), ['End'] = Color3.fromRGB(255, 255, 255),
						['Rotation'] = 0,
						['Transparency'] = 0,
						['Offset'] = Vector2.new(0, 0) --First number resembles the X axis (horizontal), and the second number resembles the Y axis (vertical).
					}},
					['Text_Color'] = Color3.fromRGB(0, 0, 0),
					['Button_Config'] = {

						['Background'] = {
							['Neutral'] = Color3.fromRGB(255, 255, 255),
							['Active'] = Color3.fromRGB(154, 154, 154),
						},
						['Text'] = {
							['Neutral'] = Color3.fromRGB(0, 0, 0),
							['Active'] = Color3.fromRGB(0, 0, 0),
						},

					}
				}
			}}
		elseif themeConfig.Theme_Type == 'Custom' then
			themeConfig = {['Theme'] = themeConfig}
		end
	end

	for i,v in pairs(_Display:GetDescendants()) do
		if v.Name == 'Theme_Gradient_Controller' then
			local nd = (themeConfig.Theme.Custom_Theme.Background_Color.Type[1] == 'Gradient') and themeConfig.Theme.Custom_Theme.Background_Color.Type.End or themeConfig.Theme.Custom_Theme.Background_Color.Type.Start
			v.Color = ColorSequence.new(themeConfig.Theme.Custom_Theme.Background_Color.Type.Start, nd)
			v.Offset = themeConfig.Theme.Custom_Theme.Background_Color.Type.Offset
			v.Rotation = themeConfig.Theme.Custom_Theme.Background_Color.Type.Rotation
			v.Transparency = NumberSequence.new(themeConfig.Theme.Custom_Theme.Background_Color.Type.Transparency)
			if v.Parent:IsA('TextLabel') then
				v.Parent.BackgroundColor3 = themeConfig.Theme.Custom_Theme.Text_Color
				v.Color = ColorSequence.new(themeConfig.Theme.Custom_Theme.Text_Color, themeConfig.Theme.Custom_Theme.Text_Color)
			elseif v.Parent:IsA('ImageLabel') then
				v.Color = ColorSequence.new(themeConfig.Theme.Custom_Theme.Text_Color, themeConfig.Theme.Custom_Theme.Text_Color)
				v.Parent.ImageColor3 = themeConfig.Theme.Custom_Theme.Text_Color
			end
		elseif v:IsA('TextLabel') then
			v.TextColor3 = themeConfig.Theme.Custom_Theme.Text_Color
			v.BorderColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Text.Neutral
		end
	end

	local T_API = game.ServerScriptService:FindFirstChild('TravelFiccient_API') or Instance.new('BindableFunction', game.ServerScriptService)
	T_API.Name = 'TravelFiccient_API'
	local L_API = Model:FindFirstChild('Local_API') or Instance.new('BindableEvent', Model)
	L_API.Name = 'Local_API'
	function T_API.OnInvoke(Target_Model, Event, Part1, Part2, Part3)
		if Target_Model == Model then
			if Event == 'Allocate_Elevator' then
				local elevator = check(Part1, elevators:GetChildren())
				if elevator then
					if (_Handicap) then
						Hall_Lanterns(elevator, Part1)
					end
					_Keypad_Input_Time = 0
					if (not elevator) then
						return spawn(function()
							_Timeout_Locked = true
							_Input_Locked = true
							_TransitionTo(lastFrame, _Display.No_Elevator)
							wait(2.5)
							_Input = ''
							_Display.Keypad.Input.Text = ''
							_TransitionTo(_Display.No_Elevator, lastFrame)
							_Timeout_Locked = false
							_Input_Locked = false
							_Btn_Debounce = false
							_Handicap = false
							_Handicap_Locked = false
							_Is_Handicap_Used = false
						end)
					end
					coroutine.wrap(function()
						_Request_Elevator_Call(elevator, Part1, Part2)
					end)()
					_Timeout_Locked = true
					_Input_Locked = true
					_Services['_Tween_Service']:Create(_Display.Blackscreen, TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
					wait(.2)
					_Display.Elevator.Visible = true
					_Display.Elevator.Main.Elevator.Text = elevator.Name
					_Display.Elevator.Floor.Text = 'To '..(_Settings['Display']['Custom_Floor_Label'][tostring(Part1)] or tostring(Part1))
					local direction = _Pad_Settings['Directionals'][elevator.Name]
					local arrow = _Display.Elevator.Main.Arrow
					_Is_Handicap_Used = false
					local rotation_index = {
						['Right'] = -90,
						['Right_Behind'] = -50,
						['Right_Ahead'] = -140,
						['Left'] = 90,
						['Left_Behind'] = 50,
						['Left_Ahead'] = 140,
						['Ahead'] = 180,
						['Behind'] = 0,
					}
					if (direction and rotation_index[direction]) then
						arrow.Rotation = rotation_index[direction]
					end
					_Services['_Tween_Service']:Create(_Display.Blackscreen, TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
					wait(5)
					_Services['_Tween_Service']:Create(_Display.Blackscreen, TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
					wait(.2)
					_Display.Elevator.Visible = false
					_Services['_Tween_Service']:Create(_Display.Blackscreen, TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
					wait(.2)
					for i,grp in pairs(_Display.Floor_Selection:GetChildren()) do
						if string.match(grp.Name, 'Group_') then
							for i,btn in pairs(grp:GetChildren()) do
								if btn:IsA('TextButton') then
									_Services['_Tween_Service']:Create(btn, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Background.Neutral}):Play()
									_Services['_Tween_Service']:Create(btn, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Text.Neutral}):Play()
								end
							end
						end
					end
					for i,grp in pairs(_Display.Floor_Selection.Floor_Groups:GetChildren()) do
						if string.match(grp.Name, 'Group_') then
							if grp:IsA('TextButton') then
								_Services['_Tween_Service']:Create(grp, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Background.Neutral}):Play()
								_Services['_Tween_Service']:Create(grp, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Text.Neutral}):Play()
							end
						end
					end
					_Btn_Debounce = false
					_Handicap = false
					_Handicap_Locked = false
					_Is_Handicap_Used = false
					_Input = ''
					_Display.Keypad.Input.Text = ''
					_Timeout_Locked = false
					_Input_Locked = false
					_Request_Elevator_Call(elevator, Part1, Part2)
					return elevator
				else
					return error('TravelFiccient: Unable to allocate nearest elevator.')
				end
			end
		end
	end

	local function playVoiceClip(clipName, pauseThread)

		_Voice_Module:PlayClip(_Voice, voiceConfig.Voice_Clips[clipName], pauseThread)

	end

	local function playVoiceSequenceProtocol(clipSequence, pauseThread)

		local function run()
			for index,item in pairs(clipSequence) do
				playVoiceClip(item[1], true)
				wait(item.Delay)
			end
		end
		if (pauseThread) then
			run()
		else
			coroutine.wrap(function()
				run()
			end)()
		end

	end

	L_API.Event:Connect(function(Event, Part1, Part2, Part3)
		if Event == 'Fire_Recall' then
			while (_Transitioning) do wait() end
			_TransitionTo(_Display.Home, _Display.Fire_Recall)
			_Input_Locked = true
			_Timeout_Locked = true
			_Handicap = false
			_Handicap_Locked = true
			_Is_Handicap_Used = false
			coroutine.wrap(function()
				for i=1,5 do
					if (not isFireRecall) then return end
					playVoiceClip('Fire_Recall', true)
					wait(2.5)
				end
			end)()
		end
		if Event == 'Fire_Recall_Off' then
			_Btn_Debounce = false
			_Handicap = false
			_Handicap_Locked = false
			_Is_Handicap_Used = false
			_Input = ''
			_Display.Keypad.Input.Text = ''
			_Timeout_Locked = false
			_Input_Locked = false
			_Highlighted_Group,_Highlighted_Button,_Group_Inactive,_Floor_Inactive = nil,nil,nil,nil
			while (_Transitioning) do wait() end
			_TransitionTo(_Display.Fire_Recall, _Display.Home)
		end
	end)

	local _HM_Click = Instance.new('Sound', A:WaitForChild('Handicap_Button'))
	_HM_Click.SoundId = 'rbxassetid://5163941878'
	_HM_Click.MaxDistance = 70
	_HM_Click.EmitterSize = 3
	_HM_Click.Volume = 1.3
	local _HB_In,_HB_Out = A:WaitForChild('Handicap_Button').CFrame * CFrame.new(0, 0, math.rad(.4)),A:WaitForChild('Handicap_Button').CFrame * CFrame.new(0, 0, -math.rad(.4))
	A:WaitForChild('Handicap_Button').Button.Handicap.MouseButton1Click:Connect(function()

		if (_Btn_Debounce_M or _Handicap_Locked) then return end
		_Btn_Debounce_M = true
		spawn(function()
			wait(.1)
			_Btn_Debounce_M = false
		end)

		local _C = _HM_Click:Clone()
		_C.Parent = _HM_Click.Parent
		_C:Play()
		game.Debris:AddItem(_C, _C.TimeLength)
		coroutine.wrap(function()
			_Services['_Tween_Service']:Create(A:WaitForChild('Handicap_Button'), TweenInfo.new(.04, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {CFrame = _HB_In}):Play()
			wait(.04)
			_Services['_Tween_Service']:Create(A:WaitForChild('Handicap_Button'), TweenInfo.new(.04, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {CFrame = _HB_Out}):Play()
			wait(.05)
		end)()
		if (isScannerActivated or isFireRecall or _Handicap_Locked) then return end
		_Handicap = true
		_Handicap_Locked = true
		_Input_Locked = true
		_Display.Floor_Selection.Floor_Groups.Visible = true
		for i,v in ipairs(_Display.Floor_Selection:GetChildren()) do
			if string.match(string.lower(v.Name), 'group_') then
				v.Visible = false
			end
		end
		if (_Highlighted_Button) then
			_Floor_Inactive = true
			for i,v in ipairs(_Display.Floor_Selection:GetChildren()) do
				if string.match(string.lower(v.Name), 'group_') then
					v.Visible = false
				end
			end
			local elevator
			local dest = _Highlighted_Button.Name
			_Btn_Debounce = true
			_Voice:Stop()
			spawn(function()
				lastFrame = _Display.Home

				elevator = check(dest, elevators:GetChildren())
				if (_Handicap) then
					Hall_Lanterns(elevator, thisFloor)
				end
				_Keypad_Input_Time = 0
				if (not elevator) then
					return spawn(function()
						_Timeout_Locked = true
						_Input_Locked = true
						_TransitionTo(lastFrame, _Display.No_Elevator)
						wait(2.5)
						_Input = ''
						_Display.Keypad.Input.Text = ''
						_TransitionTo(_Display.No_Elevator, lastFrame)
						_Timeout_Locked = false
						_Input_Locked = false
						_Btn_Debounce = false
						_Handicap = false
						_Handicap_Locked = false
						_Is_Handicap_Used = false
					end)
				end
				local callFloor = (tonumber(A.Parent.Name:sub(7)) or tonumber(A.Parent.Name))
				coroutine.wrap(function()
					_Request_Elevator_Call(elevator, callFloor, dest)
				end)()
				coroutine.wrap(function()
					_Timeout_Locked = true
					_Input_Locked = true
					_Services['_Tween_Service']:Create(_Display.Blackscreen, TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
					wait(.2)
					_Display.Elevator.Visible = true
					_Display.Elevator.Main.Elevator.Text = elevator.Name
					_Display.Elevator.Floor.Text = 'To '..(_Settings['Display']['Custom_Floor_Label'][tostring(dest)] or tostring(dest))
					local direction = _Pad_Settings['Directionals'][elevator.Name]
					local arrow = _Display.Elevator.Main.Arrow
					_Is_Handicap_Used = false
					local rotation_index = {
						['Right'] = -90,
						['Right_Behind'] = -50,
						['Right_Ahead'] = -140,
						['Left'] = 90,
						['Left_Behind'] = 50,
						['Left_Ahead'] = 140,
						['Ahead'] = 180,
						['Behind'] = 0,
					}
					if (direction and rotation_index[direction]) then
						arrow.Rotation = rotation_index[direction]
					end
					_Services['_Tween_Service']:Create(_Display.Blackscreen, TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
					wait(5)
					_Services['_Tween_Service']:Create(_Display.Blackscreen, TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
					wait(.2)
					_Display.Elevator.Visible = false
					_Services['_Tween_Service']:Create(_Display.Blackscreen, TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
					wait(.2)
					for i,grp in pairs(_Display.Floor_Selection:GetChildren()) do
						if string.match(grp.Name, 'Group_') then
							for i,btn in pairs(grp:GetChildren()) do
								if btn:IsA('TextButton') then
									_Services['_Tween_Service']:Create(btn, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Background.Neutral}):Play()
									_Services['_Tween_Service']:Create(btn, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Text.Neutral}):Play()
								end
							end
						end
					end
					for i,grp in pairs(_Display.Floor_Selection.Floor_Groups:GetChildren()) do
						if string.match(grp.Name, 'Group_') then
							if grp:IsA('TextButton') then
								_Services['_Tween_Service']:Create(grp, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Background.Neutral}):Play()
								_Services['_Tween_Service']:Create(grp, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Text.Neutral}):Play()
							end
						end
					end
					_Btn_Debounce = false
					_Handicap = false
					_Handicap_Locked = false
					_Is_Handicap_Used = false
					_Input = ''
					_Display.Keypad.Input.Text = ''
					_Timeout_Locked = false
					_Input_Locked = false
					_Highlighted_Group,_Highlighted_Button,_Group_Inactive,_Floor_Inactive = nil,nil,nil,nil
				end)()
			end)
			coroutine.resume(coroutine.create(function()
				wait(.3)
				playVoiceClip('Take_Car', true)
				wait(.08)
				pcall(function()
					playVoiceClip(elevator.Name, true)
				end)
				wait(.12)
				playVoiceClip('Going_To', true)
				wait(.04)
				playVoiceSequenceProtocol(voiceConfig.Voice_Config[tostring(dest)] or {{tostring(dest), ['Delay'] = 0}}, true)
				_Floor_Inactive = false
				_Group_Inactive = false
			end))
			_Highlighted_Group,_Highlighted_Button,_Group_Inactive,_Floor_Inactive = nil,nil,nil,nil
		elseif _Highlighted_Group then
			_Voice:Stop()
			_Group_Inactive = true
			_Floor_Inactive = false
			_Display.Floor_Selection.Floor_Groups.Visible = false
			_Display.Floor_Selection[_Highlighted_Group.Name].Visible = true
			local _Voicing = false
			wait(1)
			_Handicap_Locked = false
			if (not _Highlighted_Group) then
				_Btn_Debounce = false
				_Handicap = false
				_Handicap_Locked = false
				_Is_Handicap_Used = false
				_Input = ''
				_Display.Keypad.Input.Text = ''
				_Timeout_Locked = false
				_Input_Locked = false
				_Highlighted_Group,_Highlighted_Button,_Group_Inactive,_Floor_Inactive = nil,nil,nil,nil
				_Voice:Stop()
				_TransitionTo(_Display.Floor_Selection, _Display.Home)
				return
			end
			for flr,v in ipairs(_Display.Floor_Selection[_Highlighted_Group.Name]:GetChildren()) do
				if (v:IsA('TextButton') and v.BackgroundTransparency == 0) then
					if _Floor_Inactive then return end
					_Voicing = false
					_Highlighted_Button = v
					for i,grp2 in ipairs(_Display.Floor_Selection[_Highlighted_Group.Name]:GetChildren()) do
						if grp2:IsA('TextButton') then
							_Services['_Tween_Service']:Create(grp2, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Background.Neutral}):Play()
							_Services['_Tween_Service']:Create(grp2, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Text.Neutral}):Play()
						end
					end
					if v:IsA('TextButton') then
						_Services['_Tween_Service']:Create(v, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Background.Active}):Play()
						_Services['_Tween_Service']:Create(v, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Text.Active}):Play()
					end
					if _Floor_Inactive then return end
					if not _Voicing then
						_Voicing = true
						if _Floor_Inactive then return end
						pcall(function()
							playVoiceSequenceProtocol(voiceConfig.Voice_Config[v.Name] or {{v.Name, ['Delay'] = 0}}, true)
						end)
						if _Floor_Inactive then return end
					end
					wait(1.5)
					if _Floor_Inactive then return end
				end
			end
			_Btn_Debounce = false
			_Handicap = false
			_Handicap_Locked = false
			_Is_Handicap_Used = false
			_Input = ''
			_Display.Keypad.Input.Text = ''
			_Timeout_Locked = false
			_Input_Locked = false
			_Highlighted_Group,_Highlighted_Button,_Group_Inactive,_Floor_Inactive = nil,nil,nil,nil
			return
		elseif not _Is_Handicap_Used then
			_Is_Handicap_Used = true
			while (_Transitioning) do wait() end
			_TransitionTo(_Display.Home, _Display.Floor_Selection)
			_Timeout_Locked = true
			_Handicap_Locked = true
			_Btn_Debounce = true
			_Handicap = true
			playVoiceClip('Handicap_Message', true)
			local _Voicing = false
			wait(1)
			if _Group_Inactive then return end
			_Handicap_Locked = false
			coroutine.resume(coroutine.create(function()
				wait(.1)
				_Btn_Debounce = false
			end))
			for i=1, #_Display.Floor_Selection.Floor_Groups:GetChildren() do
				local v = _Display.Floor_Selection.Floor_Groups:FindFirstChild('Group_'..tostring(i))
				if v then
					_Voicing = false
					if _Group_Inactive then return end
					_Highlighted_Group = v
					for i,grp2 in ipairs(_Display.Floor_Selection.Floor_Groups:GetChildren()) do
						if string.match(string.lower(grp2.Name), 'group_') then
							if grp2:IsA('TextButton') then
								_Services['_Tween_Service']:Create(grp2, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Background.Neutral}):Play()
								_Services['_Tween_Service']:Create(grp2, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Text.Neutral}):Play()
							end
						end
					end
					if v:IsA('TextButton') then
						_Services['_Tween_Service']:Create(v, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Background.Active}):Play()
						_Services['_Tween_Service']:Create(v, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Text.Active}):Play()
					end
					if _Group_Inactive then return end
					if not _Voicing then
						_Voicing = true
						local split = string.split(v.Real_Floor_Group_Label.Value, '-')
						local first,last
						for i,vc in ipairs(split) do
							if not first then first = tostring(vc) end
							break
						end
						for i,vc in ipairs(split) do
							last = tostring(vc)
						end
						pcall(function()
							playVoiceSequenceProtocol(voiceConfig.Voice_Config[first] or {{first, ['Delay'] = 0}}, true)
						end)
						if _Group_Inactive then return end
						wait(.1)
						if _Group_Inactive then return end
						pcall(function()
							playVoiceClip('Through', true)
						end)
						if _Group_Inactive then return end
						wait(.1)
						if _Group_Inactive then return end
						pcall(function()
							playVoiceSequenceProtocol(voiceConfig.Voice_Config[last] or {{last, ['Delay'] = 0}}, true)
						end)
						if _Group_Inactive then return end
					end
					wait(1)
					if _Group_Inactive then return end
				end
			end
			for i,grp in ipairs(_Display.Floor_Selection:GetChildren()) do
				if string.match(grp.Name, 'Group_') then
					if grp:IsA('TextButton') then
						_Services['_Tween_Service']:Create(grp, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Background.Neutral}):Play()
						_Services['_Tween_Service']:Create(grp, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Text.Neutral}):Play()
					end
				end
			end
			for i,grp in ipairs(_Display.Floor_Selection.Floor_Groups:GetChildren()) do
				if string.match(grp.Name, 'Group_') then
					for i,grp2 in ipairs(grp:GetChildren()) do
						if grp2:IsA('TextButton') then
							_Services['_Tween_Service']:Create(grp2, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Background.Neutral}):Play()
							_Services['_Tween_Service']:Create(grp2, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Text.Neutral}):Play()
						end
					end
				end
			end
			wait(.5)
			if (not _Handicap) then return end
			_TransitionTo(_Display.Floor_Selection, _Display.Home)
			_Btn_Debounce = false
			_Handicap = false
			_Handicap_Locked = false
			_Is_Handicap_Used = false
			_Input = ''
			_Display.Keypad.Input.Text = ''
			_Timeout_Locked = false
			_Input_Locked = false
			_Highlighted_Group,_Highlighted_Button,_Group_Inactive,_Floor_Inactive = nil,nil,nil,nil
		end
	end)

	_Display.Logo.Size = UDim2.new(0, 0, 0, 0)
	_Display.Home.Header.Text = _Settings['Naming']['Home_Header']
	_Display.Blackscreen.BackgroundTransparency = 0
	for i,v in pairs(_Display:GetChildren()) do
		if v.Name ~= 'Home' then
			pcall(function()
				v.Visible = false
			end)
		end
	end
	_Display.Home.Visible = true
	_Display.Blackscreen.Visible = true
	_Display.Keypad.Input.Text = ''
	function _Transition()
		if _Transitioning then return end
		_Timeout_Locked = true
		_Transitioning = true
		_Services['_Tween_Service']:Create(_Display.Blackscreen, TweenInfo.new(.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
		wait(.3)
		_Services['_Tween_Service']:Create(_Display.Logo, TweenInfo.new(.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = UDim2.new(.2, 0, .2, 0)}):Play()
		wait(.6)
		_Services['_Tween_Service']:Create(_Display.Logo, TweenInfo.new(.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Rotation = _Display.Logo.Rotation+360}):Play()
		_Services['_Tween_Service']:Create(_Display.Logo, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Position = _Display.Logo.Position-UDim2.new(0, 0, .15, 0)}):Play()
		wait(.3)
		_Services['_Tween_Service']:Create(_Display.Logo, TweenInfo.new(.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {Position = _Display.Logo.Position+UDim2.new(0, 0, .15, 0)}):Play()
		wait(.3)
		_Services['_Tween_Service']:Create(_Display.Logo, TweenInfo.new(.4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = UDim2.new(0, 0, 0, 0)}):Play()
		wait(.4)
		_Services['_Tween_Service']:Create(_Display.Blackscreen, TweenInfo.new(.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
		wait(.6)
		_Transitioning = false
		_Timeout_Locked = false
	end
	function _TransitionTo(_From_Frame, _To_Frame)
		if _Transitioning then return end
		_Transitioning = true
		_Timeout_Locked = true
		_Services['_Tween_Service']:Create(_Display.Blackscreen, TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
		wait(.2)
		_From_Frame.Visible = false
		_Services['_Tween_Service']:Create(_Display.Blackscreen, TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
		_To_Frame.Visible = true
		wait(.2)
		_Transitioning = false
		_Timeout_Locked = false
	end
	_Transition()
	_Display.Home.Buttons_List.Floor_Selection.MouseButton1Click:Connect(function()
		_Display.Floor_Selection.Floor_Groups.Visible = true
		for i,v in ipairs(_Display.Floor_Selection:GetChildren()) do
			if string.match(string.lower(v.Name), 'group_') then
				v.Visible = false
			end
		end
		_TransitionTo(_Display.Home, _Display.Floor_Selection)
	end)
	_Display.Home.Buttons_List.Destination_Keypad.MouseButton1Click:Connect(function()
		_Keypad_Enabled = true
		_TransitionTo(_Display.Home, _Display.Keypad)
	end)
	_Display.Keypad.Home.MouseButton1Click:Connect(function()
		_TransitionTo(_Display.Keypad, _Display.Home)
	end)

	_Display.Floor_Selection.Home.MouseButton1Click:Connect(function()
		if _Handicap then return end
		coroutine.resume(coroutine.create(function()
			wait(.6)
			_Display.Floor_Selection.Floor_Groups.Visible = true
			for i,v in ipairs(_Display.Floor_Selection:GetChildren()) do
				if string.match(string.lower(v.Name), 'group_') then
					v.Visible = false
				end
			end
		end))
		_TransitionTo(_Display.Floor_Selection, _Display.Home)
	end)
	
	local startTime = tick();
	local updating = false;
	
	local function handleScreenUpdater()
		
		coroutine.wrap(function()
			if (updating) then return end
			updating = true;
			while (math.abs(tick()-startTime) <= (_Settings.Display.Pad_Fade_Timeout or 5)) do
				wait(.25)
				if (_Timeout_Locked) then startTime = tick() end
				if (isFireRecall) then updating = false return end
			end
			_Display.Blackscreen.Theme_Gradient_Controller.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0), Color3.fromRGB(0, 0, 0))
			_Services['_Tween_Service']:Create(_Display.Blackscreen, TweenInfo.new(.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
			updating = false;
		end)();
		
	end

	_Display.Blackscreen.MouseEnter:Connect(function()
		if (_Transitioning) then return end
		_Services['_Tween_Service']:Create(_Display.Blackscreen, TweenInfo.new(.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
		startTime = tick();
		handleScreenUpdater();
		wait(.4)
	end)
	_Display.Blackscreen.MouseMoved:Connect(function()
		if (_Transitioning) then return end
		_Services['_Tween_Service']:Create(_Display.Blackscreen, TweenInfo.new(.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
		startTime = tick();
		handleScreenUpdater();
		wait(.4)
		local nd = (themeConfig.Theme.Custom_Theme.Background_Color.Type[1] == 'Gradient') and themeConfig.Theme.Custom_Theme.Background_Color.Type.End or themeConfig.Theme.Custom_Theme.Background_Color.Type.Start
		_Display.Blackscreen.Theme_Gradient_Controller.Color = ColorSequence.new(themeConfig.Theme.Custom_Theme.Background_Color.Type.Start, nd)
	end)
	startTime = tick();
	handleScreenUpdater();

	local firstNum = 0

	for i,v in pairs(_Display.Floor_Selection.Floor_Groups:GetChildren()) do
		if (v:IsA('TextButton')) then
			v:Destroy()
		end
	end

	for i,v in pairs(_Display.Floor_Selection:GetChildren()) do
		if (v.Name:match('Group_')) then
			v:Destroy()
		end
	end

	for grp,v in pairs(_Settings['Display']['Floor_Groups']) do
		for i,f in ipairs(A.Parent.Parent:GetChildren()) do
			if not _Display.Floor_Selection.Floor_Groups:FindFirstChild(grp) then
				local group = script.Assets.Group_Button:Clone()
				group.Parent = _Display.Floor_Selection.Floor_Groups
				group.Name = tostring(grp)
				local firstnumberto,lastnumberto = 0,0
				for grp2,v2 in pairs(_Settings['Display']['Floor_Groups']) do
					for flr2,r2 in ipairs(v) do
						if firstnumberto == 0 then
							firstnumberto = {tonumber(r2),_Settings['Display']['Custom_Floor_Label'][tostring(r2)] or tostring(r2)}
							firstNum = tonumber(r2)
							break
						end
					end
				end
				for grp2,v2 in pairs(_Settings['Display']['Floor_Groups']) do
					for flr2,r2 in ipairs(v) do
						lastnumberto = {tonumber(r2),_Settings['Display']['Custom_Floor_Label'][tostring(r2)] or tostring(r2)}
					end
				end
				group.LayoutOrder = firstnumberto[1]
				group.Text = firstnumberto[2]..'-'..lastnumberto[2]
				local newVal = Instance.new('StringValue', group)
				newVal.Name = 'Real_Floor_Group_Label'
				newVal.Value = tostring(firstnumberto[1])..'-'..tostring(lastnumberto[1])
				local frame = script.Assets.Group:Clone()
				frame.Parent = _Display.Floor_Selection
				frame.Name = grp
				for grp2,v2 in pairs(_Settings['Display']['Floor_Groups']) do
					for flr2,r2 in ipairs(v) do
						if not frame:FindFirstChild(tostring(r2)) and A.Parent.Parent:FindFirstChild('Floor_'..tostring(r2)) or A.Parent.Parent:FindFirstChild(tostring(r2)) then
							local btn = script.Assets.Group_Button:Clone()
							btn.Parent = frame
							btn.Name = tostring(r2)
							btn.Text = _Settings['Display']['Custom_Floor_Label'][tostring(r2)] or tostring(r2)
							btn.LayoutOrder = r2
							if (r2 == thisFloor) then
								btn.BackgroundTransparency = .8
								btn.TextTransparency = .8
							end
							if (table.find((_Settings.Locking and _Settings.Locking.Locked_Floors or {}), r2)) then

								btn.BackgroundTransparency = .4
								btn.TextTransparency = .4
								local img = Instance.new('ImageButton', btn)
								img.Image = 'rbxassetid://7643218021'
								img.Size = UDim2.new(.85, 0, .85, 0)
								img.AnchorPoint = Vector2.new(.5, .5)
								img.Position = UDim2.new(.5, 0, .5, 0)
								img.BackgroundTransparency = 1
								img.ScaleType = Enum.ScaleType.Fit
								img.Name = 'Lock_Icon'
								local uiScale = Instance.new('UIScale', img)
								uiScale.Scale = 1
								img.InputBegan:Connect(function(input)
									if ((not img.Visible) or _Input_Locked or _Handicap) then return end
									if (input.UserInputType == Enum.UserInputType.Focus or input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
										_Services._Tween_Service:Create(uiScale, TweenInfo.new(.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Scale = .8}):Play()
									end
								end)
								img.InputEnded:Connect(function(input)
									if ((not img.Visible) or _Input_Locked or _Handicap) then return end
									if (input.UserInputType == Enum.UserInputType.Focus or input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
										_Services._Tween_Service:Create(uiScale, TweenInfo.new(.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Scale = 1}):Play()
									end
								end)
								img.MouseButton1Click:Connect(function()
									if ((not img.Visible) or _Input_Locked or _Handicap) then return end
									scannerReady = true
									currentFrame = _Display.Floor_Selection
									_TransitionTo(_Display.Floor_Selection, _Display.Scan_Card)
									activateScanner('unlockFloor', function()

										img.Visible = false
										btn.BackgroundTransparency = 0
										btn.TextTransparency = 0
										delay(3, function()
											if (img.Visible) then return end
											img.Visible = true
											btn.BackgroundTransparency = .4
											btn.TextTransparency = .4
										end)
										_TransitionTo(_Display.Scan_Card, _Display.Floor_Selection)

									end)
								end)

							end
							btn.MouseButton1Click:Connect(function()
								if (_Input_Locked or _Handicap or btn.BackgroundTransparency ~= 0) then return end
								lastFrame = _Display.Floor_Selection
								local elevator = check(r2, elevators:GetChildren())
								if (_Handicap) then
									Hall_Lanterns(elevator, thisFloor)
								end
								_Keypad_Input_Time = 0
								if (not elevator) then
									return spawn(function()
										_Timeout_Locked = true
										_Input_Locked = true
										_TransitionTo(lastFrame, _Display.No_Elevator)
										wait(2.5)
										_Input = ''
										_Display.Keypad.Input.Text = ''
										_TransitionTo(_Display.No_Elevator, lastFrame)
										_Timeout_Locked = false
										_Input_Locked = false
										_Btn_Debounce = false
										_Handicap = false
										_Handicap_Locked = false
										_Is_Handicap_Used = false
									end)
								end
								local callFloor = (tonumber(A.Parent.Name:sub(7)) or tonumber(A.Parent.Name))
								coroutine.wrap(function()
									_Request_Elevator_Call(elevator, callFloor, r2)
								end)()
								_Timeout_Locked = true
								_Input_Locked = true
								_Services['_Tween_Service']:Create(_Display.Blackscreen, TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
								wait(.2)
								_Display.Elevator.Visible = true
								_Display.Elevator.Main.Elevator.Text = elevator.Name
								_Display.Elevator.Floor.Text = 'To '..(_Settings['Display']['Custom_Floor_Label'][tostring(r2)] or tostring(r2))
								local direction = _Pad_Settings['Directionals'][elevator.Name]
								local arrow = _Display.Elevator.Main.Arrow
								_Is_Handicap_Used = false
								local rotation_index = {
									['Right'] = -90,
									['Right_Behind'] = -50,
									['Right_Ahead'] = -140,
									['Left'] = 90,
									['Left_Behind'] = 50,
									['Left_Ahead'] = 140,
									['Ahead'] = 180,
									['Behind'] = 0,
								}
								if (direction and rotation_index[direction]) then
									arrow.Rotation = rotation_index[direction]
								end
								_Services['_Tween_Service']:Create(_Display.Blackscreen, TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
								wait(5)
								_Services['_Tween_Service']:Create(_Display.Blackscreen, TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
								wait(.2)
								_Display.Elevator.Visible = false
								_Services['_Tween_Service']:Create(_Display.Blackscreen, TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
								wait(.2)
								for i,grp in pairs(_Display.Floor_Selection:GetChildren()) do
									if string.match(grp.Name, 'Group_') then
										for i,btn in pairs(grp:GetChildren()) do
											if btn:IsA('TextButton') then
												_Services['_Tween_Service']:Create(btn, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Background.Neutral}):Play()
												_Services['_Tween_Service']:Create(btn, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Text.Neutral}):Play()
											end
										end
									end
								end
								for i,grp in pairs(_Display.Floor_Selection.Floor_Groups:GetChildren()) do
									if string.match(grp.Name, 'Group_') then
										if grp:IsA('TextButton') then
											_Services['_Tween_Service']:Create(grp, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Background.Neutral}):Play()
											_Services['_Tween_Service']:Create(grp, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Text.Neutral}):Play()
										end
									end
								end
								_Btn_Debounce = false
								_Handicap = false
								_Handicap_Locked = false
								_Is_Handicap_Used = false
								_Input = ''
								_Display.Keypad.Input.Text = ''
								_Timeout_Locked = false
								_Input_Locked = false
							end)
						end
					end
				end
				group.MouseButton1Click:Connect(function()
					if _Handicap then return end
					_Display.Floor_Selection.Floor_Groups.Visible = false
					_Display.Floor_Selection[grp].Visible = true
				end)
			end
		end
	end
	
	local isUpdating = false
	local startTime = tick();
	local function handleUpdater()
		
		if (isUpdating) then return end
		isUpdating = true
		coroutine.wrap(function()
			while (math.abs(tick()-startTime) < 2) do
				wait(.25)
				if (isFireRecall) then isUpdating = false return end
			end
			_Keypad_Enabled = false
			if _Input == '*' then _Input = '1' end
			if not A.Parent.Parent:FindFirstChild(('Floor_'..tostring(_Input)) or (tostring(_Input))) then
				_Input = ''
				_Input_Locked = true
				_Keypad_Input_Time = 0
				local tween = _Services._Tween_Service:Create(_Display.Keypad.Input, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {TextTransparency=1});
				tween:Play();
				tween.Completed:Wait();
				_Display.Keypad.Input.Text = '???'
				local tween = _Services._Tween_Service:Create(_Display.Keypad.Input, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {TextTransparency=0});
				tween:Play();
				tween.Completed:Wait();
				wait(1)
				local tween = _Services._Tween_Service:Create(_Display.Keypad.Input, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {TextTransparency=1});
				tween:Play();
				tween.Completed:Wait();
				_Display.Keypad.Input.Text = ''
				_Input_Locked = false
				isUpdating = false;
				return
			end
			lastFrame = _Display.Keypad

			local function run(frame)

				local elevator = check(tonumber(_Input), elevators:GetChildren())
				_Keypad_Input_Time = 0
				if (_Handicap) then
					Hall_Lanterns(elevator, thisFloor)
				end
				if (not elevator) then
					return spawn(function()
						_Timeout_Locked = true
						_Input_Locked = true
						_TransitionTo(lastFrame, _Display.No_Elevator)
						wait(2.5)
						_Input = ''
						_Display.Keypad.Input.Text = ''
						_TransitionTo(_Display.No_Elevator, lastFrame)
						_Timeout_Locked = false
						_Input_Locked = false
						_Btn_Debounce = false
						_Handicap = false
						_Handicap_Locked = false
						_Is_Handicap_Used = false
					end)
				end
				local callFloor = (tonumber(A.Parent.Name:sub(7)) or tonumber(A.Parent.Name))
				coroutine.wrap(function()
					_Request_Elevator_Call(elevator, callFloor, tonumber(_Input))
				end)()
				_Timeout_Locked = true
				_Input_Locked = true
				coroutine.wrap(function()
					_TransitionTo(frame, _Display.Elevator)
				end)()
				_Display.Elevator.Main.Elevator.Text = elevator.Name
				_Display.Elevator.Floor.Text = 'To '..(_Settings['Display']['Custom_Floor_Label'][tostring(_Input)] or tostring(_Input))
				local direction = _Pad_Settings['Directionals'][elevator.Name]
				local arrow = _Display.Elevator.Main.Arrow
				_Is_Handicap_Used = false
				local rotation_index = {
					['Right'] = -90,
					['Right_Behind'] = -50,
					['Right_Ahead'] = -140,
					['Left'] = 90,
					['Left_Behind'] = 50,
					['Left_Ahead'] = 140,
					['Ahead'] = 180,
					['Behind'] = 0,
				}
				if (direction and rotation_index[direction]) then
					arrow.Rotation = rotation_index[direction]
				end
				wait(5)
				coroutine.wrap(function()
					_TransitionTo(_Display.Elevator, _Display.Keypad)
				end)()
				for i,grp in pairs(_Display.Floor_Selection:GetChildren()) do
					if string.match(grp.Name, 'Group_') then
						for i,btn in pairs(grp:GetChildren()) do
							if btn:IsA('TextButton') then
								_Services['_Tween_Service']:Create(btn, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Background.Neutral}):Play()
								_Services['_Tween_Service']:Create(btn, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Text.Neutral}):Play()
							end
						end
					end
				end
				for i,grp in pairs(_Display.Floor_Selection.Floor_Groups:GetChildren()) do
					if string.match(grp.Name, 'Group_') then
						if grp:IsA('TextButton') then
							_Services['_Tween_Service']:Create(grp, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Background.Neutral}):Play()
							_Services['_Tween_Service']:Create(grp, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Text.Neutral}):Play()
						end
					end
				end
				_Btn_Debounce = false
				_Handicap = false
				_Handicap_Locked = false
				_Is_Handicap_Used = false
				_Input = ''
				_Display.Keypad.Input.Text = ''
				_Timeout_Locked = false
				_Input_Locked = false
				isUpdating = false

			end
			if (table.find(_Settings.Locking and _Settings.Locking.Locked_Floors or {}, tonumber(_Input))) then
				scannerReady = true
				currentFrame = _Display.Keypad
				_TransitionTo(_Display.Keypad, _Display.Scan_Card)
				activateScanner('unlockFloor', function()

					run(_Display.Scan_Card)

				end)
			else
				run(_Display.Keypad)
			end
		end)()

	end

	for i,btn in pairs(_Display.Keypad.Buttons:GetChildren()) do
		if btn:IsA('TextButton') then
			btn.MouseButton1Click:Connect(function()
				if (_Handicap or (string.len(_Input) >= 4 or _Input_Locked)) then return end
				startTime = tick();
				handleUpdater();
				_Input = _Input..btn.Name
				_Keypad_Input_Time = 0
				_Services['_Tween_Service']:Create(_Display.Keypad.Input, TweenInfo.new(.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {TextTransparency = 1}):Play()
				wait(.1)
				_Display.Keypad.Input.Text = _Input
				_Services['_Tween_Service']:Create(_Display.Keypad.Input, TweenInfo.new(.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {TextTransparency = 0}):Play()
			end)
		end
	end

	function _Request_Elevator_Call(Elevator, Floor, Destination)
		Elevator.Cortex_API:Fire('Request_Call_F', Floor)
		local doorConnections = {}
		for i,v in pairs(Elevator.Legacy:GetChildren()) do
			if (v.Name:match('Door_State')) then
				doorConnections[v] = v:GetPropertyChangedSignal('Value'):Connect(function()

					if (Elevator.Legacy.Floor.Value == Floor and Elevator.Legacy.Move_Value.Value == 0 and v.Value ~= 'Closed') then
						Elevator.Cortex_API:Fire('Request_Call_F', Destination)
						for i,c in pairs(doorConnections) do
							c:Disconnect()
						end
					end

				end)
			end
		end
	end

	for i,v in pairs(A.Parent.Parent.Parent:FindFirstChild('Hall_Lanterns'):GetChildren()) do
		for i,l in pairs(v:GetChildren()) do
			for i,led in pairs(l:GetChildren()) do
				if (led:IsA('BasePart') and led.Name == 'Light') then
					led.Color,led.Material = _Settings['Hall_Lanterns']['Neutral']['Color'],_Settings['Hall_Lanterns']['Neutral']['Material']
				end
			end
		end
	end

	function Hall_Lanterns(Elevator, Floor)
		if Elevator then
			local _HL = A.Parent.Parent.Parent:FindFirstChild('Hall_Lanterns')
			if _HL then
				local _H = _HL:FindFirstChild(Elevator.Name):FindFirstChild('Floor_'..tostring(Floor))
				if _H then
					for i,v in pairs(_H:GetChildren()) do
						if v.Name == 'Light' then
							if _Settings['Hall_Lanterns']['Light_Mode'] == 'Flash' then
								coroutine.resume(coroutine.create(function()
									repeat
										v.Color,v.Material = _Settings['Hall_Lanterns']['Active']['Color'],_Settings['Hall_Lanterns']['Active']['Material']
										wait(.3)
										v.Color,v.Material = _Settings['Hall_Lanterns']['Neutral']['Color'],_Settings['Hall_Lanterns']['Neutral']['Material']
										wait(.3)
									until Elevator.Legacy.Floor.Value == tonumber(Floor) and Elevator.Legacy.Move_Direction.Value == 'N'
									for i=1,4 do
										v.Color,v.Material = _Settings['Hall_Lanterns']['Active']['Color'],_Settings['Hall_Lanterns']['Active']['Material']
										wait(.3)
										v.Color,v.Material = _Settings['Hall_Lanterns']['Neutral']['Color'],_Settings['Hall_Lanterns']['Neutral']['Material']
										wait(.3)
									end
								end))
							elseif _Settings['Hall_Lanterns']['Light_Mode'] == 'Solid' then
								coroutine.resume(coroutine.create(function()
									v.Color,v.Material = _Settings['Hall_Lanterns']['Active']['Color'],_Settings['Hall_Lanterns']['Active']['Material']
									repeat wait() until Elevator.Legacy.Floor.Value == tonumber(Floor) and Elevator.Legacy.Move_Direction.Value == 'N'
									wait(5)
									v.Color,v.Material = _Settings['Hall_Lanterns']['Neutral']['Color'],_Settings['Hall_Lanterns']['Neutral']['Material']
								end))
							elseif _Settings['Hall_Lanterns']['Light_Mode'] == 'Both' then
								coroutine.resume(coroutine.create(function()
									v.Color,v.Material = _Settings['Hall_Lanterns']['Active']['Color'],_Settings['Hall_Lanterns']['Active']['Material']
									repeat wait() until Elevator.Legacy.Floor.Value == tonumber(Floor)
									repeat
										v.Color,v.Material = _Settings['Hall_Lanterns']['Active']['Color'],_Settings['Hall_Lanterns']['Active']['Material']
										wait(.3)
										v.Color,v.Material = _Settings['Hall_Lanterns']['Neutral']['Color'],_Settings['Hall_Lanterns']['Neutral']['Material']
										wait(.3)
									until Elevator.Legacy.Floor.Value == tonumber(Floor) and Elevator.Legacy.Move_Direction.Value == 'N'
								end))
							end
						end
					end
				end
			end
		end
	end

	--function check(dest, elevs)
	--	print("run", dest, elevs)
	--	return require(script.Allocator).allocateElevator(tonumber(dest), (tonumber(A.Parent.Name:sub(7)) or tonumber(A.Parent.Name)), elevs)

	--end

	for i,button in ipairs(_Display:GetDescendants()) do
		if button:IsA('TextButton') and button.BorderSizePixel == 3 then
			button.AutoButtonColor = false
			button.BackgroundColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Background.Neutral
			button.BorderColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Text.Neutral
			button.TextColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Text.Neutral
			button.MouseButton1Down:Connect(function()
				if _Handicap or button.BackgroundTransparency ~= 0 then return end
				_Services['_Tween_Service']:Create(button, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Background.Active}):Play()
				_Services['_Tween_Service']:Create(button, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Text.Active}):Play()
			end)
			button.MouseLeave:Connect(function()
				if _Handicap or button.BackgroundTransparency ~= 0 then return end
				_Services['_Tween_Service']:Create(button, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Background.Neutral}):Play()
				_Services['_Tween_Service']:Create(button, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Text.Neutral}):Play()
			end)
			button.MouseButton1Up:Connect(function()
				if _Handicap or button.BackgroundTransparency ~= 0 then return end
				_Services['_Tween_Service']:Create(button, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Background.Neutral}):Play()
				_Services['_Tween_Service']:Create(button, TweenInfo.new(.085, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextColor3 = themeConfig.Theme.Custom_Theme.Button_Config.Text.Neutral}):Play()
			end)
		end
		if button.Name ~= 'Elevator' and button:IsA('TextLabel') or button:IsA('TextBox') or button:IsA('TextButton') then
			--local custom_font = script.Assets.Custom_Font:Clone()
			--custom_font.Parent = button
			--custom_font.Disabled = false
		end
	end

	--Fire recall and card control, new values created too, old ones are older--
	
	collectionService:AddTag(_Display.Admin_Panel, 'Locked');

	activateScanner = function(scannerType, optionalCallback)
		if ((not scannerReady) or scannerActive or scannerType == '') then return end
		scannerLight.Color = Color3.fromRGB(163, 162, 165)
		scannerLight.Material = Enum.Material.Neon
		scannerLight.Transparency = 0
		isScannerActivated = true
		_Timeout_Locked = true
		_Input_Locked = true
		_Handicap_Locked = true
		playVoiceClip('Please_Scan_Access_Card', false)
		delay(5, function()
			if not scannerReady then return end
			scannerActive = false
			scannerReady = false
			_Input = ''
			_Display.Keypad.Input.Text = ''
			_Timeout_Locked = false
			_Input_Locked = false
			_Btn_Debounce = false
			_Handicap = false
			_Handicap_Locked = false
			_Is_Handicap_Used = false
			scannerLight.Color = Color3.fromRGB(91, 93, 105)
			scannerLight.Material = Enum.Material.Glass
			scannerLight.Transparency = .15
			scannerTouchConnection:Disconnect()
			_TransitionTo(_Display.Scan_Card, currentFrame)
			currentFrame = nil
			isScannerActivated = false
		end)
		scannerTouchConnection = scannerLogo.Touched:Connect(function(hit)
			if not scannerReady or scannerActive or scannerType == '' then return end
			local accessLevel = hit.Parent:FindFirstChild('Access_Level')
			if accessLevel then
				scannerActive = true
				delay(1.3, function()
					scannerActive = false
					scannerReady = false
					isScannerActivated = false
					_Timeout_Locked = isFireRecall
					scannerLight.Color = Color3.fromRGB(91, 93, 105)
					scannerLight.Material = Enum.Material.Glass
					scannerLight.Transparency = .15
					scannerTouchConnection:Disconnect()
				end)
				local lvl
				if (_Settings['Display']['Access_Level']) then
					lvl = _Settings['Display']['Access_Level']
				else
					lvl = 5
				end
				if (accessLevel.Value >= lvl) then
					readerBeep:Play()
					_Input_Locked = false;
					scannerLight.Color = Color3.fromRGB(121, 212, 109)
					if scannerType == 'disableFS' then
						currentFrame = _Display.FS_Disable_Success
						_TransitionTo(_Display.Scan_Card, _Display.FS_Disable_Success)
						isFireRecall = false
						_Handicap_Locked = false
						L_API:Fire('Fire_Recall_Off')
						local elevators = A.Parent.Parent.Parent:WaitForChild('Elevators')
						for i,elev in pairs(elevators:GetChildren()) do
							if elev:FindFirstChild('Cortex_API') then
								spawn(function()
									elev.Cortex_API:Fire('Fire_Recall', false, (tonumber(A.Parent.Name:sub(7)) or tonumber(A.Parent.Name)))
								end)
							end
						end
						delay(2.5, function()
							_TransitionTo(_Display.FS_Disable_Success, _Display.Home)
							scannerReady = false
							scannerActive = false
							isScannerActivated = false
							scannerType = ''
						end)
					elseif (scannerType == 'adminPanelAccess') then
						local hasTag = collectionService:HasTag(_Display.Admin_Panel, 'Locked');
						if (not hasTag) then collectionService:AddTag(_Display.Admin_Panel, 'Locked'); end
						_TransitionTo(_Display.Scan_Card, _Display.Admin_Panel);
						if (hasTag) then collectionService:RemoveTag(_Display.Admin_Panel, 'Locked'); end
					elseif (scannerType == 'unlockFloor') then
						if (optionalCallback) then
							optionalCallback()
						end
					end
				else
					scannerLight.Color = Color3.fromRGB(212, 88, 88)
					spawn(function()
						readerBeep:Play()
						wait(.15)
						readerBeep:Play()
					end)
					delay(1, function()
						scannerActive = false
						scannerReady = false
						_Input = ''
						_Display.Keypad.Input.Text = ''
						_Timeout_Locked = false
						_Input_Locked = false
						_Btn_Debounce = false
						_Handicap = false
						_Handicap_Locked = false
						_Is_Handicap_Used = false
						_TransitionTo(_Display.Scan_Card, _Display.Home)
					end)
				end
			end
		end)
	end

	_Display.Fire_Recall.Disable.MouseButton1Click:Connect(function()
		scannerReady = true
		currentFrame = _Display.Fire_Recall
		_TransitionTo(_Display.Fire_Recall, _Display.Scan_Card)
		activateScanner('disableFS')
	end)

	_Display.Home.Buttons_List.Admin_Panel.MouseButton1Click:Connect(function()
		_TransitionTo(_Display.Home, _Display.Scan_Card)
		scannerReady = true
		currentFrame = _Display.Home
		activateScanner('adminPanelAccess')
	end)

	_Display.Admin_Panel.Home.MouseButton1Click:Connect(function()
		_TransitionTo(_Display.Admin_Panel, _Display.Home)
	end)

	_Display.Admin_Panel.Buttons_List.Reboot_Panel.MouseButton1Click:Connect(function()
		if (collectionService:HasTag(_Display.Admin_Panel, 'Locked')) then return end;
		_Display.Blackscreen.BackgroundTransparency = 1
		_Timeout_Locked = true
		local reset = script.Assets.Reset:Clone()
		reset.Parent = oriSettings.Parent.Loader
		reset.Disabled = false
	end)

	_Display.Admin_Panel.Buttons_List.Enable_FS.MouseButton1Click:Connect(function()
		if (collectionService:HasTag(_Display.Admin_Panel, 'Locked')) then return end;
		_TransitionTo(_Display.Admin_Panel, _Display.Fire_Recall)
		_Timeout_Locked = true
		isFireRecall = true
		_Handicap_Locked = true
		L_API:Fire('Fire_Recall')
		local elevators = A.Parent.Parent.Parent:WaitForChild('Elevators')
		for i,elev in pairs(elevators:GetChildren()) do
			if elev:FindFirstChild('Cortex_API') then
				spawn(function()
					elev.Cortex_API:Fire('Fire_Recall', true, (tonumber(A.Parent.Name:sub(7)) or tonumber(A.Parent.Name)))
				end)
			end
		end
	end)
	
end