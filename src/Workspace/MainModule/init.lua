local module = {}

--[[

	CORTEX SOURCE CODE -- 2023
	WRITTEN BY aaxtatious (540781721) & ImFirstPlace (79641334)
	DISTRIBUTION IS ALLOWED; HOWEVER, YOU MUST GIVE CREDIT TO WRITERS
	
	Module code rewrite: 08/09/2023 (aaxtatious, 540781721)
	
	© 2023 Cortex Elevator Co.

]]--

module.versionData = {
	['BETA'] = {
		['CORE'] = {
			['version'] = '10.0'
		},
	},
	['ALPHA'] = {
		['CORE'] = {
			['version'] = '9.1'
		},
	},
	['DEVELOPMENT'] = {
		['CORE'] = {
			['version'] = '9.1'
		},
	},
	['STABLE'] = {
		['CORE'] = {
			['version'] = '9.1'
		},
	},
}

local ASSET_ID = 8533575827 --// DO NOT TOUCH //--

local httpService = game:GetService('HttpService')
local dependencies = script:WaitForChild('Dependencies')
local runService = game:GetService('RunService')
local marketplaceService = game:GetService('MarketplaceService')
local insertService = game:GetService('InsertService')
local replicatedFirst = game:GetService('ReplicatedFirst')
local replicatedStorage = game:GetService('ReplicatedStorage')
local players = game:GetService('Players')
local currentAssetVersion = insertService:GetLatestAssetVersionAsync(ASSET_ID)

if (not runService:IsServer()) then return warn(`Cortex MainModule can only be ran on the server!`) end

local startupModules = script:WaitForChild('Startup_Modules')
local requiredStartupModules = {}
for i,v in pairs(startupModules:GetChildren()) do
	local ran,res = pcall(require, v)
	if (ran) then
		requiredStartupModules[v.Name] = {module=v,req=res}
		local ran,res = pcall(res.init_start)
		if (not ran) then warn(`Cortex Startup Module Error: failed to run internal function in {v.Name} :: {res}`) end
	else
		warn(`Cortex Startup Module Error :: {res}`)
	end
end

_G.Required_Elevator_Cache = _G.Required_Elevator_Cache or {}
_G.Elevator_Output_Storage_GLOBAL = _G.Elevator_Output_Storage_GLOBAL or {}
_G.CortexElevatorStorage = _G.CortexElevatorStorage or {}
_G.CORTEX_RC_WHITELIST = _G.CORTEX_RC_WHITELIST or {}

_G.Core_CurrentVersion = '6.0'
_G.TravelFiccient_CurrentVersion = '2.0'

_G.CORTEX_RC_WHITELIST = typeof(_G.CORTEX_RC_WHITELIST) == 'table' and _G.CORTEX_RC_WHITELIST or {}

local function keyClient(player: Player)
	--task.spawn(function()
	--	task.wait()
	--	local playerGui = player:WaitForChild('PlayerGui')
	--	local gui = player:FindFirstChild('KEY_SWITCH_HANDLERS')
	--	if (not gui) then
	--		gui = Instance.new('ScreenGui')
	--		gui.Name = 'KEY_SWITCH_HANDLERS'
	--		gui.ResetOnSpawn = false
	--		local src = dependencies.KEY_CLIENT_CONTROL:Clone()
	--		src.Parent = gui
	--		gui.Parent = playerGui
	--	end
	--end)
end

local function rcPlayerGui(player: Player)
	task.spawn(function()
		task.wait()
		local playerGui = player:FindFirstChild('PlayerGui')
		if (not _G.CORTEX_RC_WHITELIST[tostring(player.UserId)]) then return end
		local gui = playerGui:FindFirstChild('ELEVATOR_GUI')
		if (not gui) then
			gui = dependencies:WaitForChild('ELEVATOR_GUI'):Clone()
			gui.IgnoreGuiInset = true
			gui.ResetOnSpawn = false
			gui.Enabled = true
			gui.Parent = playerGui
		end
	end)
end
players.PlayerAdded:Connect(rcPlayerGui)
for _,v in pairs(players:GetChildren()) do
	rcPlayerGui(v)
end

