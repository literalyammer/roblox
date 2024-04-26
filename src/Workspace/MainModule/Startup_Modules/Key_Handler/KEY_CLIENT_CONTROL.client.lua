local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

local camera = workspace.CurrentCamera

local userInputService = game:GetService('UserInputService')

local Keys = {'Hoistway Access Key', 'Fire Service Key', 'Inspection Key', 'Logic Cabinet Key'}
local Mouse = Player:GetMouse()
local Key_Insert_Limit = false
local Target,Key_API,Hit_Target

local hoverMouseCursor = 'rbxassetid://14984615391'
local mouseCursor = userInputService.MouseIcon

local function findKeyToolInCharacter(findName)
	if (not Character) then return end
	for i,v in pairs(Character:GetChildren()) do
		if ((table.find(Keys, v.Name) or v:GetAttribute('isACortexKey')) and v:IsA('Tool')) then
			return v
		end
	end
	return nil
end

local lastCheckBool

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

local distance = 10

local function raycast(position: Vector3)
	params.FilterDescendantsInstances = {Player.Character}
	local worldPosition = camera:ScreenPointToRay(position.X, position.Y, distance)
	local result = workspace:Raycast(camera.CFrame.Position, worldPosition.Direction*distance, params)
	return result and result.Instance
end

local function registerTarget(input: InputObject)
	Target = raycast(input.Position)
	local foundKey = findKeyToolInCharacter('Key')
	if (Target and foundKey) then
		Key_API = (Target.Parent:FindFirstChild('Key_API') or Target.Parent:FindFirstChild('KEYSWITCH_API'))
		Hit_Target = Target.Parent:FindFirstChild('Rotate', true)
	end
	return foundKey
end

userInputService.InputChanged:Connect(function(input: InputObject, gameProcessedEvent: boolean)
	if (gameProcessedEvent or (input.UserInputType ~= Enum.UserInputType.MouseMovement)) then return end
	local foundKey = registerTarget(input)
	local thisCheckBool = Target and foundKey and Key_API and (not Key_Insert_Limit) and Hit_Target
	if (thisCheckBool ~= lastCheckBool) then
		userInputService.MouseIcon = thisCheckBool and hoverMouseCursor or mouseCursor
	end
	lastCheckBool = thisCheckBool
end)

userInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
	if (gameProcessedEvent or (input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch)) then return end
	local foundKey = registerTarget(input)
	if ((not Key_Insert_Limit) and Key_API and Hit_Target and foundKey) then
		Key_Insert_Limit = true
		local success = pcall(function()
			Key_API:InvokeServer('Activate_Key', foundKey)
		end)
		Key_Insert_Limit = false
	end
end)