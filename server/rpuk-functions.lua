-- Idk how RPUK handles any of these, to be routed later
-- I don't know whether you use charID or sessionId for these things, so I expose both
RPUK = {}

--------------------------------------------------------------------------------
-- Inputs
--------------------------------------------------------------------------------

-- Return the player's active characterID, based on sessionID
function RPUK.getCharacterId(sessionId) -- sessionId: int
    return sessionId
end

-- Return the current street cred for the player
function RPUK.getStreetCred(sessionId, characterId) -- sessionId: int, characterId: int
    return 1
end

function RPUK.getSkill(sessionId, characterId, skillId) -- sessionId: int, characterId: int, skillId: string
    -- Return the pickpocket skill for the player
    return 1
end


--------------------------------------------------------------------------------
-- Outputs
--------------------------------------------------------------------------------

-- Add item to player inventory
function RPUK.addItem(sessionId, characterId, item, amount) -- sessionId: int, characterId: int, item: string, amount: int
    print(('give %dx %s to sessionId:%s/CharID:%s'):format(amount, item, sessionId, characterId))
end

-- Log to panel, for debugging, balancing & general staffing
function RPUK.log(entry)
    -- entry: table{sessionId: int, characterId: int, pedId: int, pedCoords: vector3, success: bool, outcomeType: string, rewardAmount: int, rewardName: string}
    print(('log entry: sessionId:%s/CharID:%s pickpocketed PedID:%s at (%.2f, %.2f, %.2f) - %s (%s > %fx %s)'):format(
        entry.sessionId, entry.characterId, entry.pedId, entry.pedCoords.x, entry.pedCoords.y, entry.pedCoords.z,
        entry.success and 'success' or 'failure', entry.outcomeType, entry.rewardAmount, entry.rewardName))
end

-- Send alert to discord staff-fivem-bot
function RPUK.discordAlert(sessionId, characterId, reason) -- sessionId: int, characterId: int, reason: string
    print(('discord alert: suspicious activity from sessionId:%s/CharID:%s: %s^0'):format(sessionId, characterId, reason))
end

-- Send dispatch to police
-- Coords are vector3 of the ped, not player
function RPUK.dispatchPolice(sessionId, characterId, coords) -- sessionId: int, characterId: int, coords: vector3
    print(('police dispatch: Reported suspicious behavior (%.2f, %.2f, %.2f)'):format(coords.x, coords.y, coords.z))
    TriggerClientEvent('ox_lib:notify', -1, { description = 'Police alerted!' })
end

-- Update street cred, can be positive or negative
-- Expected: newCred = oldCred + amount
function RPUK.updateStreetCred(sessionId, characterId, amount) -- sessionId: int, characterId: int, amount: float
    print(('update street cred for sessionId:%s/CharID:%s by %.1f'):format(sessionId, characterId, amount))
end

-- Update pickpocket skill, can be positive or negative
-- Expected: newSkill = oldSkill + amount
function RPUK.updateSkill(sessionId, characterId, amount) -- sessionId: int, characterId: int, amount: float
    print(('change pickpocket skill for sessionId:%s/CharID:%s by %.1f'):format(sessionId, characterId, amount))
end
