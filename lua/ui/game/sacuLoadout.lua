--******************************************************************************************************
--** Cybran SACU loadout picker
--** UI-only. Queues a real unit ID via UNITCOMMAND_BuildFactory.
--******************************************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Button = import("/lua/maui/button.lua").Button
local Group = import("/lua/maui/group.lua").Group

local ComboLogic = import("/lua/system/blueprints-sacu-combos.lua")

local dialog
local selectedBySlot = {}

local SlotOrder = { 'LCH', 'RCH', 'Back' }
local SlotLabels = {
    LCH = 'Left',
    RCH = 'Right',
    Back = 'Back',
}

local CybranSacuId = 'url0301'
local CybranGatewayCategory = categories.CYBRAN * categories.FACTORY * categories.GATE

local function SelectedCybranGates()
    local selection = GetSelectedUnits() or {}
    return EntityCategoryFilterDown(CybranGatewayCategory, selection)
end

local function IsRemoveEnhancement(name)
    return string.sub(name, -6) == 'Remove'
end

local function ChoicesForSlot(bp, slot)
    local choices = {
        { label = '(none)', enhancements = {}, icon = nil },
    }

    local names = {}
    for name, def in bp.Enhancements or {} do
        if def.Slot == slot and not IsRemoveEnhancement(name) then
            table.insert(names, name)
        end
    end
    table.sort(names)

    for _, name in names do
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

        local def = bp.Enhancements[name]
        choices[table.getn(choices) + 1] = {
            label = LOC(def.Name or name),
            enhancements = chain,
            icon = def.Icon,
        }
    end

    return choices
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

local function SumCosts(enhancements)
    local base = __blueprints[CybranSacuId]
    local mass = base.Economy.BuildCostMass or 0
    local energy = base.Economy.BuildCostEnergy or 0
    local time = base.Economy.BuildTime or 0
    for _, name in enhancements do
        local def = base.Enhancements[name]
        if def then
            mass = mass + (def.BuildCostMass or 0)
            energy = energy + (def.BuildCostEnergy or 0)
            time = time + (def.BuildTime or 0)
        end
    end
    return mass, energy, time
end

local function SelectedEnhancements()
    local list = {}
    for _, slot in SlotOrder do
        local choice = selectedBySlot[slot]
        if choice and choice.enhancements then
            for _, name in choice.enhancements do
                table.insert(list, name)
            end
        end
    end
    return list
end

local function DestroyDialog()
    if dialog then
        dialog:Destroy()
        dialog = nil
    end
end

local function QueueSelected(count)
    count = count or 1
    local gates = SelectedCybranGates()
    if table.empty(gates) then
        print('Select a Cybran Quantum Gateway first')
        return
    end

    local id = FindBlueprintId(SelectedEnhancements())
    if not id then
        print('No blueprint for that loadout (was combo generation running?)')
        return
    end

    IssueBlueprintCommand("UNITCOMMAND_BuildFactory", id, count)
end

local function EnhancementIcon(parent, iconName)
    local bmp = Bitmap(parent)
    if iconName then
        local path = UIUtil.UIFile('/game/cybran-enhancements/' .. iconName .. '_btn_up.dds')
        if DiskGetFileInfo(path) then
            bmp:SetTexture(path)
        else
            bmp:SetSolidColor('ff444444')
        end
    else
        bmp:SetSolidColor('ff222222')
    end
    LayoutHelpers.SetDimensions(bmp, 44, 44)
    return bmp
end

