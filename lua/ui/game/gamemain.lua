--*****************************************************************************
--* File: lua/modules/ui/game/gamemain.lua
--* Author: Chris Blackwell
--* Summary: Entry point for the in game UI
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local WldUIProvider = import('/lua/ui/game/wlduiprovider.lua').WldUIProvider
local GameCommon = import('/lua/ui/game/gamecommon.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Movie = import('/lua/maui/movie.lua').Movie
local Prefs = import('/lua/user/prefs.lua')
local options = Prefs.GetFromCurrentProfile('options')

local gameParent = false
local controlClusterGroup = false
local statusClusterGroup = false
local mapGroup = false
local mfdControl = false
local ordersControl = false

local OnDestroyFuncs = {}

local NISActive = false

local isReplay = false

local waitingDialog = false

-- variables for FAF
local sendChat = import('/lua/ui/game/chat.lua').ReceiveChatFromSim
local oldData = {}
local lastObserving
-- end faf variables

-- Hotbuild stuff
modifiersKeys = {}
-- Adding modifiers shorcuts on the fly.
local currentKeyMap = import('/lua/keymap/keymapper.lua').GetKeyMappings(true)
for key, action in currentKeyMap do
    if action["category"] == "hotbuilding" then
        if key ~= nil then
            if not import('/lua/keymap/keymapper.lua').IsKeyInMap("Shift-" .. key, currentKeyMap) then
                modifiersKeys["Shift-" .. key] = action
            else
                WARN("Shift-" .. key .. " is already bind")
            end

            if not import('/lua/keymap/keymapper.lua').IsKeyInMap("Alt-" .. key, currentKeyMap) then
                modifiersKeys["Alt-" .. key] = action
            else
                WARN("Alt-" .. key .. " is already bind")
            end
        end
    end
end
IN_AddKeyMapTable(modifiersKeys)

-- check this flag to see if it's valid to show the exit dialog
supressExitDialog = false

function GetReplayState()
    return isReplay
end

-- query this to see if the UI is hidden
gameUIHidden = false

PostScoreVideo = false

IsSavedGame = false

function KillWaitingDialog()
    if waitingDialog then
        waitingDialog:Destroy()
    end
end

function SetLayout(layout)
    import('/lua/ui/game/unitviewDetail.lua').Hide()
    import('/lua/ui/game/construction.lua').SetLayout(layout)
    import('/lua/ui/game/borders.lua').SetLayout(layout)
    import('/lua/ui/game/multifunction.lua').SetLayout(layout)
    if not isReplay then
        import('/lua/ui/game/orders.lua').SetLayout(layout)

    end
    import('/lua/ui/game/avatars.lua').SetLayout()
    import('/lua/ui/game/unitview.lua').SetLayout(layout)
    import('/lua/ui/game/objectives2.lua').SetLayout(layout)
    import('/lua/ui/game/unitviewDetail.lua').SetLayout(layout, mapGroup)
    import('/lua/ui/game/economy.lua').SetLayout(layout)
    import('/lua/ui/game/missiontext.lua').SetLayout()
    import('/lua/ui/game/helptext.lua').SetLayout()
    import('/lua/ui/game/score.lua').SetLayout()
    import('/lua/ui/game/economy.lua').SetLayout()
    import('/lua/ui/game/score.lua').SetLayout()
    import('/lua/ui/game/tabs.lua').SetLayout()
    import('/lua/ui/game/controlgroups.lua').SetLayout()
    import('/lua/ui/game/chat.lua').SetLayout()
    import('/lua/ui/game/minimap.lua').SetLayout()
end

function OnFirstUpdate()
    import('/modules/hotbuild.lua').init()
    EnableWorldSounds()
    local avatars = GetArmyAvatars()
    if avatars and avatars[1]:IsInCategory("COMMAND") then
        local armiesInfo = GetArmiesTable()
        local focusArmy = armiesInfo.focusArmy
        local playerName = armiesInfo.armiesTable[focusArmy].nickname
        avatars[1]:SetCustomName(playerName)
    end
    import('/lua/UserMusic.lua').StartPeaceMusic()
    if not import('/lua/ui/campaign/campaignmanager.lua').campaignMode then
        import('/lua/ui/game/score.lua').CreateScoreUI()
    end
    PlaySound( Sound { Bank='AmbientTest', Cue='AMB_Planet_Rumble_zoom'} )
    ForkThread(
               function()
                   WaitSeconds(1.5)
                   UIZoomTo(avatars, 1)
                   WaitSeconds(1.5)
                   SelectUnits(avatars)
                   FlushEvents()
                   if not IsNISMode() then
                       import('/lua/ui/game/worldview.lua').UnlockInput()
                   end
               end
               )

    if Prefs.GetOption('skin_change_on_start') ~= 'no' then
        local focusarmy = GetFocusArmy()
        local armyInfo = GetArmiesTable()
        if focusarmy >= 1 then
            local factions = import('/lua/factions.lua').Factions
            if factions[armyInfo.armiesTable[focusarmy].faction+1].DefaultSkin then
                UIUtil.SetCurrentSkin(factions[armyInfo.armiesTable[focusarmy].faction+1].DefaultSkin)
            end
        end
    end
end

function CreateUI(isReplay)
    ConExecute("Cam_Free off")
    local prefetchTable = { models = {}, anims = {}, d3d_textures = {}, batch_textures = {} }

    -- set up our layout change function
    UIUtil.changeLayoutFunction = SetLayout

    -- update loc table with player's name
    local focusarmy = GetFocusArmy()
    if focusarmy >= 1 then
        LocGlobals.PlayerName = GetArmiesTable().armiesTable[focusarmy].nickname
    end

    GameCommon.InitializeUnitIconBitmaps(prefetchTable.batch_textures)

    gameParent = UIUtil.CreateScreenGroup(GetFrame(0), "GameMain ScreenGroup")

    controlClusterGroup, statusClusterGroup, mapGroup, windowGroup = import('/lua/ui/game/borders.lua').SetupBorderControl(gameParent)

    controlClusterGroup:SetNeedsFrameUpdate(true)
    controlClusterGroup.OnFrame = function(self, deltaTime)
        controlClusterGroup:SetNeedsFrameUpdate(false)
        OnFirstUpdate()
    end

    import('/lua/ui/game/worldview.lua').CreateMainWorldView(gameParent, mapGroup)
    import('/lua/ui/game/worldview.lua').LockInput()

    local massGroup, energyGroup = import('/lua/ui/game/economy.lua').CreateEconomyBar(statusClusterGroup)
    import('/lua/ui/game/tabs.lua').Create(mapGroup)

    mfdControl = import('/lua/ui/game/multifunction.lua').Create(controlClusterGroup)
    if not isReplay then
        ordersControl = import('/lua/ui/game/orders.lua').SetupOrdersControl(controlClusterGroup, mfdControl)

    end
    import('/lua/ui/game/avatars.lua').CreateAvatarUI(mapGroup)
    import('/lua/ui/game/construction.lua').SetupConstructionControl(controlClusterGroup, mfdControl, ordersControl)
    import('/lua/ui/game/unitview.lua').SetupUnitViewLayout(mapGroup, ordersControl)
    import('/lua/ui/game/unitviewDetail.lua').SetupUnitViewLayout(mapGroup, mapGroup)
    import('/lua/ui/game/controlgroups.lua').CreateUI(mapGroup)
    import('/lua/ui/game/transmissionlog.lua').CreateTransmissionLog()
    import('/lua/ui/game/helptext.lua').CreateHelpText(mapGroup)
    import('/lua/ui/game/timer.lua').CreateTimerDialog(mapGroup)
    import('/lua/ui/game/consoleecho.lua').CreateConsoleEcho(mapGroup)
    import('/lua/ui/game/build_templates.lua').Init()
    import('/lua/ui/game/taunt.lua').Init()

    import('/lua/ui/game/chat.lua').SetupChatLayout(windowGroup)
    import('/lua/ui/game/minimap.lua').CreateMinimap(windowGroup)

    if import('/lua/ui/campaign/campaignmanager.lua').campaignMode then
        import('/lua/ui/game/objectives2.lua').CreateUI(mapGroup)
    end

    if GetNumRootFrames() > 1 then
        import('/lua/ui/game/multihead.lua').CreateSecondView()
    end

    controlClusterGroup.HandleEvent = function(self, event)
        if event.Type == "WheelRotation" then
            import('/lua/ui/game/worldview.lua').ForwardMouseWheelInput(event)
            return true
        end
        return false
    end

    statusClusterGroup.HandleEvent = function(self, event)
        if event.Type == "WheelRotation" then
            import('/lua/ui/game/worldview.lua').ForwardMouseWheelInput(event)
            return true
        end
        return false
    end

    Prefetcher:Update(prefetchTable)
    -- UI assets should be loaded fast into memory to prevent stutter
    ConExecute('res_AfterPrefetchDelay 100')
    ConExecute('res_PrefetcherActivityDelay 1')

    -- below added for FAF
    import("/modules/displayrings.lua").Init()  -- added for acu and engineer build radius ui mod
    if SessionIsReplay() then
        ForkThread(SendChat)
        lastObserving = true
        import('/lua/ui/game/economy.lua').ToggleEconPanel(false)
        import('/lua/ui/game/avatars.lua').ToggleAvatars(false)
        AddBeatFunction(UiBeat)
    end

    import('/modules/scumanager.lua').Init()

    if options.gui_render_enemy_lifebars == 1 or options.gui_render_custom_names == 0 then
        import('/modules/console_commands.lua').Init()
    end
end

local provider = false

local function LoadDialog(parent)
    local movieFile = '/movies/UEF_load.sfd'
    local color = 'FFbadbdb'
    local loadingPref = Prefs.GetFromCurrentProfile('LoadingFaction')
    local factions = import('/lua/factions.lua').Factions
    if factions[loadingPref] and factions[loadingPref].loadingMovie then
        movieFile = factions[loadingPref].loadingMovie
        color = factions[loadingPref].loadingColor
    end

    local movie = Movie(parent, movieFile)
    LayoutHelpers.FillParent(movie, parent)
    movie:Loop(true)
    movie:Play()

    local text = '::  ' .. LOC('<LOC LOAD_0000>IN TRANSIT') .. '  ::'
    local textControl = UIUtil.CreateText(movie, text, 20, UIUtil.bodyFont)
    textControl:SetColor(color)
    LayoutHelpers.AtCenterIn(textControl, parent, 200)
    import('/lua/maui/effecthelpers.lua').Pulse(textControl, 1, 0, .8)

    ConExecute('UI_RenderUnitBars true')
    ConExecute('UI_NisRenderIcons true')
    ConExecute('ren_SelectBoxes true')
    HideGameUI('off')

    return movie
end

function CreateWldUIProvider()

    provider = WldUIProvider()

    local loadingDialog = false
    local frame1Logo = false

    local lastTime = 0

    provider.StartLoadingDialog = function(self)
        GetCursor():Hide()
        supressExitDialog = true
        if not loadingDialog then
            self.loadingDialog = LoadDialog(GetFrame(0))
            if GetNumRootFrames() > 1 then
                local frame1 = GetFrame(1)
                local frame1Logo = Bitmap(frame1, UIUtil.UIFile('/marketing/splash.dds'))
                LayoutHelpers.FillParent(frame1Logo, frame1)
            end
        end
    end

    provider.UpdateLoadingDialog = function(self, elapsedTime)
        if loadingDialog then
        end
    end

    provider.StopLoadingDialog = function(self)
        local function InitialAnimations()
            import('/lua/ui/game/tabs.lua').InitialAnimation()
            WaitSeconds(.15)
            if not SessionIsReplay() then
                import('/lua/ui/game/economy.lua').InitialAnimation()
            end
            import('/lua/ui/game/score.lua').InitialAnimation()
            WaitSeconds(.15)
            import('/lua/ui/game/multifunction.lua').InitialAnimation()
            if not SessionIsReplay() then
                import('/lua/ui/game/avatars.lua').InitialAnimation()
            end
            import('/lua/ui/game/controlgroups.lua').InitialAnimation()
            WaitSeconds(.15)
            HideGameUI('off')
        end
        local loadingPref = Prefs.GetFromCurrentProfile('LoadingFaction')
        local factions = import('/lua/factions.lua').Factions
        local texture = '/UEF_load.dds'
        local color = 'FFbadbdb'
        if factions[loadingPref] and factions[loadingPref].loadingTexture then
            texture = factions[loadingPref].loadingTexture
            color = factions[loadingPref].loadingColor
        end
        GetCursor():Show()
        local background = Bitmap(GetFrame(0), UIUtil.UIFile(texture))
        LayoutHelpers.FillParent(background, GetFrame(0))
        background.Depth:Set(200)
        background:SetNeedsFrameUpdate(true)
        background.time = 0
        background.OnFrame = function(self, delta)
            self.time = self.time + delta
            if self.time > 1.5 then
                local newAlpha = self:GetAlpha() - (delta/2)
                if newAlpha < 0 then
                    newAlpha = 0
                    self:Destroy()
                    if not import('/lua/ui/campaign/campaignmanager.lua').campaignMode then
                        ForkThread(InitialAnimations)
                    end
                end
                self:SetAlpha(newAlpha, true)
            end
        end
        local text = '::  ' .. LOC('<LOC LOAD_0000>IN TRANSIT') .. '  ::'
        local textControl = UIUtil.CreateText(background, text, 20, UIUtil.bodyFont)
        textControl:SetColor(color)
        LayoutHelpers.AtCenterIn(textControl, GetFrame(0), 200)
        FlushEvents()
    end

    provider.StartWaitingDialog = function(self)
        if not waitingDialog then waitingDialog = UIUtil.ShowInfoDialog(GetFrame(0), "<LOC gamemain_0001>Waiting For Other Players...") end
    end

    provider.UpdateWaitingDialog = function(self, elapsedTime)
        -- currently no function, but could animate waiting dialog
    end

    provider.StopWaitingDialog = function(self)
        if waitingDialog then
            waitingDialog:Destroy()
            waitingDialog = false
        end
        FlushEvents()
    end

    provider.CreateGameInterface = function(self, inIsReplay)
        isReplay = inIsReplay
        if frame1Logo then
            frame1Logo:Destroy()
            frame1Logo = false
        end
        CreateUI(isReplay)
        if not import('/lua/ui/campaign/campaignmanager.lua').campaignMode then
            HideGameUI('on')
        end
        supressExitDialog = false
        FlushEvents()
    end

    provider.DestroyGameInterface = function(self)
        if gameParent then gameParent:Destroy() end
        for _, func in OnDestroyFuncs do
            func()
        end
        import('rallypoint.lua').ClearAllRallyPoints()
    end

    provider.GetPrefetchTextures = function(self)
        return import('/lua/ui/game/prefetchtextures.lua').prefetchTextures
    end

end

function AddOnUIDestroyedFunction(func)
    table.insert(OnDestroyFuncs, func)
end

-- This function is called whenever the set of currently selected units changes
-- See /lua/unit.lua for more information on the lua unit object
--      oldSelection: What the selection was before
--      newSelection: What the selection is now
--      added: Which units were added to the old selection
--      removed: Which units where removed from the old selection
function OnSelectionChanged(oldSelection, newSelection, added, removed)

    local availableOrders, availableToggles, buildableCategories = GetUnitCommandData(newSelection)
    local isOldSelection = table.equal(oldSelection, newSelection)

    if not gameUIHidden then
        if not isReplay then
            import('/lua/ui/game/orders.lua').SetAvailableOrders(availableOrders, availableToggles, newSelection)
        end
        -- todo change the current command mode if no longer available? or set to nil?
        import('/lua/ui/game/construction.lua').OnSelection(buildableCategories,newSelection,isOldSelection)
    end

    if not isOldSelection then
        import('/lua/ui/game/selection.lua').PlaySelectionSound(added)
        import('/lua/ui/game/rallypoint.lua').OnSelectionChanged(newSelection)
    end

    if newSelection then
        local n = table.getn(newSelection)

        if n == 1 and import('/modules/selectedinfo.lua').SelectedOverlayOn then
            import('/modules/selectedinfo.lua').ActivateSingleRangeOverlay()
        else
            import('/modules/selectedinfo.lua').DeactivateSingleRangeOverlay()
        end

        -- if something died in selection, restore command mode
        if n > 0 and table.getsize(removed) > 0 and table.getsize(added) == 0 then
            local CM = import('/lua/ui/game/commandmode.lua')
            local mode, data = unpack(CM.GetCommandMode())

            if mode then
                ForkThread(function()
                    CM.StartCommandMode(mode, data)
                end)
            end
        end
    end

    import('/lua/ui/game/unitview.lua').OnSelection(newSelection)
end

function OnQueueChanged(newQueue)
    if not gameUIHidden then
        import('/lua/ui/game/construction.lua').OnQueueChanged(newQueue)
    end
end

-- Called after the Sim has confirmed the game is indeed paused. This will happen
-- on everyone's machine in a network game.
function OnPause(pausedBy, timeoutsRemaining)
    local isOwner = false
    if pausedBy == SessionGetLocalCommandSource() then
        isOwner = true
    end
    PauseSound("World",true)
    PauseSound("Music",true)
    PauseVoice("VO",true)
    import('/lua/ui/game/tabs.lua').OnPause(true, pausedBy, timeoutsRemaining, isOwner)
    import('/lua/ui/game/missiontext.lua').OnGamePause(true)
end

-- Called after the Sim has confirmed that the game has resumed.
function OnResume()
    PauseSound("World",false)
    PauseSound("Music",false)
    PauseVoice("VO",false)
    import('/lua/ui/game/tabs.lua').OnPause(false)
    import('/lua/ui/game/missiontext.lua').OnGamePause(false)
end

-- Called immediately when the user hits the pause button. This only ever gets
-- called on the machine that initiated the pause (i.e. other network players
                                                  -- won't call this)
function OnUserPause(pause)
    local Tabs = import('/lua/ui/game/tabs.lua')
    local focus = GetArmiesTable().focusArmy
    if Tabs.CanUserPause() then
        if focus == -1 and not SessionIsReplay() then
            return
        end

        if pause then
            import('/lua/ui/game/missiontext.lua').PauseTransmission()
        else
            import('/lua/ui/game/missiontext.lua').ResumeTransmission()
        end
    end
end

local _beatFunctions = {}

function AddBeatFunction(fn)
    table.insert(_beatFunctions, fn)
end

function RemoveBeatFunction(fn)
    for i,v in _beatFunctions do
        if v == fn then
            table.remove(_beatFunctions, i)
            break
        end
    end
end

-- this function is called whenever the sim beats
function OnBeat()
    for i,v in _beatFunctions do
        if v then v() end
    end
end

function GetStatusCluster()
    return statusClusterGroup
end

function GetControlCluster()
    return controlClusterGroup
end

function GetGameParent()
    return gameParent
end

function HideGameUI(state)
    if gameParent then
        if gameUIHidden or state == 'off' then
            gameUIHidden = false
            controlClusterGroup:Show()
            statusClusterGroup:Show()
            import('/lua/ui/game/worldview.lua').Contract()
            import('/lua/ui/game/borders.lua').HideBorder(false)
            import('/lua/ui/game/unitview.lua').Expand()
            import('/lua/ui/game/economy.lua').Expand()
            import('/lua/ui/game/score.lua').Expand()
            import('/lua/ui/game/objectives2.lua').Expand()
            import('/lua/ui/game/multifunction.lua').Expand()
            import('/lua/ui/game/controlgroups.lua').Expand()
            import('/lua/ui/game/tabs.lua').Expand()
            import('/lua/ui/game/announcement.lua').Expand()
            import('/lua/ui/game/minimap.lua').Expand()
            import('/lua/ui/game/construction.lua').Expand()
            if not SessionIsReplay() then
                import('/lua/ui/game/avatars.lua').Expand()
                import('/lua/ui/game/orders.lua').Expand()
            end
        else
            gameUIHidden = true
            controlClusterGroup:Hide()
            statusClusterGroup:Hide()
            import('/lua/ui/game/worldview.lua').Expand()
            import('/lua/ui/game/borders.lua').HideBorder(true)
            import('/lua/ui/game/unitview.lua').Contract()
            import('/lua/ui/game/unitviewDetail.lua').Contract()
            import('/lua/ui/game/economy.lua').Contract()
            import('/lua/ui/game/score.lua').Contract()
            import('/lua/ui/game/objectives2.lua').Contract()
            import('/lua/ui/game/multifunction.lua').Contract()
            import('/lua/ui/game/controlgroups.lua').Contract()
            import('/lua/ui/game/tabs.lua').Contract()
            import('/lua/ui/game/announcement.lua').Contract()
            import('/lua/ui/game/minimap.lua').Contract()
            import('/lua/ui/game/construction.lua').Contract()
            if not SessionIsReplay() then
                import('/lua/ui/game/avatars.lua').Contract()
                import('/lua/ui/game/orders.lua').Contract()
            end
        end
    end
end

-- Given a userunit that is adjacent to a given blueprint, does it yield a
-- bonus? Used by the UI to draw extra info
function OnDetectAdjacencyBonus(userUnit, otherBp)
    -- fixme: todo
    return true
end

function OnFocusArmyUnitDamaged(unit)
    import('/lua/UserMusic.lua').NotifyBattle()
end

local NISControls = {
    barTop = false,
    barBot = false,
}

local rangePrefs = {
    range_RenderHighlighted = false,
    range_RenderSelected = false,
    range_RenderHighlighted = false
}

local preNISSettings = {}
function NISMode(state)
    NISActive = state
    local worldView = import("/lua/ui/game/worldview.lua")
    if state == 'on' then
        import('/lua/ui/dialogs/saveload.lua').OnNISBegin()
        import('/lua/ui/dialogs/options.lua').OnNISBegin()
        import('/lua/ui/game/consoleecho.lua').ToggleOutput(false)
        import('/lua/ui/game/multifunction.lua').PreNIS()
        import('/lua/ui/game/tooltip.lua').DestroyMouseoverDisplay()
        import('/lua/ui/game/chat.lua').OnNISBegin()
        import('/lua/ui/game/unitviewDetail.lua').OnNIS()
        HideGameUI(state)
        ShowNISBars()
        if worldView.viewRight then
            import("/lua/ui/game/borders.lua").SplitMapGroup(false, true)
            preNISSettings.restoreSplitScreen = true
        else
            preNISSettings.restoreSplitScreen = false
        end
        preNISSettings.Resources = worldView.viewLeft:IsResourceRenderingEnabled()
        preNISSettings.Cartographic = worldView.viewLeft:IsCartographic()
        worldView.viewLeft:EnableResourceRendering(false)
        worldView.viewLeft:SetCartographic(false)
        ConExecute('UI_RenderUnitBars false')
        ConExecute('UI_NisRenderIcons false')
        ConExecute('ren_SelectBoxes false')
        for i, v in rangePrefs do
            ConExecute(i..' false')
        end
        preNISSettings.gameSpeed = GetGameSpeed()
        if preNISSettings.gameSpeed ~= 0 then
            SetGameSpeed(0)
        end
        preNISSettings.Units = GetSelectedUnits()
        SelectUnits({})
        RenderOverlayEconomy(false)
    else
        import('/lua/ui/game/worldview.lua').UnlockInput()
        import('/lua/ui/game/multifunction.lua').PostNIS()
        HideGameUI(state)
        HideNISBars()
        if preNISSettings.restoreSplitScreen then
            import("/lua/ui/game/borders.lua").SplitMapGroup(true, true)
        end
        worldView.viewLeft:EnableResourceRendering(preNISSettings.Resources)
        worldView.viewLeft:SetCartographic(preNISSettings.Cartographic)
        -- Todo: Restore settings of overlays, lifebars properly
        ConExecute('UI_RenderUnitBars true')
        ConExecute('UI_NisRenderIcons true')
        ConExecute('ren_SelectBoxes true')
        for i, v in rangePrefs do
            if Prefs.GetFromCurrentProfile(i) == nil then
                ConExecute(i..' true')
            else
                ConExecute(i..' '..tostring(Prefs.GetFromCurrentProfile(i)))
            end
        end
        if GetGameSpeed() ~= preNISSettings.gameSpeed then
            SetGameSpeed(preNISSettings.gameSpeed)
        end
        SelectUnits(preNISSettings.Units)
        import('/lua/ui/game/consoleecho.lua').ToggleOutput(true)
    end
    import('/lua/ui/game/missiontext.lua').SetLayout()
end

function ShowNISBars()
    if not NISControls.barTop then
        NISControls.barTop = Bitmap(GetFrame(0))
    end
    NISControls.barTop:SetSolidColor('ff000000')
    NISControls.barTop.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
    NISControls.barTop.Left:Set(function() return GetFrame(0).Left() end)
    NISControls.barTop.Right:Set(function() return GetFrame(0).Right() end)
    NISControls.barTop.Top:Set(function() return GetFrame(0).Top() end)
    NISControls.barTop.Height:Set(1)

    if not NISControls.barBot then
        NISControls.barBot = Bitmap(GetFrame(0))
    end
    NISControls.barBot:SetSolidColor('ff000000')
    NISControls.barBot.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
    NISControls.barBot.Left:Set(function() return GetFrame(0).Left() end)
    NISControls.barBot.Right:Set(function() return GetFrame(0).Right() end)
    NISControls.barBot.Bottom:Set(function() return GetFrame(0).Bottom() end)
    NISControls.barBot.Height:Set(NISControls.barTop.Height)

    NISControls.barTop:SetNeedsFrameUpdate(true)
    NISControls.barTop.OnFrame = function(self, delta)
        if delta then
            if self.Height() > GetFrame(0).Height() / 10 then
                self:SetNeedsFrameUpdate(false)
            else
                local curHeight = self.Height()
                self.Height:Set(function() return curHeight * 1.25 end)
            end
        end
    end
end

function IsNISMode()
    if NISActive == 'on' then
        return true
    else
        return false
    end
end

function HideNISBars()
    NISControls.barTop:SetNeedsFrameUpdate(true)
    NISControls.barTop.OnFrame = function(self, delta)
        if delta then
            local newAlpha = self:GetAlpha()*.8
            if newAlpha < .1 then
                NISControls.barBot:Destroy()
                NISControls.barBot = false
                NISControls.barTop:Destroy()
                NISControls.barTop = false
            else
                NISControls.barTop:SetAlpha(newAlpha)
                NISControls.barBot:SetAlpha(newAlpha)
            end
        end
    end
end

local chatFuncs = {}

function RegisterChatFunc(func, dataTag)
    table.insert(chatFuncs, {id = dataTag, func = func})
end

function ReceiveChat(sender, data)
    for i, chatFuncEntry in chatFuncs do
        if data[chatFuncEntry.id] then
            chatFuncEntry.func(sender, data)
        end
    end
end

function QuickSave(filename)
    if SessionIsActive() and
        WorldIsPlaying() and
        not SessionIsGameOver() and
        not SessionIsMultiplayer() and
        not SessionIsReplay() and
        not IsNISMode() then

        local saveType
        if import('/lua/ui/campaign/campaignmanager.lua').campaignMode then
            saveType = "CampaignSave"
        else
            saveType = "SaveGame"
        end
        local path = GetSpecialFilePath(Prefs.GetCurrentProfile().Name, filename, saveType)
        local statusStr = "<LOC saveload_0002>Quick Save in progress..."
        local status = UIUtil.ShowInfoDialog(GetFrame(0), statusStr)
        InternalSaveGame(path, filename, function(worked, errmsg)
                         status:Destroy()
                         if not worked then
                             infoStr = LOC("<LOC uisaveload_0008>Save failed! ") .. errmsg
                             UIUtil.ShowInfoDialog(GetFrame(0), infoStr, "<LOC _Ok>")
                         end
                     end)
    end
end

defaultZoom = 1.4
function SimChangeCameraZoom(newMult)
    if SessionIsActive() and
        WorldIsPlaying() and
        not SessionIsGameOver() and
        not SessionIsMultiplayer() and
        not SessionIsReplay() and
        not IsNISMode() then

        defaultZoom = newMult
        local views = import('/lua/ui/game/worldview.lua').GetWorldViews()
        for _, viewControl in views do
            if viewControl._cameraName ~= 'MiniMap' then
                GetCamera(viewControl._cameraName):SetMaxZoomMult(newMult)
            end
        end
    end
end

function UiBeat()
    local observing = (GetFocusArmy() == -1)
    if (observing ~= lastObserving) then
        lastObserving = observing
        import('/lua/ui/game/economy.lua').ToggleEconPanel(not observing)
    end
    if HasCommandLineArg("/syncreplay") and HasCommandLineArg("/gpgnet") then
        GpgNetSend("BEAT",GameTick(),GetGameSpeed())
    end
end

SendChat = function()
    while true do
        if UnitData.Chat then
            if table.getn(UnitData.Chat) > 0 then
                for index, chat in UnitData.Chat do
                    local newChat = true
                    if table.getn(oldData) > 0 then
                        for index, old in oldData do
                            if (old.oldTime + 3) < GetGameTimeSeconds() then
                                oldData[index] = nil
                            elseif old.msg.text == chat.msg.text and old.sender == chat.sender and chat.msg.to == old.msg.to then
                                newChat = false
                            elseif type(chat.msg.to) == 'number' and chat.msg.to == old.msg.to and old.msg.text == chat.msg.text then
                                newChat = false
                            end
                        end
                    end
                    if newChat then
                        chat.oldTime = GetGameTimeSeconds()
                        table.insert(oldData, chat)
                        sendChat(chat.sender, chat.msg)
                    end
                end
                UnitData.Chat = {}
            end
        end
        WaitSeconds(0.1)
    end
end
