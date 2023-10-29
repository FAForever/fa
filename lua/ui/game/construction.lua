-----------------------------------------------------------------
-- File: lua/modules/ui/game/construction.lua
-- Author: Chris Blackwell / Ted Snook
-- Summary: Construction management UI
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local UIUtil = import("/lua/ui/uiutil.lua")
local DiskGetFileInfo = UIUtil.DiskGetFileInfo
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local SpecialGrid = import("/lua/ui/controls/specialgrid.lua").SpecialGrid
local Checkbox = import("/lua/maui/checkbox.lua").Checkbox
local Button = import("/lua/maui/button.lua").Button
local FixableButton = import("/lua/maui/button.lua").FixableButton
local Edit = import("/lua/maui/edit.lua").Edit
local StatusBar = import("/lua/maui/statusbar.lua").StatusBar
local GameCommon = import("/lua/ui/game/gamecommon.lua")
local GameMain = import("/lua/ui/game/gamemain.lua")
local RadioGroup = import("/lua/maui/mauiutil.lua").RadioGroup
local Tooltip = import("/lua/ui/game/tooltip.lua")
local TooltipInfo = import("/lua/ui/help/tooltips.lua").Tooltips
local Prefs = import("/lua/user/prefs.lua")
local EnhanceCommon = import("/lua/enhancementcommon.lua")
local Templates = import("/lua/ui/game/build_templates.lua")
local BuildMode = import("/lua/ui/game/buildmode.lua")
local UnitViewDetail = import("/lua/ui/game/unitviewdetail.lua")
local options = Prefs.GetFromCurrentProfile('options')
local Effect = import("/lua/maui/effecthelpers.lua")
local TemplatesFactory = import("/lua/ui/templates_factory.lua")
local straticonsfile = import("/lua/ui/game/straticons.lua")
local Select = import("/lua/ui/game/selection.lua")
local Factions = import("/lua/factions.lua").Factions
local FactionInUnitBpToKey = import("/lua/factions.lua").FactionInUnitBpToKey
local SetIgnoreSelection = import("/lua/ui/game/gamemain.lua").SetIgnoreSelection
local EnhancementQueueFile = import("/lua/ui/notify/enhancementqueue.lua")
local getEnhancementQueue = EnhancementQueueFile.getEnhancementQueue

local modifiedCommandQueue = {}
local previousModifiedCommandQueue = {}
local lastDisplayType
local watchingUnit

local prevBuildables = false
local prevSelection = false
local prevBuildCategories = false

-- Flag to indicate if every selected unit is a factory
local allFactories = nil
if options.gui_templates_factory ~= 0 then
    allFactories = false
end

local missingIcons = {}
local dragging = false
local index = nil -- Index of the item in the queue currently being dragged
local originalIndex = false -- Original index of selected item (so that UpdateBuildQueue knows where to modify it from)
local oldQueue = {}
local modifiedQueue = {}
local updateQueue = true -- If false then queue won't update in the ui
local modified = false -- If false then buttonrelease will increase buildcount in queue
local dragLock = false -- To disable quick successive drags, which doubles the units in the queue

-- locals for Keybind labels in build queue
local hotkeyLabel_addLabel = import("/lua/keymap/hotkeylabelsui.lua").addLabel
local idRelations = {}
local upgradeKey = false
local upgradesTo = false
local allowOthers = true

function setIdRelations(idRelations_, upgradeKey_)
    idRelations = idRelations_
    upgradeKey = upgradeKey_
end

function setUpgradeAndAllowing(upgradesTo_, allowOthers_)
    upgradesTo = upgradesTo_
    allowOthers = allowOthers_
end

if options.gui_draggable_queue ~= 0 then
    -- Add gameparent handleevent for if the drag ends outside the queue window
    local gameParent = import("/lua/ui/game/gamemain.lua").GetGameParent()
    local oldGameParentHandleEvent = gameParent.HandleEvent
    gameParent.HandleEvent = function(self, event)
        if event.Type == 'ButtonRelease' then
            import("/lua/ui/game/construction.lua").ButtonReleaseCallback()
        end
        oldGameParentHandleEvent(self, event)
    end
end

local cutA = 0
local cutB = 0
if options.gui_visible_template_names ~= 0 then
    if options.gui_template_name_cutoff ~= nil then
        cutA = options.gui_template_name_cutoff
        cutB = options.gui_template_name_cutoff
    end
    cutA = cutA + 1
    cutB = cutB + 7
end

-- These are external controls used for positioning, so don't add them to our local control table
controlClusterGroup = false
mfdControl = false
ordersControl = false

local capturingKeys = false
local layoutVar = false
local DisplayData = {}
local sortedOptions = {}
local currentCommandQueue = false
local previousTabSet = nil
local previousTabSize = nil
local activeTab = nil
local showBuildIcons = false

controls = import("/lua/ui/controls.lua").Get()
controls.tabs = controls.tabs or {}

local constructionTabs = {'t1', 't2', 't3', 't4', 'templates'}
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
    -- TODO: maybe add some sanity checking?
    local unitStack = currentCommandQueue[unitIndex]
    local blueprint = __blueprints[unitStack.id]

    local tech3 = false
    local supportfactory = false

    if blueprint.CategoriesHash then
        tech3 = blueprint.CategoriesHash.TECH3
        supportfactory = blueprint.CategoriesHash.SUPPORTFACTORY
    end

    if not (tech3 and supportfactory) then
        oldDecreaseBuildCountInQueue(unitIndex, count)
    else
        LOG("Not canceling t3 support factory")
    end
end

function IssueUpgradeOrders(units, bpid)
    local itembp = __blueprints[bpid]
    local upgrades = {}
    local chain = {}
    local from = itembp.General.UpgradesFrom
    local to = bpid

    if not units[1] then return end

    while from and from ~= 'none' and from ~= to do
        table.insert(chain, 1, to)
        upgrades[from] = table.deepcopy(chain)
        to = from
        from = __blueprints[to].General.UpgradesFrom
    end

    local unitid = units[1]:GetUnitId()
    if not upgrades[unitid] then
        return
    end

    for _, o in upgrades[unitid] do
        IssueBlueprintCommand("UNITCOMMAND_Upgrade", o, 1, false)
    end
end

function ResetOrderQueue(factory)
    local queue = SetCurrentFactoryForQueueDisplay(factory)
    if queue then
        SelectUnits({factory})
        for index = table.getn(queue), 1, -1  do
            local count = queue[index].count
            if index == 1 and factory:GetWorkProgress() > 0 then
                count = count - 1
            end
            DecreaseBuildCountInQueue(index, count)
        end
    end
end

function ResetOrderQueues(units)
    local factories = EntityCategoryFilterDown((categories.SHOWQUEUE * categories.STRUCTURE) + categories.FACTORY + categories.EXTERNALFACTORY, units)
    if factories[1] then
        Select.Hidden(function()
            for _, factory in factories do
                ResetOrderQueue(factory)
            end
        end)
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

    -- Do this to prevent errors if the tab is created and destroyed in the same frame
    -- Happens when people double click super fast to select units
    btn.OnDestroy = function(self)
        btn.disabledGroup.Depth:Set(1)
    end
    if onCheckFunc then
        btn.OnCheck = onCheckFunc
    end

    btn.OnClick = function(self)
        if self._checkState ~= 'checked' then
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
    controls.extraBtn1.icon.OnTexture = UIUtil.SkinnableFile('/game/construct-sm_btn/pause_on.dds')
    controls.extraBtn1.icon.OffTexture = UIUtil.SkinnableFile('/game/construct-sm_btn/pause_off.dds')
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

    --controls.extraBtn1:UseAlphaHitTest(true)
    controls.extraBtn2 = Checkbox(controls.minBG)
    controls.extraBtn2.icon = Bitmap(controls.extraBtn2)
    controls.extraBtn2.icon.OnTexture = UIUtil.SkinnableFile('/game/construct-sm_btn/pause_on.dds')
    controls.extraBtn2.icon.OffTexture = UIUtil.SkinnableFile('/game/construct-sm_btn/pause_off.dds')
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

    --controls.extraBtn2:UseAlphaHitTest(true)
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

    -- We need this section so that Hotkey labels are kept properly in line with the elements they are attached to, which are reused rather than recreated
    oldChoicesCalcVisible = controls.choices.CalcVisible
    controls.choices.CalcVisible = function(self)
        for i, item in self.Items do
            if item.hotbuildKeyBg then
                item.hotbuildKeyBg:Destroy()
                item.hotbuildKeyText:Destroy()
            end
        end
        oldChoicesCalcVisible(self)
    end
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
        if tab ~= self then
            tab:SetCheck(false, true)
        end
    end
    controls.choices:Refresh(FormatData(sortedOptions[self.ID], nestedTabKey[self.ID] or self.ID))
    SetSecondaryDisplay('buildQueue')
