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
    Server.BlacklistNoClipMonitoringPartsForPlayer(player : Player, parts : table) --> nil []
    Server.UnBlacklistNoClipMonitoringPartsForPlayer(player : Player, parts : table) --> nil []
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
}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local PlayerProfileService = require(script.PlayerProfileService)
local PlayerProfile = require(PlayerProfileService.PlayerProfile)
local Signal = require(script.Parent.Shared.Signal)
local Maid = require(script.Parent.Shared.Maid)
local Config = require(script.Config)
local SharedConstants = require(script.Parent.Shared.SharedConstants)
local DestroyAllMaids = require(script.Parent.Shared.DestroyAllMaids)
local InitMaidFor = require(script.Parent.Shared.InitMaidFor)
local Util = require(script.Parent.Shared.Util)

Server._maid = Maid.new()
Server._onStop = Signal.new()

function Server.AreMonitoringPlayerProfilesLeft()
	return next(Server.MonitoringPlayerProfiles) ~= nil
end

function Server.TemporarilyBlacklistPlayerFromBeingMonitored(player, value)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Octagon.TemporarilyBlacklistPlayerFromBeingMonitored()",
			"Player",
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
			typeof(value)
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

	local onStopConnection = nil
	onStopConnection = Server._onStop:Connect(function()
		Server._setPlayerPrimaryNetworkOwner(player)
	end)

	task.spawn(function()
		if typeof(value) == "RBXScriptSignal" or Signal.IsSignal(value) then
			value:Wait()
		elseif typeof(value) == "function" then
			value()
		else
			task.wait(value)
		end

		onStopConnection:Disconnect()

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

function Server.BlacklistNoClipMonitoringPartsForPlayer(player, parts)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Octagon.BlacklistNoClipMonitoringPartsForPlayer()",
			"Player",
			typeof(player)
		)
	)

	assert(
		typeof(parts) == "table",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			2,
			"Octagon.BlacklistNoClipMonitoringPartsForPlayer()",
			"table",
			typeof(parts)
		)
	)

	for _, part in ipairs(parts) do
		if not part:IsA("Instance") then
			continue
		end

		CollectionService:AddTag(
			part,
			SharedConstants.Tags.NoClipBlackListed:format(player.Name)
		)
	end

	return nil
end

function Server.UnBlacklistNoClipMonitoringPartsForPlayer(player, parts)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Octagon.UnBlacklistNoClipMonitoringPartsForPlayer()",
			"Player",
			typeof(player)
		)
	)
	assert(
		typeof(parts) == "table",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Server.UnBlacklistNoClipMonitoringPartsForPlayer()",
			"table",
			typeof(parts)
		)
	)

	for _, part in ipairs(parts) do
		if not part:IsA("Instance") then
			continue
		end

		CollectionService:RemoveTag(
			part,
			SharedConstants.Tags.NoClipBlackListed:format(player.Name)
		)
	end

	return nil
end

function Server.Start()
	assert(not Server.IsStopped(), "Can't start Octagon as Octagon is stopped")
	assert(not Server.IsStarted(), "Can't start Octagon as Octagon is already started")

	Server._isStarted = true
	Server._init()

	print(("%s: Started"):format(SharedConstants.FormattedOutputMessages.Octagon.Log))

	do
		local function PlayerAdded(player)
			-- Do not create a player profile if there are no detections available
			-- or if the player is black listed from being monitored:
			if not Util.IsPlayerSubjectToBeMonitored(player) then
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

				if not Util.DoValidPlayerBodyPartsExist(player) then
					player:LoadCharacter()
					return nil
				end

				-- Setup a tag to know if a certain part is a primary part if
				-- character.PrimaryPart is nil. This is used in primary part deletion
				-- where we can't determine if the part deleted was a primary part or not:
				CollectionService:AddTag(
					character.PrimaryPart,
					SharedConstants.Tags.PrimaryPart
				)

				Server._initPlayer(playerProfile)
				Server._startNonPhysicsDetectionsForPlayer(playerProfile)
				Server.TemporarilyBlacklistPlayerFromBeingMonitored(player, function()
					playerProfile:SetDeinitTag()
					playerProfile:Init(Server._detectionsInit.Physics)
				end)

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
			else
				playerProfile:Destroy()
			end

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
		if activePhysicsDetectionFlag ~= nil then
			playerProfile.DetectionData[activePhysicsDetectionFlag].FlagExpireDt = 0
			playerProfile.OnPhysicsDetectionFlagExpire:Fire()
		end
	end

	PlayerProfileService.DestroyLoadedPlayerProfiles()
	PlayerProfileService.Cleanup()
	Server._cleanupDetections()
	DestroyAllMaids(Server)

	return nil
end

function Server._init()
	if Server._initDetections() then
		Server._initSignals()
		PlayerProfileService.Init()
	end
	
	return nil
end

