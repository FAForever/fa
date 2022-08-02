local Prefs = import('/lua/user/prefs.lua')
local options = Prefs.GetFromCurrentProfile('options')

local selectionOverlay = {
    key = 'selection',
    Label = "<LOC map_options_0006>Selection",
    Pref = 'range_RenderSelected',
    Type = 3,
    Tooltip = "overlay_selection",
}

function GetUnitRolloverInfo(unit, skipFocus)
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
    info.fuelRatio = unit:GetFuelRatio()
    info.shieldRatio = unit:GetShieldRatio()
    info.workProgress = unit:GetWorkProgress()

    local focus = unit:GetFocus()
    if focus and not skipFocus then
        _visited = { [unit:GetEntityId()] = true }
        while focus do
            if _visited[focus:GetEntityId()] then
                info.focus = GetUnitRolloverInfo(unit:GetFocus(), true)
                break
            end
            _visited[focus:GetEntityId()] = true
            info.focus = focus
            focus = focus:GetFocus()
        end
    end

    local killStat = unit:GetStat('KILLS')
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
