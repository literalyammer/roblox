local this = script.Parent
local remote = this:WaitForChild('RemoteEvent')
local ratio = this:WaitForChild('RATIO')
local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local draggableUI = require(script:WaitForChild('DraggableUI'))
local uis = game:GetService('UserInputService')
local mouse = player:GetMouse()

local doorSet = this:WaitForChild('DOOR_SET').Value or this:WaitForChild('DOOR_SET'):GetPropertyChangedSignal('Value'):Wait()

local slider,select = this.BG.Slider,this.BG.Slider.Select

local delta = Vector2.zero
local dragInput,startPos,dragStart
select.InputBegan:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1) then
		uis.MouseIcon = 'rbxasset://SystemCursors/PointingHand'
		dragInput = input
		dragStart = uis:GetMouseLocation()
		startPos = select.Position.X.Offset
		input.Changed:Connect(function()
			if (input.UserInputState == Enum.UserInputState.End) then
				dragInput = nil
				uis.MouseIcon = [[ ]]
			end
		end)
	end
end)
uis.InputChanged:Connect(function(input: InputObject)
	if (dragInput) then
		if (uis.MouseBehavior ~= Enum.MouseBehavior.Default) then
			delta += uis:GetMouseDelta()*3.5
		else
			delta = uis:GetMouseLocation()-dragStart
		end
		select.Position = UDim2.new(0, math.clamp(startPos+delta.X, 0, slider.AbsoluteSize.X), .5, 0)
	end
end)

this.BG.Top.Button.MouseButton1Down:Connect(function()
	local elevator = (doorSet:FindFirstAncestor('Car') or doorSet:FindFirstAncestor('Floors')).Parent
	if (not elevator) then return end
	elevator.Cortex_Remote:FireServer('exit',doorSet)
end)

local active = false
uis.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if (gameProcessed) then return end
	if (input.KeyCode == Enum.KeyCode.LeftControl) then
		local zoom = (camera.CFrame.Position-camera.Focus.Position).Magnitude
		player.CameraMinZoomDistance,player.CameraMaxZoomDistance = zoom,zoom
		active = true
	elseif (input.KeyCode == Enum.KeyCode.R) then
		player.CameraMinZoomDistance,player.CameraMaxZoomDistance = game.StarterPlayer.CameraMinZoomDistance,game.StarterPlayer.CameraMaxZoomDistance
		active = false
		local elevator = (doorSet:FindFirstAncestor('Car') or doorSet:FindFirstAncestor('Floors')).Parent
		if (not elevator) then return end
		elevator.Cortex_Remote:FireServer('exit',doorSet)
	end
end)
local lastTick = tick()
uis.InputChanged:Connect(function(input: InputObject)
	if (input.UserInputType == Enum.UserInputType.MouseWheel and active) then
		if (input.Position.Z == 1 or input.Position.Z == -1) then
			local t = math.clamp((tick()-lastTick),0,.2)
			lastTick = tick()
			game:GetService('TweenService'):Create(select,TweenInfo.new(t,Enum.EasingStyle.Linear,Enum.EasingDirection.Out),{Position=UDim2.fromOffset(math.clamp(select.Position.X.Offset+input.Position.Z*7.5,0,slider.AbsoluteSize.X),0)}):Play()
		end
	end
end)
uis.InputEnded:Connect(function(input: InputObject)
	if (input.KeyCode == Enum.KeyCode.LeftControl) then
		player.CameraMinZoomDistance,player.CameraMaxZoomDistance = game.StarterPlayer.CameraMinZoomDistance,game.StarterPlayer.CameraMaxZoomDistance
		active = false
	end
end)

select:GetPropertyChangedSignal('Position'):Connect(function()
	remote:FireServer('UPDATE_RATIO_VALUE',select.Position.X.Offset/slider.AbsoluteSize.X,0,1)
end)