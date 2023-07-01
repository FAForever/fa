--***************************************************************************
--*
--**  File     :  /lua/ai/SeaPlatoonTemplates.lua
--**
--**  Summary  : Global platoon templates
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

-- ==== Global Form platoons ==== --

PlatoonTemplate {
    Name = 'SeaRaid',
    Plan = 'GuardMarker',
    GlobalSquads = {
        { categories.MOBILE * categories.NAVAL * categories.SUBMERSIBLE * categories.TECH1, 1, 3, 'Attack', 'none' }
    },
}