end

function CreateTabs(type)
    local defaultTabOrder = {}
    local desiredTabs = 0
    -- Construction tab, this is called before fac templates have been added
    if type == 'construction' and allFactories and options.gui_templates_factory ~= 0 then
        -- nil value would cause refresh issues if templates tab is currently selected
        sortedOptions.templates = {}

        -- Prevent tab autoselection when in templates tab,
        -- Normally triggered when number of active tabs has changed (fac upgrade added/removed from queue)
        local templatesTab = GetTabByID('templates')
        if templatesTab and templatesTab:IsChecked() then
            local numActive = 0
            for _, tab in controls.tabs do
                if sortedOptions[tab.ID] and not table.empty(sortedOptions[tab.ID]) then
                    if tab.ID != 'templates' then
                        numActive = numActive + 1
                    end
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
            Tooltip.AddControlTooltip(controls.tabs[i], 'construction_tab_' .. tab)
            Tooltip.AddControlTooltip(controls.tabs[i].disabledGroup, 'construction_tab_' .. tab .. '_dis')
        end
        desiredTabs = table.getsize(constructionTabs)
        defaultTabOrder = {t3 = 1, t2 = 2, t1 = 3, t4 = 4} -- T4 is last because only the Novax can build T4 but not T3
    elseif type == 'enhancement' then
        local selection = sortedOptions.selection
        local enhancements = selection[1]:GetBlueprint().Enhancements
        local enhCommon = import("/lua/enhancementcommon.lua")
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
                            local texture = "/textures/ui/common" .. GetEnhancementPrefix(bpID, enhancementPrefixes[slotName] .. icon)
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
        defaultTabOrder = {Back = 1, LCH = 2, RCH = 3}
    elseif type == 'selection' then
        activeTab = nil
    end

    while table.getsize(controls.tabs) > desiredTabs do
        controls.tabs[table.getsize(controls.tabs)]:Destroy()
        controls.tabs[table.getsize(controls.tabs)] = nil
    end

    import(UIUtil.GetLayoutFilename('construction')).LayoutTabs(controls)
    local defaultTab = false
    local numActive = 0
    for _, tab in controls.tabs do
        if sortedOptions[tab.ID] and not table.empty(sortedOptions[tab.ID]) then
            tab:Enable()

            if tab.ID != 'templates' then
                numActive = numActive + 1
            end

            if defaultTabOrder[tab.ID] then
                if not defaultTab or defaultTabOrder[tab.ID] < defaultTabOrder[defaultTab.ID] then
                    defaultTab = tab
                end
            end
        else
            tab:Disable()
        end
    end

    if previousTabSet ~= type or previousTabSize ~= numActive then
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
    local icon = "land"
    if unitID and unitID ~= 'default' then
        if not validIcons[bp.General.Icon] then
            if bp.General.Icon then WARN(debug.traceback(nil, "Invalid icon" .. bp.General.Icon .. " for unit " .. tostring(unitID))) end
            bp.General.Icon = "land"
        else
            icon = bp.General.Icon
        end
    end

    return UIUtil.UIFile('/icons/units/' .. icon .. '_up.dds'),
           UIUtil.UIFile('/icons/units/' .. icon .. '_down.dds'),
           UIUtil.UIFile('/icons/units/' .. icon .. '_over.dds'),
           UIUtil.UIFile('/icons/units/' .. icon .. '_up.dds')
end

function GetEnhancementPrefix(unitID, iconID)
    local prefix = ''
    if string.sub(unitID, 2, 2) == 'a' then
        prefix = '/game/aeon-enhancements/' .. iconID
    elseif string.sub(unitID, 2, 2) == 'e' then
        prefix = '/game/uef-enhancements/' .. iconID
    elseif string.sub(unitID, 2, 2) == 'r' then
        prefix = '/game/cybran-enhancements/' .. iconID
    elseif string.sub(unitID, 2, 2) == 's' then
        prefix = '/game/seraphim-enhancements/' .. iconID
    end
    return prefix
end

function GetEnhancementTextures(unitID, iconID)
    local prefix = GetEnhancementPrefix(unitID, iconID)
    return UIUtil.UIFile(prefix .. '_btn_up.dds', true),
    UIUtil.UIFile(prefix .. '_btn_down.dds', true),
    UIUtil.UIFile(prefix .. '_btn_over.dds', true),
    UIUtil.UIFile(prefix .. '_btn_up.dds', true),
    UIUtil.UIFile(prefix .. '_btn_sel.dds', true)
end

