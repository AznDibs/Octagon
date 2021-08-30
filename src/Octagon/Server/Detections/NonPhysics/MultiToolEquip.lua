-- SilentsReplacement
-- MultiToolEquip
-- July 26, 2021

--[[
    MultiToolEquip.Enabled : boolean
    
	MultiToolEquip.Init() --> nil []
    MultiToolEquip.Start(playerProfile : PlayerProfile) --> nil []
    MultiToolEquip.Cleanup() --> nil []
]]

local MultiToolEquip = {
	Enabled = true,
}

local Shared = script:FindFirstAncestor("Octagon").Shared
local Util = require(Shared.Util)
local Signal = require(Shared.Signal)
local Maid = require(Shared.Maid)
local InitMaidFor = require(Shared.InitMaidFor)
local DestroyAll = require(Shared.DestroyAll)

local LocalConstants = { MaxEquippedToolCount = 1 }

MultiToolEquip._onPlayerDetection = Signal.new()
MultiToolEquip._maid = Maid.new()

local playerEquippedTools = {}

function MultiToolEquip.Init()
	MultiToolEquip._initSignals()

	return nil
end

function MultiToolEquip.Start(playerProfile)
	local player = playerProfile.Player
	playerEquippedTools[player] = playerEquippedTools[player]
		or {
			Count = 0,
			Tools = {},
		}

	local childAddedConnection = player.Character.ChildAdded:Connect(function(tool)
		if not tool:IsA("BackpackItem") then
			return nil
		end

		local playerEquippedToolsData = playerEquippedTools[player]

		playerEquippedToolsData.Tools[tool] = tool
		playerEquippedToolsData.Count += 1

		if playerEquippedToolsData.Count > LocalConstants.MaxEquippedToolCount then
			MultiToolEquip._onPlayerDetection:Fire(playerProfile)
		end
	end)

	playerProfile.DetectionMaid:AddTask(childAddedConnection)
	MultiToolEquip._maid:AddTask(childAddedConnection)

	-- Handle case where the player has already equipped more tools before the above
	-- events ran:
	do
		local equippedTools, equippedToolsCount = Util.GetPlayerEquippedTools(player)
		local playerEquippedToolsData = playerEquippedTools[player]

		playerEquippedToolsData.Count = equippedToolsCount
		playerEquippedToolsData.Tools = equippedTools

		if playerEquippedToolsData.Count > LocalConstants.MaxEquippedToolCount then
			MultiToolEquip._onPlayerDetection:Fire(playerProfile)
		end
	end

	return nil
end

function MultiToolEquip.Cleanup()
	DestroyAll(MultiToolEquip, Maid.IsMaid)

	return nil
end

function MultiToolEquip._initSignals()
	InitMaidFor(MultiToolEquip, MultiToolEquip._maid, Signal.IsSignal)

	MultiToolEquip._onPlayerDetection:Connect(function(playerProfile)
		local player = playerProfile.Player
		local playerEquippedToolsData = playerEquippedTools[player]

		-- Parent tools equipped to the player's backpack
		-- until the amount of tools the player has equipped is <=
		-- LocalConstants.MaxEquippedToolCount, effectively preventing
		-- multiple tools being equipped:

		for _, tool in pairs(playerEquippedToolsData.Tools) do
			if playerEquippedToolsData.Count == LocalConstants.MaxEquippedToolCount then
				break
			end

			playerEquippedToolsData.Count -= 1
			playerEquippedToolsData.Tools[tool] = nil

			-- Parent the tool back to the backpack. Do this in the same frame except
			-- at a very very slightly later time to prevent bugs:
			task.defer(function()
				if not Util.IsInstanceDestroyed(tool) then
					tool.Parent = player.Backpack
				end
			end)
		end
	end)

	return nil
end

return MultiToolEquip