local REMOTECONTROLS_API = game.ReplicatedStorage:FindFirstChild('CORTEX_RC_REMOTE') or Instance.new('RemoteFunction', game.ReplicatedStorage)
REMOTECONTROLS_API.Name = 'CORTEX_RC_REMOTE'
function REMOTECONTROLS_API.OnServerInvoke(USER, ELEVATOR, PARAMS)
	if (not _G.CORTEX_RC_WHITELIST[tostring(USER.UserId)]) then return end
	ELEVATOR.Cortex_API:Fire(unpack(PARAMS))
end

local globalRemote = game.ReplicatedStorage:FindFirstChild('Coretex_Remote_GLOBAL')
if (not globalRemote) then
	globalRemote = Instance.new('RemoteEvent')
	globalRemote.Name = 'Cortex_Remote_GLOBAL'
	globalRemote.Parent = game.ReplicatedStorage
end
local remoteSignal = replicatedStorage:FindFirstChild('Cortex_Remote_Signal')
if (not remoteSignal) then
	remoteSignal = Instance.new('RemoteFunction')
	remoteSignal.Name = 'Cortex_Remote_Signal'
	remoteSignal.Parent = replicatedStorage
	function remoteSignal.OnServerInvoke(user, protocol, params)
		if (protocol == 'GET_PLAYER_WELDS') then
			local signal = params:FindFirstChild('Cortex_Signal')
			if (not signal) then return end
			return signal:Invoke('GET_ELEVATOR_WELDS')
		end
	end
end

local function createErrorMsg(title: string, message: string, player: Player?)
	local function addGui(append: Instance)
		local newGui = dependencies.ErrorMsg:Clone()
		newGui.Parent = append
		newGui.Enabled = true
		newGui.Frame.Title.Text = title
		newGui.Frame.Message.Text = message
		newGui.Frame.Position = UDim2.fromOffset(0,-newGui.Frame.AbsoluteSize.Y)
		game:GetService('TweenService'):Create(newGui.Frame,TweenInfo.new(.15,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Position=UDim2.fromScale(.5,0)}):Play()
		local tween = game:GetService('TweenService'):Create(newGui.Frame.Status,TweenInfo.new(7,Enum.EasingStyle.Linear,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(0,newGui.Frame.Status.AbsoluteSize.Y)})
		tween:Play()
		tween.Completed:Wait()
		local tween = game:GetService('TweenService'):Create(newGui.Frame,TweenInfo.new(.1,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Position=UDim2.fromOffset(0,-newGui.Frame.AbsoluteSize.Y)+UDim2.fromScale(.5,0)})
		tween:Play()
		tween.Completed:Wait()
		newGui:Destroy()
	end
	if (runService:IsRunMode()) then
		local starterGui = game:GetService('StarterGui')
		starterGui.ShowDevelopmentGui = true
		local newGui = starterGui:FindFirstChild(dependencies.ErrorMsg.Name)
		if (not newGui) then
			task.spawn(addGui, starterGui)
		end
	else
		for i,v in pairs(game.Players:GetChildren()) do
			if (v == player or (not player)) then
				local newGui = v.PlayerGui:FindFirstChild(dependencies.ErrorMsg.Name)
				if (not newGui) then
					task.spawn(addGui, v.PlayerGui)
				end
			end
		end
	end
end

task.spawn(function()
	while true do
		task.wait(60)
		local webVersion = insertService:GetLatestAssetVersionAsync(ASSET_ID)
		if (webVersion ~= currentAssetVersion) then
			currentAssetVersion = webVersion
			--createErrorMsg(`New Cortex MainModule Version Available`, `A new version of the Cortex MainModule is available; please restart your server for update(s) to apply.\nv{webVersion}`)
			print(string.format([[
				----------------------
				>>>>>>>>>> %s <<<<<<<<<<<<
				NEW CORTEX MAINMODULE VERSION AVAILABLE
				A new version of the Cortex MainModule is available; new version will apply after server restarts.
				----------------------
			]], webVersion))
		end
	end
end)

