-- SilentsReplacement
-- init
-- August 12, 2021

--[[
	Server.MonitoringPlayerProfiles : table
	Server.BlacklistedPlayers : table

    Server.Start() --> nil []
    Server.Stop() --> nil []
	Server.IsStarted() --> boolean [IsStarted]
	Server.IsStopped() --> boolean [IsStopped]
    Server.BlacklistNoClipMonitoringParts(parts : table) --> nil []
    Server.UnBlacklistNoClipMonitoringParts(parts : table) --> nil []
    Server.IsPlayerSubjectToBeMonitored(player : Player) --> boolean [IsPlayerSubjectToBeMonitored]
    Server.IsPlayerGameOwner(player : Player) --> boolean [IsPlayerGameOwner]
    Server.TemporarilyBlacklistPlayerFromBeingMonitored(
        player : Player,
        value : number | function | RBXScriptSignal | Signal
    ) --> nil  []
]]

local Server = {
	MonitoringPlayerProfiles = {},
	BlacklistedPlayers = {},

	_detectionsInit = {
		Physics = {},
		NonPhysics = {},
	},

	_areModulesInit = false,
	_arePhysicsDetectionsInit = false,
	_isStarted = false,
	_isStopped = false,
	_heartBeatScriptConnection = nil,

	_playersInitialized = {},
	_shouldMonitorPlayerResultCache = {},
	_isPlayerGameOwnerResultCache = {},
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local PlayerProfileService = require(script.PlayerProfileService)
local Signal = require(script.Parent.Shared.Signal)
local Maid = require(script.Parent.Shared.Maid)
local RetryPcall = require(script.Parent.Shared.RetryPcall)
local Config = require(script.Config)
local SharedConstants = require(script.Parent.Shared.SharedConstants)
local DestroyAll = require(script.Parent.Shared.DestroyAll)
local InitMaidFor = require(script.Parent.Shared.InitMaidFor)
local Util = require(script.Parent.Shared.Util)

local LocalConstants = {
	FailedPcallRetryInterval = 5,
	MaxFailedPcallTries = 5,
	OwnerGroupRank = 255,
	DefaultPlayerGroupRank = 0,
}

Server._maid = Maid.new()
Server._onStop = Signal.new()

function Server.AreMonitoringPlayerProfilesLeft()
	return next(Server.MonitoringPlayerProfiles) ~= nil
end

function Server.IsPlayerGameOwner(player)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Octagon.IsPlayerGameOwner()",
			"a Player object",
			typeof(player)
		)
	)

	local cachedResult = Server._isPlayerGameOwnerResultCache[player.UserId]

	if cachedResult ~= nil then
		if Signal.IsSignal(cachedResult) then
			-- The cached result is currently a signal which means that this method
			-- was called again while it was performing a lookup for the same
			-- argument, wait until that signal fires and return the results
			-- instead of performing an other unnecessary lookup:
			return cachedResult:Wait()
		else
			return cachedResult
		end
	end

	local isPlayerGameOwner = false
	local onIsPlayerGameOwnerResult = Signal.new()
	Server._isPlayerGameOwnerResultCache[player.UserId] = onIsPlayerGameOwnerResult

	if game.CreatorType == Enum.CreatorType.Group then
		isPlayerGameOwner = Server._getPlayerRankInGroup(player, game.CreatorId)
			== LocalConstants.OwnerGroupRank
	else
		isPlayerGameOwner = player.UserId == game.CreatorId
	end

	onIsPlayerGameOwnerResult:Fire(isPlayerGameOwner)
	onIsPlayerGameOwnerResult:Destroy()

	Server._isPlayerGameOwnerResultCache[player.UserId] = isPlayerGameOwner

	return isPlayerGameOwner
end

