--*****************************************************************************
--* File: lua/modules/ui/game/multifunction.lua
--* Author: Chris Blackwell
--* Summary: UI for the multifunction display
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local Button = import('/lua/maui/button.lua').Button
local Grid = import('/lua/maui/grid.lua').Grid
local Text = import('/lua/maui/text.lua').Text
local GameCommon = import('/lua/ui/game/gamecommon.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local econ = import("/lua/ui/game/economy.lua")
local cmdMode = import('/lua/ui/game/commandmode.lua')
local UIPing = import('/lua/ui/game/ping.lua')
local Prefs = import('/lua/user/prefs.lua')
local miniMap = import('/lua/ui/game/minimap.lua')
local UIMain = import('/lua/ui/uimain.lua')
local Borders = import('/lua/ui/game/borders.lua')

local filters = import('/lua/ui/game/rangeoverlayparams.lua').RangeOverlayParams
local worldView = import('/lua/ui/game/borders.lua').GetMapGroup()
savedParent = false

controls = import('/lua/ui/controls.lua').Get()
controls.overlayBtns = controls.overlayBtns or {}
controls.pingBtns = controls.pingBtns or {}

savedParent = controls.savedParent

local activeFilters = Prefs.GetFromCurrentProfile('activeFilters') or {}

local filterConditionals = {
    {
        key = 'rollover',
        Label = "<LOC map_options_0005>Rollover",
        Pref = 'range_RenderHighlighted',
        Type = 3,
        Tooltip = "overlay_rollover",
    },
    {
        key = 'selection',
        Label = "<LOC map_options_0006>Selection",
        Pref = 'range_RenderSelected',
        Type = 3,
        Tooltip = "overlay_selection",
    },
    {
        key = 'buildpreview',
        Label = "<LOC map_options_0007>Build Preview",
        Pref = 'range_RenderBuild',
        Type = 3,
        Tooltip = "overlay_build_preview",
    },
}

local buttons = {
    overlays = {
        {
            tooltip = 'mfd_strat_view',
            bitmap = 'control',
            id = 'mapoptions',
            OnCheck = function(self, checked)
                if checked and not self.Dropout then
                    self.Dropout = CreateMapDropout(self)
                else
                    self.Dropout:Close()
                    self.Dropout = false
                end
            end,
        },
        {
            tooltip = 'mfd_defense',
            bitmap = 'team-color',
            id = 'teamcolor',
            OnCheck = function(self, checked)
                TeamColorMode(checked)
            end,
        },
        {
            tooltip = 'mfd_economy',
            bitmap = 'economy',
            id = 'economy',
            OnCheck = function(self, checked)
                RenderOverlayEconomy(checked)
            end,
        },
        {
            tooltip = 'mfd_military',
            bitmap = 'military-radar',
            id = 'military',
            dropout = true,
            dropout_tooltip = 'mfd_military_dropout',
            OnCheck = function(self, checked)
                if checked then
                    SetActiveOverlays()
                else
                    SetOverlayFilters({})
                end
            end,
        },
    },
    pings = {
        {
            tooltip = 'mfd_alert_ping',
            cursor = 'RULEUCC_Guard',
            pingType = 'alert',
            bitmap = 'ping-alert',
        },
        {
            tooltip = 'mfd_move_ping',
            cursor = 'RULEUCC_Move',
            pingType = 'move',
            bitmap = 'ping-move',
        },
        {
            tooltip = 'mfd_attack_ping',
            cursor = 'RULEUCC_Attack',
            pingType = 'attack',
            bitmap = 'ping-attack',
        },
        {
            tooltip = 'mfd_marker_ping',
            cursor = 'MESSAGE',
            pingType = 'marker',
            bitmap = 'ping-marker',
        },
    },
}

function SetActiveOverlays()
    local tempFilters = {}
    local combos = {}
    local comboData = {}
    for overlay,_ in activeFilters do
        for filterName,filterData in filters do
            if overlay == filterData.key and filterData.Combo then
                table.insert(tempFilters, filterName)
                combos[filterData.Type] = 'empty'
                comboData[filterData.Type] = filterData
                comboData[filterData.Type].filterName = filterName
                break
            end
        end
    end
    for overlay,_ in activeFilters do
        for filterName,filterData in filters do
            if overlay == filterData.key then
                if combos[filterData.Type] then
                    if combos[filterData.Type] == 'empty' then
                        combos[filterData.Type] = filterData.Categories
                    else
                        combos[filterData.Type] = filterData.Categories + combos[filterData.Type]
                    end
                else
                    table.insert(tempFilters, filterName)
                end
                break
            end
        end
    end
    local buttonState = true
    for i, categories in combos do
        local info = comboData[i]
        SetOverlayFilter(info.filterName,categories,info.NormalColor,info.SelectColor,info.RolloverColor,info.Inner[1],info.Inner[2],info.Outer[1],info.Outer[2])
    end
    if table.getsize(tempFilters) == 0 then
        buttonState = false
        GetButton('military'):Disable()
    else
        GetButton('military'):Enable()
    end
    Prefs.SetToCurrentProfile('activeFilters', activeFilters)
    GetButton('military'):SetCheck(buttonState, true)
    SetOverlayFilters(tempFilters)
end

function PreNIS()
    SetOverlayFilters({})
end

function PostNIS()
    SetActiveOverlays()
end

function Create(parent)
    savedParent = parent

    controls.bg = Group(savedParent)

    controls.bg.panel = Bitmap(savedParent)
    controls.bg.leftBrace = Bitmap(savedParent)
    controls.bg.leftGlow = Bitmap(savedParent)
    controls.bg.rightGlowTop = Bitmap(savedParent)
    controls.bg.rightGlowMiddle = Bitmap(savedParent)
    controls.bg.rightGlowBottom = Bitmap(savedParent)

    controls.collapseArrow = Checkbox(savedParent)
    Tooltip.AddCheckboxTooltip(controls.collapseArrow, 'mfd_collapse')

    local function CreateOverlayBtn(buttonData)
        local btn = false
        if buttonData.button then
            btn = Button(controls.bg,
                UIUtil.SkinnableFile('/game/mfd_btn/'..buttonData.bitmap..'_btn_up.dds'),
                UIUtil.SkinnableFile('/game/mfd_btn/'..buttonData.bitmap..'_btn_down.dds'),
                UIUtil.SkinnableFile('/game/mfd_btn/'..buttonData.bitmap..'_btn_over.dds'),
                UIUtil.SkinnableFile('/game/mfd_btn/'..buttonData.bitmap..'_btn_dis.dds'),
                'UI_Tab_Click_01', 'UI_Tab_Rollover_01')
            Tooltip.AddButtonTooltip(btn, buttonData.tooltip)
        else
            btn = Checkbox(controls.bg,
                UIUtil.SkinnableFile('/game/mfd_btn/'..buttonData.bitmap..'_btn_up.dds'),
                UIUtil.SkinnableFile('/game/mfd_btn/'..buttonData.bitmap..'_btn_over.dds'),
                UIUtil.SkinnableFile('/game/mfd_btn/'..buttonData.bitmap..'_btn_down.dds'),
                UIUtil.SkinnableFile('/game/mfd_btn/'..buttonData.bitmap..'_btn_down.dds'),
                UIUtil.SkinnableFile('/game/mfd_btn/'..buttonData.bitmap..'_btn_dis.dds'),
                UIUtil.SkinnableFile('/game/mfd_btn/'..buttonData.bitmap..'_btn_dis.dds'),
                'UI_Tab_Click_01', 'UI_Tab_Rollover_01')
            Tooltip.AddCheckboxTooltip(btn, buttonData.tooltip)
        end
        btn.ID = buttonData.id
        btn:UseAlphaHitTest(true)

        if buttonData.dropout then
            btn.dropout = Checkbox(btn,
                UIUtil.SkinnableFile('/game/filter-arrow_btn/tab-open_btn_up.dds'),
                UIUtil.SkinnableFile('/game/filter-arrow_btn/tab-close_btn_up.dds'),
                UIUtil.SkinnableFile('/game/filter-arrow_btn/tab-open_btn_over.dds'),
                UIUtil.SkinnableFile('/game/filter-arrow_btn/tab-close_btn_over.dds'),
                UIUtil.SkinnableFile('/game/filter-arrow_btn/tab-open_btn_dis.dds'),
                UIUtil.SkinnableFile('/game/filter-arrow_btn/tab-close_btn_dis.dds'),
                'UI_Tab_Click_01', 'UI_Tab_Rollover_01')
            Tooltip.AddCheckboxTooltip(btn.dropout, buttonData.dropout_tooltip)
        end

        return btn
    end

    local function CreatePingBtn(buttonData)
        local btn = Button(controls.bg,
            UIUtil.SkinnableFile('/game/mfd_btn/'..buttonData.bitmap..'_btn_up.dds'),
            UIUtil.SkinnableFile('/game/mfd_btn/'..buttonData.bitmap..'_btn_down.dds'),
            UIUtil.SkinnableFile('/game/mfd_btn/'..buttonData.bitmap..'_btn_over.dds'),
            UIUtil.SkinnableFile('/game/mfd_btn/'..buttonData.bitmap..'_btn_dis.dds'),
            'UI_Tab_Click_01', 'UI_Tab_Rollover_01')
        Tooltip.AddButtonTooltip(btn, buttonData.tooltip)
        btn:UseAlphaHitTest(true)
        btn.ID = buttonData.pingType
        btn.cursor = buttonData.cursor
        if SessionIsReplay() or GetFocusArmy() == -1 then
            btn:Disable()
        end
        return btn
    end

    for index, buttonData in buttons.overlays do
        controls.overlayBtns[index] = CreateOverlayBtn(buttonData)
    end

    for index, buttonData in buttons.pings do
        controls.pingBtns[index] = CreatePingBtn(buttonData)
    end

    for overlay, info in filters do
        SetOverlayFilter(overlay,info.Categories,info.NormalColor,info.SelectColor,info.RolloverColor,info.Inner[1],info.Inner[2],info.Outer[1],info.Outer[2])
    end

    for _, info in filterConditionals do
        if info.Pref then
            local pref = Prefs.GetFromCurrentProfile(info.Pref)
            if pref == nil then
                pref = true
            end
            ConExecute(info.Pref..' '..tostring(pref))
            if pref then
                activeFilters[info.key] = true
            end
        end
    end

    SetLayout()

    SetActiveOverlays()

    function EndBehavior(mode, data)
        if mode == 'ping' and data.pingLocation and not data.isCancel then
            UIPing.DoPing(data.pingtype)
        end
    end
    cmdMode.AddEndBehavior(EndBehavior)
end

function SetLayout(layout)
    import(UIUtil.GetLayoutFilename('multifunction')).SetLayout()
    CommonLogic()
end

function CommonLogic()
    for i, control in controls.overlayBtns do
        local index = i
        if buttons.overlays[index].OnClick then
            control.OnClick = buttons.overlays[index].OnClick
        elseif buttons.overlays[index].OnCheck then
            control.OnCheck = buttons.overlays[index].OnCheck
        end
        if control.dropout then
            control.dropout.OnCheck = OnDropoutChecked
        end
    end
    for i, control in controls.pingBtns do
        local index = i
        control.OnClick = PingClickHandler
    end
    controls.collapseArrow.OnCheck = function(self, checked)
        ToggleMFDPanel()
    end
end

function PingClickHandler(button, modifiers)
    local modeData = {
        cursor=button.cursor,
        pingtype=button.ID,
        pingLocation=true,
    }
    cmdMode.StartCommandMode("ping", modeData)
end

function GetButton(buttonID)
    for _, control in controls.overlayBtns do
        if control.ID == buttonID then
            return control
        end
    end
    for _, control in controls.pingBtns do
        if control.ID == buttonID then
            return control
        end
    end
end

function ToggleMilitary()
    GetButton('military'):ToggleCheck()
end

function ToggleDefense()
    GetButton('teamcolor'):ToggleCheck()
end

function ToggleEconomy()
    GetButton('economy'):ToggleCheck()
end

function ToggleIntel()
end

function OnDropoutChecked(self, checked)
    if self.list then
        self.list:Close()
    else
        CreateFilterDropout(self)
    end
end

function CreateMapDropout(parent)
    import('/lua/ui/game/chat.lua').CloseChatConfig()
    local bg = CreateDropoutBG(false)

    local function CreateMapOptions(inMapControl)
        local function CreateToggleItem(parent, label)
            local bg = Bitmap(parent)
            bg.checked = true

            bg.treehorz = Bitmap(bg)
            bg.treehorz:SetSolidColor(UIUtil.fontColor)
            bg.treehorz.Height:Set(1)
            bg.treehorz.Width:Set(6)
            LayoutHelpers.AtLeftIn(bg.treehorz, bg)
            LayoutHelpers.AtVerticalCenterIn(bg.treehorz, bg)

            bg.check = Bitmap(bg, UIUtil.SkinnableFile('/game/temp_textures/checkmark.dds'))
            LayoutHelpers.AtLeftIn(bg.check, bg, 8)
            LayoutHelpers.AtVerticalCenterIn(bg.check, bg)
            bg.check.OnHide = function(self, hidden)
                if not hidden and not bg.checked then
                    return true
                end
            end

            bg.label = UIUtil.CreateText(bg, LOC(label), 12, UIUtil.bodyFont)
            LayoutHelpers.RightOf(bg.label, bg.check)
            LayoutHelpers.AtVerticalCenterIn(bg.label, bg)

            bg.Width:Set(parent.Width)
            bg.Height:Set(bg.label.Height)

            bg.OnCheck = function() end
            bg.SetCheck = function(self, checked)
                self.checked = checked
                self.check:SetHidden(not checked)
            end

            bg.HandleEvent = function(self, event)
                if event.Type == 'MouseEnter' then
                    self:SetSolidColor('ff444444')
                    PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Opt_Mini_Button_Over'}))
                elseif event.Type == 'MouseExit' then
                    self:SetSolidColor('00000000')
                elseif event.Type == 'ButtonPress' then
                    PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Opt_Mini_Button_Click'}))
                    self.checked = not self.checked
                    if self.checked then
                        self.check:Show()
                    else
                        self.check:Hide()
                    end
                    self:OnCheck(self.checked)
                end
            end

            return bg
        end
        # Make an option group consisting of a checkbox and a name
        local group = Group(bg)
        local mapControl = inMapControl
        local camName = mapControl._cameraName

        group.title = UIUtil.CreateText(group, LOC(mapControl._displayName), 14, UIUtil.bodyFont)
        LayoutHelpers.AtLeftTopIn(group.title, group)

        group.toggles = {}
        if camName == 'MiniMap' then
            group.toggles[1] = CreateToggleItem(group, '<LOC map_options_0000>Enabled')
            group.toggles[1]:SetCheck(miniMap.GetMinimapState())
            group.toggles[1].OnCheck = function(self, checked)
                miniMap.ToggleMinimap()
            end
        else
            group.toggles[1] = CreateToggleItem(group, '<LOC map_options_0001>Cartographic')
            group.toggles[1]:SetCheck(mapControl:IsCartographic())
            group.toggles[1].OnCheck = function(self, checked)
                mapControl:SetCartographic(checked)
                Prefs.SetToCurrentProfile(camName.."_cartographic_mode", checked)
            end
        end
        group.toggles[2] = CreateToggleItem(group, '<LOC map_options_0002>Resources')
        group.toggles[2]:SetCheck(mapControl:IsResourceRenderingEnabled())
        group.toggles[2].OnCheck = function(self, checked)
            mapControl:EnableResourceRendering(checked)
            Prefs.SetToCurrentProfile(camName.."_resource_icons", checked)
        end
        if camName == 'WorldCamera' or camName == 'WorldCamera2' then
            local splitOnCheck = not Borders.mapSplitState
            local wording = '<LOC map_options_0003>Join'
            if splitOnCheck then
                wording = '<LOC map_options_0004>Split'
            end
            group.toggles[3] = CreateToggleItem(group, wording)
            group.toggles[3]:SetCheck(false)
            group.toggles[3].OnCheck = function(self, checked)
                Borders.SplitMapGroup(splitOnCheck)
            end
            LayoutHelpers.Below(group.toggles[3], group.toggles[2])
        end

        LayoutHelpers.AtLeftTopIn(group.toggles[1], group, 0, 20)
        LayoutHelpers.Below(group.toggles[2], group.toggles[1])

        group.treeVert = Bitmap(group)
        group.treeVert:SetSolidColor(UIUtil.fontColor)
        group.treeVert.Width:Set(1)
        LayoutHelpers.AtLeftIn(group.treeVert, bg)
        group.treeVert.Top:Set(group.title.Bottom)
        group.treeVert.Bottom:Set(function() return group.toggles[table.getsize(group.toggles)].Top() + (group.toggles[1].Height()/2) end)

        group.Width:Set(170)
        group.Height:Set(function() return group.title.Height() + (table.getsize(group.toggles) * group.toggles[1].Height()) end)
        return group
    end

    local viewControls = import('/lua/ui/game/worldview.lua').GetWorldViews()
    local Views = {}
    for _, control in viewControls do
        table.insert(Views, control)
    end
    table.sort(Views, function(a,b)
        return a._order <= b._order
    end)
    local prevControl = false
    bg.mapControls = {}
    local maxWidth = 0
    local totHeight = 0
    for i, control in Views do
        local index = i
        bg.mapControls[index] = CreateMapOptions(control)
        if prevControl then
            LayoutHelpers.Below(bg.mapControls[index], prevControl, 5)
        else
            LayoutHelpers.AtLeftTopIn(bg.mapControls[index], bg, 0, 0)
        end
        prevControl = bg.mapControls[index]
        maxWidth = math.max(prevControl.Width()+5, maxWidth)
        totHeight = totHeight + prevControl.Height() + 5
    end

    local function SetItemAlpha(alpha)
        for _, item in bg.mapControls do
            item:SetAlpha(alpha, true)
        end
    end

    bg.Height:Set(totHeight + 0)
    bg.Width:Set(maxWidth + 30)
    LayoutHelpers.AtCenterIn(bg, GetFrame(0))
    bg.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)

    bg.Close = function(self)
        parent:SetCheck(false, true)
        parent.Dropout = nil
        self:Destroy()
    end

    local okButton = UIUtil.CreateButtonStd(bg, '/game/menu-btns/close', "", 12)
    LayoutHelpers.AtRightTopIn(okButton, bg, -10, -10)
    okButton.OnClick = function(self, modifiers)
        bg:Close()
    end
    return bg
