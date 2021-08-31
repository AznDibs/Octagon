-- SilentsReplacement
-- PlayerProfile
-- August 07, 2021

--[[
    PlayerProfile.new() --> PlayerProfile []
    PlayerProfile.IsPlayerProfile(self : any) --> boolean [IsPlayerProfile]

    -- Only when accessed from an object returned by PlayerProfile.new:

    PlayerProfile.OnPhysicsDetectionFlag : Signal (detectionFlag : string)
    PlayerProfile.OnPhysicsDetectionFlagExpire : Signal (expiredDetectionFlag : string)
    PlayerProfile.Player : Player
    PlayerProfile.Maid : Maid
	PlayerProfile.OnInit : Signal ()
    PlayerProfile.DetectionMaid : Maid
    PlayerProfile.PhysicsDetectionFlagsHistory : table
    PlayerProfile.PhysicsDetectionFlags : number
    
	PlayerProfile:IncrementPhysicsThreshold(physicsThreshold : string, thresholdIncrement : number) --> nil []
	PlayerProfile:DecrementPhysicsThreshold(physicsThreshold : string, thresholdDecrement : number) --> nil []
    PlayerProfile:RegisterPhysicsDetectionFlag(detection : string, flag : string) --> nil []
	PlayerProfile:GetPhysicsThresholdIncrement(physicsThreshold : string) --> number [thresholdIncrement]
    PlayerProfile:IsDestroyed() --> boolean [IsDestroyed]
    PlayerProfile:Destroy() --> nil []
    PlayerProfile:Init() --> nil []
    PlayerProfile:IsInit() --> boolean [IsInit]
    PlayerProfile:GetCurrentActivePhysicsDetectionFlag() --> string | nil [physicsDetectionFlag]
]]

local PlayerProfile = {}
PlayerProfile.__index = PlayerProfile

local Workspace = game:GetService("Workspace")

local Octagon = script:FindFirstAncestor("Octagon")
local Signal = require(Octagon.Shared.Signal)
local Maid = require(Octagon.Shared.Maid)
local DestroyAllMaids = require(Octagon.Shared.DestroyAllMaids)
local InitMaidFor = require(Octagon.Shared.InitMaidFor)
local PlayerProfileService = require(script.Parent)
local SharedConstants = require(Octagon.Shared.SharedConstants)

local LocalConstants = {
	MaxServerFps = 60,
	AdditionalVerticalSpeedLeeway = 12,
	MinPhysicsThreshold = 0,
	MaxPhysicsThreshold = math.huge,
	MinPhysicsThresholdIncrement = 0,
	MaxPhysicsThresholdIncrement = math.huge,

	AlwaysAvailableMethods = {
		"IsDestroyed",
	},
}

function PlayerProfile.IsPlayerProfile(self)
	return typeof(self) == "table" and self._isPlayerProfile
end

function PlayerProfile.new(player)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerProfile.new()",
			"a player object",
			typeof(player)
		)
	)

	assert(
		not PlayerProfileService.LoadedPlayerProfiles[player],
		"Can't create new player profile class for the same player!"
	)

	local self = setmetatable({
		Maid = Maid.new(),
		DetectionMaid = Maid.new(),
		Player = player,
		DetectionData = {},
		PhysicsThresholds = {
			HorizontalSpeed = 0,
			VerticalSpeed = 0,
		},
		PhysicsDetectionFlagsHistory = {},
		OnPhysicsDetectionFlag = Signal.new(),
		OnPhysicsDetectionFlagExpire = Signal.new(),
		OnInit = Signal.new(),
		PhysicsDetectionFlagCount = 0,
		_isPlayerProfile = true,
		_isInit = false,
		_isDestroyed = false,
		_physicsThresholdIncrements = {},
	}, PlayerProfile)

	InitMaidFor(self, self.Maid, Signal.IsSignal)
	PlayerProfileService.LoadedPlayerProfiles[player] = self
	PlayerProfileService.OnPlayerProfileLoaded:Fire(self)

	return self
end

function PlayerProfile:IsDestroyed()
	return self._isDestroyed
end

function PlayerProfile:Destroy()
	local player = self.Player

	self:_cleanup()
	self._isDestroyed = true

	setmetatable(self, {
		__index = function(_, key)
			if typeof(PlayerProfile[key]) == "function" then
				local availableMethodIndex = table.find(
					LocalConstants.AlwaysAvailableMethods,
					key
				)

				assert(
					availableMethodIndex,
					("Can only call methods [%s] as profile is destroyed"):format(
						table.concat(LocalConstants.AlwaysAvailableMethods)
					)
				)

				return PlayerProfile[key]
			end

			return nil
		end,
	})

	PlayerProfileService.OnPlayerProfileDestroyed:Fire(player)

	return nil
end

function PlayerProfile:IsInit()
	return self._isInit
end

