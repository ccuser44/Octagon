-- SilentsReplacement
-- PlayerProfileService
-- August 10, 2021

--[[
    PlayerProfileService.OnPlayerProfileLoaded : Signal (playerProfile : PlayerProfile) 
    PlayerProfileService.OnPlayerProfileDestroyed : Signal (player : Player)
    PlayerProfileService.OnPlayerProfileInit : Signal (playerProfile : PlayerProfile) 
    PlayerProfileService.LoadedPlayerProfiles : table

	PlayerProfileService.Init() --> nil []
    PlayerProfileService.GetPlayerProfile(player : Player) --> PlayerProfile | nil []
    PlayerProfileService.ArePlayerProfilesLoaded() --> boolean [ArePlayerProfilesLoaded]
    PlayerProfileService.DestroyLoadedPlayerProfiles() --> nil []
]]

local PlayerProfileService = {
	LoadedPlayerProfiles = {},
}

local Octagon = script:FindFirstAncestor("Octagon")
local Signal = require(Octagon.Shared.Signal)
local SharedConstants = require(Octagon.Shared.SharedConstants)
local Maid = require(Octagon.Shared.Maid)
local Util = require(Octagon.Shared.Util)
local InitMaidFor = require(Octagon.Shared.InitMaidFor)
local DestroyAllMaids = require(Octagon.Shared.DestroyAllMaids)

function PlayerProfileService.ArePlayerProfilesLoaded()
	return next(PlayerProfileService.LoadedPlayerProfiles) ~= nil
end

function PlayerProfileService.DestroyLoadedPlayerProfiles()
	for _, playerProfile in pairs(PlayerProfileService.LoadedPlayerProfiles) do
		playerProfile:Destroy()
	end

	return nil
end
 
function PlayerProfileService.Init()
	PlayerProfileService._initSignals()
	PlayerProfileService._initModules()

	return nil
end

function PlayerProfileService.Cleanup()
	DestroyAllMaids(PlayerProfileService)

	return nil
end

function PlayerProfileService.GetPlayerProfile(player)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerProfileService.GetPlayerProfile()",
			"Player",
			typeof(player)
		)
	)

	local playerProfile = PlayerProfileService.LoadedPlayerProfiles[player]

	if playerProfile ~= nil then
		return playerProfile
	elseif PlayerProfileService._isInit and Util.IsPlayerSubjectToBeMonitored(player) then
		return PlayerProfileService._waitForPlayerProfile(player)
	end

	return nil
end

function PlayerProfileService._waitForPlayerProfile(player)
	local onPlayerProfileLoaded = Signal.new()

	local onPlayerProfileLoadedConnection = nil
	onPlayerProfileLoadedConnection = PlayerProfileService.OnPlayerProfileLoaded:Connect(
		function(playerProfile)
			if playerProfile.Player == player then
				onPlayerProfileLoaded:Fire(playerProfile)
			end
		end
	)

	local playerProfile = onPlayerProfileLoaded:Wait()
	if not playerProfile:IsInit() then
		playerProfile.OnInit:Wait()
	end

	onPlayerProfileLoaded:Destroy()
	onPlayerProfileLoadedConnection:Disconnect()

	return playerProfile
end

function PlayerProfileService._initModules()
	for _, child in ipairs(script:GetChildren()) do
		PlayerProfileService[child.Name] = child
	end

	return nil
end

function PlayerProfileService._initSignals()
	PlayerProfileService._maid = Maid.new()
	PlayerProfileService.OnPlayerProfileLoaded = Signal.new()
	PlayerProfileService.OnPlayerProfileDestroyed = Signal.new()
	PlayerProfileService.OnPlayerProfileInit = Signal.new()

	InitMaidFor(PlayerProfileService, PlayerProfileService._maid, Signal.IsSignal)
	PlayerProfileService._initModules()

	PlayerProfileService.OnPlayerProfileLoaded:Connect(function(playerProfile)
		PlayerProfileService.LoadedPlayerProfiles[playerProfile.Player] = playerProfile
	end)

	PlayerProfileService.OnPlayerProfileDestroyed:Connect(function(player)
		PlayerProfileService.LoadedPlayerProfiles[player] = nil
	end)

	return nil
end

return PlayerProfileService
