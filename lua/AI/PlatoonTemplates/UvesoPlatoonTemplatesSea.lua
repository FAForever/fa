

PlatoonTemplate {
    Name = 'U123 KILLALL 2 30',
    Plan = 'AttackPrioritizedSeaTargetsAIUveso',
    GlobalSquads = {
        { categories.MOBILE * categories.NAVAL - categories.ENGINEER, 2, 30, 'Attack', 'none' }
    }
}
PlatoonTemplate {
    Name = 'U123-KILLALL Solo',
    Plan = 'AttackPrioritizedSeaTargetsAIUveso',
    GlobalSquads = {
        { categories.MOBILE * categories.NAVAL - categories.ENGINEER, 1, 1, 'Attack', 'none' }
    }
}
PlatoonTemplate {
    Name = 'U123-AntiSubPanic 1 500',
    Plan = 'AttackPrioritizedSeaTargetsAIUveso',
    GlobalSquads = {
        { categories.MOBILE * categories.NAVAL - categories.EXPERIMENTAL - categories.CARRIER - categories.NUKE, 1, 500, 'Attack', 'none' }
    },
}

--InterceptorAIUveso
--NavalStrikeForceAI -- direct move
--NavalForceAI -- AIPlatoonNavalAttackVector
--NavalForceAISorian -- pathing
--NavalHuntAI -- direct move
