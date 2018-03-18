PlatoonTemplate {
    Name = 'AddToMassExtractorUpgradePlatoon',
    Plan = 'MassUpgradePlatoonMerger',
    GlobalSquads = {
        { categories.MASSEXTRACTION * (categories.TECH1 + categories.TECH2 + categories.TECH3) , 1, 200, 'support', 'none' }
    },
}

PlatoonTemplate {
    Name = 'U1EngineerTransfer',
    Plan = 'TransferAIUveso',
    GlobalSquads = {
        { categories.MOBILE * categories.ENGINEER * categories.TECH1, 1, 1, 'support', 'none' },
    },
}
PlatoonTemplate {
    Name = 'U2EngineerTransfer',
    Plan = 'TransferAIUveso',
    GlobalSquads = {
        { categories.MOBILE * categories.ENGINEER * categories.TECH2, 1, 1, 'support', 'none' },
    },
}
PlatoonTemplate {
    Name = 'U3EngineerTransfer',
    Plan = 'TransferAIUveso',
    GlobalSquads = {
        { categories.MOBILE * categories.ENGINEER * categories.TECH3, 1, 1, 'support', 'none' },
    },
}
