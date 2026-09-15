--******************************************************************************************************
--** SACU loadout picker
--** Used by each faction's Quantum Gateway enhancement tab. Clicks choose slots; Queue issues a factory build.
--******************************************************************************************************

-- selectedBySlot[sacuId][slot] = enhancement chain. Keyed per-SACU (not just per-slot)
-- so switching selection between, say, a UEF and an Aeon gateway can't leave a stale
-- enhancement name from one faction selected against another's slot picker.
local selectedBySlot = {}

local SlotOrder = { 'LCH', 'RCH', 'Back' }

--- Sorted, pipe-joined key for an enhancement set. Must stay identical to the
--- copy in blueprints-sacu-combos.lua, since both sides need to agree on the
--- generated combo preset names.
-- Reproduced here instead of imported - that file is loaded via doscript()
-- from Blueprints.lua, and import()-ing it too would re-run it into a
-- second, throwaway module table just for this one function.
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
--- every faction's combos - vanilla or added by a mod, since this checks the
--- SACULOADOUTCOMBO category (set by MarkHiddenSacuLoadoutPresets in
--- blueprints-sacu-combos.lua) and the preset's own recorded base id rather
--- than a hardcoded faction/id table.
--- @param id? string
--- @return string?
function UnitBuildIconId(id)
    if type(id) ~= 'string' then
        return id
    end
    local bp = __blueprints[id]
    local assigned = bp and bp.EnhancementPresetAssigned
    if bp and bp.CategoriesHash and bp.CategoriesHash['SACULOADOUTCOMBO'] and assigned then
        return assigned.BaseBlueprintId or id
    end
    return id
end

--- The base SACU blueprint id that `selection` can currently build, derived
--- from the selection's real build capability (GetUnitCommandData) rather than
--- a hardcoded GATE-category/faction table. This means it works for any unit
--- that can build a SACU - a custom faction's gateway, a mod that grants the
--- ability to a non-gateway unit, "All Faction Quantum Gate", or construction
--- rules changed mid-match by another mod - not just units tagged GATE with
--- one of the four vanilla faction categories.
--- A selection that can build more than one distinct base SACU is treated as
--- ambiguous and rejected (returns nil) rather than half-honored, for the same
--- reason a mixed-faction selection used to be rejected: QueueSelected only
--- ever issues one blueprint id to the whole selection. A selection with any
--- non-factory unit in it is rejected outright for the same reason.
--- @param selection Unit[]
--- @return string?
function GetSelectionSacuId(selection)
    if not selection or table.empty(selection) then
        return nil
    end

    -- Reject a selection with anything other than factories outright, rather
    -- than trusting GetUnitCommandData's buildableCategories result alone -
    -- same "don't half-honor an ambiguous selection" reasoning as the
    -- multi-base-SACU check below.
    if not table.empty(EntityCategoryFilterOut(categories.FACTORY, selection)) then
        return nil
    end

    local _, _, buildableCategories = GetUnitCommandData(selection)
    if not buildableCategories then
        return nil
    end

    local buildableUnits = EntityCategoryGetUnitList(buildableCategories * categories.SUBCOMMANDER)
    local baseSacuId = nil
    for _, id in buildableUnits do
        local bp = __blueprints[id]
        -- The base SACU is the one entry with no EnhancementPresetAssigned -
        -- every loadout preset (hand-authored or our generated combos) is a
        -- clone of it and carries that field.
        if bp and not bp.EnhancementPresetAssigned then
            if baseSacuId and baseSacuId ~= id then
                return nil
            end
            baseSacuId = id
        end
    end
    return baseSacuId
end

--- True if `selection` can currently build exactly one shared base SACU.
--- Used to decide whether to show the "Queue SACU loadout" order/button at
--- all; QueueSelected below calls GetSelectionSacuId itself to know what to
--- actually build.
--- @param selection Unit[]
--- @return boolean
function IsGatewaySelection(selection)
    return GetSelectionSacuId(selection) ~= nil
end

--- Enhancement definitions on sacuId's blueprint, keyed by enhancement name.
--- @param sacuId? UnitId
--- @return table<string, UnitBlueprintEnhancement>?
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
    local depth = 0
    while bp.Enhancements[current] and bp.Enhancements[current].Prerequisite and depth < 8 do
        local pre = bp.Enhancements[current].Prerequisite
        if not bp.Enhancements[pre] or IsRemoveEnhancement(pre) then
            break
        end
        table.insert(chain, 1, pre)
        current = pre
        depth = depth + 1
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
        if bp and bp.BaseBlueprintId == sacuId and bp.EnhancementPresetAssigned then
            local assigned = bp.EnhancementPresetAssigned
            if assigned.Enhancements and EnhancementSetKey(assigned.Enhancements) == want then
                local realId = bp.BlueprintId or id
                found = realId
                if type(realId) == 'string' and string.find(realId, 'combo_') then
                    return realId
                end
            end
        end
    end
    return found
end

--- Queues the currently-selected loadout at the gateway. Leaves presenting
--- the result to the caller rather than printing here, so the UI can decide
--- how to show success/failure (sound, message, etc).
--- @param count? integer
--- @return boolean success
--- @return string idOrReason the queued blueprint id on success, else a failure reason
function QueueSelected(count)
    count = count or 1
    local selection = GetSelectedUnits() or {}
    if not IsGatewaySelection(selection) then
        return false, 'Select a Quantum Gateway first'
    end

    local sacuId = GetSelectionSacuId(selection)
    local id = sacuId and FindBlueprintId(sacuId, SelectedEnhancements(sacuId))
    if not id then
        return false, 'No blueprint for that loadout'
    end

    IssueBlueprintCommand("UNITCOMMAND_BuildFactory", id, count)
    return true, id
end
