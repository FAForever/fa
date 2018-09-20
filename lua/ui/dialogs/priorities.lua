local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local Button = import('/lua/maui/button.lua').Button
local Prefs = import('/lua/user/prefs.lua')
local Dragger = import('/lua/maui/dragger.lua').Dragger
local ItemList = import('/lua/maui/itemlist.lua').ItemList
local Combo = import('/lua/ui/controls/combo.lua').Combo
local Edit = import('/lua/maui/edit.lua').Edit

local SetWeaponPriorities = import('/lua/keymap/misckeyactions.lua').SetWeaponPriorities
local UpdateHotkeys = import('/lua/keymap/misckeyactions.lua').updatePriData
local Orders = import('/lua/ui/game/orders.lua')

local categoryID ={[1] = 'AIR', [2] = 'ANTIAIR', [3] = 'ANTIMISSILE', [4] = 'ANTINAVY', [5] = 'ANTISUB',
    [6] = 'ARTILLERY', [7] = 'BATTLESHIP', [8] = 'BOMBER', [9] = 'CARRIER', [10] = 'COMMAND',[11] = 'CONSTRUCTION',
    [12] = 'COUNTERINTELLIGENCE',[13] = 'CRUISER',[14] = 'DEFENSE',[15] = 'DESTROYER',[16] = 'DIRECTFIRE',
    [17] = 'ECONOMIC',[18] = 'ENERGYPRODUCTION',[19] = 'ENERGYSTORAGE',[20] = 'ENGINEER',[21] = 'EXPERIMENTAL',
    [22] = 'FACTORY',[23] = 'FRIGATE',[24] = 'GROUNDATTACK',[25] = 'HOVER',[26] = 'INDIRECTFIRE', 
    [27] = 'INTELLIGENCE', [28] = 'LAND', [29] = 'MASSEXTRACTION',[30] = 'MASSPRODUCTION',[31] = 'MASSSTORAGE',
    [32] = 'MOBILE',[33] = 'MOBILESONAR',[34] = 'NAVAL',[35] = 'NUKE',[36] = 'NUKESUB',
    [37] = 'OMNI',[38] = 'RADAR',[39] = 'RECLAIMABLE',[40] = 'SCOUT',[41] = 'SHIELD',[42] = 'SNIPER',
    [43] = 'SONAR',[44] = 'STRATEGIC',[45] = 'STRUCTURE',[46] = 'SUBCOMMANDER',[47] = 'SUBMERSIBLE',
    [48] = 'TECH1',[49] = 'TECH2',[50] = 'TECH3',[51] = 'TRANSPORTATION'}

local mainData
local main

local mainDataDefault = {
    category = {}, 
    sets = {ACU = {10}, Power = {18,45}, PD = {14,16,45}, Engies = {20, 39}, Shields = {41}, EXP = {21}}, 
    defaults = {ACU = true, Power = true, PD = true, Engies = true, Shields = true, EXP = true}, 
    buttonLayout = {[1] = "Default", [2] = "ACU", [3] = "Engies", [4] = "PD", [5] = "Power", [6] = "Shields", [7] = "EXP"},
    buttonLayoutExpand = {},
    hotkeys = {[1] = "ACU", [2] = "Engies", [3] = "PD", [4] = "Power", [5] = "Shields", [6] = "EXP"},
    defCheck = true, 
    }
    
mainData = Prefs.GetFromCurrentProfile("mainPriData") or mainDataDefault 

local function SavePrefs()
    Prefs.SetToCurrentProfile("mainPriData", mainData)
    Prefs.SavePreferences()
    UpdateHotkeys()
    Orders.UpdatePriData()
end

local function ResetPri()
    mainData = table.deepcopy(mainDataDefault)
    Prefs.SetToCurrentProfile("mainPriData", mainData)
    Prefs.SavePreferences()
    UpdateHotkeys()
    Orders.UpdatePriData()
end


