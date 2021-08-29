-- SilentsReplacement
-- HorizontalSpeed
-- July 18, 2021

--[[
    HorizontalSpeed.Leeway : number
    HorizontalSpeed.StartInterval : number
    HorizontalSpeed.PlayerDetectionFlagExpireInterval : number
    HorizontalSpeed.LeewayMultiplier : number
    HorizontalSpeed.Enabled : boolean

	HorizontalSpeed.Cleanup() --> nil []
	HorizontalSpeed.Init() --> nil []
    HorizontalSpeed.Start(
        detectionData : table
        playerProfile : PlayerProfile
        dt : number
    ) --> nil []
]]

local HorizontalSpeed = {
	Leeway = 8,
	StartInterval = 0.3,
	PlayerDetectionFlagExpireInterval = 4,
	LeewayMultiplier = 1.3,
	Enabled = true,
}

local Octagon = require(script:FindFirstAncestor("Octagon"))
local Util = require(Octagon.Shared.Util)
local SharedConstants = require(Octagon.Shared.SharedConstants)
local Signal = require(Octagon.Shared.Signal)
local Maid = require(Octagon.Shared.Maid)
local InitMaidFor = require(Octagon.Shared.InitMaidFor)
local DestroyAllMaids = require(Octagon.Shared.DestroyAllMaids)

HorizontalSpeed._onPlayerDetection = Signal.new()
HorizontalSpeed._maid = Maid.new()

function HorizontalSpeed.Start(detectionData, playerProfile, dt)
	-- Calculate average horizontal speed per mutliple frames and compare it
	-- to the maximum possible and flag the player accordingly:
	local lastCFrame = detectionData.PhysicsData.LastCFrame
	local averageHorizontalSpeed = HorizontalSpeed._calculateAverageSpeed(
		playerProfile.Player.Character.PrimaryPart.Position,
		lastCFrame.Position,
		dt
	)

	if averageHorizontalSpeed > playerProfile.PhysicsThresholds.HorizontalSpeed then
		HorizontalSpeed._onPlayerDetection:Fire(playerProfile, lastCFrame)
	end

	return nil
end

function HorizontalSpeed.Cleanup()
	DestroyAllMaids(HorizontalSpeed)

	return nil
end

function HorizontalSpeed.Init()
	HorizontalSpeed._initSignals()

	return nil
end

function HorizontalSpeed._calculateAverageSpeed(currentPosition, lastPosition, dt)
	return math.floor(
		(
			currentPosition * SharedConstants.Vectors.XZ
			- lastPosition * SharedConstants.Vectors.XZ
		).Magnitude / dt
	)
end

function HorizontalSpeed._initSignals()
	InitMaidFor(HorizontalSpeed, HorizontalSpeed._maid, Signal.IsSignal)
	
	HorizontalSpeed._onPlayerDetection:Connect(function(playerProfile, lastCFrame)
		local player = playerProfile.Player
		local primaryPart = player.Character.PrimaryPart

		playerProfile:RegisterPhysicsDetectionFlag("HorizontalSpeed", "HighHorizontalSpeed")

		-- Zero out the player's velocity on the XZ axis to have them immediately
		-- stop moving:
		primaryPart.AssemblyLinearVelocity *= SharedConstants.Vectors.Y
		primaryPart.CFrame = lastCFrame

		-- Temporarily have the server handle physics
		-- for the player, which means the player can't do
		-- any physics exploits but results in jerky movement
		Util.SetBasePartNetworkOwner(primaryPart, nil)
	end)

	return nil
end

return HorizontalSpeed
