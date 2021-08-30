-- SilentsReplacement
-- DestroyAll
-- August 27, 2021

--[[
    DestroyAll(tabl : table) --> nil []
]]

return function(tabl, callBack)
	for _, value in pairs(tabl) do
		if callBack(value) then
			value:Destroy()
		end
	end

	return nil
end
