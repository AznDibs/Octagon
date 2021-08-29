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
		"thread",
		"function",
	},

	DefaultKeyIgnoreList = {},
}

return function(tabl, keyIgnoreList)
	keyIgnoreList = keyIgnoreList or LocalConstants.DefaultKeyIgnoreList

	for key, value in pairs(tabl) do
		if
			not table.find(LocalConstants.ReferenceTypes, typeof(key))
				and not table.find(LocalConstants.ReferenceTypes, typeof(value))
			or table.find(keyIgnoreList, key)
		then
			continue
		end

		tabl[key] = nil
	end

	return nil
end
