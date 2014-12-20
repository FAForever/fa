#*****************************************************************************
#* File: lua/modules/ui/game/construction.lua
#* Author: Chris Blackwell / Ted Snook
#* Summary: Construction management UI
#*
#* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#*****************************************************************************

local UIUtil = import('/lua/ui/uiutil.lua')
local DiskGetFileInfo = UIUtil.DiskGetFileInfo
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local SpecialGrid = import('/lua/ui/controls/specialgrid.lua').SpecialGrid
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local Button = import('/lua/maui/button.lua').Button
local Edit = import('/lua/maui/edit.lua').Edit
local StatusBar = import('/lua/maui/statusbar.lua').StatusBar
local GameCommon = import('/lua/ui/game/gamecommon.lua')
local GameMain = import('/lua/ui/game/gamemain.lua')
local RadioGroup = import('/lua/maui/mauiutil.lua').RadioGroup
local Tooltip = import('/lua/ui/game/tooltip.lua')
local TooltipInfo = import('/lua/ui/help/tooltips.lua').Tooltips
local Prefs = import('/lua/user/prefs.lua')
local EnhanceCommon = import('/lua/enhancementcommon.lua')
local Templates = import('/lua/ui/game/build_templates.lua')
local BuildMode = import('/lua/ui/game/buildmode.lua')
local UnitViewDetail = import('/lua/ui/game/unitviewDetail.lua')
local options = Prefs.GetFromCurrentProfile('options')
local Effect = import('/lua/maui/effecthelpers.lua')
local TemplatesFactory = import('/modules/templates_factory.lua')
local straticonsfile = import('/modules/straticons.lua')

local unitGridPages = {
    RULEUTL_Basic = {Order = 0, Label = "<LOC CONSTRUCT_0000>T1"},
    RULEUTL_Advanced = {Order = 1, Label = "<LOC CONSTRUCT_0001>T2"},
    RULEUTL_Secret = {Order = 2, Label = "<LOC CONSTRUCT_0002>T3"},
    RULEUTL_Experimental = {Order = 3, Label = "<LOC CONSTRUCT_0003>Exp"},
    RULEUTL_Munition = {Order = 4, Label = "<LOC CONSTRUCT_0004>Munition"},   -- note that this doesn't exist yet
}

local prevBuildables = false
local prevSelection = false
local prevBuildCategories = false

local allFactories = nil

if options.gui_templates_factory != 0 then
    allFactories = false
end

local dragging = false
local index = nil           --index of the item in the queue currently being dragged
local originalIndex = false --original index of selected item (so that UpdateBuildQueue knows where to modify it from)
local oldQueue = {}
local modifiedQueue = {}
local updateQueue = true    --if false then queue won't update in the ui
local modified = false      --if false then buttonrelease will increase buildcount in queue
local dragLock = false      --to disable quick successive drags, which doubles the units in the queue

if options.gui_draggable_queue != 0 then
    --add gameparent handleevent for if the drag ends outside the queue window
    local gameParent = import('gamemain.lua').GetGameParent()
    local oldGameParentHandleEvent = gameParent.HandleEvent
    gameParent.HandleEvent = function(self, event)
        if event.Type == 'ButtonRelease' then
            import('/lua/ui/game/construction.lua').ButtonReleaseCallback()
        end
        oldGameParentHandleEvent(self, event)
    end
end

local cutA = 0
local cutB = 0
if options.gui_visible_template_names != 0 then
    if options.gui_template_name_cutoff != nil then
        cutA = options.gui_template_name_cutoff
        cutB = options.gui_template_name_cutoff
    end
    cutA = cutA + 1
    cutB = cutB + 7
end


-- these are external controls used for positioning, so don't add them to our local control table
controlClusterGroup = false
mfdControl = false
ordersControl = false

local capturingKeys = false
local layoutVar = false
local DisplayData = {}
local sortedOptions = {}
local newTechUnits = {}
local currentCommandQueue = false
local previousTabSet = nil
local previousTabSize = nil
local activeTab = nil

local showBuildIcons = false

controls = {
    minBG = false,
    maxBG = false,
    midBG = false,
    tabs = {},
}

local constructionTabs = {'t1','t2','t3','t4','templates'}
local nestedTabKey = {
    t1 = 'construction',
    t2 = 'construction',
    t3 = 'construction',
    t4 = 'construction',
}

local enhancementTooltips = {
    LCH = 'construction_tab_enhancment_left',
    RCH = 'construction_tab_enhancment_right',
    Back = 'construction_tab_enhancment_back',
}

local whatIfBuilder = nil
local whatIfBlueprintID = nil
local selectedwhatIfBuilder = nil
local selectedwhatIfBlueprintID = nil


--
-- Workaround for an apparent engine bug that appeared when engymod was deployed (by Rienzilla)
--
-- When we queue a t2 and t3 support factory (or, any upgrade, in which the upgrades
-- are not defined by the UpgradesTo and UpgradesFrom blueprint field, but by the
-- UpgradesFromBase field), and then cancel the t3 factory, the call to DecreaseBuildCountInQueue
-- will not only remove all t3 units queued, but also all t2 units, including the factory
--
-- Now if the factory was already in the process of being built when that happens, the
-- game crashes as soon as it finishes a unit that is not in its queue.
--
-- So, we override DecreaseBuildCountInQueue, and make t3 support factories uncancellable.
--
-- TODO: make the factory cancelable, but re-add the rest of the queue once the engine has removed it

local oldDecreaseBuildCountInQueue = DecreaseBuildCountInQueue
function DecreaseBuildCountInQueue(unitIndex, count)

   --   LOG("Called DecreaseBuildCountInQueue hook")

   -- FIXME: maybe add some sanity checking?
   local unitStack = currentCommandQueue[unitIndex]
   local blueprint = __blueprints[unitStack.id]

   local tech3 = false
   local supportfactory = false

   if blueprint.Categories then
       for i,v in ipairs(blueprint.Categories) do
          if v == 'SUPPORTFACTORY' then
    	 supportfactory = true
          elseif v == 'TECH3' then
    	 tech3 = true
          end
          if tech3 and supportfactory then break end
       end
   end

   if not (tech3 and supportfactory) then
      --LOG("DecreaseBuildCountInQueue: calling super()")
      oldDecreaseBuildCountInQueue(unitIndex, count)
   else
      LOG("Not canceling t3 support factory")
   end
end

function CreateTab(parent, id, onCheckFunc)
    local btn = Checkbox(parent)
    btn.Depth:Set(function() return parent.Depth() + 10 end)

    btn.disabledGroup = Group(parent)
    btn.disabledGroup.Depth:Set(function() return btn.Depth() + 1 end)

    btn.HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Tab_Rollover_02'}))
        elseif event.Type == 'ButtonPress' then
            PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Tab_Click_02'}))
        end
        Checkbox.HandleEvent(self, event)
    end

    # Do this to prevent errors if the tab is created and destroyed in the same frame
    # Happens when people double click super fast to select units
    btn.OnDestroy = function(self)
        btn.disabledGroup.Depth:Set(1)
    end
    if onCheckFunc then
        btn.OnCheck = onCheckFunc
    end

    btn.OnClick = function(self)
        if self._checkState != 'checked' then
            self:ToggleCheck()
        end
    end

    btn:UseAlphaHitTest(true)
    return btn
end

function CreateUI()
    controls.constructionGroup = Group(controlClusterGroup)
    controls.minBG = Bitmap(controls.constructionGroup)
    controls.maxBG = Bitmap(controls.constructionGroup)
    controls.midBG1 = Bitmap(controls.constructionGroup)
    controls.midBG2 = Bitmap(controls.constructionGroup)
    controls.midBG3 = Bitmap(controls.constructionGroup)
    controls.choices = SpecialGrid(controls.constructionGroup, false)
    controls.choicesBGMin = Bitmap(controls.constructionGroup)
    controls.choicesBGMid = Bitmap(controls.constructionGroup)
    controls.choicesBGMax = Bitmap(controls.constructionGroup)
    controls.scrollMin = Button(controls.choices)
    controls.scrollMax = Button(controls.choices)
    controls.scrollMinIcon = Button(controls.choices)
    controls.scrollMaxIcon = Button(controls.choices)
    controls.pageMin = Button(controls.choices)
    controls.pageMax = Button(controls.choices)
    controls.pageMinIcon = Button(controls.choices)
    controls.pageMaxIcon = Button(controls.choices)
    controls.secondaryChoices = SpecialGrid(controls.constructionGroup, false)
    controls.secondaryChoicesBGMin = Bitmap(controls.constructionGroup)
    controls.secondaryChoicesBGMid = Bitmap(controls.constructionGroup)
    controls.secondaryChoicesBGMax = Bitmap(controls.constructionGroup)
    controls.secondaryScrollMin = Button(controls.secondaryChoices)
    controls.secondaryScrollMax = Button(controls.secondaryChoices)
    controls.secondaryScrollMinIcon = Button(controls.secondaryChoices)
    controls.secondaryScrollMaxIcon = Button(controls.secondaryChoices)
    controls.secondaryPageMin = Button(controls.secondaryChoices)
    controls.secondaryPageMax = Button(controls.secondaryChoices)
    controls.secondaryPageMinIcon = Button(controls.secondaryChoices)
    controls.secondaryPageMaxIcon = Button(controls.secondaryChoices)
    controls.leftBracketMin = Bitmap(controls.constructionGroup)
    controls.leftBracketMax = Bitmap(controls.constructionGroup)
    controls.leftBracketMid = Bitmap(controls.constructionGroup)
    controls.rightBracketMin = Bitmap(controls.constructionGroup)
    controls.rightBracketMax = Bitmap(controls.constructionGroup)
    controls.rightBracketMid = Bitmap(controls.constructionGroup)
    controls.extraBtn1 = Checkbox(controls.minBG)
    controls.extraBtn1.icon = Bitmap(controls.extraBtn1)
    controls.extraBtn1.icon.OnTexture = UIUtil.UIFile('/game/construct-sm_btn/pause_on.dds')
    controls.extraBtn1.icon.OffTexture = UIUtil.UIFile('/game/construct-sm_btn/pause_off.dds')
    LayoutHelpers.AtCenterIn(controls.extraBtn1.icon, controls.extraBtn1)
    controls.extraBtn1.icon:DisableHitTest()
    controls.extraBtn1.OnDisable = function(self)
        if controls.extraBtn1.icon then
            controls.extraBtn1.icon:SetTexture(controls.extraBtn1.icon.OffTexture)
        end
        Checkbox.OnDisable(self)
    end
    controls.extraBtn1.OnEnable = function(self)
        controls.extraBtn1.icon:Show()
        if controls.extraBtn1.icon then
            controls.extraBtn1.icon:SetTexture(controls.extraBtn1.icon.OnTexture)
        end
        Checkbox.OnEnable(self)
    end
    controls.extraBtn1:UseAlphaHitTest(true)
    controls.extraBtn2 = Checkbox(controls.minBG)
    controls.extraBtn2.icon = Bitmap(controls.extraBtn2)
    controls.extraBtn2.icon.OnTexture = UIUtil.UIFile('/game/construct-sm_btn/pause_on.dds')
    controls.extraBtn2.icon.OffTexture = UIUtil.UIFile('/game/construct-sm_btn/pause_off.dds')
    LayoutHelpers.AtCenterIn(controls.extraBtn2.icon, controls.extraBtn2)
    controls.extraBtn2.icon:DisableHitTest()
    controls.extraBtn2.OnDisable = function(self)
        if controls.extraBtn2.icon then
            controls.extraBtn2.icon:SetTexture(controls.extraBtn2.icon.OffTexture)
        end
        Checkbox.OnDisable(self)
    end
    controls.extraBtn2.OnEnable = function(self)
        controls.extraBtn2.icon:Show()
        controls.extraBtn2.icon:SetTexture(controls.extraBtn2.icon.OnTexture)
        Checkbox.OnEnable(self)
    end
    controls.extraBtn2:UseAlphaHitTest(true)
    controls.secondaryProgress = StatusBar(controls.secondaryChoices, 0, 1, false, false,
        UIUtil.UIFile('/game/unit-over/health-bars-back-1_bmp.dds'),
        UIUtil.UIFile('/game/unit-over/bar01_bmp.dds'),
        true, "Unit RO Health Status Bar")

    controls.constructionTab = CreateTab(controls.constructionGroup, nil, OnTabCheck)
    controls.constructionTab.ID = 'construction'
    Tooltip.AddCheckboxTooltip(controls.constructionTab, 'construction_tab_construction')
    controls.selectionTab = CreateTab(controls.constructionGroup, nil, OnTabCheck)
    controls.selectionTab.ID = 'selection'
    Tooltip.AddCheckboxTooltip(controls.selectionTab, 'construction_tab_attached')
    controls.enhancementTab = CreateTab(controls.constructionGroup, nil, OnTabCheck)
    controls.enhancementTab.ID = 'enhancement'
    Tooltip.AddCheckboxTooltip(controls.enhancementTab, 'construction_tab_enhancement')
