-- SilentsReplacement
-- DestroyAllMaids
-- August 27, 2021

--[[
    DestroyAllMaids(tabl : table) --> nil []
]]

local Maid = require(script.Maid)

return function(tabl)
	for _, value in pairs(tabl) do
		if Maid.IsMaid(value) then
			value:Destroy()
		end
	end

	return nil
end