function PlayerProfile:Init(physicsDetections)
	assert(not self:IsInit(), "Cannot init player profile if it is already init")
	assert(
		typeof(physicsDetections) == "table",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerProfile:Init()",
			"table",
			typeof(physicsDetections)
		)
	)

	self:_initPhysicsDetectionData(physicsDetections)
	self:_initPhysicsThresholds(physicsDetections)

	self._isInit = true
	PlayerProfileService.OnPlayerProfileInit:Fire(self)
	self.OnInit:Fire()

	return nil
end

function PlayerProfile:IncrementPhysicsThreshold(physicsThreshold, thresholdIncrement)
	assert(
		typeof(physicsThreshold) == "string",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerProfile:IncrementPhysicsThreshold()",
			"string",
			typeof(physicsThreshold)
		)
	)

	assert(
		typeof(thresholdIncrement) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			2,
			"PlayerProfile:IncrementPhysicsThreshold()",
			"number",
			typeof(thresholdIncrement)
		)
	)

	self.PhysicsThresholds[physicsThreshold] += thresholdIncrement
	self._physicsThresholdIncrements[physicsThreshold] += thresholdIncrement

	return nil
end

function PlayerProfile:DecrementPhysicsThreshold(physicsThreshold, thresholdDecrement)
	assert(
		typeof(physicsThreshold) == "string",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerProfile:DecrementPhysicsThreshold()",
			"string",
			typeof(physicsThreshold)
		)
	)

	assert(
		typeof(thresholdDecrement) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			2,
			"PlayerProfile:DecrementPhysicsThreshold()",
			"number",
			typeof(thresholdDecrement)
		)
	)

	assert(self.PhysicsThresholds[physicsThreshold], "Invalid physics threshold")

	self.PhysicsThresholds[physicsThreshold] = math.clamp(
		self.PhysicsThresholds[physicsThreshold] - thresholdDecrement,
		LocalConstants.MinPhysicsThreshold,
		LocalConstants.MaxPhysicsThreshold
	)

	self._physicsThresholdIncrements[physicsThreshold] = math.clamp(
		self._physicsThresholdIncrements[physicsThreshold] - thresholdDecrement,
		LocalConstants.MinPhysicsThresholdIncrement,
		LocalConstants.MaxPhysicsThresholdIncrement
	)

	return nil
end

function PlayerProfile:RegisterPhysicsDetectionFlag(detection, flag)
	assert(
		typeof(detection) == "string",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerProfile:RegisterPhysicsDetectionFlag()",
			"string",
			typeof(detection)
		)
	)

	assert(
		typeof(flag) == "string",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			2,
			"PlayerProfile:RegisterPhysicsDetectionFlag()",
			"string",
			typeof(flag)
		)
	)

	local detections = script:FindFirstAncestor("Server").Detections
	local physicsDetectionModule = detections.Physics:FindFirstChild(detection)
		and require(detections.Physics[detection])
   
	assert(
		physicsDetectionModule or detections.NonPhysics:FindFirstChild(detection),
		"Invalid detection"
	)

	if physicsDetectionModule then
		local detectionData = self.DetectionData[detection]

		detectionData.FlagExpireDt = physicsDetectionModule.PlayerDetectionFlagExpireInterval

		task.spawn(function()
			while detectionData.FlagExpireDt > 0 do
				detectionData.FlagExpireDt -= task.wait(1)
			end

			-- Prevent edge case where the player profile was
			-- destroyed while this loop is running. This happens
			-- when the player immediately leaves after being flagged
			-- by a physics detection:
			if self:IsDestroyed() then
				return nil
			end

			detectionData.FlagExpireDt = 0
			self.OnPhysicsDetectionFlagExpire:Fire(flag)
		end)
	end

	self.PhysicsDetectionFlagCount += 1
	table.insert(self.PhysicsDetectionFlagsHistory, flag)
	self.OnPhysicsDetectionFlag:Fire(flag)

	return nil
end

function PlayerProfile:SetDeinitTag()
	self._isInit = false

	return nil
end

function PlayerProfile:GetCurrentActivePhysicsDetectionFlag()
	for detection, detectionData in pairs(self.DetectionData) do
		if detectionData.FlagExpireDt > 0 then
			return detection
		end
	end

	return nil
end

function PlayerProfile:GetPhysicsThresholdIncrement(physicsThreshold)
	assert(
		typeof(physicsThreshold) == "string",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerProfile:GetPhysicsThresholdIncrement()",
			"string",
			typeof(physicsThreshold)
		)
	)

	return self._physicsThresholdIncrements[physicsThreshold]
end

function PlayerProfile:_cleanup()
	DestroyAllMaids(self)
	self.Player = nil

	return nil
end

function PlayerProfile:_initPhysicsDetectionData(physicsDetections)
	-- Setup detection data:
	for detectionName, detection in pairs(physicsDetections) do
		detection = require(detection)

		local physicsData = {
			LastCFrame = nil,
			RaycastParams = nil,
		}

		-- Setup ray cast params for no clip detection:
		if detectionName == "NoClip" then
			local rayCastParams = RaycastParams.new()
			rayCastParams.FilterDescendantsInstances = { self.Player.Character }
			rayCastParams.IgnoreWater = true
			physicsData.RaycastParams = rayCastParams
		end

		local detectionData = self.DetectionData[detectionName]
		local lastStartDt = detectionData and detectionData.LastStartDt
		local flagExpireDt = detectionData and detectionData.FlagExpireDt

		self.DetectionData[detectionName] = {
			DetectionDataTag = true,
			LastStartDt = lastStartDt or 0,
			FlagExpireDt = flagExpireDt or 0,
			PhysicsData = physicsData,
			PlayerDetectionExpireInterval = detection.PlayerDetectionExpireInterval,
		}
	end

	return nil
