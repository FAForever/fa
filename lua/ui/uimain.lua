--*****************************************************************************
--* File: lua/modules/ui/uimain.lua
--* Author: Chris Blackwell
--* Summary: The entry point for UI scripting
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local UIFile = UIUtil.UIFile
local Prefs = import("/lua/user/prefs.lua")
local Text = import("/lua/maui/text.lua").Text
local OnlineProvider = import("/lua/multiplayer/onlineprovider.lua")
local CampaignManager = import("/lua/ui/campaign/campaignmanager.lua")

local console = false
local alreadySetup = false

--* Initialize the UI states, this is always called on startup
function SetupUI()

    -- SetCursor needs to happen anytime this function is called because we
    -- could be switching lua states.
    local c = UIUtil.CreateCursor()
    SetCursor( c )

    -- the rest of this function only needs to run once to set up the globals, so 
    -- don't do it again if not needed
    if alreadySetup then return end
    alreadySetup = true

    UIUtil.currentLayout = Prefs.GetFromCurrentProfile('layout') or 'bottom'
    local skin = Prefs.GetFromCurrentProfile('skin')
    UIUtil.SetCurrentSkin(skin or 'uef')    -- default skin to start

    UIUtil.consoleDepth = 5000000 -- no UI element should depth higher than this!
end

-- THE FOLLOWING FUNCTIONS SHOULD NOT BE CALLED FROM LUA CODE
-- THEY ARE CALLED FROM THE ENGINE AND EXPECT A DIFFERENT LUA STATE
function StartSplashScreen()
    console = false
    import("/lua/ui/splash/splash.lua").CreateUI()
end

function StartFrontEndUI()
    console = false
    
    -- make sure cheat keys are disabled if needed
    if not DebugFacilitiesEnabled() then
        local keyMap = import("/lua/keymap/defaultkeymap.lua")
        IN_RemoveKeyMapTable(keyMap.debugKeyMap)                
    end    
    
    -- if there is an auto continue state, then launch op immediately
    if GetFrontEndData('NextOpBriefing') then
        CampaignManager.LaunchBriefing(GetFrontEndData('NextOpBriefing'))
    else
        import("/lua/ui/menus/main.lua").CreateUI()
    end
    if GetNumRootFrames() > 1 then
        import("/lua/ui/game/multihead.lua").ShowLogoInHead1()
    end
end

--- Hosts a multiplayer LAN lobby.
--- Called by the engine with the command line argument `/hostgame <protocol> <port> <playerName> <gameName> <mapFile>`
--- Add the argument `/players <number>` to use the auto lobby. `/<factionName>` to choose a faction.
---@param protocol UILobbyProtocols
---@param port number
---@param playerName string
---@param gameName string
---@param mapFile FileName
---@param natTraversalProvider userdata?
function StartHostLobbyUI(protocol, port, playerName, gameName, mapFile, natTraversalProvider)
    LOG("Hosting lobby from the command line")
    local lobby
    -- auto lobby only works with 2+ players
    local autoStart = GetCommandLineArg("/players", 1)[1] >= 2
    if autoStart then   
        lobby = import("/lua/ui/lobby/autolobby.lua")
    else
        lobby = import("/lua/ui/lobby/lobby.lua")
    end
    lobby.CreateLobby(protocol, port, playerName, nil, natTraversalProvider, GetFrame(0), StartFrontEndUI)
    lobby.HostGame(gameName, mapFile, false)
end

--- Joins a multiplayer lobby.
--- Called by the engine with the command line argument `/joingame <protocol> <address> <playerName>`
--- Add the argument `/players <number>` to use the auto lobby. `/<factionName>` to choose a faction.
---@param protocol UILobbyProtocols
---@param address string
---@param playerName string
---@param natTraversalProvider userdata?
function StartJoinLobbyUI(protocol, address, playerName, natTraversalProvider)
    LOG("Joining lobby from the command line") -- can also be from lobby.lua ReturnToMenu(true), but that never gets called
    local lobby
    -- auto lobby only works with 2+ players
    local autoStart = GetCommandLineArg("/players", 1)[1] >= 2
    if autoStart then
        lobby = import("/lua/ui/lobby/autolobby.lua")
    else
        lobby = import("/lua/ui/lobby/lobby.lua")
    end
    local port = 0
    lobby.CreateLobby(protocol, port, playerName, nil, natTraversalProvider, GetFrame(0), StartFrontEndUI)
    lobby.JoinGame(address, false)
