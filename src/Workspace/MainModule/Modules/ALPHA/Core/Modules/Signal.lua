local HttpsService = game:GetService("HttpService")

local Signal = {}
Signal.__index = Signal

function Signal:INITIATE_PLUGIN_INTERNAL(CORE, SOURCE) end --SILENCES INITIATION ERRORS

local function IsFunction(func)
	if typeof(func) ~= "function" then
		error(string.format("invalid argument #1 (function expected got %s)", typeof(func)))
	end
end

function Signal.new()
	return setmetatable({
		_connections = {},
	}, Signal)
end

function Signal:Once(func)
	IsFunction(func)

	local once = nil

	once = self:Connect(function(...)
		once:Disconnect()

		func(...)
	end)

	return once
end

function Signal:Connect(func)
	IsFunction(func)

	local connection = {
		_name = HttpsService:GenerateGUID(),
		_func = func,
		_connected = true,
	}

	self._connections[connection._name] = connection

	function connection:Disconnect()
		connection._connected = false
	end

	connection.disconnect = connection.Disconnect

	return connection
end

function Signal:Wait()
	local yield = coroutine.running()

	self:Once(function(...)
		task.spawn(yield, ...)
	end)

	return coroutine.yield()
end

function Signal:Fire(...: any)
	for i, connection in pairs(self._connections) do
		if connection._connected then
			IsFunction(connection._func)
			
			task.spawn(connection._func, ...)
		else
			local index = table.find(self._connections, connection._name)

			table.remove(self._connections, index)
		end
	end
end

function Signal:Destroy()
	for i, connection in pairs(self._connections) do
		connection:Disconnect()
	end
	
	self._connections = {}
end

Signal.New = Signal.new
Signal.connect = Signal.Connect
Signal.wait = Signal.Wait
Signal.fire = Signal.Fire
Signal.once = Signal.Once
Signal.destroy = Signal.Destroy

return Signal