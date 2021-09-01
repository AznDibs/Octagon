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
	_areModulesInit = false,
	_isInit = false,
	_destroyedPlayerProfiles = {},
}

local Octagon = script:FindFirstAncestor("Octagon")
local Signal = require(Octagon.Shared.Signal)
local SharedConstants = require(Octagon.Shared.SharedConstants)
local Maid = require(Octagon.Shared.Maid)
local Util = require(Octagon.Shared.Util)
local InitMaidFor = require(Octagon.Shared.InitMaidFor)
local DestroyAllMaids = require(Octagon.Shared.DestroyAllMaids)

PlayerProfileService.OnPlayerProfileLoaded = Signal.new()
PlayerProfileService.OnPlayerProfileDestroyed = Signal.new()
PlayerProfileService.OnPlayerProfileInit = Signal.new()
PlayerProfileService._maid = Maid.new()

function PlayerProfileService.ArePlayerProfilesLoaded()
	return next(PlayerProfileService.LoadedPlayerProfiles) ~= nil
end

function PlayerProfileService.DestroyLoadedPlayerProfiles()
	for _, playerProfile in pairs(PlayerProfileService.LoadedPlayerProfiles) do
		playerProfile:Destroy()
	end

	return nil
end

function PlayerProfileService.Init()
	PlayerProfileService._isInit = true
	PlayerProfileService._initSignals()

	return nil
end

function PlayerProfileService.Cleanup()
	DestroyAllMaids(PlayerProfileService)

	return nil
end

function PlayerProfileService.GetPlayerProfile(player)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerProfileService.GetPlayerProfile()",
			"Player",
			typeof(player)
		)
	)

	local playerProfile = PlayerProfileService.LoadedPlayerProfiles[player]

	if playerProfile then
		return playerProfile
	elseif
		not table.find(PlayerProfileService._destroyedPlayerProfiles, player.UserId)
		and PlayerProfileService._isInit
		and Util.IsPlayerSubjectToBeMonitored(player)
	then
		return PlayerProfileService._waitForPlayerProfile(player)
	end

	return nil
end

function PlayerProfileService._waitForPlayerProfile(player)
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
	InitMaidFor(PlayerProfileService, PlayerProfileService._maid, Signal.IsSignal)
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

if not PlayerProfileService._areModulesInit then
	PlayerProfileService._initModules()
end

return PlayerProfileService
