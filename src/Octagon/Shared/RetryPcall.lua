-- SilentsReplacement
-- RetryPcall
-- August 13, 2021

--[[
    RetryPcall(
        maxTries : number | nil, 
        retryInterval : number | nil, 
        argsData : table
    ) --> any [tuple]
]]

local LocalConstants = {
	DefaultFailedPcallTries = 5,
	DefaultFailedPcallRetryInterval = 4,
}

return function(maxTries, retryInterval, argsData)
	retryInterval = retryInterval or LocalConstants.DefaultFailedPcallRetryInterval
	maxTries = maxTries or LocalConstants.DefaultFailedPcallTries

	local tries = 0

	while tries < maxTries do
		local wasSuccessfull, response = pcall(argsData[1], select(2, table.unpack(argsData)))

		if wasSuccessfull then
			return wasSuccessfull, response
		else
			tries += 1

			if tries == maxTries then
				return wasSuccessfull, response
			end

			task.wait(retryInterval)
		end
	end
end
