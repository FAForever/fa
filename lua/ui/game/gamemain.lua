--*****************************************************************************
--* File: lua/modules/ui/game/gamemain.lua
--* Author: Chris Blackwell
--* Summary: Entry point for the in game UI
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local utils = import("/lua/system/utils.lua")
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local WldUIProvider = import("/lua/ui/game/wlduiprovider.lua").WldUIProvider
local GameCommon = import("/lua/ui/game/gamecommon.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Movie = import("/lua/maui/movie.lua").Movie
local Prefs = import("/lua/user/prefs.lua")
local options = Prefs.GetFromCurrentProfile('options')

local controls = import("/lua/ui/controls.lua").Get()

local gameParent = controls.gameParent
local controlClusterGroup = controls.cluster
local statusClusterGroup = controls.status
local mapGroup = controls.map
local mfdControl = controls.mfd
local ordersControl = false

local OnDestroyFuncs = {}

local NISActive = false
local isReplay = false
local waitingDialog = false

local sendChat = import("/lua/ui/game/chat.lua").ReceiveChatFromSim
local oldData = {}
local lastObserving


-- generating hotbuild modifier shortcuts on the fly
modifiersKeys = import("/lua/keymap/keymapper.lua").GenerateHotbuildModifiers()
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

-- The focus army as set at the start of the game. Allows us to detect whether someone was originally an observer or a player
OriginalFocusArmy = -1

GameHasAIs = false

function KillWaitingDialog()
    if waitingDialog then
        waitingDialog:Destroy()
    end
end

function SetLayout(layout)
    import("/lua/ui/game/unitviewdetail.lua").Hide()
    import("/lua/ui/game/construction.lua").SetLayout(layout)
    import("/lua/ui/game/borders.lua").SetLayout(layout)
    import("/lua/ui/game/multifunction.lua").SetLayout(layout)
    if not isReplay then
        import("/lua/ui/game/orders.lua").SetLayout(layout)
    end
    import("/lua/ui/game/avatars.lua").SetLayout()
    import("/lua/ui/game/unitview.lua").SetLayout(layout)
    import('/lua/ui/game/objectives2.lua').SetLayout(layout)
    import("/lua/ui/game/unitviewdetail.lua").SetLayout(layout, mapGroup)
    import("/lua/ui/game/economy.lua").SetLayout(layout)
    import("/lua/ui/game/missiontext.lua").SetLayout()
    import("/lua/ui/game/helptext.lua").SetLayout()
    import("/lua/ui/game/score.lua").SetLayout()
    import("/lua/ui/game/tabs.lua").SetLayout()
    import("/lua/ui/game/controlgroups.lua").SetLayout()
    import("/lua/ui/game/chat.lua").SetLayout()
    import("/lua/ui/game/minimap.lua").SetLayout()
    import("/lua/ui/game/massfabs.lua").SetLayout()
    import("/lua/ui/game/recall.lua").SetLayout()
end

function OnFirstUpdate()
    import("/lua/keymap/hotbuild.lua").init()
    EnableWorldSounds()
    import("/lua/usermusic.lua").StartPeaceMusic()

    local avatars = GetArmyAvatars()
    local armiesInfo = GetArmiesTable()
    local focusArmy = armiesInfo.focusArmy
    local playerArmy = armiesInfo.armiesTable[focusArmy]
    if avatars and avatars[1]:IsInCategory("COMMAND") then
        avatars[1]:SetCustomName(playerArmy.nickname)
        PlaySound(Sound {
            Bank = 'AmbientTest',
            Cue = 'AMB_Planet_Rumble_zoom'
        })
        ForkThread(function()
            WaitSeconds(1)

            UIZoomTo(avatars, 1)
            WaitSeconds(1.5)

            local selected = false
            repeat
                WaitSeconds(0.1)

                if not gameUIHidden then
                    SelectUnits(avatars)
                    selected = GetSelectedUnits()
                end
            until not table.empty(selected) or GameTick() > 50
        end)
    end

    FlushEvents()
    if not IsNISMode() then
        import("/lua/ui/game/worldview.lua").UnlockInput()
    end

    if not import("/lua/ui/campaign/campaignmanager.lua").campaignMode then
        import("/lua/ui/game/score.lua").CreateScoreUI()
    end

    if Prefs.GetOption('skin_change_on_start') ~= 'no' then
        if focusArmy >= 1 then
            local factionSkin = import("/lua/factions.lua").Factions[playerArmy.faction + 1].DefaultSkin
            if factionSkin then
                UIUtil.SetCurrentSkin(factionSkin)
                return
            end
        end
    end
    UIUtil.UpdateCurrentSkin()
end

function CreateUI(isReplay)
    -- overwrite some globals for performance / safety

    import("/lua/ui/override/exit.lua")
    import("/lua/ui/override/armiestable.lua")
    import("/lua/ui/override/sessionclients.lua")

    -- start long-running threads

    import("/lua/system/performance.lua")
    import("/lua/ui/game/cursor/depth.lua")
    import("/lua/ui/game/cursor/hover.lua")

    -- casting tools

    import("/lua/ui/game/casting/mouse.lua")
    import("/lua/ui/game/casting/painting.lua")

    -- overwrite some globals for performance / safety

    -- ensure logger is turned off for the average user
    if not GetPreference('debug.enable_debug_facilities') then
        SetPreference('Options.Log', {
            Debug = false,
            Info = false,
            Warn = false,
            Error = false,
            Custom = false,
            Filter = '*debug:',
        })
    end

    -- prevents the nvidia stuttering bug with their more recent drivers
    ConExecute('d3d_WindowsCursor on')

    -- tweak networking parameters
    ConExecute('net_MinResendDelay 100')
    ConExecute('net_MaxResendDelay 1000')

    ConExecute('net_MaxSendRate 8192')
    ConExecute('net_MaxBacklog 8192')

    ConExecute('net_SendDelay 5')
    ConExecute('net_AckDelay 5')

    -- enable experimental graphics
    if  Prefs.GetFromCurrentProfile('options.fidelity') >= 2 and
        Prefs.GetFromCurrentProfile('options.experimental_graphics') == 1
    then
        ForkThread(function()
            WaitSeconds(1.0)

            if Prefs.GetFromCurrentProfile('options.level_of_detail') == 2 then
                -- allow meshes and effects to be seen from further away
                ConExecute("cam_SetLOD WorldCamera 0.65")
            end

            if Prefs.GetFromCurrentProfile('options.shadow_quality') == 3 then
                -- improve shadow LOD and resolution
                ConExecute("ren_ShadowLOD 1024")
                ConExecute("ren_ShadowSize 2048")
            end
        end)
    end

    local focusArmy = GetFocusArmy()

    -- keep track of the original focus army
    import("/lua/ui/game/ping.lua").OriginalFocusArmy = focusArmy
    OriginalFocusArmy = focusArmy

    ConExecute("Cam_Free off")
    local prefetchTable = { models = {}, anims = {}, d3d_textures = {}, batch_textures = {} }

    -- Set up our layout change function
    UIUtil.changeLayoutFunction = SetLayout

    -- Update loc table with player's name
    if focusArmy >= 1 then
        LocGlobals.PlayerName = GetArmiesTable().armiesTable[focusArmy].nickname
    end

    GameCommon.InitializeUnitIconBitmaps(prefetchTable.batch_textures)

    controls.gameParent = UIUtil.CreateScreenGroup(GetFrame(0), "GameMain ScreenGroup")
    gameParent = controls.gameParent

    controlClusterGroup, statusClusterGroup, mapGroup, windowGroup = import("/lua/ui/game/borders.lua").SetupBorderControl(gameParent)

    controls.cluster = controlClusterGroup
    controls.status = statusClusterGroup
    controls.map = mapGroup
    controls.window = windowGroup

    controlClusterGroup:SetNeedsFrameUpdate(true)
    controlClusterGroup.OnFrame = function(self, deltaTime)
        controlClusterGroup:SetNeedsFrameUpdate(false)
        OnFirstUpdate()
    end

    import("/lua/ui/game/worldview.lua").CreateMainWorldView(gameParent, mapGroup)
    import("/lua/ui/game/worldview.lua").LockInput()

    import("/lua/ui/game/economy.lua").CreateEconomyBar(statusClusterGroup)
    import("/lua/ui/game/tabs.lua").Create(mapGroup)

    mfdControl = import("/lua/ui/game/multifunction.lua").Create(controlClusterGroup)
    controls.mfd = mfdControl

    controls.mfp = import("/lua/ui/game/massfabs.lua").Create(statusClusterGroup)
    controls.recall = import("/lua/ui/game/recall.lua").Create(statusClusterGroup)

    if not isReplay then
        ordersControl = import("/lua/ui/game/orders.lua").SetupOrdersControl(controlClusterGroup, mfdControl)
        controls.ordersControl = ordersControl
    end

    import("/lua/ui/game/avatars.lua").CreateAvatarUI(mapGroup)
    import("/lua/ui/game/construction.lua").SetupConstructionControl(controlClusterGroup, mfdControl, ordersControl)
    import("/lua/ui/game/unitview.lua").SetupUnitViewLayout(mapGroup, ordersControl)
    import("/lua/ui/game/unitviewdetail.lua").SetupUnitViewLayout(mapGroup, mapGroup)
    import("/lua/ui/game/controlgroups.lua").CreateUI(mapGroup)
    import("/lua/ui/game/transmissionlog.lua").CreateTransmissionLog()
    import("/lua/ui/game/helptext.lua").CreateHelpText(mapGroup)
    import("/lua/ui/game/timer.lua").CreateTimerDialog(mapGroup)
    import("/lua/ui/game/consoleecho.lua").CreateConsoleEcho(mapGroup)
    import("/lua/ui/game/build_templates.lua").Init()
    import("/lua/ui/game/taunt.lua").Init()

    import("/lua/ui/game/chat.lua").SetupChatLayout(windowGroup)
    import("/lua/ui/game/minimap.lua").CreateMinimap(windowGroup)

    if import("/lua/ui/campaign/campaignmanager.lua").campaignMode then
        import('/lua/ui/game/objectives2.lua').CreateUI(mapGroup)
    end

    if GetNumRootFrames() > 1 then
        import("/lua/ui/game/multihead.lua").CreateSecondView()
    end

    controlClusterGroup.HandleEvent = function(self, event)
        if event.Type == "WheelRotation" then
            import("/lua/ui/game/worldview.lua").ForwardMouseWheelInput(event)
            return true
        end
        return false
    end

    statusClusterGroup.HandleEvent = function(self, event)
        if event.Type == "WheelRotation" then
            import("/lua/ui/game/worldview.lua").ForwardMouseWheelInput(event)
            return true
        end
        return false
    end

    Prefetcher:Update(prefetchTable)
    -- UI assets should be loaded fast into memory to prevent stutter
    ConExecute('res_AfterPrefetchDelay 100')
    ConExecute('res_PrefetcherActivityDelay 1')

    if SessionIsReplay() then
        ForkThread(SendChat)
        lastObserving = true
        import("/lua/ui/game/economy.lua").ToggleEconPanel(false)
        import("/lua/ui/game/avatars.lua").ToggleAvatars(false)
        AddBeatFunction(UiBeat)
    end

    if options.gui_render_enemy_lifebars == 1 or options.gui_render_custom_names == 0 then
        import("/lua/ui/game/launchconsolecommands.lua").Init()
    end

    RegisterChatFunc(SendResumedBy, 'SendResumedBy')

    import("/lua/keymap/hotkeylabels.lua").init()
    import("/lua/ui/notify/customiser.lua").init(isReplay, import("/lua/ui/game/borders.lua").GetMapGroup())
    import("/lua/ui/game/reclaim.lua").SetMapSize()
end

-- Current SC_FrameTimeClamp settings allows up to 100 fps as default (some users probably set this to 0 to "increase fps" which would be counter-productive)
-- Let's find out max Hz capability of adapter so we don't render unnecessary frames, should help a bit with render thread at 100%
function AdjustFrameRate()
    if options.vsync == 1 then return end

    local video = options.video
    local fps = 100

    if type(options.primary_adapter) == 'string' then
        local data = utils.StringSplit(options.primary_adapter, ',')
        local hz = tonumber(data[3])
        if hz then
            fps = math.max(60, hz)
        end
    end

    ConExecute("SC_FrameTimeClamp " .. (1000 / fps))
end

local provider = false

local function LoadDialog(parent)
    local movieFile = '/movies/UEF_load.sfd'
    local color = 'FFbadbdb'
    local loadingPref = Prefs.GetFromCurrentProfile('LoadingFaction')
    local factions = import("/lua/factions.lua").Factions
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
    textControl:SetDropShadow(true)
    LayoutHelpers.AtCenterIn(textControl, parent, 200)
    import("/lua/maui/effecthelpers.lua").Pulse(textControl, 1, 0, .8)

    if Prefs.GetOption('loading_tips') then
        local tipControl = UIUtil.CreateText(movie, '', 20, UIUtil.bodyFont)
        tipControl:SetColor(color)
        tipControl:SetDropShadow(true)
        LayoutHelpers.CenteredBelow(tipControl, textControl, 40)
        ForkThread(
            function(control)
                local tipsTbl = import("/lua/ui/help/loadingtips.lua").Tips
                local tipsSize = table.getn(tipsTbl)
                while WorldIsLoading() do
                    control:SetText(LOC(tipsTbl[Random(1, tipsSize)]))
                    control:SetDropShadow(true)
                    WaitSeconds(7)
                end
            end,
            tipControl
        )
    end

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
            import("/lua/ui/game/tabs.lua").InitialAnimation()
            WaitSeconds(.15)
            if not SessionIsReplay() then
                import("/lua/ui/game/economy.lua").InitialAnimation()
            end
            import("/lua/ui/game/score.lua").InitialAnimation()
            WaitSeconds(.15)
            import("/lua/ui/game/multifunction.lua").InitialAnimation()
            if not SessionIsReplay() then
                import("/lua/ui/game/avatars.lua").InitialAnimation()
            end
            import("/lua/ui/game/controlgroups.lua").InitialAnimation()
            WaitSeconds(.15)
            HideGameUI('off')
        end
        local loadingPref = Prefs.GetFromCurrentProfile('LoadingFaction')
        local factions = import("/lua/factions.lua").Factions
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
                    if not import("/lua/ui/campaign/campaignmanager.lua").campaignMode then
                        ForkThread(InitialAnimations)
                    end
                end
                self:SetAlpha(newAlpha, true)
            end
        end
        local text = '::  ' .. LOC('<LOC LOAD_0000>IN TRANSIT') .. '  ::'
        local textControl = UIUtil.CreateText(background, text, 20, UIUtil.bodyFont)
        textControl:SetColor(color)
        textControl:SetDropShadow(true)
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
        if not import("/lua/ui/campaign/campaignmanager.lua").campaignMode then
            HideGameUI('on')
        end
        supressExitDialog = false
        FlushEvents()
        AdjustFrameRate()
    end

    provider.DestroyGameInterface = function(self)
        if gameParent then gameParent:Destroy() end
        for _, func in OnDestroyFuncs do
            func()
        end
        import("/lua/ui/game/rallypoint.lua").ClearAllRallyPoints()
    end

    provider.GetPrefetchTextures = function(self)
        return import("/lua/ui/game/prefetchtextures.lua").prefetchTextures
    end

end

function AddOnUIDestroyedFunction(func)
    table.insert(OnDestroyFuncs, func)
end

-- Called after the Sim has confirmed the game is indeed paused. This will happen
-- on everyone's machine in a network game.
function OnPause(pausedBy, timeoutsRemaining)
    PauseSound("World",true)
    PauseSound("Music",true)
    PauseVoice("VO",true)
    import("/lua/ui/game/tabs.lua").OnPause(true, pausedBy, timeoutsRemaining)
    import("/lua/ui/game/missiontext.lua").OnGamePause(true)
end

-- Called after the Sim has confirmed that the game has resumed.
local ResumedBy = nil
function SendResumedBy(sender)
    if not ResumedBy then ResumedBy = sender end
end

function OnResume()
    PauseSound("World",false)
    PauseSound("Music",false)
    PauseVoice("VO",false)
    import("/lua/ui/game/tabs.lua").OnPause(false, ResumedBy)
    import("/lua/ui/game/missiontext.lua").OnGamePause(false)
    ResumedBy = nil
end

-- Called immediately when the user hits the pause button on the machine
-- that initiated the pause and other network players won't call this function
function OnUserPause(pause)
    local Tabs = import("/lua/ui/game/tabs.lua")
    local focus = GetArmiesTable().focusArmy
    if Tabs.CanUserPause() then
        if focus == -1 and not SessionIsReplay() then
            return
        end

        if pause then
            import("/lua/ui/game/missiontext.lua").PauseTransmission()
        else
            import("/lua/ui/game/missiontext.lua").ResumeTransmission()
        end
    end
end

local _beatFunctions = {}

-- Adds a function callback that will be called on sim beats
-- @param fn       - specifies function callback
-- @param throttle - specifies whether never to run a function more than 10 times per second
--                   to reduce UI load when speeding up sim / replay
-- @param key      - specifies optional key used later for removing callbacks by a key
function AddBeatFunction(fn, throttle, key)
    table.insert(_beatFunctions, {fn = fn, throttle = throttle == true, key = key})
end

-- Removes a function callback from calling on sim beats
-- @param fn  - specifies function callback
-- @param key - specifies optional key associated with function callback
function RemoveBeatFunction(fn, key)
    for i,v in _beatFunctions do
        if v.fn == fn then
            table.remove(_beatFunctions, i)
            break
        end
        if key and v.key == key then
            table.remove(_beatFunctions, i)
            break
        end
    end
end

-- Calls function callbacks that were added previously, whenever the sim beat occurs
local last = 0
function OnBeat()
    local rate = GetSimRate()
    local throttle = false

    if rate > 0 then
        if GetSystemTimeSeconds() - last < 0.1 then
            throttle = true
        else
            last = GetSystemTimeSeconds()
        end
    end

    for i,v in _beatFunctions do
        if v.throttle and throttle then continue end
        if v.fn then v.fn() end
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
            import("/lua/ui/game/worldview.lua").Contract()
            import("/lua/ui/game/borders.lua").HideBorder(false)
            import("/lua/ui/game/unitview.lua").Expand()
            import("/lua/ui/game/economy.lua").Expand()
            import("/lua/ui/game/score.lua").Expand()
            import('/lua/ui/game/objectives2.lua').Expand()
            import("/lua/ui/game/multifunction.lua").Expand()
            import("/lua/ui/game/controlgroups.lua").Expand()
            import("/lua/ui/game/tabs.lua").Expand()
            import("/lua/ui/game/announcement.lua").Expand()
            import("/lua/ui/game/minimap.lua").Expand()
            import("/lua/ui/game/construction.lua").Expand()
            if not SessionIsReplay() then
                import("/lua/ui/game/avatars.lua").Expand()
                import("/lua/ui/game/orders.lua").Expand()
            end
        else
            gameUIHidden = true
            controlClusterGroup:Hide()
            statusClusterGroup:Hide()
            import("/lua/ui/game/worldview.lua").Expand()
            import("/lua/ui/game/borders.lua").HideBorder(true)
            import("/lua/ui/game/unitview.lua").Contract()
            import("/lua/ui/game/unitviewdetail.lua").Contract()
            import("/lua/ui/game/economy.lua").Contract()
            import("/lua/ui/game/score.lua").Contract()
            import('/lua/ui/game/objectives2.lua').Contract()
            import("/lua/ui/game/multifunction.lua").Contract()
            import("/lua/ui/game/controlgroups.lua").Contract()
            import("/lua/ui/game/tabs.lua").Contract()
            import("/lua/ui/game/announcement.lua").Contract()
            import("/lua/ui/game/minimap.lua").Contract()
            import("/lua/ui/game/construction.lua").Contract()
            if not SessionIsReplay() then
                import("/lua/ui/game/avatars.lua").Contract()
                import("/lua/ui/game/orders.lua").Contract()
            end
        end
    end
end

-- Given an UserUnit that is adjacent to a given blueprint, does it yield a
-- bonus? Used by the UI to draw extra info
function OnDetectAdjacencyBonus(userUnit, otherBp)
    -- fixme: todo
    return true
end

function OnFocusArmyUnitDamaged(unit)
    import("/lua/usermusic.lua").NotifyBattle()
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
        import("/lua/ui/dialogs/saveload.lua").OnNISBegin()
        import("/lua/ui/dialogs/options.lua").OnNISBegin()
        import("/lua/ui/game/consoleecho.lua").ToggleOutput(false)
        import("/lua/ui/game/multifunction.lua").PreNIS()
        import("/lua/ui/game/tooltip.lua").DestroyMouseoverDisplay()
        import("/lua/ui/game/chat.lua").OnNISBegin()
        import("/lua/ui/game/unitviewdetail.lua").OnNIS()
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
        import("/lua/ui/game/worldview.lua").UnlockInput()
        import("/lua/ui/game/multifunction.lua").PostNIS()
        HideGameUI(state)
        HideNISBars()
        if preNISSettings.restoreSplitScreen then
            import("/lua/ui/game/borders.lua").SplitMapGroup(true, true)
        end
        worldView.viewLeft:EnableResourceRendering(preNISSettings.Resources)
        worldView.viewLeft:SetCartographic(preNISSettings.Cartographic)
        -- TODO: Restore settings of overlays, life-bars properly
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
        import("/lua/ui/game/consoleecho.lua").ToggleOutput(true)
    end
    import("/lua/ui/game/missiontext.lua").SetLayout()
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
        if import("/lua/ui/campaign/campaignmanager.lua").campaignMode then
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
        local views = import("/lua/ui/game/worldview.lua").GetWorldViews()
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
        import("/lua/ui/game/economy.lua").ToggleEconPanel(not observing)
    end
    if HasCommandLineArg("/syncreplay") and HasCommandLineArg("/gpgnet") then
        GpgNetSend("BEAT",GameTick(),GetGameSpeed())
    end
end

SendChat = function()
    while true do
        if UnitData.Chat then
            if not table.empty(UnitData.Chat) then
                for index, chat in UnitData.Chat do
                    local newChat = true
                    if not table.empty(oldData) then
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

-----------------------------------------------------------------------------------------------
--- Selection related functionality
--- 
--- There's a tricky flow going on in this section. It is important to understand it before you
--- try to interact with it.
---
--- The goal is to filter the selection based on some preferences. The flow that is the engine
--- walks through is:
---
--- - (1) (engine)  Selection event: either through `SelectUnits` or the user selecting units
--- - (2) (engine)  Filtering of selection: this is where the engine excludes engineers
--- - (3) (Lua)     Selection changed event: the call to `OnSelectionChanged`
---
--- We can not access step (2) to add our own filtering based on some preferences. Therefore we 
--- introduced our own, adjusted flow:
---
--- - (1) (engine)  Selection event: either through `SelectUnits` or the user selecting units
--- - (2) (engine)  Filtering of selection: this is where the engine excludes engineers
--- - (3) (Lua)     Filtering of selection in Lua via `OnSelectionChanged`
--- - (4) (engine)  Selection event through `SelectUnits`
--- - (5) (engine)  Filtering of selection
--- - (6) (Lua)     Selection changed event: the second call to `OnSelectionChanged` with the 
---                     correct selection
--- 
--- But the complexity doesn't end there: there are a lot of mods that hook the `OnSelectionChanged`
--- function which is now being called multiple times, with wrong parameters! As an example, the
--- following parameters make no sense in the new flow:
---
--- - `added`: list of units that are introduced
--- - `removed`: list of units that are removed
--- - `oldSelection`: list of units that we previously selected
---
--- These parameters make no sense because they are applied between steps 3 and 6, which is therefore 
--- no longer representative of the actual changes. 
---
--- And all of that on top of various strange hooks and calls that makes this function a gigantic mess.

local hotkeyLabelsOnSelectionChanged = false
local upgradeTab = import("/lua/keymap/upgradetab.lua").upgradeTab

local PrefsDeselectByLayer = Prefs.GetFromCurrentProfile('options.options_selection_filtering_layer')
function UpdatePrefsDeselectByLayer(value)
    PrefsDeselectByLayer = value
end

local PrefsDeselectAssistingEngineers = Prefs.GetFromCurrentProfile('options.options_selection_filter_assisting_engineers')
function UpdatePrefsDeselectAssistingEngineers(value)
    PrefsDeselectAssistingEngineers = value
end

local PrefsDeselectAssistingUnits = Prefs.GetFromCurrentProfile('options.options_selection_filter_assisting_units')
function UpdatePrefsDeselectAssistingUnits(value)
    PrefsDeselectAssistingUnits = value
end

--- allows us to ignore the depriorization phase
local ignoreFiltering = false
function IgnoreFiltering()
    ignoreFiltering = true
end

-- allows us to entirely ignore the selection event
local ignoreSelection = false
function SetIgnoreSelection(ignore)
    ignoreSelection = ignore
    import("/lua/ui/game/commandmode.lua").SetIgnoreSelection(ignore)
end

--- Deselects units by their layer type
---@param selection UserUnit[]
---@param count number
---@return UserUnit[]
---@return number
function DeselectByLayer(selection, count)
    local units, unitCount
    if PrefsDeselectByLayer == 'L+N/A' then
        -- find and return land or naval units
        units = EntityCategoryFilterDown(categories.LAND + categories.AMPHIBIOUS + categories.NAVAL + categories.HOVER, selection)
        unitCount = table.getn(units)

        if unitCount > 0 then
            return units, unitCount
        end

        -- find and return air units
        units = EntityCategoryFilterDown(categories.AIR, selection)
        unitCount = table.getn(units)

        if unitCount > 0 then
            return units, unitCount
        end

    elseif PrefsDeselectByLayer == 'L/N/A' then
        -- find and return land units
        units = EntityCategoryFilterDown(categories.LAND + categories.AMPHIBIOUS + categories.HOVER, selection)
        unitCount = table.getn(units)

        if unitCount > 0 then
            return units, unitCount
        end

        -- find and return naval units
        units = EntityCategoryFilterDown(categories.NAVAL, selection)
        unitCount = table.getn(units)

        if unitCount > 0 then
            return units, unitCount
        end

        -- find and return air units
        units = EntityCategoryFilterDown(categories.AIR, selection)
        unitCount = table.getn(units)

        if unitCount > 0 then
            return units, unitCount
        end
    elseif PrefsDeselectByLayer == 'N/L/A' then
        -- find and return naval units
        units = EntityCategoryFilterDown(categories.NAVAL, selection)
        unitCount = table.getn(units)

        if unitCount > 0 then
            return units, unitCount
        end

        -- find and return land units
        units = EntityCategoryFilterDown(categories.LAND + categories.AMPHIBIOUS + categories.HOVER, selection)
        unitCount = table.getn(units)

        if unitCount > 0 then
            return units, unitCount
        end

        -- find and return air units
        units = EntityCategoryFilterDown(categories.AIR, selection)
        unitCount = table.getn(units)

        if unitCount > 0 then
            return units, unitCount
        end
    end

    return selection, count
end

--- Deselects units that are locked out
---@param selection UserUnit[]
---@param count number
---@return UserUnit[]
---@return number
function DeselectLockedOut(selection, count)
    -- try and filter locked out units
    local head = 1
    for k = 1, count do
        local userUnit = selection[k]
        if not userUnit.LockedOutOfSelection then
            selection[head] = userUnit
            head = head + 1
        end
    end

    -- if we end up with nothing, just keep the selection
    if head == 1 then
        return selection, count
    end

    -- remove units that are no longer part of the selection
    for k = head, count do
        selection[k] = nil
    end

    return selection, head - 1
end

---@param selection UserUnit[]
---@param count number
---@return UserUnit[]
---@return number
function DeselectAssistingEngineers(selection, count)
    -- try and filter locked out units
    local head = 1
    for k = 1, count do
        local userUnit = selection[k]
        if not (userUnit:GetBlueprint().CategoriesHash["ENGINEER"] and userUnit:GetGuardedEntity()) then
            selection[head] = userUnit
            head = head + 1
        end
    end

    -- if we end up with nothing, just keep the selection
    if head == 1 then
        return selection, count
    end

    -- remove units that are no longer part of the selection
    for k = head, count do
        selection[k] = nil
    end

    return selection, head - 1
end

---@param selection UserUnit[]
---@param count number
---@return UserUnit[]
---@return number
function DeselectAssistingUnits(selection, count)
    -- try and filter locked out units
    local head = 1
    for k = 1, count do
        local userUnit = selection[k]
        if not (not userUnit:GetBlueprint().CategoriesHash["ENGINEER"] and userUnit:GetGuardedEntity()) then
            selection[head] = userUnit
            head = head + 1
        end
    end

    -- if we end up with nothing, just keep the selection
    if head == 1 then
        return selection, count
    end

    -- remove units that are no longer part of the selection
    for k = head, count do
        selection[k] = nil
    end

    return selection, head - 1
end

-- Function to remove low priority units from a selection which includes units other than low priority ones
function DeselectSelens(selection)
    local LowPriorityUnits = false
    local otherUnits = false

    -- Find any units with the low priority flag
    for id, unit in selection do
        -- Stupid-ass UnitData table uses string number IDs as keys
        if UnitData[unit:GetEntityId()].LowPriority then
            LowPriorityUnits = true
        else
            if not otherUnits then otherUnits = {} end -- Ugly hack to make later logic easier
            table.insert(otherUnits, unit)
        end
    end

    -- Return original selection with no-change key if nothing has changed
    if (otherUnits and not LowPriorityUnits) or (not otherUnits and LowPriorityUnits) then
        return selection, false
    end

    return otherUnits, true
end

--- A cache used with ObserveSelection to prevent continious table allocations
local cachedSelection = {
    oldSelection = { },
    newSelection = { },
    added = { },
    removed = { },
}

--- Observable to allow mods to do something with a new selection
ObserveSelection = import("/lua/shared/observable.lua").Create()

-- This function is called whenever the set of currently selected units changes
-- See /lua/unit.lua for more information on the lua unit object
---@param oldSelection UserUnit[]   This parameter is usually wrong and you should not use it
---@param newSelection UserUnit[]   
---@param added UserUnit[]          This parameter is usually wrong and you should not use it
---@param removed UserUnit[]        This parameter is usually wrong and you should not use it
function OnSelectionChanged(oldSelection, newSelection, added, removed)

    -- allows us to ignore the selection - including the selection sound
    if ignoreSelection then
        return
    end

    -- unironically, allows us to ignore the selection - including the selection sound
    if import("/lua/ui/game/selection.lua").IsHidden() then
        return
    end

    -- allows us to ignore the deprioritzation for this selection
    if ignoreFiltering then
        ignoreFiltering = false

    else
        -- do not ignore selections when holding down shift
        if not IsKeyDown('Shift') and not table.empty(added) and table.empty(removed) then
            ---@type number
            local originalCount = table.getn(newSelection)

            -- go through the various deprioritzation categories
            local selection, count = newSelection, originalCount
            selection, count = DeselectLockedOut(selection, count)

            if PrefsDeselectByLayer ~= 'off' then
                selection, count = DeselectByLayer(selection, count)
            end

            if PrefsDeselectAssistingEngineers ~= 'off' then
                selection, count = DeselectAssistingEngineers(selection, count)
            end

            if PrefsDeselectAssistingUnits ~= 'off' then
                selection, count = DeselectAssistingUnits(selection, count)
            end

            -- if something changed then we re-select the units through this hacky-approach
            if originalCount != count then
                ForkThread(
                    function()
                        IgnoreFiltering()
                        SelectUnits(selection)
                    end
                )
                return
            end
        end
    end

    -- populate observable and send out a notification
    cachedSelection.oldSelection = oldSelection
    cachedSelection.newSelection = newSelection
    cachedSelection.added = added
    cachedSelection.removed = removed
    ObserveSelection:Set(cachedSelection)

    -- apparently we can't import these files at the start, therefore we have this odd pattern
    if not hotkeyLabelsOnSelectionChanged then
        hotkeyLabelsOnSelectionChanged = import("/lua/keymap/hotkeylabels.lua").onSelectionChanged
    end

    -- Deselect Selens if necessary. Also do work on Hotbuild labels
    local changed = false -- Prevent recursion
    if newSelection and not table.empty(newSelection) then
        newSelection, changed = DeselectSelens(newSelection)

        if changed then
            ForkThread(function()
                SelectUnits(newSelection)
            end)
            return
        end

        -- This bit is for the Hotbuild labels. See the buildActionUpgrade() function in hotbuild.lua for a bit more
        -- documentation
        local bp = newSelection[1]:GetBlueprint()
        local upgradesTo = nil
        local potentialUpgrades = upgradeTab[bp.BlueprintId] or {bp.General.UpgradesTo}
        if potentialUpgrades then
            local availableOrders, availableToggles, buildableCategories = GetUnitCommandData(newSelection)
            for _, upgr in potentialUpgrades do
                if EntityCategoryContains(buildableCategories, upgr) then
                    upgradesTo = upgr
                    break
                end
                local nextSuccessiveUpgrade = __blueprints[upgr].General.UpgradesTo
                while nextSuccessiveUpgrade do
                    -- Note: Should we ever add a structure that has different upgrade path choices on a non-base
                    -- version of the structure, e.g. different choices for the 4th cybran shield upgrade or something
                    -- like it, the way we find the correct icon to put the hotbuild upgrade keybind label using this
                    -- while loop will break. As there currently is no such structure in the game, and I don't know how
                    -- the general case of finding that correct icon should work in such an imaginary case, I'll leave
                    -- it at this, currently working, code.
                    if EntityCategoryContains(buildableCategories, nextSuccessiveUpgrade) then
                        upgradesTo = nextSuccessiveUpgrade
                        break
                    end
                    nextSuccessiveUpgrade = __blueprints[nextSuccessiveUpgrade].General.UpgradesTo
                end
            end
        end

        if upgradesTo and upgradesTo:len() < 7 then
            upgradesTo = nil
        end
        local isFactory = newSelection[1]:IsInCategory("FACTORY")
        hotkeyLabelsOnSelectionChanged(upgradesTo, isFactory)
    end

    local availableOrders, availableToggles, buildableCategories = GetUnitCommandData(newSelection)
    local isOldSelection = table.equal(oldSelection, newSelection)

    if not gameUIHidden then
        if not isReplay then
            import("/lua/ui/game/orders.lua").SetAvailableOrders(availableOrders, availableToggles, newSelection)
        end
        -- TODO change the current command mode if no longer available? or set to nil?
        import("/lua/ui/game/construction.lua").OnSelection(buildableCategories,newSelection,isOldSelection)
    end

    if not isOldSelection then
        import("/lua/ui/game/selection.lua").PlaySelectionSound(added)
        import("/lua/ui/game/rallypoint.lua").OnSelectionChanged(newSelection)
        if Prefs.GetFromCurrentProfile('options.repeatbuild') == 'On' then
            local factories = EntityCategoryFilterDown(categories.STRUCTURE * categories.FACTORY, added) -- find all newly selected factories
            for _, factory in factories do
                if not factory.HasBeenSelected then
                    factory:ProcessInfo('SetRepeatQueue','true')
                    factory.HasBeenSelected = true
                end
            end
        end

    end

    if newSelection then
        local n = table.getn(newSelection)

        -- if something died in selection, restore command mode
        if n > 0 and not table.empty(removed) and table.empty(added) then
            local CM = import("/lua/ui/game/commandmode.lua")
            local mode, data = unpack(CM.GetCommandMode())

            if mode then
                ForkThread(function()
                    CM.StartCommandMode(mode, data)
                end)
            end
        end
    end

    import("/lua/ui/game/unitview.lua").OnSelection(newSelection)
end

function OnQueueChanged(newQueue)
    if not gameUIHidden then
        import("/lua/ui/game/construction.lua").OnQueueChanged(newQueue)
    end
end