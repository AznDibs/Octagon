-- SilentsReplacement
-- Config
-- July 20, 2021

--[[
	Example setup:

	return {
		ShouldMonitorGameOwner = true,

		PlayersBlackListedFromBeingMonitored = {
			[124236236] = true, -- 124236236 being the user id of a player

			GroupConfig = {
				[8876330] = { 
					MinimumPlayerGroupRank = 35,
					RequiredPlayerGroupRank = nil,
				}
			},
		},
	}
]]

return {
	ShouldMonitorGameOwner = true,

	PlayersBlackListedFromBeingMonitored = {
		GroupConfig = {},
	},
}
