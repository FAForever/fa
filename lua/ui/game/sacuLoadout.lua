--******************************************************************************************************
--** SACU loadout picker
--** Used by each faction's Quantum Gateway enhancement tab. Clicks choose slots; Queue issues a factory build.
--******************************************************************************************************

-- selectedBySlot[sacuId][slot] = enhancement chain for in-progress slot picks.
local selectedBySlot = {}

local SlotOrder = { 'LCH', 'RCH', 'Back' }

--- Sorted, pipe-joined key for an enhancement set. Must match the copy in
--- blueprints-sacu-combos.lua.
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

--- Base SACU icon id for a generated combo unit; anything else unchanged.
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

--- The base SACU blueprint id that `selection` can currently build, or nil if
--- ambiguous or not a factory selection.
--- @param selection Unit[]
--- @return string?
function GetSelectionSacuId(selection)
    if not selection or table.empty(selection) then
        return nil
    end

    -- Only factories can have a valid SACU loadout selection.
    if not table.empty(EntityCategoryFilterOut(categories.FACTORY, selection)) then
        return nil
    end

    local _, _, buildableCategories = GetUnitCommandData(selection)
    if not buildableCategories then
        return nil
    end

    local candidates = EntityCategoryGetUnitList(buildableCategories * categories.SACULOADOUTBASE)
    local baseSacuId = nil
    for _, id in candidates do
        local bp = __blueprints[id]
        -- The base SACU has no EnhancementPresetAssigned.
        if bp and not bp.EnhancementPresetAssigned then
            if baseSacuId then
                return nil
            end
            baseSacuId = id
        end
    end
    return baseSacuId
end

--- True if `selection` can build exactly one shared base SACU.
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

--- Blueprint id of the preset matching this combo, or nil if none.
local function ComboBlueprintId(sacuId, enhancements)
    if table.empty(enhancements) then
        return sacuId
    end

    local bp = __blueprints[sacuId]
    if not bp or not bp.EnhancementPresets then
        return nil
    end

    local want = EnhancementSetKey(enhancements)
    for presetName, preset in bp.EnhancementPresets do
        if preset.Enhancements and EnhancementSetKey(preset.Enhancements) == want then
            return string.lower(sacuId .. '_' .. presetName)
        end
    end
    return nil
end

--- Queues the currently-selected loadout at the gateway.
--- @param count? integer
--- @return boolean success
--- @return string idOrReason the queued blueprint id on success, else a failure reason
function QueueSelected(count)
    count = count or 1
    local selection = GetSelectedUnits() or {}
    local sacuId = GetSelectionSacuId(selection)
    if not sacuId then
        return false, 'Selection cannot build any units with loadouts'
    end

    local id = ComboBlueprintId(sacuId, SelectedEnhancements(sacuId))
    if not id then
        return false, 'No blueprint for that loadout'
    end

    IssueBlueprintCommand("UNITCOMMAND_BuildFactory", id, count)
    return true, id
end
