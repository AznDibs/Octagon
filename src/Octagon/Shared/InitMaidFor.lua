-- SilentsReplacement
-- InitMaidFor
-- August 27, 2021

--[[
    InitMaidFor(tabl : table, maid : Maid, callBack : function) --> [] nil
]]

return function(tabl, maid, callBack)
	for _, value in pairs(tabl) do
		if callBack(value) then
			maid:AddTask(value)
		end
	end

	return nil
end
