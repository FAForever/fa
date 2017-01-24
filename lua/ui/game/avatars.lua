--*****************************************************************************
--* File: lua/modules/ui/game/avatars.lua
--* Author: Ted Snook
--* Summary: In Game Avatar Icons
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Button = import('/lua/maui/button.lua').Button
local Group = import('/lua/maui/group.lua').Group
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local StatusBar = import('/lua/maui/statusbar.lua').StatusBar
local GameCommon = import('/lua/ui/game/gamecommon.lua')
local GameMain = import('/lua/ui/game/gamemain.lua')
local ToolTip = import('/lua/ui/game/tooltip.lua')
local TooltipInfo = import('/lua/ui/help/tooltips.lua').Tooltips
local Prefs = import('/lua/user/prefs.lua')
local Factions = import('/lua/factions.lua').Factions
local options = Prefs.GetFromCurrentProfile('options')
local DiskGetFileInfo = UIUtil.DiskGetFileInfo

controls = import('/lua/ui/controls.lua').Get()
controls.avatars = controls.avatars or {}

local recievingBeatUpdate = false
local currentFaction = GetArmiesTable().armiesTable[GetFocusArmy()].faction
local expandedCheck = false
local currentIndex = 1

function GetEngineerGeneric()
    local idleEngineers = GetIdleEngineers()
    if idleEngineers then
        local selEngineer = idleEngineers[currentIndex] or idleEngineers[1]
        currentIndex = currentIndex + 1
        if currentIndex > table.getn(idleEngineers) then
            currentIndex = 1
        end
        UISelectAndZoomTo(selEngineer)
    end
end

function CreateAvatarUI(parent)
    controls.parent = parent

    controls.avatarGroup = Group(controls.parent)
    controls.avatarGroup.Depth:Set(100)

    controls.bgTop = Bitmap(controls.avatarGroup)
    controls.bgBottom = Bitmap(controls.avatarGroup)
    controls.bgStretch = Bitmap(controls.avatarGroup)
    controls.collapseArrow = Checkbox(controls.parent)
    controls.collapseArrow.OnCheck = function(self, checked)
        ToggleAvatars(checked)
    end
    ToolTip.AddCheckboxTooltip(controls.collapseArrow, 'avatars_collapse')

    controls.avatarGroup:DisableHitTest()
    controls.bgTop:DisableHitTest()
    controls.bgBottom:DisableHitTest()
    controls.bgStretch:DisableHitTest()

    SetLayout()

    if GetFocusArmy() ~= -1 then
        recievingBeatUpdate = true
        GameMain.AddBeatFunction(AvatarUpdate, true)
    end
end

function ToggleAvatars(checked)
    -- disable when in Screen Capture mode
    if import('/lua/ui/game/gamemain.lua').gameUIHidden then
        return
    end

    if UIUtil.GetAnimationPrefs() then
        if controls.avatarGroup:IsHidden() then
            PlaySound(Sound({Cue = "UI_Score_Window_Open", Bank = "Interface"}))
            controls.collapseArrow:SetCheck(false, true)
            controls.avatarGroup:Show()
            controls.avatarGroup:SetNeedsFrameUpdate(true)
            controls.avatarGroup.OnFrame = function(self, delta)
                local newRight = self.Right() - (1000*delta)
                if newRight < controls.parent.Right() - 0 then
                    newRight = function() return controls.parent.Right() - 0 end
                    self:SetNeedsFrameUpdate(false)
                end
                self.Right:Set(newRight)
            end
        else
            PlaySound(Sound({Cue = "UI_Score_Window_Close", Bank = "Interface"}))
            controls.avatarGroup:SetNeedsFrameUpdate(true)
            controls.avatarGroup.OnFrame = function(self, delta)
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
        if checked or not controls.avatarGroup:IsHidden() then
            controls.avatarGroup:Hide()
            controls.collapseArrow:SetCheck(true, true)
        else
            controls.avatarGroup:Show()
            controls.collapseArrow:SetCheck(false, true)
        end
    end
end

function SetLayout()
    import(UIUtil.GetLayoutFilename('avatars')).SetLayout()
end