return function(source, config, initProtocol, versionData)
	task.spawn(function()
		for i,v in pairs(requiredStartupModules) do
			local ran,res = pcall(v.req.init_core)
			if (not ran) then warn(`Cortex Startup Module Error: failed to run internal function on initiate in module {v.module.Name} :: {res}`) end
		end
	end)

	versionData = { ['BUILD'] = if (typeof(versionData) == 'table') then versionData.BUILD else 'STABLE' }
	if (versionData.BUILD == 'DEVELOPMENT') then versionData.BUILD = 'BETA' end
	local moduleTree = script.Modules:FindFirstChild(versionData.BUILD)
	if (not moduleTree) then moduleTree = script.Modules.STABLE; versionData.BUILD = 'STABLE'; warn(`Cortex MainModule Initiator - Elevator model {source.Parent.Name} :: Build {versionData.BUILD} not found! Falling back to the STABLE build`) end
	if (initProtocol == 'Core') then
		local uniqueID = source:GetAttribute('UniqueID') or `CortexElevator_{httpService:GenerateGUID(false)}`
		local moduleCache = _G.Required_Elevator_Cache[uniqueID]
		local car,floors = source.Parent:FindFirstChild('Car'),source.Parent:FindFirstChild('Floors')
		if ((not car) or (not floors)) then return error(string.format('CORTEX CLASSIC %s :: INITIATION FATAL ERROR - INITIATED MODEL IS NOT source VALID ELEVATOR MODEL TO INITIATE THE \'CORE\' MODULE', _G['Core_CurrentVersion'])) end
		if (not moduleCache) then
			_G.Required_Elevator_Cache[uniqueID] = moduleTree.Core:Clone()
			moduleCache = _G.Required_Elevator_Cache[uniqueID]
		end
		local ran,res = pcall(require, moduleCache)
		if (not ran) then task.spawn(createErrorMsg, `{(module.versionData[versionData.BUILD] or module.versionData.STABLE).CORE.version} Initiation Error`, res) return error(`Cortex MainModule :: ERROR ENCOUNTERED WHILST RUNNING {string.upper(initProtocol)} ---- {res}`) end
		ran,res = pcall(res.Start, source, config, {['BUILD']=versionData.BUILD,['VERSION']=(module.versionData[versionData.BUILD] or module.versionData.STABLE).CORE.version}, dependencies)
		if (not ran) then task.spawn(createErrorMsg, `{(module.versionData[versionData.BUILD] or module.versionData.STABLE).CORE.version} Initiation Error`, res) return error(`Cortex MainModule :: ERROR ENCOUNTERED WHILST RUNNING {string.upper(initProtocol)} ---- {res}`) end
	elseif (initProtocol == 'TravelFiccient') then
		local panels = source.Parent:FindFirstChild('Panels')
		if (not panels) then return error(string.format('CORTEX TRAVELFICCIENT %s :: INITIATION FATAL ERROR - INITIATED MODEL IS NOT source VALID TRAVELFICCIENT BANK MODEL TO INITIATE THE \'TRAVELFICCIENT\' MODULE', _G['TravelFiccient_CurrentVersion'])) end
		for i,v in pairs(panels:GetDescendants()) do
			if (v.Name == 'Panel') then
				local ran,res = pcall(require, moduleTree.TravelFiccient:Clone())
				ran,res = pcall(res, v, config, moduleTree.Core.Voice_Module)
				if (not ran) then return error(`Cortex MainModule :: ERROR ENCOUNTERED WHILST RUNNING {string.upper(initProtocol)} ---- {res}`) end
			end
		end
	elseif (initProtocol == 'Multi_Bay') then
		local callButtons = source.Parent:FindFirstChild('Call_Buttons')
		if (not callButtons) then return error('CORTEX MULTIBAY :: INITIATION FATAL ERROR - INITIATED MODEL IS NOT source VALID MULTIBAY BANK MODEL TO INITIATE THE \'MULTIBAY\' MODULE') end
		require(moduleTree.Multi_Bay:Clone())(source)
	elseif (config == 'Auto_Door') then
		require(moduleTree.Auto_Door_Controller:Clone())(source)
	elseif (initProtocol == 'Security_Guard') then
		require(moduleTree.Security_Guard_AI:Clone())(source, config)
	end

end