function CommonLogic()
    controls.choices:SetupScrollControls(controls.scrollMin, controls.scrollMax, controls.pageMin, controls.pageMax)
    controls.secondaryChoices:SetupScrollControls(controls.secondaryScrollMin, controls.secondaryScrollMax, controls.secondaryPageMin, controls.secondaryPageMax)

    controls.secondaryProgress:SetNeedsFrameUpdate(true)
    controls.secondaryProgress.OnFrame = function(self, delta)
        local frontOfQueue = sortedOptions.selection[1]
        if not frontOfQueue or frontOfQueue:IsDead() then
            return
        end

        controls.secondaryProgress:SetValue(frontOfQueue:GetWorkProgress() or 0)
        if controls.secondaryChoices.top == 1 and not controls.selectionTab:IsChecked() and not controls.constructionGroup:IsHidden() then
            self:SetAlpha(1, true)
        else
            self:SetAlpha(0, true)
        end
    end

    controls.secondaryChoices.SetControlToType = function(control, type)
        local function SetIconTextures(control)
            if DiskGetFileInfo(UIUtil.UIFile('/icons/units/' .. control.Data.id .. '_icon.dds', true)) then
                control.Icon:SetTexture(UIUtil.UIFile('/icons/units/' .. control.Data.id .. '_icon.dds', true))
            else
                control.Icon:SetTexture(UIUtil.UIFile('/icons/units/default_icon.dds'))
            end
            if __blueprints[control.Data.id].StrategicIconName then
                local iconName = __blueprints[control.Data.id].StrategicIconName
                if DiskGetFileInfo('/textures/ui/common/game/strategicicons/' .. iconName .. '_rest.dds') then
                    control.StratIcon:SetTexture('/textures/ui/common/game/strategicicons/' .. iconName .. '_rest.dds')
                    LayoutHelpers.SetDimensions(control.StratIcon, control.StratIcon.BitmapWidth(), control.StratIcon.BitmapHeight())
                    --control.StratIcon.Height:Set(control.StratIcon.BitmapHeight)
                    --control.StratIcon.Width:Set(control.StratIcon.BitmapWidth)
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
                LayoutHelpers.SetDimensions(control, 48, 20)
                --control.Width:Set(48)
                --control.Height:Set(20)
            else
                control.Icon:SetTexture(UIUtil.UIFile('/game/c-q-e-panel/divider_bmp.dds'))
                LayoutHelpers.SetDimensions(control, 20, 48)
                --control.Width:Set(20)
                --control.Height:Set(48)
            end
            LayoutHelpers.SetDimensions(control.Icon, control.Icon.BitmapWidth(), control.Icon.BitmapHeight())
            --control.Icon.Width:Set(control.Icon.BitmapWidth)
            --control.Icon.Height:Set(control.Icon.BitmapHeight)
            control.Count:SetText('')
            control:Disable()
            control.StratIcon:SetSolidColor('00000000')
            control:SetSolidColor('00000000')
            control.BuildKey = nil
        elseif type == 'queuestack' or type == 'attachedunit' then
            SetIconTextures(control)
            local up, down, over, dis = GetBackgroundTextures(control.Data.id)
            control:SetNewTextures(up, down, over, dis)
            control:SetOverrideTexture(down)
            control.tooltipID = LOC(__blueprints[control.Data.id].Description) or 'no description'
            control:DisableOverride()
            LayoutHelpers.SetDimensions(control, 48, 48)
            --control.Height:Set(48)
            --control.Width:Set(48)
            LayoutHelpers.SetDimensions(control.Icon, 48, 48)
            --control.Icon.Height:Set(48)
            --control.Icon.Width:Set(48)
            control.BuildKey = nil
            if control.Data.count > 1 then
                control.Count:SetText(control.Data.count)
                control.Count:SetColor('ffffffff')
            else
                control.Count:SetText('')
            end
            control.Icon:Show()
            control:Enable()
        elseif type == 'enhancementqueue' then
            local data = control.Data
            local _, down, over, _, up = GetEnhancementTextures(data.unitID, data.icon)

            control:SetSolidColor('00000000')
            control.Icon:SetSolidColor('00000000')
            control.tooltipID = data.name
            control:SetNewTextures(GetEnhancementTextures(data.unitID, data.icon))
            LayoutHelpers.SetDimensions(control, 48, 48)
            --control.Height:Set(48)
            --control.Width:Set(48)
            LayoutHelpers.SetDimensions(control.Icon, 48, 48)
            --control.Icon.Height:Set(48)
            --control.Icon.Width:Set(48)
            control.StratIcon:SetSolidColor('00000000')
            control.Count:SetText('')

            if control.SetOverrideTexture then
                control:SetOverrideTexture(up)
            else
                control:SetUpAltButtons(up, up, up, up)
            end

            control:Disable()
            control.Icon:Show()
            control:Enable()
        end
    end

    controls.secondaryChoices.CreateElement = function()
        local btn = FixableButton(controls.choices)

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
        local btn = FixableButton(controls.choices)

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

    local key = nil
    local id = nil

    controls.choices.SetControlToType = function(control, type)
        local function SetIconTextures(control, optID)
            local id = optID or control.Data.id
            if DiskGetFileInfo(UIUtil.UIFile('/icons/units/' .. id .. '_icon.dds', true)) then
                control.Icon:SetTexture(UIUtil.UIFile('/icons/units/' .. id .. '_icon.dds', true))
            else
                control.Icon:SetTexture(UIUtil.UIFile('/icons/units/default_icon.dds'))
            end
            if __blueprints[id].StrategicIconName then
                local iconName = __blueprints[id].StrategicIconName
                if DiskGetFileInfo('/textures/ui/common/game/strategicicons/' .. iconName .. '_rest.dds') then
                    control.StratIcon:SetTexture('/textures/ui/common/game/strategicicons/' .. iconName .. '_rest.dds')
                    LayoutHelpers.SetDimensions(control.StratIcon, control.StratIcon.BitmapWidth(), control.StratIcon.BitmapHeight())
                    --control.StratIcon.Height:Set(control.StratIcon.BitmapHeight)
                    --control.StratIcon.Width:Set(control.StratIcon.BitmapWidth)
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
                LayoutHelpers.SetDimensions(control, 48, 20)
                --control.Width:Set(48)
                --control.Height:Set(20)
            else
                control.Icon:SetTexture(UIUtil.UIFile('/game/c-q-e-panel/arrow_bmp.dds'))
                LayoutHelpers.SetDimensions(control, 20, 48)
                --control.Width:Set(20)
                --control.Height:Set(48)
            end
            control.Icon.Depth:Set(function() return control.Depth() + 5 end)
            LayoutHelpers.SetDimensions(control.Icon, 30, control.Icon.BitmapHeight())
            --control.Icon.Height:Set(control.Icon.BitmapHeight)
            --control.Icon.Width:Set(30)
            control.Icon:Show()
            control.StratIcon:SetSolidColor('00000000')
            control.StratIcon:Hide()
            control.LowFuel:SetAlpha(0, true)
            control.LowFuel:SetNeedsFrameUpdate(false)
            control.BuildKey = nil
        elseif type == 'spacer' then
            if controls.choices._vertical then
                control.Icon:SetTexture(UIUtil.UIFile('/game/c-q-e-panel/divider_horizontal_bmp.dds'))
                LayoutHelpers.SetDimensions(control, 48, 20)
                --control.Width:Set(48)
                --control.Height:Set(20)
            else
                control.Icon:SetTexture(UIUtil.UIFile('/game/c-q-e-panel/divider_bmp.dds'))
                LayoutHelpers.SetDimensions(control, 20, 48)
                --control.Width:Set(20)
                --control.Height:Set(48)
            end
            LayoutHelpers.SetDimensions(control.Icon, control.Icon.BitmapWidth(), control.Icon.BitmapHeight())
            --control.Icon.Width:Set(control.Icon.BitmapWidth)
            --control.Icon.Height:Set(control.Icon.BitmapHeight)
            control.Count:SetText('')
            control:Disable()
            control.StratIcon:SetSolidColor('00000000')
            control:SetSolidColor('00000000')
            control.LowFuel:SetAlpha(0, true)
            control.LowFuel:SetNeedsFrameUpdate(false)
            control.BuildKey = nil
        elseif type == 'enhancement' then
            control.Icon:SetSolidColor('00000000')
            local up, down, over, _, selected = GetEnhancementTextures(control.Data.unitID, control.Data.icon)
            control:SetNewTextures(up, down, over, up)
            control:SetOverrideTexture(selected)
            control.tooltipID = LOC(control.Data.enhTable.Name) or 'no description'
            control:SetOverrideEnabled(control.Data.Selected)
            LayoutHelpers.SetDimensions(control, 48, 48)
            --control.Height:Set(48)
            --control.Width:Set(48)
            LayoutHelpers.SetDimensions(control.Icon, 48, 48)
            --control.Icon.Height:Set(48)
            --control.Icon.Width:Set(48)
            control.Icon.Depth:Set(function() return control.Depth() + 1 end)
            control.Count:SetText('')
            control.StratIcon:SetSolidColor('00000000')
            control.LowFuel:SetAlpha(0, true)
            control.LowFuel:SetNeedsFrameUpdate(false)
            control.BuildKey = nil
            if control.Data.Disabled then
                control:Enable()
                control.Data.TooltipOnly = true
                if not control.Data.Selected then
                    control.Icon:SetSolidColor('aa000000')
                end
            else
                control.Data.TooltipOnly = false
                control:Enable()
            end
        elseif type == 'templates' then
            control:DisableOverride()
            SetIconTextures(control, control.Data.template.icon)
            control:SetNewTextures(GetBackgroundTextures(control.Data.template.icon))
            LayoutHelpers.SetDimensions(control, 48, 48)
            --control.Height:Set(48)
            --control.Width:Set(48)
            if control.Data.template.icon then
                control.Icon:SetTexture(UIUtil.UIFile('/icons/units/' .. control.Data.template.icon .. '_icon.dds', true))
            else
                control.Icon:SetTexture('/textures/ui/common/icons/units/default_icon.dds')
            end
            LayoutHelpers.SetDimensions(control.Icon, 48, 48)
            --control.Icon.Height:Set(48)
            --control.Icon.Width:Set(48)
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
            control.LowFuel:SetNeedsFrameUpdate(false)
        elseif type == 'item' then
            local id = control.Data.id
            SetIconTextures(control)
            control:SetNewTextures(GetBackgroundTextures(id))
            local _, down = GetBackgroundTextures(id)
            control.tooltipID = LOC(__blueprints[id].Description) or 'no description'
            control:SetOverrideTexture(down)
            control:DisableOverride()
            LayoutHelpers.SetDimensions(control, 48, 48)
            --control.Height:Set(48)
            --control.Width:Set(48)
            LayoutHelpers.SetDimensions(control.Icon, 48, 48)
            --control.Icon.Height:Set(48)
            --control.Icon.Width:Set(48)
            control.Icon.Depth:Set(function() return control.Depth() + 1 end)
            control.BuildKey = nil
            if showBuildIcons then
                local unitBuildKeys = BuildMode.GetUnitKeys(sortedOptions.selection[1]:GetBlueprint().BlueprintId, GetCurrentTechTab())
                control.Count:SetText(unitBuildKeys[id] or '')
                control.Count:SetColor('ffff9000')
            else
                control.Count:SetText('')
            end
            control.Icon:Show()
            control:Enable()
            control.LowFuel:SetAlpha(0, true)
            control.LowFuel:SetNeedsFrameUpdate(false)

            if id == upgradesTo and upgradeKey then
                hotkeyLabel_addLabel(control, control.Icon, upgradeKey)
            elseif allowOthers or upgradesTo == nil then
                local key = idRelations[id]
                if key then
                    hotkeyLabel_addLabel(control, control.Icon, key)
                end
            end
        elseif type == 'unitstack' then
            SetIconTextures(control)
            control:SetNewTextures(GetBackgroundTextures(control.Data.id))
            control.tooltipID = LOC(__blueprints[control.Data.id].Description) or 'no description'
            control:DisableOverride()
            LayoutHelpers.SetDimensions(control, 48, 48)
            --control.Height:Set(48)
            --control.Width:Set(48)
            LayoutHelpers.SetDimensions(control.Icon, 48, 48)
            --control.Icon.Height:Set(48)
            --control.Icon.Width:Set(48)
            control.LowFuel:SetAlpha(0, true)
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
    if options.gui_bigger_strat_build_icons ~= 0 then
        local oldSecondary = controls.secondaryChoices.SetControlToType
        local oldPrimary = controls.choices.SetControlToType
        -- Add idle icon to buttons
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
        -- Add idle icon to buttons
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

    if options.gui_visible_template_names ~= 0 then
        local oldSecondary = controls.secondaryChoices.SetControlToType
        local oldPrimary = controls.choices.SetControlToType
        local oldPrimaryCreate = controls.choices.CreateElement
        controls.choices.CreateElement = function()
            local btn = oldPrimaryCreate()
            -- Create the display area
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
            -- The text
            if type == 'templates' and 'templates' then
                control.Tmplnm.Width:Set(48)
                if STR_Utf8Len(control.Data.template.name) >= cutA then
                    control.Tmplnm:SetText(STR_Utf8SubString(control.Data.template.name, cutA, cutB))
                end
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

        if iconConversion and DiskGetFileInfo('/textures/ui/icons_strategic/' .. iconConversion .. '.dds') then
            control.StratIcon:SetTexture('/textures/ui/icons_strategic/' .. iconConversion .. '.dds')
            LayoutHelpers.SetDimensions(control.StratIcon, control.StratIcon.BitmapWidth(), control.StratIcon.BitmapHeight())
            LayoutHelpers.AtTopIn(control.StratIcon, control.Icon, 1)
            LayoutHelpers.AtRightIn(control.StratIcon, control.Icon, 1)
            LayoutHelpers.ResetBottom(control.StratIcon)
            LayoutHelpers.ResetLeft(control.StratIcon)
            control.StratIcon:SetAlpha(0.8)
        elseif not missingIcons[iconName] then
            missingIcons[iconName] = true
            LOG('Strat Icon Mod Error: updated strat icon required for: ', iconName)
        end
    end
