--*****************************************************************************
--* File: lua/modules/ui/lobby/restrictedUnitsDlg.lua
--* Author: Chris Blackwell
--* Summary: Dialog to allow user to select what units they would like to disable
--* in a skirmish game
--*
--* Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Group = import("/lua/maui/group.lua").Group
local Checkbox = import("/lua/maui/checkbox.lua").Checkbox

local restrictedUnits = import("/lua/ui/lobby/restrictedUnitsData.lua").restrictedUnits

function CreateDialog(parent, initialRestrictions, OnOk, OnCancel, isHost)
     
    -- build a set of what's currently restricted to make it easy for initial setup
    local initialRestrictedSet = {}
    if initialRestrictions then
        for index, restriction in initialRestrictions do
            initialRestrictedSet[restriction] = true
        end
    end

    local dialog = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_m.dds'))
    LayoutHelpers.AtCenterIn(dialog, parent)
    LayoutHelpers.DepthOverParent(dialog, parent, 100)
    dialog.Width:Set(300)
    dialog.Height:Set(450)
    
    dialog.border = CreateBorder(dialog)
    dialog.brackets = UIUtil.CreateDialogBrackets(dialog, 118, 106, 118, 104)
    
    local title = UIUtil.CreateText(dialog, "<LOC restricted_units_dlg_0000>Unit Manager", 20, UIUtil.titleFont)
    LayoutHelpers.AtTopIn(title, dialog.border.tm, 12)
    LayoutHelpers.AtHorizontalCenterIn(title, dialog)
    
    local cancelBtn = UIUtil.CreateButtonStd(dialog, '/scx_menu/small-btn/small', "<LOC _Close>", 16, 2, 0, "UI_Menu_Cancel_02", "UI_Opt_Affirm_Over")
    LayoutHelpers.Below(cancelBtn, dialog, -16)
    LayoutHelpers.AtHorizontalCenterIn(cancelBtn, dialog)
    
    local okBtn
    local resetBtn
    
    local numElementsPerPage = 15
    local scrollGroup = Group(dialog)
    LayoutHelpers.AtLeftTopIn(scrollGroup, dialog, -50, -3)
    scrollGroup.Width:Set(function() return dialog.Width() + 70 end)
    
    if isHost == true then
        cancelBtn.label:SetText(LOC("<LOC _Cancel>"))
        
        okBtn = UIUtil.CreateButtonStd(dialog, '/scx_menu/small-btn/small', "<LOC _Ok>", 16, 2, 0, "UI_Opt_Yes_No", "UI_Opt_Affirm_Over")
        LayoutHelpers.Below(okBtn, dialog, -20)
        LayoutHelpers.AtLeftIn(okBtn, dialog, -50)
        LayoutHelpers.RightOf(cancelBtn, okBtn)
        
        resetBtn = UIUtil.CreateButtonStd(dialog, '/scx_menu/small-btn/small', "<LOC _Reset>", 16, 2, 0, "UI_Opt_Yes_No", "UI_Opt_Affirm_Over")
        LayoutHelpers.Below(resetBtn, dialog, -70)
        LayoutHelpers.AtHorizontalCenterIn(resetBtn, dialog)
        Tooltip.AddButtonTooltip(resetBtn, 'options_reset_all')
        
        numElementsPerPage = 13
        scrollGroup.Height:Set(function() return dialog.Height() - 60 end)
    else
        scrollGroup.Height:Set(function() return dialog.Height() - 2 end)
    end


    UIUtil.CreateVertScrollbarFor(scrollGroup)

    scrollGroup.controlList = {}
    scrollGroup.top = 1
    
    scrollGroup.GetScrollValues = function(self, axis)
        return 1, table.getn(self.controlList), self.top, math.min(self.top + numElementsPerPage - 1, table.getn(scrollGroup.controlList))
    end

    scrollGroup.ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta))
    end

    scrollGroup.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta) * numElementsPerPage)
    end

    scrollGroup.ScrollSetTop = function(self, axis, top)
        top = math.floor(top)
        if top == self.top then return end
        self.top = math.max(math.min(table.getn(self.controlList) - numElementsPerPage + 1 , top), 1)
        self:CalcVisible()
    end

    scrollGroup.IsScrollable = function(self, axis)
        return true
    end
    
    scrollGroup.CalcVisible = function(self)
        local top = self.top
        local bottom = self.top + numElementsPerPage
        for index, control in ipairs(self.controlList) do
            if index < top or index >= bottom then
                control:Hide()
                control.Top:Set(function() return self.Top() end)
            else
                control:Show()
                control.Left:Set(self.Left)
                local lIndex = index
                local lControl = control
                control.Top:Set(function() return self.Top() + ((lIndex - top) * lControl.Height()) end)
            end
        end
    end

    local function CreateListElement(parentControl, urKey)
        local textures = {up = UIUtil.UIFile('/scx_menu/restrict_units/bg_up.dds'),
            over = UIUtil.UIFile('/scx_menu/restrict_units/bg_over.dds'),
            sel_up = UIUtil.UIFile('/scx_menu/restrict_units/bg_sel_up.dds'),
            sel_over = UIUtil.UIFile('/scx_menu/restrict_units/bg_sel_over.dds')}
            
        local bg = Bitmap(parentControl, textures.up)
        bg.urKey= urKey
        
        local label = UIUtil.CreateText(bg, LOC(restrictedUnits[urKey].name), 14, UIUtil.bodyFont)
        LayoutHelpers.AtLeftIn(label, bg, 34)
        LayoutHelpers.AtVerticalCenterIn(label, bg)
        label:DisableHitTest()

        if initialRestrictedSet[urKey] then
            bg.active = true
            bg:SetTexture(textures.sel_up)
        else
            bg.active = false
            bg:SetTexture(textures.up)
        end

        bg.Toggle = function(self)
            self.active = not self.active  
            if self.active then
                self:SetTexture(textures.sel_up)
            else
                self:SetTexture(textures.up)
            end        
        end

        bg.Clear = function(self)
            self.active = false
            self:SetTexture(textures.up)
        end
        bg.IsHost = isHost
        bg.HandleEvent = function(self, event)
            if self.IsHost then
                if event.Type == 'MouseEnter' then
                    if self.active then
                        bg:SetTexture(textures.sel_over)
                    else
                        bg:SetTexture(textures.over)
                    end   
                    local sound = Sound({Cue = "UI_Tab_Rollover_01", Bank = "Interface",})
                    PlaySound(sound)
                elseif event.Type == 'MouseExit' then
                    if self.active then
                        bg:SetTexture(textures.sel_up)
                    else
                        bg:SetTexture(textures.up)
                    end    
                elseif event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
                    self:Toggle()
                    local sound = Sound({Cue = "UI_Tab_Click_01", Bank = "Interface",})
                    PlaySound(sound)
                end            
            end
        end

        if restrictedUnits[urKey].tooltip then
            Tooltip.AddControlTooltip(bg, restrictedUnits[urKey].tooltip)
        end

        bg:Hide()
        return bg
    end

    local sortOrder = import("/lua/ui/lobby/restrictedUnitsData.lua").sortOrder
    for index, key in sortOrder do
        if restrictedUnits[key] then
            table.insert(scrollGroup.controlList, CreateListElement(scrollGroup, key))
        end    
    end

    scrollGroup.HandleEvent = function(control, event)
        if event.Type == 'WheelRotation' then
            local lines = 1
            if event.WheelRotation > 0 then
                lines = -1
            end
            control:ScrollLines(nil, lines)
        end
    end
    scrollGroup:CalcVisible()

    local function KillDialog()
        dialog:Destroy()
    end

    cancelBtn.OnClick = function(self, modifiers)
        OnCancel()
        KillDialog()
    end
    
    if isHost == true then
        okBtn.OnClick = function(self, modifiers)
            local newRestrictions = {}
            
            for index, control in scrollGroup.controlList do
                if control.active == true then
                    table.insert(newRestrictions, control.urKey)
                end
            end
            
            OnOk(newRestrictions)
            KillDialog()
        end
        
        resetBtn.OnClick = function(self, modifiers)
            for index, control in scrollGroup.controlList do
                control:Clear()
            end    
        end
    end

    UIUtil.MakeInputModal(dialog, function() okBtn.OnClick(okBtn) end, function() cancelBtn.OnClick(cancelBtn) end)
    UIUtil.CreateWorldCover(dialog)    
