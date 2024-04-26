local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local tweenService = game:GetService('TweenService')

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Whitelist
local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Whitelist
local elevators = {}
local raycastDistance = 30

player.CharacterAdded:Connect(function(char)
	character = char
end)

local data = {
	['enabled'] = {0,0,0},
	['disabled'] = {-80,10,-25},
}

game:GetService('RunService'):BindToRenderStep('cortexAudioHandlerUpdate', Enum.RenderPriority.Camera.Value+1, function()
	if (not character) then return end
	local root = character:FindFirstChild('HumanoidRootPart')
	if (not root) then return end
	params.FilterDescendantsInstances = elevators
	overlapParams.FilterDescendantsInstances = {root}
	for i,elevator in next,elevators do
		local function processFar(target: Part, soundGroup: SoundGroup)
			local distance = math.clamp((target.Position-root.Position).Magnitude/raycastDistance, 0, 1)
			local result = workspace:Raycast(root.Position, (target.Position-root.Position).Unit*raycastDistance, params)
			local isEnabled = (result and result.Instance == target) or #workspace:GetPartBoundsInBox(target.CFrame, target.Size, overlapParams) > 0
			tweenService:Create(soundGroup.Muffler, TweenInfo.new(.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {HighGain=isEnabled and data.enabled[1] or data.disabled[1]*distance,LowGain=isEnabled and data.enabled[2] or data.disabled[2]*distance,MidGain=isEnabled and data.enabled[3] or data.disabled[3]*distance}):Play()
		end
		if (not elevator.Car:FindFirstChild('Cab_Region')) then return end
		processFar(elevator.Car.Cab_Region, elevator.Car.Cab_Region.SoundGroup)
	end
end)

task.wait()
local function checkElevator(elev)
	if ((not elev) or (not elev:FindFirstChild('Cortex_API') or (not elev:FindFirstChild('Car') or table.find(elevators, elev)))) then return end
	table.insert(elevators, elev)
end
for i,v in next,workspace:GetDescendants() do
	checkElevator(v)
end
workspace.DescendantAdded:Connect(checkElevator)
workspace.DescendantRemoving:Connect(function(elev)
	task.wait()
	local index = table.find(elevators, elev)
	if (not index) then return end
	table.remove(elevators, index)
end)