end

function CloseMapDialog()
    if GetButton('mapoptions').Dropout then
        GetButton('mapoptions').Dropout:Destroy()
        GetButton('mapoptions').Dropout = nil
    end
end

function RefreshMapDialog()
    if GetButton('mapoptions').Dropout then
        GetButton('mapoptions').Dropout:Destroy()
        GetButton('mapoptions').Dropout = CreateMapDropout(GetButton('mapoptions'))
    end
end

function CreateFilterDropout(parent)
    local bg = CreateDropoutBG()

    local weaponFilters = {}
    local intelFilters = {}
    for _, data in filters do
        if data.Type == 1 then
            table.insert(weaponFilters, data)
        end
    end
    for _, data in filters do
        if data.Type == 2 then
            table.insert(intelFilters, data)
        end
    end

    local function SortFunc(a,b)
        if a.Combo or b.Combo then
            if a.Combo then
                return false
            else
                return true
            end
        else
            return a.key < b.key
        end
    end

    table.sort(weaponFilters, SortFunc)
    table.sort(intelFilters, SortFunc)

    bg.items = {}

    local function SetTitleCheck(type)
        local titleControl = false
        local checkState = false
        for _, control in bg.items do
            if control.Data.Type == type then
                if control.title or control.Data.Combo then
                    if control.title then
                        titleControl = control
                    end
                    continue
                end
                if checkState then
                    if checkState == 'all' and control.checked then
                        continue
                    elseif checkState == 'none' and not control.checked then
                        continue
                    else
                        checkState = 'some'
                        break
                    end
                else
                    if control.checked then
                        checkState = 'all'
                    else
                        checkState = 'none'
                    end
                end
            end
        end
        if checkState == 'all' then
            titleControl.checked = true
            titleControl.check:Show()
            titleControl.check:SetTexture(UIUtil.SkinnableFile('/game/temp_textures/checkmark.dds'))
        elseif checkState == 'none' then
            titleControl.checked = false
            titleControl.check:Hide()
            titleControl.check:SetTexture(UIUtil.SkinnableFile('/game/temp_textures/checkmark.dds'))
        else
            titleControl.checked = true
            titleControl.check:Show()
            titleControl.check:SetTexture(UIUtil.SkinnableFile('/game/temp_textures/checkmark_dark.dds'))
        end
    end

    local function TitleEventHandler(self, event)
        if event.Type == 'MouseEnter' then
            PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Opt_Mini_Button_Over'}))
            self:SetSolidColor('ff444444')
        elseif event.Type == 'MouseExit' then
            self:SetSolidColor('00000000')
        elseif event.Type == 'ButtonPress' then
            PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Opt_Mini_Button_Click'}))
            self.checked = not self.checked
            if self.checked then
                self.check:Show()
                self.check:SetTexture(UIUtil.SkinnableFile('/game/temp_textures/checkmark.dds'))
            else
                self.check:Hide()
            end
            for _, control in bg.items do
                if control.Data.Type == self.Data.Type and control != self then
                    if control.Data.Combo then
                        continue
                    end
                    control.checked = self.checked
                    control:OnChecked()
                end
            end
            SetActiveOverlays()
        end
    end

    local function OnComboChecked(self)
        local color = false
        if self.checked then
            self.check:SetTexture(UIUtil.SkinnableFile('/game/temp_textures/combo_sel.dds'))
            color = 'dd'..string.sub(self.Data.NormalColor, 3, 8)
            activeFilters[self.Data.key] = true
        else
            self.check:SetTexture(UIUtil.SkinnableFile('/game/temp_textures/combo_up.dds'))
            activeFilters[self.Data.key] = nil
        end
        for _, control in bg.items do
            if control.Data.Type == self.Data.Type and control.checked then
                if control.title or control.Data.Combo then
                    continue
                end
                if control.checkBGColor then
                    if color then
                        control.checkBGColor:SetSolidColor(color)
                    else
                        control.checkBGColor:SetSolidColor('dd'..string.sub(control.Data.NormalColor, 3, 8))
                    end
                end
            end
        end
    end

    local function GetCombo(type)
        for _, control in bg.items do
            if control.Data.Combo and control.Data.Type == type then
                return control
            end
        end
    end

    local function OnChecked(self)
        if self.checked then
            self.check:Show()
            local color = '00000000'
            if self.Data.NormalColor then
                local combo = GetCombo(self.Data.Type)
                if combo.checked then
                    color = 'dd'..string.sub(combo.Data.NormalColor, 3, 8)
                else
                    color = 'dd'..string.sub(self.Data.NormalColor, 3, 8)
                end
            end
            if self.checkBGColor then
                self.checkBGColor:SetSolidColor(color)
            end
            activeFilters[self.Data.key] = true
        else
            self.check:Hide()
            if self.checkBGColor then
                self.checkBGColor:SetSolidColor('00000000')
            end
            activeFilters[self.Data.key] = nil
        end
        if self.Data.Pref then
            ConExecute(self.Data.Pref..' '..tostring(self.checked))
            Prefs.SetToCurrentProfile(self.Data.Pref, self.checked)
        end
    end

    local function EventHandler(self, event)
        if event.Type == 'MouseEnter' then
            PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Opt_Mini_Button_Over'}))
            self:SetSolidColor('ff444444')
        elseif event.Type == 'MouseExit' then
            self:SetSolidColor('00000000')
        elseif event.Type == 'ButtonPress' then
            PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Opt_Mini_Button_Click'}))
            self.checked = not self.checked
            self:OnChecked()
            if not self.Data.Combo then
                SetTitleCheck(self.Data.Type)
            end
            SetActiveOverlays()
        end
    end

    local function CreateEntry(parent, data, title)
        local bg = Bitmap(parent)
        bg.Data = data
        bg.checked = false
        bg.title = title
        local fontSize = 12
        if title then
            fontSize = 16
            bg.HandleEvent = TitleEventHandler
        else
            bg.HandleEvent = EventHandler
            if data.Combo then
                bg.OnChecked = OnComboChecked
            else
                bg.OnChecked = OnChecked
            end
        end

        bg.check = Bitmap(bg)


        if data.Combo then
            bg.check:SetTexture(UIUtil.SkinnableFile('/game/temp_textures/combo_up.dds'))
        else
            bg.check:SetTexture(UIUtil.SkinnableFile('/game/temp_textures/checkmark.dds'))
            bg.check:Hide()
            bg.checkBorder = {}
            bg.checkBorder.t = Bitmap(bg)
            bg.checkBorder.t:SetSolidColor(UIUtil.fontColor)
            bg.checkBorder.t.Bottom:Set(bg.check.Top)
            bg.checkBorder.t.Left:Set(bg.check.Left)
            bg.checkBorder.t.Right:Set(bg.check.Right)
            bg.checkBorder.t.Height:Set(1)

            bg.checkBorder.b = Bitmap(bg)
            bg.checkBorder.b:SetSolidColor(UIUtil.fontColor)
            bg.checkBorder.b.Top:Set(bg.check.Bottom)
            bg.checkBorder.b.Left:Set(bg.check.Left)
            bg.checkBorder.b.Right:Set(bg.check.Right)
            bg.checkBorder.b.Height:Set(1)

            bg.checkBorder.l = Bitmap(bg)
            bg.checkBorder.l:SetSolidColor(UIUtil.fontColor)
            bg.checkBorder.l.Right:Set(bg.check.Left)
            bg.checkBorder.l.Top:Set(bg.checkBorder.t.Top)
            bg.checkBorder.l.Bottom:Set(bg.checkBorder.b.Bottom)
            bg.checkBorder.l.Width:Set(1)

            bg.checkBorder.r = Bitmap(bg)
            bg.checkBorder.r:SetSolidColor(UIUtil.fontColor)
            bg.checkBorder.r.Left:Set(bg.check.Right)
            bg.checkBorder.r.Top:Set(bg.checkBorder.t.Top)
            bg.checkBorder.r.Bottom:Set(bg.checkBorder.b.Bottom)
            bg.checkBorder.r.Width:Set(1)

            bg.checkBGColor = Bitmap(bg)
            LayoutHelpers.FillParent(bg.checkBGColor, bg.check)

            bg.checkBorder.t.Depth:Set(function() return bg.check.Depth() - 1 end)
            bg.checkBorder.b.Depth:Set(function() return bg.check.Depth() - 1 end)
            bg.checkBorder.l.Depth:Set(function() return bg.check.Depth() - 1 end)
            bg.checkBorder.r.Depth:Set(function() return bg.check.Depth() - 1 end)
            bg.checkBGColor.Depth:Set(function() return bg.check.Depth() - 1 end)
        end

        if activeFilters[data.key] then
            bg.checked = true
            if bg.OnChecked then
                bg:OnChecked()
            else
                bg.check:Show()
            end
        end

        bg.text = UIUtil.CreateText(bg, data.Label, fontSize, UIUtil.bodyFont)
        if title or data.Combo then
            LayoutHelpers.AtLeftIn(bg.text, bg, 20)
            LayoutHelpers.AtVerticalCenterIn(bg.text, bg)
            LayoutHelpers.AtLeftIn(bg.check, bg, 2)
            LayoutHelpers.AtVerticalCenterIn(bg.check, bg)
        else
            bg.treeVert = Bitmap(bg)
            bg.treeVert:SetSolidColor(UIUtil.fontColor)
            bg.treeVert.Width:Set(1)
            bg.treeVert.Height:Set(bg.Height)
            LayoutHelpers.AtLeftTopIn(bg.treeVert, bg, 5)

            bg.treeHorz = Bitmap(bg)
            bg.treeHorz:SetSolidColor(UIUtil.fontColor)
            bg.treeHorz.Width:Set(6)
            bg.treeHorz.Height:Set(1)

            LayoutHelpers.AtLeftIn(bg.treeHorz, bg, 5)
            LayoutHelpers.AtVerticalCenterIn(bg.treeHorz, bg)
            LayoutHelpers.RightOf(bg.text, bg.check, 5)
            LayoutHelpers.AtVerticalCenterIn(bg.text, bg)
            LayoutHelpers.RightOf(bg.check, bg.treeHorz)
            LayoutHelpers.AtVerticalCenterIn(bg.check, bg)
        end

        bg.Height:Set(function() return bg.text.Height() + 4 end)

        return bg
    end

    local function ProcessItems(table, index, maxWidth, title, type, tooltip)
        if title and type then
            bg.items[index] = CreateEntry(bg, {Label = title, Type = type}, true)
            Tooltip.AddControlTooltip(bg.items[index].check, tooltip)
            Tooltip.AddControlTooltip(bg.items[index].text, tooltip)
            Tooltip.AddControlTooltip(bg.items[index], tooltip)
            if index == 1 then
                LayoutHelpers.AtLeftTopIn(bg.items[index], bg)
            else
                LayoutHelpers.Below(bg.items[index], bg.items[index-1], 5)
            end
            index = index + 1
        end
        local firstVert = true
        for i, data in table do
            bg.items[index] = CreateEntry(bg, data, data.Title)
            Tooltip.AddControlTooltip(bg.items[index].check, data.Tooltip)
            Tooltip.AddControlTooltip(bg.items[index].text, data.Tooltip)
            Tooltip.AddControlTooltip(bg.items[index], data.Tooltip)
            LayoutHelpers.Below(bg.items[index], bg.items[index-1])
            if bg.items[index].treeVert and firstVert then
                local I = index
                LayoutHelpers.AtLeftTopIn(bg.items[index].treeVert, bg.items[index], 5, -3)
                bg.items[index].treeVert.Height:Set(function() return bg.items[I].Height() + 3 end)
                firstVert = false
            end
            maxWidth = math.max(maxWidth, bg.items[index].text.Width() + bg.items[index].check.Width() + 20)
            index = index + 1
        end
        if bg.items[index-1].Data.Combo then
            bg.items[index-2].treeVert.Height:Set(function() return bg.items[index-2].Height() + 1 end)
        else
            bg.items[index-1].treeVert.Height:Set(function() return bg.items[index-1].Height() / 2 end)
        end
        return index, maxWidth
    end

    local maxWidth = 0
    local index = 1

    index, maxWidth = ProcessItems(filterConditionals, index, maxWidth, '<LOC filters_0002>Conditions', 3, "overlay_conditions")
    index, maxWidth = ProcessItems(weaponFilters, index, maxWidth, '<LOC filters_0000>Military', 1, "overlay_military")
    index, maxWidth = ProcessItems(intelFilters, index, maxWidth, '<LOC filters_0001>Intel', 2, "overlay_intel")

    SetTitleCheck(1)
    SetTitleCheck(2)
    SetTitleCheck(3)

    local totalHeight = 0
    for _, filter in bg.items do
        totalHeight = filter.Height() + totalHeight
        filter.Width:Set(maxWidth)
    end

    local function SetItemAlpha(alpha)
        for _, item in bg.items do
            item:SetAlpha(alpha, true)
        end
    end

    bg.Height:Set(30)
    bg.Width:Set(5)
    bg.Left:Set(function() return controls.bg.Right() + 36 end)
    bg.Top:Set(function() return controls.bg.Top() + 23 end)
    bg.TargetWidth = maxWidth
    bg.TargetHeight = totalHeight + 10
    bg:SetNeedsFrameUpdate(true)
    local curAlpha = 0
    SetItemAlpha(curAlpha)
    bg.OnFrame = function(self, delta)
        local moving = false
        if self.Width() < self.TargetWidth then
            local newWidth = math.min(self.Width() + (delta*500), self.TargetWidth)
            self.Width:Set(newWidth)
            moving = true
        end
        if self.Height() < self.TargetHeight then
            local newHeight = math.min(self.Height() + (delta*800), self.TargetHeight)
            self.Height:Set(newHeight)
            moving = true
        end
        if not moving then
            curAlpha = curAlpha + (delta*4)
            if curAlpha > 1 then
                curAlpha = 1
                self:SetNeedsFrameUpdate(false)
            end
            SetItemAlpha(curAlpha)
        end
    end
    bg.Active = true
    bg.Close = function(self)
        PlaySound(Sound({Bank = 'Interface', Cue = 'UI_MFD_checklist'}))
        self:SetNeedsFrameUpdate(true)
        self.OnFrame = function(self, delta)
            if curAlpha > 0 then
                curAlpha = curAlpha - (delta*4)
                if curAlpha < 0 then
                    curAlpha = 0
                end
                SetItemAlpha(curAlpha)
            else
                local moveComplete = true
                if self.Width() > 5 then
                    local newWidth = math.max(self.Width() - (delta*500), 5)
                    self.Width:Set(newWidth)
                    moveComplete = false
                end
                if self.Height() > 30 then
                    local newHeight = math.max(self.Height() - (delta*800), 30)
                    self.Height:Set(newHeight)
                    moveComplete = false
                end
                if moveComplete then
                    self:Destroy()
                    self:SetNeedsFrameUpdate(false)
                    parent:SetCheck(false, true)
                    parent.list = nil
                end
            end
        end
    end

    PlaySound(Sound({Bank = 'Interface', Cue = 'UI_MFD_checklist'}))

    bg.MouseClickFunc = function(event)
        if bg.Active then
            if (event.x < bg.Left() or event.x > bg.Right()) or (event.y < bg.Top() or event.y > bg.Bottom()) then
                bg:Close()
                bg.Active = false
            end
        else
            UIMain.RemoveOnMouseClickedFunc(bg.MouseClickFunc)
        end
    end

    UIMain.AddOnMouseClickedFunc(bg.MouseClickFunc)

    bg.MouseClickFunc.OnDestroy = function(self)
        UIMain.RemoveOnMouseClickedFunc(bg.MouseClickFunc)
    end

    parent.list = bg
