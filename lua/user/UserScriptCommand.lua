--*****************************************************************************
--* File: lua/modules/ui/game/userScriptCommand.lua
--* Summary: User layer ability handling
--*
--* Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local CM = import("/lua/ui/game/commandmode.lua")

--- Parameters of a script order given with a target in command mode.
--- Besides `TaskName`, the engine reads only these fields. Each task declares the other fields it reads in a subclass.
--- These checks only run in the UI, so a UI mod or console command can send any values:
--- the sim task must validate them
---@class VerifiedScriptTaskParams : ScriptTaskParams
---@field UserValidated boolean # The engine issues the order only when true. The sim task receives it too
---@field AuthorizedUnits? UserUnit[] # Units the engine gives the order to, instead of the selection. Removed before the table goes to the sim

--- Called by the engine when the player clicks in `RULEUCC_Script` command mode, on a unit or the ground.
--- The returned table becomes the order's parameters, so `TaskName` picks the sim task.
--- The engine issues the order only when `UserValidated` is true, and only to `AuthorizedUnits`.
--- The sim drops units the player doesn't control. When this function errors, the engine logs it and issues nothing.
--- `UserVerifyScript` in the command mode data replaces the default check, which authorizes every selected unit
---@see CommandModeDataOrderScript
---@param data UserCommand
---@return VerifiedScriptTaskParams result
function VerifyScriptCommand(data)
    local mode = CM.GetCommandMode()

    local result = {
        TaskName = mode[2].TaskName,
        UserValidated = false,
        Location = data.Target.Position
    }

    if mode[1] != "order" then
        WARN('VerifyScriptCommand() called when command mode is not "order"')
        return result
    end

    if mode[2].name != "RULEUCC_Script" then
        WARN('VerifyScriptCommand() called when command name is not "Script"')
        return result
    end

    --LOG('verify script: ',mode[2].UserVerifyScript)
    if mode[2].UserVerifyScript then
        import(mode[2].UserVerifyScript).VerifyScriptCommand(data,result)
    else
        result.AuthorizedUnits = data.Units
        result.UserValidated = true
    end

    return result
end
