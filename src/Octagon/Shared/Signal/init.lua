-- SilentsReplacement
-- Signal
-- July 13, 2021

--[[
	Signal.new() --> Signal []
	Signal.IsSignal(self : any) --> boolean [IsSignal]

	-- Only when accessed from an object returned by Signal.new:

	Signal.ConnectedConnectionCount : number
	Signal.Connections : table

	Signal:Connect(callBack : function) --> Connection []
	Signal:Fire(tuple : any) --> nil []
	Signal:FireDeferred(tuple : any) --> nil []
	Signal:Wait() --> any [tuple]
	Signal:WaitUntilArgumentsPassed(tuple : any) --> any [tuple]
    Signal:DisconnectAllConnections() --> nil []
	Signal:Destroy() -->  nil []
	Signal:IsDestroyed() --> boolean [IsDestroyed]
]]

local Signal = {}
Signal.__index = Signal

local Connection = require(script.Connection)
local ClearReferenceTypes = require(script.ClearReferenceTypes)

local LocalConstants = {
	MinMultipleReturnValueCount = 2,
	MinMultipleArgumentCount = 2,
	AlwaysAvailableMethods = {
		"IsDestroyed",
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
		Connections = {},
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
	table.insert(self.Connections, connection)

	return connection
end

function Signal:DisconnectAllConnections()
	for _, connection in ipairs(self.Connections) do
		if connection:IsConnected() then
			connection:Disconnect()
		end
	end

	return nil
end

function Signal:IsDestroyed()
	return self._isDestroyed
end

function Signal:Destroy()
	self:DisconnectAllConnections()
	self._isDestroyed = true

	-- Set only reference type keys/values to nil:
	ClearReferenceTypes(self)

	setmetatable(self, {
		__index = function(_, key)
			if typeof(Signal[key]) == "function" then
				assert(
					table.find(LocalConstants.AlwaysAvailableMethods, key),
					("Can only call methods [%s] as signal is destroyed"):format(
						table.concat(LocalConstants.AlwaysAvailableMethods)
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

	if next(returnValues) ~= nil then
		return table.unpack(returnValues)
	else
		return nil
	end
end

function Signal:WaitUntilArgumentsPassed(...)
	local expectedArguments = { ... }

	if #expectedArguments < LocalConstants.MinMultipleArgumentCount then
		expectedArguments = table.unpack(expectedArguments)
	end

	while true do
		-- Signal:Wait() returns any arguments passed to Signal:Fire()
		local returnValues = { self:Wait() }

		if #returnValues < LocalConstants.MinMultipleReturnValueCount then
			returnValues = table.unpack(returnValues)
		end

		-- Case of multiple return and expected return values:
		if typeof(returnValues) == "table" and typeof(expectedArguments) == "table" then
			local areReturnValuesEqual = true

			for index, returnValue in ipairs(returnValues) do
				if returnValue ~= expectedArguments[index] then
					areReturnValuesEqual = false
				end
			end

			if areReturnValuesEqual then
				return expectedArguments
			end

			-- Case of just 1 expected and return value:
		elseif typeof(returnValues) ~= "table" and typeof(expectedArguments) ~= "table" then
			if returnValues == expectedArguments then
				return expectedArguments
			end
		end

		-- Yield the thread to prevent overload in case thread concurrency issue
		-- occurs with Signal:Wait():
		task.wait()
	end

	return nil
end

function Signal:Fire(...)
	-- Call signals in reverse order (end - start) and use a primitive for loop rather than
	-- an iterator function to not call handlers that were added while this method was
	-- still running:

	local connectionsLength = #self.Connections

	for index = connectionsLength, 1, -1 do
		local connection = self.Connections[index]

		if not connection or not connection:IsConnected() then
			continue
		end

		task.spawn(connection.Callback, ...)
	end

	return nil
end

function Signal:FireDeferred(...)
	-- Call signals in reverse order (end - start) and use a primitive for loop rather than
	-- an iterator function to not call handlers that were added while this method was
	-- still running. This is same as Signal:Fire(), except it resumes handlers at a slightly
	-- later time (deferred):

	local connectionsLength = #self.Connections

	for index = connectionsLength, 1, -1 do
		local connection = self.Connections[index]

		if not connection or not connection:IsConnected() then
			continue
		end

		task.defer(connection.Callback, ...)
	end

	return nil
end

return Signal