function Server.TemporarilyBlacklistPlayerFromBeingMonitored(player, value)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Octagon.TemporarilyBlacklistPlayerFromBeingMonitored()",
			"a Player object",
			typeof(player)
		)
	)
	assert(
		typeof(value) == "number"
			or typeof(value) == "RBXScriptSignal"
			or Signal.IsSignal(value)
			or typeof(value) == "function",

		SharedConstants.ErrorMessages.InvalidArgument:format(
			2,
			"Octagon.TemporarilyBlacklistPlayerFromBeingMonitored()",
			"number or RBXScriptSignal or Signal or function",
			typeof(player)
		)
	)

	local playerProfile = PlayerProfileService.GetPlayerProfile(player)

	assert(
		playerProfile,
		(
			"Cannot temporarily black list player [%s] as player isn't being monitored by Octagon"
		):format(player.Name)
	)

	Server.MonitoringPlayerProfiles[player] = nil

	if Server._heartBeatScriptConnection and Server._heartBeatScriptConnection.Connected then
		if not Server.AreMonitoringPlayerProfilesLeft() then
			-- This player that is temporary black listed, is the only current
			-- player that is being monitored, it's safe to disconnect the heartbeat
			-- disconnection:
			Server._heartBeatScriptConnection:Disconnect()
		end
	end

	local serverOnStopConnection = nil
	serverOnStopConnection = Server._onStop:Connect(function()
		Server._setPlayerPrimaryNetworkOwner(player)
		serverOnStopConnection:Disconnect()
	end)

	task.spawn(function()
		if typeof(value) == "RBXScriptSignal" or Signal.IsSignal(value) then
			value:Wait()
		elseif typeof(value) == "function" then
			value()
		else
			task.wait(value)
		end

		if playerProfile:IsDestroyed() or Server.IsStopped() then
			return nil
		end

		Server.MonitoringPlayerProfiles[player] = playerProfile

		if not Util.DoValidPlayerBodyPartsExist(player) then
			return nil
		end

		playerProfile:_updateAllDetectionPhysicsData(
			"LastCFrame",
			player.Character.PrimaryPart.CFrame
		)

		if
			Server._heartBeatScriptConnection
			and not Server._heartBeatScriptConnection.Connected
		then
			Server._heartBeatScriptConnection = Server._startHeartBeatUpdate()
		end
	end)

	return nil
end

function Server.IsPlayerSubjectToBeMonitored(player)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Octagon.IsPlayerSubjectToBeMonitored()",
			"a Player object",
			typeof(player)
		)
	)

	return Server._shouldMonitorPlayer(player)
end

function Server._shouldMonitorPlayer(player)
	local cachedResult = Server._shouldMonitorPlayerResultCache[player.UserId]

	if cachedResult ~= nil then
		if Signal.IsSignal(cachedResult) then
			-- The cached result is currently a signal which means that this method
			-- was called again while it was performing a lookup for the same
			-- argument, wait until that signal fires and return the results
			-- instead of performing an other unnecessary lookup:
			return cachedResult:Wait()
		else
			return cachedResult
		end
	end

	local onShouldMonitorPlayerResult = Signal.new()
	Server._shouldMonitorPlayerResultCache[player] = onShouldMonitorPlayerResult

	local isPlayerBlackListedFromBeingMonitored =
		Server._isPlayerBlackListedFromBeingMonitored(
			player
		)

	if not isPlayerBlackListedFromBeingMonitored then
		local isPlayerGameOwner = Server.IsPlayerGameOwner(player)

		isPlayerBlackListedFromBeingMonitored = isPlayerGameOwner
			and not Config.ShouldMonitorGameOwner

		if not isPlayerBlackListedFromBeingMonitored and not isPlayerGameOwner then
			for groupId, config in pairs(Config.PlayersBlackListedFromBeingMonitored.GroupConfig) do
				local minimumPlayerGroupRank = config.MinimumPlayerGroupRank
				local requiredPlayerGroupRank = config.RequiredPlayerGroupRank

				assert(
					typeof(groupId) == "number",
					"Key in Config.GroupConfig must be a number (group id)"
				)

				assert(
					typeof(minimumPlayerGroupRank) == "number"
						or typeof(requiredPlayerGroupRank) == "number",
					(
						"RequiredPlayerGroupRank or MinimumPlayerGroupRank must be a number in Config.PlayersBlackListedFromBeingMonitored.GroupConfig[%d]"
					):format(groupId)
				)

				local playerGroupRank = Server._getPlayerRankInGroup(player, groupId)

				isPlayerBlackListedFromBeingMonitored = playerGroupRank
						== requiredPlayerGroupRank
					or minimumPlayerGroupRank
						and playerGroupRank >= minimumPlayerGroupRank

				if isPlayerBlackListedFromBeingMonitored then
					break
				end
			end
		end
	end

	onShouldMonitorPlayerResult:Fire(not isPlayerBlackListedFromBeingMonitored)
	onShouldMonitorPlayerResult:Destroy()

	-- Cache lookup result for later reuse:
	Server._shouldMonitorPlayerResultCache[player.UserId] =
		not isPlayerBlackListedFromBeingMonitored

	return not isPlayerBlackListedFromBeingMonitored
