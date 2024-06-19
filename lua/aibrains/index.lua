--- Converts the (lobby) key defined in `aitypes.lua` or for custom AIs in the `CustomAIs_v2` folder
--- to a brain instance specific for that AI
keyToBrain = {
    -- default
    default = { "/lua/aibrains/base-ai.lua", "AIBrain" },
    campaign = { "/lua/aibrains/campaign-ai.lua", "AIBrain" },

    -- base AI
    tech = { "/lua/aibrains/tech-ai.lua", "AIBrain" },
    turtle = { "/lua/aibrains/turtle-ai.lua", "AIBrain" },
    rush = { "/lua/aibrains/rush-ai.lua", "AIBrain" },
    easy = { "/lua/aibrains/medium-ai.lua", "AIBrain" },
    medium = { "/lua/aibrains/medium-ai.lua", "AIBrain" },
    adaptive = { "/lua/aibrains/adaptive-ai.lua", "AIBrain" },
    random = { "/lua/aibrains/adaptive-ai.lua", "AIBrain" },

    -- base AIX
    techcheat = { "/lua/aibrains/tech-ai.lua", "AIBrain" },
    turtlecheat = { "/lua/aibrains/turtle-ai.lua", "AIBrain" },
    rushcheat = { "/lua/aibrains/rush-ai.lua", "AIBrain" },
    adaptivecheat = { "/lua/aibrains/adaptive-ai.lua", "AIBrain" },
    randomcheat = { "/lua/aibrains/adaptive-ai.lua", "AIBrain" },
}
