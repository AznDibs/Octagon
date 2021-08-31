-- SilentsReplacement
-- DestroyAllMaids.lua
-- August 27, 2021

--[[
    DestroyAllMaids(tabl : table) --> nil []
]]

local Maid = require(script.Maid)

local LocalConstants = {
	ErrorMessages = {
		InvalidArgument = "Invalid argument#%d to %s: expected %s, got %s",
	},
}

return function(tabl)
	assert(
		typeof(tabl) == "table",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"DestroyAllMaids",
			"table",
			typeof(tabl)
		)
	)
	
	for _, value in pairs(tabl) do
		if Maid.IsMaid(value) then
			value:Destroy()
		end
	end

	return nil
end
