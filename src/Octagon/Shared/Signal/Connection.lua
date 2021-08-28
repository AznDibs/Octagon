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
		_isConnected = true,
		_signal = signal,
		_isConnection = true,
		_signalConnectionIndex = #signal.Connections + 1,
	}, Connection)
end

function Connection:Disconnect()
	self._isConnected = false
	self._signal.ConnectedConnectionCount -= 1
	table.remove(self._signal.Connections, self._signalConnectionIndex)

	ClearReferenceTypes(self)

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