end

function StartGameUI()
    console = false
    import("/lua/ui/game/gamemain.lua").CreateWldUIProvider()
end
-- END SHOULD NOT BE CALLED FROM LUA CODE

-- toggle the console window (create if needed)
function ToggleConsole()
    if console then
        if console:IsHidden() then
            console:Show()
        else
            console:Hide()
        end
    else
        console = import("/lua/ui/dialogs/console.lua").CreateDialog()
        console:Show()
    end
end

--* The following scripts are alternate entry points to the UI from the engine
--* Typically these are dialog popup type calls

--- Called by engine when closing the app or calling UI_Quit in console
---@param yesNoOnly boolean # true when closing the app
function ShowEscapeDialog(yesNoOnly)
    import("/lua/ui/dialogs/eschandler.lua").HandleEsc(yesNoOnly)
end

-- when escape is pressed and it's not captured by any controls, this defines the behvaior of what should occur
local escapeHandler = nil

function SetEscapeHandler(handler)
    escapeHandler = handler
end

--- Used by the "escape" key action (default action for esc key)
function EscapeHandler()
    -- faf-re engine only: Escape first stops a replay timeline move under way.
    if rawget(_G, 'GetEngineInfo') and import("/lua/ui/game/replay_timeline.lua").OnEscape() then
        return
    end
    if not WorldIsLoading() and (import("/lua/ui/game/gamemain.lua").supressExitDialog != true) then
        if escapeHandler then
            escapeHandler()
        else
            import("/lua/ui/dialogs/eschandler.lua").HandleEsc()
        end
    end
end

-- network disconnection/boot dialog
local prevDisconnectModule
function UpdateDisconnectDialog()
    local module = import("/lua/ui/dialogs/disconnect.lua")
    if prevDisconnectModule and prevDisconnectModule != module then
        pcall(prevDisconnectModule.DestroyDialog)
    end
    prevDisconnectModule = module
    module.Update()
end

function NoteGameSpeedChanged(clientIndex, newSpeed)
    local clients = GetSessionClients()
    local client = clients[clientIndex]
    -- Note: this string has an Engine loc tag because it was
    -- originally in the engine.  If we were not already past the loc
    -- deadline, I'd change to to be some UI loc tag.  But we are, so
    -- I'm not going to change it and risk the wrath of the producers.
    print(LOCF("<LOC Engine0006>%s: adjusting game speed to %+d", client.name, newSpeed))
    import("/lua/ui/game/score.lua").NoteGameSpeedChanged(newSpeed)
    import('/lua/ui/game/objectives2.lua').NoteGameSpeedChanged(newSpeed)
end

function NoteGameOver()
    SetFocusArmy(-1)
    if not import("/lua/ui/dialogs/score.lua").scoreScreenActive then
        GetCursor():Show()
    end
    if SessionIsReplay() then
        import("/lua/ui/game/score.lua").ArmyAnnounce(1, '<LOC _Replay_over>Replay over.')
    else
        import("/lua/ui/game/score.lua").ArmyAnnounce(1, '<LOC _Game_over>Game over.')
    end
end

---@alias ClickType "ButtonPress" | "ButtonDClick"

---@class MouseButtonEvent
---@field Type ClickType
---@field x number
---@field y number

---@type fun(event: MouseButtonEvent)[]
local mouseClickFuncs = {}

--- Called by the engine when the left, right, or middle mouse buttons are pressed.
---@param event MouseButtonEvent
function OnMouseButtonPress(event)
    if mouseClickFuncs and table.getsize(mouseClickFuncs) > 0 then
        for _, func in mouseClickFuncs do
            func(event)
        end
    end
end

---@param func fun(event: MouseButtonEvent)
function AddOnMouseClickedFunc(func)
    table.insert(mouseClickFuncs, func)
end

---@param func fun(event: MouseButtonEvent)
function RemoveOnMouseClickedFunc(func)
    local i = 1
    local found = false
    while mouseClickFuncs[i] do
        if mouseClickFuncs[i] == func then
            found = true
            break
        end
        i = i + 1
    end
    if found then
        table.remove(mouseClickFuncs, i)
    end