end

function CreateDropoutBG(createConnector)
    local bg = Bitmap(controls.bg, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_m.dds'))

    if createConnector != false then
        bg.connector = Bitmap(bg, UIUtil.SkinnableFile('/game/filter-ping-list-panel/energy-bar_bmp.dds'))
        LayoutHelpers.AtVerticalCenterIn(bg.connector, controls.bg)
        bg.connector.Left:Set(function() return controls.bg.Right() - 2 end)
        bg.connector.Depth:Set(function() return bg.Depth() - 5 end)
    end

    bg.bgTL = Bitmap(bg, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_ul.dds'))
    bg.bgTL.Bottom:Set(bg.Top)
    bg.bgTL.Right:Set(bg.Left)

    bg.bgTR = Bitmap(bg, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_ur.dds'))
    bg.bgTR.Bottom:Set(bg.Top)
    bg.bgTR.Left:Set(bg.Right)

    bg.bgTM = Bitmap(bg, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_horz_um.dds'))
    bg.bgTM.Bottom:Set(bg.Top)
    bg.bgTM.Left:Set(bg.bgTL.Right)
    bg.bgTM.Right:Set(bg.bgTR.Left)

    bg.bgBL = Bitmap(bg, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_ll.dds'))
    bg.bgBL.Top:Set(bg.Bottom)
    bg.bgBL.Right:Set(bg.Left)

    bg.bgBR = Bitmap(bg, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_lr.dds'))
    bg.bgBR.Top:Set(bg.Bottom)
    bg.bgBR.Left:Set(bg.Right)

    bg.bgBM = Bitmap(bg, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_lm.dds'))
    bg.bgBM.Top:Set(bg.Bottom)
    bg.bgBM.Left:Set(bg.bgTL.Right)
    bg.bgBM.Right:Set(bg.bgTR.Left)

    bg.bgL = Bitmap(bg, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_vert_l.dds'))
    bg.bgL.Top:Set(bg.Top)
    bg.bgL.Bottom:Set(bg.Bottom)
    bg.bgL.Right:Set(bg.Left)

    bg.bgR = Bitmap(bg, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_vert_r.dds'))
    bg.bgR.Top:Set(bg.Top)
    bg.bgR.Bottom:Set(bg.Bottom)
    bg.bgR.Left:Set(bg.Right)

    bg:DisableHitTest(true)

    return bg
end

function ToggleMFDPanel(state)
    if import('/lua/ui/game/gamemain.lua').gameUIHidden then
        return
    end
    if UIUtil.GetAnimationPrefs() then
        if state or controls.bg:IsHidden() then
            PlaySound(Sound({Cue = "UI_Score_Window_Open", Bank = "Interface"}))
            controls.bg:Show()
            controls.bg:SetNeedsFrameUpdate(true)
            controls.bg.OnFrame = function(self, delta)
                local newLeft = self.Left() + (1000*delta)
                if newLeft > savedParent.Left()+15 then
                    newLeft = savedParent.Left()+15
                    self:SetNeedsFrameUpdate(false)
                end
                self.Left:Set(newLeft)
            end
            controls.collapseArrow:SetCheck(false, true)
        else
            PlaySound(Sound({Cue = "UI_Score_Window_Close", Bank = "Interface"}))
            controls.bg:SetNeedsFrameUpdate(true)
            controls.bg.OnFrame = function(self, delta)
                local newLeft = self.Left() - (1000*delta)
                if newLeft < savedParent.Left()-self.Width() - 10 then
                    newLeft = savedParent.Left()-self.Width() - 10
                    self:SetNeedsFrameUpdate(false)
                    self:Hide()
                end
                self.Left:Set(newLeft)
            end
            controls.collapseArrow:SetCheck(true, true)
        end
    else
        if state or GUI.bg:IsHidden() then
            controls.bg:Show()
            controls.collapseArrow:SetCheck(false, true)
        else
            controls.bg:Hide()
            controls.collapseArrow:SetCheck(true, true)
        end
    end
end

function Contract()
end

function Expand()
end

function InitialAnimation()
    controls.bg:Show()
    controls.bg.Left:Set(savedParent.Left()-controls.bg.Width())
    controls.bg:SetNeedsFrameUpdate(true)
    controls.bg.OnFrame = function(self, delta)
        local newLeft = self.Left() + (1000*delta)
        if newLeft > savedParent.Left()+15 then
            newLeft = savedParent.Left()+15
            self:SetNeedsFrameUpdate(false)
        end
        self.Left:Set(newLeft)
    end
    controls.collapseArrow:Show()
    controls.collapseArrow:SetCheck(false, true)
end

function UpdateMinimapState(minimap)
    RefreshMapDialog()
end

function FocusArmyChanged()
    for i, control in controls.pingBtns do
        if GetFocusArmy() == -1 then
            control:Disable()
        else
            control:Enable()
        end
    end
end

function UpdateActiveFilters()
    activeFilters = Prefs.GetFromCurrentProfile('activeFilters') or {}
    SetActiveOverlays()
end
