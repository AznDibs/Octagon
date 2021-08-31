-- SilentsReplacement
-- Connection
-- August 01, 2021

--[[
	Connection.new() --> Connection []
	Connection.IsConnection(self : any) --> boolean [IsConnection]
	
	Connection.Callback : function
	Connection.Next : Connection | nil

	-- Only when accessed from an object returned by Connection.new:
	
	Connection:Disconnect() --> nil []
	Connection:IsConnected() -- > boolean [IsConnected]
]]

local Connection = {}
Connection.__index = Connection

local LocalConstants = {
	Methods = {
		AlwaysAvailable = {
			"IsConnected",
		},
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
	self._signal.ConnectedConnectionCount -= 1
	self._connected = false

	-- Unhook the node, but DON'T clear it. That way any fire calls that are
	-- currently sitting on this node will be able to iterate forwards off of
	-- it, but any subsequent fire calls will not hit it, and it will be GCed
	-- when no more fire calls are sitting on it.
	if self._signal.ConnectionListHead == self then
		self._signal.ConnectionListHead = self.Next
	else
		local previousConnectionListHead = self._signal.ConnectionListHead
		while previousConnectionListHead ~= nil and previousConnectionListHead.Next ~= self do
			previousConnectionListHead = previousConnectionListHead.Next
		end

		if previousConnectionListHead ~= nil then
			previousConnectionListHead.Next = self.Next
		end
	end

	setmetatable(self, {
		__index = function(_, key)
			if typeof(Connection[key]) == "function" then
				assert(
					table.find(LocalConstants.Methods.AlwaysAvailable, key) ~= nil,
					("Can only call methods [%s] as connection is disconnected"):format(
						table.concat(LocalConstants.Methods.AlwaysAvailable)
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
