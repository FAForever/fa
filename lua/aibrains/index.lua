

--- Converts the (lobby) key defined in `aitypes.lua` or for custom AIs in the `CustomAIs_v2` folder
--- to a brain instance specific for that AI
keyToBrain = {
    -- standard framework
    default = import("/lua/aibrains/default.lua").AIBrainDefault,

    -- base AIs
    tech = import("/lua/aibrains/base.lua").AIBrain,
    rush = import("/lua/aibrains/base.lua").AIBrain,
    easy = import("/lua/aibrains/base.lua").AIBrain,
    normal = import("/lua/aibrains/base.lua").AIBrain,
    adaptive = import("/lua/aibrains/base.lua").AIBrain,
    random = import("/lua/aibrains/base.lua").AIBrain,

    techcheat = import("/lua/aibrains/base.lua").AIBrain,
    rushcheat = import("/lua/aibrains/base.lua").AIBrain,
    easycheat = import("/lua/aibrains/base.lua").AIBrain,
    normalcheat = import("/lua/aibrains/base.lua").AIBrain,
    adaptivecheat = import("/lua/aibrains/base.lua").AIBrain,
    randomcheat = import("/lua/aibrains/base.lua").AIBrain,

    -- sorian AIs
    sorian = import("/lua/aibrains/sorian.lua").AIBrain,
    sorianwater = import("/lua/aibrains/sorian.lua").AIBrain,
    sorianair = import("/lua/aibrains/sorian.lua").AIBrain,
    sorianrush = import("/lua/aibrains/sorian.lua").AIBrain,
    sorianturtle = import("/lua/aibrains/sorian.lua").AIBrain,
    sorianadaptive = import("/lua/aibrains/sorian.lua").AIBrain,

    soriancheat = import("/lua/aibrains/sorian.lua").AIBrain,
    sorianwatercheat = import("/lua/aibrains/sorian.lua").AIBrain,
    sorianaircheat = import("/lua/aibrains/sorian.lua").AIBrain,
    sorianrushcheat = import("/lua/aibrains/sorian.lua").AIBrain,
    sorianturtlecheat = import("/lua/aibrains/sorian.lua").AIBrain,
    sorianadaptivecheat = import("/lua/aibrains/sorian.lua").AIBrain,
}