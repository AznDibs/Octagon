-- SilentsReplacement
-- RetryPcall
-- August 13, 2021

--[[
    RetryPcall(
        maxTries : number | nil, 
        retryInterval : number | nil, 
        argsData : table
    ) --> boolean [wasSuccessful], response : any [tuple]
]]

local LocalConstants = {
	DefaultFailedPcallTries = 5,
	DefaultFailedPcallRetryInterval = 4,
}

return function(maxTries, retryInterval, arguments)
	local retryInterval = retryInterval or LocalConstants.DefaultFailedPcallRetryInterval
	local maxTries = maxTries or LocalConstants.DefaultFailedPcallTries

	local tries = 0
	local wasSuccessfull, response = nil, nil

	while tries < maxTries do
		wasSuccessfull, response = pcall(arguments[1], select(2, table.unpack(arguments)))

		if wasSuccessfull then
			break
		else
			tries += 1

			task.wait(retryInterval)
		end
	end

	return wasSuccessfull, response
end
