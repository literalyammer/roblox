--[[

	!! UPDATE 09/26/2023 !!
	FIXED MAJOR MEMORY LEAK ISSUE WITH REMOTE/BINDABLE
	EVENTS BEING FIRED EVERY RENDERSTEPPED FRAME

]]--

_G.ButtonHandlerRunning = if (typeof(_G.ButtonHandlerRunning) == 'boolean') then _G.ButtonHandlerRunning else false --// Prevents multiple handlers from running at once in the same server

return function()

	if (_G.ButtonHandlerRunning) then return end
	_G.ButtonHandlerRunning = true

	local runService = game:GetService('RunService')
	local collectionService = game:GetService('CollectionService')
	local userInputService = game:GetService('UserInputService')
	local VRService = game:GetService('VRService')

	local player = game.Players.LocalPlayer
	local mouse
	if (player) then mouse = player:GetMouse() if (not player.Character) then player.CharacterAdded:Wait() end end
	local camera = workspace.CurrentCamera

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	local mouseIcon = userInputService.MouseIcon

	local distance = 15

	local function findAncestor(start: any, name: string)
		if (typeof(start) ~= 'Instance') then return end
		local result = start:FindFirstChild(name)
		if (result) then
			return result
		else
			return findAncestor(start.Parent, name)
		end
	end

	--// Updated handler to utilise if-then checks instead of returns //--
	local function checkInputEnter(input: InputObject)
		return (
			input.UserInputType == Enum.UserInputType.MouseButton1 or
				input.UserInputType == Enum.UserInputType.MouseMovement or
				input.UserInputType == Enum.UserInputType.Touch or
				input.KeyCode == Enum.KeyCode.ButtonR2 or
				input.KeyCode == Enum.KeyCode.ButtonX or
				input.UserInputType == Enum.UserInputType.Gamepad1
		)
	end

	local currentTarget = { target = nil, api = nil, remote = nil } -- Button target
	local isMouseDown = false
	local lastPressedTime = os.clock()
	local lastCheck = false

	local function handleInput(input: InputObject, gameProcessed: boolean)
		if (not checkInputEnter(input)) then return end
		if (input.UserInputState == Enum.UserInputState.Begin or ((not currentTarget.target) and (userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or userInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonR2) or userInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonX)))) then
			params.FilterDescendantsInstances = player and {player.Character} or {}
			local pos = mouse and { ['X'] = mouse.X, ['Y'] = mouse.Y } or input.Position
			if (VRService.VREnabled) then
				pos = input.Position
			end
			local worldPosition = camera:ScreenPointToRay(pos.X, pos.Y, 10)
			local result = workspace:Raycast(camera.CFrame.Position, worldPosition.Direction*distance, params)
			local target = result and result.Instance
			local buttonCheck = target and target:GetAttribute('isACortexElevButton')
			local api,remote = findAncestor(target, 'Cortex_API') or findAncestor(target, 'Button_API'),findAncestor(target, 'Cortex_Remote') or findAncestor(target, 'Button_Remote')
			if ((not buttonCheck) or (not api) or (not remote) or (target.CFrame.Position-camera.CFrame.Position).Magnitude > distance) then return end
			currentTarget = { target = target, api = api, remote = remote }
			if (not currentTarget.target) then return end
			isMouseDown = true
			local info = {'onButtonPressed', {['button'] = target.Parent}}
			if ((os.clock()-lastPressedTime) <= .1) then return end
			lastPressedTime = os.clock()
			if (player) then
				remote:FireServer(unpack(info))
			else
				api:Fire(unpack(info))
			end
		else
			local lastTarget = currentTarget
			local lastMouseState = isMouseDown
			if (input.UserInputState == Enum.UserInputState.Change) then
				params.FilterDescendantsInstances = player and {player.Character} or {}
				local pos = mouse and { ['X'] = mouse.X, ['Y'] = mouse.Y } or input.Position
				local worldPosition = camera:ScreenPointToRay(pos.X, pos.Y, 10)
				local result = workspace:Raycast(camera.CFrame.Position, worldPosition.Direction*distance, params)
				local target = result and result.Instance
				local buttonCheck = target and target:GetAttribute('isACortexElevButton')
				local api,remote = findAncestor(target, 'Cortex_API') or findAncestor(target, 'Button_API'),findAncestor(target, 'Cortex_Remote') or findAncestor(target, 'Button_Remote')
				local check = buttonCheck and api and remote and (target.CFrame.Position-camera.CFrame.Position).Magnitude <= distance

				local inputType = string.match(input.UserInputType.Name, 'Mouse') and 'KeyboardMouse' or userInputService.GamepadEnabled and 'Gamepad' or 'KeyboardMouse'
				local cursorName = string.match(input.UserInputType.Name, 'Mouse') and 'ArrowCursor' or userInputService.GamepadEnabled and 'PointerOver' or 'ArrowCursor'
				if (lastCheck ~= check) then
					userInputService.MouseIcon = check and `rbxasset://textures/Cursors/{inputType}/{cursorName}.png` or mouseIcon
					lastCheck = check
				end
				currentTarget = { target = check and target, api = api, remote = remote }
			elseif (input.UserInputState == Enum.UserInputState.End) then
				isMouseDown = false
			end
			if not ((((currentTarget.target ~= lastTarget.target and lastMouseState) and input.UserInputState == Enum.UserInputState.Change) or input.UserInputState == Enum.UserInputState.End) and lastTarget.target) then return end
			local info = {'onButtonReleased', {['button'] = lastTarget.target.Parent}}
			if (player) then
				lastTarget.remote:FireServer(unpack(info))
			else
				lastTarget.api:Fire(unpack(info))
			end
			currentTarget = { target = nil, api = nil, remote = nil } -- // Reset the button target if mouse has left the button
		end
	end
	userInputService.InputBegan:Connect(handleInput)
	userInputService.InputChanged:Connect(handleInput)
	userInputService.InputEnded:Connect(handleInput)

end