-- SilentsReplacement
-- Signal
-- July 13, 2021

--[[
	Signal.new() --> Signal []
	Signal.IsSignal(self : any) --> boolean [IsSignal]

	-- Only when accessed from an object returned by Signal.new:

	Signal.ConnectedConnectionCount : number
	Signal.ConnectionListHead : function | nli

	Signal:Connect(callBack : function) --> Connection []
	Signal:Fire(tuple : any) --> nil []
	Signal:DeferredFire(tuple : any) --> nil []
	Signal:Wait() --> any [tuple]
	Signal:WaitUntilArgumentsPassed(tuple : any) --> any [tuple]
    Signal:DisconnectAllConnections() --> nil []
	Signal:Destroy() -->  nil []
	Signal:IsDestroyed() --> boolean [IsDestroyed]
]]

local Signal = {
	_freeRunnerThread = nil,
}
Signal.__index = Signal

local Connection = require(script.Connection)

local LocalConstants = {
	MinArgumentCount = 1,
	Methods = {
		AlwaysAvailable = {
			"IsDestroyed",
		},
	},

	ErrorMessages = {
		InvalidArgument = "Invalid argument#%d to %s: expected %s, got %s",
	},
}

function Signal.IsSignal(self)
	return typeof(self) == "table" and self._isSignal
end

function Signal.new()
	return setmetatable({
		ConnectedConnectionCount = 0,
		ConnectionListHead = nil,
		_isDestroyed = false,
		_isSignal = true,
	}, Signal)
end

function Signal:Connect(callBack)
	assert(
		typeof(callBack) == "function",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Signal:Connect",
			"function",
			typeof(callBack)
		)
	)

	local connection = Connection.new(self, callBack)

	if self.ConnectionListHead ~= nil then
		connection.Next = self.ConnectionListHead
		self.ConnectionListHead = connection
	else
		self.ConnectionListHead = connection
	end

	return connection
end

function Signal:DisconnectAllConnections()
	self.ConnectionListHead = nil

	return nil
end

function Signal:IsDestroyed()
	return self._isDestroyed
end

function Signal:Destroy()
	self:DisconnectAllConnections()
	self._isDestroyed = true

	setmetatable(self, {
		__index = function(_, key)
			if typeof(Signal[key]) == "function" then
				assert(
					table.find(LocalConstants.Methods.AlwaysAvailable, key) ~= nil,
					("Can only call methods [%s] as signal is destroyed"):format(
						table.concat(LocalConstants.Methods.AlwaysAvailable)
					)
				)

				return Signal[key]
			end

			return nil
		end,
	})

	return nil
end

function Signal:Wait()
	-- This method of resuming a yielded coroutine is efficient as it doesn't
	-- cause any internal script errors (when resuming a yielded coroutine directly):
	local yieldedCoroutine = coroutine.running()

	local connection = nil
	connection = self:Connect(function(...)
		connection:Disconnect()
		task.spawn(yieldedCoroutine, ...)
	end)

	local returnValues = { coroutine.yield() }

	-- Prevent no return values:
	if #returnValues >= LocalConstants.MinArgumentCount then
		return returnValues[1]
	else
		return table.unpack(returnValues)
	end
end

function Signal:WaitUntilArgumentsPassed(...)
	local expectedArguments = { ... }

	while true do
		-- Signal:Wait() returns any arguments passed to Signal:Fire()
		local returnValues = { self:Wait() }

		-- Case of multiple return and expected return values:
		if
			#returnValues > LocalConstants.MinArgumentCount
			and #expectedArguments > LocalConstants.MinArgumentCount
		then
			local areReturnValuesEqual = true

			for index, returnValue in ipairs(returnValues) do
				if returnValue ~= expectedArguments[index] then
					areReturnValuesEqual = false
				end
			end

			if areReturnValuesEqual then
				return expectedArguments
			end
		else
			if returnValues[1] == expectedArguments[1] then
				return expectedArguments
			end
		end

		-- Prevent script execution timout incase of any thread concurrency issues:
		task.wait()
	end

	return nil
end

function Signal:Fire(...)
	-- Call handlers in reverse order (end - start):
	local connection = self.ConnectionListHead

	while connection ~= nil do
		if connection:IsConnected() then
			if not Signal._freeRunnerThread then
				Signal._freeRunnerThread = coroutine.create(
					Signal._runEventHandlerInFreeThread
				)
			end

			task.spawn(Signal._freeRunnerThread, connection.Callback, ...)
		end

		connection = connection.Next
	end

	return nil
end

function Signal:DeferredFire(...)
	-- Call handlers in reverse order (end - start), except at a very slightly later
	-- time (next engine step):
	local connection = self.ConnectionListHead

	while connection do
		if connection:IsConnected() then
			if not Signal._freeRunnerThread then
				Signal._freeRunnerThread = coroutine.create(
					Signal._runEventHandlerInFreeThread
				)
			end

			task.spawn(Signal._freeRunnerThread, connection.Callback, ...)
		end

		connection = connection.Next
	end

	return nil
end

function Signal._acquireRunnerThreadAndCallEventHandler(callBack, ...)
	local acquiredRunnerThread = Signal._freeRunnerThread
	Signal._freeRunnerThread = nil

	callBack(...)
	Signal._freeRunnerThread = acquiredRunnerThread

	return nil
end

function Signal._runEventHandlerInFreeThread(...)
	Signal._acquireRunnerThreadAndCallEventHandler(...)
	while true do
		Signal._acquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end

	return nil
end

return Signal
