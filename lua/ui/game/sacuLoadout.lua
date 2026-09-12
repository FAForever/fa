--******************************************************************************************************
--** Cybran SACU loadout picker
--** Used by the Quantum Gateway enhancement tab. Clicks choose slots; Queue issues a factory build.
--******************************************************************************************************

local ComboLogic = import("/lua/system/blueprints-sacu-combos.lua")

local selectedBySlot = {}

local SlotOrder = { 'LCH', 'RCH', 'Back' }
local CybranSacuId = 'url0301'

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

    local want = ComboLogic.EnhancementSetKey(enhancements)
    for id, bp in __blueprints do
        local assigned = bp.EnhancementPresetAssigned
        if assigned and assigned.BaseBlueprintId == CybranSacuId and assigned.Enhancements then
            if ComboLogic.EnhancementSetKey(assigned.Enhancements) == want then
                return id
            end
        end
    end
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
