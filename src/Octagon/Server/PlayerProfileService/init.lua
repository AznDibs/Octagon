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
}

local Signal = require(script:FindFirstAncestor("Octagon").Shared.Signal)

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
	return PlayerProfileService.LoadedPlayerProfiles[player] or PlayerProfileService._waitForPlayerProfile(player)
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

	PlayerProfileService.OnPlayerProfileDestroyed:Connect(function(player)
		PlayerProfileService.LoadedPlayerProfiles[player] = nil
	end)

	PlayerProfileService.OnPlayerProfileLoaded:Connect(function(playerProfile)
		PlayerProfileService.LoadedPlayerProfiles[playerProfile.Player] = playerProfile
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
