-- SilentsReplacement
-- NoClip
-- July 18, 2021

--[[
    NoClip.Leeway : number
    NoClip.StartInterval : number
    NoClip.PlayerDetectionFlagExpireInterval : number
    NoClip.LeewayMultiplier : number
    NoClip.Enabled : boolean

	NoClip.Cleanup --> nil []
	NoClip.Init() --> nil []
    NoClip.Start(
        detectionData : table 
        playerProfile : PlayerProfile
    ) --> nil []
]]

local NoClip = {
	Leeway = 2,
	StartInterval = 0.1,
	PlayerDetectionFlagExpireInterval = 4,
	LeewayMultiplier = 1,
	Enabled = true,
}

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Shared = script:FindFirstAncestor("Octagon").Shared
local Util = require(Shared.Util)
local SharedConstants = require(Shared.SharedConstants)
local Signal = require(Shared.Signal)
local Maid = require(Shared.Maid)
local InitMaidFor = require(Shared.InitMaidFor)
local DestroyAll = require(Shared.DestroyAll)

NoClip._maid = Maid.new()
NoClip._onPlayerDetection = Signal.new()

function NoClip.Init()
	NoClip._initSignals()

	return nil
end

function NoClip.Start(detectionData, playerProfile, _)
	local physicsData = detectionData.PhysicsData

	if NoClip._isNoClipping(playerProfile.Player, physicsData) then
		NoClip._onPlayerDetection:Fire(playerProfile, physicsData.LastCFrame)
	end

	return nil
end

function NoClip.Cleanup()
	DestroyAll(NoClip, Maid.IsMaid)

	return nil
end

function NoClip._isNoClipping(player, physicsData)
	local primaryPart = player.Character.PrimaryPart
	local lastCFrame = physicsData.LastCFrame
	local rayCastParams = physicsData.RaycastParams

	local lastCurrentPositionRay = Workspace:Raycast(
		lastCFrame.Position,
		primaryPart.Position - lastCFrame.Position,
		rayCastParams
	)

	if lastCurrentPositionRay then
		local instance = lastCurrentPositionRay.Instance
          
		-- Safe check to prevent fasle positives:
		if
			CollectionService:HasTag(instance, SharedConstants.Tags.NoClipBlackListed)
			or not primaryPart:CanCollideWith(instance)
		then
			return false
		end

		-- Cast a ray to determine if an legit player
		-- went extremely closely but not through an object:
		local currentLastPositionRay = Workspace:Raycast(
			primaryPart.Position,
			lastCFrame.Position - primaryPart.Position,
			rayCastParams
		)

		if currentLastPositionRay then
			-- Player walked through an object and outside, calculate
			-- depth to determine if it was an legit player or not.
			return (currentLastPositionRay.Position - lastCurrentPositionRay.Position).Magnitude
				>= NoClip.Leeway
		end

		-- Player simply entered the object and is staying there:
		return true
	end

	return false
end

function NoClip._initSignals()
	InitMaidFor(NoClip, NoClip._maid, Signal.IsSignal)
	
	NoClip._onPlayerDetection:Connect(function(playerProfile, lastCFrame)
		local primaryPart = playerProfile.Player.Character.PrimaryPart

		playerProfile:RegisterPhysicsDetectionFlag("NoClip", "NoClip")
		primaryPart.CFrame = lastCFrame

		-- Temporarily have the server handle physics
		-- for the player, which means the player can't do
		-- any physics exploits but results in jerky movement
		Util.SetBasePartNetworkOwner(primaryPart, nil)
	end)

	return nil
end

return NoClip
