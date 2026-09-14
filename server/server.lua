--------------------------------------------------------------------------------
-- Supporting functions
--------------------------------------------------------------------------------

local function getLevel(skill)
    return math.min(math.floor(skill / Config.SkillPerLevel), Config.MaxLevel)
end

-- Multiplier for success chance
local function getScaledMultiplier(value, cap, maxMultiplier)
    return 1.0 + (maxMultiplier - 1.0) * math.min(value / cap, 1.0)
end

local function rollItem(level)
    local pool = Config.LevelItems[level]
    local roll = math.random(100)
    local total = 0

    for _, item in ipairs(pool) do
        total += item.chance

        if roll <= total then
            return item.name, math.random(item.min, item.max)
        end
    end
end

local function rollFrom(pool)
    local roll = math.random(100)
    local total = 0

    for _, entry in ipairs(pool) do
        total += entry.chance

        if roll <= total then
            return entry.key
        end
    end
end

--------------------------------------------------------------------------------
-- Core functionality
--------------------------------------------------------------------------------

local cooldowns = {} -- Previous attempts, for tracking cooldowns server-side
local pending = {} -- Attempts that are in-progress

-- Decide the outcome & provide that to client
lib.callback.register('pickpocket:requestOutcome', function(playerId, pedId, pedCoords, witnessed)
    local characterId = RPUK.getCharacterId(playerId)
    local playerCoords = GetEntityCoords(GetPlayerPed(playerId))
    local distance = #(playerCoords - pedCoords)

    cooldowns[characterId] = cooldowns[characterId] or {}

    local lastAttempt = cooldowns[characterId][pedId]
    local onCooldown = lastAttempt and GetGameTimer() - lastAttempt < Config.CooldownTime

    -- AntiCheat
    if distance > Config.PickpocketRange then
        RPUK.discordAlert(characterId, ('tried pickpocketing a ped %.1fm away (max %.0fm)'):format(distance, Config.PickpocketRange))
        return { ok = false }
    end
    
    if onCooldown then
        RPUK.discordAlert(characterId, 'requested a pickpocket while still on cooldown for this ped')
    end
    --- end AntiCheat

    local streetCred = RPUK.getStreetCred(playerId, Config.SkillId) or 0
    local successChance = Config.SuccessChance * getScaledMultiplier(streetCred, Config.StreetCredMax, Config.SuccessMultiplierMax)

    local success = not onCooldown and math.random(100) <= successChance
    local key = rollFrom(success and Config.OnSuccess or Config.OnFailure)

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
    if GetGameTimer() - request.rolledAt < Config.PickpocketTime - 500 then
        return RPUK.discordAlert(request.characterId, 'client confirmed a pickpocket faster than what should be possible')
    end
    --- end AntiCheat

    cooldowns[request.characterId][request.pedId] = GetGameTimer()

    if request.success then
        local skill = RPUK.getSkill(playerId, Config.SkillId) or 0

        RPUK.updateStreetCred(playerId, math.random(Config.CredMin, Config.CredMax))
        RPUK.updateSkill(playerId, Config.SkillGain)

        local name, amount = rollItem(getLevel(skill))
        RPUK.addItem(playerId, name, amount)
    elseif not request.success then
        RPUK.updateStreetCred(playerId, -(math.random(Config.CredMin, Config.CredMax) * 0.5)) -- unsuccessful removes cred with 0.5x multiplier
    end

    local policeAlertChance = Config.PoliceAlertChanceNoWitness
    if request.witnessed then
        policeAlertChance = Config.PoliceAlertChanceWitness
    end

    if math.random(100) <= policeAlertChance then
        RPUK.dispatchPolice(request.pedCoords)
    end

    RPUK.log(request)
end)
