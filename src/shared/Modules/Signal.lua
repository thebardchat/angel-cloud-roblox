--[[
	Signal.lua — Lightweight custom event/signal implementation
	ModuleScript → ReplicatedStorage.Shared.Signal

	Usage:
		local Signal = require(ReplicatedStorage.Shared.Signal)
		local onDamage = Signal.new()
		local conn = onDamage:Connect(function(amount) print("Took", amount, "damage") end)
		onDamage:Fire(25)
		conn:Disconnect()

	Features:
		- :Connect(fn) returns a connection with :Disconnect()
		- :Once(fn) auto-disconnects after first fire
		- :Fire(...) calls all connected handlers
		- :Wait() yields until next fire, returns args
		- :DisconnectAll() removes all connections
		- :Destroy() cleans up completely

	Based on GoodSignal pattern (MIT licensed, battle-tested in production Roblox games)
]]

local Signal = {}
Signal.__index = Signal

type Connection = {
	Disconnect: (self: Connection) -> (),
	Connected: boolean,
}

type SignalType = {
	Connect: (self: SignalType, fn: (...any) -> ()) -> Connection,
	Once: (self: SignalType, fn: (...any) -> ()) -> Connection,
	Fire: (self: SignalType, ...any) -> (),
	Wait: (self: SignalType) -> ...any,
	DisconnectAll: (self: SignalType) -> (),
	Destroy: (self: SignalType) -> (),
}

local Connection = {}
Connection.__index = Connection

function Connection.new(signal, fn)
	return setmetatable({
		_signal = signal,
		_fn = fn,
		Connected = true,
	}, Connection)
end

function Connection:Disconnect()
	if not self.Connected then
		return
	end
	self.Connected = false

	local connections = self._signal._connections
	for i, conn in connections do
		if conn == self then
			table.remove(connections, i)
			break
		end
	end
end

function Signal.new(): SignalType
	return setmetatable({
		_connections = {},
		_waiting = {},
	}, Signal)
end

function Signal:Connect(fn: (...any) -> ()): Connection
	local conn = Connection.new(self, fn)
	table.insert(self._connections, conn)
	return conn
end

function Signal:Once(fn: (...any) -> ()): Connection
	local conn
	conn = self:Connect(function(...)
		if conn.Connected then
			conn:Disconnect()
		end
		fn(...)
	end)
	return conn
end

function Signal:Fire(...)
	-- Fire to all connected handlers
	for _, conn in self._connections do
		if conn.Connected then
			task.spawn(conn._fn, ...)
		end
	end

	-- Resume any waiting threads
	for _, thread in self._waiting do
		task.spawn(thread, ...)
	end
	table.clear(self._waiting)
end

function Signal:Wait(): ...any
	table.insert(self._waiting, coroutine.running())
	return coroutine.yield()
end

function Signal:DisconnectAll()
	for _, conn in self._connections do
		conn.Connected = false
	end
	table.clear(self._connections)
	table.clear(self._waiting)
end

function Signal:Destroy()
	self:DisconnectAll()
	setmetatable(self, nil)
end

return Signal