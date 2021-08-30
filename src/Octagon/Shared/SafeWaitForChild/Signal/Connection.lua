-- SilentsReplacement
-- Connection
-- August 01, 2021

--[[
	Connection.new() --> Connection []
	Connection.IsConnection(self : any) --> boolean [IsConnection]
	
	Connection.Callback : function

	-- Only when accessed from an object returned by Connection.new:
	
	Connection:Disconnect() --> nil []
	Connection:IsConnected() -- > boolean [IsConnected]
]]

local Connection = {}
Connection.__index = Connection

local ClearReferenceTypes = require(script.Parent.ClearReferenceTypes)

local LocalConstants = {
	AlwaysAvailableMethods = {
		"IsConnected",
	},
}

function Connection.IsConnection(self)
	return typeof(self) == "table" and self._isConnection
end

function Connection.new(signal, callBack)
	signal.ConnectedConnectionCount += 1

	return setmetatable({
		Callback = callBack,
		Next = nil,
		_isConnected = true,
		_signal = signal,
		_isConnection = true,
	}, Connection)
end

function Connection:Disconnect()
	self._isConnected = false
	self._signal.ConnectedConnectionCount -= 1

	-- Unhook the node, but DON'T clear it. That way any fire calls that are
	-- currently sitting on this node will be able to iterate forwards off of
	-- it, but any subsequent fire calls will not hit it, and it will be GCed
	-- when no more fire calls are sitting on it.
	if self._signal.HandlerListHead == self then
		self._signal.HandlerListHead = self.Next
	else
		local previousHandlerListHead = self._signal.HandlerListHead
		while previousHandlerListHead and previousHandlerListHead.Next ~= self do
			previousHandlerListHead = previousHandlerListHead.Next
		end

		if previousHandlerListHead then
			previousHandlerListHead.Next = self.Next
		end
	end

	ClearReferenceTypes(self)
	self._connected = false

	setmetatable(self, {
		__index = function(_, key)
			if typeof(Connection[key]) == "function" then
				assert(
					table.find(LocalConstants.AlwaysAvailableMethods, key),
					("Can only call methods [%s] as connection is disconnected"):format(
						table.concat(LocalConstants.AlwaysAvailableMethods)
					)
				)

				return Connection[key]
			end

			return nil
		end,
	})

	return nil
end

function Connection:IsConnected()
	return self._isConnected
end

return Connection