end

function Server.BlacklistNoClipMonitoringParts(parts)
	assert(
		typeof(parts) == "table",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Server.BlacklistNoClipMonitoringParts()",
			"table",
			typeof(parts)
		)
	)

	for _, part in ipairs(parts) do
		if not part:IsA("BasePart") then
			continue
		end

		CollectionService:AddTag(part, SharedConstants.Tags.NoClipBlackListed)
	end

	return nil
end

function Server.UnBlacklistNoClipMonitoringParts(parts)
	assert(
		typeof(parts) == "table",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Server.UnBlacklistNoClipMonitoringParts()",
			"table",
			typeof(parts)
		)
	)

	for _, part in ipairs(parts) do
		if not part:IsA("BasePart") then
			continue
		end

		CollectionService:RemoveTag(part, SharedConstants.Tags.NoClipBlackListed)
	end

	return nil
end

function Server.Start()
	local PlayerProfile = require(PlayerProfileService.PlayerProfile)

	assert(not Server.IsStopped(), "Can't start Octagon as Octagon is stopped")
	assert(not Server.IsStarted(), "Can't start Octagon as Octagon is already started")

	Server._isStarted = true
	Server._init()

	print(("%s: Started"):format(SharedConstants.FormattedOutputMessages.Octagon.Log))

	do
		local function PlayerAdded(player)
			if not Server._shouldMonitorPlayer(player) then
				table.insert(Server.BlacklistedPlayers, player)
				return nil
			elseif
				not next(Server._detectionsInit.Physics)
				and not next(Server._detectionsInit.NonPhysics)
			then
				return nil
			end

			local playerProfile = PlayerProfile.new(player)

			playerProfile.OnPhysicsDetectionFlagExpire:Connect(function()
				Server._setPlayerPrimaryNetworkOwner(player)
			end)

			playerProfile.OnPhysicsDetectionFlag:Connect(function()
				-- Temporarily black list the player from being monitored until
				-- their detection flag has expired:
				Server.TemporarilyBlacklistPlayerFromBeingMonitored(
					player,
					playerProfile.OnPhysicsDetectionFlagExpire
				)
			end)

			local function CharacterAdded(character)
				playerProfile.DetectionMaid:Cleanup()
				Server._startNonPhysicsDetections(playerProfile)

				-- The player's character will be loaded again if they
				-- don't have either of these based on the default detections:
				if not Util.DoValidPlayerBodyPartsExist(player) then
					return nil
				end

				Server.TemporarilyBlacklistPlayerFromBeingMonitored(player, function()
					playerProfile:SetDeinitTag()
					playerProfile:Init(Server._detectionsInit.Physics)
				end)

				-- Setup a tag to know if a certain part is a primary part if
				-- character.PrimaryPart is nil. This is used in primary part deletion
				-- where we can't determine if the part deleted was a primary part or not:
				CollectionService:AddTag(
					character.PrimaryPart,
					SharedConstants.Tags.PrimaryPart
				)

				return nil
			end

			CharacterAdded(player.Character or player.CharacterAdded:Wait())
			playerProfile.Maid:AddTask(player.CharacterAdded:Connect(CharacterAdded))

			return nil
		end

		local function PlayerRemoving(player)
			local playerProfile = PlayerProfileService.GetPlayerProfile(player)

			if not playerProfile then
				table.remove(
					Server.BlacklistedPlayers,
					table.find(Server.BlacklistedPlayers, player)
				)
				return nil
			end

			playerProfile:Destroy()

			return nil
		end

		Server._maid:AddTask(Players.PlayerAdded:Connect(PlayerAdded))
		Server._maid:AddTask(Players.PlayerRemoving:Connect(PlayerRemoving))

		-- This is necessary as scripts will always run
		-- slightly late as they are deferred, which results in the PlayerAdded
		-- event not to fire for current players:
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(PlayerAdded, player)
		end
	end

	return nil