function CreateAvatar(unit)
    local bg = Bitmap(controls.avatarGroup, UIUtil.SkinnableFile('/game/avatar/avatar_bmp.dds'))
    bg.ID = unit:GetEntityId()
    bg.Blueprint = unit:GetBlueprint()
    bg.tooltipKey = 'avatar_Avatar_ACU'

    bg.units = {unit}

    bg.icon = Bitmap(bg)
    LayoutHelpers.AtLeftTopIn(bg.icon, bg, 5, 5)

    -- Commander icon
    if UIUtil.UIFile('/icons/units/'..bg.Blueprint.BlueprintId..'_icon.dds', true) then
        bg.icon:SetTexture(UIUtil.UIFile('/icons/units/'..bg.Blueprint.BlueprintId..'_icon.dds', true))
    else
        bg.icon:SetTexture(UIUtil.UIFile('/icons/units/default_icon.dds'))
    end
    bg.icon.Height:Set(44)
    bg.icon.Width:Set(44)
    bg.icon:DisableHitTest()

    bg.healthbar = StatusBar(bg, 0, 1, false, false,
        UIUtil.SkinnableFile('/game/avatar/health-bar-back_bmp.dds'),
        UIUtil.SkinnableFile('/game/avatar/health-bar-green.dds'),
        true, "avatar RO Health Status Bar")
    bg.healthbar.Left:Set(function() return bg.Left() + 8 end)
    bg.healthbar.Right:Set(function() return bg.Right() - 14 end)
    bg.healthbar.Bottom:Set(function() return bg.Bottom() - 5 end)
    bg.healthbar.Top:Set(function() return bg.healthbar.Bottom() - 10 end)
    bg.healthbar.Height:Set(function() return bg.healthbar.Bottom() - bg.healthbar.Top() end)
    bg.healthbar.Width:Set(function() return bg.healthbar.Right() - bg.healthbar.Left() end)
    bg.healthbar:DisableHitTest(true)


    bg.curIndex = 1
    bg.HandleEvent = ClickFunc
    bg.idleAnnounced = true
    bg.lastAlert = 0

    bg.Update = function(self)
        if bg.units[1]:IsIdle() and not bg.idle then
            if not bg.idle then
                bg.idle = Bitmap(bg.icon, UIUtil.SkinnableFile('/game/idle_mini_icon/idle_icon.dds'))
                LayoutHelpers.AtLeftTopIn(bg.idle, bg.icon, -2, -2)
                bg.idle:DisableHitTest()
                bg.idle.cycles = 0
                bg.idle.dir = 1
                bg.idle:SetNeedsFrameUpdate(true)
                bg.idle:SetAlpha(0)
                bg.idle.OnFrame = function(self, delta)
                    local newAlpha = self:GetAlpha() + (delta * 3 * self.dir)
                    if newAlpha > 1 then
                        newAlpha = 1
                        self.dir = -1
                        self.cycles = self.cycles + 1
                        if self.cycles >= 5 then
                            self:SetNeedsFrameUpdate(false)
                        end
                    elseif newAlpha < 0 then
                        newAlpha = 0
                        self.dir = 1
                    end
                    self:SetAlpha(newAlpha)
                end
            end
        elseif not bg.units[1]:IsIdle() then
            if bg.idle then
                bg.idle:Destroy()
                bg.idle = false
            end
        end
        local tempPrevHealth = bg.healthbar._value()
        local tempHealth = self.units[1]:GetHealth()
        bg.healthbar:SetRange(0, self.units[1]:GetMaxHealth())
        bg.healthbar:SetValue(tempHealth)
        if tempPrevHealth ~= tempHealth then
            SetHealthbarColor(bg.healthbar, self.units[1]:GetHealth() / self.units[1]:GetMaxHealth())
        end
    end

    return bg
end

function SetHealthbarColor(control, value)
    if value > .75 then
        control._bar:SetTexture(UIUtil.SkinnableFile('/game/avatar/health-bar-green.dds'))
    elseif value > .25 then
        control._bar:SetTexture(UIUtil.SkinnableFile('/game/avatar/health-bar-yellow.dds'))
    elseif value > 0 then
        control._bar:SetTexture(UIUtil.SkinnableFile('/game/avatar/health-bar-red.dds'))
    end
end

