local Prefs = import('/lua/user/prefs.lua')
local options = Prefs.GetFromCurrentProfile('options')
local activeFilters = Prefs.GetFromCurrentProfile('activeFilters') or {}

SelectedOverlayOn = activeFilters['selection'] == true
OverlayActive = false
SelectedInfoOn = true

if options.gui_enhanced_unitview == 0 then
    SelectedInfoOn = false
end

function GetUnitRolloverInfo(unit)
    local info = {}
    local econData = unit:GetEconData()

    info.blueprintId = unit:GetBlueprint().BlueprintId
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

    if unit:GetFocus() then
        info.focus = GetUnitRolloverInfo(unit:GetFocus())
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

function ToggleOn()
    if SelectedInfoOn then
        SelectedInfoOn = false
    else
        SelectedInfoOn = true
    end
end

function EnableSelectedOverlay(bool)
    local enable = false
    SelectedOverlayOn = bool

    if SelectedOverlayOn then
        local selUnits = GetSelectedUnits()
        if selUnits and table.getn(selUnits) == 1 then
            enable = true
        end
    end

    EnableSingleRangeOverlay(enable)
end

function EnableSingleRangeOverlay(bool)
    ConExecute('range_RenderSelected ' .. tostring(bool))
    OverlayActive = bool
end
