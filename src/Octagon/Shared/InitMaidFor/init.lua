-- SilentsReplacement
-- InitMaidFor
-- August 27, 2021

--[[
    InitMaidFor(tabl : table, maid : Maid, method : function) --> [] nil
]]

local LocalConstants = {
	ErrorMessages = {
		InvalidArgument = "Invalid argument#%d to %s: expected %s, got %s",
	},
}

local Maid = require(script.Maid)

return function(tabl, maid, method)
	assert(
		typeof(tabl) == "table",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"InitMaidFor",
			"table",
			typeof(tabl)
		)
	)
	assert(
		Maid.IsMaid(maid),
		LocalConstants.ErrorMessages.InvalidArgument:format(
			2,
			"InitMaidFor",
			"maid",
			typeof(tabl)
		)
	)
	assert(
		typeof(method) == "function",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			3,
			"InitMaidFor",
			"function",
			typeof(method)
		)
	)

	for _, value in pairs(tabl) do
		if method(value) then
			maid:AddTask(value)
		end
	end

	return nil
end