end

function OnTabCheck(self, checked)
    if self.ID == 'construction' then
        controls.selectionTab:SetCheck(false, true)
        controls.enhancementTab:SetCheck(false, true)
        SetSecondaryDisplay('buildQueue')
    elseif self.ID == 'selection' then
        controls.constructionTab:SetCheck(false, true)
        controls.enhancementTab:SetCheck(false, true)
        controls.choices:Refresh(FormatData(sortedOptions.selection, 'selection'))
        SetSecondaryDisplay('attached')
    elseif self.ID == 'enhancement' then
        controls.selectionTab:SetCheck(false, true)
        controls.constructionTab:SetCheck(false, true)
        SetSecondaryDisplay('buildQueue')
    end
    CreateTabs(self.ID)
end

function OnNestedTabCheck(self, checked)
    activeTab = self
    for _, tab in controls.tabs do
        if tab != self then
            tab:SetCheck(false, true)
        end
    end
    controls.choices:Refresh(FormatData(sortedOptions[self.ID], nestedTabKey[self.ID] or self.ID))
    SetSecondaryDisplay('buildQueue')
end

function CreateTabs(type)
    local defaultTabOrder = {}
    local desiredTabs = 0
    -- construction tab, this is called before fac templates have been added
    if type == 'construction' and allFactories and options.gui_templates_factory != 0 then
        -- nil value would cause refresh issues if templates tab is currently selected
        sortedOptions.templates = {}

        -- prevent tab autoselection when in templates tab,
        -- normally triggered when number of active tabs has changed (fac upgrade added/removed from queue)
        local templatesTab = GetTabByID('templates')
        if templatesTab and templatesTab:IsChecked() then
            local numActive = 0
            for _, tab in controls.tabs do
                if sortedOptions[tab.ID] and table.getn(sortedOptions[tab.ID]) > 0 then
                    numActive = numActive + 1
                end
            end
            previousTabSize = numActive
        end
    end
    if type == 'construction' then
        for index, tab in constructionTabs do
            local i = index
            if not controls.tabs[i] then
                controls.tabs[i] = CreateTab(controls.constructionGroup, tab, OnNestedTabCheck)
            end
            controls.tabs[i].ID = tab
            controls.tabs[i].OnRolloverEvent = function(self, event)
            end
            Tooltip.AddControlTooltip(controls.tabs[i], 'construction_tab_'..tab)
            Tooltip.AddControlTooltip(controls.tabs[i].disabledGroup, 'construction_tab_'..tab..'_dis')
        end
        desiredTabs = table.getsize(constructionTabs)
        defaultTabOrder = {t3=1, t2=2, t1=3}
    elseif type == 'enhancement' then
        local selection = sortedOptions.selection
        local enhancements = selection[1]:GetBlueprint().Enhancements
        local enhCommon = import('/lua/enhancementcommon.lua')
        local enhancementPrefixes = {Back = 'b-', LCH = 'la-', RCH = 'ra-'}
        local newTabs = {}
        if enhancements.Slots then
            local tabIndex = 1
            for slotName, slotInfo in enhancements.Slots do
                if not controls.tabs[tabIndex] then
                    controls.tabs[tabIndex] = CreateTab(controls.constructionGroup, nil, OnNestedTabCheck)
                end
                controls.tabs[tabIndex].tooltipKey = enhancementTooltips[slotName]
                controls.tabs[tabIndex].OnRolloverEvent = function(self, event)
                    if event == 'enter' then
                        local existing = enhCommon.GetEnhancements(selection[1]:GetEntityId())
                        if existing[slotName] then
                            local enhancement = enhancements[existing[slotName]]
                            local icon = enhancements[existing[slotName]].Icon
                            local bpID = selection[1]:GetBlueprint().BlueprintId
                            local enhName = existing[slotName]
                            local texture = "/textures/ui/common"..GetEnhancementPrefix(bpID, enhancementPrefixes[slotName]..icon)
                            UnitViewDetail.ShowEnhancement(enhancement, bpID, icon, texture, sortedOptions.selection[1])
                        end
                    elseif event == 'exit' then
                        if existing[slotName] then
                            UnitViewDetail.Hide()
                        end
                    end
                end
                Tooltip.AddControlTooltip(controls.tabs[tabIndex], enhancementTooltips[slotName])
                controls.tabs[tabIndex].ID = slotName
                newTabs[tabIndex] = controls.tabs[tabIndex]
                tabIndex = tabIndex + 1
                sortedOptions[slotName] = {}
                for enhName, enhTable in enhancements do
                    if enhTable.Slot == slotName then
                        enhTable.ID = enhName
                        enhTable.UnitID = selection[1]:GetBlueprint().BlueprintId
                        table.insert(sortedOptions[slotName], enhTable)
                    end
                end
            end
            desiredTabs = table.getsize(enhancements.Slots)
        end
        defaultTabOrder = {Back=1, LCH=2, RCH=3}
    end
    while table.getsize(controls.tabs) > desiredTabs do
        controls.tabs[table.getsize(controls.tabs)]:Destroy()
        controls.tabs[table.getsize(controls.tabs)] = nil
    end
    import(UIUtil.GetLayoutFilename('construction')).LayoutTabs(controls)
    local defaultTab = false
    local numActive = 0
    for _, tab in controls.tabs do
        if sortedOptions[tab.ID] and table.getn(sortedOptions[tab.ID]) > 0 then
            tab:Enable()
            numActive = numActive + 1
            if defaultTabOrder[tab.ID] then
                if not defaultTab or defaultTabOrder[tab.ID] < defaultTabOrder[defaultTab.ID] then
                    defaultTab = tab
                end
            end
        else
            tab:Disable()
        end
    end
    if previousTabSet != type or previousTabSize != numActive then
        if defaultTab then
            defaultTab:SetCheck(true)
        end
        previousTabSet = type
        previousTabSize = numActive
    elseif activeTab then
        activeTab:SetCheck(true)
    end
end

function GetBackgroundTextures(unitID)
    local bp = __blueprints[unitID]
    local validIcons = {land = true, air = true, sea = true, amph = true}
    if validIcons[bp.General.Icon] then
        return UIUtil.UIFile('/icons/units/'..bp.General.Icon..'_up.dds'),
            UIUtil.UIFile('/icons/units/'..bp.General.Icon..'_down.dds'),
            UIUtil.UIFile('/icons/units/'..bp.General.Icon..'_over.dds'),
            UIUtil.UIFile('/icons/units/'..bp.General.Icon..'_up.dds')
    else
        return UIUtil.UIFile('/icons/units/land_up.dds'),
            UIUtil.UIFile('/icons/units/land_down.dds'),
            UIUtil.UIFile('/icons/units/land_over.dds'),
            UIUtil.UIFile('/icons/units/land_up.dds')
    end
end

function GetEnhancementPrefix(unitID, iconID)
    local prefix = ''
    if string.sub(unitID, 2, 2) == 'a' then
        prefix = '/game/aeon-enhancements/'..iconID
    elseif string.sub(unitID, 2, 2) == 'e' then
        prefix = '/game/uef-enhancements/'..iconID
    elseif string.sub(unitID, 2, 2) == 'r' then
        prefix = '/game/cybran-enhancements/'..iconID
    elseif string.sub(unitID, 2, 2) == 's' then
        prefix = '/game/seraphim-enhancements/'..iconID
    end
    return prefix
end

function GetEnhancementTextures(unitID, iconID)
    local prefix = GetEnhancementPrefix(unitID, iconID)
    return UIUtil.UIFile(prefix..'_btn_up.dds'),
        UIUtil.UIFile(prefix..'_btn_down.dds'),
        UIUtil.UIFile(prefix..'_btn_over.dds'),
        UIUtil.UIFile(prefix..'_btn_up.dds'),
        UIUtil.UIFile(prefix..'_btn_sel.dds')
end

local UPPER_GLOW_THRESHHOLD = .5
local LOWER_GLOW_THRESHHOLD = .1
local GLOW_SPEED = 2

function CommonLogic()
    controls.choices:SetupScrollControls(controls.scrollMin, controls.scrollMax, controls.pageMin, controls.pageMax)
    controls.secondaryChoices:SetupScrollControls(controls.secondaryScrollMin, controls.secondaryScrollMax, controls.secondaryPageMin, controls.secondaryPageMax)

    controls.secondaryProgress:SetNeedsFrameUpdate(true)
    controls.secondaryProgress.OnFrame = function(self, delta)
        if sortedOptions.selection[1] and not sortedOptions.selection[1]:IsDead() and sortedOptions.selection[1]:GetWorkProgress() then
            controls.secondaryProgress:SetValue(sortedOptions.selection[1]:GetWorkProgress())
        end
        if controls.secondaryChoices.top == 1 and not controls.selectionTab:IsChecked() and not controls.constructionGroup:IsHidden() then
            self:SetAlpha(1, true)
        else
            self:SetAlpha(0, true)
        end
    end

    controls.secondaryChoices.SetControlToType = function(control, type)
        local function SetIconTextures(control)
            if DiskGetFileInfo(UIUtil.UIFile('/icons/units/'..control.Data.id..'_icon.dds')) then
                control.Icon:SetTexture(UIUtil.UIFile('/icons/units/'..control.Data.id..'_icon.dds'))
            else
                control.Icon:SetTexture(UIUtil.UIFile('/icons/units/default_icon.dds'))
            end
            if __blueprints[control.Data.id].StrategicIconName then
                local iconName = __blueprints[control.Data.id].StrategicIconName
                if DiskGetFileInfo('/textures/ui/common/game/strategicicons/'..iconName..'_rest.dds') then
                    control.StratIcon:SetTexture('/textures/ui/common/game/strategicicons/'..iconName..'_rest.dds')
                    control.StratIcon.Height:Set(control.StratIcon.BitmapHeight)
                    control.StratIcon.Width:Set(control.StratIcon.BitmapWidth)
                else
                    control.StratIcon:SetSolidColor('ff00ff00')
                end
            else
                control.StratIcon:SetSolidColor('00000000')
            end
        end

        if type == 'spacer' then
            if controls.secondaryChoices._vertical then
                control.Icon:SetTexture(UIUtil.UIFile('/game/c-q-e-panel/divider_horizontal_bmp.dds'))
                control.Width:Set(48)
                control.Height:Set(20)
            else
                control.Icon:SetTexture(UIUtil.UIFile('/game/c-q-e-panel/divider_bmp.dds'))
                control.Width:Set(20)
                control.Height:Set(48)
            end
            control.Icon.Width:Set(control.Icon.BitmapWidth)
            control.Icon.Height:Set(control.Icon.BitmapHeight)
            control.Count:SetText('')
            control:Disable()
            control.StratIcon:SetSolidColor('00000000')
            control:SetSolidColor('00000000')
#            control.ConsBar:SetAlpha(0, true)
            control.BuildKey = nil
        elseif type == 'queuestack' or type == 'attachedunit' then
            SetIconTextures(control)
            local up, down, over, dis = GetBackgroundTextures(control.Data.id)
            control:SetNewTextures(up, down, over, dis)
            control:SetUpAltButtons(down,down,down,down)
            control.tooltipID = LOC(__blueprints[control.Data.id].Description) or 'no description'
            control.mAltToggledFlag = false
            control.Height:Set(48)
            control.Width:Set(48)
            control.Icon.Height:Set(48)
            control.Icon.Width:Set(48)
#            if __blueprints[control.Data.id].General.ConstructionBar then
#                control.ConsBar:SetAlpha(1, true)
#            else
#                control.ConsBar:SetAlpha(0, true)
#            end
            control.BuildKey = nil
            if control.Data.count > 1 then
                control.Count:SetText(control.Data.count)
                control.Count:SetColor('ffffffff')
            else
                control.Count:SetText('')
            end
            control.Icon:Show()
            control:Enable()
        end
    end

    controls.secondaryChoices.CreateElement = function()
        local btn = Button(controls.choices)

        btn.Icon = Bitmap(btn)
        btn.Icon:DisableHitTest()
        LayoutHelpers.AtCenterIn(btn.Icon, btn)

        btn.StratIcon = Bitmap(btn.Icon)
        btn.StratIcon:DisableHitTest()
        LayoutHelpers.AtTopIn(btn.StratIcon, btn.Icon, 4)
        LayoutHelpers.AtLeftIn(btn.StratIcon, btn.Icon, 4)

        btn.Count = UIUtil.CreateText(btn.Icon, '', 20, UIUtil.bodyFont)
        btn.Count:SetColor('ffffffff')
        btn.Count:SetDropShadow(true)
        btn.Count:DisableHitTest()
        LayoutHelpers.AtBottomIn(btn.Count, btn, 4)
        LayoutHelpers.AtRightIn(btn.Count, btn, 3)
        btn.Count.Depth:Set(function() return btn.Icon.Depth() + 10 end)

