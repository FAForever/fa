--****************************************************************************
--**
--**  File     :  /lua/unittemplates.lua
--**  Author(s): John Comes
--**
--**  Summary  : The Template that links unit types to unit IDs
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

if not ScenarioInfo.GameHasAIs then
    WARN("Unit templates loaded in a non-ai game:" .. reprs(debug.traceback()))
end

UnitTemplates =
{
    -- Earth Unit List
    {
        -- Engineers
        {
            'Engineer',
            'uel0105', 
        },
        {
            'EngineerT2',
            'uel0208', 
        },
        {
            'EngineerT3',
            'uel0309', 
        },

    },
    
    -- Aeon Unit List
    {
        -- Engineers
        {
            'Engineer',
            'ual0105', 
        },
        {
            'EngineerT2',
            'ual0208', 
        },
        {
            'EngineerT3',
            'ual0309', 
        },

    },
    
    -- Cybran Unit List
    {
        -- Engineers
        {
            'Engineer',
            'ual0105', 
        },
        {
            'EngineerT2',
            'ual0208', 
        },
        {
            'EngineerT3',
            'ual0309', 
        },
        
    },
}