function CreateIdleTab(unitData, id, expandFunc)
    local bg = Bitmap(controls.avatarGroup, UIUtil.SkinnableFile('/game/avatar/avatar-s-e-f_bmp.dds'))
    bg.id = id
    bg.tooltipKey = 'mfd_idle_'..id

    bg.allunits = unitData
    bg.units = unitData

    bg.icon = Bitmap(bg)
    LayoutHelpers.AtLeftTopIn(bg.icon, bg, 7, 8)
    bg.icon:SetSolidColor('00000000')
    bg.icon.Height:Set(34)
    bg.icon.Width:Set(34)
    bg.icon:DisableHitTest()

    bg.count = UIUtil.CreateText(bg.icon, '', 18, UIUtil.bodyFont)
    bg.count:DisableHitTest()
    bg.count:SetDropShadow(true)
    LayoutHelpers.AtBottomIn(bg.count, bg.icon)
    LayoutHelpers.AtRightIn(bg.count, bg.icon)

    bg.expandCheck = Checkbox(bg,
        UIUtil.SkinnableFile('/game/avatar-arrow_btn/tab-open_btn_up.dds'),
        UIUtil.SkinnableFile('/game/avatar-arrow_btn/tab-close_btn_up.dds'),
        UIUtil.SkinnableFile('/game/avatar-arrow_btn/tab-open_btn_over.dds'),
        UIUtil.SkinnableFile('/game/avatar-arrow_btn/tab-close_btn_over.dds'),
        UIUtil.SkinnableFile('/game/avatar-arrow_btn/tab-open_btn_dis.dds'),
        UIUtil.SkinnableFile('/game/avatar-arrow_btn/tab-close_btn_dis.dds'))
    bg.expandCheck.Right:Set(function() return bg.Left() + 4 end)
    LayoutHelpers.AtVerticalCenterIn(bg.expandCheck, bg)
    bg.expandCheck.OnCheck = function(self, checked)
        if checked then
            if expandedCheck and expandedCheck ~= bg.id and GetCheck(expandedCheck) then
                GetCheck(expandedCheck):SetCheck(false)
            end
            expandedCheck = bg.id
            self.expandList = expandFunc(self, bg.units)
        else
            expandedCheck = false
            if self.expandList then
                self.expandList:Destroy()
                self.expandList = nil
            end
        end
    end
    bg.curIndex = 1
    bg.HandleEvent = ClickFunc
    bg.Update = function(self, units)
        self.allunits = units
        self.units = {}
        if self.id == 'engineer' then
            local sortedUnits = {}
            sortedUnits[5] = EntityCategoryFilterDown(categories.SUBCOMMANDER, self.allunits)
            sortedUnits[4] = EntityCategoryFilterDown(categories.TECH3 - categories.SUBCOMMANDER, self.allunits)
            sortedUnits[3] = EntityCategoryFilterDown(categories.FIELDENGINEER, self.allunits)
            sortedUnits[2] = EntityCategoryFilterDown(categories.TECH2 - categories.FIELDENGINEER, self.allunits)
            sortedUnits[1] = EntityCategoryFilterDown(categories.TECH1, self.allunits)

            local keyToIcon = {'T1','T2','T2F','T3','SCU'}

            local i = table.getn(sortedUnits)
            local needIcon = true
            while i > 0 do
                if table.getn(sortedUnits[i]) > 0 then
                    if needIcon then
                        -- Idle engineer icons
                        if Factions[currentFaction].IdleEngTextures[keyToIcon[i]] and UIUtil.UIFile(Factions[currentFaction].IdleEngTextures[keyToIcon[i]],true) then
                            self.icon:SetTexture(UIUtil.UIFile(Factions[currentFaction].IdleEngTextures[keyToIcon[i]],true))
                        else
                            self.icon:SetTexture(UIUtil.UIFile(Factions[currentFaction].IdleEngTextures['T2']))
                        end
                        needIcon = false
                    end
                    for _, unit in sortedUnits[i] do
                        table.insert(self.units, unit)
                    end
                end
                i = i - 1
            end
        elseif self.id == 'factory' then
            local categoryTable = {'LAND','AIR','NAVAL'}
            local sortedFactories = {}
            for i, cat in categoryTable do
                sortedFactories[i] = {}
                sortedFactories[i][1] = EntityCategoryFilterDown(categories.TECH1 * categories[cat], self.allunits)
                sortedFactories[i][2] = EntityCategoryFilterDown(categories.TECH2 * categories[cat], self.allunits)
                sortedFactories[i][3] = EntityCategoryFilterDown(categories.TECH3 * categories[cat], self.allunits)
            end

            local i = 3
            local needIcon = true
            while i > 0 do
                for curCat = 1, 3 do
                    if table.getn(sortedFactories[curCat][i]) > 0 then
                        if needIcon then
                            -- Idle factory icons
                            if UIUtil.UIFile(Factions[currentFaction].IdleFactoryTextures[categoryTable[curCat]][i],true) then
                                self.icon:SetTexture(UIUtil.UIFile(Factions[currentFaction].IdleFactoryTextures[categoryTable[curCat]][i],true))
                            else
                                self.icon:SetTexture(UIUtil.UIFile('/icons/units/default_icon.dds'))
                            end
                            needIcon = false
                        end
                        for _, unit in sortedFactories[curCat][i] do
                            table.insert(self.units, unit)
                        end
                    end
                end
                i = i - 1
            end
           if needIcon == true then
               local ExpFactories = EntityCategoryFilterDown(categories.EXPERIMENTAL, self.allunits)
               if table.getn(ExpFactories) > 0 then
                   local FactoryUnitId = ExpFactories[1]:GetUnitId()
                   if UIUtil.UIFile('/icons/units/' .. FactoryUnitId .. '_icon.dds', true) then
                       self.icon:SetTexture(UIUtil.UIFile('/icons/units/' .. FactoryUnitId .. '_icon.dds', true))
                   else
                       self.icon:SetTexture(UIUtil.UIFile('/icons/units/default_icon.dds'))
                   end
               end
           end
        end
        self.count:SetText(table.getsize(self.allunits))

        if self.expandCheck.expandList then
            self.expandCheck.expandList:Update(self.allunits)
        end
    end

    return bg
