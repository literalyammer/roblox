return function(Script)
	warn('Cortex Auto Door Controller: Initializing...')
	local ranBool,debugInfo = coroutine.resume(coroutine.create(function()
		local this = Script.Parent
		local level = this:WaitForChild('Level')
		local config = this:FindFirstChild('Config')

		if not Script.Parent:FindFirstChild('Config') then
			return assert(false, 'Cortex Sliding Door Engine v1.2.7: Config module not found')
		end

		config = require(config)

		local engines = {}
		local status = 'closed'
		local delta = 0
		local heartbeat = game:GetService('RunService').Heartbeat
		local players = {}
		local doorTime = 0
		local isInSensor,prevInSensor = false,false

		local sensors = this:FindFirstChild('Sensors')

		local weld = function(model, weldPart)
			for i,v in pairs(model:GetDescendants()) do
				if v:IsA('BasePart') then
					if v ~= weldPart then
						local scaler = v.Parent:FindFirstChild('Scaler')
						if scaler then
							for i,v in pairs(scaler.Parent:GetDescendants()) do
								if v:IsA('BasePart') then
									if v ~= weldPart then
										if v ~= scaler and v ~= scaler.Open then
											local wd = Instance.new('Weld', v)
											wd.Name = v.Name..'To'..scaler.Name..'Weld'
											wd.Part0 = v
											wd.C0 = CFrame.new()
											wd.C1 = scaler.CFrame:ToObjectSpace(v.CFrame)
											wd.Part1 = scaler
										elseif v == scaler and not scaler:FindFirstChild('Engine') then
											local wd = Instance.new('ManualWeld', v)
											wd.Name = 'Engine'
											wd.Part0 = v
											wd.C0 = CFrame.new()
											wd.C1 = v.Open.CFrame:ToObjectSpace(v.CFrame)
											wd.Part1 = v.Open
											local openv = Instance.new('CFrameValue', wd)
											openv.Name = 'Open_Pos'
											openv.Value = wd.C1
											local closev = Instance.new('CFrameValue', wd)
											closev.Name = 'Close_Pos'
											closev.Value = wd.C0
											engines[#engines+1] = wd
										elseif v == scaler.Open then
											local wd = Instance.new('Weld', v)
											wd.Name = v.Name..'To'..weldPart.Name..'Weld'
											wd.Part0 = v
											wd.C0 = CFrame.new()
											wd.C1 = weldPart.CFrame:ToObjectSpace(v.CFrame)
											wd.Part1 = weldPart
										end
									end
								end
							end
						end
					end
					v.Anchored = false
				end
			end
		end

		local outputDebugMessage = function(message, outputType, bypass)
			local prefixMessage = 'Cortex Auto Door Controller: '
			if (not config.Debug) and not bypass then return end
			if outputType == 'print' then
				print(prefixMessage..message)
			elseif outputType == 'warn' then
				warn(prefixMessage..message)
			elseif outputType == 'error' then
				error(prefixMessage..message)
			elseif outputType == 'assert' then
				assert(false, prefixMessage..message)
			end
		end

		weld(this.Doors, level)

		for i,v in pairs(this:GetChildren()) do
			if v.Name == 'SensorLight' then
				for i,g in pairs(v:GetDescendants()) do
					if g.Name == 'LED' then
						g.Color = Color3.fromRGB(0, 0, 0)
					end
				end
			end
		end

		local addSound = function(name, id, volume, pitch, looped, part)
			local sound = part:FindFirstChild(name) or Instance.new('Sound', part)
			sound.Name = name
			sound.SoundId = 'rbxassetid://'..tostring(id)
			sound.Volume = volume
			sound.RollOffMaxDistance = 100
			sound.RollOffMinDistance = 4
			sound.Looped = looped
			sound.PlaybackSpeed = pitch
			return sound
		end

		if config.Door_Sound_Loop then
			soundLoop = addSound('Door_Motor_Loop', 142724164, .13, 0, true, level)
			soundLoop:Play()
		end
		local openSound = addSound('Open_Sound', config.Open_Sound.Sound_Id, config.Open_Sound.Volume, config.Open_Sound.Pitch, false, level)
		local closeSound = addSound('Close_Sound', config.Close_Sound.Sound_Id, config.Close_Sound.Volume, config.Close_Sound.Pitch, false, level)
		local sensorBeep = addSound('Sensor_Beep', 1283290053, .7, 2.46, false, level)

		local open = function()
			if status ~= 'closed' and status ~= 'closing' then return end
			status = 'opening'
			openSound:Play()
			outputDebugMessage('Opening doors', 'print', false)
			for i,v in pairs(this:GetChildren()) do
				if v.Name == 'SensorLight' then
					for i,g in pairs(v:GetDescendants()) do
						if g.Name == 'LED' then
							coroutine.wrap(function()
								while status == 'opening' do
									g.Color = Color3.fromRGB(255, 0, 0)
									heartbeat:Wait()
								end
							end)()
						end
					end
				end
			end
			if soundLoop then
				coroutine.wrap(function()
					local tween1 = game:GetService('TweenService'):Create(soundLoop, TweenInfo.new(config.Door_Open_Speed/2.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {PlaybackSpeed = .7-(config.Door_Open_Speed/math.pi/2)})
					local tween2 = game:GetService('TweenService'):Create(soundLoop, TweenInfo.new(config.Door_Open_Speed/2.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {PlaybackSpeed = 0})
					tween1:Play()
					wait(config.Door_Open_Speed/1)
					tween2:Play()
				end)()
			end
			for i,v in pairs(engines) do
				coroutine.wrap(function()
					local lerpTime = config.Door_Open_Speed*60
					for i=1,lerpTime do
						v.C0 = v.C0:Lerp(v.Open_Pos.Value, (i*i)*delta*.012/math.rad(lerpTime*math.pi)/config.Door_Open_Speed)
						heartbeat:Wait()
						if status ~= 'opening' then return end
					end
					status = 'open'
					outputDebugMessage('Doors opened', 'print', false)
				end)()
			end
			repeat wait() until status == 'open'
		end
		local close = function()
			if status ~= 'open' then return end
			status = 'closing'
			outputDebugMessage('Closing doors', 'print', false)
			for i,v in pairs(this:GetChildren()) do
				if v.Name == 'SensorLight' then
					for i,g in pairs(v:GetDescendants()) do
						if g.Name == 'LED' then
							coroutine.wrap(function()
								while status == 'closing' do
									g.Color = Color3.fromRGB(255, 0, 0)
									wait(.15)
									if status ~= 'closing' then return end
									g.Color = Color3.fromRGB(0, 0, 0)
									wait(.15)
									if status ~= 'closing' then return end
								end
							end)()
						end
					end
				end
			end
			if soundLoop then
				coroutine.wrap(function()
					local tween1 = game:GetService('TweenService'):Create(soundLoop, TweenInfo.new(config.Door_Close_Speed/2.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {PlaybackSpeed = .7-(config.Door_Close_Speed/math.pi/2)})
					local tween2 = game:GetService('TweenService'):Create(soundLoop, TweenInfo.new(config.Door_Close_Speed/2.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {PlaybackSpeed = 0})
					tween1:Play()
					wait(config.Door_Close_Speed/1)
					tween2:Play()
				end)()
			end
			for i,v in pairs(engines) do
				coroutine.wrap(function()
					local lerpTime = config.Door_Close_Speed*60
					for i=1,lerpTime do
						v.C0 = v.C0:Lerp(v.Close_Pos.Value, (i*i)*delta*.01/math.rad(lerpTime*math.pi)/config.Door_Close_Speed)
						heartbeat:Wait()
						if status ~= 'closing' then return end
					end
					status = 'closed'
					outputDebugMessage('Doors closed', 'print', false)
				end)()
			end
			if not config.Close_Sound_After_Close then
				closeSound:Play()
			end
			repeat wait() until status == 'closed'
			if config.Close_Sound_After_Close then
				closeSound:Play()
			end
		end

		for i,v in pairs(workspace:GetDescendants()) do
			local human = v:FindFirstChildWhichIsA('Humanoid')
			if human then
				players[#players+1] = v
			end
		end
		workspace.ChildAdded:Connect(function(c)
			wait()
			if c:FindFirstChildWhichIsA('Humanoid') then
				players[#players+1] = c
			end
		end)
		workspace.ChildRemoved:Connect(function(c)
			wait()
			if c:FindFirstChildWhichIsA('Humanoid') then
				for i,v in pairs(players) do
					if v == c then
						table.remove(players, i)
					end
				end
			end
		end)

		if sensors then
			for i,v in pairs(sensors:GetChildren()) do
				if config.Sensor_Type == 'Touch' then
					v.Touched:Connect(function(hit)
						if hit.Parent:FindFirstChild('Humanoid') then
							spawn(open)
						end
					end)
				end
			end
		end

		local api = this:FindFirstChild('API') or Instance.new('BindableEvent', this)
		api.Name = 'API'
		api.Event:Connect(function(event, param1, param2)
			if event == 'Open' then
				spawn(open)
			end
			if event == 'Close' then
				spawn(close)
			end
		end)

		heartbeat:Connect(function(d)
			delta = d
			if status == 'open' then
				doorTime += .025
			else
				doorTime = 0
			end
			if doorTime >= config.Open_Time then
				doorTime = 0
				spawn(close)
			end
			if config.Sensor_Type == 'Region' then
				for i,v in pairs(sensors:GetChildren()) do
					local region = Region3.new(
						Vector3.new(
							v.Position.X - v.Size.X/2,
							v.Position.Y - v.Size.Y/2,
							v.Position.Z - v.Size.Z/2
						),
						Vector3.new(
							v.Position.X + v.Size.X/2,
							v.Position.Y + v.Size.Y/2,
							v.Position.Z + v.Size.Z/2
						)
					)
					isInSensor = #workspace:FindPartsInRegion3WithWhiteList(region, players, math.huge) > 0
					if isInSensor then
						spawn(open)
						doorTime = 0
					end
					if prevInSensor ~= isInSensor then
						prevInSensor = isInSensor
						if prevInSensor and config.Sensor_Beep then
							sensorBeep:Play()
						end
					end
				end
			end
		end)
	end))
	if not ranBool then
		assert(false, 'Cortex Auto Door Controller: Error occured in controller\nStack trace: '..debug.traceback()..'\nError Message: '..debugInfo)
	end
end