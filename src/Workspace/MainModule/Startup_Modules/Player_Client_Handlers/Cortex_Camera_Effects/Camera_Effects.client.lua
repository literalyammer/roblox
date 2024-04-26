local runService = game:GetService('RunService')

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local runThread

local function handle(char)
	task.wait()
	local camera = workspace.CurrentCamera
	
	local function startupAnimation(direction: number, config)
		if ((not config) or (not config.Enable)) then return end
		local function lerp(a, b, t)
			return a+(b-a)*t
		end
		local startTime = tick()
		while ((tick()-startTime)/config.Duration < 1) do
			local dtTime = runService.RenderStepped:Wait()
			local s = math.cos((tick()-startTime)/config.Duration*5.5)*config.Amplitude*lerp(1, 0, (tick()-startTime)/config.Duration/1.45)*math.deg(dtTime)
			camera.CFrame = camera.CFrame:Lerp(camera.CFrame*CFrame.Angles(-direction*math.rad(s), 0, 0), .45)
		end
	end
	
	local root = char:WaitForChild('HumanoidRootPart')
	root.ChildAdded:Connect(function(child: any)
		if (child.Name ~= 'Cortex_Elevator_Weld') then return end
		local elevator = child.Part1.Parent.Parent
		local settings = require(elevator:WaitForChild('Settings'))
		local velocity = elevator:WaitForChild('Legacy'):WaitForChild('Velocity')
		local moveValue = elevator:WaitForChild('Legacy'):WaitForChild('Move_Value')
		local topSpeed = settings.Movement.Travel_Speed
		
		local connection: RBXScriptConnection
		connection = velocity:GetPropertyChangedSignal('Value'):Connect(function()
			if (math.abs(velocity.Value) <= 0) then return end
			connection:Disconnect()
			local joltConfig = typeof(settings.Camera_Effects) == 'table' and settings.Camera_Effects[`Jolt_{moveValue.Value == 1 and 'Up' or moveValue.Value == -1 and 'Down' or nil}`]
			local travelEffects = typeof(settings.Camera_Effects) == 'table' and settings.Camera_Effects.Movement_Effects
			task.spawn(startupAnimation, moveValue.Value, joltConfig)


			local startTime = tick()
			camera.CameraType = Enum.CameraType.Follow

			runThread = task.spawn(function()
				if ((not travelEffects) or (not travelEffects.Enable)) then return end
				local swayFrequency = travelEffects.Frequency
				local sAmplitude = travelEffects.Amplitude
				while (math.abs(velocity.Value) > 0) do
					runService.RenderStepped:Wait()

					local t = 1.5+math.cos(tick()*swayFrequency)/2
					local swayAmplitude = sAmplitude*velocity.Value/topSpeed
					local xNoise = math.noise(t)
					local yNoise = math.noise(0, t)

					local xSway = math.sin(xNoise*.05*15/.025)*swayAmplitude
					local ySway = math.cos(yNoise*.05*15/.025)*swayAmplitude

					camera.CFrame = camera.CFrame:Lerp(camera.CFrame*CFrame.Angles(math.rad(xSway), math.rad(ySway), 0), .25)
				end
			end)
		end)
	end)
	root.ChildRemoved:Connect(function(child: any)
		task.wait()
		if (child.Name ~= 'Cortex_Elevator_Weld' or (not runThread)) then return end
		task.cancel(runThread)
		runThread = nil
	end)
end

handle(character)

player.CharacterAdded:Connect(handle)