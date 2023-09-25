--*****************************************************************************
--* File: lua/modules/ui/game/controlgroups.lua
--*
--* Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local GameMain = import("/lua/ui/game/gamemain.lua")
local Group = import("/lua/maui/group.lua").Group
local Button = import("/lua/maui/button.lua").Button
local Checkbox = import("/lua/maui/checkbox.lua").Checkbox
local Movie = import("/lua/maui/movie.lua").Movie
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local GameCommon = import("/lua/ui/game/gamecommon.lua")
local Announcement = import("/lua/ui/game/announcement.lua").CreateAnnouncement
local Selection = import("/lua/ui/game/selection.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")

controls = {
    groups = {},
}

validGroups = {
    ['1'] = true,
    ['2'] = true,
    ['3'] = true,
    ['4'] = true,
    ['5'] = true,
    ['6'] = true,
    ['7'] = true,
    ['8'] = true,
    ['9'] = true,
    ['0'] = true,
}

groupOrder = {'1','2','3','4','5','6','7','8','9','0'}

function CreateUI(mapGroup)
    controls.parent = mapGroup

    controls.container = Group(controls.parent)
    controls.container.Depth:Set(100)

    controls.bgTop = Bitmap(controls.container)
    controls.bgBottom = Bitmap(controls.container)
    controls.bgStretch = Bitmap(controls.container)
    controls.collapseArrow = Checkbox(controls.parent)
    controls.collapseArrow.OnCheck = function(self, checked)
        ToggleControlGroups(checked)
    end
    Tooltip.AddCheckboxTooltip(controls.collapseArrow, 'control_collapse')

    controls.container:DisableHitTest(true)

    Selection.RegisterSelectionSetCallback(OnSelectionSetChanged)

    ForkThread(CheckGroups)

    controls.container:Hide()
    SetLayout()
    for i, v in validGroups do
        import("/lua/ui/game/selection.lua").ApplySelectionSet(i)
    end
end

function CheckGroups()
    while controls.container do
        for i, v in controls.groups do
            v:UpdateGroup()
        end
        WaitSeconds(1)
    end
end

function SetLayout()
    import(UIUtil.GetLayoutFilename('controlgroups')).SetLayout()
end

function OnSelectionSetChanged(name, units, applied)
    if not validGroups[name] then return end
    local function CreateGroup(units, label)
        local bg = Bitmap(controls.container, UIUtil.SkinnableFile('/game/avatar/avatar-control-group_bmp.dds'))

        bg.icon = Bitmap(bg)
        LayoutHelpers.SetDimensions(bg.icon, 28, 20)
        LayoutHelpers.AtCenterIn(bg.icon, bg, 0, -4)

        bg.label = UIUtil.CreateText(bg.icon, label, 18, UIUtil.bodyFont)
        bg.label:SetColor('ffffffff')
        bg.label:SetDropShadow(true)
        LayoutHelpers.AtRightIn(bg.label, bg.icon)
        LayoutHelpers.AtBottomIn(bg.label, bg, 5)

        bg.icon:DisableHitTest()
        bg.label:DisableHitTest()

        bg.units = units

        bg.UpdateGroup = function(self)
            self.units = ValidateUnitsList(self.units)

            if not table.empty(self.units) then
                local sortedUnits = {}
                sortedUnits[1] = EntityCategoryFilterDown(categories.COMMAND, self.units)
                sortedUnits[2] = EntityCategoryFilterDown(categories.EXPERIMENTAL, self.units)
                sortedUnits[3] = EntityCategoryFilterDown(categories.TECH3 - categories.FACTORY, self.units)
                sortedUnits[4] = EntityCategoryFilterDown(categories.TECH2 - categories.FACTORY, self.units)
                sortedUnits[5] = EntityCategoryFilterDown(categories.TECH1 - categories.FACTORY, self.units)
                sortedUnits[6] = EntityCategoryFilterDown(categories.FACTORY, self.units)

                local iconID = ''
                for _, unitTable in sortedUnits do
                    if not table.empty(unitTable) then
                        iconID = unitTable[1]:GetBlueprint().BlueprintId
                        break
                    end
                end
                if iconID ~= '' and UIUtil.UIFile('/icons/units/' .. iconID .. '_icon.dds', true) then
                    self.icon:SetTexture(UIUtil.UIFile('/icons/units/' .. iconID .. '_icon.dds', true))
                else
                    self.icon:SetTexture('/textures/ui/common/icons/units/default_icon.dds')
                end
            else
                self:Destroy()
                controls.groups[self.name] = nil
            end
        end
        bg.name = label
        bg.HandleEvent = function(self,event)
            if event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
                if event.Modifiers.Shift and event.Modifiers.Ctrl then
                    Selection.FactorySelection(self.name)
                elseif event.Modifiers.Shift then
                    Selection.AppendSetToSelection(self.name)
                elseif event.Modifiers.Left then
                    Selection.ApplySelectionSet(self.name)
                elseif event.Modifiers.Right then
                    Selection.AppendSelectionToSet(self.name)
                end
            end
        end

        bg:UpdateGroup()

        return bg
    end
    if not controls.groups[name] and units then
        PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Economy_Click'}))
        controls.groups[name] = CreateGroup(units, name)
        local unitIDs = {}
        for _, unit in units do
            table.insert(unitIDs, unit:GetEntityId())
        end
        SimCallback({Func = 'OnControlGroupAssign', Args = unitIDs})
    elseif controls.groups[name] and not units then
        controls.groups[name]:Destroy()
        controls.groups[name] = nil
    elseif controls.groups[name] then
        controls.groups[name].units = units
        controls.groups[name]:UpdateGroup()
        local unitIDs = {}
        for _, unit in units do
            table.insert(unitIDs, unit:GetEntityId())
        end
        SimCallback({Func = 'OnControlGroupAssign', Args = unitIDs})
    end
    import(UIUtil.GetLayoutFilename('controlgroups')).LayoutGroups()