function createPrioMain() --prio sets & settings
    if main then
        main:Destroy()
        main = nil
    end
    
    local function updateList()
        main.setList:DeleteAllItems()
        
        local i = 1
    
        for key, val in mainData.sets or {} do
            main.setList:AddItem(key)
            main.setList.table[i] = key
            i = i + 1
        end
    end

    local function updateInfo(name)
        if main.updateCategories then
            main.updateCategories:Destroy()
            main.updateCategories = nil
        end
        
        if main.updateDefaults then
            main.updateDefaults:Destroy()
            main.updateDefaults = nil
        end
        
        main.updateCategories = Bitmap(main, UIUtil.UIFile('/game/ability_brd/chat_brd_m.dds'))
        main.updateCategories.Width:Set(0)
        main.updateCategories.Height:Set(0)
        LayoutHelpers.AtLeftTopIn(main.updateCategories, main, 0, 20)
        
        local line = 0
        
        for key, val in mainData.sets[name] do
            if line == 0 then
                main.updateCategories[key] = UIUtil.CreateText(main.updateCategories, categoryID[val], 14, "Calibri")
                LayoutHelpers.AtLeftTopIn(main.updateCategories[key], main.infoCategories, 30, 20)
                main.updateCategories[key]:SetColor('B59F7B')
                line = line + 1
            else
                main.updateCategories[key] = UIUtil.CreateText(main.updateCategories, categoryID[val], 14, "Calibri")
                LayoutHelpers.AtLeftTopIn(main.updateCategories[key], main.infoCategories, 30 , 20 + (line * 20))
                main.updateCategories[key]:SetColor('B59F7B')
                line = line + 1
            end
        end
        
        if mainData.defaults[name] then
            main.updateDefaults = UIUtil.CreateText(main, "YES", 14, "Calibri")
            LayoutHelpers.AtLeftTopIn(main.updateDefaults, main.infoDefaults, 90, 0)
            main.updateDefaults:SetColor('11A02E')
        else
            main.updateDefaults = UIUtil.CreateText(main, "NO", 14, "Calibri")
            LayoutHelpers.AtLeftTopIn(main.updateDefaults, main.infoDefaults, 90, 0)
            main.updateDefaults:SetColor('B50A19')
        end    
    end        
    
    mainData.category = {}
    
    local width = 800
    local height = 350
    
    main = Bitmap(GetFrame(0))
    main:SetTexture(UIUtil.UIFile('/game/Weapon-priorities/infoBack.dds'))
    main.Depth:Set(10000)
    main.Width:Set(width)
    main.Height:Set(height)
    main:SetAlpha(0.6)
        
    LayoutHelpers.AtCenterIn(main, GetFrame(0), -200)
    
    main.back = Bitmap(main, UIUtil.UIFile('/game/Weapon-priorities/BackMain3.dds'))
    LayoutHelpers.AtLeftTopIn(main.back, main, 0, 0)
    main.back:DisableHitTest()
    
    main.HandleEvent = function(self, event)
        if event.Type == 'ButtonPress' then
            local drag = Dragger()
            local offX = event.MouseX - self.Left()
            local offY = event.MouseY - self.Top()
            
            drag.OnMove = function(dragself, x, y)
                self.Left:Set(x - offX)
                self.Top:Set(y - offY)
                GetCursor():SetTexture(UIUtil.GetCursor('MOVE_WINDOW'))
            end

            drag.OnRelease = function(dragself)    
                GetCursor():Reset()
                drag:Destroy()
            end
            
            PostDragger(self:GetRootFrame(), event.KeyCode, drag)
        end
    end
    
    main.closeButton =  Button(main, 
        UIUtil.UIFile('/game/Weapon-priorities/close1.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/close1.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/close2.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/close2.dds'))
        
    LayoutHelpers.AtLeftTopIn(main.closeButton, main, width - 20, 5) 
        
    main.closeButton.OnClick = function(self, event)
        main:Destroy()
        main = nil
    end
  
    -- Dropdowns
    
    main.dropdown1 = Combo(main, 14, 10, nil, nil)
    main.dropdown1.Width:Set(200)
    LayoutHelpers.AtLeftTopIn(main.dropdown1, main, 550, 100)
    main.dropdown1.OnClick = function(self, index, text, skipUpdate)
        if index == 1 then
            mainData.category[1] = nil
        else    
            mainData.category[1] = index - 1
        end    
    end
    
    main.dropdown1:ClearItems()
    main.dropdown1.itemArray = {}
    main.dropdown1.itemArray[1] = "-"
    
    local index = 2
    
    for key, category in categoryID do
            main.dropdown1.itemArray[index] = category
            index = index + 1
    end   
    main.dropdown1:AddItems(main.dropdown1.itemArray, 1)
    
    
    main.dropdown2 = Combo(main, 14, 10, nil, nil)
    main.dropdown2.Width:Set(200)
    LayoutHelpers.AtLeftTopIn(main.dropdown2, main.dropdown1, 0, 30)
    main.dropdown2.OnClick = function(self, index, text, skipUpdate)
        if index == 1 then
            mainData.category[2] = nil
        else    
            mainData.category[2] = index - 1
        end    
    end

    main.dropdown2:AddItems(main.dropdown1.itemArray, 1)

    main.dropdown3 = Combo(main, 14, 10, nil, nil)
    main.dropdown3.Width:Set(200)
    LayoutHelpers.AtLeftTopIn(main.dropdown3, main.dropdown2, 0, 30)
    main.dropdown3.OnClick = function(self, index, text, skipUpdate)
        if index == 1 then
            mainData.category[3] = nil
        else    
            mainData.category[3] = index - 1
        end    
    end

    main.dropdown3:AddItems(main.dropdown1.itemArray, 1)
    
    
    main.dropdown4 = Combo(main, 14, 10, nil, nil)
    main.dropdown4.Width:Set(200)
    LayoutHelpers.AtLeftTopIn(main.dropdown4, main.dropdown3, 0, 30)
    main.dropdown4.OnClick = function(self, index, text, skipUpdate)
        if index == 1 then
            mainData.category[4] = nil
        else    
            mainData.category[4] = index - 1
        end    
    end

    main.dropdown4:AddItems(main.dropdown1.itemArray, 1)
    
    
    ---"Add" button
    main.savePrioSet = UIUtil.CreateButton(main,
        '/dialogs/toggle_btn/toggle-d_btn_up.dds',
        '/dialogs/toggle_btn/toggle-d_btn_down.dds',
        '/dialogs/toggle_btn/toggle-d_btn_over.dds',
        '/dialogs/toggle_btn/toggle-d_btn_dis.dds',
        'Add', 12)
    main.savePrioSet.label:SetFont(UIUtil.bodyFont, 12)
    LayoutHelpers.AtLeftTopIn(main.savePrioSet, main.dropdown4, 0, 70)
    main.savePrioSet.OnClick = function(self, modifiers)
        if main.nameDialog then return end
        
        main.nameDialog = Bitmap(main, UIUtil.SkinnableFile('/dialogs/dialog_02/panel_bmp.dds'), "Marker Name Dialog")
        LayoutHelpers.AtCenterIn(main.nameDialog, GetFrame(0))
        main.nameDialog.Depth:Set(GetFrame(0):GetTopmostDepth() + 10)

        main.nameDialog.label = UIUtil.CreateText(main.nameDialog, "Name your set  (6 letters max):", 16, UIUtil.buttonFont)
        LayoutHelpers.AtLeftTopIn(main.nameDialog.label, main.nameDialog, 35, 30)

        main.nameDialog.cancelButton = UIUtil.CreateButtonStd(main.nameDialog, '/widgets02/small', "<LOC _CANCEL>", 12)
        LayoutHelpers.AtLeftTopIn(main.nameDialog.cancelButton, main.nameDialog, 480, 110)
        
        main.nameDialog.cancelButton.OnClick = function(self, modifiers)
            main.nameDialog:Destroy()
            main.nameDialog = nil
        end

        main.nameDialog.nameEdit = Edit(main.nameDialog)
        LayoutHelpers.AtLeftTopIn(main.nameDialog.nameEdit, main.nameDialog, 35, 60)
        main.nameDialog.nameEdit.Width:Set(283)
        main.nameDialog.nameEdit.Height:Set(main.nameDialog.nameEdit:GetFontHeight())
        main.nameDialog.nameEdit:ShowBackground(false)
        main.nameDialog.nameEdit:AcquireFocus()
        UIUtil.SetupEditStd(main.nameDialog.nameEdit, UIUtil.fontColor, nil, nil, nil, UIUtil.bodyFont, 16, 30)

        main.nameDialog.okButton = UIUtil.CreateButtonStd(main.nameDialog, '/widgets02/small', "<LOC _OK>", 12)
        LayoutHelpers.AtLeftTopIn(main.nameDialog.okButton, main.nameDialog, 30, 110)
        
        main.nameDialog.okButton.OnClick = function(self, modifiers)
            local newName = main.nameDialog.nameEdit:GetText()
            local IDs = {}
            
            for key, val in mainData.category do
                table.insert(IDs, val)
            end  
            
            if IDs[1] then
                mainData.sets[newName] = IDs
                
                if mainData.defCheck == true then
                    mainData.defaults[newName] = true
                else
                    mainData.defaults[newName] = nil  
                end
                
                updateList()
                createPrioButtonSettings()
                SavePrefs()
            else
                print ("Please select at least 1 category")
            end
            main.nameDialog:Destroy()
            main.nameDialog = nil
        end

        main.nameDialog.nameEdit.OnEnterPressed = function(self, text)
            main.nameDialog.okButton.OnClick()
        end
        
    end
    
    ---Delete----
    main.deleteSet = UIUtil.CreateButton(main,
        '/dialogs/toggle_btn/toggle-d_btn_up.dds',
        '/dialogs/toggle_btn/toggle-d_btn_down.dds',
        '/dialogs/toggle_btn/toggle-d_btn_over.dds',
        '/dialogs/toggle_btn/toggle-d_btn_dis.dds',
        'Delete', 12)
    main.deleteSet.label:SetFont(UIUtil.bodyFont, 12)
    LayoutHelpers.AtLeftTopIn(main.deleteSet, main.savePrioSet, 120, 0)
    main.deleteSet.OnClick = function(self, modifiers)
        local SelcetedSet = main.setList:GetSelection()
        if SelcetedSet ~= -1 then
            local name = main.setList.table[SelcetedSet + 1]
            
            mainData.sets[name] = nil
            mainData.defaults[name] = nil
            
            for key, val in mainData.buttonLayout do
                if val == name then
                    mainData.buttonLayout[key] = nil
                end
            end 
            for key, val in mainData.buttonLayoutExpand do
                if val == name then
                    mainData.buttonLayoutExpand[key] = nil
                end
            end 
            
            updateList()
            SavePrefs()
            createPrioButtonSettings()
        else
            print("No set selected")
        end    
    end
    
    ---RESET----
    main.reset = UIUtil.CreateButton(main,
        '/dialogs/toggle_btn/toggle-d_btn_up.dds',
        '/dialogs/toggle_btn/toggle-d_btn_down.dds',
        '/dialogs/toggle_btn/toggle-d_btn_over.dds',
        '/dialogs/toggle_btn/toggle-d_btn_dis.dds',
        'Reset', 12)
    main.reset.label:SetFont(UIUtil.bodyFont, 12)
    LayoutHelpers.AtLeftTopIn(main.reset, main.savePrioSet, 120, 30)
    main.reset.OnClick = function(self, modifiers)
        if main.resetDialog then return end
        
        main.resetDialog = Bitmap(main, UIUtil.SkinnableFile('/dialogs/dialog_02/panel_bmp.dds'), "Marker Name Dialog")
        LayoutHelpers.AtCenterIn(main.resetDialog, GetFrame(0))
        main.resetDialog.Depth:Set(GetFrame(0):GetTopmostDepth() + 10)

        main.resetDialog.label = UIUtil.CreateText(main.resetDialog, "Reset all settings/presets/buttons to default?", 20, UIUtil.buttonFont)
        LayoutHelpers.AtLeftTopIn(main.resetDialog.label, main.resetDialog, 125, 45)

        main.resetDialog.cancelButton = UIUtil.CreateButtonStd(main.resetDialog, '/widgets02/small', "<LOC _CANCEL>", 12)
        LayoutHelpers.AtLeftTopIn(main.resetDialog.cancelButton, main.resetDialog, 480, 110)
        
        main.resetDialog.cancelButton.OnClick = function(self, modifiers)
            main.resetDialog:Destroy()
            main.resetDialog = nil
        end

        main.resetDialog.okButton = UIUtil.CreateButtonStd(main.resetDialog, '/widgets02/small', "<LOC _OK>", 12)
        LayoutHelpers.AtLeftTopIn(main.resetDialog.okButton, main.resetDialog, 30, 110)
        
        main.resetDialog.okButton.OnClick = function(self, modifiers)  
            main.resetDialog:Destroy()
            main.resetDialog = nil
            
            ResetPri()
            createPrioMain() 
        end       
    end

    -------List-----------
    main.setList = ItemList(main, "setList")
    main.setList:SetFont(UIUtil.bodyFont, 14)
    main.setList:SetColors(UIUtil.fontColor, "00000000", "FF000000",  UIUtil.highlightColor, "ffbcfffe")
    main.setList:ShowMouseoverItem(true)

    main.setList.Depth:Set(function() return main.Depth() + 10 end)

    main.setList.Width:Set(200)
    main.setList.Height:Set(200)
    LayoutHelpers.AtLeftTopIn(main.setList, main, 290, 110)
    
    main.setList:AcquireKeyboardFocus(true)
    
    UIUtil.CreateLobbyVertScrollbar(main.setList, 2, -1, -25)
    
    main.setList.table = {}
    local i = 1
    
    for key, val in mainData.sets or {} do
        main.setList:AddItem(key)
        main.setList.table[i] = key
        i = i + 1
    end
    
    main.setList.OnClick = function(self, index)
        main.setList:SetSelection(index)
        local name = main.setList.table[index + 1] 
        updateInfo(name)
    end
    
    ---Information & other text---
    
    main.infoTitle = UIUtil.CreateText(main, 'Info', 20, UIUtil.bodyFont)
    LayoutHelpers.AtLeftTopIn(main.infoTitle, main, 80, 50)
    main.infoTitle:SetColor('ff99a3b0')

    main.infoCategories = UIUtil.CreateText(main, 'Categories:', 14, UIUtil.bodyFont)
    LayoutHelpers.AtLeftTopIn(main.infoCategories, main, 30, 100)
    main.infoCategories:SetColor('ff99a3b0')
    
    main.infoDefaults = UIUtil.CreateText(main, 'Use defaults:', 14, UIUtil.bodyFont)
    LayoutHelpers.AtLeftTopIn(main.infoDefaults, main.infoCategories, 0, 120)
    main.infoDefaults:SetColor('ff99a3b0')
    
    main.presets = UIUtil.CreateText(main, 'Presets', 20, UIUtil.bodyFont)
    LayoutHelpers.AtLeftTopIn(main.presets, main, 350, 50)
    main.presets:SetColor('ff99a3b0')
    
    main.selectCat = UIUtil.CreateText(main, 'Categories', 20, UIUtil.bodyFont)
    LayoutHelpers.AtLeftTopIn(main.selectCat, main, 600, 50)
    main.selectCat:SetColor('ff99a3b0')
    
    ---CheckBox----
    
    main.CheckBoxDef = UIUtil.CreateCheckbox(main, '/CHECKBOX/')
    main.CheckBoxDef.Height:Set(13)
    main.CheckBoxDef.Width:Set(13)
  
    if mainData.defCheck == true then
        main.CheckBoxDef:SetCheck(true, true)
    else
        main.CheckBoxDef:SetCheck(false, true)
    end
	
    main.CheckBoxDef.OnClick = function(self)
        if(main.CheckBoxDef:IsChecked()) then
            mainData.defCheck = nil
            main.CheckBoxDef:SetCheck(false, true)
        else
            mainData.defCheck = true
            main.CheckBoxDef:SetCheck(true, true)
        end
    end
    
    LayoutHelpers.AtLeftTopIn(main.CheckBoxDef, main.savePrioSet, 2, -25)
    
    main.CheckBoxDef.text = UIUtil.CreateText(main.CheckBoxDef, "Use default priorities", 14, UIUtil.bodyFont)
    
    LayoutHelpers.AtLeftTopIn(main.CheckBoxDef.text, main.CheckBoxDef, 20, -2)
    
    createPrioButtonSettings()
