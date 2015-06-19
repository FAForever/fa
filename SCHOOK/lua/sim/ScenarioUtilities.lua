----[                                                                             ]--
----[  File     : ScenarioUtilities.lua                                           ]--
----[  Author(s): Ivan Rumsey                                                     ]--
----[                                                                             ]--
----[  Summary  : Utility functions for use with scenario save file.              ]--
----[             Created from examples provided by Jeff Petkau.                  ]--
----[                                                                             ]--
----[  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.             ]--
local Entity = import('/lua/sim/Entity.lua').Entity

-- Creates an army group at a certain veteran level
function CreateArmyGroupAsPlatoonVeteran(strArmy, strGroup, formation, veteranLevel)
    local plat = CreateArmyGroupAsPlatoon(strArmy, strGroup, formation)
    veteranLevel = veteranLevel or 5
    for k,v in plat:GetPlatoonUnits() do
        v:SetVeterancy(veteranLevel)
    end
    return plat
end