function Server._initSignals()
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
			return
		end

		Server._heartBeatScriptConnection = Server._startHeartBeatUpdate()
	end)

	PlayerProfileService.OnPlayerProfileDestroyed:Connect(function(player)
		Server.MonitoringPlayerProfiles[player] = nil

		if Server.AreMonitoringPlayerProfilesLeft() then
			return
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
	return Server._maid:AddTask(RunService.Heartbeat:Connect(function(dt)
		Server._heartBeatUpdate(
			dt,
			script.Detections.Physics.VerticalSpeed,
			script.Detections.Physics.HorizontalSpeed
		)
	end))
end

function Server._cleanupDetections()
	for _, module in pairs(Server._detectionsInit.NonPhysics) do
		require(module).Cleanup()
	end

	for _, module in pairs(Server._detectionsInit.Physics) do
		require(module).Cleanup()
	end

	return nil
end

function Server._initDetections()
	local areDetectionsInit = false

	for _, module in ipairs(script.Detections.Physics:GetChildren()) do
		local requiredModule = require(module)

		if not requiredModule.Enabled then
			continue
		end

		areDetectionsInit = true
		requiredModule.Init()

		Server._arePhysicsDetectionsInit = true
		Server._detectionsInit.Physics[module.Name] = module
	end

	for _, module in ipairs(script.Detections.NonPhysics:GetChildren()) do
		local requiredModule = require(module)

		if not requiredModule.Enabled then
			continue
		end

		areDetectionsInit = true
		requiredModule.Init()
		Server._detectionsInit.NonPhysics[module.Name] = module
	end

	return areDetectionsInit
end

function Server._heartBeatUpdate(dt, verticalSpeed, horizontalSpeed)
	-- Loop through all loaded profiles and perform physics exploit detections:
	for _, playerProfile in pairs(Server.MonitoringPlayerProfiles) do
		local player = playerProfile.Player
		local primaryPart = player.Character.PrimaryPart

		for detection, module in pairs(Server._detectionsInit.Physics) do
			local requiredModule = require(module)

			local detectionData = playerProfile.DetectionData[detection]
			local physicsData = detectionData.PhysicsData
			local lastCFrame = physicsData.LastCFrame

			detectionData.LastStartDt += dt

			local lastStartDt = detectionData.LastStartDt
			local shouldStartDetection = true

			if lastStartDt >= requiredModule.StartInterval then
				if lastCFrame ~= nil then
					-- Safe check to avoid false positives:
					if
						Util.IsBasePartFalling(primaryPart, lastCFrame.Position)
							and module == verticalSpeed
						or not Util.IsPlayerWalking(player, lastCFrame.Position)
							and module == horizontalSpeed
					then
						shouldStartDetection = false
					end

					if shouldStartDetection then
						requiredModule.Start(detectionData, playerProfile, lastStartDt)
					end
				end

				detectionData.LastStartDt = 0
				physicsData.LastCFrame = primaryPart.CFrame
			end
		end
	end

	return nil
end

function Server._initPlayer(playerProfile)
	local player = playerProfile.Player
	local primaryPart = player.Character.PrimaryPart
	local humanoid = player.Character.Humanoid

	if Server._arePhysicsDetectionsInit then
		playerProfile.Maid:AddTask(
			primaryPart:GetPropertyChangedSignal("CFrame"):Connect(function()
				playerProfile:_updateAllDetectionPhysicsData("LastCFrame", primaryPart.CFrame)
			end)
		)

		playerProfile.Maid:AddTask(
			primaryPart:GetPropertyChangedSignal("Parent"):Connect(function()
				Server.TemporarilyBlacklistPlayerFromBeingMonitored(
					player,
					player.CharacterAdded
				)
			end)
		)

		playerProfile.Maid:AddTask(
			primaryPart:GetPropertyChangedSignal("AssemblyLinearVelocity"):Connect(function()
				Server.TemporarilyBlacklistPlayerFromBeingMonitored(player, function()
					task.wait(primaryPart.AssemblyLinearVelocity.Magnitude / Workspace.Gravity)
				end)
			end)
		)

		playerProfile.Maid:AddTask(
			humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
				if not humanoid.SeatPart then
					return
				end

				-- Player is in seat, temporarily black list the player once they get out to
				-- prevent horizontal / vertical speed false positive:
				Server.TemporarilyBlacklistPlayerFromBeingMonitored(player, function()
					humanoid.SeatPart:GetPropertyChangedSignal("Occupant"):Wait()
					-- Player has got out of the seat, but yield for a second before
					-- finishing execution to prevent physics detections from immediately
					-- starting. This prevents false positives when a player gets out of a
					-- seat quickly:
					task.wait(1)
				end)
			end)
		)
	end
end

function Server._setPlayerPrimaryNetworkOwner(player)
	local primaryPart = player.Character and player.Character.PrimaryPart
	if not primaryPart then
		return nil
	end

	Util.SetBasePartNetworkOwner(primaryPart, player)

	return nil
end

function Server._startNonPhysicsDetectionsForPlayer(playerProfile)
	for _, module in pairs(Server._detectionsInit.NonPhysics) do
		require(module).Start(playerProfile)
	end

	return nil
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