#        btn.ConsBar = Bitmap(btn, UIUtil.UIFile('/icons/units/cons_bar.dds'))
#        btn.ConsBar:DisableHitTest()
#        LayoutHelpers.AtCenterIn(btn.ConsBar, btn)

        btn.Glow = Bitmap(btn)
        btn.Glow:SetTexture(UIUtil.UIFile('/game/units_bmp/glow.dds'))
        btn.Glow:DisableHitTest()
        LayoutHelpers.FillParent(btn.Glow, btn)
        btn.Glow:SetAlpha(0)
        btn.Glow.Incrementing = 1
        btn.Glow.OnFrame = function(glow, elapsedTime)
            local curAlpha = glow:GetAlpha()
            curAlpha = curAlpha + (elapsedTime * glow.Incrementing * GLOW_SPEED)
            if curAlpha > UPPER_GLOW_THRESHHOLD then
                curAlpha = UPPER_GLOW_THRESHHOLD
                glow.Incrementing = -1
            elseif curAlpha < LOWER_GLOW_THRESHHOLD then
                curAlpha = LOWER_GLOW_THRESHHOLD
                glow.Incrementing = 1
            end
            glow:SetAlpha(curAlpha)
        end

        btn.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                PlaySound(Sound({Cue = "UI_MFD_Rollover", Bank = "Interface"}))
                Tooltip.CreateMouseoverDisplay(self, self.tooltipID, nil, false)
            elseif event.Type == 'MouseExit' then
                Tooltip.DestroyMouseoverDisplay()
            end
            return Button.HandleEvent(self, event)
        end

        btn.OnRolloverEvent = OnRolloverHandler
        btn.OnClick = OnClickHandler

        return btn
    end

    controls.choices.CreateElement = function()
        local btn = Button(controls.choices)

        btn.Icon = Bitmap(btn)
        btn.Icon:DisableHitTest()
        LayoutHelpers.AtCenterIn(btn.Icon, btn)

        btn.StratIcon = Bitmap(btn.Icon)
        btn.StratIcon:DisableHitTest()
        LayoutHelpers.AtTopIn(btn.StratIcon, btn.Icon, 4)
        LayoutHelpers.AtLeftIn(btn.StratIcon, btn.Icon, 4)

        btn.Count = UIUtil.CreateText(btn.Icon, '', 20, UIUtil.bodyFont)
        btn.Count:SetColor('ffffffff')
        btn.Count:SetDropShadow(true)
        btn.Count:DisableHitTest()
        LayoutHelpers.AtBottomIn(btn.Count, btn)
        LayoutHelpers.AtRightIn(btn.Count, btn)

#        btn.ConsBar = Bitmap(btn, UIUtil.UIFile('/icons/units/cons_bar.dds'))
#        btn.ConsBar:DisableHitTest()
#        LayoutHelpers.AtCenterIn(btn.ConsBar, btn)

        btn.LowFuel = Bitmap(btn)
        btn.LowFuel:SetSolidColor('ffff0000')
        btn.LowFuel:DisableHitTest()
        LayoutHelpers.FillParent(btn.LowFuel, btn)
        btn.LowFuel:SetAlpha(0)
        btn.LowFuel:DisableHitTest()
        btn.LowFuel.Incrementing = 1

        btn.LowFuelIcon = Bitmap(btn.LowFuel, UIUtil.UIFile('/game/unit_view_icons/fuel.dds'))
        LayoutHelpers.AtLeftIn(btn.LowFuelIcon, btn, 4)
        LayoutHelpers.AtBottomIn(btn.LowFuelIcon, btn, 4)
        btn.LowFuelIcon:DisableHitTest()

        btn.LowFuel.OnFrame = function(glow, elapsedTime)
            local curAlpha = glow:GetAlpha()
            curAlpha = curAlpha + (elapsedTime * glow.Incrementing)
            if curAlpha > .4 then
                curAlpha = .4
                glow.Incrementing = -1
            elseif curAlpha < 0 then
                curAlpha = 0
                glow.Incrementing = 1
            end
            glow:SetAlpha(curAlpha)
        end

        btn.Glow = Bitmap(btn)
        btn.Glow:SetTexture(UIUtil.UIFile('/game/units_bmp/glow.dds'))
        btn.Glow:DisableHitTest()
        LayoutHelpers.FillParent(btn.Glow, btn)
        btn.Glow:SetAlpha(0)
        btn.Glow.Incrementing = 1
        btn.Glow.OnFrame = function(glow, elapsedTime)
            local curAlpha = glow:GetAlpha()
            curAlpha = curAlpha + (elapsedTime * glow.Incrementing * GLOW_SPEED)
            if curAlpha > UPPER_GLOW_THRESHHOLD then
                curAlpha = UPPER_GLOW_THRESHHOLD
                glow.Incrementing = -1
            elseif curAlpha < LOWER_GLOW_THRESHHOLD then
                curAlpha = LOWER_GLOW_THRESHHOLD
                glow.Incrementing = 1
            end
            glow:SetAlpha(curAlpha)
        end


        btn.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                PlaySound(Sound({Cue = "UI_MFD_Rollover", Bank = "Interface"}))
                Tooltip.CreateMouseoverDisplay(self, self.tooltipID, nil, false)
            elseif event.Type == 'MouseExit' then
                Tooltip.DestroyMouseoverDisplay()
            end
            return Button.HandleEvent(self, event)
        end

        btn.OnRolloverEvent = OnRolloverHandler
        btn.OnClick = OnClickHandler

        return btn
    end

    controls.choices.SetControlToType = function(control, type)
        local function SetIconTextures(control, optID)
            local id = optID or control.Data.id
            if DiskGetFileInfo(UIUtil.UIFile('/icons/units/'..id..'_icon.dds')) then
                control.Icon:SetTexture(UIUtil.UIFile('/icons/units/'..id..'_icon.dds'))
            else
                control.Icon:SetTexture(UIUtil.UIFile('/icons/units/default_icon.dds'))
            end
            if __blueprints[id].StrategicIconName then
                local iconName = __blueprints[id].StrategicIconName
                if DiskGetFileInfo('/textures/ui/common/game/strategicicons/'..iconName..'_rest.dds') then
                    control.StratIcon:SetTexture('/textures/ui/common/game/strategicicons/'..iconName..'_rest.dds')
                    control.StratIcon.Height:Set(control.StratIcon.BitmapHeight)
                    control.StratIcon.Width:Set(control.StratIcon.BitmapWidth)
                else
                    control.StratIcon:SetSolidColor('ff00ff00')
                end
            else
                control.StratIcon:SetSolidColor('00000000')
            end
        end

        if type == 'arrow' then
            control.Count:SetText('')
            control:Disable()
            control:SetSolidColor('00000000')
            if controls.choices._vertical then
                control.Icon:SetTexture(UIUtil.UIFile('/game/c-q-e-panel/arrow_vert_bmp.dds'))
                control.Width:Set(48)
                control.Height:Set(20)
            else
                control.Icon:SetTexture(UIUtil.UIFile('/game/c-q-e-panel/arrow_bmp.dds'))
                control.Width:Set(20)
                control.Height:Set(48)
            end
            control.Icon.Depth:Set(function() return control.Depth() + 5 end)
            control.Icon.Height:Set(control.Icon.BitmapHeight)
            control.Icon.Width:Set(30)
            control.StratIcon:SetSolidColor('00000000')
            control.LowFuel:SetAlpha(0, true)
#            control.ConsBar:SetAlpha(0, true)
            control.LowFuel:SetNeedsFrameUpdate(false)
            control.BuildKey = nil
        elseif type == 'spacer' then
            if controls.choices._vertical then
                control.Icon:SetTexture(UIUtil.UIFile('/game/c-q-e-panel/divider_horizontal_bmp.dds'))
                control.Width:Set(48)
                control.Height:Set(20)
            else
                control.Icon:SetTexture(UIUtil.UIFile('/game/c-q-e-panel/divider_bmp.dds'))
                control.Width:Set(20)
                control.Height:Set(48)
            end
            control.Icon.Width:Set(control.Icon.BitmapWidth)
            control.Icon.Height:Set(control.Icon.BitmapHeight)
            control.Count:SetText('')
            control:Disable()
            control.StratIcon:SetSolidColor('00000000')
            control:SetSolidColor('00000000')
            control.LowFuel:SetAlpha(0, true)
#            control.ConsBar:SetAlpha(0, true)
            control.LowFuel:SetNeedsFrameUpdate(false)
            control.BuildKey = nil
        elseif type == 'enhancement' then
            control.Icon:SetSolidColor('00000000')
            control:SetNewTextures(GetEnhancementTextures(control.Data.unitID, control.Data.icon))
            local _,down,over,_,up = GetEnhancementTextures(control.Data.unitID, control.Data.icon)
            control:SetUpAltButtons(up,up,up,up)
            control.tooltipID = LOC(control.Data.enhTable.Name) or 'no description'
            control.mAltToggledFlag = control.Data.Selected
            control.Height:Set(48)
            control.Width:Set(48)
            control.Icon.Height:Set(48)
            control.Icon.Width:Set(48)
            control.Icon.Depth:Set(function() return control.Depth() + 1 end)
            control.Count:SetText('')
            control.StratIcon:SetSolidColor('00000000')
            control.LowFuel:SetAlpha(0, true)
#            control.ConsBar:SetAlpha(0, true)
            control.LowFuel:SetNeedsFrameUpdate(false)
            control.BuildKey = nil
            if control.Data.Disabled then
                control:Disable()
                if not control.Data.Selected then
                    control.Icon:SetSolidColor('aa000000')
                end
            else
                control:Enable()
            end
        elseif type == 'templates' then
            control.mAltToggledFlag = false
            SetIconTextures(control, control.Data.template.icon)
            control:SetNewTextures(GetBackgroundTextures(control.Data.template.icon))
            control.Height:Set(48)
            control.Width:Set(48)
            if control.Data.template.icon then
                control.Icon:SetTexture('/textures/ui/common/icons/units/'..control.Data.template.icon..'_icon.dds')
            else
                control.Icon:SetTexture('/textures/ui/common/icons/units/default_icon.dds')
            end
            control.Icon.Height:Set(48)
            control.Icon.Width:Set(48)
            control.Icon.Depth:Set(function() return control.Depth() + 1 end)
            control.StratIcon:SetSolidColor('00000000')
            control.tooltipID = control.Data.template.name or 'no description'
            control.BuildKey = control.Data.template.key
            if showBuildIcons and control.Data.template.key then
                control.Count:SetText(string.char(control.Data.template.key) or '')
                control.Count:SetColor('ffff9000')
            else
                control.Count:SetText('')
            end
            control.Icon:Show()
            control:Enable()
            control.LowFuel:SetAlpha(0, true)
#            control.ConsBar:SetAlpha(0, true)
            control.LowFuel:SetNeedsFrameUpdate(false)
        elseif type == 'item' then
            SetIconTextures(control)
            control:SetNewTextures(GetBackgroundTextures(control.Data.id))
            local _,down = GetBackgroundTextures(control.Data.id)
            control.tooltipID = LOC(__blueprints[control.Data.id].Description) or 'no description'
            control:SetUpAltButtons(down,down,down,down)
            control.mAltToggledFlag = false
            control.Height:Set(48)
            control.Width:Set(48)
            control.Icon.Height:Set(48)
            control.Icon.Width:Set(48)
            control.Icon.Depth:Set(function() return control.Depth() + 1 end)
            control.BuildKey = nil
            if showBuildIcons then
                local unitBuildKeys = BuildMode.GetUnitKeys(sortedOptions.selection[1]:GetBlueprint().BlueprintId, GetCurrentTechTab())
                control.Count:SetText(unitBuildKeys[control.Data.id] or '')
                control.Count:SetColor('ffff9000')
            else
                control.Count:SetText('')
            end
            control.Icon:Show()
            control:Enable()
            control.LowFuel:SetAlpha(0, true)
#            if __blueprints[control.Data.id].General.ConstructionBar then
#                control.ConsBar:SetAlpha(1, true)
#            else
#                control.ConsBar:SetAlpha(0, true)
#            end
            control.LowFuel:SetNeedsFrameUpdate(false)
            if newTechUnits and table.find(newTechUnits, control.Data.id) then
                table.remove(newTechUnits, table.find(newTechUnits, control.Data.id))
                control.NewInd = Bitmap(control, UIUtil.UIFile('/game/selection/selection_brackets_player_highlighted.dds'))
                control.NewInd.Height:Set(80)
                control.NewInd.Width:Set(80)
                LayoutHelpers.AtCenterIn(control.NewInd, control)
                control.NewInd:DisableHitTest()
                control.NewInd.Incrementing = false
                control.NewInd:SetNeedsFrameUpdate(true)
                control.NewInd.OnFrame = function(ind, delta)
                    local newAlpha = ind:GetAlpha() - delta / 5
                    if newAlpha < 0 then
                        ind:SetAlpha(0)
                        ind:SetNeedsFrameUpdate(false)
                        return
                    else
                        ind:SetAlpha(newAlpha)
                    end
                    if ind.Incrementing then
                        local newheight = ind.Height() + delta * 100
                        if newheight > 80 then
                            ind.Height:Set(80)
                            ind.Width:Set(80)
                            ind.Incrementing = false
                        else
                            ind.Height:Set(newheight)
                            ind.Width:Set(newheight)
                        end
                    else
                        local newheight = ind.Height() - delta * 100
                        if newheight < 50 then
                            ind.Height:Set(50)
                            ind.Width:Set(50)
                            ind.Incrementing = true
                        else
                            ind.Height:Set(newheight)
                            ind.Width:Set(newheight)
                        end
                    end
                end
            end
        elseif type == 'unitstack' then
            SetIconTextures(control)
            control:SetNewTextures(GetBackgroundTextures(control.Data.id))
            control.tooltipID = LOC(__blueprints[control.Data.id].Description) or 'no description'
            control.mAltToggledFlag = false
            control.Height:Set(48)
            control.Width:Set(48)
            control.Icon.Height:Set(48)
            control.Icon.Width:Set(48)
            control.LowFuel:SetAlpha(0, true)
