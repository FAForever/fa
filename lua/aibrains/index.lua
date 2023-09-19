
--- Converts the (lobby) key defined in `aitypes.lua` or for custom AIs in the `CustomAIs_v2` folder
--- to a brain instance specific for that AI
keyToBrain = {
    -- default
    default = import("/lua/aibrains/base-ai.lua").AIBrain,
    campaign = import("/lua/aibrains/campaign-ai.lua").AIBrain,

    -- base AI
    --easy = import("/lua/aibrains/easy-ai.lua").AIBrain,
    tech = import("/lua/aibrains/base-ai.lua").AIBrain,
    turtle = import("/lua/aibrains/base-ai.lua").AIBrain,
    rush = import("/lua/aibrains/base-ai.lua").AIBrain,
    easy = import("/lua/aibrains/base-ai.lua").AIBrain,
    medium = import("/lua/aibrains/base-ai.lua").AIBrain,
    adaptive = import("/lua/aibrains/adaptive-ai.lua").AIBrain,
    random = import("/lua/aibrains/base-ai.lua").AIBrain,

    -- base AIX
    techcheat = import("/lua/aibrains/base-ai.lua").AIBrain,
    turtlecheat = import("/lua/aibrains/base-ai.lua").AIBrain,
    rushcheat = import("/lua/aibrains/base-ai.lua").AIBrain,
    adaptivecheat = import("/lua/aibrains/adaptive-ai.lua").AIBrain,
    randomcheat = import("/lua/aibrains/base-ai.lua").AIBrain,
}