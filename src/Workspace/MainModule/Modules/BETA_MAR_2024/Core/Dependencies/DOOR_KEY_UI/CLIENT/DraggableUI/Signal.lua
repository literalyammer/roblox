local Signal = {}
Signal.__index = Signal
Signal.__tostring = function()
	return "Signal"
end

Signal.Event = {} :: {
	Connect: (self: { RBXScriptSignal }) -> RBXScriptConnection,
	Once: (self: { RBXScriptSignal }) -> RBXScriptConnection,
	Wait: (self: { RBXScriptSignal }) -> ...any,
}
Signal.Event.__index = Signal.Event
Signal.Event.__tostring = function()
	return "Event"
end

local Connection = {}
Connection.__index = Connection
Connection.__tostring = function()
	return "Connection"
end

local function DisableTableIndex(Table: {})
	setmetatable(Table, {
		__index = function(_, key)
			error(("Attempt to get Connection::%s (not a valid member)"):format(tostring(key)), 2)
		end,

		__newindex = function(_, key)
			error(("Attempt to set Connection::%s (not a valid member)"):format(tostring(key)), 2)
		end,
	})
end

Connection.__eq = function(self, other)
	return self._Handler == other._Handler
end

function Connection.new(Parent: {}, Handler: any): RBXScriptConnection
	return setmetatable({
		_Handler = Handler,
		_Parent = Parent,
	}, Connection)
end

function Connection:Disconnect()
	local Position = table.find(self._Parent, self)

	if Position then
		table.remove(self._Parent, Position)
	end
end

function Connection:_Fire(...)
	self._Handler(...)
end

function Signal.new()
	return setmetatable({}, Signal)
end

function Signal.Event:Connect(Handler: any): RBXScriptConnection
	local self: RBXScriptConnection = self
	local _Connection = Connection.new(self, Handler)

	table.insert(self, _Connection)

	return _Connection
end

function Signal.Event:Once(Handler: any): RBXScriptConnection
	local self: RBXScriptConnection = self

	local Fired = false
	local Connection

	Connection = self:Connect(function(...)
		if Fired then
			return
		end

		Fired = true
		Connection:Disconnect()
		Handler(...)
	end)

	return Connection
end

function Signal.Event:Wait(): ...any
	local self: RBXScriptConnection = self

	local Result = coroutine.running()
	local Fired = false
	local Connection

	Connection = self:Connect(function(...)
		if Fired then
			return
		end

		Fired = true
		Connection:Disconnect()
		task.spawn(Result, ...)
	end)

	return coroutine.yield()
end

function Signal:DisconnectAll()
	local self: RBXScriptConnection = self

	for _, Handler in ipairs(self.Event) do
		coroutine.wrap(Handler.Disconnect)(Handler)
	end
end

function Signal:Fire(...: any)
	local self: RBXScriptConnection = self
	local args = { ... }

	for _, Handler in ipairs(self.Event) do
		coroutine.wrap(Handler._Fire)(Handler, unpack(args))
	end
end

function Signal:Destroy()
	local self: RBXScriptConnection = self

	self:DisconnectAll()
	table.clear(self)
end

DisableTableIndex(Signal)
DisableTableIndex(Connection)
DisableTableIndex(Signal.Event)

export type Event = {
	Connect: (self: { Event }, func: (...any) -> ()) -> RBXScriptConnection,
	Once: (self: { Event }, func: (...any) -> ()) -> RBXScriptConnection,
	Wait: (self: { Event }) -> ...any,
}

export type Signal = {
	new: (
	) -> {
		Event: Event,
		Destroy: (self: { Signal }) -> (),
		Fire: (self: { Signal }, ...any) -> (),
		DisconnectAll: (self: { Signal }) -> (),
	},
}

return Signal :: Signal