#            if __blueprints[control.Data.id].General.ConstructionBar then
#                control.ConsBar:SetAlpha(1, true)
#            else
#                control.ConsBar:SetAlpha(0, true)
#            end
            control.BuildKey = nil
            if control.Data.lowFuel then
                control.LowFuel:SetNeedsFrameUpdate(true)
                control.LowFuelIcon:SetAlpha(1)
            else
                control.LowFuel:SetNeedsFrameUpdate(false)
            end
            if table.getn(control.Data.units) > 1 then
                control.Count:SetText(table.getn(control.Data.units))
                control.Count:SetColor('ffffffff')
            else
                control.Count:SetText('')
            end
            control.Icon:Show()
            control:Enable()
        end
    end
    if options.gui_bigger_strat_build_icons != 0 then
        local oldSecondary = controls.secondaryChoices.SetControlToType
        local oldPrimary = controls.choices.SetControlToType
        -- norem add idle icon to buttons
        local oldPrimaryCreate = controls.choices.CreateElement
        controls.choices.CreateElement = function()
            local btn = oldPrimaryCreate()
            btn.IdleIcon = Bitmap(btn.Icon, UIUtil.SkinnableFile('/game/idle_mini_icon/idle_icon.dds'))
            LayoutHelpers.AtBottomIn(btn.IdleIcon, btn)
            LayoutHelpers.AtLeftIn(btn.IdleIcon, btn)
            btn.IdleIcon:DisableHitTest()
            btn.IdleIcon:SetAlpha(0)
            return btn
        end
        controls.secondaryChoices.SetControlToType = function(control, type)
            oldSecondary(control, type)
            if control.StratIcon.Underlay then
                control.StratIcon.Underlay:Hide()
            end
            StratIconReplacement(control)
        end
        controls.choices.SetControlToType = function(control, type)
            oldPrimary(control, type)
            if control.StratIcon.Underlay then
                control.StratIcon.Underlay:Hide()
            end
            StratIconReplacement(control)

            -- AZ improved selection code
            if type == 'unitstack' and control.Data.idleCon then
                control.IdleIcon:SetAlpha(1)
            end
        end
    else -- If we dont have bigger strat icons selected, just do the idle icon
        local oldSecondary = controls.secondaryChoices.SetControlToType
        local oldPrimary = controls.choices.SetControlToType
        -- norem add idle icon to buttons
        local oldPrimaryCreate = controls.choices.CreateElement
        controls.choices.CreateElement = function()
            local btn = oldPrimaryCreate()
            btn.IdleIcon = Bitmap(btn.Icon, UIUtil.SkinnableFile('/game/idle_mini_icon/idle_icon.dds'))
            LayoutHelpers.AtBottomIn(btn.IdleIcon, btn)
            LayoutHelpers.AtLeftIn(btn.IdleIcon, btn)
            btn.IdleIcon:DisableHitTest()
            btn.IdleIcon:SetAlpha(0)
            return btn
        end
        controls.secondaryChoices.SetControlToType = function(control, type)
            oldSecondary(control, type)
        end
        controls.choices.SetControlToType = function(control, type)
            oldPrimary(control, type)
            -- AZ improved selection code
            if type == 'unitstack' and control.Data.idleCon then
                control.IdleIcon:SetAlpha(1)
            end
        end
    end

    if options.gui_visible_template_names != 0 then
        local oldSecondary = controls.secondaryChoices.SetControlToType
        local oldPrimary = controls.choices.SetControlToType
        local oldPrimaryCreate = controls.choices.CreateElement
        controls.choices.CreateElement = function()
            local btn = oldPrimaryCreate()
        -- creating the display area
            btn.Tmplnm = UIUtil.CreateText(btn.Icon, '', 11, UIUtil.bodyFont)
            btn.Tmplnm:SetColor('ffffff00')
            btn.Tmplnm:DisableHitTest()
            btn.Tmplnm:SetDropShadow(true)
            btn.Tmplnm:SetCenteredHorizontally(true)
            LayoutHelpers.CenteredBelow(btn.Tmplnm, btn, 0)
            btn.Tmplnm.Depth:Set(function() return btn.Icon.Depth() + 10 end)
            return btn
        end
        controls.secondaryChoices.SetControlToType = function(control, type)
            oldSecondary(control, type)
        end
        controls.choices.SetControlToType = function(control, type)
            oldPrimary(control, type)
        -- the text
            if type == 'templates' and 'templates' then
                control.Tmplnm.Width:Set(48)
                control.Tmplnm:SetText(string.sub(control.Data.template.name, cutA, cutB))
            end
        end
    end

end

function StratIconReplacement(control)
    if __blueprints[control.Data.id].StrategicIconName then
        local iconName = __blueprints[control.Data.id].StrategicIconName
        local iconConversion
        if options.gui_bigger_strat_build_icons == 2 then
            iconConversion = straticonsfile.aSpecificStratIcons[control.Data.id] or straticonsfile.aStratIconTranslationFull[iconName]
        else
            iconConversion = straticonsfile.aSpecificStratIcons[control.Data.id] or straticonsfile.aStratIconTranslation[iconName]
        end
        if iconConversion and DiskGetFileInfo('/textures/ui/icons_strategic/'..iconConversion..'.dds') then
            control.StratIcon:SetTexture('/textures/ui/icons_strategic/'..iconConversion..'.dds')
            LayoutHelpers.AtTopIn(control.StratIcon, control.Icon, 1)
            LayoutHelpers.AtRightIn(control.StratIcon, control.Icon, 1)
            LayoutHelpers.ResetBottom(control.StratIcon)
            LayoutHelpers.ResetLeft(control.StratIcon)
            control.StratIcon:SetAlpha(0.8)
        else
            LOG('Strat Icon Mod Error: updated strat icon required for: ', iconName)
        end
    end
end

