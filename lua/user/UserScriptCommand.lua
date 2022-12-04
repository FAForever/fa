--*****************************************************************************
--* File: lua/modules/ui/game/userScriptCommand.lua
--* Summary: User layer ability handling
--*
--* Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************
local CM = import("/lua/ui/game/commandmode.lua")

-- The user wants to issue an ability order in the current command mode. This
-- function validates the request. If the request is valid we set 
-- UserValidated to allow the order to be issued. If it's not valid we end the 
-- commandmode or do nothing depending on the context.
--
-- VerifyAbility should return a result table of the following format:
-- result = {
--    string AbilityName - What ability to execute
--    string TaskName - Which task class to execute (e.g. AbilityTask, SkillTask)
--    bool UserValidated - Whether or not this request has been validated
--    table AuthorizedUnits - List of units to issue the command to
-- }
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
