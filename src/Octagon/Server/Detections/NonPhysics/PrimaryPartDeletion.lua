-- SilentsReplacement
-- PrimaryPartDeletion
-- July 26, 2021

--[[
    PrimaryPartDeletion.Enabled : boolean

	PrimaryPartDeletion.Init() --> nil []
    PrimaryPartDeletion.Start(playerProfile : PlayerProfile) --> nil []
    PrimaryPartDeletion.Cleanup() --> nil []
]]

local PrimaryPartDeletion = {
	Enabled = true,
}

local CollectionService = game:GetService("CollectionService")

local Shared = script:FindFirstAncestor("Octagon").Shared
local SharedConstants = require(Shared.SharedConstants)
local Util = require(Shared.Util)
local Signal = require(Shared.Signal)
local Maid = require(Shared.Maid)
local InitMaidFor = require(Shared.InitMaidFor)
local DestroyAllMaids = require(Shared.DestroyAllMaids)

PrimaryPartDeletion._onPlayerDetection = Signal.new()
PrimaryPartDeletion._maid = Maid.new()

function PrimaryPartDeletion.Init()
	PrimaryPartDeletion._initSignals()

	return nil
end

function PrimaryPartDeletion.Start(playerProfile)
	local player = playerProfile.Player
	local primaryPartParentChangedConnection = nil
	primaryPartParentChangedConnection = player.Character.PrimaryPart.ChildRemoved:Connect(
		function() end
	)

	local childRemovingConnection = player.Character.ChildRemoved:Connect(function(child)
		task.defer(function()
			if
				not CollectionService:HasTag(child, SharedConstants.Tags.PrimaryPart)
				or not primaryPartParentChangedConnection.Connected
				or Util.HasBasePartFallenToVoid(child)
			then
				return
			end

			PrimaryPartDeletion._onPlayerDetection:Fire(playerProfile)
		end)
	end)

	PrimaryPartDeletion._maid:AddTask(childRemovingConnection)
	PrimaryPartDeletion._maid:AddTask(primaryPartParentChangedConnection)
	playerProfile.DetectionMaid:AddTask(childRemovingConnection)
	playerProfile.DetectionMaid:AddTask(primaryPartParentChangedConnection)

	return nil
end

function PrimaryPartDeletion.Cleanup()
	DestroyAllMaids(PrimaryPartDeletion)

	return nil
end

function PrimaryPartDeletion._initSignals()
	InitMaidFor(PrimaryPartDeletion, PrimaryPartDeletion._maid, Signal.IsSignal)

	PrimaryPartDeletion._onPlayerDetection:Connect(function(playerProfile)
		playerProfile.Player:LoadCharacter()
	end)

	return nil
end

return PrimaryPartDeletion
