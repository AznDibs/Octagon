-- SilentsReplacement
-- init
-- August 12, 2021

--[[
    Client.OnPlayerFling : Signal ()
    Client.OnPlayerHardGroundLand : Signal ()

    Client.Start() --> nil []
    Client.Stop() --> nil []
	Client.IsStarted() --> boolean [IsStarted]
	Client.IsStopped() --> boolean [IsStopped]
]]

local Client = {
	_isStarted = false,
	_isStopped = false,
	_areModulesInit = false,
}

local Players = game:GetService("Players")

local Shared = script:FindFirstAncestor("Octagon").Shared
local SharedConstants = require(Shared.SharedConstants)
local Signal = require(Shared.Signal)
local SafeWaitForChild = require(Shared.SafeWaitForChild)
local Maid = require(Shared.Maid)
local InitMaidFor = require(Shared.InitMaidFor)
local DestroyAllMaids = require(Shared.DestroyAllMaids)

local LocalConstants = { MinPlayerHardGroundLandYVelocity = 145 }

Client.OnPlayerFling = Signal.new()
Client.OnPlayerHardGroundLand = Signal.new()
Client._maid = Maid.new()

local localPlayer = Players.LocalPlayer

function Client.IsStarted()
	return Client._isStarted
end

function Client.IsStopped()
	return Client._isStopped
end

function Client.Start()
	assert(not Client.IsStopped(), "Can't start Octagon as Octagon is stopped")
	assert(not Client.IsStarted(), "Can't start Octagon as Octagon is already started")

	print(("%s: Started"):format(SharedConstants.FormattedOutputMessages.Octagon.Log))

	Client._isStarted = true
	Client._init()
	Client._trackHumanoidState(localPlayer.Character or localPlayer.CharacterAdded:Wait())

	-- Track humanoid state again whenever a new
	-- character is added so that the code works
	-- with the new character rather than working with the
	-- old one:
	Client._maid:AddTask(localPlayer.CharacterAdded:Connect(function(character)
		Client._trackHumanoidState(character)
	end))

	return nil
end

function Client.Stop()
	assert(not Client.IsStopped(), "Can't stop Octagon as Octagon is already stopped")
	assert(Client.IsStarted(), "Can't stop Octagon as Octagon isn't started")

	print(("%s: Stopped"):format(SharedConstants.FormattedOutputMessages.Octagon.Log))

	Client._isStopped = true
	Client._isStarted = false
	Client._cleanup()

	return nil
end

function Client._init()
	Client._initSignals()

	return nil
end
 
function Client._cleanup()
	DestroyAllMaids(Client)

	return nil
end

function Client._trackHumanoidState(character)
	local humanoid = SafeWaitForChild(character, "Humanoid")

	if not humanoid then
		return nil
	end

	humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Ragdoll then
			Client.OnPlayerFling:Fire()
		elseif
			newState == Enum.HumanoidStateType.Landed and localPlayer.Character.PrimaryPart
		then
			if
				math.abs(localPlayer.Character.PrimaryPart.AssemblyLinearVelocity.Y)
				>= LocalConstants.MinPlayerHardGroundLandYVelocity
			then
				Client.OnPlayerHardGroundLand:Fire()
			end
		end
	end)

	return nil
end

function Client._initModules()
	Client._areModulesInit = true

	script.Parent.Server:Destroy()

	for _, child in ipairs(script:GetChildren()) do
		Client[child.Name] = child
	end

	for _, child in ipairs(script.Parent:GetChildren()) do
		if child.Name ~= "Client" then
			Client[child.Name] = child
		end
	end

	return nil
end

function Client._initSignals()
	InitMaidFor(Client, Client._maid, Signal.IsSignal)

	Client.OnPlayerFling:Connect(function()
		-- Zero out their velocity to prevent them from flinging:
		localPlayer.Character.PrimaryPart.AssemblyLinearVelocity *= SharedConstants.Vectors.Default
	end)

	Client.OnPlayerHardGroundLand:Connect(function()
		-- Zero out their velocity to prevent them from flinging:
		localPlayer.Character.PrimaryPart.AssemblyLinearVelocity *= SharedConstants.Vectors.XZ
	end)

	return nil
end

if not Client._areModulesInit then
	Client._initModules()
end

return Client
