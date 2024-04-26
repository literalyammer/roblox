repeat wait() until game.Players.LocalPlayer
local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

local Run_Service = game:GetService('RunService')
local Keys = {'Hoistway Access Key', 'Fire Service Key', 'Inspection Key', 'Logic Cabinet Key'}
local Mouse = Player:GetMouse()
local Key_Insert_Limit = false
local Target,Key_API,Hit_Target
local userInputService = game:GetService('UserInputService')

local hoverMouseCursor = 'rbxassetid://5487704161'
local mouseCursor = userInputService.MouseIcon

local function findKeyToolInCharacter(findName)

	local result;
	if (Character) then

		for i,v in pairs(Character:GetChildren()) do
			if (v.Name:match(findName) and v:IsA('Tool')) then
				result = v;
				break;
			end
		end

	end
	return result;

end

local lastCheckBool
Run_Service.RenderStepped:Connect(function()
	Target = Mouse.Target
	local isKey = false
	local foundKey = findKeyToolInCharacter('Key');
	if (Target and foundKey) then
		Key_API = (Target.Parent:FindFirstChild('Key_API') or Target.Parent:FindFirstChild('KEYSWITCH_API'))
		Hit_Target = Target.Parent:FindFirstChild('Rotate')
	end
	local thisCheckBool = isKey and Target and foundKey and Key_API and (not Key_Insert_Limit) and Hit_Target
	if (thisCheckBool ~= lastCheckBool) then
		userInputService.MouseIcon = thisCheckBool and hoverMouseCursor or mouseCursor
	end
	lastCheckBool = thisCheckBool
end)

Mouse.Button1Down:Connect(function()
	local foundKey = findKeyToolInCharacter('Key');
	if ((not Key_Insert_Limit) and Key_API and Hit_Target and foundKey) then
		Key_Insert_Limit = true
		local success = pcall(function()
			Key_API:InvokeServer('Activate_Key', foundKey)
		end)
		Key_Insert_Limit = false
	end
end)