end

function GetCheck(id)
    if id == 'engineer' and controls.idleEngineers then
        return controls.idleEngineers.expandCheck
    elseif id == 'factory' and controls.idleFactories then
        return controls.idleFactories.expandCheck
    end
end

function ClickFunc(self, event)
    if event.Type == 'MouseEnter' then
        if self.tooltipKey and not self.tooltip then
            self.tooltip = ToolTip.CreateExtendedToolTip(self, TooltipInfo[self.tooltipKey].title, TooltipInfo[self.tooltipKey].description)
            LayoutHelpers.LeftOf(self.tooltip, self)
            self.tooltip:SetAlpha(0, true)
            self.tooltip:SetNeedsFrameUpdate(true)
            self.tooltip.OnFrame = function(self, deltaTime)
                self:SetAlpha(math.min(self:GetAlpha() + (deltaTime * 3), 1), true)
                if self:GetAlpha() == 1 then
                    self:SetNeedsFrameUpdate(false)
                end
            end
        end
    elseif event.Type == 'MouseExit' then
        if self.tooltip then
            self.tooltip:Destroy()
            self.tooltip = nil
        end
        self.curIndex = 1
    elseif event.Type == 'ButtonPress' then
        if event.Modifiers.Middle and options.gui_idle_engineer_avatars ~= 0 then
            if self.id then --it's a primary idle unit button, deal with all units
                if event.Modifiers.Shift then
                    local curUnits = {}
                    curUnits = GetSelectedUnits() or {}
                    UISelectionByCategory(string.upper(self.id), false, true, false, true)
                    local newSelection = GetSelectedUnits() or {}
                    for i, unit in newSelection do
                        table.insert(curUnits, unit)
                    end
                    SelectUnits(curUnits)
                else
                    UISelectionByCategory(string.upper(self.id), false, true, false, true)
                end
            elseif self.ID then --it's an ACU icon
            else --it's a submenu button, restrict selection to tech levels
                if self.units[1] then
                    local function UnitIsInList(testUnit)
                        for i, unit in self.units do
                            if unit == testUnit then
                                return true
                            end
                        end
                        return false
                    end

                    local curUnits = {}
                    if event.Modifiers.Shift then
                        curUnits = GetSelectedUnits() or {}
                    end

                    if self.units[1]:IsInCategory('ENGINEER') then
                        UISelectionByCategory('ENGINEER', false, true, false, true)
                    else
                        UISelectionByCategory('FACTORY', false, true, false, true)
                    end
                    local tempSelection = GetSelectedUnits() or {}
                    for i, unit in tempSelection do
                        if UnitIsInList(unit) then
                            table.insert(curUnits, unit)
                        end
                    end

                    SelectUnits(curUnits)
                end
            end
        else
            if self.units then
                if not self.units[self.curIndex] then
                    self.curIndex = 1
                end
                if event.Modifiers.Left then
                    local selectUnits = {self.units[self.curIndex]}
                    if event.Modifiers.Shift then
                        selectUnits = GetSelectedUnits() or {}
                        table.insert(selectUnits, self.units[self.curIndex])
                    end
                    SelectUnits(selectUnits)
                elseif event.Modifiers.Right then
                    if event.Modifiers.Shift then
                        local selection = GetSelectedUnits() or {}
                        table.insert(selection, self.units[self.curIndex])
                        UISelectAndZoomTo(self.units[self.curIndex])
                        SelectUnits(selection)
                    else
                        UISelectAndZoomTo(self.units[self.curIndex])
                    end
                end
                self.curIndex = self.curIndex + 1
            end
        end
        return true
    elseif event.Type == 'ButtonDClick' then
        if self.units then
            if not self.units[self.curIndex] then
                self.curIndex = 1
            end
            if event.Modifiers.Left then
                local selectUnits = self.units
                if event.Modifiers.Shift then
                    selectUnits = GetSelectedUnits() or {}
                    for _, unit in self.units do
                        table.insert(selectUnits, unit)
                    end
                end
                SelectUnits(selectUnits)
            elseif event.Modifiers.Right then
                if event.Modifiers.Shift then
                    local selection = GetSelectedUnits() or {}
                    for _, unit in self.units do
                        table.insert(selection, unit)
                    end
                    UISelectAndZoomTo(self.units[self.curIndex])
                    SelectUnits(selection)
                else
                    UISelectAndZoomTo(self.units[self.curIndex])
                    SelectUnits(self.units)
                end
            end
            self.curIndex = self.curIndex + 1
        end
        return true
    end