end

function OnRolloverHandler(button, state)
    local item = button.Data

    if options.gui_draggable_queue ~= 0 and item.type == 'queuestack' and prevSelection and EntityCategoryContains(categories.FACTORY + categories.EXTERNALFACTORY, prevSelection[1]) then
        if state == 'enter' then
            button.oldHandleEvent = button.HandleEvent
            -- If we have entered the button and are dragging something then we want to replace it with what we are dragging
            if dragging == true then
                -- Move item from old location (index) to new location (this button's index)
                MoveItemInQueue(currentCommandQueue, index, item.position)
                -- Since the currently selected button has now moved, update the index
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
                            -- Left button pressed so start dragging procedure
                            dragging = true
                            index = item.position
                            originalIndex = index

                            self.dragMarker = Bitmap(self, '/textures/ui/queuedragger.dds')
                            LayoutHelpers.FillParent(self.dragMarker, self)
                            self.dragMarker:DisableHitTest()
                            Effect.Pulse(self.dragMarker, 1.5, 0.6, 0.8)

                            -- Copy un modified queue so that current build order is recorded (for deleting it)
                            oldQueue = table.copy(currentCommandQueue)
                        end
                    else
                        PlaySound(Sound({Cue = "UI_MFD_Click", Bank = "Interface"}))
                        DecreaseBuildCountInQueue(item.position, count)
                    end
                elseif event.Type == 'ButtonRelease' then
                    if dragging then
                        -- If queue has changed then update queue, else increase build count (like default)
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
                            RefreshUI()
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
        end
    end

    if state == 'enter' then
        if item.type == 'item' then
            UnitViewDetail.Show(__blueprints[item.id], sortedOptions.selection[1], item.id)
        elseif item.type == 'queuestack' or item.type == 'unitstack' or item.type == 'attachedunit' then
            UnitViewDetail.Show(__blueprints[item.id], nil, item.id)
        elseif item.type == 'enhancement' then
            UnitViewDetail.ShowEnhancement(item.enhTable, item.unitID, item.icon, GetEnhancementPrefix(item.unitID, item.icon), sortedOptions.selection[1])
        elseif item.type == 'enhancementqueue' then
            UnitViewDetail.ShowEnhancement(item.enhancement, item.unitID, item.icon, GetEnhancementPrefix(item.unitID, item.icon), sortedOptions.selection[1])
        end
    else
        UnitViewDetail.Hide()
    end
end

function watchForQueueChange(unit)
    if watchingUnit == unit then
        return
    end

    updateQueue = false
    watchingUnit = unit
    ForkThread(function()
        local threadWatchingUnit = watchingUnit
        while unit:GetCommandQueue()[1].type ~= 'Script' do
            WaitSeconds(0.2)
        end

        local selection = GetSelectedUnits() or {}
        if lastDisplayType and table.getn(selection) == 1 and threadWatchingUnit == watchingUnit and selection[1] == threadWatchingUnit then
            SetSecondaryDisplay(lastDisplayType)
        end
        watchingUnit = nil
    end)
end

function checkBadClean(unit)
    local enhancementQueue = getEnhancementQueue()
    local queue = enhancementQueue[unit:GetEntityId()]

    return previousModifiedCommandQueue[1].type == 'enhancementqueue' and queue and queue[1] and not string.find(queue[1].ID, 'Remove')
end

--- Returns an array of enhancement prerequisites
---@param enh UnitBlueprintEnhancement
---@return Enhancement[] | nil
function GetPrerequisites(enh)
    local prereq = enh.Prerequisite
    if not prereq then
        return
    end
    local prereqs = {}
    local unitEnhancements = __blueprints[enh.UnitID].Enhancements
    repeat
        table.insert(prereqs, prereq)
        prereq = unitEnhancements[prereq].Prerequisite
    until not prereq
    -- put the enhancement base at index 1
    local n = table.getn(prereqs)
    for k = 1, n / 2 do
        prereqs[k], prereqs[n - k + 1] = prereqs[n - k + 1], prereqs[k]
    end
    return prereqs
end

function OrderEnhancement(item, clean, destroy)
    local units = sortedOptions.selection
    if table.empty(units) then
        return
    end

    local slot = item.enhTable.Slot
    local enhId = item.id
    local prereqs = GetPrerequisites(item.enhTable)
    local enhancementQueue = getEnhancementQueue()
    SetIgnoreSelection(true)

    for _, unit in units do
        local entityId = unit:GetEntityId()
        if clean and not EnhancementQueueFile.currentlyUpgrading(unit) then
            enhancementQueue[entityId] = {}
        end

        local existingEnh = EnhanceCommon.GetEnhancements(entityId)[slot]
        if existingEnh == enhId then
            continue
        end

        local doOrder = true
        local removeAlreadyOrdered = false
        local highestPrereqIndex = table.find(prereqs, existingEnh) or 0
        if enhancementQueue[entityId] then
            for _, enhancement in enhancementQueue[entityId] do
                if enhancement.Slot ~= slot then
                    continue
                end

                local queuedEnhId = enhancement.ID
                local prereqIndex = table.find(prereqs, queuedEnhId)
                if prereqIndex then
                    if prereqIndex > highestPrereqIndex then
                        highestPrereqIndex = prereqIndex
                    end
                elseif existingEnh and queuedEnhId == existingEnh .. 'Remove' then
                    removeAlreadyOrdered = true
                elseif queuedEnhId == enhId then
                    doOrder = false
                    break
                end
            end
        end
        if not doOrder then
            continue
        end

        local orders = {}
        if not removeAlreadyOrdered and existingEnh and not table.find(prereqs, existingEnh) then
            -- user selected "No" to replacing the enhancement
            if not destroy then
                continue
            end

            table.insert(orders, existingEnh .. 'Remove')
        end
        if prereqs then
            for k = highestPrereqIndex + 1, table.getn(prereqs) do
                table.insert(orders, prereqs[k])
            end
        end
        table.insert(orders, item.id)


        local cleanOrder = clean
        if cleanOrder and not unit:IsIdle() and unit:GetCommandQueue()[1].type == 'Script' then
            cleanOrder = false
        end

        local unitSel = {unit}
        SelectUnits(unitSel)
        for _, order in orders do
            orderTable = {TaskName = 'EnhanceTask', Enhancement = order}
            IssueCommand("UNITCOMMAND_Script", orderTable, cleanOrder)
            if cleanOrder then
                cleanOrder = false
            end
        end

        if unit:IsInCategory('COMMAND') then
            local _, _, buildableCategories = GetUnitCommandData(unitSel)
            OnSelection(buildableCategories, unitSel, true)
        end
    end

    SelectUnits(units)
    SetIgnoreSelection(false)

    controls.choices:Refresh(FormatData(sortedOptions[slot], slot))
end

function OnClickHandler(button, modifiers)
    PlaySound(Sound({Cue = "UI_MFD_Click", Bank = "Interface"}))
    local item = button.Data

    if options.gui_improved_unit_deselection ~= 0 then
        -- Improved unit deselection -ghaleon
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
                else -- Default right-click behavior
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

                return
            end
        end
    end

    if item.type == "templates" and allFactories then

        if modifiers.Right then
            -- Options menu
            if button.OptionMenu then
                button.OptionMenu:Destroy()
                button.OptionMenu = nil
            else
                button.OptionMenu = CreateFacTemplateOptionsMenu(button)
            end
            for _, otherBtn in controls.choices.Items do
                if button ~= otherBtn and otherBtn.OptionMenu then
                    otherBtn.OptionMenu:Destroy()
                    otherBtn.OptionMenu = false
                end
            end
        else
            -- Add template to build queue
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
        local itembp = __blueprints[item.id]
        local count = 1
        local performUpgrade = false
        local buildCmd = "build"

        if modifiers.Ctrl or modifiers.Shift then
            count = 5
        end

        if modifiers.Left then
            -- See if we are issuing an upgrade order
            if itembp.General.UpgradesFrom == 'none' then
                performUpgrade = false
            else
                for i, v in sortedOptions.selection do
                    if v then -- Its possible that your unit will have died by the time this gets to it
                        local unitBp = v:GetBlueprint()
                        if itembp.General.UpgradesFrom == unitBp.BlueprintId then
                            performUpgrade = true
                        elseif itembp.General.UpgradesFrom == unitBp.General.UpgradesTo then
                            performUpgrade = true
                        elseif itembp.General.UpgradesFromBase ~= "none" then
                            -- Try testing against the base
                            if itembp.General.UpgradesFromBase == unitBp.BlueprintId then
                                performUpgrade = true
                            elseif itembp.General.UpgradesFromBase == unitBp.General.UpgradesFromBase then
                                performUpgrade = true
                            end
                        end
                    end
                end
            end

            -- Hold alt to reset queue, same as hotbuild
            if modifiers.Alt then
                ResetOrderQueues(sortedOptions.selection)
            end

            if performUpgrade then
                IssueUpgradeOrders(sortedOptions.selection, item.id)
            else
                if itembp.Physics.MotionType == 'RULEUMT_None' or EntityCategoryContains(categories.NEEDMOBILEBUILD, item.id) then
                    -- Stationary means it needs to be placed, so go in to build mobile mode
                    import("/lua/ui/game/commandmode.lua").StartCommandMode(buildCmd, {name = item.id})
                else
                    -- If the item to build can move, it must be built by a factory
                    -- Mobile factories: we check for platforms (the attached units can be given orders as normal)
                    -- If we've got platforms, we take our selected units (minus the platforms), then add the
                    -- external factories to that list, then give orders with 
                    -- IssueBlueprintCommandToUnits (which can give orders to an arbitrary list of units)
                    -- instead of IssueBlueprintCommand (which gives orders to the current selection)
                    local selection = GetSelectedUnits()
                    local exFacs = EntityCategoryFilterDown(categories.EXTERNALFACTORY, selection)
                    if not table.empty(exFacs) then
                        local exFacUnits = EntityCategoryFilterOut(categories.EXTERNALFACTORY, selection)
                        for _, exFac in exFacs do
                            table.insert(exFacUnits, exFac:GetCreator())
                        end
                        -- in case we've somehow selected both the platform and the factory, only put the fac in once
                        exFacUnits = table.unique(exFacUnits)
                        IssueBlueprintCommandToUnits(exFacUnits, "UNITCOMMAND_BuildFactory", item.id, count)
                    else
                        IssueBlueprintCommand("UNITCOMMAND_BuildFactory", item.id, count)
                    end
                end
            end
        else
            local unitIndex = false
            for index, unitStack in currentCommandQueue or {} do
                if unitStack.id == item.id then
                    unitIndex = index
                end
            end
            if unitIndex ~= false then
                DecreaseBuildCountInQueue(unitIndex, count)
            end
        end
        RefreshUI()
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
            button:ToggleOverride()

            -- Add or Remove the entity to the session selection
            if button:GetOverrideEnabled() then
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
                if button ~= otherBtn and otherBtn.OptionMenu then
                    otherBtn.OptionMenu:Destroy()
                    otherBtn.OptionMenu = false
                end
            end
        else
            import("/lua/ui/game/commandmode.lua").StartCommandMode('build', {name = item.template.templateData[3][1]})
            SetActiveBuildTemplate(item.template.templateData)
        end

    elseif item.type == 'enhancement' and button.Data.TooltipOnly == false then
        local doOrder = true
        local clean = not modifiers.Shift
        local enhancementQueue = getEnhancementQueue()

        local enhId = item.id
        local enh = item.enhTable
        local slot = enh.Slot
        local prereqs = GetPrerequisites(enh)
        for _, unit in sortedOptions.selection do
            local unitId = unit:GetEntityId()
            local existingEnhancements = EnhanceCommon.GetEnhancements(unitId)
            local existingEnh = existingEnhancements[slot]
            if not existingEnh or table.find(prereqs, existingEnh) then
                continue
            end

            local alreadyWarned = false
            for _, enhancement in enhancementQueue[unitId] or {} do
                if enhancement.ID == existingEnh .. 'Remove' then
                    alreadyWarned = true
                    break
                end
            end
            if alreadyWarned then
                continue
            end

            if existingEnh ~= enhId then
                UIUtil.QuickDialog(GetFrame(0), "<LOC enhancedlg_0000>Choosing this enhancement will destroy the existing enhancement in this slot.  Are you sure?",
                    "<LOC _Yes>", function()
                        safecall("OrderEnhancement", OrderEnhancement, item, clean, true)
                    end,
                    "<LOC _No>", function()
                        safecall("OrderEnhancement", OrderEnhancement, item, clean, false)
                    end,
                    nil, nil,
                    true,  {worldCover = true, enterButton = 1, escapeButton = 2}
                )
                doOrder = false
                break
            end
        end

        if doOrder then
            OrderEnhancement(item, clean, false)
        end
    elseif item.type == 'queuestack' then
        local count = 1
        if modifiers.Shift or modifiers.Ctrl then
            count = 5
        end

        if modifiers.Left then
            IncreaseBuildCountInQueue(item.position, count)
            
        elseif modifiers.Right then
            DecreaseBuildCountInQueue(item.position, count)
        end
        RefreshUI()
    end
end

local warningtext = false
function ProcessKeybinding(key, templateID)
    local templateObject
    if allFactories then
        templateObject = TemplatesFactory
    else
        templateObject = Templates
    end

    if key == UIUtil.VK_ESCAPE then
        templateObject.ClearTemplateKey(capturingKeys or templateID)
        RefreshUI()
    elseif key == string.byte('b') or key == string.byte('B') then
        warningtext:SetText(LOC("<LOC CONSTRUCT_0005>Key must not be b!"))
    else
        if (key >= string.byte('A') and key <= string.byte('Z')) or (key >= string.byte('a') and key <= string.byte('z')) then
            if (key >= string.byte('a') and key <= string.byte('z')) then
                key = string.byte(string.upper(string.char(key)))
            end
            if templateObject.SetTemplateKey(capturingKeys or templateID, key) then
                RefreshUI()
            else
                warningtext:SetText(LOCF("<LOC CONSTRUCT_0006>%s is already used!", string.char(key)))
            end
        else
            warningtext:SetText(LOC("<LOC CONSTRUCT_0007>Key must be a-z!"))
        end
    end
end

function CreateTemplateOptionMenu(button, templateObj)
    local group = Group(button)
    group.Depth:Set(button:GetRootFrame():GetTopmostDepth() + 1)
    local title = Edit(group)

    -- Closure copy
    local templates = templateObj
    local btn = button
    local theTemplate = btn.Data.template

    local items = {
        {
            label = '<LOC _Rename>Rename',
            action = function()
                title:AcquireFocus()
            end
        },
        {
            label = '<LOC _Change_Icon>Change Icon',
            arrow = true,
            action = function()
                local contents = {}
                local controls = {}
                for _, entry in theTemplate.templateData do
                    if type(entry) == 'table' then
                        contents[entry.id or entry[1]] = true
                    end
                end
                for iconType, _ in contents do
                    local bmp = Bitmap(group, UIUtil.UIFile('/icons/units/' .. iconType .. '_icon.dds', true))
                    LayoutHelpers.SetDimensions(bmp, 30, 30)
                    --bmp.Height:Set(30)
                    --bmp.Width:Set(30)
                    bmp.ID = iconType
                    table.insert(controls, bmp)
                end
                group.SubMenu = CreateSubMenu(group, controls, function(id)
                    templates.SetTemplateIcon(theTemplate.templateID, id)
                    RefreshUI()
                end)
            end
        },
        {
            label = '<LOC _Change_Keybinding>Change Keybinding',
            action = function()
                local text = UIUtil.CreateText(group, "<LOC CONSTRUCT_0008>Press a key to bind", 12, UIUtil.bodyFont)
                if not BuildMode.IsInBuildMode() then
                    text:AcquireKeyboardFocus(false)
                    text.HandleEvent = function(self, event)
                        if event.Type == 'KeyDown' then
                            ProcessKeybinding(event.KeyCode, theTemplate.templateID)
                        end
                        return true
                    end
                    local oldTextOnDestroy = text.OnDestroy
                    text.OnDestroy = function(self)
                        text:AbandonKeyboardFocus()
                        oldTextOnDestroy(self)
                    end
                else
                    capturingKeys = theTemplate.templateID
                end
                warningtext = text
                group.SubMenu = CreateSubMenu(group, {text}, function(id)
                    templates.SetTemplateKey(theTemplate.templateID, id)
                    RefreshUI()
                end, false)
            end
        },
        {
            label = '<LOC _Send_to>Send to',
            arrow = true,
            action = function()
                local armies = GetArmiesTable().armiesTable
                local entries = {}
                for i, armyData in armies do
                    if i ~= GetFocusArmy() and armyData.human then
                        local entry = UIUtil.CreateText(group, armyData.nickname, 12, UIUtil.bodyFont)
                        entry.ID = i
                        table.insert(entries, entry)
                    end
                end
                if not table.empty(entries) then
                    group.SubMenu = CreateSubMenu(group, entries, function(id)
                        templates.SendTemplate(theTemplate.templateID, id)
                        RefreshUI()
                    end)
                end
            end,
            disabledFunc = function()
                return table.getsize(GetSessionClients()) <= 1
            end
        },
        {
            label = '<LOC _Delete>Delete',
            action = function()
                templates.RemoveTemplate(theTemplate.templateID)
                RefreshUI()
            end
        }
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
        maxWidth = math.max(maxWidth, itemControls[i].label.Width() + 4)
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
        templates.RenameTemplate(button.Data.template.templateID, text)
        RefreshUI()
    end

    UIUtil.SurroundWithNinePatch(group, "/game/chat_brd/", 4, 4)

    group.HandleEvent = function(self, event)
        return true
    end

    return group
end

function CreateTemplateOptionsMenu(button)
    return CreateTemplateOptionMenu(button, Templates)
end

function CreateFacTemplateOptionsMenu(button)
    return CreateTemplateOptionMenu(button, TemplatesFactory)
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
            LayoutHelpers.Below(control, contents[i - 1])
        end
        if setupOnClickHandler ~= false then
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
    UIUtil.SurroundWithNinePatch(menu, "/game/chat_brd/", 4, 4)

    return menu
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

function ToggleUnitPauseAll()
    if controls.selectionTab:IsChecked() or controls.constructionTab:IsChecked() then
        controls.extraBtn2:ToggleCheck(false)
    else
        SetPaused(sortedOptions.selection, true)
    end
end

function ToggleUnitUnpauseAll()
    if controls.selectionTab:IsChecked() or controls.constructionTab:IsChecked() then
        controls.extraBtn2:OnCheck(true)
    else
        SetPaused(sortedOptions.selection, false)
    end
end

function CreateExtraControls(controlType)
    local SetupPauseButton = function()
        Tooltip.AddCheckboxTooltip(controls.extraBtn2, 'construction_pause')
        controls.extraBtn2.OnCheck = function(self, checked)
            SetPaused(sortedOptions.selection, checked)
            -- If we have exFacs platforms or exFac units selected, we'll pause their counterparts as well
            for _, exFac in EntityCategoryFilterDown(categories.EXTERNALFACTORY + categories.EXTERNALFACTORYUNIT, sortedOptions.selection) do
                exFac:GetCreator():ProcessInfo('SetPaused', tostring(checked))
            end
        end
        if pauseEnabled then
            controls.extraBtn2:Enable()
        else
            controls.extraBtn2:Disable()
        end
        controls.extraBtn2:SetCheck(GetIsPaused(sortedOptions.selection), true)
    end

    if controlType == 'construction' or controlType == 'templates' then
        Tooltip.AddCheckboxTooltip(controls.extraBtn1, 'construction_infinite')
        controls.extraBtn1.OnClick = function(self, modifiers)
            return Checkbox.OnClick(self, modifiers)
        end
        controls.extraBtn1.OnCheck = function(self, checked)
            for _, v in sortedOptions.selection do
                v:ProcessInfo('SetRepeatQueue', tostring(checked))
                if EntityCategoryContains(categories.EXTERNALFACTORY + categories.EXTERNALFACTORYUNIT, v) then
                    v:GetCreator():ProcessInfo('SetRepeatQueue', tostring(checked))
                end
            end
        end
        local allFactories = true
        local currentInfiniteQueueCheckStatus = true

        for _, v in sortedOptions.selection do
            if not v:IsRepeatQueue() then
                currentInfiniteQueueCheckStatus = false
            end

            if not (v:IsInCategory('FACTORY') or v:IsInCategory('EXTERNALFACTORY'))then
                allFactories = false
            end
        end

        if allFactories then
            controls.extraBtn1:SetCheck(currentInfiniteQueueCheckStatus, true)
            controls.extraBtn1:Enable()
        else
            controls.extraBtn1:Disable()
        end

        SetupPauseButton()
    elseif controlType == 'selection' then
        Tooltip.AddCheckboxTooltip(controls.extraBtn1, 'save_template')
        local validForTemplate = true
        local faction = false
        for i, v in sortedOptions.selection do
            if not v:IsInCategory('STRUCTURE') then
                validForTemplate = false
                break
            end
            if i == 1 then
                local factions = import("/lua/factions.lua").Factions
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
        SetupPauseButton()
    elseif controlType == 'enhancement' then
        SetupPauseButton()
    else
        controls.extraBtn1:Disable()
        controls.extraBtn2:Disable()
    end
end

function updateCommandQueue()
    OnQueueChanged(currentCommandQueue)
end

local insertIntoTableLowestTechFirst = import("/lua/ui/game/selectionsort.lua").insertIntoTableLowestTechFirst
function FormatData(unitData, type)
    local retData = {}
    if type == 'construction' then
        local function SortFunc(unit1, unit2)
            local bp1 = __blueprints[unit1]
            local bp2 = __blueprints[unit2]
            local v1 = bp1.BuildIconSortPriority or bp1.StrategicIconSortPriority
            local v2 = bp2.BuildIconSortPriority or bp2.StrategicIconSortPriority

            if v1 >= v2 then
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

        -- Get function for checking for restricted units
        local IsRestricted = import("/lua/game.lua").IsRestricted

        -- This section adds the arrows in for a build icon which is an upgrade from the
        -- selected unit. If there is an upgrade chain, it will display them split by arrows.
        -- I'm excluding Factories from this for now, since the chain of T1 -> T2 HQ -> T3 HQ
        -- or T1 -> T2 Support -> T3 Support is not supported yet by the code which actually
        -- looks up, stores, and executes the upgrade chain. This needs doing for 3654.
        local unitSelected = sortedOptions.selection[1]
        local isStructure = EntityCategoryContains(categories.STRUCTURE - (categories.FACTORY + categories.EXTERNALFACTORY), unitSelected)

        for i, units in sortedUnits do
            table.sort(units, SortFunc)
            local index = i
            if not table.empty(units) then
                if not table.empty(retData) then
                    table.insert(retData, {type = 'spacer'})
                end

                for index, unit in units do
                    -- Show UI data/icons only for not restricted units
                    local restrict = false
                    if not IsRestricted(unit, GetFocusArmy()) then
                        local bp = __blueprints[unit]
                        -- Check if upgradeable structure
                        if isStructure and
                                bp and bp.General and
                                bp.General.UpgradesFrom and
                                bp.General.UpgradesFrom ~= 'none' then

                            restrict = IsRestricted(bp.General.UpgradesFrom, GetFocusArmy())
                            if not restrict then
                                table.insert(retData, {type = 'arrow'})
                            end
                        end

                        if not restrict then
                            table.insert(retData, {type = 'item', id = unit})
                        end
                    end
                end
            end
        end

        CreateExtraControls('construction')
        SetSecondaryDisplay('buildQueue')
    elseif type == 'selection' then
        local sortedUnits = {
            [1] = {cat = "ALLUNITS", units = {}},
            [2] = {cat = "LAND", units = {}},
            [3] = {cat = "AIR", units = {}},
            [4] = {cat = "NAVAL", units = {}},
            [5] = {cat = "STRUCTURE", units = {}},
            [6] = {cat = "SORTCONSTRUCTION", units = {}},
        }

        local lowFuelUnits = {}
        local idleConsUnits = {}

        for _, unit in unitData do
            local id = unit:GetBlueprint().BlueprintId

            if unit:IsInCategory('AIR') and unit:GetFuelRatio() < .2 and unit:GetFuelRatio() > -1 then
                if not lowFuelUnits[id] then
                    lowFuelUnits[id] = {}
                end
                table.insert(lowFuelUnits[id], unit)
            elseif options.gui_seperate_idle_builders ~= 0 and unit:IsInCategory('CONSTRUCTION') and unit:IsIdle() then
                if not idleConsUnits[id] then
                    idleConsUnits[id] = {}
                end
                table.insert(idleConsUnits[id], unit)
            else
                local cat = 0
                for i, t in sortedUnits do
                    if unit:IsInCategory(t.cat) then
                        cat = i
                    end
                end

                if not sortedUnits[cat].units[id] then
                    sortedUnits[cat].units[id] = {}
                end

                table.insert(sortedUnits[cat].units[id], unit)
            end
        end

        local function insertSpacer(didPutUnits)
            if didPutUnits then
                table.insert(retData, {type = 'spacer'})
                return not didPutUnits
            end
        end

        -- Sort selected units into order and insert spaces
        local didPutUnits = false
        for _, t in sortedUnits do
            didPutUnits = insertSpacer(didPutUnits)

            retData, didPutUnits = insertIntoTableLowestTechFirst(t.units, retData, false, false)
        end

        -- Split out low fuel
        didPutUnits = insertSpacer(didPutUnits)
        retData, didPutUnits = insertIntoTableLowestTechFirst(lowFuelUnits, retData, true, false)

        -- Split out idle constructors
        didPutUnits = insertSpacer(didPutUnits)
        retData, didPutUnits = insertIntoTableLowestTechFirst(idleConsUnits, retData, false, true)

        -- Remove trailing spacer if there is one
        if retData[table.getn(retData)].type == 'spacer' then
            table.remove(retData, table.getn(retData))
        end

        CreateExtraControls('selection')
        SetSecondaryDisplay('attached')

        import(UIUtil.GetLayoutFilename('construction')).OnTabChangeLayout(type)
    elseif type == 'templates' then
        table.sort(unitData, function(a, b)
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
        -- Enhancements
        local existingEnhancements = EnhanceCommon.GetEnhancements(sortedOptions.selection[1]:GetEntityId())
        local enhancementQueue
        if table.getn(sortedOptions.selection) == 1 then
            enhancementQueue = getEnhancementQueue()[sortedOptions.selection[1]:GetEntityId()] or {}
        end

        -- Filter enhancements based on restrictions
        local restEnh = EnhanceCommon.GetRestricted()
        local filteredEnh = {}
        local totalEnhancements = 0
        for _, enhTable in unitData do
            local enhId = enhTable.ID
            if not restEnh[enhId] and not enhId:find("Remove") then
                totalEnhancements = totalEnhancements + 1
                filteredEnh[totalEnhancements] = enhTable
            end
        end

        local function FindDependency(id)
            for _, enh in filteredEnh do
                if enh.Prerequisite == id then
                    return enh
                end
            end
        end

        local function AddEnhancement(enhTable)
            local iconData = {
                type = 'enhancement',
                enhTable = enhTable,
                unitID = enhTable.UnitID,
                id = enhTable.ID,
                icon = enhTable.Icon,
                Selected = false,
                Disabled = false,
            }
            if enhancementQueue then
                local slot = enhTable.Slot
                if existingEnhancements[slot] == enhTable.ID then
                    iconData.Selected = true
                end
                local prereqs = GetPrerequisites(enhTable)
                for _, queuedEnh in enhancementQueue do
                    if queuedEnh.Slot == slot and not table.find(prereqs, queuedEnh.ID) and not queuedEnh.ID:find("Remove") then
                        iconData.Disabled = true
                        break
                    end
                end
            end
            table.insert(retData, iconData)
        end

        local usedEnhancements = {}
        local totalUsed = 0
        for _, enhTable in filteredEnh do
            local enhId = enhTable.ID
            if usedEnhancements[enhId] or enhTable.Prerequisite then
                continue
            end

            AddEnhancement(enhTable)
            usedEnhancements[enhId] = true

            local curEnh = FindDependency(enhId)
            while curEnh do
                table.insert(retData, {type = 'arrow'})
                AddEnhancement(curEnh)
                usedEnhancements[curEnh.ID] = true
                totalUsed = totalUsed + 1
                curEnh = FindDependency(curEnh.ID)
            end
            if totalUsed < totalEnhancements then
                table.insert(retData, {type = 'spacer'})
            end
        end

        CreateExtraControls('enhancement')
        SetSecondaryDisplay('buildQueue')
    end

    import(UIUtil.GetLayoutFilename('construction')).OnTabChangeLayout(type)

    if type == 'templates' and allFactories then
        -- Replace Infinite queue with Create template
        Tooltip.AddCheckboxTooltip(controls.extraBtn1, 'save_template')
        if not table.empty(currentCommandQueue) then
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

function HandleIntegrationIssue()
    modifiedCommandQueue = table.copy(currentCommandQueue or {})

    local splitStack = nil
    local currCount = 1
    for _, command in previousModifiedCommandQueue do
        if command.type == 'enhancementqueue' then
            table.insert(modifiedCommandQueue, currCount, command)
            currCount = currCount + 1
        else
            local currentCount = modifiedCommandQueue[currCount]
            if currentCount and currentCount.displayCount then
                currentCount.displayCount = nil
            end

            local id = command.id
            local count = command.displayCount

            if splitStack and splitStack.id == id then
                table.insert(modifiedCommandQueue, currCount, splitStack)
                splitStack = nil
            end
            if currentCount and currentCount.id == id then
                if count and currentCount.count > count then
                    splitStack = {id = id, count = currentCount.count - count}
                    currentCount.displayCount = count
                end
                currCount = currCount + 1
            end
        end
    end
end

function IntegrateEnhancements()
    local uid = sortedOptions.selection[1]:GetEntityId()
    local fullCommandQueue = sortedOptions.selection[1]:GetCommandQueue()
    local enhancementQueue = getEnhancementQueue()
    local found = {}
    local currCount = 1
    local currEnh = 1
    local skip = 0
    local skippingCommand = nil

    local currentEnhancements = EnhanceCommon.GetEnhancements(uid)
    if currentEnhancements then
        for _, enhancement in currentEnhancements do
            found[enhancement] = true
        end
    end

    for _, command in fullCommandQueue do
        if command.type == 'Script' then
            if skip > 0 then
                local splitCommand = {id = skippingCommand.id, count = skip}
                table.insert(modifiedCommandQueue, currCount, splitCommand)
                skippingCommand.displayCount = skippingCommand.count - skip
                skip = 0
            end

            local enhancement = enhancementQueue[uid][currEnh]
            if not enhancement then
                HandleIntegrationIssue()
                return
            end

            local newCommand = {icon = enhancement.Icon, id = enhancement.UnitID, type = 'enhancementqueue', name = enhancement.Name, enhancement = enhancement}
            if not found[enhancement.ID] and not string.find(enhancement.ID, 'Remove') then
                table.insert(modifiedCommandQueue, currCount, newCommand)
                currCount = currCount + 1
            end

            found[enhancement.ID] = true

            currEnh = currEnh + 1
        elseif command.type == 'BuildMobile' then
            if skip > 0 then
                skip = skip - 1
            else
                if not modifiedCommandQueue[currCount] then
                    HandleIntegrationIssue()
                    return
                end

                skip = modifiedCommandQueue[currCount].count - 1
                skippingCommand = modifiedCommandQueue[currCount]
                skippingCommand.displayCount = nil
                currCount = currCount + 1
            end
        end
    end

    local size = table.getn(enhancementQueue[uid] or {})
    if enhancementQueue[uid] and currEnh < (size + 1) then
        while currEnh < (size + 1) do
            EnhancementQueueFile.removeEnhancement(sortedOptions.selection[1])
            size = size - 1
        end
        SetSecondaryDisplay('buildQueue')
    end

    previousModifiedCommandQueue = modifiedCommandQueue
end

function SetSecondaryDisplay(type)
    lastDisplayType = type
    if updateQueue then -- Don't update the queue the tick after a buttonreleasecallback
        local data = {}
        if type == 'buildQueue' then
            modifiedCommandQueue = table.copy(currentCommandQueue or {})
            if table.getn(sortedOptions.selection) == 1 then
                IntegrateEnhancements()
            end

            previousModifiedCommandQueue = modifiedCommandQueue
            if modifiedCommandQueue and not table.empty(modifiedCommandQueue) then
                local index = 1
                local newStack = nil
                local lastStack = nil

                for _, item in modifiedCommandQueue do
                    if item.type == 'enhancementqueue' then
                        table.insert(data, {type = 'enhancementqueue', unitID = item.id, icon = item.icon, name = item.name, enhancement = item.enhancement})
                    else
                        newStack = {type = 'queuestack', id = item.id, count = item.displayCount or item.count, position = index}
                        if lastStack and lastStack.id == newStack.id then
                            newStack.position = index - 1
                        else
                            index = index + 1
                            lastStack = newStack
                        end
                        table.insert(data, newStack)
                    end
                end
            end

            if table.getn(sortedOptions.selection) == 1 and not table.empty(data) then
                controls.secondaryProgress:SetNeedsFrameUpdate(true)
            else
                controls.secondaryProgress:SetNeedsFrameUpdate(false)
                controls.secondaryProgress:SetAlpha(0, true)
            end
        elseif type == 'attached' then
            local attachedUnits = EntityCategoryFilterDown(categories.MOBILE, GetAttachedUnitsList(sortedOptions.selection))
            if attachedUnits and not table.empty(attachedUnits) then
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
        -- Render the command queue
        if currentCommandQueue then
            SetQueueGrid(currentCommandQueue, selection)
        else
            ClearQueueGrid()
        end
        SetQueueState(false)
    elseif not table.empty(selection) then
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
    buildableCategories = EnhancementQueueFile.ModifyBuildablesForACU(buildableCategories, selection)

    if table.empty(selection) then
        sortedOptions.selection = {}
    end

    if options.gui_templates_factory ~= 0 then
        if table.empty(selection) then
            allFactories = false
        else
            allFactories = true
            for i, v in selection do
                if not (v:IsInCategory('FACTORY') or v:IsInCategory('EXTERNALFACTORY')) then
                    allFactories = false
                    break
                end
            end
        end
    end

    if table.getn(selection) == 1 then
        -- Queue display is easy: if we've got one unit selected, and it's an exFac platform,
        -- show the queue of its attached external factory
        -- this automatically supports removing/modifying the queue, neat!
        if EntityCategoryContains(categories.EXTERNALFACTORY, selection[1]) then
            currentCommandQueue = SetCurrentFactoryForQueueDisplay(selection[1]:GetCreator())
        else
            currentCommandQueue = SetCurrentFactoryForQueueDisplay(selection[1])
        end
    else
        currentCommandQueue = {}
        ClearCurrentFactoryForQueueDisplay()
    end

    if not table.empty(selection) then
        capturingKeys = false
        -- Sorting down units
        local buildableUnits = EntityCategoryGetUnitList(buildableCategories)
        if not isOldSelection then
            previousTabSet = nil
            previousTabSize = nil
            activeTab = nil
            ClearSessionExtraSelectList()
        end
        sortedOptions = {}
        UnitViewDetail.Hide()

        if not selection[1]:IsInCategory('FACTORY') then
            local inQueue = {}
            for _, v in currentCommandQueue or {} do
                inQueue[v.id] = true
            end


            local bpid = __blueprints[selection[1]:GetBlueprint().BlueprintId].General.UpgradesTo
            if bpid then
                while bpid and bpid ~= '' do -- UpgradesTo is sometimes ''??
                    if not inQueue[bpid] then
                        table.insert(buildableUnits, bpid)
                    end
                    bpid = __blueprints[bpid].General.UpgradesTo
                end

                buildableUnits = table.unique(buildableUnits)
            end
        end

        -- Only honour CONSTRUCTIONSORTDOWN if we selected a factory
        local allFactory = true
        for i, v in selection do
            if allFactory and not ( v:IsInCategory('FACTORY') or v:IsInCategory('EXTERNALFACTORY')) then
                allFactory = false
            end
        end

        if allFactory then
            local sortDowns = EntityCategoryFilterDown(categories.CONSTRUCTIONSORTDOWN, buildableUnits)
            sortedOptions.t1 = EntityCategoryFilterDown(categories.TECH1 - categories.CONSTRUCTIONSORTDOWN, buildableUnits)
            sortedOptions.t2 = EntityCategoryFilterDown(categories.TECH2 - categories.CONSTRUCTIONSORTDOWN, buildableUnits)
            sortedOptions.t3 = EntityCategoryFilterDown(categories.TECH3 - categories.CONSTRUCTIONSORTDOWN, buildableUnits)
            sortedOptions.t4 = EntityCategoryFilterDown(categories.EXPERIMENTAL - categories.CONSTRUCTIONSORTDOWN, buildableUnits)

            for _, unit in sortDowns do
                if EntityCategoryContains(categories.EXPERIMENTAL, unit) then
                    table.insert(sortedOptions.t3, unit)
                elseif EntityCategoryContains(categories.TECH3, unit) then
                    table.insert(sortedOptions.t2, unit)
                elseif EntityCategoryContains(categories.TECH2, unit) then
                    table.insert(sortedOptions.t1, unit)
                end
            end
        elseif EntityCategoryContains(categories.ENGINEER + categories.FACTORY + categories.EXTERNALFACTORY, selection[1]) then
            sortedOptions.t1 = EntityCategoryFilterDown(categories.TECH1, buildableUnits)
            sortedOptions.t2 = EntityCategoryFilterDown(categories.TECH2, buildableUnits)
            sortedOptions.t3 = EntityCategoryFilterDown(categories.TECH3, buildableUnits)
            sortedOptions.t4 = EntityCategoryFilterDown(categories.EXPERIMENTAL, buildableUnits)
        else
            sortedOptions.t1 = buildableUnits
        end

        if not table.empty(buildableUnits) then
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
            if allSameUnit and bpID and bpID ~= v:GetBlueprint().BlueprintId then
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
        if allMobile and templates and not table.empty(templates) then
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

    if not table.empty(selection) then
        -- Repeated from original to access the local variables
        local allSameUnit = true
        local bpID = false
        local allMobile = true
        for i, v in selection do
            if allMobile and not v:IsInCategory('MOBILE') then
                allMobile = false
            end
            if allSameUnit and bpID and bpID ~= v:GetBlueprint().BlueprintId then
                allSameUnit = false
            else
                bpID = v:GetBlueprint().BlueprintId
            end
            if not allMobile and not allSameUnit then
                break
            end
        end

        -- Upgrade multiple SCU at once
        if selection[1]:GetBlueprint().Enhancements and allSameUnit then
            controls.enhancementTab:Enable()
        end

        -- Allow all races to build other races templates
        if options.gui_all_race_templates ~= 0 then
            local templates = Templates.GetTemplates()
            local buildableUnits = EntityCategoryGetUnitList(buildableCategories)
            if allMobile and templates and not table.empty(templates) then

                local unitFactionName = selection[1]:GetBlueprint().General.FactionName
                local currentFaction = Factions[ FactionInUnitBpToKey[unitFactionName] ]

                if currentFaction then
                    sortedOptions.templates = {}
                    local function ConvertID(BPID)
                        local prefixes = currentFaction.GAZ_UI_Info.BuildingIdPrefixes or {}
                        for k, prefix in prefixes do
                            local newBPID = string.gsub(BPID, "(%a+)(%d+)", prefix .. "%2")
                            if table.find(buildableUnits, newBPID) then
                                return newBPID
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

                -- Refresh the construction tab to show any new available templates
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

    -- Add valid templates for selection
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
                        -- Allow templates containing factory upgrades & higher tech units
                        if index > 1 then
                            for i = index - 1, 1, -1 do
                                local blueprint = __blueprints[template.templateData[i].id]
                                if blueprint.General.UpgradesFrom ~= 'none' then
                                    -- Previous entry is a (valid) upgrade
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

        -- Templates tab enable & refresh
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

-- Given a tech level, sets that tech level, returns false if tech level not available
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
        GetTabByID('t' .. tostring(techLevel)):SetCheck(true)
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
        return BuildTemplate(key)
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
        -- Take indexfrom out and shunt all indices from indexfrom to indexto up one
        for i = indexfrom, (indexto - 1) do
            queue[i] = queue[i + 1]
        end
    elseif indexfrom > indexto then
        -- Take indexfrom out and shunt all indices from indexto to indexfrom down one
        for i = indexfrom, (indexto + 1), -1 do
            queue[i] = queue[i - 1]
        end
    end
    queue[indexto] = moveditem
    modifiedQueue = queue
    currentCommandQueue = queue

    -- Update buttons in the UI
    SetSecondaryDisplay('buildQueue')
end

function UpdateBuildList(newqueue, from)
    -- The way this does this is UGLY but I can only find functions to remove things from the build queue and to add them at the end
    -- Thus the only way I can see to modify the build queue is to delete it back to the point it is modified from (the from argument) and then
    -- add the modified version back in. Unfortunately this causes a momentary 'skip' in the displayed build cue as it is deleted and replaced

    for i = table.getn(oldQueue), from, -1 do
        DecreaseBuildCountInQueue(i, oldQueue[i].count)
    end
    for i = from, table.getn(newqueue) do
        local blueprint = __blueprints[newqueue[i].id]
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
        -- Don't update the queue next time round, to avoid a list of 0 builds
        updateQueue = false
        -- Disable dragging until the queue is rebuilt
        dragLock = true
        -- Reset modified so buildcount increasing can be used again
        modified = false
        -- Mouse button released so end drag
        dragging = false

        local first_modified_index
        if originalIndex <= index then
            first_modified_index = originalIndex
        else
            first_modified_index = index
        end
        -- On the release of the mouse button we want to update the ACTUAL build queue that the factory does. So far, only the UI has been changed,
        UpdateBuildList(modifiedQueue, first_modified_index)
        -- Nothing is now selected
        index = nil
    end
end