end

function ToggleControlGroups(state)
    -- disable when in Screen Capture mode
    if import("/lua/ui/game/gamemain.lua").gameUIHidden then
        return
    end

    if UIUtil.GetAnimationPrefs() then
        if controls.container:IsHidden() then
            PlaySound(Sound({Cue = "UI_Score_Window_Open", Bank = "Interface"}))
            controls.collapseArrow:SetCheck(false, true)
            controls.container:Show()
            controls.container:SetNeedsFrameUpdate(true)
            controls.container.OnFrame = function(self, delta)
                local newRight = self.Right() - (1000*delta)
                if newRight < controls.parent.Right() - 0 then
                    newRight = function() return controls.parent.Right() - 0 end
                    self:SetNeedsFrameUpdate(false)
                end
                self.Right:Set(newRight)
            end
        else
            PlaySound(Sound({Cue = "UI_Score_Window_Close", Bank = "Interface"}))
            controls.container:SetNeedsFrameUpdate(true)
            controls.container.OnFrame = function(self, delta)
                local newRight = self.Right() + (1000*delta)
                if newRight > controls.parent.Right() + self.Width() then
                    newRight = function() return controls.parent.Right() + self.Width() end
                    self:Hide()
                    self:SetNeedsFrameUpdate(false)
                end
                self.Right:Set(newRight)
            end
            controls.collapseArrow:SetCheck(true, true)
        end
    else
        if state or controls.container:IsHidden() then
            controls.container:Show()
            controls.collapseArrow:SetCheck(true, true)
        else
            controls.container:Hide()
            controls.collapseArrow:SetCheck(false, true)
        end
    end
end

function Contract()
    controls.container:Hide()
    controls.collapseArrow:Hide()
end

function Expand()
    if not table.empty(controls.groups) then
        controls.container:Show()
        controls.collapseArrow:Show()
    end
end

function InitialAnimation()
    --controls.container:Show()
    controls.container.Left:Set(controls.parent.Left()-controls.container.Width())
    controls.container:SetNeedsFrameUpdate(true)
    controls.container.OnFrame = function(self, delta)
        local newLeft = self.Left() + (1000*delta)
        if newLeft > controls.parent.Left()-3 then
            newLeft = function() return controls.parent.Left()-3 end
            self:SetNeedsFrameUpdate(false)
        end
        self.Left:Set(newLeft)
    end
    --controls.collapseArrow:Show()
    controls.collapseArrow:SetCheck(false, true)
end