function CreateDialog()
    DestroyDialog()

    local base = __blueprints[CybranSacuId]
    if not base or not base.Enhancements then
        print('Cybran SACU blueprint not found')
        return
    end

    local parent = GetFrame(0)
    dialog = Bitmap(parent)
    dialog:SetSolidColor('cc111111')
    dialog.Depth:Set(function() return parent.Depth() + 100 end)
    LayoutHelpers.AtCenterIn(dialog, parent)
    LayoutHelpers.SetDimensions(dialog, 560, 420)

    local title = UIUtil.CreateText(dialog, 'Cybran SACU loadout', 16, UIUtil.titleFont)
    LayoutHelpers.AtTopIn(title, dialog, 12)
    LayoutHelpers.AtHorizontalCenterIn(title, dialog)

    local hint = UIUtil.CreateText(dialog, 'Pick one option per slot, then queue.', 11, UIUtil.bodyFont)
    LayoutHelpers.Below(hint, title, 6)
    LayoutHelpers.AtHorizontalCenterIn(hint, dialog)

    selectedBySlot = {}
    local columnWidth = 170
    local startX = 20

    local costLabel = UIUtil.CreateText(dialog, '', 12, UIUtil.bodyFont)
    LayoutHelpers.AtBottomIn(costLabel, dialog, 52)
    LayoutHelpers.AtLeftIn(costLabel, dialog, 16)

    local idLabel = UIUtil.CreateText(dialog, '', 10, UIUtil.bodyFont)
    LayoutHelpers.Below(idLabel, costLabel, 2)
    LayoutHelpers.AtLeftIn(idLabel, dialog, 16)

    local function RefreshSummary()
        local enh = SelectedEnhancements()
        local mass, energy, time = SumCosts(enh)
        costLabel:SetText(string.format('Mass %d   Energy %d   Build time %d', mass, energy, time))
        local id = FindBlueprintId(enh)
        idLabel:SetText('Queues: ' .. tostring(id or '(missing blueprint)'))
    end

    for slotIndex, slot in SlotOrder do
        local header = UIUtil.CreateText(dialog, SlotLabels[slot] or slot, 14, UIUtil.titleFont)
        LayoutHelpers.AtLeftTopIn(header, dialog, startX + (slotIndex - 1) * columnWidth, 70)

        local choices = ChoicesForSlot(base, slot)
        selectedBySlot[slot] = choices[1]

        local last = header
        for _, choice in choices do
            local row = Group(dialog)
            LayoutHelpers.SetDimensions(row, 160, 48)
            LayoutHelpers.Below(row, last, 6)
            LayoutHelpers.AtLeftIn(row, header)

            local icon = EnhancementIcon(row, choice.icon)
            LayoutHelpers.AtLeftIn(icon, row)
            LayoutHelpers.AtVerticalCenterIn(icon, row)

            local btn = Button(row)
            btn:SetSolidColor('ff2a2a2a')
            LayoutHelpers.SetDimensions(btn, 110, 40)
            LayoutHelpers.RightOf(btn, icon, 4)
            LayoutHelpers.AtVerticalCenterIn(btn, row)

            local label = UIUtil.CreateText(btn, choice.label, 10, UIUtil.bodyFont)
            LayoutHelpers.AtCenterIn(label, btn)

            btn.choice = choice
            btn.slot = slot
            btn.OnClick = function(self)
                selectedBySlot[self.slot] = self.choice
                RefreshSummary()
            end

            last = row
        end
    end

    local queueBtn = UIUtil.CreateButtonStd(dialog, '/widgets02/small', 'Queue 1', 12)
    LayoutHelpers.AtBottomIn(queueBtn, dialog, 12)
    LayoutHelpers.AtRightIn(queueBtn, dialog, 110)
    queueBtn.OnClick = function()
        QueueSelected(1)
    end

    local queueFive = UIUtil.CreateButtonStd(dialog, '/widgets02/small', 'Queue 5', 12)
    LayoutHelpers.AtBottomIn(queueFive, dialog, 12)
    LayoutHelpers.AtRightIn(queueFive, dialog, 16)
    queueFive.OnClick = function()
        QueueSelected(5)
    end

    local closeBtn = UIUtil.CreateButtonStd(dialog, '/widgets02/small', 'Close', 12)
    LayoutHelpers.AtBottomIn(closeBtn, dialog, 12)
    LayoutHelpers.AtLeftIn(closeBtn, dialog, 16)
    closeBtn.OnClick = function()
        DestroyDialog()
    end

    RefreshSummary()
end

function Toggle()
    if dialog then
        DestroyDialog()
    else
        CreateDialog()
    end
end

function Open()
    CreateDialog()
end

function Close()
    DestroyDialog()
end
