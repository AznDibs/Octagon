-- SilentsReplacement
-- ClearReferenceTypes
-- August 27, 2021

--[[
    ClearReferenceTypes(tabl : table) --> nil []
]]

local LocalConstants = {
	ReferenceTypes = {
		"table",
		"Instance",
		"string",
		"thread",
		"function",
	},
}

return function(tabl)
	-- Set only reference type keys/values to nil:
	for key, value in pairs(tabl) do
		if
			table.find(LocalConstants.ReferenceTypes, typeof(key))
			and not table.find(LocalConstants.ReferenceTypes, typeof(value))
		then
			continue
		end

		tabl[key] = nil
	end

    return nil
end
