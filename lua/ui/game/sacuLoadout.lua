--******************************************************************************************************
--** SACU loadout picker
--** Used by each faction's Quantum Gateway enhancement tab. Clicks choose slots; Queue issues a factory build.
--******************************************************************************************************

-- Note: deliberately NOT importing blueprints-sacu-combos.lua here. That file is
-- loaded via doscript() from Blueprints.lua so its functions become real globals;
-- import()-ing it as well would re-run the whole file into a second, throwaway
-- module table just to reach EnhancementSetKey. The one function we need is
-- reproduced locally below instead.

-- selectedBySlot[sacuId][slot] = enhancement chain. Keyed per-SACU (not just per-slot)
-- so switching selection between, say, a UEF and an Aeon gateway can't leave a stale
-- enhancement name from one faction selected against another's slot picker.
local selectedBySlot = {}

local SlotOrder = { 'LCH', 'RCH', 'Back' }

-- Base SACU blueprint id for each faction, keyed by the faction category that the
-- Quantum Gateway (and the SACU it builds) both carry. Exported so other UI files
-- (construction.lua, unitview.lua, unitviewDetail.lua, ...) don't each hard-code
-- the ids themselves.
FactionSacuIds = {
    UEF = 'uel0301',
    AEON = 'ual0301',
    CYBRAN = 'url0301',
    SERAPHIM = 'xsl0301',
}
local ComboIdSuffix = '_combo'

--- Which of FactionSacuIds' factions (if any) a unit belongs to.
--- @param unit Unit
--- @return string|nil faction category, e.g. 'CYBRAN'
local function GetUnitSacuFaction(unit)
    for faction in FactionSacuIds do
        if unit:IsInCategory(faction) then
            return faction
        end
    end
end

--- Sorted, pipe-joined key for an enhancement set. Must stay identical to the
--- copy in blueprints-sacu-combos.lua, since both sides need to agree on the
--- generated combo preset names.
--- @param list string[]
--- @return string
local function EnhancementSetKey(list)
    local copy = {}
    for _, name in list do
        table.insert(copy, name)
    end
    table.sort(copy)
    return string.lower(table.concat(copy, '|'))
end

--- Generated combo units share their base SACU's icon (they have no icon of their
--- own). Used by construction.lua, unitview.lua and unitviewDetail.lua so the
--- build grid, queue grid and unit-view panel all fall back consistently, for
--- every faction's combos.
--- @param id string|nil
--- @return string|nil
function UnitBuildIconId(id)
    if type(id) ~= 'string' then
        return id
    end
    for _, sacuId in FactionSacuIds do
        local prefix = sacuId .. ComboIdSuffix
        if string.sub(id, 1, string.len(prefix)) == prefix then
            return sacuId
        end
    end
    return id
end

--- True if every unit in the selection is a Quantum Gateway belonging to the
--- SAME known faction. A mixed-faction selection is rejected outright (rather
--- than accepted and half-honored) because QueueSelected only ever derives
--- one preset id, from selection[1]'s faction, and issues it to the whole
--- selection - a gateway of a different faction would silently reject that
--- blueprint id and queue nothing, which is the "strange behavior" this
--- guards against.
function IsGatewaySelection(selection)
    if not selection or table.empty(selection) then
        return false
    end
    local faction = nil
    for _, unit in selection do
        if not unit:IsInCategory('GATE') then
            return false
        end
        local unitFaction = GetUnitSacuFaction(unit)
        if not unitFaction or (faction and unitFaction ~= faction) then
            return false
        end
        faction = unitFaction
    end
    return true
end

--- The SACU blueprint id the current selection's gateway(s) build. Like the rest
--- of this picker, assumes a selection is a single faction's gateways - mixed
--- selections just use the first unit's faction.
--- @param selection Unit[]
--- @return string|nil
function GetSelectionSacuId(selection)
    if not selection or table.empty(selection) then
        return nil
    end
    local faction = GetUnitSacuFaction(selection[1])
    return faction and FactionSacuIds[faction]
end

function GetSacuEnhancements(sacuId)
    local bp = sacuId and __blueprints[sacuId]
    if bp then
        return bp.Enhancements
    end
end

local function IsRemoveEnhancement(name)
    return string.sub(name, -6) == 'Remove'
end

local function EnhancementChain(sacuId, name)
    local bp = __blueprints[sacuId]
    local chain = { name }
    local current = name
    local guard = 0
    while bp.Enhancements[current] and bp.Enhancements[current].Prerequisite and guard < 8 do
        local pre = bp.Enhancements[current].Prerequisite
        if not bp.Enhancements[pre] or IsRemoveEnhancement(pre) then
            break
        end
        table.insert(chain, 1, pre)
        current = pre
        guard = guard + 1
    end
    return chain
end

local function SlotMapFor(sacuId)
    selectedBySlot[sacuId] = selectedBySlot[sacuId] or {}
    return selectedBySlot[sacuId]
end

function SelectedEnhancements(sacuId)
    local list = {}
    local slots = selectedBySlot[sacuId]
    if not slots then
        return list
    end
    for _, slot in SlotOrder do
        local choice = slots[slot]
        if choice then
            for _, name in choice do
                table.insert(list, name)
            end
        end
    end
    return list
end

function IsEnhancementSelected(sacuId, enhId)
    local slots = selectedBySlot[sacuId]
    if not slots then
        return false
    end
    for _, slot in SlotOrder do
        local choice = slots[slot]
        if choice and choice[table.getn(choice)] == enhId then
            return true
        end
    end
    return false
end

function OnSlotIconClick(item, modifiers)
    local enh = item.enhTable or item
    local name = enh.ID or item.id
    local slot = enh.Slot
    local sacuId = enh.UnitID
    if not slot or not sacuId then
        return
    end

    local slots = SlotMapFor(sacuId)
    if modifiers and modifiers.Right or IsRemoveEnhancement(name) then
        slots[slot] = nil
        print('SACU ' .. slot .. ' cleared')
        return
    end

    slots[slot] = EnhancementChain(sacuId, name)
    print('SACU ' .. slot .. ': ' .. name)
end

local function FindBlueprintId(sacuId, enhancements)
    if table.empty(enhancements) then
        return sacuId
    end

    local want = EnhancementSetKey(enhancements)
    local found = nil
    for id, bp in __blueprints do
        if type(id) == 'string' and bp and bp.EnhancementPresetAssigned then
            local assigned = bp.EnhancementPresetAssigned
            if assigned.BaseBlueprintId == sacuId and assigned.Enhancements then
                if EnhancementSetKey(assigned.Enhancements) == want then
                    local realId = bp.BlueprintId or id
                    if type(realId) == 'string' and string.find(realId, sacuId) then
                        found = realId
                        if string.find(realId, 'combo_') then
                            return realId
                        end
                    end
                end
            end
        end
    end
    return found
end

function QueueSelected(count)
    count = count or 1
    local selection = GetSelectedUnits() or {}
    if not IsGatewaySelection(selection) then
        print('Select a Quantum Gateway first')
        return
    end

    local sacuId = GetSelectionSacuId(selection)
    local id = sacuId and FindBlueprintId(sacuId, SelectedEnhancements(sacuId))
    if not id then
        print('No blueprint for that loadout')
        return
    end

    IssueBlueprintCommand("UNITCOMMAND_BuildFactory", id, count)
    print('Queued ' .. id)
end

-- Old floating dialog kept for console testing.
function Open()
    QueueSelected(1)
end

function Toggle()
    QueueSelected(1)
end

function Close()
end