end

function CreateIdleEngineerList(parent, units)
    local group = Group(parent)

    local bgTop = Bitmap(group, UIUtil.SkinnableFile('/game/avatar-engineers-panel/panel-eng_bmp_t.dds'))
    local bgBottom = Bitmap(group, UIUtil.SkinnableFile('/game/avatar-engineers-panel/panel-eng_bmp_b.dds'))
    local bgStretch = Bitmap(group, UIUtil.SkinnableFile('/game/avatar-engineers-panel/panel-eng_bmp_m.dds'))

    group.Width:Set(bgTop.Width)
    group.Height:Set(1)

    bgTop.Bottom:Set(group.Top)
    bgBottom.Top:Set(group.Bottom)
    bgStretch.Top:Set(group.Top)
    bgStretch.Bottom:Set(group.Bottom)

    LayoutHelpers.AtHorizontalCenterIn(bgTop, group)
    LayoutHelpers.AtHorizontalCenterIn(bgBottom, group)
    LayoutHelpers.AtHorizontalCenterIn(bgStretch, group)

    group.connector = Bitmap(group, UIUtil.SkinnableFile('/game/avatar-engineers-panel/bracket_bmp.dds'))
    group.connector.Right:Set(function() return parent.Left() + 8 end)
    LayoutHelpers.AtVerticalCenterIn(group.connector, parent)

    LayoutHelpers.LeftOf(group, parent, 10)
    group.Top:Set(function() return math.max(controls.avatarGroup.Top()+10, (parent.Top() + (parent.Height() / 2)) - (group.Height() / 2)) end)

    group:DisableHitTest(true)

    group.icons = {}

    group.Update = function(self, unitData)
        local function CreateUnitEntry(techLevel, userUnits, icontexture)
            local entry = Group(self)

            entry.icon = Bitmap(entry)
            -- Iddle engineer icons groupwindow
            if UIUtil.UIFile(icontexture,true) then
                entry.icon:SetTexture(UIUtil.UIFile(icontexture,true))
            else
                entry.icon:SetTexture(UIUtil.UIFile('/icons/units/default_icon.dds'))
            end
            entry.icon.Height:Set(34)
            entry.icon.Width:Set(34)
            LayoutHelpers.AtRightIn(entry.icon, entry, 22)
            LayoutHelpers.AtVerticalCenterIn(entry.icon, entry)

            entry.iconBG = Bitmap(entry, UIUtil.SkinnableFile('/game/avatar-factory-panel/avatar-s-e-f_bmp.dds'))
            LayoutHelpers.AtCenterIn(entry.iconBG, entry.icon)
            entry.iconBG.Depth:Set(function() return entry.icon.Depth() - 1 end)

            if options.gui_scu_manager ~= 0 then
                --SCU MANAGER SHOW CORRECT ICON
                if techLevel == 'C' or techLevel == 'E' then
                    entry.techIcon = Bitmap(entry, UIUtil.UIFile('/SCUManager/tech-'..techLevel..'_bmp.dds'))
                else
                    entry.techIcon = Bitmap(entry, UIUtil.SkinnableFile('/game/avatar-engineers-panel/tech-'..techLevel..'_bmp.dds'))
                end
            else
                entry.techIcon = Bitmap(entry, UIUtil.SkinnableFile('/game/avatar-engineers-panel/tech-'..techLevel..'_bmp.dds'))
            end
            LayoutHelpers.AtLeftIn(entry.techIcon, entry)
            LayoutHelpers.AtVerticalCenterIn(entry.techIcon, entry.icon)

            entry.count = UIUtil.CreateText(entry, '', 20, UIUtil.bodyFont)
            entry.count:SetColor('ffffffff')
            entry.count:SetDropShadow(true)
            LayoutHelpers.AtRightIn(entry.count, entry.icon)
            LayoutHelpers.AtBottomIn(entry.count, entry.icon)

            entry.countBG = Bitmap(entry)
            entry.countBG:SetSolidColor('77000000')
            entry.countBG.Top:Set(function() return entry.count.Top() - 1 end)
            entry.countBG.Left:Set(function() return entry.count.Left() - 1 end)
            entry.countBG.Right:Set(function() return entry.count.Right() + 1 end)
            entry.countBG.Bottom:Set(function() return entry.count.Bottom() + 1 end)

            entry.countBG.Depth:Set(function() return entry.Depth() + 1 end)
            entry.count.Depth:Set(function() return entry.countBG.Depth() + 1 end)

            entry.Height:Set(function() return entry.iconBG.Height() end)
            entry.Width:Set(self.Width)

            entry.icon:DisableHitTest()
            entry.iconBG:DisableHitTest()
            entry.techIcon:DisableHitTest()
            entry.count:DisableHitTest()
            entry.countBG:DisableHitTest()

            entry.curIndex = 1
            entry.units = userUnits
            entry.HandleEvent = ClickFunc

            return entry
        end
        local engineers = {}
        if options.gui_scu_manager ~= 0 then
            engineers[7] = {}
            engineers[6] = {}
            engineers[5] = {}
        else
            engineers[5] = EntityCategoryFilterDown(categories.SUBCOMMANDER, unitData)
        end
        engineers[4] = EntityCategoryFilterDown(categories.TECH3 - categories.SUBCOMMANDER, unitData)
        engineers[3] = EntityCategoryFilterDown(categories.FIELDENGINEER, unitData)
        engineers[2] = EntityCategoryFilterDown(categories.TECH2 - categories.FIELDENGINEER, unitData)
        engineers[1] = EntityCategoryFilterDown(categories.TECH1, unitData)

        local indexToIcon = {'1', '2', '2', '3', '3'}
        local keyToIcon = {'T1','T2','T2F','T3','SCU'}
        if options.gui_scu_manager ~= 0 then
            local tempSCUs = EntityCategoryFilterDown(categories.SUBCOMMANDER, unitData)

            if table.getsize(tempSCUs) > 0 then
                for i, unit in tempSCUs do
                    if unit.SCUType then
                        if unit.SCUType == 'Combat' then
                            table.insert(engineers[7], unit)
                        elseif unit.SCUType == 'Engineer' then
                            table.insert(engineers[6], unit)
                        end
                    else
                        table.insert(engineers[5], unit)
                    end
                end
            end
            indexToIcon = {'1', '2', '2', '3', '3', 'E', 'C'}
            keyToIcon = {'T1','T2','T2F','T3','SCU', 'SCU', 'SCU'}
        end

        for index, units in engineers do
            local i = index
            if i == 3 and currentFaction ~= 1 then
                continue
            end
            if not self.icons[i] then
                self.icons[i] = CreateUnitEntry(indexToIcon[i], units, Factions[currentFaction].IdleEngTextures[keyToIcon[index]])
                self.icons[i].priority = i
            end
            if table.getn(units) > 0 and not self.icons[i]:IsHidden() then
                self.icons[i].units = units
                self.icons[i].count:SetText(table.getn(units))
                self.icons[i].count:Show()
                self.icons[i].countBG:Show()
                self.icons[i].icon:SetAlpha(1)
            else
                self.icons[i].units = {}
                self.icons[i].count:Hide()
                self.icons[i].countBG:Hide()
                self.icons[i].icon:SetAlpha(.2)
            end
        end
        local prevGroup = false
        local groupHeight = 0
        for index, engGroup in engineers do
            local i = index
            if not self.icons[i] then continue end
            if prevGroup then
                LayoutHelpers.Above(self.icons[i], prevGroup)
            else
                LayoutHelpers.AtLeftIn(self.icons[i], self, 7)
                LayoutHelpers.AtBottomIn(self.icons[i], self, 2)
            end
            groupHeight = groupHeight + self.icons[i].Height()
            prevGroup = self.icons[i]
        end
        group.Height:Set(groupHeight)
    end

    group:Update(units)

    return group
