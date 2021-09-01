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
	Util.IsPlayerSubjectToBeMonitored(player : Player) --> boolean [IsPlayerSubjectToBeMonitored]
    Util.IsPlayerGameOwner(player : Player) --> boolean [IsPlayerGameOwner]
]]

local Util = {
	_shouldMonitorPlayerResultsCache = {},
	_isPlayerGameOwnerResultsCache = {},
}

local Workspace = game:GetService("Workspace")

local Octagon = script:FindFirstAncestor("Octagon")
local SharedConstants = require(Octagon.Shared.SharedConstants)
local Signal = require(Octagon.Shared.Signal)
local Config = require(Octagon.Server.Config)
local RetryPcall = require(Octagon.Shared.RetryPcall)

local LocalConstants = {
	FailedPcallRetryInterval = 5,
	MaxFailedPcallTries = 5,
	OwnerGroupRank = 255,
	DefaultPlayerGroupRank = 0,
	PlayerMinWalkingDistance = 0.125
}

function Util.IsPlayerGameOwner(player)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Util.IsPlayerGameOwner()",
			"Player",
			typeof(player)
		)
	)

	local cachedResult = Util._isPlayerGameOwnerResultsCache[player.UserId]

	-- If the cached result is a signal, that means that this method
	-- was called again while it was performing a lookup for the same
	-- argument, wait until that signal fires and return the results
	-- instead of performing an other unnecessary lookup. Else, return the
	-- result because we know it was already computed:
	if cachedResult ~= nil then
		if Signal.IsSignal(cachedResult) then
			return cachedResult:Wait()
		else
			return cachedResult
		end
	end

	local isPlayerGameOwner = false
	local onIsPlayerGameOwnerResult = Signal.new()
	Util._isPlayerGameOwnerResultsCache[player.UserId] = onIsPlayerGameOwnerResult

	if game.CreatorType == Enum.CreatorType.Group then
		isPlayerGameOwner = Util._getPlayerRankInGroup(player, game.CreatorId)
			== LocalConstants.OwnerGroupRank
	else
		isPlayerGameOwner = player.UserId == game.CreatorId
	end

	onIsPlayerGameOwnerResult:Fire(isPlayerGameOwner)
	onIsPlayerGameOwnerResult:Destroy()

	Util._isPlayerGameOwnerResultsCache[player.UserId] = isPlayerGameOwner

	return isPlayerGameOwner
end

function Util.IsPlayerSubjectToBeMonitored(player)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Util.IsPlayerSubjectToBeMonitored()",
			"Player",
			typeof(player)
		)
	)

	local cachedResult = Util._shouldMonitorPlayerResultsCache[player.UserId]

	-- If the cached result is a signal, that means that this method
	-- was called again while it was performing a lookup for the same
	-- argument, wait until that signal fires and return the results
	-- instead of performing an other unnecessary lookup. Else, return the
	-- result because we know it was already computed:
	if cachedResult ~= nil then
		if Signal.IsSignal(cachedResult) then
			return cachedResult:Wait()
		else
			return cachedResult
		end
	end

	local onShouldMonitorPlayerResult = Signal.new()
	Util._shouldMonitorPlayerResultsCache[player] = onShouldMonitorPlayerResult

	local isPlayerBlackListedFromBeingMonitored = Util._isPlayerBlackListedFromBeingMonitored(
		player
	)

	if not isPlayerBlackListedFromBeingMonitored then
		local isPlayerGameOwner = Util.IsPlayerGameOwner(player)

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

				local playerGroupRank = Util._getPlayerRankInGroup(player, groupId)

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

	local shouldMonitorPlayer = not isPlayerBlackListedFromBeingMonitored
	onShouldMonitorPlayerResult:Fire(shouldMonitorPlayer)
	onShouldMonitorPlayerResult:Destroy()

	-- Cache lookup result for later reuse:
	Util._shouldMonitorPlayerResultsCache[player.UserId] = shouldMonitorPlayer

	return shouldMonitorPlayer
