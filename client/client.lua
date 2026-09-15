local PICKPOCKET_RADIUS = 2.0 -- meters - clientside only
local PICKPOCKET_TIME = 1000 * 3 -- ms (Should match server-side)
local COOLDOWN_TIME = 1000 * 30 -- Ditto ^
local WITNESS_RADIUS = 50.0 -- radius for witnesses, at least 1 required for chance at police dispatch

-- last attempt pickpocketing ped as logged from client to block UI, server verifies
local lastAttempt = {}

--------------------------------------------------------------------------------
-- Supporting functions
--------------------------------------------------------------------------------

local function getPedId(ped)
    if NetworkGetEntityIsNetworked(ped) then
        return NetworkGetNetworkIdFromEntity(ped) -- Networked ped returns positive value
    end

    return -ped -- Negative value is a local ped
end

local function hasNearbyWitness(ped)
    local nearby = lib.getNearbyPeds(GetEntityCoords(cache.ped), WITNESS_RADIUS)

    for i = 1, #nearby do
        if nearby[i].ped ~= ped then
            return true
        end
    end
    return false
end

-- Draws the range marker & keeps track of whether the player is in it, cancels the action if not
local function startRadiusWatch(ped, onCancel)
    local active = true

    CreateThread(function()
        while active do
            if not DoesEntityExist(ped) then
                onCancel()
                break
            end

            local pedCoords = GetEntityCoords(ped)

            DrawMarker(1, pedCoords.x, pedCoords.y, pedCoords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                PICKPOCKET_RADIUS * 2, PICKPOCKET_RADIUS * 2, 0.01, 255, 255, 255, 255, false, false, 2, false, nil, nil, false)

            if #(GetEntityCoords(cache.ped) - pedCoords) > PICKPOCKET_RADIUS then
                onCancel()
            end

            Wait(0)
        end
    end)

    return function() active = false end
end

local function playAnimation(dict, clip, loop)
    lib.requestAnimDict(dict)
    TaskPlayAnim(cache.ped, dict, clip, 8.0, -8.0, -1, loop and 49 or 48, 0, false, false, false)
end


--------------------------------------------------------------------------------
-- Core functionality
-------------------------------------------------------------------------------

local function pickpocket(data)
    local ped = data.entity

    if not ped or ped == 0 then return end

    if lastAttempt[ped] and GetGameTimer() - lastAttempt[ped] < COOLDOWN_TIME then
        RPUK.notify("This person seems on guard, I'd best wait.")
        return
    end

    local pedId = getPedId(ped)
    local witnessed = hasNearbyWitness(ped)

    local stopWatch = startRadiusWatch(ped, RPUK.cancelProgress)

    playAnimation('mp_common', 'givetake1_a', true)

    
    -- Tell server that we're starting a pickpocket, it'll return the outcome
    local outcome
    CreateThread(function()
        outcome = lib.callback.await('pickpocket:requestOutcome', false, pedId, GetEntityCoords(ped), witnessed)

        if not outcome.ok then
            RPUK.cancelProgress()
        end
    end)

    local completed = RPUK.progressBar({
        duration = PICKPOCKET_TIME,
        label = 'Nicking their shit...',
        canCancel = true
    })

    stopWatch()
    ClearPedTasks(cache.ped)

    -- Player walked out of range
    if not completed then
        RPUK.notify("My arms aren't that long...") 
        return
    end

    -- If we've not yet gotten an answer from the server
    local waited = 0
    while not outcome and waited < 2000 do
        Wait(50)
        waited += 50
    end

    -- Either got no response from the server, or anticheat blocked it
    if not outcome or not outcome.ok then
        RPUK.notify("You found nothing worth taking.")
        return
    end

    lastAttempt[ped] = GetGameTimer()
    TriggerServerEvent('pickpocket:confirmOutcome', pedId)

    if outcome.success then
        playAnimation('gestures@m@standing@casual', 'gesture_nod_yes_soft')
    else
        playAnimation('gestures@m@standing@casual', 'gesture_damn')
    end

    PresentOutcome(ped, outcome.outcomeType) -- Shows outcome to client
end


-- Entry point
AddEventHandler('pickpocket:start', function(data)
    pickpocket(data)
end)
