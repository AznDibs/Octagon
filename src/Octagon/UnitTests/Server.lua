-- SilentsReplacement
-- Server
-- August 29, 2021

local Server = {
	_testsPassed = {
		Util = {},
		PlayerProfileService = {},
		PlayerProfile = {},
		Octagon = {},
	},
	_testsFailed = {
		Util = {},
		PlayerProfileService = {},
		PlayerProfile = {},
		Octagon = {},
	},
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Octagon = require(ReplicatedStorage.Octagon)
local PlayerProfileService = require(Octagon.PlayerProfileService)
local PlayerProfile = require(PlayerProfileService.PlayerProfile)
local Util = require(Octagon.Shared.Util)

function Server.TestUtilModule()
	print("[----------------------------------------")
	print("Starting tests for Util Module")
	print("----------------------------------------]")

	local player = nil

	-- Util.HasBasePartFallenToVoid() test:
	do
		-- Expected behaviour: Util.HasBasePartFallenToVoid() should return true
		-- if the given base part's position's Y is <= Workspace.FallenPartsDestroyHeight:

		local basePart = Instance.new("Part")
		local hasTestPassed = false

		if not Util.HasBasePartFallenToVoid(basePart) then
			basePart.Position = Vector3.new(0, Workspace.FallenPartsDestroyHeight, 0)
			hasTestPassed = Util.HasBasePartFallenToVoid(basePart)
		end

		Server._checkTest("Util", hasTestPassed, "Util.HasBasePartFallenToVoid()")
		basePart:Destroy()
	end

	-- Util.IsInstanceDestroyed() test:
	do
		-- Expected behaviour: Util.IsInstanceDestroyed() should return true
		-- if the given base part is destroyed, not just parented to nil:

		local hasTestPassed = false
		local basePart = Instance.new("Part")

		if not Util.IsInstanceDestroyed(basePart) then
			basePart.Parent = nil

			if not Util.IsInstanceDestroyed(basePart) then
				basePart:Destroy()
				hasTestPassed = Util.IsInstanceDestroyed(basePart)
			end
		end

		Server._checkTest("Util", hasTestPassed, "Util.IsInstanceDestroyed()")
		basePart:Destroy()
	end

	player = Server._getPlayer()

	-- Util.IsPlayerWalking() test:
	do
		-- Expected behaviour: Util.IsPlayerWalking() should return true
		-- if the distance between the last position and the current player's position
		-- is >= 0.125 (only accounting for X and Z axis, not Y):

		local hasTestPassed = false

		if not player then
			warn("Aborting test for Util.IsPlayerWalking() as no player was found")
		else
			local primaryPart = (player.Character or player.CharacterAdded:Wait()).PrimaryPart
			if not Util.IsPlayerWalking(player, primaryPart.Position) then
				-- Make sure only the X and Z axis are counted:
				if
					not Util.IsPlayerWalking(
						player,
						primaryPart.Position + Vector3.new(0, 100, 0)
					)
				then
					hasTestPassed = Util.IsPlayerWalking(
						player,
						primaryPart.Position + Vector3.new(0, 0, 35)
					)
				end
			end

			Server._checkTest("Util", hasTestPassed, "Util.IsPlayerWalking()")
		end
	end

	-- Util.IsBasePartFalling() test:
	do
		-- Expected behaviour: Util.IsBasePartFalling() should return true
		-- if the base part's current position's Y axis is lower than their
		-- last position's Y axis:

		local hasTestPassed = false
		local basePart = Instance.new("Part")

		if not Util.IsBasePartFalling(basePart, basePart.Position) then
			if
				not Util.IsBasePartFalling(
					basePart,
					basePart.Position + Vector3.new(0, -35, 0)
				)
			then
				-- Make sure only the Y axis is accounted for:
				if
					not Util.IsBasePartFalling(
						basePart,
						basePart.Position + Vector3.new(1350, 0, 3560)
					)
				then
					hasTestPassed = Util.IsBasePartFalling(
						basePart,
						basePart.Position + Vector3.new(0, 5, 0)
					)
				end
			end
		end

		Server._checkTest("Util", hasTestPassed, "Util.IsBasePartFalling()")
	end

	-- Util.DoValidPlayerBodyPartsExist() test:
	do
		-- Expected behaviour: Util.DoValidPlayerBodyPartsExist() should return true
		-- if the given player's character, humanoid and the primary part exist:
		local hasTestPassed = false

		if not player then
			warn("Aborting test for Util.DoValidPlayerBodyPartsExist() as no player was found")
		else
			if
				Util.DoValidPlayerBodyPartsExist(player)
				and player.Character
				and player.Character.PrimaryPart
				and player.Character:FindFirstChildWhichIsA("Humanoid")
			then
				local character = player.Character
				local primaryPart = character.PrimaryPart

				player.Character = nil

				if not Util.DoValidPlayerBodyPartsExist(player) then
					player.Character = character
					player.Character.PrimaryPart = nil
					hasTestPassed = not Util.DoValidPlayerBodyPartsExist(player)
				end

				player.Character.PrimaryPart = primaryPart
			end

			task.spawn(player.LoadCharacter, player)
			Server._checkTest("Util", hasTestPassed, "Util.DoValidPlayerBodyPartsExist()")
		end
	end

	-- Util.SetBasePartNetworkOwner() test:
	do
		if not player then
			warn("Aborting test for Util.SetBasePartNetworkOwner() as no player was found")
		else
			-- Expected behaviour: Util.SetBasePartNetworkOwner() should set the network
			-- owner of the given base part to either the given player or nil (server):
			local hasTestPassed = false
			local basePart = Instance.new("Part")
			basePart.Parent = Workspace

			Util.SetBasePartNetworkOwner(basePart, nil)
			if not basePart:GetNetworkOwner() then
				Util.SetBasePartNetworkOwner(basePart, player)
				hasTestPassed = basePart:GetNetworkOwner() == player
			end

			Server._checkTest("Util", hasTestPassed, "Util.SetBasePartNetworkOwner()")
			basePart:Destroy()
		end
	end

	-- Util.SetBasePartNetworkOwner() test:
	do
		if not player then
			warn("Aborting test for Util.SetBasePartNetworkOwner() as no player was found")
		else
			-- Expected behaviour: Util.SetBasePartNetworkOwner() should set the network
			-- owner of the given base part to either the given player or nil (server):
			local hasTestPassed = false
			local basePart = Instance.new("Part")
			basePart.Parent = Workspace

			Util.SetBasePartNetworkOwner(basePart, nil)
			if not basePart:GetNetworkOwner() then
				Util.SetBasePartNetworkOwner(basePart, player)
				hasTestPassed = basePart:GetNetworkOwner() == player
			end

			Server._checkTest("Util", hasTestPassed, "Util.SetBasePartNetworkOwner()")
			basePart:Destroy()
		end
	end

	-- Util.GetBasePartNetworkOwner() test:
	do
		if not player then
			warn("Aborting test for Util.GetBasePartNetworkOwner() as no player was found")
		else
			-- Expected behaviour: Util.GetBasePartNetworkOwner() should return the network
			-- ownership of the base part and nil for a anchored base part:
			local hasTestPassed = false
			local basePart = Instance.new("Part")
			basePart.Anchored = true
			basePart.Parent = Workspace

			if not Util.GetBasePartNetworkOwner(basePart) then
				basePart.Anchored = false
				Util.SetBasePartNetworkOwner(basePart, player)
				hasTestPassed = Util.GetBasePartNetworkOwner(basePart) == player
			end

			Server._checkTest("Util", hasTestPassed, "Util.GetBasePartNetworkOwner()")
			basePart:Destroy()
		end
	end

	-- Util.GetPlayerEquippedTools() test:
	do
		if not player then
			warn("Aborting test for Util.GetPlayerEquippedTools() as no player was found")
		else
			-- Expected behaviour: Util.GetPlayerEquippedTools() should return 2 arguments, an
			-- dictionary of the tools the player has equipped along with the number of tools
			-- equipped:
			local hasTestPassed = false
			local equippedTools, equippedToolCount = Util.GetPlayerEquippedTools(player)

			if not next(equippedTools) and equippedToolCount == 0 then
				local tool = Instance.new("Tool")
				tool.Parent = player.Character

				equippedTools, equippedToolCount = Util.GetPlayerEquippedTools(player)
				hasTestPassed = next(equippedTools) and equippedToolCount == 1

				task.defer(tool.Destroy, tool)
			end

			Server._checkTest("Util", hasTestPassed, "Util.GetPlayerEquippedTools()")
		end
	end

	if #Server._testsPassed.Util > 0 then
		print(table.concat(Server._testsPassed.Util, "\n"))
	end

	if #Server._testsFailed.Util > 0 then
		warn(table.concat(Server._testsFailed.Util, "\n"))
	end

	return nil
end

function Server.TestPlayerProfileServiceModule()
	local player = Server._getPlayer()

	if not player then
		warn("Aborting PlayerProfileServiceModule test was no player was found")
		return nil
	end

	print("[----------------------------------------")
	print("Starting tests for PlayerProfileService Module")
	print("----------------------------------------]")

	-- PlayerProfileService.OnPlayerProfileLoaded [Signal] test:
	do
		-- Expected behaviour: PlayerProfileService.OnPlayerProfileLoaded should be fired
		-- whenever a new profile is created, along with the
		-- player profile that was created, being passed as the only argument:
		local hasTestPassed = false

		task.defer(PlayerProfile.new, player)
		local playerProfile = PlayerProfileService.OnPlayerProfileLoaded:Wait()
		hasTestPassed = PlayerProfile.IsPlayerProfile(playerProfile)

		Server._checkTest(
			"PlayerProfileService",
			hasTestPassed,
			"PlayerProfileService.OnPlayerProfileLoaded [Signal]"
		)
	end
 
	-- PlayerProfileService.OnPlayerProfileDestroyed [Signal] test:
	do
		-- Expected behaviour: PlayerProfileService.OnPlayerProfileDestroyed should be fired
		-- whenever a profile is destroyed, along with the player associated to that profile,
		-- being passed as the only argument:
		local hasTestPassed = false

		task.defer(function()
			PlayerProfileService.GetPlayerProfile(player):Destroy()
		end)

		hasTestPassed = PlayerProfileService.OnPlayerProfileDestroyed:Wait() == player

		Server._checkTest(
			"PlayerProfileService",
			hasTestPassed,
			"PlayerProfileService.OnPlayerProfileDestroyed [Signal]"
		)
	end

	-- PlayerProfileService.OnPlayerProfileInit [Signal] test:
	do
		-- Expected behaviour: PlayerProfileService.OnPlayerProfileInit should be fired
		-- whenever a profile is init, along with that profile being passed as the
		-- only argument:
		local hasTestPassed = false
		local playerProfile = nil

		task.defer(function()
			playerProfile = PlayerProfile.new(player)
			playerProfile:Init({})
			playerProfile:Destroy()
		end)

		hasTestPassed = PlayerProfileService.OnPlayerProfileInit:Wait()
			== PlayerProfileService.GetPlayerProfile(player)

		Server._checkTest(
			"PlayerProfileService",
			hasTestPassed,
			"PlayerProfileService.OnPlayerProfileInit [Signal]"
		)

		if not playerProfile:IsDestroyed() then
			PlayerProfileService.OnPlayerProfileDestroyed:Wait()
			task.wait() -- Prevent race conditions
		end
	end

	-- PlayerProfileService.GetPlayerProfile() test:
	do
		-- Expected behaviour: PlayerProfileService.GetPlayerProfile() should
		-- return the given player's profile if created:
		local hasTestPassed = false
		local playerProfile = PlayerProfileService.GetPlayerProfile(player)

		if not playerProfile then
			playerProfile = PlayerProfile.new(player)
			hasTestPassed = PlayerProfile.IsPlayerProfile(
				PlayerProfileService.GetPlayerProfile(player)
			)
		end

		Server._checkTest(
			"PlayerProfileService",
			hasTestPassed,
			"PlayerProfileService.GetPlayerProfile()"
		)
	end

	-- PlayerProfileService.ArePlayerProfilesLoaded() test:
	do
		-- Expected behaviour: PlayerProfileService.ArePlayerProfilesLoaded() should
		-- return true if there are more than 0 player profiles loaded:
		local hasTestPassed = false

		if PlayerProfileService.ArePlayerProfilesLoaded() then
			PlayerProfileService.GetPlayerProfile(player):Destroy()
			hasTestPassed = not PlayerProfileService.ArePlayerProfilesLoaded()
		end

		Server._checkTest(
			"PlayerProfileService",
			hasTestPassed,
			"PlayerProfileService.ArePlayerProfilesLoaded()"
		)
	end

	-- PlayerProfileService.DestroyLoadedPlayerProfiles() test:
	do
		-- Expected behaviour: PlayerProfileService.DestroyLoadedPlayerProfiles() should
		-- destroy all loaded player profiles:
		local hasTestPassed = false

		local playerProfile = PlayerProfile.new(player)
		PlayerProfileService.DestroyLoadedPlayerProfiles()
		hasTestPassed = playerProfile:IsDestroyed()

		Server._checkTest(
			"PlayerProfileService",
			hasTestPassed,
			"PlayerProfileService.DestroyLoadedPlayerProfiles()"
		)
	end

	if #Server._testsPassed.PlayerProfileService > 0 then
		print(table.concat(Server._testsPassed.PlayerProfileService, "\n"))
	end

	if #Server._testsFailed.PlayerProfileService > 0 then
		warn(table.concat(Server._testsFailed.PlayerProfileService, "\n"))
	end
end

function Server._checkTest(key, hasTestPassed, log)
	local testCount = (#Server._testsPassed[key] + #Server._testsFailed[key]) + 1

	if hasTestPassed then
		table.insert(Server._testsPassed[key], ("Test#%d [Passed]: %s"):format(testCount, log))
	else
		table.insert(Server._testsFailed[key], ("Test#%d [Failed]: %s"):format(testCount, log))
	end

	return nil
end

function Server._getPlayer()
	local player = Players:GetPlayers()[1]

	if player then
		if not player.Character then
			player.CharacterAdded:Wait()
		end
	end

	return player
end

return Server
