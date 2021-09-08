-- SilentsReplacement
-- init
-- August 12, 2021

--[[
    Client.OnPlayerHardGroundLand : Signal ()

    Client.Start() --> nil []
    Client.Stop() --> nil []
	Client.AllowPlayerBouncing() --> nil []
	Client.PreventPlayerBouncing() --> nil []
	Client.IsStarted() --> boolean [IsStarted]
	Client.IsStopped() --> boolean [IsStopped]
]]

local Client = {
	_allowLocalPlayerBouncing = false,
	_isStarted = false,
	_isStopped = false,
	_isInit = false,
}

local Players = game:GetService("Players")

local Octagon = script:FindFirstAncestor("Octagon")
local SharedConstants = require(Octagon.Shared.SharedConstants)
local Signal = require(Octagon.Shared.Signal)
local SafeWaitForChild = require(Octagon.Shared.SafeWaitForChild)
local Maid = require(Octagon.Shared.Maid)
local InitMaidFor = require(Octagon.Shared.InitMaidFor)
local DestroyAllMaids = require(Octagon.Shared.DestroyAllMaids)

local LocalConstants = { MinPlayerHardGroundLandYVelocity = 145 }

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
	Client._trackHumanoidState(localPlayer.Character or localPlayer.CharacterAdded:Wait())

	-- Track humanoid state again whenever a new
	-- character is added so that the code works
	-- with the new character rather than working with the
	-- old one:
	Client._maid:AddTask(localPlayer.CharacterAdded:Connect(function(character)
		Client._humanoidStateTrackerMaid:Cleanup()
		Client._trackHumanoidState(character)
	end))

	return nil
end

function Client.AllowPlayerBouncing()
	Client._allowLocalPlayerBouncing = true

	return nil
end

function Client.PreventPlayerBouncing()
	Client._allowLocalPlayerBouncing = false

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
	Client._isInit = true
	Client._initModules()
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

	Client._humanoidStateTrackerMaid:AddTask(
		humanoid.StateChanged:Connect(function(_, newState)
			if
				newState == Enum.HumanoidStateType.Landed
				and localPlayer.Character.PrimaryPart ~= nil
			then
				if
					math.abs(localPlayer.Character.PrimaryPart.AssemblyLinearVelocity.Y)
					>= LocalConstants.MinPlayerHardGroundLandYVelocity
				then
					Client.OnPlayerHardGroundLand:Fire()
				end
			end
		end)
	)

	return nil
end

function Client._initModules()
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
	Client._maid = Maid.new()
	Client.OnPlayerFling = Signal.new()
	Client.OnPlayerHardGroundLand = Signal.new()
	Client._humanoidStateTrackerMaid = Maid.new()

	InitMaidFor(Client, Client._maid, Signal.IsSignal)

	Client.OnPlayerHardGroundLand:Connect(function()
		if Client._allowLocalPlayerBouncing then
			return
		end

		-- Zero out their velocity on the Y axis to prevent them from bouncing high up:
		localPlayer.Character.PrimaryPart.AssemblyLinearVelocity *= SharedConstants.Vectors.XZ
	end)

	return nil
end

if not Client._isInit then
	Client._init()
end

return Client
