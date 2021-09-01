-- SilentsReplacement
-- Maid
-- July 06, 2021

--[[
	Maid.new() --> Maid []
	Maid.IsMaid(self : any) --> boolean [IsMaid]

	-- Only when accessed from an object created by Maid.new():
	
	Maid:AddTask(
		task : table | function | RBXScriptConnection,
		customCleanupMethod : string | nil
	) --> task []

	Maid:Cleanup() --> nil []
	Maid:IsDestroyed() --> boolean [IsDestroyed]
	Maid:RemoveTask(task) --> nil []
	Maid:Destroy() --> nil []
	Maid:LinkToInstances(instances : table) --> instances []
]]

local Maid = {}
Maid.__index = Maid

local LocalConstants = {
	Methods = {
		Default = {
			"Disconnect",
			"Destroy",
			"DoCleaning",
			"Cleanup",
		},

		AlwaysAvailable = {
			"IsDestroyed",
		},
	},

	ErrorMessages = {
		InvalidArgument = "Invalid argument#%d to %s: expected %s, got %s",
	},
}

function Maid.new()
	return setmetatable({
		_tasks = {},
		_isDestroyed = false,
		_isMaid = true,
	}, Maid)
end

function Maid.IsMaid(self)
	return typeof(self) == "table" and self._isMaid
end

function Maid:AddTask(task, customCleanupMethod)
	assert(
		typeof(task) == "function"
			or typeof(task) == "RBXScriptConnection"
			or typeof(task) == "table",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Maid.new()",
			"function or RBXScriptConnection or table",
			typeof(task)
		)
	)
	assert(
		typeof(customCleanupMethod) == "string" or customCleanupMethod == nil,
		LocalConstants.ErrorMessages.InvalidArgument:format(
			2,
			"Maid.new()",
			"string or nil",
			typeof(customCleanupMethod)
		)
	)

	if typeof(task) == "table" then
		if customCleanupMethod then
			assert(
				typeof(task[customCleanupMethod]) == "function",
				("Cleanup method [%s] not found in task: %s"):format(
					customCleanupMethod,
					tostring(task)
				)
			)
		end

		task = {
			Task = task,
			CustomCleanupMethod = customCleanupMethod,
		}
	end

	self._tasks[task] = task

	return task
end

function Maid:RemoveTask(task)
	assert(
		typeof(task) == "function"
			or typeof(task) == "RBXScriptConnection"
			or typeof(task) == "table",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Maid:RemoveTask()",
			"function or RBXScriptConnection or table",
			typeof(task)
		)
	)

	self._tasks[task] = nil

	return nil
end

function Maid:IsDestroyed()
	return self._isDestroyed
end

function Maid:Destroy()
	self:Cleanup()
	self._isDestroyed = true

	setmetatable(self, {
		__index = function(_, key)
			if typeof(Maid[key]) == "function" then
				assert(
					table.find(LocalConstants.Methods.AlwaysAvailable, key),
					("Can only call methods [%s] as maid is destroyed"):format(
						table.concat(LocalConstants.Methods.AlwaysAvailable)
					)
				)

				return Maid[key]
			end

			return nil
		end,
	})

	return nil
end

function Maid:LinkToInstances(instances)
	assert(
		typeof(instances) == "table",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Maid:LinkToInstances()",
			"table",
			typeof(table)
		)
	)

	for _, instance in ipairs(instances) do
		local instanceParentChangedConnection = nil
		instanceParentChangedConnection = self:AddTask(
			instance:GetPropertyChangedSignal("Parent"):Connect(function()
				if not instance.Parent then
					task.defer(function()
						-- If the connection has also been disconnected, then its
						-- guaranteed that the instance has been destroyed through
						-- Destroy():
						if not instanceParentChangedConnection.Connected then
							self:Cleanup()
						end
					end)
				end
			end)
		)
	end

	return instances
end

function Maid:Cleanup()
	for key, task in pairs(self._tasks) do
		if typeof(task) == "function" then
			task()
		elseif typeof(task) == "RBXScriptConnection" then
			task:Disconnect()
		elseif typeof(task) == "table" then
			local customCleanupMethod = task.Task[task.CustomCleanupMethod]

			if customCleanupMethod ~= nil then
				customCleanupMethod(task.Task)
			else
				local defaultMethod = Maid._getDefaultMethod(task.Task)

				if defaultMethod ~= nil then
					task.Task[defaultMethod](task.Task)
				else
					warn(
						(
							"[Maid]: Can't cleanup task: %s as no default / custom method was found"
						):format(task.Task)
					)
				end
			end
		end

		self._tasks[key] = nil
	end

	return nil
end

function Maid._getDefaultMethod(task)
	for _, method in pairs(LocalConstants.Methods.Default) do
		if typeof(task[method]) == "function" then
			return method
		end
	end

	return nil
end

return Maid