end

function CreateIdleFactoryList(parent, units)
    local bg = Bitmap(parent, UIUtil.SkinnableFile('/game/avatar-factory-panel/factory-panel_bmp.dds'))

    bg.Right:Set(function() return parent.Left() - 9 end)
    bg.Top:Set(function() return math.max(controls.avatarGroup.Top()+10, (parent.Top() + (parent.Height() / 2)) - (bg.Height() / 2)) end)

    local connector = Bitmap(bg, UIUtil.SkinnableFile('/game/avatar-factory-panel/bracket_bmp.dds'))
    LayoutHelpers.AtVerticalCenterIn(connector, parent)
    connector.Right:Set(function() return parent.Left() + 7 end)

    bg:DisableHitTest(true)

    bg.icons = {}

    local iconData = {'LAND','AIR','NAVAL'}

    local idleTextures = Factions[currentFaction].IdleFactoryTextures

    local prevIcon = false
    for type, category in iconData do
        local function CreateIcon(texture)
            local icon = Bitmap(bg)
            -- Idle facory icons groupwindow
            if UIUtil.UIFile(texture,true) then
                icon:SetTexture(UIUtil.UIFile(texture,true))
            else
                icon:SetTexture(UIUtil.UIFile('/icons/units/default_icon.dds'))
            end
            icon.Height:Set(40)
            icon.Width:Set(40)

            icon.count = UIUtil.CreateText(icon, '', 20, UIUtil.bodyFont)
            icon.count:SetColor('ffffffff')
            LayoutHelpers.AtRightIn(icon.count, icon)
            LayoutHelpers.AtBottomIn(icon.count, icon)

            icon.countBG = Bitmap(icon)
            icon.countBG:SetSolidColor('77000000')
            icon.countBG.Top:Set(function() return icon.count.Top() - 1 end)
            icon.countBG.Left:Set(function() return icon.count.Left() - 1 end)
            icon.countBG.Right:Set(function() return icon.count.Right() + 1 end)
            icon.countBG.Bottom:Set(function() return icon.count.Bottom() + 1 end)

            icon.countBG.Depth:Set(function() return icon.Depth() + 1 end)
            icon.count.Depth:Set(function() return icon.countBG.Depth() + 1 end)

            icon.curIndex = 1
            icon.HandleEvent = ClickFunc

            return icon
        end
        bg.icons[category] = {}
        local table = bg.icons[category]
        for index=1, 3 do
            local i = index
            table[i] = CreateIcon(idleTextures[category][i])
            if i == 1 then
                if prevIcon then
                    LayoutHelpers.RightOf(table[i], prevIcon, 4)
                else
                    LayoutHelpers.AtLeftIn(table[i], bg, 38)
                    LayoutHelpers.AtBottomIn(table[i], bg, 10)
                end
                prevIcon = table[i]
            else
                LayoutHelpers.Above(table[i], table[i-1], 4)
            end
        end
    end

    bg.Update = function(self, unitData)
        local factories = {LAND = {}, AIR = {}, NAVAL = {}}
        for type, table in factories do
            table[1] = EntityCategoryFilterDown(categories.TECH1 * categories[type], unitData)
            table[2] = EntityCategoryFilterDown(categories.TECH2 * categories[type], unitData)
            table[3] = EntityCategoryFilterDown(categories.TECH3 * categories[type], unitData)
        end
        for type, icons in bg.icons do
            for index=1,3 do
                local i = index
                if table.getn(factories[type][i]) > 0 then
                    bg.icons[type][i].units = factories[type][i]
                    bg.icons[type][i]:SetAlpha(1)
                    bg.icons[type][i].countBG:Show()
                    bg.icons[type][i].count:SetText(table.getn(factories[type][i]))
                else
                    bg.icons[type][i]:SetAlpha(.2)
                    bg.icons[type][i].countBG:Hide()
                    bg.icons[type][i].count:SetText('')
                end
            end
        end
    end

    bg:Update(units)

    return bg
