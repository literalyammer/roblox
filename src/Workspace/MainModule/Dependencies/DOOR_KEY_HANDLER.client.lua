repeat task.wait() until game:IsLoaded()
local this = script.Parent
local player = game.Players.LocalPlayer
local uis = game:GetService('UserInputService')
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera
uis.MouseIconEnabled = true
local icon = uis.MouseIcon

local runService = game:GetService('RunService')

local mouseIcon = 6479191129

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

local function findAncestor(origin: Instance, name: string)
	if (not origin) then return end
	local result = origin.Parent
	if (not result) then return end
	result = result:FindFirstChild(name)
	if (result) then return result end
	return findAncestor(origin.Parent, name)
end

local function containsDropKey()
	local char = player.Character
	if (not char) then return end
	for i,v in pairs(char:GetChildren()) do
		if (v.Name == 'Drop Key' or v:GetAttribute('CortexDoorKey')) then
			return v
		end
	end
	return
end

local scaler,lastKeyCheckStatus
runService:BindToRenderStep('DROP_KEY_CLIENT_UPDATE', Enum.RenderPriority.First.Value, function()
	local char = player.Character
	local hasDoorKey = containsDropKey()
	if (not char) then return end
	params.FilterDescendantsInstances = {char}
	local mousePos = uis:GetMouseLocation()
	local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y, 0)
	local result = workspace:Raycast(camera.CFrame.Position, ray.Direction*10, params)
	scaler = findAncestor(result and result.Instance, 'Scaler')
	local keyStatusCheck = scaler and hasDoorKey
	if (lastKeyCheckStatus ~= keyStatusCheck) then
		lastKeyCheckStatus = keyStatusCheck
		uis.MouseIcon = keyStatusCheck and `rbxassetid://{mouseIcon}` or icon
	end
end)

uis.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if (gameProcessed) then return end
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		local cortexRemote = findAncestor(scaler, 'Cortex_Remote')
		if (not cortexRemote) then return end
		local elevator = cortexRemote.Parent
		local oldDropKey = require(elevator.Settings).Doors.Use_Old_Drop_Key
		cortexRemote:FireServer(oldDropKey and 'dropKeyToggle' or 'addDropKeyGuiToPlayer', scaler.Parent.Parent)
	end
end)