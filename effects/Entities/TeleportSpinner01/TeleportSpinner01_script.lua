--****************************************************************************
--**
--**  File     :  /effects/entities/TeleportSpinner01/TeleportSpinner01_script.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  :  Teleport Spinner effect object
--**
--**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell
local EffectTemplate = import("/lua/effecttemplates.lua")

TeleportSpinner01 = Class(NullShell) {
    OnCreate = function(self)
        NullShell.OnCreate(self)
        local army = self:GetArmy()
       
        for k, v in EffectTemplate.CSGTestSpinner1 do
            CreateEmitterOnEntity( self, army, v )
        end
    end,
}

TypeClass = TeleportSpinner01