end

function AvatarUpdate()
    if import('/lua/ui/game/gamemain.lua').IsNISMode() then
        return
    end
    local avatars = GetArmyAvatars()
    local engineers = GetIdleEngineers()
    local factories = GetIdleFactories()
    local needsAvatarLayout = false
    local validAvatars = {}

    -- Find the faction key (1 - 4 valid. 5+ happen for Civilian, default to 4 to use Seraphim textures)
    -- armiesTable[GetFocusArmy()].faction returns 0 = UEF, 1 = Aeon, 2 = Cybran, 3 = Seraphim, 4 = Civilian Army, 5 = Civilian Neutral
    -- We want 1 - 4, with 4 max
    currentFaction = math.min(GetArmiesTable().armiesTable[GetFocusArmy()].faction + 1, 4)

    if avatars then
        for _, unit in avatars do
            if controls.avatars[unit:GetEntityId()] then
                controls.avatars[unit:GetEntityId()]:Update()
            else
                controls.avatars[unit:GetEntityId()] = CreateAvatar(unit)
                needsAvatarLayout = true
            end
            validAvatars[unit:GetEntityId()] = true
        end
        for entID, control in controls.avatars do
            local i = entID
            if not validAvatars[i] then
                controls.avatars[i]:Destroy()
                controls.avatars[i] = nil
                needsAvatarLayout = true
            end
        end
    elseif controls.avatars then
        for entID, control in controls.avatars do
            local i = entID
            controls.avatars[i]:Destroy()
            controls.avatars[i] = nil
            needsAvatarLayout = true
        end
    end

    if engineers then
        if controls.idleEngineers then
            controls.idleEngineers:Update(engineers)
        else
            controls.idleEngineers = CreateIdleTab(engineers, 'engineer', CreateIdleEngineerList)
            if expandedCheck == 'engineer' then
                controls.idleEngineers.expandCheck:SetCheck(true)
            end
            needsAvatarLayout = true
        end
    else
        if controls.idleEngineers then
            controls.idleEngineers:Destroy()
            controls.idleEngineers = nil
            needsAvatarLayout = true
        end
    end

    if factories and table.getn(EntityCategoryFilterDown(categories.ALLUNITS - categories.GATE, factories)) > 0 then
        if controls.idleFactories then
            controls.idleFactories:Update(EntityCategoryFilterDown(categories.ALLUNITS - categories.GATE, factories))
        else
            controls.idleFactories = CreateIdleTab(EntityCategoryFilterDown(categories.ALLUNITS - categories.GATE, factories), 'factory', CreateIdleFactoryList)
            if expandedCheck == 'factory' then
                controls.idleFactories.expandCheck:SetCheck(true)
            end
            needsAvatarLayout = true
        end
    else
        if controls.idleFactories then
            controls.idleFactories:Destroy()
            controls.idleFactories = nil
            needsAvatarLayout = true
        end
    end

    if needsAvatarLayout then
        import(UIUtil.GetLayoutFilename('avatars')).LayoutAvatars()
    end

    local buttons = import('/modules/scumanager.lua').buttonGroup
    if options.gui_scu_manager == 0 then
        buttons:Hide()
    else
        buttons:Show()
        buttons.Right:Set(function() return controls.collapseArrow.Right() - 2 end)
        buttons.Top:Set(function() return controls.collapseArrow.Bottom() end)
    end
