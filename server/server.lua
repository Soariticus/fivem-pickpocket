local PICKPOCKET_RANGE = 10.0 -- Any attempt further away from the ped gets sent in discord
local PICKPOCKET_TIME = 1000 * 3 -- Any shorter and alert sent in discord
local COOLDOWN_TIME = 1000 * 30 -- Ditto ^

local POLICE_ALERT_CHANCE = 10 
local SUCCESS_CHANCE = 40

local ON_SUCCESS = {
    { chance = 90, key = 'cash' },
    { chance = 10, key = 'item' },
}

local ON_FAILURE = {
    { chance = 70, key = 'nothing' },
    { chance = 30, key = 'caught' }, -- ped attacks/runs away
}

-- Items that can be gotten, and how many
local ITEMS = {
    { name = 'weed', min = 1, max = 3 },
    { name = 'coke', min = 1, max = 2 },
}

-- How much cash can be gained
local CASH_MIN = 100
local CASH_MAX = 500

--------------------------------------------------------------------------------
-- Supporting functions
--------------------------------------------------------------------------------

local function rollItem()
    local item = ITEMS[math.random(#ITEMS)]
    return item.name, math.random(item.min, item.max)
end

local function rollFrom(pool)
    local roll, total = math.random(100), 0

    for _, entry in ipairs(pool) do
        total += entry.chance

        if roll <= total then
            return entry.key
        end
    end
end

--------------------------------------------------------------------------------
-- Core functionality
-------------------------------------------------------------------------------

local cooldowns = {} -- Previous attempts, for tracking cooldowns server-side
local pending = {} -- Attempts that are in-progress

-- Decide the outcome & provide that to client
lib.callback.register('pickpocket:requestOutcome', function(playerId, pedId, pedCoords, witnessed)
    local characterId = RPUK.getCharacterId(playerId)
    local playerCoords = GetEntityCoords(GetPlayerPed(playerId))
    local distance = #(playerCoords - pedCoords)

    if distance > PICKPOCKET_RANGE then
        RPUK.discordAlert(characterId, ('tried pickpocketing a ped %.1fm away (max %.0fm)'):format(distance, PICKPOCKET_RANGE))
        return { ok = false }
    end

    cooldowns[characterId] = cooldowns[characterId] or {}

    local lastAttempt = cooldowns[characterId][pedId]
    local onCooldown = lastAttempt and GetGameTimer() - lastAttempt < COOLDOWN_TIME

    -- Client checks this locally, so getting here SHOULD be impossible(?)
    if onCooldown then
        RPUK.discordAlert(characterId, 'requested a pickpocket while still on cooldown for this ped')
    end

    local success = not onCooldown and math.random(100) <= SUCCESS_CHANCE
    local key = rollFrom(success and ON_SUCCESS or ON_FAILURE)

    -- Stash the outcome until client confirms they're done
    pending[playerId] = {
        characterId = characterId,
        pedId = pedId,
        pedCoords = pedCoords,
        witnessed = witnessed,
        success = success,
        key = key,
        rolledAt = GetGameTimer(),
    }

    return { ok = true, success = success, key = key }
end)

-- Client reports progress bar done
RegisterNetEvent('pickpocket:confirmOutcome', function(pedId)
    local playerId = source
    local request = pending[playerId]

    pending[playerId] = nil -- Clear early in case anything hangs server-side

    -- Anticheat
    if not request or request.pedId ~= pedId then
        return RPUK.discordAlert(RPUK.getCharacterId(playerId), 'client confirmed a pickpocket that never started')
    end
    if GetGameTimer() - request.rolledAt < PICKPOCKET_TIME - 500 then
        return RPUK.discordAlert(request.characterId, 'client confirmed a pickpocket faster than what should be possible')
    end
    -- end anticheat

    cooldowns[request.characterId][request.pedId] = GetGameTimer()

    if request.success then
        if request.key == 'cash' then
            RPUK.addItem(playerId, 'cash', math.random(CASH_MIN, CASH_MAX))
        elseif request.key == 'item' then
            RPUK.addItem(playerId, rollItem())
        end
    end

    if request.witnessed and math.random(100) <= POLICE_ALERT_CHANCE then
        RPUK.dispatchPolice(request.pedCoords)
    end

    RPUK.log(request)
end)