end

function createPrioButtonSettings()
    if main.buttons then
        main.buttons:Destroy()
        main.buttons = nil
    end
    
    if main.hotkeys then
        main.hotkeys:Destroy()
        main.hotkeys = nil
    end                   
    local width = 800
    local height = 250
    
    main.buttons = Bitmap(main, UIUtil.UIFile('/game/Weapon-priorities/infoBack.dds'))
    main.buttons.Width:Set(width)
    main.buttons.Height:Set(height)
    main.buttons:SetAlpha(0.6)
    
    LayoutHelpers.AtLeftTopIn(main.buttons, main, 0, 350)
    
    main.buttons.back = Bitmap(main.buttons, UIUtil.UIFile('/game/Weapon-priorities/buttonsBack2.dds'))
    LayoutHelpers.AtLeftTopIn(main.buttons.back, main.buttons, 0, 0)
    main.buttons.back:DisableHitTest()
    
    main.buttons.but = Checkbox(main.buttons)
    main.buttons.but:SetNewTextures(
        UIUtil.UIFile('/game/Weapon-priorities/ButOn.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/ButOn.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/ButOn.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/ButOn.dds')
        )
    LayoutHelpers.AtLeftTopIn(main.buttons.but, main.buttons, 290, 20)
                                           

    
    main.buttons.hot = Checkbox(main.buttons)
    main.buttons.hot:SetNewTextures(
        UIUtil.UIFile('/game/Weapon-priorities/HotOff.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/HotOff.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/HotOff2.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/HotOff2.dds')
        )
    LayoutHelpers.AtLeftTopIn(main.buttons.hot, main.buttons.but, 100, 4)
    main.buttons.hot.OnCheck = function(control, checked)
        createPrioHotkeys()
    end
    
    local i = 2
    
    while i < 8 do
        main.buttons[i] = Combo(main.buttons, 14, 10, nil, nil)
        main.buttons[i].Width:Set(130)
        LayoutHelpers.AtLeftTopIn(main.buttons[i], main.buttons, 200, 230 - i * 20)
        
        main.buttons[i].Number = i 
        
        main.buttons[i].OnClick = function(self, index, text, skipUpdate)
            if index == 1 then
                mainData.buttonLayout[self.Number] = nil
            else
                mainData.buttonLayout[self.Number] = main.buttons[2].itemArray[index]
            end    
            SavePrefs()
        end
        
        if i == 2 then
            local index = 2
            
            main.buttons[2]:ClearItems()
            main.buttons[2].itemArray = {}
            main.buttons[2].ID = {}
            main.buttons[2].itemArray[1] = "-"
            
            for name, set in mainData.sets do
                main.buttons[2].itemArray[index] = name
                main.buttons[2].ID[name] = index
                index = index + 1
            end 
            
            main.buttons[i]:AddItems(main.buttons[i].itemArray, 1)
            
            if mainData.buttonLayout[i] then
                main.buttons[i]:SetItem(main.buttons[2].ID[mainData.buttonLayout[i]])
            end 
        
        else          
            main.buttons[i]:AddItems(main.buttons[2].itemArray, 1)
            
            if mainData.buttonLayout[i] then
                main.buttons[i]:SetItem(main.buttons[2].ID[mainData.buttonLayout[i]])
            end 
        end    
         
        i = i + 1      
    end
    
    main.buttons.expand = UIUtil.CreateCheckbox(main.buttons, '/CHECKBOX/')
    main.buttons.expand.Height:Set(13)
    main.buttons.expand.Width:Set(13)
    LayoutHelpers.AtLeftTopIn(main.buttons.expand, main.buttons[2], 150, -120)

    if mainData.expand then
        main.buttons.expand:SetCheck(true, true)
    else
        main.buttons.expand:SetCheck(false, true)
    end
	
    main.buttons.expand.OnClick = function(self)
        if(main.buttons.expand:IsChecked()) then
            mainData.expand = nil
            main.buttons.expand:SetCheck(false, true)
        else
            mainData.expand = true
            main.buttons.expand:SetCheck(true, true)
        end
        SavePrefs()
        createPrioButtonSettings()
    end
    
    main.buttons.expandText = UIUtil.CreateText(main.buttons, "More buttons", 14, UIUtil.bodyFont)
    LayoutHelpers.AtLeftTopIn(main.buttons.expandText, main.buttons.expand, 20, -2)
    
    if mainData.expand then
        while i < 15 do
            main.buttons[i] = Combo(main.buttons, 14, 10, nil, nil)
            main.buttons[i].Width:Set(130)
            LayoutHelpers.AtLeftTopIn(main.buttons[i], main.buttons[2], 150, 180 - i * 20)
            
            main.buttons[i].Number = i 
            
            main.buttons[i].OnClick = function(self, index, text, skipUpdate)
                if index == 1 then
                    mainData.buttonLayoutExpand[self.Number] = nil
                else
                    mainData.buttonLayoutExpand[self.Number] = main.buttons[2].itemArray[index]
                end    
                SavePrefs()
            end
                    
            main.buttons[i]:AddItems(main.buttons[2].itemArray, 1)
            
            if mainData.buttonLayoutExpand[i] then
                main.buttons[i]:SetItem(main.buttons[2].ID[mainData.buttonLayoutExpand[i]])
            end 
    
            i = i + 1      
        end    
    end
