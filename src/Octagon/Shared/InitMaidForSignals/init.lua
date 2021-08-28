-- SilentsReplacement
-- InitMaidForSignals
-- August 27, 2021

--[[
    InitMaidForSignals(tabl : table, maid : Maid) --> [] nil
]]

local Signal = require(script.Signal)

return function(tabl, maid)
	for _, value in pairs(tabl) do
		if Signal.IsSignal(value) then
			maid:AddTask(value)
		end
	end

	return nil
end