end

function PlayerProfile:_updateAllDetectionPhysicsData(key, value)
	for _, detectionData in pairs(self.DetectionData) do
		detectionData.PhysicsData[key] = value
	end

	return nil
end

function PlayerProfile:_initPhysicsThresholds(physicsDetections)
	local Server = require(script:FindFirstAncestor("Server"))

	local player = self.Player
	local humanoid = player.Character.Humanoid
	local primaryPart = player.Character.PrimaryPart

	if next(physicsDetections) ~= nil then
		for detectionName, _ in pairs(physicsDetections) do
			self._physicsThresholdIncrements[detectionName] = self._physicsThresholdIncrements[detectionName]
				or 0
			self.PhysicsThresholds[detectionName] = 0
		end

		self.Maid:AddTask(primaryPart:GetPropertyChangedSignal("CFrame"):Connect(function()
			self:_updateAllDetectionPhysicsData("LastCFrame", primaryPart.CFrame)
		end))

		self.Maid:AddTask(primaryPart:GetPropertyChangedSignal("Parent"):Connect(function()
			Server.TemporarilyBlacklistPlayerFromBeingMonitored(player, player.CharacterAdded)
		end))

		self.Maid:AddTask(
			primaryPart:GetPropertyChangedSignal("AssemblyLinearVelocity"):Connect(function()
				Server.TemporarilyBlacklistPlayerFromBeingMonitored(player, function()
					task.wait(primaryPart.AssemblyLinearVelocity.Magnitude / Workspace.Gravity)
				end)
			end)
		)

		self.Maid:AddTask(humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
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
		end))
	end

	if physicsDetections.VerticalSpeed ~= nil then
		local VerticalSpeed = require(physicsDetections.VerticalSpeed)

		local function ComputeMaxVerticalSpeed(jumpPower, thresholdIncrement)
			local verticalSpeedLeeway = VerticalSpeed.Leeway / 100

			return jumpPower
				+ math.sqrt(jumpPower * VerticalSpeed.LeewayMultiplier) * VerticalSpeed.LeewayMultiplier
				+ VerticalSpeed.LeewayMultiplier * (LocalConstants.MaxServerFps * verticalSpeedLeeway)
				+ thresholdIncrement
				+ LocalConstants.AdditionalVerticalSpeedLeeway
		end

		local function ComputeJumpPowerFromJumpHeight(jumpHeight)
			return math.sqrt(2 * Workspace.Gravity * jumpHeight)
		end

		self.PhysicsThresholds.VerticalSpeed = ComputeMaxVerticalSpeed(
			humanoid.UseJumpPower and humanoid.JumpPower
				or ComputeJumpPowerFromJumpHeight(humanoid.JumpHeight),
			self._physicsThresholdIncrements.VerticalSpeed
		)

		self.Maid:AddTask(humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
			self.PhysicsThresholds.VerticalSpeed = ComputeMaxVerticalSpeed(
				humanoid.JumpPower,
				self._physicsThresholdIncrements.VerticalSpeed
			)
		end))

		self.Maid:AddTask(humanoid:GetPropertyChangedSignal("JumpHeight"):Connect(function()
			self.PhysicsThresholds.VerticalSpeed = ComputeMaxVerticalSpeed(
				ComputeJumpPowerFromJumpHeight(humanoid.JumpHeight),
				self._physicsThresholdIncrements.VerticalSpeed
			)
		end))
	end

	if physicsDetections.HorizontalSpeed ~= nil then
		local HorizontalSpeed = require(physicsDetections.HorizontalSpeed)

		local function ComputeMaxHorizontalSpeed(horizontalSpeed, thresholdIncrement)
			local horizontalSpeedLeeway = HorizontalSpeed.Leeway / 100

			return horizontalSpeed
				+ math.sqrt(horizontalSpeed * HorizontalSpeed.LeewayMultiplier) * HorizontalSpeed.LeewayMultiplier
				+ HorizontalSpeed.LeewayMultiplier * (LocalConstants.MaxServerFps * horizontalSpeedLeeway)
				+ thresholdIncrement
		end

		self.PhysicsThresholds.HorizontalSpeed = ComputeMaxHorizontalSpeed(
			humanoid.WalkSpeed,
			self._physicsThresholdIncrements.HorizontalSpeed
		)

		self.Maid:AddTask(humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			self.PhysicsThresholds.HorizontalSpeed = ComputeMaxHorizontalSpeed(
				humanoid.WalkSpeed,
				self._physicsThresholdIncrements.HorizontalSpeed
			)
		end))
	end
end

return PlayerProfile