end

-- network desync info
function ShowDesyncDialog(beatNumber, strings)
    import("/lua/ui/dialogs/desync.lua").UpdateDialog(beatNumber, strings)
end

--* The following functions are invoked by the engine to show some text at a certain location
--TODO keep a table of cursor texts to have multiple available?
local cursorText = false

function StartCursorText(x, y, text, color, time, flash)
    if cursorText and cursorText._inTimer then return end -- if cursor text has a time, don't stomp it
    if cursorText then cursorText:Destroy() end
    cursorText = Text(GetFrame(0))
    cursorText:SetText(LOC(text))
    cursorText:SetColor(color)
    cursorText:SetFont(UIUtil.bodyFont, 18)
    cursorText:SetDropShadow(true)
    cursorText.Left:Set(x + 16)
    cursorText.Top:Set(y)

    cursorText:SetNeedsFrameUpdate(true)

    cursorText.OnFrame = function(self, elapsedTime)
        if flash then
            if not cursorText._flashTime then
                cursorText._flashTime = 0
            else
                cursorText._flashTime = cursorText._flashTime + elapsedTime
            end
            if cursorText._flashTime > 0.25 then -- 1/4 second flashes
                cursorText:SetHidden(not cursorText:IsHidden())
                cursorText._flashTime = 0
            end
        end

        if not cursorText._time then
            cursorText._time = 0
        else
            cursorText._time = cursorText._time + elapsedTime
        end
        if time > 0 then
            cursorText._inTimer = true
            if time < (cursorText._time) then
                cursorText:Destroy()
                cursorText = nil
            end
        end
    end
end

function StopCursorText()
    if cursorText and cursorText._inTimer then return end -- if cursor text has a time, don't stomp it
    if cursorText then cursorText:Destroy() end
end

function IncreaseGameSpeed()
    if not WorldIsLoading() and (import("/lua/ui/game/gamemain.lua").supressExitDialog != true) then
        ConExecute('WLD_IncreaseSimRate')
    end    
end

function DecreaseGameSpeed()
    if not WorldIsLoading() and (import("/lua/ui/game/gamemain.lua").supressExitDialog != true) then
        ConExecute('WLD_DecreaseSimRate')
    end    
end

function OnApplicationResize(head, width, height)
    -- resize can cause odd ui behavior in construction manager, so just deselect after a resize
    SelectUnits(nil)
end

