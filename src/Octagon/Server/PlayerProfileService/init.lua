-- SilentsReplacement
-- PlayerProfileService
-- August 10, 2021

--[[
    PlayerProfileService.OnPlayerProfileLoaded : Signal (playerProfile : PlayerProfile) 
    PlayerProfileService.OnPlayerProfileDestroyed : Signal (player : Player)
    PlayerProfileService.OnPlayerProfileInit : Signal (playerProfile : PlayerProfile) 
    PlayerProfileService.LoadedPlayerProfiles : table

    PlayerProfileService.GetPlayerProfile(player : Player) --> PlayerProfile | nil []
    PlayerProfileService.ArePlayerProfilesLoaded() --> boolean [ArePlayerProfilesLoaded]
    PlayerProfileService.DestroyLoadedPlayerProfiles() --> nil []
]]

local PlayerProfileService = {
	LoadedPlayerProfiles = {},
	_areSignalsInit = false,
	_areModulesInit = false,
	_destroyedPlayerProfiles = {},
}

local Shared = script:FindFirstAncestor("Octagon").Shared
local Signal = require(Shared.Signal)
local SharedConstants = require(Shared.SharedConstants)

PlayerProfileService.OnPlayerProfileLoaded = Signal.new()
PlayerProfileService.OnPlayerProfileDestroyed = Signal.new()
PlayerProfileService.OnPlayerProfileInit = Signal.new()

function PlayerProfileService.ArePlayerProfilesLoaded()
	return next(PlayerProfileService.LoadedPlayerProfiles) ~= nil
end

function PlayerProfileService.DestroyLoadedPlayerProfiles()
	for _, playerProfile in pairs(PlayerProfileService.LoadedPlayerProfiles) do
		playerProfile:Destroy()
	end

	return nil
end

function PlayerProfileService.GetPlayerProfile(player)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerProfileService.GetPlayerProfile()",
			"a Player object",
			typeof(player)
		)
	)

	local playerProfile = PlayerProfileService.LoadedPlayerProfiles[player]
	
	if playerProfile then
		return playerProfile
	elseif not table.find(PlayerProfileService._destroyedPlayerProfiles, player.UserId)
	then
		return PlayerProfileService._waitForPlayerProfile(player)
	end

	return nil
end

function PlayerProfileService._waitForPlayerProfile(player)
	local Server = require(script.Parent)

	if not Server.IsPlayerSubjectToBeMonitored(player) or not Server.IsStarted() then
		return nil
	end

	local onPlayerProfileLoaded = Signal.new()

	local onPlayerProfileLoadedConnection = nil
	onPlayerProfileLoadedConnection = PlayerProfileService.OnPlayerProfileLoaded:Connect(
		function(playerProfile)
			if playerProfile.Player == player then
				onPlayerProfileLoaded:Fire(playerProfile)
			end
		end
	)

	local playerProfile = onPlayerProfileLoaded:Wait()
	if not playerProfile:IsInit() then
		playerProfile.OnInit:Wait()
	end

	onPlayerProfileLoaded:Destroy()
	onPlayerProfileLoadedConnection:Disconnect()

	return playerProfile
end

function PlayerProfileService._initSignals()
	PlayerProfileService._areSignalsInit = true

	PlayerProfileService.OnPlayerProfileLoaded:Connect(function(playerProfile)
		PlayerProfileService.LoadedPlayerProfiles[playerProfile.Player] = playerProfile
	end)
 
	PlayerProfileService.OnPlayerProfileDestroyed:Connect(function(player)
		table.insert(PlayerProfileService._destroyedPlayerProfiles, player.UserId)
		PlayerProfileService.LoadedPlayerProfiles[player] = nil
	end)

	return nil
end

function PlayerProfileService._initModules()
	PlayerProfileService._areModulesInit = true
	PlayerProfileService.PlayerProfile = script.PlayerProfile

	return nil
end

if not PlayerProfileService._areSignalsInit then
	PlayerProfileService._initSignals()
end

if not PlayerProfileService._areModulesInit then
	PlayerProfileService._initModules()
end

return PlayerProfileService