end

function Util.GetPlayerEquippedTools(player)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Util.GetPlayerEquippedTools()",
			"Player",
			typeof(player)
		)
	)

	local equippedTools = {}
	local equippedToolCount = 0

	for _, tool in ipairs(player.Character:GetChildren()) do
		if not tool:IsA("BackpackItem") then
			continue
		end

		equippedTools[tool] = tool
		equippedToolCount += 1
	end

	return equippedTools, equippedToolCount
end

function Util.GetBasePartNetworkOwner(basePart)
	assert(
		typeof(basePart) == "Instance" and basePart:IsA("BasePart"),
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Util.GetBasePartNetworkOwner()",
			"BasePart",
			typeof(basePart)
		)
	)

	if basePart.Anchored then
		return nil
	end

	return basePart:GetNetworkOwner()
end

function Util.SetBasePartNetworkOwner(basePart, networkOwner)
	assert(
		typeof(basePart) == "Instance" and basePart:IsA("BasePart"),
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Util.SetBasePartNetworkOwner()",
			"BasePart",
			typeof(basePart)
		)
	)
	assert(
		typeof(networkOwner) == "Instance" and networkOwner:IsA("Player")
			or networkOwner == nil,
		SharedConstants.ErrorMessages.InvalidArgument:format(
			2,
			"Util.SetBasePartNetworkOwner()",
			"Player",
			typeof(networkOwner)
		)
	)

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
	assert(
		typeof(basePart) == "Instance" and basePart:IsA("BasePart"),
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Util.HasBasePartFallenToVoid()",
			"BasePart",
			typeof(basePart)
		)
	)

	return basePart.Position.Y <= Workspace.FallenPartsDestroyHeight
end

function Util.IsBasePartFalling(basePart, lastPosition)
	assert(
		typeof(basePart) == "Instance" and basePart:IsA("BasePart"),
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Util.IsBasePartFalling()",
			"BasePart",
			typeof(basePart)
		)
	)
	assert(
		typeof(lastPosition) == "Vector3",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			2,
			"Util.IsBasePartFalling()",
			"Vector3",
			typeof(basePart)
		)
	)

	return basePart.Position.Y < lastPosition.Y
end

function Util.IsPlayerWalking(player, lastPosition)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Util.IsPlayerWalking()",
			"Player",
			typeof(player)
		)
	)

	assert(
		typeof(lastPosition) == "Vector3",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			2,
			"Util.IsPlayerWalking()",
			"Vector3",
			typeof(lastPosition)
		)
	)

	if not player.Character then
		return false
	end

	return (
		player.Character.PrimaryPart.Position * SharedConstants.Vectors.XZ
		- lastPosition * SharedConstants.Vectors.XZ
	).Magnitude >= LocalConstants.PlayerMinWalkingDistance
end

function Util.DoValidPlayerBodyPartsExist(player)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Util.DoValidPlayerBodyPartsExist()",
			"Player",
			typeof(player)
		)
	)

	local character = player.Character

	if not character then
		return false
	end

	return (character.PrimaryPart and character:FindFirstChildWhichIsA("Humanoid")) ~= nil
end

function Util.IsInstanceDestroyed(instance)
	assert(
		typeof(instance) == "Instance",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Util.IsInstanceDestroyed()",
			"Instance",
			typeof(instance)
		)
	)

	local wasSuccessFull, response = pcall(function()
		instance.Parent = instance
	end)

	return not wasSuccessFull and response:match("locked") ~= nil
end

function Util._isPlayerBlackListedFromBeingMonitored(player)
	return Config.PlayersBlackListedFromBeingMonitored[player.UserId]
		and not Util.IsPlayerGameOwner(player)
end

function Util._getPlayerRankInGroup(player, groupId)
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
			("%s: Failed to get %s's group rank. Error: %s"):format(
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

return Util
