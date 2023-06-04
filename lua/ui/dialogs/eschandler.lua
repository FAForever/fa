--*****************************************************************************
--* File: lua/modules/ui/dialogs/eschandler.lua
--* Author: Chris Blackwell
--* Summary: Determines appropriate actions to take when the escape key is pressed in game
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local Prefs = import("/lua/user/prefs.lua")

local quickDialog = false

-- Terminate the game in a vaguely graceful fashion. This may or may not reduce the amount of times
-- sudden quits lead to players having to wait for a timeout.
function SafeQuit()
    if SessionIsActive() and not SessionIsReplay() then
        ForkThread(function ()
            ConExecute('ren_oblivion true')
            ConExecute('ren_ui false')
            SessionEndGame()
            WaitSeconds(0.1)
            ExitApplication()
        end)
    else
        ExitApplication()
    end
end

-- Stack of escape handlers. The topmost one is called when escape is pressed.
local escapeHandlers = {}

--- Push a new escape handler onto the stack. This becomes the current escape handler, ahead of the
-- old one.
--
-- @param handler
--
-- @see PopEscapeHandler
function PushEscapeHandler(handler)
    table.insert(escapeHandlers, handler)
end

--- Remove the current escape handler and restore the previous one pushed.
function PopEscapeHandler()
    if table.empty(escapeHandlers) then
        LOG("Error popping escape handler, stack is empty")
        LOG(repr(debug.traceback()))
        return
    end
    table.remove(escapeHandlers)
end

--- Default escape handler
-- Gets called with quit_game = True regardless of keybindings
-- if the main escape button for the game is pressed.
--
-- Also the default keyaction for the 'escape' key.
--
-- @param quit_game
function HandleEsc(quit_game)
    -- If we've registered a custom escape handler, call it.
    local eschandler = escapeHandlers[table.getn(escapeHandlers)]
    -- If quit_game is true, allow users to exit regardless
    -- of any escape handlers
    if eschandler and not quit_game then
        eschandler()
        return
    end

    local function CreateYesNoDialog()
        if quickDialog then
            return
        end
        GetCursor():Show()
        quickDialog = UIUtil.QuickDialog(GetFrame(0), "<LOC EXITDLG_0000>Are you sure you'd like to quit?",
            "<LOC _Yes>", function() SafeQuit() end,
            "<LOC _No>", function() quickDialog:Destroy() quickDialog = false end,
            nil, nil,
            true,
            {escapeButton = 2, enterButton = 1, worldCover = true})
    end

    if quit_game then
        if Prefs.GetOption('quick_exit') == 'true' then
            SafeQuit()
        else
            CreateYesNoDialog()
        end
    elseif import("/lua/ui/game/commandmode.lua").GetCommandMode()[1] ~= false then
        import("/lua/ui/game/commandmode.lua").EndCommandMode(true)
    elseif GetSelectedUnits() then
        SelectUnits(nil)
    end
end

-- kept for mod backwards compatibility
local Utils = import("/lua/system/utils.lua")