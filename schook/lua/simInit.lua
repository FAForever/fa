--===================================================================================
-- Do global init and set up common global functions
--===================================================================================
doscript '/lua/SimSync.lua'

local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')

local baseSetupSession = SetupSession
function SetupSession()
    ScenarioInfo.TriggerManager = import('/lua/TriggerManager.lua').Manager
    TriggerManager = ScenarioInfo.TriggerManager
    baseSetupSession()
end

local baseBeginSession = BeginSession
function BeginSession()
    ScenarioUtils.CreateProps()
    ScenarioUtils.CreateResources()

    baseBeginSession()

    import('/lua/sim/score.lua').init()

    --start watching for victory conditions
    ForkThread(import('/lua/victory.lua').CheckVictory, ScenarioInfo)
end

local basePostLoad = OnPostLoad
function OnPostLoad()
    basePostLoad()
    import('/lua/ScenarioFramework.lua').OnPostLoad()
    import('/lua/SimObjectives.lua').OnPostLoad()
    import('/lua/sim/SimUIState.lua').OnPostLoad()
    import('/lua/SimPing.lua').OnArmyChange()
    import('/lua/SimPingGroup.lua').OnPostLoad()
    import('/lua/SimDialogue.lua').OnPostLoad()
    import('/lua/SimSync.lua').OnPostLoad()
    if GetFocusArmy() ~= -1 then
        Sync.SetAlliedVictory = ArmyBrains[GetFocusArmy()].RequestingAlliedVictory or false
    end
end

local baseOnCreateArmyBrain = OnCreateArmyBrain
function OnCreateArmyBrain(index, brain, name, nickname)
    ScenarioUtils.InitializeStartLocation(name)
    ScenarioUtils.SetPlans(name)

    baseOnCreateArmyBrain(index,brain,name,nickname)
end

for k,file in DiskFindFiles('/lua/AI/PlatoonTemplates', '*.lua') do
    import(file)
end

for k,file in DiskFindFiles('/lua/AI/AIBuilders', '*.lua') do
    import(file)
end

for k,file in DiskFindFiles('/lua/AI/AIBaseTemplates', '*.lua') do
    import(file)
end