end

function createPrioHotkeys()

    if main.buttons then
        main.buttons:Destroy()
        main.buttons = nil
    end
    
    if main.hotkeys then
        main.hotkeys:Destroy()
        main.hotkeys = nil
    end
    
    local width = 800
    local height = 250
    
    main.hotkeys = Bitmap(main, UIUtil.UIFile('/game/Weapon-priorities/infoBack.dds'))
    main.hotkeys.Width:Set(width)
    main.hotkeys.Height:Set(height)
    main.hotkeys:SetAlpha(0.6)
    
    LayoutHelpers.AtLeftTopIn(main.hotkeys, main, 0, 350)
    
    main.hotkeys.back = Bitmap(main.hotkeys, UIUtil.UIFile('/game/Weapon-priorities/hotkeysBack.dds'))
    LayoutHelpers.AtLeftTopIn(main.hotkeys.back, main.hotkeys, 0, 0)
    main.hotkeys.back:DisableHitTest()

    
    main.hotkeys.but = Checkbox(main.hotkeys)
    main.hotkeys.but:SetNewTextures(
        UIUtil.UIFile('/game/Weapon-priorities/ButOff.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/ButOff.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/ButOff2.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/ButOff2.dds')
        )
    LayoutHelpers.AtLeftTopIn(main.hotkeys.but, main.hotkeys, 290, 23)
    main.hotkeys.but.OnCheck = function(control, checked)
        createPrioButtonSettings()
    end
    
    
    main.hotkeys.hot = Checkbox(main.hotkeys)
    main.hotkeys.hot:SetNewTextures(
        UIUtil.UIFile('/game/Weapon-priorities/HotOn.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/HotOn.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/HotOn.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/HotOn.dds')
        )
    LayoutHelpers.AtLeftTopIn(main.hotkeys.hot, main.hotkeys.but, 100, -2)
    
    
    local i = 2
    
    while i < 7 do
        main.hotkeys[i] = Combo(main.hotkeys, 14, 10, nil, nil)
        main.hotkeys[i].Width:Set(130)
        LayoutHelpers.AtLeftTopIn(main.hotkeys[i], main.hotkeys, 230, 40 + i * 25)
        
        main.hotkeys[i].Number = i - 1 
        
        main.hotkeys[i].OnClick = function(self, index, text, skipUpdate)
            if index == 1 then
                mainData.hotkeys[self.Number] = nil
            else
                mainData.hotkeys[self.Number] = main.hotkeys[2].itemArray[index]
            end    
            SavePrefs()
        end
        
        if i == 2 then
            local index = 2
            
            main.hotkeys[2]:ClearItems()
            main.hotkeys[2].itemArray = {}
            main.hotkeys[2].ID = {}
            main.hotkeys[2].itemArray[1] = "-"
            
            for name, set in mainData.sets do
                main.hotkeys[2].itemArray[index] = name
                main.hotkeys[2].ID[name] = index
                index = index + 1
            end 
            
            main.hotkeys[i]:AddItems(main.hotkeys[i].itemArray, 1)
            
            if mainData.hotkeys[i - 1] and main.hotkeys[2].ID[mainData.hotkeys[i - 1]] then
                main.hotkeys[i]:SetItem(main.hotkeys[2].ID[mainData.hotkeys[i - 1]])
            end 
        
        else          
            main.hotkeys[i]:AddItems(main.hotkeys[2].itemArray, 1)
            
            if mainData.hotkeys[i - 1] and main.hotkeys[2].ID[mainData.hotkeys[i - 1]] then
                main.hotkeys[i]:SetItem(main.hotkeys[2].ID[mainData.hotkeys[i - 1]])
            end 
        end

        main.hotkeys[i].text = UIUtil.CreateText(main.hotkeys[i], 'Custom'..(i - 1)..'     =', 14, UIUtil.bodyFont)
        LayoutHelpers.AtLeftTopIn(main.hotkeys[i].text, main.hotkeys[i], -100, 0)
        main.hotkeys[i].text:SetColor('E0C498')
        main.hotkeys[i].text:DisableHitTest()
         
        i = i + 1      
    end
    
    
    while i < 12 do
        main.hotkeys[i] = Combo(main.hotkeys, 14, 10, nil, nil)
        main.hotkeys[i].Width:Set(130)
        LayoutHelpers.AtLeftTopIn(main.hotkeys[i], main.hotkeys[2], 300, -175 + i * 25)
        
        main.hotkeys[i].Number = i - 1
        
        main.hotkeys[i].OnClick = function(self, index, text, skipUpdate)
            if index == 1 then
                mainData.hotkeys[self.Number] = nil
            else
                mainData.hotkeys[self.Number] = main.hotkeys[2].itemArray[index]
            end    
            SavePrefs()
        end
                
        main.hotkeys[i]:AddItems(main.hotkeys[2].itemArray, 1)
        
        if mainData.hotkeys[i - 1] and main.hotkeys[2].ID[mainData.hotkeys[i - 1]] then
            main.hotkeys[i]:SetItem(main.hotkeys[2].ID[mainData.hotkeys[i - 1]])
        end 
        
        if i < 11 then
            main.hotkeys[i].text = UIUtil.CreateText(main.hotkeys[i], 'Custom'..(i - 1)..'     =', 14, UIUtil.bodyFont)
        else
            main.hotkeys[i].text = UIUtil.CreateText(main.hotkeys[i], 'Custom'..(i - 1)..'   =', 14, UIUtil.bodyFont)
        end
        
        LayoutHelpers.AtLeftTopIn(main.hotkeys[i].text, main.hotkeys[i], -100, 0)
        main.hotkeys[i].text:SetColor('E0C498')
        main.hotkeys[i].text:DisableHitTest()
          
        i = i + 1      
    end
end