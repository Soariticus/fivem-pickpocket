-- Results as sent to client
local RESULTS = {
    cash = { message = 'You stole some money!' },
    item = { message = 'You stole something!' },
    nothing = { message = 'You found nothing worth taking.' },
    caught = {
        message = 'You got caught lacking!',
        onCaught = function(ped)
            if math.random(2) == 1 then
                TaskCombatPed(ped, cache.ped, 0, 16)
            else
                TaskSmartFleePed(ped, cache.ped, 100.0, -1, false, false)
            end
        end,
    },
}

-- Output UI message to client
function PresentOutcome(ped, key)
    local result = RESULTS[key]

    if not result then return end

    RPUK.notify({ description = result.message, type = result.type })

    if result.onCaught then
        result.onCaught(ped)
    end
end
