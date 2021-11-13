local unit_methodsGetStat = moho.unit_methods.GetStat
local unit_methodsGetWorkProgress = moho.unit_methods.GetWorkProgress
local unit_methodsGetFuelRatio = moho.unit_methods.GetFuelRatio
local unit_methodsGetShieldRatio = moho.unit_methods.GetShieldRatio

local Prefs = import('/lua/user/prefs.lua')
local options = Prefs.GetFromCurrentProfile('options')

local selectionOverlay = {
        key = 'selection',
        Label = "<LOC map_options_0006>Selection",
        Pref = 'range_RenderSelected',
        Type = 3,
        Tooltip = "overlay_selection",
}

function GetUnitRolloverInfo(unit)
    local info = {}

    info.blueprintId = unit:GetBlueprint().BlueprintId

    local econData = unit:GetEconData()

    info.energyConsumed = econData["energyConsumed"]
    info.energyProduced = econData["energyProduced"]
    info.energyRequested = econData["energyRequested"]
    info.massConsumed = econData["massConsumed"]
    info.massProduced = econData["massProduced"]
    info.massRequested = econData["massRequested"]

    info.entityId = unit:GetEntityId()

    info.maxHealth = unit:GetMaxHealth()
    info.health = unit:GetHealth()
    info.fuelRatio = unit_methodsGetFuelRatio(unit)
    info.shieldRatio = unit_methodsGetShieldRatio(unit)
    info.workProgress = unit_methodsGetWorkProgress(unit)

    if unit:GetFocus() then
        info.focus = GetUnitRolloverInfo(unit:GetFocus())
    end

    local killStat = unit_methodsGetStat(unit, 'KILLS')
    info.kills = killStat.Value

    local missileInfo = unit:GetMissileInfo()
    info.nukeSiloBuildCount = missileInfo.nukeSiloBuildCount
    info.nukeSiloMaxStorageCount = missileInfo.nukeSiloMaxStorageCount
    info.nukeSiloStorageCount = missileInfo.nukeSiloStorageCount
    info.tacticalSiloBuildCount = missileInfo.tacticalSiloBuildCount
    info.tacticalSiloMaxStorageCount = missileInfo.tacticalSiloMaxStorageCount
    info.tacticalSiloStorageCount = missileInfo.tacticalSiloStorageCount

    info.customName = unit:GetCustomName(unit)
    info.userUnit = unit
    info.armyIndex = unit:GetArmy() - 1

    return info
end

