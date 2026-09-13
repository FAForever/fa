--******************************************************************************************************
--** Cybran SACU loadout picker
--** Used by the Quantum Gateway enhancement tab. Clicks choose slots; Queue issues a factory build.
--******************************************************************************************************

-- Note: deliberately NOT importing blueprints-sacu-combos.lua here. That file is
-- loaded via doscript() from Blueprints.lua so its functions become real globals;
-- import()-ing it as well would re-run the whole file into a second, throwaway
-- module table just to reach EnhancementSetKey. The one function we need is
-- reproduced locally below instead.

local selectedBySlot = {}

local SlotOrder = { 'LCH', 'RCH', 'Back' }

-- Exported so other UI files (construction.lua, unitview.lua, unitviewDetail.lua, ...)
-- don't each hard-code the Cybran SACU blueprint id.
CybranSacuId = 'url0301'
local ComboIdPrefix = CybranSacuId .. '_combo'

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

--- Generated combo units share the base SACU's icon (they have no icon of their
--- own). Used by construction.lua, unitview.lua and unitviewDetail.lua so the
--- build grid, queue grid and unit-view panel all fall back consistently.
--- @param id string|nil
--- @return string|nil
function UnitBuildIconId(id)
    if id and string.sub(id, 1, string.len(ComboIdPrefix)) == ComboIdPrefix then
        return CybranSacuId
    end
    return id
end

function IsCybranGatewaySelection(selection)
    if not selection or table.empty(selection) then
        return false
    end
    for _, unit in selection do
        if not (unit:IsInCategory('GATE') and unit:IsInCategory('CYBRAN')) then
            return false
        end
    end
    return true
end

function GetSacuEnhancements()
    local bp = __blueprints[CybranSacuId]
    if bp then
        return bp.Enhancements
    end
end

local function IsRemoveEnhancement(name)
    return string.sub(name, -6) == 'Remove'
end

local function EnhancementChain(name)
    local bp = __blueprints[CybranSacuId]
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

function SelectedEnhancements()
    local list = {}
    for _, slot in SlotOrder do
        local choice = selectedBySlot[slot]
        if choice then
            for _, name in choice do
                table.insert(list, name)
            end
        end
    end
    return list
end

function IsEnhancementSelected(enhId)
    for _, slot in SlotOrder do
        local choice = selectedBySlot[slot]
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
    if not slot then
        return
    end

    if modifiers and modifiers.Right or IsRemoveEnhancement(name) then
        selectedBySlot[slot] = nil
        print('SACU ' .. slot .. ' cleared')
        return
    end

    selectedBySlot[slot] = EnhancementChain(name)
    print('SACU ' .. slot .. ': ' .. name)
end

local function FindBlueprintId(enhancements)
    if table.empty(enhancements) then
        return CybranSacuId
    end

    local want = EnhancementSetKey(enhancements)
    local found = nil
    for id, bp in __blueprints do
        if type(id) == 'string' and bp and bp.EnhancementPresetAssigned then
            local assigned = bp.EnhancementPresetAssigned
            if assigned.BaseBlueprintId == CybranSacuId and assigned.Enhancements then
                if EnhancementSetKey(assigned.Enhancements) == want then
                    local realId = bp.BlueprintId or id
                    if type(realId) == 'string' and string.find(realId, CybranSacuId) then
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
    if not IsCybranGatewaySelection(selection) then
        print('Select a Cybran Quantum Gateway first')
        return
    end

    local id = FindBlueprintId(SelectedEnhancements())
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
