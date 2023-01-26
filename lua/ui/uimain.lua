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


--Used by command line to host a game
function StartHostLobbyUI(protocol, port, playerName, gameName, mapName, natTraversalProvider)
    LOG("Command line hostlobby")
    local lobby = import("/lua/ui/lobby/lobby.lua")
    lobby.CreateLobby(protocol, port, playerName, nil, natTraversalProvider, GetFrame(0), StartFrontEndUI)
    lobby.HostGame(gameName, mapName, false)
end

--Used by command line to join a game
function StartJoinLobbyUI(protocol, address, playerName, natTraversalProvider)
    local lobby = import("/lua/ui/lobby/lobby.lua")
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

-- context sensitive exit dialog
function ShowEscapeDialog(yesNoOnly)
    import("/lua/ui/dialogs/eschandler.lua").HandleEsc(yesNoOnly)
end

-- when escape is pressed and it's not captured by any controls, this defines the behvaior of what should occur
local escapeHandler = nil

function SetEscapeHandler(handler)
    escapeHandler = handler
end

-- called by the engine when escape is pressed but there's no specific handler for it
function EscapeHandler()
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

local mouseClickFuncs = {}

function OnMouseButtonPress(event)
    if mouseClickFuncs and table.getsize(mouseClickFuncs) > 0 then
        for _, func in mouseClickFuncs do
            func(event)
        end
    end
end

function AddOnMouseClickedFunc(func)
    table.insert(mouseClickFuncs, func)
end

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