end

function Server.IsStopped()
	return Server._isStopped
end

function Server.IsStarted()
	return Server._isStarted
end

function Server.Stop()
	assert(not Server.IsStopped(), "Can't stop Octagon as Octagon is already stopped")
	assert(Server.IsStarted(), "Can't stop Octagon as Octagon isn't started")

	print(("%s: Stopped"):format(SharedConstants.FormattedOutputMessages.Octagon.Log))

	Server._isStarted = false
	Server._isStopped = true
	Server._onStop:Fire()
	Server._cleanup()

	return nil
end

function Server._cleanup()
	Server.BlacklistedPlayers = {}

	for _, playerProfile in pairs(PlayerProfileService.LoadedPlayerProfiles) do
		local activePhysicsDetectionFlag = playerProfile:GetCurrentActivePhysicsDetectionFlag()
		if activePhysicsDetectionFlag then
			playerProfile.DetectionData[activePhysicsDetectionFlag].FlagExpireDt = 0
			playerProfile.OnPhysicsDetectionFlagExpire:Fire()
		end
	end

	PlayerProfileService.DestroyLoadedPlayerProfiles()
	Server._cleanupDetections()
	DestroyAll(Server, Maid.IsMaid)

	return nil
end

function Server._init()
	Server._initDetections()
	Server._initSignals()

	return nil
end

function Server._initSignals()
	-- Don't init signals unnecessarily if no physics detections were available to start
	-- as these signals depend on the physics detections:
	if not Server._arePhysicsDetectionsInit then
		return nil
	end

	InitMaidFor(Server, Server._maid, Signal.IsSignal)

	-- Track newly loaded player profiles and start
	-- heartbeat update ONLY if a new player profile is loaded, This is to prevent
	-- an unnecessary heartbeat event running:

	PlayerProfileService.OnPlayerProfileInit:Connect(function(playerProfile)
		Server.MonitoringPlayerProfiles[playerProfile.Player] = playerProfile

		if
			Server._heartBeatScriptConnection
			and Server._heartBeatScriptConnection.Connected
		then
			return nil
		end

		Server._heartBeatScriptConnection = Server._startHeartBeatUpdate()
	end)

	PlayerProfileService.OnPlayerProfileDestroyed:Connect(function(player)
		Server.MonitoringPlayerProfiles[player] = nil

		if not Server.AreMonitoringPlayerProfilesLeft() then
			return nil
		end

		if
			Server._heartBeatScriptConnection and Server._heartBeatScriptConnection.Connected
		then
			Server._heartBeatScriptConnection:Disconnect()
		end
	end)

	if PlayerProfileService.ArePlayerProfilesLoaded() then
		Server._heartBeatScriptConnection = Server._startHeartBeatUpdate()
	end

	return nil
end

function Server._isPlayerBlackListedFromBeingMonitored(player)
	return Config.PlayersBlackListedFromBeingMonitored[player.UserId]
		and not Server.IsPlayerGameOwner(player)
end