end

function CreateBorder(parent)
    local tbl = {}
    tbl.tl = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_ul.dds'))
    tbl.tm = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_horz_um.dds'))
    tbl.tr = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_ur.dds'))
    tbl.l = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_vert_l.dds'))
    tbl.r = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_vert_r.dds'))
    tbl.bl = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_ll.dds'))
    tbl.bm = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_lm.dds'))
    tbl.br = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_lr.dds'))
    
    tbl.tl.Bottom:Set(parent.Top)
    tbl.tl.Right:Set(parent.Left)
    
    tbl.tr.Bottom:Set(parent.Top)
    tbl.tr.Left:Set(parent.Right)
    
    tbl.tm.Bottom:Set(parent.Top)
    tbl.tm.Right:Set(parent.Right)
    tbl.tm.Left:Set(parent.Left)
    
    tbl.l.Bottom:Set(parent.Bottom)
    tbl.l.Top:Set(parent.Top)
    tbl.l.Right:Set(parent.Left)
    
    tbl.r.Bottom:Set(parent.Bottom)
    tbl.r.Top:Set(parent.Top)
    tbl.r.Left:Set(parent.Right)
    
    tbl.bl.Top:Set(parent.Bottom)
    tbl.bl.Right:Set(parent.Left)
    
    tbl.br.Top:Set(parent.Bottom)
    tbl.br.Left:Set(parent.Right)
    
    tbl.bm.Top:Set(parent.Bottom)
    tbl.bm.Right:Set(parent.Right)
    tbl.bm.Left:Set(parent.Left)
    
    tbl.tl.Depth:Set(function() return parent.Depth() - 1 end)
    tbl.tm.Depth:Set(function() return parent.Depth() - 1 end)
    tbl.tr.Depth:Set(function() return parent.Depth() - 1 end)
    tbl.l.Depth:Set(function() return parent.Depth() - 1 end)
    tbl.r.Depth:Set(function() return parent.Depth() - 1 end)
    tbl.bl.Depth:Set(function() return parent.Depth() - 1 end)
    tbl.bm.Depth:Set(function() return parent.Depth() - 1 end)
    tbl.br.Depth:Set(function() return parent.Depth() - 1 end)
    
    return tbl
end