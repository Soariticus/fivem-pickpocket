-- Idk how RPUK handles any of these, to be routed later
RPUK = {}

function RPUK.getCharacterId(playerId)
    return GetPlayerIdentifierByType(playerId, 'license') or ('id:' .. playerId)
end

function RPUK.addItem(playerId, item, amount)
    print(('give %dx %s to ID: %s)'):format(playerId, amount, item))
end

-- Log for panel, has:
-- charId, PedId, PedCoords x,y,z, success & outcome (cash/item/nothing/caught)
function RPUK.log(entry)
    print(('log entry: %s pickpocketed PedID:%s at (%.2f, %.2f, %.2f) - %s (%s)'):format(
        entry.characterId, entry.pedId, entry.pedCoords.x, entry.pedCoords.y, entry.pedCoords.z,
        entry.success and 'success' or 'failure', entry.key))
end

-- Send alert to discord staff-fivem-bot
function RPUK.discordAlert(characterId, reason)
    print(('discord alert: suspicious activity from %s: %s^0'):format(characterId, reason))
end

-- Send dispatch to police, and let everyone know a dispatch went out
function RPUK.dispatchPolice(coords)
    print(('police dispatch: Reported suspicious behavior (%.2f, %.2f, %.2f)'):format(coords.x, coords.y, coords.z))
    TriggerClientEvent('ox_lib:notify', -1, { description = 'Police alerted!' })
end
