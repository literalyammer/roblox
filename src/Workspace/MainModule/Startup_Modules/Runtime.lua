--[[

	This is a demo
		
	Task: The Cortex MainModule will boot, and you can cast any errors/plugins when initiating through this module
	
	Functions:
	init_start: Starts the module only once per require cache (will only run once)
	init_core: Starts the module each time the MainModule's internal function is called

]]--

local module = {}

function module.init_start()
	local replicatedStorage = game:GetService('ReplicatedStorage')
	local CLIENT_FOLDER: Folder = replicatedStorage:FindFirstChild('CORTEX_CLIENT_INSTANCES') or Instance.new('Folder')
	CLIENT_FOLDER.Name = 'CORTEX_CLIENT_INSTANCES'
	CLIENT_FOLDER.Parent = replicatedStorage
	local RUNTIME_REMOTE_SIGNAL: RemoteEvent = CLIENT_FOLDER:FindFirstChild('RUNTIME_REMOTE_SIGNAL') or Instance.new('RemoteEvent')
	RUNTIME_REMOTE_SIGNAL.Name = 'RUNTIME_REMOTE_SIGNAL'
	RUNTIME_REMOTE_SIGNAL.Parent = CLIENT_FOLDER
	local serverDtTime = replicatedStorage:FindFirstChild('SERVER_DELTA_TIME')
	local serverDtTime = replicatedStorage:FindFirstChild('SERVER_DELTA_TIME')
	if (not serverDtTime) then
		serverDtTime = Instance.new('NumberValue')
		serverDtTime.Parent = replicatedStorage
		serverDtTime.Name = 'SERVER_DELTA_TIME'
	end
	local EVENT = Instance.new('BindableEvent')
	EVENT.Parent = script
	_G.Cortex_SERVER = _G.Cortex_SERVER or {
		EVENTS={
			RUNTIME_EVENT={
				INSTANCE=EVENT,
				EVENT=EVENT.Event
			},
		},
		DELTA_TIME=0,
	}

	local lastTick = os.clock()
	game:GetService('RunService').PreAnimation:Connect(function()
		_G.Cortex_SERVER.DELTA_TIME = os.clock()-lastTick
		lastTick = os.clock()
		serverDtTime.Value = _G.Cortex_SERVER.DELTA_TIME
		EVENT:Fire(_G.Cortex_SERVER.DELTA_TIME)
		if (#game.Players:GetChildren() > 0) then
			--RUNTIME_REMOTE_SIGNAL:FireAllClients(dtTime)
		end
	end)
end
function module.init_core()

end

return module