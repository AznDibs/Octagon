# Blacklisting players from being monitored

Octagon provides a way to black list players from being monitored. This is useful for games that make use of admin commands or if you want to black list admins, specific players, etc.

The below example which black lists players from being monitored who have a minimum group rank of `35` inside this [group](https://www.roblox.com/groups/8876330/Perdux-Studios#!/about) which has the group id of `8876330`.

```lua
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
		GroupConfig = {
			[8876330] = { 
				MinimumPlayerGroupRank = 35,
				RequiredPlayerGroupRank = nil,
			},
		},
	},
}
```

You can also add in more groups if you'd like. The below example black lists players from being monitored who have a minimum group rank of `35` inside this [group](https://www.roblox.com/groups/8876330/Perdux-Studios#!/about) which has the group id of `8876330` or players who have a minimum group rank of `10` inside this [group](https://www.roblox.com/groups/3059674/Badimo#!/about) which has the group id of `3059674`.

```lua
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
		GroupConfig = {
			[8876330] = { 
				MinimumPlayerGroupRank = 35,
				RequiredPlayerGroupRank = nil,
			},

            [3059674] = { 
				MinimumPlayerGroupRank = 10,
				RequiredPlayerGroupRank = nil,
			},
		},
	},
}
```

You also can black list certain people specifically like so. The below example black lists players who have a user id of `700264840` or `1253464373`.

```lua
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
        [700264840] = true,
        [1253464373] = true,

		GroupConfig = {},
	},
}
```

Lastly, you can even combine both solutions:

```lua
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
        [700264840] = true,
        [1253464373] = true,

		GroupConfig = {
            [8876330] = { 
				MinimumPlayerGroupRank = 35,
				RequiredPlayerGroupRank = nil,
			},

            [3059674] = { 
				MinimumPlayerGroupRank = 10,
				RequiredPlayerGroupRank = nil,
			},
        },
	},
}
```