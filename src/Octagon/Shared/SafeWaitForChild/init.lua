-- SilentsReplacement
-- SafeWaitForChild
-- July 01, 2021

--[[
	SafeWaitForChild(instance : Instance, childName : string, timeOut : number | nil) 
    --> Instance | nil [Child]
]]

local Signal = require(script.Signal)
local Maid = require(script.Maid)

local LocalConstants = {
	DefaultTimeout = 15,
	ErrorMessages = {
		InvalidArgument = "Invalid argument#%d to %s: expected %s, got %s",
	},
}

return function(instance, childName, timeOut)
	assert(
		typeof(instance) == "Instance",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"SafeWaitForChild()",
			"instance",
			typeof(instance)
		)
	)
	assert(
		typeof(childName) == "string",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			2,
			"SafeWaitForChild()",
			"string",
			typeof(childName)
		)
	)

	timeOut = timeOut or LocalConstants.DefaultTimeout
 
	assert(
		typeof(timeOut) == "number",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			3,
			"SafeWaitForChild()",
			"number or nil",
			typeof(timeOut)
		)
	)

	if instance:FindFirstChild(childName) then
		return instance[childName]
	end

	local maid = Maid.new()
	local signal = Signal.new()

	maid:AddTask(signal)

	maid:AddTask(instance:GetPropertyChangedSignal("Parent"):Connect(function(_, parent)
		if not parent and not signal:IsDestroyed() then
			signal:Fire(nil)
		end
	end))

	maid:AddTask(instance.ChildAdded:Connect(function(child)
		if child.Name == childName and not signal:IsDestroyed() then
			signal:Fire(child)
		end
	end))

	task.spawn(function()
		task.wait(timeOut)
		if not signal:IsDestroyed() then
			signal:Fire(nil)
		end
	end)

	local returnValues = { signal:Wait() }
	maid:Destroy()

	return table.unpack(returnValues)
end
