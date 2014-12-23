--*****************************************************************************
--* File: lua/modules/ui/dialogs/eschandler.lua
--* Author: Chris Blackwell
--* Summary: Determines appropriate actions to take when the escape key is pressed in game
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import('/lua/ui/uiutil.lua')
local Prefs = import('/lua/user/prefs.lua')
local Utils = import('/lua/system/utils.lua')

local quickDialog = false

-- Ridiculous evil hack to perform graceful game exits.
-- Instead of just killing the app (which leads everyone to have to wait for a timeout), we call
-- the methods involved in terminating a game session. This will broadcast a message on the next
-- tick that will have everyone else boot us: we just have to keep the app alive long enough for
-- that to happen. A second *should* be sufficient, as more than that would've been lagging like a
-- fish in play anyway...
-- We use safeCall because none of these things will work sensibly if not in a game. It allows those
-- useless calls to be skipped over and an exit to be achieved in the usual case.
function SafeQuit()
    ExitGame()
    Utils.safecall("Don't panic.", SessionEndGame)
    Utils.safecall("Don't panic.", WaitSeconds, 1)
    ExitApplication()
end

-- If yesNoOnly is true, then the in game dialog will never be shown
function HandleEsc(yesNoOnly)

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

    if yesNoOnly then
        if Prefs.GetOption('quick_exit') == 'true' then
            SafeQuit()
        else
            CreateYesNoDialog()
        end
    elseif import('/lua/ui/game/commandmode.lua').GetCommandMode()[1] != false then
    import('/lua/ui/game/commandmode.lua').EndCommandMode(true)
    elseif GetSelectedUnits() then
        SelectUnits(nil)
    end
end