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

	ReferenceTypes = {
		"table",
		"Instance",
		"string",
		"thread",
		"function",
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

function Maid:AddTask(task, customCleanupMethod, identifier)
	if typeof(task) == "table" then
		task = {
			Task = task,
			CustomCleanupMethod = customCleanupMethod,
			Identifier = identifier,
		}
	end

	self._tasks[task] = task

	return task
end

function Maid:RemoveTask(task)
	self._tasks[task] = nil

	return nil
end

function Maid:IsDestroyed()
	return self._isDestroyed
end

function Maid:Destroy()
	self:Cleanup()
	self._isDestroyed = true

	-- Set only reference type keys/values to nil:
	for key, value in pairs(self) do
		if
			table.find(LocalConstants.ReferenceTypes, typeof(key))
			and not table.find(LocalConstants.ReferenceTypes, typeof(value))
		then
			continue
		end

		self[key] = nil
	end

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

function Maid:Cleanup()
	for key, task in pairs(self._tasks) do
		if typeof(task) == "function" then
			task()
		elseif typeof(task) == "RBXScriptConnection" then
			task:Disconnect()
		elseif typeof(task) == "table" then
			local customCleanupMethod = task.Task[task.CustomCleanupMethod]

			if customCleanupMethod then
				customCleanupMethod(task.Task)
			else
				local defaultMethod = task.Task[Maid._getDefaultMethod(task.Task)]

				if defaultMethod then
					defaultMethod(task.Task)
				else
					warn(
						(
							"[Maid] [Debug]: Task [%s] can't be cleaned up as no default or custom method was found"
						):format(task.Identifier or tostring(task))
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
		if task[method] then
			return method
		end
	end

	return nil
end

return Maid
