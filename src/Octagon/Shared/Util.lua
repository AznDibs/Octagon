-- SilentsReplacement
-- Util
-- July 20, 2021

--[[
    Util.HasBasePartFallenToVoid(basePart : BasePart) --> boolean [HasBasePartFallenToVoid]
    Util.IsInstanceDestroyed(instance : Instance], lastPosition : Vector3) --> boolean [IsInstanceDestroyed]
    Util.IsPlayerWalking(player : Player, lastPosition : Vector3) --> boolean [IsPlayerWalking]
    Util.IsBasePartFalling(basePart : basePart, lastPosition : Vector3) --> boolean [IsBasePartFalling]
    Util.DoValidPlayerBodyPartsExist(player : Player) --> boolean [DoValidPlayerBodyPartsExist]
    Util.SetBasePartNetworkOwner(basePart : BasePart, networkOwner : player | nil) --> nil []
    Util.GetBasePartNetworkOwner(basePart : BasePart) --> Player | nil [BasePartNetworkOwner]
    Util.GetPlayerEquippedTools(player : Player) --> table [equippedTools], number [equippedToolCount]
]]

local Util = {}

local Workspace = game:GetService("Workspace")

local SharedConstants = require(script:FindFirstAncestor("Octagon").Shared.SharedConstants)

local LocalConstants = { PlayerMinWalkingDistance = 0.125 }

function Util.GetPlayerEquippedTools(player)
	local equippedTools = {}
	local equippedToolsCount = 0

	for _, tool in ipairs(player.Character:GetChildren()) do
		if not tool:IsA("BackpackItem") then
			continue
		end

		equippedTools[tool] = tool
		equippedToolsCount += 1
	end

	return equippedTools, equippedToolsCount
end

function Util.GetBasePartNetworkOwner(basePart)
	if basePart.Anchored then
		return nil
	end

	return basePart:GetNetworkOwner()
end

function Util.SetBasePartNetworkOwner(basePart, networkOwner)
	local canSetNetworkOwnership, errorMessage = basePart:CanSetNetworkOwnership()

	if canSetNetworkOwnership then
		basePart:SetNetworkOwner(networkOwner)
	else
		warn(
			("%s: Cannot set network owner of base part [%s] because %s"):format(
				SharedConstants.FormattedOutputMessages.Util.Debug,
				basePart.Name,
				errorMessage
			)
		)
	end

	return nil
end

function Util.HasBasePartFallenToVoid(basePart)
	return basePart.Position.Y <= Workspace.FallenPartsDestroyHeight
end

function Util.IsBasePartFalling(basePart, lastPosition)
	return basePart.Position.Y < lastPosition.Y
end

function Util.IsPlayerWalking(player, lastPosition)
	if not player.Character then
		return false
	end

	return (
		player.Character.PrimaryPart.Position * SharedConstants.Vectors.XZ
		- lastPosition * SharedConstants.Vectors.XZ
	).Magnitude >= LocalConstants.PlayerMinWalkingDistance
end

function Util.DoValidPlayerBodyPartsExist(player)
	local character = player.Character

	if not character then
		return false
	end

	return (character.PrimaryPart and character:FindFirstChildWhichIsA("Humanoid")) ~= nil
end

function Util.IsInstanceDestroyed(instance)
	local _, response = pcall(function()
		instance.Parent = instance
	end)

	return response:match("locked") ~= nil
end

return Util
