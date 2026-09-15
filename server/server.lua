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
            return entry.outcomeType
        end
    end
end

--------------------------------------------------------------------------------
-- Core functionality
--------------------------------------------------------------------------------

local cooldowns = {} -- Previous attempts, for tracking cooldowns server-side
local pending = {} -- Attempts that are in-progress

-- Decide the outcome & provide that to client
lib.callback.register('pickpocket:requestOutcome', function(sessionId, pedId, pedCoords, witnessed)
    local characterId = RPUK.getCharacterId(sessionId)
    local playerCoords = GetEntityCoords(GetPlayerPed(sessionId))
    local distance = #(playerCoords - pedCoords)

    cooldowns[characterId] = cooldowns[characterId] or {}

    local lastAttempt = cooldowns[characterId][pedId]
    local onCooldown = lastAttempt and GetGameTimer() - lastAttempt < Config.CooldownTime

    -- AntiCheat
    if distance > Config.PickpocketRange then
        RPUK.discordAlert(sessionId, characterId, ('tried pickpocketing a ped %.1fm away (max %.0fm)'):format(distance, Config.PickpocketRange))
        return { ok = false }
    end
    
    if onCooldown then
        RPUK.discordAlert(sessionId, characterId, 'requested a pickpocket while still on cooldown for this ped')
    end
    --- end AntiCheat

    local streetCred = RPUK.getStreetCred(sessionId, characterId) or 0
    local successChance = Config.SuccessChance * getScaledMultiplier(streetCred, Config.StreetCredMax, Config.SuccessMultiplierMax)

    local success = not onCooldown and math.random(100) <= successChance
    local outcomeType = rollFrom(success and Config.OnSuccess or Config.OnFailure)

    -- Stash the outcome until client confirms they're done
    pending[sessionId] = {
        sessionId = sessionId,
        characterId = characterId,
        pedId = pedId,
        pedCoords = pedCoords,
        witnessed = witnessed,
        success = success,
        rolledAt = GetGameTimer(),
        outcomeType = outcomeType,
        rewardName = 'None',
        rewardAmount = -1
    }

    return { ok = true, success = success, outcomeType = outcomeType }
end)

-- Client reports progress bar done
RegisterNetEvent('pickpocket:confirmOutcome', function(pedId)
    local sessionId = source
    local request = pending[sessionId]

    pending[sessionId] = nil -- Clear early in case anything hangs server-side

    -- Anticheat
    if not request or request.pedId ~= pedId then
        return RPUK.discordAlert(sessionId, RPUK.getCharacterId(sessionId), 'client confirmed a pickpocket that never started')
    end

    local characterId = request.characterId

    if GetGameTimer() - request.rolledAt < Config.PickpocketTime - 500 then
        return RPUK.discordAlert(sessionId, characterId, 'client confirmed a pickpocket faster than what should be possible')
    end
    --- end AntiCheat

    cooldowns[characterId][request.pedId] = GetGameTimer()

    if request.success then
        local skill = RPUK.getSkill(sessionId, characterId, Config.SkillId) or 0

        RPUK.updateStreetCred(sessionId, characterId, math.random(Config.CredMin, Config.CredMax))
        RPUK.updateSkill(sessionId, characterId, Config.SkillGain)

        request.rewardName, request.rewardAmount = rollItem(getLevel(skill))
        RPUK.addItem(sessionId, characterId, request.rewardName, request.rewardAmount)
    elseif not request.success then
        RPUK.updateStreetCred(sessionId, characterId, -(math.random(Config.CredMin, Config.CredMax) * 0.5)) -- unsuccessful removes cred with 0.5x multiplier
    end

    local policeAlertChance = Config.PoliceAlertChanceNoWitness
    if request.witnessed then
        policeAlertChance = Config.PoliceAlertChanceWitness
    end

    if math.random(100) <= policeAlertChance then
        RPUK.dispatchPolice(sessionId, characterId, request.pedCoords)
    end

    RPUK.log(request)
end)
