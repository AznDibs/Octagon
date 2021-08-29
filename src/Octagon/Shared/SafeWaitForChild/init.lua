-- SilentsReplacement
-- SafeWaitForChild
-- July 01, 2021

--[[
	SafeWaitForChild(instance : Instance, childName : string, timeOut : number | nil) 
    --> Instance | nil [Child]
]]

local Signal = require(script.Signal)
local Maid = require(script.Maid)

local LocalConstants = { DefaultTimeout = 15 }

return function(instance, childName, timeOut)
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
		task.wait(timeOut or LocalConstants.DefaultTimeout)
		if not signal:IsDestroyed() then
			signal:Fire(nil)
		end
	end)

	local returnValues = { signal:Wait() }
	maid:Destroy()

	return table.unpack(returnValues)
end