function OnRolloverHandler(button, state)
    local item = button.Data

    if options.gui_draggable_queue != 0 and item.type == 'queuestack' and prevSelection and EntityCategoryContains(categories.FACTORY, prevSelection[1]) then
        if state == 'enter' then
            button.oldHandleEvent = button.HandleEvent
            --if we have entered the button and are dragging something then we want to replace it with what we are dragging
            if dragging == true then
                --move item from old location (index) to new location (this button's index)
                MoveItemInQueue(currentCommandQueue, index, item.position)
                --since the currently selected button has now moved, update the index
                index = item.position

                button.dragMarker = Bitmap(button, '/textures/ui/queuedragger.dds')
                LayoutHelpers.FillParent(button.dragMarker, button)
                button.dragMarker:DisableHitTest()
                Effect.Pulse(button.dragMarker, 1.5, 0.6, 0.8)

            end
            button.HandleEvent = function(self, event)
                if event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
                    local count = 1
                    if event.Modifiers.Ctrl == true or event.Modifiers.Shift == true then
                        count = 5
                    end

                    if event.Modifiers.Left then
                        if not dragLock then
                            --left button pressed so start dragging procedure
                            dragging = true
                            index = item.position
                            originalIndex = index

                            self.dragMarker = Bitmap(self, '/textures/ui/queuedragger.dds')
                            LayoutHelpers.FillParent(self.dragMarker, self)
                            self.dragMarker:DisableHitTest()
                            Effect.Pulse(self.dragMarker, 1.5, 0.6, 0.8)

                            --copy un modified queue so that current build order is recorded (for deleting it)
                            oldQueue = table.copy(currentCommandQueue)
                        end
                    else
                        PlaySound(Sound({Cue = "UI_MFD_Click", Bank = "Interface"}))
                        DecreaseBuildCountInQueue(item.position, count)
                    end
                elseif event.Type == 'ButtonRelease' then
                    if dragging then
                        --if queue has changed then update queue, else increase build count (like default)
                        if modified then
                            ButtonReleaseCallback()
                        else
                            PlaySound(Sound({Cue = "UI_MFD_Click", Bank = "Interface"}))
                            dragging = false
                            local count = 1
                            if event.Modifiers.Ctrl == true or event.Modifiers.Shift == true then
                                count = 5
                            end
                            IncreaseBuildCountInQueue(item.position, count)
                        end
                        if self.dragMarker then
                            self.dragMarker:Destroy()
                            self.dragMarker = false
                        end
                    end
                else
                    button.oldHandleEvent(self, event)
                end
            end
            button.Glow:SetNeedsFrameUpdate(true)
        else
            if button.oldHandleEvent then
                button.HandleEvent = button.oldHandleEvent
            else
                WARN('OLD HANDLE EVENT MISSING HOW DID THIS HAPPEN?!')
            end
            if button.dragMarker then
                button.dragMarker:Destroy()
                button.dragMarker = false
            end
            button.Glow:SetNeedsFrameUpdate(false)
            button.Glow:SetAlpha(0)
            UnitViewDetail.Hide()
        end
    else
        if state == 'enter' then
            button.Glow:SetNeedsFrameUpdate(true)
            if item.type == 'item' then
                UnitViewDetail.Show(__blueprints[item.id], sortedOptions.selection[1], item.id)
            elseif item.type == 'enhancement' then
                UnitViewDetail.ShowEnhancement(item.enhTable, item.unitID, item.icon, GetEnhancementPrefix(item.unitID, item.icon), sortedOptions.selection[1])
            end
        else
            button.Glow:SetNeedsFrameUpdate(false)
            button.Glow:SetAlpha(0)
            UnitViewDetail.Hide()
        end
    end
end

function OnClickHandler(button, modifiers)
    PlaySound(Sound({Cue = "UI_MFD_Click", Bank = "Interface"}))
    local item = button.Data

    if options.gui_improved_unit_deselection != 0 then
        --Improved unit deselection -ghaleon
        if item.type == 'unitstack' then
            if modifiers.Right then
                if modifiers.Shift or modifiers.Ctrl or (modifiers.Shift and modifiers.Ctrl) then -- we have one of our modifiers
                    local selectionx = {}
                    local countx = 0
                    if modifiers.Shift then countx = 1 end
                    if modifiers.Ctrl then countx = 5 end
                    if modifiers.Shift and modifiers.Ctrl then countx = 10 end
                    for _, unit in sortedOptions.selection do
                        local foundx = false
                        for _, checkUnit in item.units do
                            if checkUnit == unit and countx > 0 then
                                foundx = true
                                countx = countx - 1
                                break
                            end
                        end
                        if not foundx then
                            table.insert(selectionx, unit)
                        end
                    end
                    SelectUnits(selectionx)
                else -- default right-click behavior
                    local selection = {}
                    for _, unit in sortedOptions.selection do
                        local found = false
                        for _, checkUnit in item.units do
                            if checkUnit == unit then
                                found = true
                                break
                            end
                        end
                        if not found then
                            table.insert(selection, unit)
                        end
                    end
                    SelectUnits(selection)
                end
            end
            -- override default rightclick handler
            if modifiers.Right then return end
            -- else new code does not work as intended
        end
    end


    if item.type == "templates" and allFactories then

        if modifiers.Right then
            -- options menu
            if button.OptionMenu then
                button.OptionMenu:Destroy()
                button.OptionMenu = nil
            else
                button.OptionMenu = CreateFacTemplateOptionsMenu(button)
            end
            for _, otherBtn in controls.choices.Items do
                if button != otherBtn and otherBtn.OptionMenu then
                    otherBtn.OptionMenu:Destroy()
                    otherBtn.OptionMenu = false
                end
            end
        else
            -- add template to build queue
            for _, data in ipairs(item.template.templateData) do
                local blueprint = __blueprints[data.id]
                if blueprint.General.UpgradesFrom == 'none' then
                    IssueBlueprintCommand("UNITCOMMAND_BuildFactory", data.id, data.count)
                else
                    IssueBlueprintCommand("UNITCOMMAND_Upgrade", data.id, 1, false)
                end
            end
        end
    elseif item.type == 'item' then
        ClearBuildTemplates()
        local blueprint = __blueprints[item.id]
        local count = 1
        local performUpgrade = false
        local buildCmd = "build"

        if modifiers.Ctrl or modifiers.Shift then
            count = 5
        end

        if modifiers.Left then
            # see if we are issuing an upgrade order
            if blueprint.General.UpgradesFrom == 'none' then
                performUpgrade = false
            else
                for i,v in sortedOptions.selection do
                    if v then   # its possible that your unit will have died by the time this gets to it
                        local unitBp = v:GetBlueprint()
                        if blueprint.General.UpgradesFrom == unitBp.BlueprintId then
                            performUpgrade = true
                        elseif blueprint.General.UpgradesFrom == unitBp.General.UpgradesTo then
                            performUpgrade = true
                        elseif blueprint.General.UpgradesFromBase != "none" then
                            # try testing against the base
                            if blueprint.General.UpgradesFromBase == unitBp.BlueprintId then
                                performUpgrade = true
                            elseif blueprint.General.UpgradesFromBase == unitBp.General.UpgradesFromBase then
                                performUpgrade = true
                            end
                        end
                    end
                end
            end

            if performUpgrade then
                IssueBlueprintCommand("UNITCOMMAND_Upgrade", item.id, 1, false)
            else
                if blueprint.Physics.MotionType == 'RULEUMT_None' or EntityCategoryContains(categories.NEEDMOBILEBUILD, item.id) then
                    # stationary means it needs to be placed, so go in to build mobile mode
					import('/lua/ui/game/commandmode.lua').StartCommandMode(buildCmd, {name=item.id})
                else
                    # if the item to build can move, it must be built by a factory
                    #TODO -what about mobile factories?
                    IssueBlueprintCommand("UNITCOMMAND_BuildFactory", item.id, count)
                end
            end
        else
            local unitIndex = false
            for index, unitStack in currentCommandQueue do
                if unitStack.id == item.id then
                    unitIndex = index
                end
            end
            if unitIndex != false then
                DecreaseBuildCountInQueue(unitIndex, count)
            end
        end
    elseif item.type == 'unitstack' then
        if modifiers.Left then
            SelectUnits(item.units)
        elseif modifiers.Right then
            local selection = {}
            for _, unit in sortedOptions.selection do
                local found = false
                for _, checkUnit in item.units do
                    if checkUnit == unit then
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(selection, unit)
                end
            end
            SelectUnits(selection)
        end
    elseif item.type == 'attachedunit' then
        if modifiers.Left then
            -- Toggling selection of the entity
            button:OnAltToggle()

            -- Add or Remove the entity to the session selection
            if button.mAltToggledFlag then
                AddToSessionExtraSelectList(item.unit)
            else
                RemoveFromSessionExtraSelectList(item.unit)
            end
        end
    elseif item.type == 'templates' then
        ClearBuildTemplates()
        if modifiers.Right then
            if button.OptionMenu then
                button.OptionMenu:Destroy()
                button.OptionMenu = nil
            else
                button.OptionMenu = CreateTemplateOptionsMenu(button)
            end
            for _, otherBtn in controls.choices.Items do
                if button != otherBtn and otherBtn.OptionMenu then
                    otherBtn.OptionMenu:Destroy()
                    otherBtn.OptionMenu = false
                end
            end
        else
            import('/lua/ui/game/commandmode.lua').StartCommandMode('build', {name=item.template.templateData[3][1]})
            SetActiveBuildTemplate(item.template.templateData)
        end

        if options.gui_template_rotator != 0 then
            local item = button.Data
            local activeTemplate = item.template.templateData
            local worldview = import('/lua/ui/game/worldview.lua').viewLeft
            local oldHandleEvent = worldview.HandleEvent
            worldview.HandleEvent = function(self, event)
                if event.Type == 'ButtonPress' then
                    if event.Modifiers.Middle then
                        ClearBuildTemplates()
                        local tempTemplate = table.deepcopy(activeTemplate)
                        for i = 3, table.getn(activeTemplate) do
                            local index = i
                            activeTemplate[index][3] = 0 - tempTemplate[index][4]
                            activeTemplate[index][4] = tempTemplate[index][3]
                        end
                        SetActiveBuildTemplate(activeTemplate)
                    elseif event.Modifiers.Shift then
                    else
                        worldview.HandleEvent = oldHandleEvent
                    end
                end
            end
        end

    elseif item.type == 'enhancement' then
        local existingEnhancements = EnhanceCommon.GetEnhancements(sortedOptions.selection[1]:GetEntityId())
        if existingEnhancements[item.enhTable.Slot] and existingEnhancements[item.enhTable.Slot] != item.enhTable.Prerequisite then
            if existingEnhancements[item.enhTable.Slot] != item.id then
            UIUtil.QuickDialog(GetFrame(0), "<LOC enhancedlg_0000>Choosing this enhancement will destroy the existing enhancement in this slot.  Are you sure?",
                "<LOC _Yes>", function()
                        ForkThread(function()
                            local orderData = {
                                # UserVerifyScript='/lua/ui/game/EnhanceCommand.lua',
                                TaskName = "EnhanceTask",
                                Enhancement = existingEnhancements[item.enhTable.Slot]..'Remove',
                            }
                            IssueCommand("UNITCOMMAND_Script", orderData, true)
                            WaitSeconds(.5)
                            orderData = {
                                # UserVerifyScript='/lua/ui/game/EnhanceCommand.lua',
                                TaskName = "EnhanceTask",
                                Enhancement = item.id,
                            }
                            IssueCommand("UNITCOMMAND_Script", orderData, true)
                        end)
                    end,
                "<LOC _No>", nil,
                nil, nil,
                true,  {worldCover = true, enterButton = 1, escapeButton = 2})
            end
        else
            local orderData = {
                # UserVerifyScript='/lua/ui/game/EnhanceCommand.lua',
                TaskName = "EnhanceTask",
                Enhancement = item.id,
            }
            IssueCommand("UNITCOMMAND_Script", orderData, true)
        end
    elseif item.type == 'queuestack' then
       --LOG("clicked a queuestack in construction.lua")
        local count = 1
        if modifiers.Shift or modifiers.Ctrl then
            count = 5
        end
        if modifiers.Left then
	   --LOG("unit++")
            IncreaseBuildCountInQueue(item.position, count)
        elseif modifiers.Right then
	   --LOG("unit-- attempt")
	   DecreaseBuildCountInQueue(item.position, count)
        end
    end
end

local warningtext = false
function ProcessKeybinding(key, templateID)
    if allFactories then
        if key == UIUtil.VK_ESCAPE then
            TemplatesFactory.ClearTemplateKey(capturingKeys or templateID)
            RefreshUI()
        elseif key == string.byte('b') or key == string.byte('B') then
            warningtext:SetText(LOC("<LOC CONSTRUCT_0005>Key must not be b!"))
        else
            if (key >= string.byte('A') and key <= string.byte('Z')) or (key >= string.byte('a') and key <= string.byte('z')) then
                if (key >= string.byte('a') and key <= string.byte('z')) then
                    key = string.byte(string.upper(string.char(key)))
                end
                if TemplatesFactory.SetTemplateKey(capturingKeys or templateID, key) then
                    RefreshUI()
                else
                    warningtext:SetText(LOCF("<LOC CONSTRUCT_0006>%s is already used!", string.char(key)))
                end
            else
                warningtext:SetText(LOC("<LOC CONSTRUCT_0007>Key must be a-z!"))
            end
        end
        return true
    else
        if key == UIUtil.VK_ESCAPE then
            Templates.ClearTemplateKey(capturingKeys or templateID)
            RefreshUI()
        elseif key == string.byte('b') or key == string.byte('B') then
            warningtext:SetText(LOC("<LOC CONSTRUCT_0005>Key must not be b!"))
        else
            if (key >= string.byte('A') and key <= string.byte('Z')) or (key >= string.byte('a') and key <= string.byte('z')) then
                if (key >= string.byte('a') and key <= string.byte('z')) then
                    key = string.byte(string.upper(string.char(key)))
                end
                if Templates.SetTemplateKey(capturingKeys or templateID, key) then
                    RefreshUI()
                else
                    warningtext:SetText(LOCF("<LOC CONSTRUCT_0006>%s is already used!", string.char(key)))
                end
            else
                warningtext:SetText(LOC("<LOC CONSTRUCT_0007>Key must be a-z!"))
            end
        end
        return true
    end
end

function CreateTemplateOptionsMenu(button)
    local group = Group(button)
    group.Depth:Set(button:GetRootFrame():GetTopmostDepth() + 1)
    local title = Edit(group)
    local items = {
        {label = '<LOC _Rename>Rename',
        action = function()
            title:AcquireFocus()
        end,},
        {label = '<LOC _Change_Icon>Change Icon',
        action = function()
            local contents = {}
            local controls = {}
            for _, entry in button.Data.template.templateData do
                if type(entry) != 'table' then continue end
                if not contents[entry[1]] then
                    contents[entry[1]] = true
                end
            end
            for iconType, _ in contents do
                local bmp = Bitmap(group, '/textures/ui/common/icons/units/'..iconType..'_icon.dds')
                bmp.Height:Set(30)
                bmp.Width:Set(30)
                bmp.ID = iconType
                table.insert(controls, bmp)
            end
            group.SubMenu = CreateSubMenu(group, controls, function(id)
                Templates.SetTemplateIcon(button.Data.template.templateID, id)
                RefreshUI()
            end)
        end,
        arrow = true},
        {label = '<LOC _Change_Keybinding>Change Keybinding',
        action = function()
            local text = UIUtil.CreateText(group, "<LOC CONSTRUCT_0008>Press a key to bind", 12, UIUtil.bodyFont)
            if not BuildMode.IsInBuildMode() then
                text:AcquireKeyboardFocus(false)
                text.HandleEvent = function(self, event)
                    if event.Type == 'KeyDown' then
                        ProcessKeybinding(event.KeyCode, button.Data.template.templateID)
                    end
                    return true
                end
                local oldTextOnDestroy = text.OnDestroy
                text.OnDestroy = function(self)
                    text:AbandonKeyboardFocus()
                    oldTextOnDestroy(self)
                end
            else
                capturingKeys = button.Data.template.templateID
            end
            warningtext = text
            group.SubMenu = CreateSubMenu(group, {text}, function(id)
                Templates.SetTemplateKey(button.Data.template.templateID, id)
                RefreshUI()
            end, false)
        end,},
        {label = '<LOC _Send_to>Send to',
        action = function()
            local armies = GetArmiesTable().armiesTable
            local entries = {}
            for i, armyData in armies do
                if i != GetFocusArmy() and armyData.human then
                    local entry = UIUtil.CreateText(group, armyData.nickname, 12, UIUtil.bodyFont)
                    entry.ID = i
                    table.insert(entries, entry)
                end
            end
            if table.getsize(entries) > 0 then
                group.SubMenu = CreateSubMenu(group, entries, function(id)
                    Templates.SendTemplate(button.Data.template.templateID, id)
                    RefreshUI()
                end)
            end
        end,
        disabledFunc = function()
            if table.getsize(GetSessionClients()) > 1 then
                return false
            else
                return true
            end
        end,
        arrow = true},
        {label = '<LOC _Delete>Delete',
        action = function()
            Templates.RemoveTemplate(button.Data.template.templateID)
            RefreshUI()
        end,},
    }
    local function CreateItem(data)
        local bg = Bitmap(group)
        bg:SetSolidColor('00000000')
        bg.label = UIUtil.CreateText(bg, LOC(data.label), 12, UIUtil.bodyFont)
        bg.label:DisableHitTest()
        LayoutHelpers.AtLeftTopIn(bg.label, bg, 2)
        bg.Height:Set(function() return bg.label.Height() + 2 end)
        bg.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                self:SetSolidColor('ff777777')
            elseif event.Type == 'MouseExit' then
                self:SetSolidColor('00000000')
            elseif event.Type == 'ButtonPress' then
                if group.SubMenu then
                    group.SubMenu:Destroy()
                    group.SubMenu = false
                end
                data.action()
            end
            return true
        end

        if data.disabledFunc and data.disabledFunc() then
            bg:Disable()
            bg.label:SetColor('ff777777')
        end

        return bg
    end
    local totHeight = 0
    local maxWidth = 0
    title.Height:Set(function() return title:GetFontHeight() end)
    title.Width:Set(function() return title:GetStringAdvance(LOC(button.Data.template.name)) end)
    UIUtil.SetupEditStd(title, "ffffffff", nil, "ffaaffaa", UIUtil.highlightColor, UIUtil.bodyFont, 14, 200)
    title:SetDropShadow(true)
    title:ShowBackground(true)
    title:SetText(LOC(button.Data.template.name))
    LayoutHelpers.AtLeftTopIn(title, group)
    totHeight = totHeight + title.Height()
    maxWidth = math.max(maxWidth, title.Width())
    local itemControls = {}
    local prevControl = false
    for index, actionData in items do
        local i = index
        itemControls[i] = CreateItem(actionData)
        if prevControl then
            LayoutHelpers.Below(itemControls[i], prevControl)
        else
            LayoutHelpers.Below(itemControls[i], title)
        end
        totHeight = totHeight + itemControls[i].Height()
        maxWidth = math.max(maxWidth, itemControls[i].label.Width()+4)
        prevControl = itemControls[i]
    end
    for _, control in itemControls do
        control.Width:Set(maxWidth)
    end
    title.Width:Set(maxWidth)
    group.Height:Set(totHeight)
    group.Width:Set(maxWidth)
    LayoutHelpers.Above(group, button, 10)

    title.HandleEvent = function(self, event)
        Edit.HandleEvent(self, event)
        return true
    end
    title.OnEnterPressed = function(self, text)
        Templates.RenameTemplate(button.Data.template.templateID, text)
        RefreshUI()
    end

    local bg = CreateMenuBorder(group)

    group.HandleEvent = function(self, event)
        return true
    end

    return group
end

function CreateSubMenu(parentMenu, contents, onClickFunc, setupOnClickHandler)
    local menu = Group(parentMenu)
    menu.Left:Set(function() return parentMenu.Right() + 25 end)
    menu.Bottom:Set(parentMenu.Bottom)

    local totHeight = 0
    local maxWidth = 0
    for index, inControl in contents do
        local i = index
        local control = inControl
        if i == 1 then
            LayoutHelpers.AtLeftTopIn(control, menu)
        else
            LayoutHelpers.Below(control, contents[i-1])
        end
        if setupOnClickHandler != false then
            control.bg = Bitmap(control)
            control.bg.HandleEvent = function(self, event)
                if event.Type == 'MouseEnter' then
                    self:SetSolidColor('ff777777')
                elseif event.Type == 'MouseExit' then
                    self:SetSolidColor('00000000')
                elseif event.Type == 'ButtonPress' then
                    onClickFunc(control.ID)
                end
            end
            control.bg.Depth:Set(function() return control.Depth() - 1 end)
            control.bg.Top:Set(control.Top)
            control.bg.Bottom:Set(control.Bottom)
            control.bg.Left:Set(function() return control.Left() - 2 end)
            control.bg.Right:Set(function() return control.Right() + 2 end)
        end
        control:SetParent(menu)
        control.Depth:Set(function() return menu.Depth() + 5 end)
        control:DisableHitTest()
        totHeight = totHeight + control.Height()
        maxWidth = math.max(maxWidth, control.Width() + 4)
    end

    menu.Height:Set(totHeight)
    menu.Width:Set(maxWidth)
    local bg = CreateMenuBorder(menu)
    return menu
end

function CreateMenuBorder(group)
    local bg = Bitmap(group, UIUtil.UIFile('/game/chat_brd/drop-box_brd_m.dds'))
    bg.tl = Bitmap(group, UIUtil.UIFile('/game/chat_brd/drop-box_brd_ul.dds'))
    bg.tm = Bitmap(group, UIUtil.UIFile('/game/chat_brd/drop-box_brd_horz_um.dds'))
    bg.tr = Bitmap(group, UIUtil.UIFile('/game/chat_brd/drop-box_brd_ur.dds'))
    bg.l = Bitmap(group, UIUtil.UIFile('/game/chat_brd/drop-box_brd_vert_l.dds'))
    bg.r = Bitmap(group, UIUtil.UIFile('/game/chat_brd/drop-box_brd_vert_r.dds'))
    bg.bl = Bitmap(group, UIUtil.UIFile('/game/chat_brd/drop-box_brd_ll.dds'))
    bg.bm = Bitmap(group, UIUtil.UIFile('/game/chat_brd/drop-box_brd_lm.dds'))
    bg.br = Bitmap(group, UIUtil.UIFile('/game/chat_brd/drop-box_brd_lr.dds'))

    LayoutHelpers.FillParent(bg, group)
    bg.Depth:Set(group.Depth)

    bg.tl.Bottom:Set(group.Top)
    bg.tl.Right:Set(group.Left)
    bg.tl.Depth:Set(group.Depth)

    bg.tm.Bottom:Set(group.Top)
    bg.tm.Right:Set(group.Right)
    bg.tm.Left:Set(group.Left)
    bg.tm.Depth:Set(group.Depth)

    bg.tr.Bottom:Set(group.Top)
    bg.tr.Left:Set(group.Right)
    bg.tr.Depth:Set(group.Depth)

    bg.l.Bottom:Set(group.Bottom)
    bg.l.Right:Set(group.Left)
    bg.l.Top:Set(group.Top)
    bg.l.Depth:Set(group.Depth)

    bg.r.Bottom:Set(group.Bottom)
    bg.r.Left:Set(group.Right)
    bg.r.Top:Set(group.Top)
    bg.r.Depth:Set(group.Depth)

    bg.bl.Top:Set(group.Bottom)
    bg.bl.Right:Set(group.Left)
    bg.bl.Depth:Set(group.Depth)

    bg.br.Top:Set(group.Bottom)
    bg.br.Left:Set(group.Right)
    bg.br.Depth:Set(group.Depth)

    bg.bm.Top:Set(group.Bottom)
    bg.bm.Right:Set(group.Right)
    bg.bm.Left:Set(group.Left)
    bg.bm.Depth:Set(group.Depth)

    return bg
end

function GetTabByID(id)
    for _, control in controls.tabs do
        if control.ID == id then
            return control
        end
    end
    return false
end

local pauseEnabled = false
function EnablePauseToggle()
    if controls.extraBtn2 then
        controls.extraBtn2:Enable()
    end
    pauseEnabled = true
end
function DisablePauseToggle()
    if controls.extraBtn2 then
        controls.extraBtn2:Disable()
    end
    pauseEnabled = false
end

function ToggleUnitPause()
    if controls.selectionTab:IsChecked() or controls.constructionTab:IsChecked() then
        controls.extraBtn2:ToggleCheck()
    else
        SetPaused(sortedOptions.selection, not GetIsPaused(sortedOptions.selection))
    end
end

function CreateExtraControls(controlType)
    if controlType == 'construction' or controlType == 'templates' then
        Tooltip.AddCheckboxTooltip(controls.extraBtn1, 'construction_infinite')
        controls.extraBtn1.OnClick = function(self, modifiers)
            return Checkbox.OnClick(self, modifiers)
        end
        controls.extraBtn1.OnCheck = function(self, checked)
            for i,v in sortedOptions.selection do
                if checked then
                    v:ProcessInfo('SetRepeatQueue', 'true')
                else
                    v:ProcessInfo('SetRepeatQueue', 'false')
                end
            end
        end
        local allFactories = true
        local currentInfiniteQueueCheckStatus = true

        for i,v in sortedOptions.selection do
            if not v:IsRepeatQueue() then
                currentInfiniteQueueCheckStatus = false
            end

            if not v:IsInCategory('FACTORY') then
                allFactories = false
            end
        end

        if allFactories then
            controls.extraBtn1:SetCheck(currentInfiniteQueueCheckStatus, true)
            controls.extraBtn1:Enable()
        else
            controls.extraBtn1:Disable()
        end

        Tooltip.AddCheckboxTooltip(controls.extraBtn2, 'construction_pause')
        controls.extraBtn2.OnCheck = function(self, checked)
            SetPaused(sortedOptions.selection, checked)
        end
        if pauseEnabled then
            controls.extraBtn2:Enable()
        else
            controls.extraBtn2:Disable()
        end
        controls.extraBtn2:SetCheck(GetIsPaused(sortedOptions.selection),true)
    elseif controlType == 'selection' then
        Tooltip.AddCheckboxTooltip(controls.extraBtn1, 'save_template')
        local validForTemplate = true
        local faction = false
        for i,v in sortedOptions.selection do
            if not v:IsInCategory('STRUCTURE') then
                validForTemplate = false
                break
            end
            if i == 1 then
                local factions = import('/lua/factions.lua').Factions
                for _, factionData in factions do
                    if v:IsInCategory(factionData.Category) then
                        faction = factionData.Category
                        break
                    end
                end
            elseif not v:IsInCategory(faction) then
                validForTemplate = false
                break
            end
        end
        if validForTemplate then
            controls.extraBtn1:Enable()
            controls.extraBtn1.OnClick = function(self, modifiers)
                Templates.CreateBuildTemplate()
            end
        else
            controls.extraBtn1:Disable()
        end
        Tooltip.AddCheckboxTooltip(controls.extraBtn2, 'construction_pause')
        controls.extraBtn2.OnCheck = function(self, checked)
            SetPaused(sortedOptions.selection, checked)
        end
        if pauseEnabled then
            controls.extraBtn2:Enable()
        else
            controls.extraBtn2:Disable()
        end
        controls.extraBtn2:SetCheck(GetIsPaused(sortedOptions.selection),true)
    else
        controls.extraBtn1:Disable()
        controls.extraBtn2:Disable()
    end
end

function FormatData(unitData, type)
    local retData = {}
    if type == 'construction' then
        local function SortFunc(unit1, unit2)
            local bp1 = __blueprints[unit1].BuildIconSortPriority or __blueprints[unit1].StrategicIconSortPriority
            local bp2 = __blueprints[unit2].BuildIconSortPriority or __blueprints[unit2].StrategicIconSortPriority
            if bp1 >= bp2 then
                return false
            else
                return true
            end
        end
        local sortedUnits = {}
        local sortCategories = {
            categories.SORTCONSTRUCTION,
            categories.SORTECONOMY,
            categories.SORTDEFENSE,
            categories.SORTSTRATEGIC,
            categories.SORTINTEL,
            categories.SORTOTHER,
        }
        local miscCats = categories.ALLUNITS
        local borders = {}
        for i, v in sortCategories do
            local category = v
            local index = i - 1
            local tempIndex = i
            while index > 0 do
                category = category - sortCategories[index]
                index = index - 1
            end
            local units = EntityCategoryFilterDown(category, unitData)
            table.insert(sortedUnits, units)
            miscCats = miscCats - v
        end

        table.insert(sortedUnits, EntityCategoryFilterDown(miscCats, unitData))

        for i, units in sortedUnits do
            table.sort(units, SortFunc)
            local index = i
            if table.getn(units) > 0 then
                if table.getn(retData) > 0 then
                    table.insert(retData, {type = 'spacer'})
                end
                for unitIndex, unit in units do
                    table.insert(retData, {type = 'item', id = unit})
                end
            end
        end
        CreateExtraControls('construction')
        SetSecondaryDisplay('buildQueue')
    elseif type == 'selection' then
        local function SortFunc(unit1, unit2)
         if unit1.id >= unit2.id then
            return false
         else
            return true
         end
        end

        local sortedUnits = {}
        local lowFuelUnits = {}
        local idleConsUnits = {}
        for _, unit in unitData do
         local id = unit:GetBlueprint().BlueprintId

         if unit:IsInCategory('AIR') and unit:GetFuelRatio() < .2 and unit:GetFuelRatio() > -1 then
            if not lowFuelUnits[id] then
               lowFuelUnits[id] = {}
            end
            table.insert(lowFuelUnits[id], unit)
         elseif options.gui_seperate_idle_builders != 0 and unit:IsInCategory('CONSTRUCTION') and unit:IsIdle() then
            if not idleConsUnits[id] then
               idleConsUnits[id] = {}
            end
            table.insert(idleConsUnits[id], unit)
         else
            if not sortedUnits[id] then
               sortedUnits[id] = {}
            end
            table.insert(sortedUnits[id], unit)
         end
        end

        local displayUnits = true
        if displayUnits then
         for i, v in sortedUnits do
            table.insert(retData, {type = 'unitstack', id = i, units = v})
         end
        end
        for i, v in lowFuelUnits do
         table.insert(retData, {type = 'unitstack', id = i, units = v, lowFuel = true})
        end
        for i, v in idleConsUnits do
         table.insert(retData, {type = 'unitstack', id = i, units = v, idleCon = true})
        end

        -- Sort unit types
        table.sort(retData, SortFunc)

        CreateExtraControls('selection')
        SetSecondaryDisplay('attached')

        import(UIUtil.GetLayoutFilename('construction')).OnTabChangeLayout(type)
    elseif type == 'templates' then
        table.sort(unitData, function(a,b)
            if a.key and not b.key then
                return true
            elseif b.key and not a.key then
                return false
            elseif a.key and b.key then
                return a.key <= b.key
            elseif a.name == b.name then
                return false
            else
                if LOC(a.name) <= LOC(b.name) then
                    return true
                else
                    return false
                end
            end
        end)
        for _, v in unitData do
            table.insert(retData, {type = 'templates', id = 'template', template = v})
        end
        CreateExtraControls('templates')
        SetSecondaryDisplay('buildQueue')
    else
        #Enhancements
        local existingEnhancements = EnhanceCommon.GetEnhancements(sortedOptions.selection[1]:GetEntityId())
        local slotToIconName = {
            RCH = 'ra',
            LCH = 'la',
            Back = 'b',
        }
        local filteredEnh = {}
        local usedEnhancements = {}
        local restrictList = EnhanceCommon.GetRestricted()
        for index, enhTable in unitData do
            if not string.find(enhTable.ID, 'Remove') then
                local restricted = false
                for _, enhancement in restrictList do
                    if enhancement == enhTable.ID then
                        restricted = true
                        break
                    end
                end
                if not restricted then
                    table.insert(filteredEnh, enhTable)
                end
            end
        end
        local function GetEnhByID(id)
            for i, enh in filteredEnh do
                if enh.ID == id then
                    return enh
                end
            end
        end
        local function FindDependancy(id)
            for i, enh in filteredEnh do
                if enh.Prerequisite and enh.Prerequisite == id then
                    return enh.ID
                end
            end
        end
        local function AddEnhancement(enhTable, disabled)
            local iconData = {
                type = 'enhancement',
                enhTable = enhTable,
                unitID = enhTable.UnitID,
                id = enhTable.ID,
                icon = enhTable.Icon,
                Selected = false,
                Disabled = disabled,
            }
            if existingEnhancements[enhTable.Slot] == enhTable.ID then
                iconData.Selected = true
            end
            table.insert(retData, iconData)
        end
        for i, enhTable in filteredEnh do
            if not usedEnhancements[enhTable.ID] and not enhTable.Prerequisite then
                AddEnhancement(enhTable, false)
                usedEnhancements[enhTable.ID] = true
                if FindDependancy(enhTable.ID) then
                    local searching = true
                    local curID = enhTable.ID
                    while searching do
                        table.insert(retData, {type = 'arrow'})
                        local tempEnh = GetEnhByID(FindDependancy(curID))
                        local disabled = true
                        if existingEnhancements[enhTable.Slot] == tempEnh.Prerequisite then
                            disabled = false
                        end
                        AddEnhancement(tempEnh, disabled)
                        usedEnhancements[tempEnh.ID] = true
                        if FindDependancy(tempEnh.ID) then
                            curID = tempEnh.ID
                        else
                            searching = false
                            if table.getsize(usedEnhancements) <= table.getsize(filteredEnh)-1 then
                                table.insert(retData, {type = 'spacer'})
                            end
                        end
                    end
                else
                    if table.getsize(usedEnhancements) <= table.getsize(filteredEnh)-1 then
                        table.insert(retData, {type = 'spacer'})
                    end
                end
            end
        end
        CreateExtraControls('enhancement')
        SetSecondaryDisplay('buildQueue')
    end
    import(UIUtil.GetLayoutFilename('construction')).OnTabChangeLayout(type)


    if type == 'templates' and allFactories then
        -- replace Infinite queue by Create template
        Tooltip.AddCheckboxTooltip(controls.extraBtn1, 'save_template')
        if table.getsize(currentCommandQueue) > 0 then
            controls.extraBtn1:Enable()
            controls.extraBtn1.OnClick = function(self, modifiers)
                TemplatesFactory.CreateBuildTemplate(currentCommandQueue)
            end
        else
            controls.extraBtn1:Disable()
        end
        controls.extraBtn1.icon.OnTexture = UIUtil.UIFile('/game/construct-sm_btn/template_on.dds')
        controls.extraBtn1.icon.OffTexture = UIUtil.UIFile('/game/construct-sm_btn/template_off.dds')
        if controls.extraBtn1:IsDisabled() then
            controls.extraBtn1.icon:SetTexture(controls.extraBtn1.icon.OffTexture)
        else
            controls.extraBtn1.icon:SetTexture(controls.extraBtn1.icon.OnTexture)
        end
    end

    return retData
end

function SetSecondaryDisplay(type)
    if updateQueue then --don't update the queue the tick after a buttonreleasecallback
        local data = {}
        if type == 'buildQueue' then
            if currentCommandQueue and table.getn(currentCommandQueue) > 0 then
                for index, unit in currentCommandQueue do
                    table.insert(data, {type = 'queuestack', id = unit.id, count = unit.count, position = index})
                end
            end
            if table.getn(sortedOptions.selection) == 1 and table.getn(data) > 0 then
                controls.secondaryProgress:SetNeedsFrameUpdate(true)
            else
                controls.secondaryProgress:SetNeedsFrameUpdate(false)
                controls.secondaryProgress:SetAlpha(0, true)
            end
        elseif type == 'attached' then
            local attachedUnits = EntityCategoryFilterDown(categories.MOBILE, GetAttachedUnitsList(sortedOptions.selection))
            if attachedUnits and table.getn(attachedUnits) > 0 then
                for _, v in attachedUnits do
                    table.insert(data, {type = 'attachedunit', id = v:GetBlueprint().BlueprintId, unit = v})
                end
            end
            controls.secondaryProgress:SetAlpha(0, true)
        end
        controls.secondaryChoices:Refresh(data)
    else
        updateQueue = true
    end
end

function OnQueueChanged(newQueue)
    currentCommandQueue = newQueue
    if not controls.selectionTab:IsChecked() then
        SetSecondaryDisplay('buildQueue')
    end
end

function CheckForOrderQueue(newSelection)
    if table.getn(selection) == 1 then
        -- render the command queue
        if currentCommandQueue then
            SetQueueGrid(currentCommandQueue, selection)
        else
            ClearQueueGrid()
        end
        SetQueueState(false)
    elseif table.getn(selection) > 0 then
        ClearCurrentFactoryForQueueDisplay()
        ClearQueueGrid()
        SetQueueState(false)
    else
        ClearCurrentFactoryForQueueDisplay()
        ClearQueueGrid()
        SetQueueState(true)
    end
end

function RefreshUI()
    OnSelection(prevBuildCategories, prevSelection, true)
    capturingKeys = false
end

function OnSelection(buildableCategories, selection, isOldSelection)

    if options.gui_templates_factory != 0 then
        if table.empty(selection) then
            allFactories = false
        else
            allFactories = true
            for i, v in selection do
                if not v:IsInCategory('FACTORY') then
                    allFactories = false
                    break
                end
            end
        end
    end

    if table.getsize(selection) > 0 then
        capturingKeys = false
        #Sorting down units
        local buildableUnits = EntityCategoryGetUnitList(buildableCategories)
        if not isOldSelection then
            previousTabSet = nil
            previousTabSize = nil
            activeTab = nil
            ClearSessionExtraSelectList()
        end
        sortedOptions = {}
        UnitViewDetail.Hide()

	-- Engymod addition by Rienzilla
	-- Only honour CONSTRUCTIONSORTDOWN if we selected a factory
        local allFactory = true
	for i, v in selection do
	   if allFactory and not v:IsInCategory('FACTORY') then
	      allFactory = false
	   end
	end

	if allFactory then
	   local sortDowns = EntityCategoryFilterDown(categories.CONSTRUCTIONSORTDOWN, buildableUnits)
	   sortedOptions.t1 = EntityCategoryFilterDown(categories.TECH1-categories.CONSTRUCTIONSORTDOWN, buildableUnits)
	   sortedOptions.t2 = EntityCategoryFilterDown(categories.TECH2-categories.CONSTRUCTIONSORTDOWN, buildableUnits)
	   sortedOptions.t3 = EntityCategoryFilterDown(categories.TECH3-categories.CONSTRUCTIONSORTDOWN, buildableUnits)
	   sortedOptions.t4 = EntityCategoryFilterDown(categories.EXPERIMENTAL-categories.CONSTRUCTIONSORTDOWN, buildableUnits)

	   for _, unit in sortDowns do
	      if EntityCategoryContains(categories.EXPERIMENTAL, unit) then
		 table.insert(sortedOptions.t3, unit)
	      elseif EntityCategoryContains(categories.TECH3, unit) then
		 table.insert(sortedOptions.t2, unit)
	      elseif EntityCategoryContains(categories.TECH2, unit) then
		 table.insert(sortedOptions.t1, unit)
	      end
	   end
	else
	   sortedOptions.t1 = EntityCategoryFilterDown(categories.TECH1, buildableUnits)
	   sortedOptions.t2 = EntityCategoryFilterDown(categories.TECH2, buildableUnits)
	   sortedOptions.t3 = EntityCategoryFilterDown(categories.TECH3, buildableUnits)
	   sortedOptions.t4 = EntityCategoryFilterDown(categories.EXPERIMENTAL, buildableUnits)
	end

        if table.getn(buildableUnits) > 0 then
            controls.constructionTab:Enable()
        else
            controls.constructionTab:Disable()
            if BuildMode.IsInBuildMode() then
                BuildMode.ToggleBuildMode()
            end
        end

        sortedOptions.selection = selection
        controls.selectionTab:Enable()

        local allSameUnit = true
        local bpID = false
        local allMobile = true
        for i, v in selection do
            if allMobile and not v:IsInCategory('MOBILE') then
                allMobile = false
            end
            if allSameUnit and bpID and bpID != v:GetBlueprint().BlueprintId then
                allSameUnit = false
            else
                bpID = v:GetBlueprint().BlueprintId
            end
            if not allMobile and not allSameUnit then
                break
            end
        end

        if table.getn(selection) == 1 and selection[1]:GetBlueprint().Enhancements then
            controls.enhancementTab:Enable()
        else
            controls.enhancementTab:Disable()
        end

        local templates = Templates.GetTemplates()
        if allMobile and templates and table.getsize(templates) > 0 then
            sortedOptions.templates = {}
            for templateIndex, template in templates do
                local valid = true
                for _, entry in template.templateData do
                    if type(entry) == 'table' then
                        if not table.find(buildableUnits, entry[1]) then
                            valid = false
                            break
                        end
                    end
                end
                if valid then
                    template.templateID = templateIndex
                    table.insert(sortedOptions.templates, template)
                end
            end
        end

        if table.getn(selection) == 1 then
            currentCommandQueue = SetCurrentFactoryForQueueDisplay(selection[1])
        else
            currentCommandQueue = {}
            ClearCurrentFactoryForQueueDisplay()
        end

        if not isOldSelection then
            if not controls.constructionTab:IsDisabled() then
                controls.constructionTab:SetCheck(true)
            else
                controls.selectionTab:SetCheck(true)
            end
        elseif controls.constructionTab:IsChecked() then
            controls.constructionTab:SetCheck(true)
        elseif controls.enhancementTab:IsChecked() then
            controls.enhancementTab:SetCheck(true)
        else
            controls.selectionTab:SetCheck(true)
        end

        prevSelection = selection
        prevBuildCategories = buildableCategories
        prevBuildables = buildableUnits
        import(UIUtil.GetLayoutFilename('construction')).OnSelection(false)

        controls.constructionGroup:Show()
        controls.choices:CalcVisible()
        controls.secondaryChoices:CalcVisible()
    else
        if BuildMode.IsInBuildMode() then
            BuildMode.ToggleBuildMode()
        end
        currentCommandQueue = {}
        ClearCurrentFactoryForQueueDisplay()
        import(UIUtil.GetLayoutFilename('construction')).OnSelection(true)
    end

    if table.getsize(selection) > 0 then
        --repeated from original to access the local variables
        local allSameUnit = true
        local bpID = false
        local allMobile = true
        for i, v in selection do
            if allMobile and not v:IsInCategory('MOBILE') then
                allMobile = false
            end
            if allSameUnit and bpID and bpID != v:GetBlueprint().BlueprintId then
                allSameUnit = false
            else
                bpID = v:GetBlueprint().BlueprintId
            end
            if not allMobile and not allSameUnit then
                break
            end
        end

        --Upgrade multiple SCU at once
        if selection[1]:GetBlueprint().Enhancements and allSameUnit then
            controls.enhancementTab:Enable()
        end

        --Allow all races to build other races templates
        if options.gui_all_race_templates != 0 then
            local templates = Templates.GetTemplates()
            local buildableUnits = EntityCategoryGetUnitList(buildableCategories)
            if allMobile and templates and table.getsize(templates) > 0 then
                local currentFaction = selection[1]:GetBlueprint().General.FactionName
                if currentFaction then
                    sortedOptions.templates = {}
                    local function ConvertID(BPID)
                        local prefixes = {
                            ["AEON"] = {
                                "uab",
                                "xab",
                                "dab",
                            },
                            ["UEF"] = {
                                "ueb",
                                "xeb",
                                "deb",
                            },
                            ["CYBRAN"] = {
                                "urb",
                                "xrb",
                                "drb",
                            },
                            ["SERAPHIM"] = {
                                "xsb",
                                "usb",
                                "dsb",
                            },
                        }
                        for i, prefix in prefixes[string.upper(currentFaction)] do
                            if table.find(buildableUnits, string.gsub(BPID, "(%a+)(%d+)", prefix .. "%2")) then
                                return string.gsub(BPID, "(%a+)(%d+)", prefix .. "%2")
                            end
                        end
                        return false
                    end
                    for templateIndex, template in templates do
                        local valid = true
                        local converted = false
                        for _, entry in template.templateData do
                            if type(entry) == 'table' then
                                if not table.find(buildableUnits, entry[1]) then

                                    entry[1] = ConvertID(entry[1])
                                    converted = true
                                    if not table.find(buildableUnits, entry[1]) then
                                        valid = false
                                        break
                                    end
                                end
                            end
                        end
                        if valid then
                            if converted then
                                template.icon = ConvertID(template.icon)
                            end
                            template.templateID = templateIndex
                            table.insert(sortedOptions.templates, template)
                        end
                    end
                end

                --refresh the construction tab to show any new available templates
                if not isOldSelection then
                    if not controls.constructionTab:IsDisabled() then
                        controls.constructionTab:SetCheck(true)
                    else
                        controls.selectionTab:SetCheck(true)
                    end
                elseif controls.constructionTab:IsChecked() then
                    controls.constructionTab:SetCheck(true)
                elseif controls.enhancementTab:IsChecked() then
                    controls.enhancementTab:SetCheck(true)
                else
                    controls.selectionTab:SetCheck(true)
                end
            end
        end
    end

    -- add valid templates for selection
    if allFactories then
        sortedOptions.templates = {}
        local templates = TemplatesFactory.GetTemplates()
        if templates and not table.empty(templates) then
            local buildableUnits = EntityCategoryGetUnitList(buildableCategories)
            for templateIndex, template in ipairs(templates) do
                local valid = true
                for index, entry in ipairs(template.templateData) do
                    if not table.find(buildableUnits, entry.id) then
                        valid = false
                        -- allow templates containing factory upgrades & higher tech units
                        if index > 1 then
                            for i = index - 1, 1, -1 do
                                local blueprint = __blueprints[template.templateData[i].id]
                                if blueprint.General.UpgradesFrom ~= 'none' then
                                    -- previous entry is a (valid) upgrade
                                    valid = true
                                    break
                                end
                            end
                        end
                        break
                    end
                end
                if valid then
                    template.templateID = templateIndex
                    table.insert(sortedOptions.templates, template)
                end
            end
        end

        -- templates tab enable & refresh
        local templatesTab = GetTabByID('templates')
        if templatesTab then
            templatesTab:Enable()
            if templatesTab:IsChecked() then
                templatesTab:SetCheck(true)
            end
        end
    end

end

function ShowBuildModeKeys(show)
    showBuildIcons = show
    if not controls.constructionTab:IsChecked() and show then
        controls.constructionTab:SetCheck(true)
    end
    if not controls.choices:IsHidden() then
        controls.choices:CalcVisible()
    end
end

function SetLayout(layout)
    if controls.choices.Items then
        for index, _ in controls.choices.Items do
            local i = index
            if controls.choices.Items[i] then
                controls.choices.Items[i]:Destroy()
                controls.choices.Items[i] = nil
            end
        end
    end
    import(UIUtil.GetLayoutFilename('construction')).SetLayout()
    CommonLogic()
end

function SetupConstructionControl(parent, inMFDControl, inOrdersControl)
    mfdControl = inMFDControl
    ordersControl = inOrdersControl
    controlClusterGroup = parent

    CreateUI()

    SetLayout(UIUtil.currentLayout)

    return controls.constructionGroup
end


function NewTech(Data)
    for _, unitList in Data do
        for _, unit in unitList do
            table.insert(newTechUnits, unit)
        end
    end
end

# given a tech level, sets that tech level, returns false if tech level not available
function SetCurrentTechTab(techLevel)
    if techLevel == 1 and GetTabByID('t1'):IsDisabled() then
        return false
    elseif techLevel == 2 and GetTabByID('t2'):IsDisabled() then
        return false
    elseif techLevel == 3 and GetTabByID('t3'):IsDisabled() then
        return false
    elseif techLevel == 4 and GetTabByID('t4'):IsDisabled() then
        return false
    elseif techLevel == 5 and GetTabByID('templates'):IsDisabled() then
        return false
    elseif techLevel > 5 or techLevel < 1 then
        return false
    end
    if techLevel == 5 then
        GetTabByID('templates'):SetCheck(true)
    else
        GetTabByID('t'..tostring(techLevel)):SetCheck(true)
    end
    return true
end

function GetCurrentTechTab()
    if GetTabByID('t1'):IsChecked() then
        return 1
    elseif GetTabByID('t2'):IsChecked() then
        return 2
    elseif GetTabByID('t3'):IsChecked() then
        return 3
    elseif GetTabByID('t4'):IsChecked() then
        return 4
    elseif GetTabByID('templates'):IsChecked() then
        return 5
    else
        return nil
    end
end

function Contract()
    controls.constructionGroup:Hide()
end

function Expand()
    if GetSelectedUnits() then
        controls.constructionGroup:Show()
    else
        controls.constructionGroup:Hide()
    end
end

function HandleBuildModeKey(key)
    if capturingKeys then
        ProcessKeybinding(key)
    else
        BuildTemplate(key)
    end
end

function BuildTemplate(key, modifiers)
    for _, item in controls.choices.Items do
        if item.BuildKey == key then
            OnClickHandler(item, modifiers)
            return true
        end
    end
    return false
end

function OnEscapeInBuildMode()
    if capturingKeys then
        Templates.ClearTemplateKey(capturingKeys)
        RefreshUI()
        return true
    end
    return false
end

function CycleTabs()
    if controls.constructionGroup:IsHidden() then return end

    if controls.constructionTab:IsChecked() then
        controls.selectionTab:SetCheck(true)
    elseif controls.selectionTab:IsChecked() then
        if controls.enhancementTab:IsDisabled() then
            controls.constructionTab:SetCheck(true)
        else
            controls.enhancementTab:SetCheck(true)
        end
    elseif controls.enhancementTab:IsChecked() then
        controls.constructionTab:SetCheck(true)
    end
end

function IsConstructionEnabled()
    return not controls.constructionTab:IsDisabled()
end

function ToggleInfinateMode()
    if controls.infBtn then
        controls.infBtn:ToggleCheck()
    end
end

function MoveItemInQueue(queue, indexfrom, indexto)
    modified = true
    local moveditem = queue[indexfrom]
    if indexfrom < indexto then
        --take indexfrom out and shunt all indices from indexfrom to indexto up one
        for i = indexfrom, (indexto - 1) do
            queue[i] = queue[i+1]
        end
    elseif indexfrom > indexto then
        --take indexfrom out and shunt all indices from indexto to indexfrom down one
        for i = indexfrom, (indexto + 1), -1 do
            queue[i] = queue[i-1]
        end
    end
    queue[indexto] = moveditem
    modifiedQueue = queue
    currentCommandQueue = queue
    --update buttons in the UI
    SetSecondaryDisplay('buildQueue')
end

function UpdateBuildList(newqueue, from)
    --The way this does this is UGLY but I can only find functions to remove things from the build queue and to add them at the end
    --Thus the only way I can see to modify the build queue is to delete it back to the point it is modified from (the from argument) and then
    --add the modified version back in. Unfortunately this causes a momentary 'skip' in the displayed build cue as it is deleted and replaced

    for i = table.getn(oldQueue), from, -1  do
        DecreaseBuildCountInQueue(i, oldQueue[i].count)
    end
    for i = from, table.getn(newqueue)  do
        blueprint = __blueprints[newqueue[i].id]
        if blueprint.General.UpgradesFrom == 'none' then
            IssueBlueprintCommand("UNITCOMMAND_BuildFactory", newqueue[i].id, newqueue[i].count)
        else
            IssueBlueprintCommand("UNITCOMMAND_Upgrade", newqueue[i].id, 1, false)
        end
    end
    ForkThread(dragPause)
end

function dragPause()
    WaitSeconds(0.4)
    dragLock = false
end

function ButtonReleaseCallback()
    if dragging == true then
        PlaySound(Sound({Cue = "UI_MFD_Click", Bank = "Interface"}))
        --don't update the queue next time round, to avoid a list of 0 builds
        updateQueue = false
        --disable dragging until the queue is rebuilt
        dragLock = true
        --reset modified so buildcount increasing can be used again
        modified = false
        --mouse button released so end drag
        dragging = false
        if originalIndex <= index then
            first_modified_index = originalIndex
        else
            first_modified_index = index
        end
        --on the release of the mouse button we want to update the ACTUAL build queue that the factory does. So far, only the UI has been changed,
        UpdateBuildList(modifiedQueue, first_modified_index)
        --nothing is now selected
        index = nil
    end
end

function CreateFacTemplateOptionsMenu(button)
    local group = Group(button)
    group.Depth:Set(button:GetRootFrame():GetTopmostDepth() + 1)
    local title = Edit(group)
    local items = {
        {label = '<LOC _Rename>Rename',
        action = function()
            title:AcquireFocus()
        end,},
        {label = '<LOC _Change_Icon>Change Icon',
        action = function()
            local contents = {}
            local controls = {}
            for _, entry in button.Data.template.templateData do
                if type(entry) != 'table' then continue end
                if not contents[entry.id] then
                    contents[entry.id] = true
                end
            end
            for iconType, _ in contents do
                local bmp = Bitmap(group, '/textures/ui/common/icons/units/'..iconType..'_icon.dds')
                bmp.Height:Set(30)
                bmp.Width:Set(30)
                bmp.ID = iconType
                table.insert(controls, bmp)
            end
            group.SubMenu = CreateSubMenu(group, controls, function(id)
                TemplatesFactory.SetTemplateIcon(button.Data.template.templateID, id)
                RefreshUI()
            end)
        end,
        arrow = true},
        {label = '<LOC _Change_Keybinding>Change Keybinding',
        action = function()
            local text = UIUtil.CreateText(group, "<LOC CONSTRUCT_0008>Press a key to bind", 12, UIUtil.bodyFont)
            if not BuildMode.IsInBuildMode() then
                text:AcquireKeyboardFocus(false)
                text.HandleEvent = function(self, event)
                    if event.Type == 'KeyDown' then
                        ProcessKeybinding(event.KeyCode, button.Data.template.templateID)
                    end
                    return true
                end
                local oldTextOnDestroy = text.OnDestroy
                text.OnDestroy = function(self)
                    text:AbandonKeyboardFocus()
                    oldTextOnDestroy(self)
                end
            else
                capturingKeys = button.Data.template.templateID
            end
            warningtext = text
            group.SubMenu = CreateSubMenu(group, {text}, function(id)
                TemplatesFactory.SetTemplateKey(button.Data.template.templateID, id)
                RefreshUI()
            end, false)
        end,},
        {label = '<LOC _Send_to>Send to',
        -- menu item disabled but not removed, to be consistent with standard templates menu
        action = function()
            LOG('Send templates disabled')
        end,
        disabledFunc = function()
            return true
        end,},
        {label = '<LOC _Delete>Delete',
        action = function()
            TemplatesFactory.RemoveTemplate(button.Data.template.templateID)
            RefreshUI()
        end,},
    }
    local function CreateItem(data)
        local bg = Bitmap(group)
        bg:SetSolidColor('00000000')
        bg.label = UIUtil.CreateText(bg, LOC(data.label), 12, UIUtil.bodyFont)
        bg.label:DisableHitTest()
        LayoutHelpers.AtLeftTopIn(bg.label, bg, 2)
        bg.Height:Set(function() return bg.label.Height() + 2 end)
        bg.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                self:SetSolidColor('ff777777')
            elseif event.Type == 'MouseExit' then
                self:SetSolidColor('00000000')
            elseif event.Type == 'ButtonPress' then
                if group.SubMenu then
                    group.SubMenu:Destroy()
                    group.SubMenu = false
                end
                data.action()
            end
            return true
        end

        if data.disabledFunc and data.disabledFunc() then
            bg:Disable()
            bg.label:SetColor('ff777777')
        end

        return bg
    end
    local totHeight = 0
    local maxWidth = 0
    title.Height:Set(function() return title:GetFontHeight() end)
    title.Width:Set(function() return title:GetStringAdvance(LOC(button.Data.template.name)) end)
    UIUtil.SetupEditStd(title, "ffffffff", nil, "ffaaffaa", UIUtil.highlightColor, UIUtil.bodyFont, 14, 200)
    title:SetDropShadow(true)
    title:ShowBackground(true)
    title:SetText(LOC(button.Data.template.name))
    LayoutHelpers.AtLeftTopIn(title, group)
    totHeight = totHeight + title.Height()
    maxWidth = math.max(maxWidth, title.Width())
    local itemControls = {}
    local prevControl = false
    for index, actionData in items do
        local i = index
        itemControls[i] = CreateItem(actionData)
        if prevControl then
            LayoutHelpers.Below(itemControls[i], prevControl)
        else
            LayoutHelpers.Below(itemControls[i], title)
        end
        totHeight = totHeight + itemControls[i].Height()
        maxWidth = math.max(maxWidth, itemControls[i].label.Width()+4)
        prevControl = itemControls[i]
    end
    for _, control in itemControls do
        control.Width:Set(maxWidth)
    end
    title.Width:Set(maxWidth)
    group.Height:Set(totHeight)
    group.Width:Set(maxWidth)
    LayoutHelpers.Above(group, button, 10)

    title.HandleEvent = function(self, event)
        Edit.HandleEvent(self, event)
        return true
    end
    title.OnEnterPressed = function(self, text)
        TemplatesFactory.RenameTemplate(button.Data.template.templateID, text)
        RefreshUI()
    end

    local bg = CreateMenuBorder(group)

    group.HandleEvent = function(self, event)
        return true
    end

    return group
    end
