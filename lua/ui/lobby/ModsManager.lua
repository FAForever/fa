---------------------------------------
-- File: lua/modules/ui/lobby/lobby.lua
-- Author: Xinnony
-- Summary: Mods Manager GUI
---------------------------------------

local Mods = import('/lua/mods.lua')
local UIUtil = import('/lua/ui/uiutil.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local MultiLineText = import('/lua/maui/multilinetext.lua').MultiLineText
local Prefs = import('/lua/user/prefs.lua')
local GUI_OPEN = false

function UpdateClientModStatus(mod_selec)
    if GUI_OPEN then
        IsHost = false
        modstatus = mod_selec
        Refresh_Mod_List(false, true, true, IsHost, modstatus, false)
    end
end

function HostModStatus(availableMods)
    Mods.ClearCache() -- Force reload of mod info to pick up changes on disk
    local my_all = Mods.AllSelectableMods()
    local my_sel = Mods.GetSelectedMods()
    local r = {}

    local function everyoneHas(uid)
        for peer, modset in availableMods do
            if not modset[uid] then
                return false
            end
        end
        return true
    end

    for uid,mod in my_all do
        if mod.ui_only or everyoneHas(uid) then
            if mod.ui_only then
                r[uid] = true
            else
                r[uid] = true
            end
        else
            r[uid] = false
        end
    end
    return r
end

function NEW_MODS_GUI(parent, IsHost, modstatus, availableMods)
    GUI = parent
    if IsHost then modstatus = false end
    GUI_ModsManager = Group(GUI)
    LayoutHelpers.AtCenterIn(GUI_ModsManager, GUI)
    GUI_ModsManager.Depth:Set(GetFrame(parent:GetRootFrame():GetTargetHead()):GetTopmostDepth() + 1)
        
    local background = Bitmap(GUI_ModsManager, UIUtil.SkinnableFile('/scx_menu/lan-game-lobby/Mod_Lobby.dds'))
    GUI_ModsManager.Width:Set(background.Width)
    GUI_ModsManager.Height:Set(background.Height)
    LayoutHelpers.FillParent(background, GUI_ModsManager)
        
    local dialog2 = Group(GUI_ModsManager)
    dialog2.Width:Set(537)
    dialog2.Height:Set(548)
    LayoutHelpers.AtCenterIn(dialog2, GUI_ModsManager)
        
    -- Title
    local text0 = UIUtil.CreateText(dialog2, 'Mod Manager', 17, 'Arial')
    text0:SetColor('B9BFB9')
    text0:SetDropShadow(true)
    LayoutHelpers.AtHorizontalCenterIn(text0, dialog2, 0)
    LayoutHelpers.AtTopIn(text0, dialog2, 10)
        
    -- SubTitle
    local text1 = UIUtil.CreateText(dialog2, '', 12, 'Arial')
    text1:SetColor('B9BFB9')
    text1:SetDropShadow(true)
    LayoutHelpers.AtHorizontalCenterIn(text1, dialog2, 0)
    LayoutHelpers.AtTopIn(text1, dialog2, 26)
        
    -- Save button
    local SaveButton = UIUtil.CreateButtonWithDropshadow(dialog2, '/BUTTON/medium/', "Ok", -1)
    LayoutHelpers.AtLeftIn(SaveButton, dialog2, 0)
    LayoutHelpers.AtBottomIn(SaveButton, dialog2, 10)
        
    -- Checkbox UI mod filter
    local cbox_UI = UIUtil.CreateCheckboxStd(dialog2, '/RADIOBOX/radio')
    LayoutHelpers.AtLeftIn(cbox_UI, dialog2, 20+130+10)
    LayoutHelpers.AtBottomIn(cbox_UI, dialog2, 16)
    Tooltip.AddCheckboxTooltip(cbox_UI, {text='UI Mods', body='UI mods are activated only for you. You can have a mod of this type activated without the enemy knowing'})
    cbox_UI_TEXT = UIUtil.CreateText(cbox_UI, 'UI Mods', 14, 'Arial')
        
    cbox_UI_TEXT:SetColor('B9BFB9')
    cbox_UI_TEXT:SetDropShadow(true)
    LayoutHelpers.AtLeftIn(cbox_UI_TEXT, cbox_UI, 25)
    LayoutHelpers.AtVerticalCenterIn(cbox_UI_TEXT, cbox_UI)
    cbox_UI:SetCheck(true, true)
            
    -- Checkbox game mod filter
    local cbox_GAME = UIUtil.CreateCheckboxStd(dialog2, '/RADIOBOX/radio')
    LayoutHelpers.AtLeftIn(cbox_GAME, dialog2, 20+130+100)
    LayoutHelpers.AtBottomIn(cbox_GAME, dialog2, 16)
    Tooltip.AddCheckboxTooltip(cbox_GAME, {text='Game Mods', body='Game mods are activated for all players, and all players must have the same version of the mod'})
    cbox_GAME_TEXT = UIUtil.CreateText(cbox_GAME, 'Game Mods', 14, 'Arial')
        
    cbox_GAME_TEXT:SetColor('B9BFB9')
    cbox_GAME_TEXT:SetDropShadow(true)
    LayoutHelpers.AtLeftIn(cbox_GAME_TEXT, cbox_GAME, 25)
    LayoutHelpers.AtVerticalCenterIn(cbox_GAME_TEXT, cbox_GAME)
    cbox_GAME:SetCheck(false, true)
            
    -- Checkbox hide unselectable mods
    local cbox_Act = UIUtil.CreateCheckboxStd(dialog2, '/CHECKBOX/radio')
    LayoutHelpers.AtLeftIn(cbox_Act, dialog2, 20+130+120+100)
    LayoutHelpers.AtBottomIn(cbox_Act, dialog2, 23)
    Tooltip.AddCheckboxTooltip(cbox_Act, {text='Hide Unselectable', body='Hide mods which are unselectable due to compatibility issues, or because a player in the lobby does not have them'})
    cbox_Act_TEXT = UIUtil.CreateText(cbox_Act, 'Hide Unselectable', 14, 'Arial')
        
    cbox_Act_TEXT:SetColor('B9BFB9')
    cbox_Act_TEXT:SetDropShadow(true)
    LayoutHelpers.AtLeftIn(cbox_Act_TEXT, cbox_Act, 25)
    LayoutHelpers.AtVerticalCenterIn(cbox_Act_TEXT, cbox_Act)
    cbox_Act:SetCheck(true, true)
            
    -- Checkbox condensed list
    local cbox_Act2 = UIUtil.CreateCheckboxStd(dialog2, '/CHECKBOX/radio')
    LayoutHelpers.AtLeftIn(cbox_Act2, dialog2, 20+130+120+100)
    LayoutHelpers.AtBottomIn(cbox_Act2, dialog2, 6)
    Tooltip.AddCheckboxTooltip(cbox_Act2, {text='Condensed View', body='Displays mods as a simplified list'})
    cbox_Act_TEXT2 = UIUtil.CreateText(cbox_Act2, 'Condensed View', 14, 'Arial')
    
    cbox_Act_TEXT2:SetColor('B9BFB9')
    cbox_Act_TEXT2:SetDropShadow(true)
    LayoutHelpers.AtLeftIn(cbox_Act_TEXT2, cbox_Act2, 25)
    LayoutHelpers.AtVerticalCenterIn(cbox_Act_TEXT2, cbox_Act2)
    
    local XinnoModsManagerLittleView = Prefs.GetFromCurrentProfile('XinnoModsManagerLittleView') or false
    if XinnoModsManagerLittleView then
        cbox_Act2:SetCheck(true, true)
    else
        cbox_Act2:SetCheck(false, true)
    end
    
    if IsHost then
        cbox_GAME:Enable()
        cbox_Act:Enable()
    else
        cbox_GAME:Disable()
        cbox_Act:Disable()
        cbox_GAME_TEXT:Disable()
        cbox_Act_TEXT:Disable()
        cbox_GAME:SetCheck(false, true)
        cbox_Act:SetCheck(false, true)
        cbox_GAME_TEXT:SetColor('5C5F5C')
        cbox_Act_TEXT:SetColor('5C5F5C')
    end
    cbox_GAME.OnCheck = function(self, checked)
        if checked then
            cbox_UI:SetCheck(false, true)
            if IsHost then
                save_mod()
                swiffer()
                Refresh_Mod_List(checked, cbox_UI:IsChecked(), cbox_Act:IsChecked(), IsHost, modstatus, cbox_Act2:IsChecked())
            end
        else
            cbox_GAME:SetCheck(true, true)
        end
    end
    cbox_UI.OnCheck = function(self, checked)
        if checked then
            cbox_GAME:SetCheck(false, true)
            save_mod()
            swiffer()
            Refresh_Mod_List(cbox_GAME:IsChecked(), checked, cbox_Act:IsChecked(), IsHost, modstatus, cbox_Act2:IsChecked())
        else
            cbox_UI:SetCheck(true, true)
        end
    end
    cbox_Act.OnCheck = function(self, checked)
        if IsHost then
            save_mod()
            swiffer()
            Refresh_Mod_List(cbox_GAME:IsChecked(), cbox_UI:IsChecked(), checked, IsHost, modstatus, cbox_Act2:IsChecked())
        end
    end
    cbox_Act2.OnCheck = function(self, checked)
        save_mod()
        swiffer()
        Refresh_Mod_List(cbox_GAME:IsChecked(), cbox_UI:IsChecked(), cbox_Act:IsChecked(), IsHost, modstatus, checked)
        Prefs.SetToCurrentProfile('XinnoModsManagerLittleView', checked)
    end

    -- Mod list
    local scrollGroup = Group(dialog2)
    scrollGroup.Width:Set(519)
    scrollGroup.Height:Set(450)
    LayoutHelpers.AtLeftTopIn(scrollGroup, dialog2, 0, 47)
    UIUtil.CreateLobbyVertScrollbar(scrollGroup)
    scrollGroup.controlList = {}
    scrollGroup.top = 1
    numElementsPerPage = 6
    
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
    
    scrollGroup.CalcVisible = function(self)
        local top = self.top
        local bottom = self.top + numElementsPerPage
        for index, control in ipairs(self.controlList) do
            if index < top or index >= bottom then
                control:Hide()
            else
                control:Show()
                control.Left:Set(self.Left)
                local lIndex = index
                local lControl = control
                control.Top:Set(function() return self.Top() + ((lIndex - top) * lControl.Height()) end)
            end
        end
    end
    
    SaveButton.OnClick = function(self)
        save_mod()
        GUI_OPEN = false
        import('/lua/ui/lobby/lobby.lua').OnModsChanged(selectedMods)
        GUI_ModsManager:Destroy()
        return selectedMods
    end
    
    function count_mod_UI_actived()
        count_ui = 0
        for k, v in scrollGroup.controlList do
            if v.actived and v.modInfo.ui_only then
                count_ui = count_ui + 1
            end
        end
        return count_ui
    end
    
    function count_mod_SIM_actived()
        count_sim = 0
        for k, v in scrollGroup.controlList do
            if v.actived and not v.modInfo.ui_only then
                count_sim = count_sim + 1
            end
        end
        return count_sim
    end
    
    function swiffer()
        for k, v in scrollGroup.controlList do
            v:Destroy()
        end
    end
    
    function save_mod()
        selectedMods = {}
        for index, control in scrollGroup.controlList do
            if control.actived then
                selectedMods[control.modInfo.uid] = true
            end
        end
        import('/lua/mods.lua').SetSelectedMods(selectedMods)
    end
    
    function Refresh_Mod_List(cbox_GAME, cbox_UI, cbox_Act, IsHost, modstatus, cbox_Act2)
        index = 0
        exclusiveMod = false
        current_list = {}
        scrollGroup.controlList = {}
        local allmods = Mods.AllSelectableMods()
        local selmods = Mods.GetSelectedMods()
        local unselmods = Mods.GetUnSelectedMods()
        local GetUI_Activedmods = Mods.GetUiMods() -- Active UI
        local GetUI_Unactivedmods = Mods.GetUiMods(unselmods) -- Active + Inactive UI
        local GetSIM_Activedmods = Mods.GetGameMods() -- Active SIM
        local GetSIM_Unactivedmods = Mods.GetGameMods(unselmods) -- Active + Inactive SIM

        if not IsHost then
            for k, v in allmods do
                if modstatus[v.uid] then
                    table.insert(current_list, v)
                end
            end
            for k, v in GetUI_Activedmods do
                table.insert(current_list, v)
            end
            if cbox_UI then
                for k, v in GetUI_Unactivedmods do
                    table.insert(current_list, v)
                end
            end
        else
            for k, v in GetSIM_Activedmods do
                table.insert(current_list, v)
            end
            for k, v in GetUI_Activedmods do
                table.insert(current_list, v)
            end
            if cbox_GAME and IsHost then
                for k, v in GetSIM_Unactivedmods do
                    table.insert(current_list, v)
                end
            end
            if cbox_UI then
                for k, v in GetUI_Unactivedmods do
                    table.insert(current_list, v)
                end
            end
        end
        
        -- Remove mods which are unselectable because of conflicts or because not all the players have them
        if cbox_Act then
            for i, v in current_list do
                if not v.selectable or availableMods[v.uid] == v.uid then
                    table.remove(current_list, i)
                    i = i - 1
                end
            end
        end
        
        table.sort(current_list, function(a,b)
            if selmods[a.uid] and selmods[b.uid] then
                return a.name < b.name
            elseif selmods[a.uid] or selmods[b.uid] then
                return selmods[a.uid] or false
            else
                return a.name < b.name
            end
        end)

        for k, v in current_list do
            if not cbox_Act2 then
                table.insert(scrollGroup.controlList, CreateListElementtt(scrollGroup, v, k, false))
            else
                table.insert(scrollGroup.controlList, CreateListElementtt(scrollGroup, v, k, true))
            end
            if IsHost and selmods[v.uid] then
                scrollGroup.controlList[k].actived = true
                scrollGroup.controlList[k].type:SetColor('101010')
                if v.ui_only then
                    scrollGroup.controlList[k].type:SetText('UI Mod Activated')
                    scrollGroup.controlList[k].bg:SetTexture('/textures/ui/common/MODS/enable_ui.dds')
                else
                    scrollGroup.controlList[k].type:SetText('Game Mod Activated')
                    scrollGroup.controlList[k].bg:SetTexture('/textures/ui/common/MODS/enable_game.dds')
                end
            elseif not IsHost and modstatus[v.uid] and not v.ui_only then
                scrollGroup.controlList[k].actived = true
                scrollGroup.controlList[k].type:SetColor('101010')
                scrollGroup.controlList[k].type:SetText('Game Mod Activated')
                scrollGroup.controlList[k].bg:SetTexture('/textures/ui/common/MODS/enable_game.dds')
            elseif not IsHost and selmods[v.uid] and v.ui_only then
                scrollGroup.controlList[k].actived = true
                scrollGroup.controlList[k].type:SetColor('101010')
                scrollGroup.controlList[k].type:SetText('UI Mod Activated')
                scrollGroup.controlList[k].bg:SetTexture('/textures/ui/common/MODS/enable_ui.dds')
            end
            if scrollGroup.controlList[k].modInfo.exclusive and selmods[v.uid] then
                exclusiveMod = true
                scrollGroup.controlList[k].actived = true
                scrollGroup.controlList[k].type:SetColor('101010')
                scrollGroup.controlList[k].type:SetText('Exclusive Mod Activated')
                scrollGroup.controlList[k].bg:SetTexture('/textures/ui/common/MODS/enable_excusif.dds')
            end
        end
        
        text1:SetText(count_mod_SIM_actived()..' Game Mods and '..count_mod_UI_actived()..' UI Mods actived')
        
        local function UNActiveMod(the_mod)
            the_mod.actived = false
            the_mod.type:SetColor('B9BFB9')
            the_mod.bg:SetTexture('/textures/none.dds')
            the_mod.bg0:SetTexture('/textures/none.dds')
            if the_mod.ui then
                the_mod.type:SetText('UI Mod')
            else
                the_mod.type:SetText('Game Mod')
            end
        end
        
        local function ActiveExclusifMod(the_exclusif_mod)
            local function FUNC_RUN()
                exclusiveMod = true
                for index, control in scrollGroup.controlList do
                    if control.actived and control != the_exclusif_mod then
                        UNActiveMod(control)
                    end
                end
                the_exclusif_mod.actived = true
                the_exclusif_mod.type:SetColor('101010')
                the_exclusif_mod.type:SetText('Exclusive Mod Activated')
                the_exclusif_mod.bg:SetTexture('/textures/ui/common/MODS/enable_excusif.dds')
                PlaySound(Sound({Cue = "UI_Mod_Select", Bank = "Interface",}))
                text1:SetText(count_mod_SIM_actived()..' Game Mods and '..count_mod_UI_actived()..' UI Mods actived')
            end
            UIUtil.QuickDialog(GUI_ModsManager, 
                "<LOC uimod_0010>The mod you have requested is marked as exclusive. If you select this mod, all other mods will be disabled. Do you wish to enable this mod?",
                "<LOC _Yes>", FUNC_RUN,
                "<LOC _No>")
        end
        
        local function ActiveMod(the_mod)
            local depends = Mods.GetDependencies(the_mod.modInfo.uid)
            local skipExit = false
            local allMods = Mods.AllMods()
            
            if depends.missing then
                local boxText = LOC("<LOC uimod_0012>The requested mod can not be enabled as it requires the following mods that you don't currently have installed:\n\n")
                for uid, v in depends.missing do
                    local name
                    if the_mod.modInfo.requiresNames and the_mod.modInfo.requiresNames[uid] then
                        name = the_mod.modInfo.requiresNames[uid]
                    else
                        name = uid
                    end
                    boxText = boxText .. name .. "\n"
                end
                UIUtil.QuickDialog(GUI_ModsManager, boxText, "<LOC _Ok>")
                skipExit = true
            
            elseif depends.requires then
                local Tname = {}
                for uid, v in depends.requires do
                    local name
                    if the_mod.modInfo.requiresNames and the_mod.modInfo.requiresNames[uid] then
                        table.insert(Tname, uid)
                        name = the_mod.modInfo.requiresNames[uid]
                    else
                        table.insert(Tname, uid)
                        name = uid
                    end
                end
                for i, c in Tname do -- Check if the Mod is listed in the GUI
                    exist = false
                    for index, control in scrollGroup.controlList do
                        if control.modInfo.uid == c then
                            exist = true
                            control.actived = true
                            if control.ui then
                                control.type:SetColor('101010')
                                control.type:SetText('UI Mod Activated')
                                control.bg:SetTexture('/textures/ui/common/MODS/enable_ui.dds')
                            else
                                control.type:SetColor('101010')
                                control.type:SetText('Game Mod Activated')
                                control.bg:SetTexture('/textures/ui/common/MODS/enable_game.dds')
                            end
                        end
                    end
                    if not exist then -- IF The mod is not listed in the GUI, create the mod in the list
                        table.insert(scrollGroup.controlList, the_mod.pos+1, CreateListElementtt(scrollGroup, allMods[c], the_mod.pos, false))
                        control = scrollGroup.controlList[the_mod.pos+1]
                        control.actived = true
                        if control.ui then
                            control.type:SetColor('101010')
                            control.type:SetText('UI Mod Activated')
                            control.bg:SetTexture('/textures/ui/common/MODS/enable_ui.dds')
                        else
                            control.type:SetColor('101010')
                            control.type:SetText('Game Mod Activated')
                            control.bg:SetTexture('/textures/ui/common/MODS/enable_game.dds')
                        end
                        EVENT_Click()
                        scrollGroup:CalcVisible()
                    end
                end
            
            elseif depends.conflicts then
                local boxText = LOC("You can't enable this because of conflicts with the following mod :\n")
                local conflict = false
                local Tname = {}
                for uid, v in depends.conflicts do
                    local name
                    if the_mod.modInfo.requiresNames and the_mod.modInfo.requiresNames[uid] then
                        table.insert(Tname, uid)
                        name = the_mod.modInfo.requiresNames[uid]
                    else
                        table.insert(Tname, uid)
                        name = uid
                    end
                end
                for i, c in Tname do -- Get the name of the conflict mod
                    if allMods[c].name then
                        boxText = boxText .. allMods[c].name .. '\n'
                    else
                        boxText = boxText .. '- '.. c .. '\n'
                    end
                end
                for index, control in scrollGroup.controlList do -- Check if the conflict mod is active or not
                    for i, c in Tname do
                        if control.modInfo.uid == c and control.actived then
                            conflict = true
                        end
                    end
                end
                --
                if conflict then
                    UIUtil.QuickDialog(GUI_ModsManager, boxText, "<LOC _Ok>")
                    skipExit = true
                end
            end
            
            if not skipExit then
                the_mod.actived = true
                if the_mod.ui then
                    the_mod.type:SetColor('101010')
                    the_mod.type:SetText('UI Mod Activated')
                    the_mod.bg:SetTexture('/textures/ui/common/MODS/enable_ui.dds')
                else
                    the_mod.type:SetColor('101010')
                    the_mod.type:SetText('Game Mod Activated')
                    the_mod.bg:SetTexture('/textures/ui/common/MODS/enable_game.dds')
                end
            end
        end
        
        local function ActiveModAndRemoveExclusifMod(the_mod)
            local function FUNC_RUN()
                LOG('>> ActiveModAndRemoveExclusifMod')
                exclusiveMod = false
                for index, control in scrollGroup.controlList do
                    if control.actived and control.modInfo.exclusive then
                        UNActiveMod(control)
                    end
                end
                ActiveMod(the_mod)
                PlaySound(Sound({Cue = "UI_Mod_Select", Bank = "Interface",}))
                text1:SetText(count_mod_SIM_actived()..' Game Mods and '..count_mod_UI_actived()..' UI Mods actived')
            end
            UIUtil.QuickDialog(GUI_ModsManager,
                "<LOC uimod_0011>You currently have an exclusive mod selected, do you wish to deselect it?",
                "<LOC _Yes>", FUNC_RUN,
                "<LOC _No>")
        end

        function EVENT_Click()
            for i, v in scrollGroup.controlList do
                v.HandleEvent = function(self, event)
                    if event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
                        if not IsHost and not self.ui then
                            -- You can't enable Game Mod if you not the Host
                        else
                            if not self.modInfo.selectable then
                                self.type:SetColor('B9BFB9')
                                self.type:SetText('This mod cannot be selected')
                                self.bg:SetTexture('/textures/ui/common/MODS/enable_not.dds')
                            elseif not availableMods[self.modInfo.uid] and not self.ui then
                                -- If other player not have the mod
                                self.type:SetColor('B9BFB9')
                                self.type:SetText('One or more players do not have this mod')
                                self.bg:SetTexture('/textures/ui/common/MODS/enable_not.dds')
                            else
                                if self.actived then
                                    UNActiveMod(self)
                                else
                                    if self.modInfo.exclusive then
                                        ActiveExclusifMod(self)
                                    else
                                        if exclusiveMod then 
                                            ActiveModAndRemoveExclusifMod(self)
                                        else
                                            ActiveMod(self)
                                        end
                                    end
                                end
                                PlaySound(Sound({Cue = "UI_Mod_Select", Bank = "Interface",}))
                                text1:SetText(count_mod_SIM_actived()..' Game Mods and '..count_mod_UI_actived()..' UI Mods actived')
                            end
                        end
                    elseif event.Type == 'MouseEnter' then
                        if self.actived then
                            self.bg0:SetTexture('/textures/ui/common/MODS/line_black.dds')
                        else
                            self.bg0:SetTexture('/textures/ui/common/MODS/line_blank.dds')
                        end
                    elseif event.Type == 'MouseExit' then
                        self.bg0:SetTexture('/textures/none.dds')
                    end
                end
            end
        end
        EVENT_Click()
        
        scrollGroup.top = 1
        scrollGroup:CalcVisible()
    end
    Refresh_Mod_List(false, true, true, IsHost, modstatus, cbox_Act2:IsChecked())

    scrollGroup.HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' then
            local lines = 1
            if event.WheelRotation > 0 then
                lines = -1
            end
            self:ScrollLines(nil, lines)
        end
    end

    GUI_OPEN = true
end

function CreateListElementtt(parent, modInfo, Pos, little)
    local group = Group(parent)
        if little then
            numElementsPerPage = 22
            group.Height:Set(20)
        else
            numElementsPerPage = 6
            group.Height:Set(function() return parent.Height() / numElementsPerPage  end)
        end
        group.Width:Set(parent.Width)
        LayoutHelpers.AtLeftTopIn(group, parent, 0, group.Height()*(Pos-1))
    
    group.pos = Pos
    group.modInfo = modInfo
    group.actived = false
    
    group.bg = Bitmap(group, '/textures/none.dds')
        group.bg.Height:Set(group.Height())
        group.bg.Width:Set(group.Width())
        LayoutHelpers.AtLeftTopIn(group.bg, group, 0, 0)
    
    group.bg0 = Bitmap(group, '/textures/none.dds')
        group.bg0.Height:Set(group.Height())
        group.bg0.Width:Set(group.Width())
        LayoutHelpers.AtLeftTopIn(group.bg0, group, 0, 0)
    
    group.icon = Bitmap(group, modInfo.icon)
        if little then
            group.icon.Height:Set(20)
            group.icon.Width:Set(20)
            LayoutHelpers.AtLeftTopIn(group.icon, group, 0, 0)
        else
            group.icon.Height:Set(56)
            group.icon.Width:Set(56)
            LayoutHelpers.AtLeftTopIn(group.icon, group, 10, 10)
        end
    
    group.name = UIUtil.CreateText(group, modInfo.name, 14, UIUtil.bodyFont)
        group.name:SetColor('B9BFB9')
        if little then
            LayoutHelpers.AtLeftTopIn(group.name, group, 30, 1)
        else
            LayoutHelpers.AtLeftTopIn(group.name, group, 80, 10)
        end
        group.name:SetDropShadow(true)
    
    if not little then
        group.desc = MultiLineText(group, UIUtil.bodyFont, 12, 'B9BFB9')
            LayoutHelpers.AtLeftTopIn(group.desc, group, 80, 30)
            group.desc.Height:Set(40)
            group.desc.Width:Set(group.Width()-86)
            group.desc:SetText(modInfo.description)
    end
    
    group.type = UIUtil.CreateText(group, '', 10, 'Arial Narrow Bold')
        group.type:SetColor('B9BFB9')
        if modInfo.ui_only then
            group.type:SetText('UI Mod')
            group.type:SetFont('Arial Black', 11)
            group.ui = true
        else
            group.type:SetText('Game Mod')
            group.type:SetFont('Arial Black', 11)
            group.ui = false
        end
        if little then
            LayoutHelpers.AtRightTopIn(group.type, group, 12, 2)
        else
            LayoutHelpers.AtRightTopIn(group.type, group, 12, 4)
        end
    if little then
        Tooltip.AddControlTooltip(group.bg, {text=modInfo.name, body=modInfo.description})
    end
    
    return group
end