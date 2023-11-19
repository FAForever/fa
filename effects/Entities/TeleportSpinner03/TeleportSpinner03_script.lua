------------------------------------------------------------------------------
-- File     :  /effects/entities/TeleportSpinner03/TeleportSpinner03_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Teleport Spinner effect object
-- Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------

local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell
local EffectTemplate = import("/lua/EffectTemplates.lua")

---@class TeleportSpinner03 : NullShell
TeleportSpinner03 = Class(NullShell) {

    ---@param self TeleportSpinner03
    OnCreate = function(self)
        NullShell.OnCreate(self)
        local army = self:GetArmy()

        for k, v in EffectTemplate.CSGTestSpinner3 do
            CreateEmitterOnEntity( self, army, v )
        end
    end,
}
TypeClass = TeleportSpinner03