function Server._startHeartBeatUpdate()
	local VerticalSpeed = require(script.Detections.Physics.VerticalSpeed)
	local HorizontalSpeed = require(script.Detections.Physics.HorizontalSpeed)

	return Server._maid:AddTask(RunService.Heartbeat:Connect(function(dt)
		Server._heartBeatUpdate(dt, VerticalSpeed, HorizontalSpeed)
	end))
end

function Server._cleanupDetections()
	for _, detection in pairs(Server._detectionsInit.NonPhysics) do
		require(detection).Cleanup()
	end

	for _, detection in pairs(Server._detectionsInit.Physics) do
		require(detection).Cleanup()
	end

	return nil
end

function Server._initDetections()
	for _, module in ipairs(script.Detections.Physics:GetChildren()) do
		local requiredModule = require(module)

		if not requiredModule.Enabled then
			continue
		end

		requiredModule.Init()

		Server._arePhysicsDetectionsInit = true
		Server._detectionsInit.Physics[module.Name] = module
	end

	for _, module in ipairs(script.Detections.NonPhysics:GetChildren()) do
		local requiredModule = require(module)

		if not requiredModule.Enabled then
			continue
		end

		requiredModule.Init()
		Server._detectionsInit.NonPhysics[module.Name] = module
	end

	return nil
end

function Server._heartBeatUpdate(dt, verticalSpeed, horizontalSpeed)
	-- Loop through all loaded profiles and perform physics exploit detections:
	for _, playerProfile in pairs(Server.MonitoringPlayerProfiles) do
		local player = playerProfile.Player
		local primaryPart = player.Character.PrimaryPart

		for detectionName, detection in pairs(Server._detectionsInit.Physics) do
			detection = require(detection)

			local detectionData = playerProfile.DetectionData[detectionName]
			local physicsData = detectionData.PhysicsData
			local lastCFrame = physicsData.LastCFrame

			detectionData.LastStartDt += dt

			local lastStartDt = detectionData.LastStartDt
			local shouldStartDetection = true

			if lastStartDt >= detection.StartInterval then
				if lastCFrame then
					-- Safe check to avoid false positives:
					if
						Util.IsBasePartFalling(primaryPart, lastCFrame.Position)
							and detection == verticalSpeed
						or not Util.IsPlayerWalking(player, lastCFrame.Position)
							and detection == horizontalSpeed
					then
						shouldStartDetection = false
					end

					if shouldStartDetection then
						detection.Start(detectionData, playerProfile, lastStartDt)
					end
				end

				detectionData.LastStartDt = 0
				physicsData.LastCFrame = primaryPart.CFrame
			end
		end
	end

	return nil
end

function Server._setPlayerPrimaryNetworkOwner(player)
	local primaryPart = player.Character and player.Character.PrimaryPart
	if not primaryPart then
		return nil
	end

	Util.SetBasePartNetworkOwner(player.Character.PrimaryPart, player)

	return nil
end

function Server._startNonPhysicsDetections(playerProfile)
	for _, detection in pairs(Server._detectionsInit.NonPhysics) do
		require(detection).Start(playerProfile)
	end

	return nil
end

function Server._getPlayerRankInGroup(player, groupId)
	local wasSuccessFull, response = RetryPcall(
		LocalConstants.MaxFailedPcallTries,
		LocalConstants.FailedPcallRetryInterval,

		{
			player.GetRankInGroup,
			player,
			groupId,
		}
	)

	if not wasSuccessFull then
		warn(
			("%s: Failed to get %s's group rank because %s"):format(
				SharedConstants.FormattedOutputMessages.Octagon.Debug,
				player.Name,
				response
			)
		)

		return LocalConstants.DefaultPlayerGroupRank
	else
		return response
	end
end

function Server._initModules()
	Server._areModulesInit = true

	for _, child in ipairs(script:GetChildren()) do
		Server[child.Name] = child
	end

	for _, child in ipairs(script.Parent:GetChildren()) do
		if child.Name ~= "Server" then
			Server[child.Name] = child
		end
	end

	return nil
end

if not Server._areModulesInit then
	Server._initModules()
end

return Server