end

function FocusArmyChanged()
    for i, control in controls.avatars do
        local index = i
        if controls.avatars[index] then
            controls.avatars[index]:Destroy()
            controls.avatars[index] = nil
        end
    end
    if GetFocusArmy() == -1 then
        GameMain.RemoveBeatFunction(AvatarUpdate)
        recievingBeatUpdate = false
    elseif not recievingBeatUpdate then
        recievingBeatUpdate = true
        GameMain.AddBeatFunction(AvatarUpdate, true)
    end
end

local preContractState = false
function Contract()
    preContractState = controls.avatarGroup:IsHidden()
    controls.avatarGroup:Hide()
    controls.collapseArrow:Hide()
end

function Expand()
    controls.avatarGroup:SetHidden(preContractState)
    controls.collapseArrow:Show()
end

function InitialAnimation()
    controls.avatarGroup:Show()
    controls.avatarGroup.Left:Set(controls.parent.Left()-controls.avatarGroup.Width())
    controls.avatarGroup:SetNeedsFrameUpdate(true)
    controls.avatarGroup.OnFrame = function(self, delta)
        local newLeft = self.Left() + (1000*delta)
        if newLeft > controls.parent.Left()-3 then
            newLeft = function() return controls.parent.Left()-3 end
            self:SetNeedsFrameUpdate(false)
        end
        self.Left:Set(newLeft)
    end
    controls.collapseArrow:Show()
    controls.collapseArrow:SetCheck(false, true)
end
