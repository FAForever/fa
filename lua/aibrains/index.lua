
--- Converts the (lobby) key defined in `aitypes.lua` or for custom AIs in the `CustomAIs_v2` folder
--- to a brain instance specific for that AI
keyToBrain = {
    -- default
    default = import("/lua/aibrains/base-ai.lua").AIBrain,

    -- base AIs
    tech = import("/lua/aibrains/base-ai.lua").AIBrain,
    rush = import("/lua/aibrains/base-ai.lua").AIBrain,
    easy = import("/lua/aibrains/base-ai.lua").AIBrain,
    normal = import("/lua/aibrains/base-ai.lua").AIBrain,
    adaptive = import("/lua/aibrains/base-ai.lua").AIBrain,
    random = import("/lua/aibrains/base-ai.lua").AIBrain,

    techcheat = import("/lua/aibrains/base-ai.lua").AIBrain,
    rushcheat = import("/lua/aibrains/base-ai.lua").AIBrain,
    easycheat = import("/lua/aibrains/base-ai.lua").AIBrain,
    normalcheat = import("/lua/aibrains/base-ai.lua").AIBrain,
    adaptivecheat = import("/lua/aibrains/base-ai.lua").AIBrain,
    randomcheat = import("/lua/aibrains/base-ai.lua").AIBrain,
}