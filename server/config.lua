Config = {}

Config.PickpocketRange = 10.0 -- Any attempt further away from the ped gets sent in discord
Config.PickpocketTime = 1000 * 3 -- Any shorter and alert sent in discord - MATCH ON CLIENT
Config.CooldownTime = 1000 * 30 -- Ditto ^

Config.PoliceAlertChanceWitness = 10
Config.PoliceAlertChanceNoWitness = 5
Config.SuccessChance = 40 -- scales based on street cred

Config.OnSuccess = {
    { chance = 100, outcomeType = 'item' },
}

Config.OnFailure = {
    { chance = 70, outcomeType = 'nothing' },
    { chance = 30, outcomeType = 'caught' }, -- ped attacks/runs away
}

-- Amount of cred that can be gained/lost
Config.CredMin = 1
Config.CredMax = 3


-- Skill related
Config.SkillId = 'pickpocket'
Config.SkillGain = 1 -- Might be 3?
Config.MaxLevel = 5
Config.SkillPerLevel = 100 -- Guesstimate


-- Scaling
Config.StreetCredMax = 100000 -- Max streetcred
Config.SuccessMultiplierMax = 1.25 -- Success chance multiplier at max streetcred


-- Per skill level
Config.LevelItems = {
    [0] = {
        { chance = 65, name = 'cash', min = 300, max = 1200 },
        { chance = 25, name = 'sativa', min = 2, max = 3 },
        { chance = 10, name = 'wad_of_cash', min = 1, max = 3 },
    },
    [1] = {
        { chance = 65, name = 'cash', min = 450, max = 1350 },
        { chance = 20, name = 'sativa', min = 3, max = 8 },
        { chance = 15, name = 'wad_of_cash', min = 1, max = 3 },
    },
    [2] = {
        { chance = 65, name = 'cash', min = 600, max = 1500 },
        { chance = 25, name = 'wad_of_cash', min = 1, max = 3 },
        { chance = 10, name = 'sativa', min = 3, max = 8 },
    },
    [3] = {
        { chance = 70, name = 'cash', min = 750, max = 1650 },
        { chance = 30, name = 'wad_of_cash', min = 1, max = 3 },
    },
    [4] = {
        { chance = 60, name = 'cash', min = 900, max = 1800 },
        { chance = 40, name = 'wad_of_cash', min = 1, max = 3 },
    },
    [5] = {
        { chance = 50, name = 'cash', min = 1050, max = 1950 },
        { chance = 50, name = 'wad_of_cash', min = 1, max = 3 },
    },
}