-- faf-re engine only: the screen of a player taking a seat back (Draiget/faf-re#275).
-- GetEngineInfo exists only in faf-re, so on the original executable none of this runs.
if rawget(_G, 'GetEngineInfo') then
    -- Draiget/faf-re#275: what the player taking a seat back sees. The engine calls these only
    -- in a client started with /rejoin. Before the map loads there is no other screen,
    -- while it loads this sits over the loading screen, and while the game so far runs
    -- it covers the game, so nobody watches it run at full speed.

    do
        local UIUtil = import("/lua/ui/uiutil.lua")
        local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
        local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
        local Movie = import("/lua/maui/movie.lua").Movie
        local Prefs = import("/lua/user/prefs.lua")

        local barWidth = 520
        local screen = false

        --- The game's loading screen as `LoadDialog` in gamemain.lua makes it, so the view doesn't
        --- change when the real one takes over for the map.
        local function CreateTransit(cover)
            local frame = GetFrame(0)
            local movieFile = '/movies/UEF_load.sfd'
            local color = 'FFbadbdb'
            local faction = import("/lua/factions.lua").Factions[Prefs.GetFromCurrentProfile('LoadingFaction')]
            if faction and faction.loadingMovie then
                movieFile = faction.loadingMovie
                color = faction.loadingColor
            end

            local movie = Movie(cover, movieFile)
            LayoutHelpers.FillParent(movie, frame)
            movie:Loop(true)
            movie:Play()

            local text = UIUtil.CreateText(movie, '::  ' .. LOC('<LOC LOAD_0000>IN TRANSIT') .. '  ::', 20, UIUtil.bodyFont)
            text:SetColor(color)
            text:SetDropShadow(true)
            LayoutHelpers.AtCenterIn(text, frame, 200)
            import("/lua/maui/effecthelpers.lua").Pulse(text, 1, 0, .8)
            return movie
        end

        local function CreateScreen()
            local frame = GetFrame(0)

            local cover = Bitmap(frame)
            cover.Depth:Set(frame:GetTopmostDepth() + 1)
            LayoutHelpers.FillParent(cover, frame)

            -- Under IN TRANSIT, which both this screen and the loading screen show at this height.
            cover.text = UIUtil.CreateText(cover, '', 18, UIUtil.bodyFont)
            cover.text:SetColor('FFbadbdb')
            cover.text:SetDropShadow(true)
            cover.text.Depth:Set(function() return cover.Depth() + 10 end)
            LayoutHelpers.AtHorizontalCenterIn(cover.text, frame)
            cover.text.Top:Set(function() return frame.Top() + 0.5 * frame.Height() + LayoutHelpers.ScaleNumber(230) end)

            cover.track = Bitmap(cover)
            cover.track:SetSolidColor('ff303030')
            cover.track.Depth:Set(function() return cover.Depth() + 10 end)
            LayoutHelpers.SetDimensions(cover.track, barWidth, 10)
            LayoutHelpers.AtHorizontalCenterIn(cover.track, frame)
            cover.track.Top:Set(function() return cover.text.Bottom() + LayoutHelpers.ScaleNumber(8) end)

            cover.fill = Bitmap(cover.track)
            cover.fill:SetSolidColor('ff4fa0e0')
            LayoutHelpers.SetDimensions(cover.fill, 1, 10)
            LayoutHelpers.AtLeftTopIn(cover.fill, cover.track, 0, 0)

            return cover
        end

        local function StageText(stage, progress)
            -- No measure: the travelling block alone says it is under way.
            local percent = ''
            if progress >= 0 then
                percent = string.format(": %d%%", math.floor(progress * 100))
            end
            if stage == 'connecting' then
                return LOC("<LOC rejoin_0010>Reconnecting to the game")
            elseif stage == 'transfer' then
                return LOC("<LOC rejoin_0011>Reconnecting: receiving the game so far") .. percent
            elseif stage == 'loading' then
                return LOC("<LOC rejoin_0012>Rejoining the game: loading the map")
            end
            return LOC("<LOC rejoin_0013>Rejoining the game: catching up") .. percent
        end

        --- `stage` is 'connecting', 'transfer', 'loading' or 'catchingUp', with `progress`
        --- 0 to 1 or negative when there is no measure; '' takes the screen away.
        function UpdateRejoinScreen(stage, progress)
            if stage == '' then
                if screen and not IsDestroyed(screen) then
                    screen:Destroy()
                end
                screen = false
                return
            end

            -- A new Lua state takes over between the loading screen and the game.
            if not screen or IsDestroyed(screen) then
                screen = CreateScreen()
            end

            if screen.stage != stage then
                screen.stage = stage
                screen.stageStart = GetSystemTimeSeconds()
                LOG('REJOIN: screen says ' .. stage)
                -- The loading screen is itself what's on show during the load.
                screen:SetSolidColor(stage == 'loading' and '00000000' or 'ff000000')
                if stage == 'loading' then
                    if screen.transit then
                        screen.transit:Destroy()
                        screen.transit = false
                    end
                elseif not screen.transit then
                    screen.transit = CreateTransit(screen)
                end
            end

            screen.text:SetText(StageText(stage, progress))

            if progress >= 0 then
                LayoutHelpers.AtLeftTopIn(screen.fill, screen.track, 0, 0)
                LayoutHelpers.SetWidth(screen.fill, math.max(1, barWidth * progress))
            else
                -- No measure: a block that travels, so it can't be read as a percentage.
                local blockWidth = 60
                local travelled = math.mod(GetSystemTimeSeconds() - screen.stageStart, 3) / 3
                LayoutHelpers.AtLeftTopIn(screen.fill, screen.track, (barWidth - blockWidth) * travelled, 0)
                LayoutHelpers.SetWidth(screen.fill, blockWidth)
            end
        end

        function StartRejoinScreen()
            UpdateRejoinScreen('connecting', -1)
        end
    end
end