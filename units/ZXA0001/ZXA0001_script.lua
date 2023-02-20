-----------------------------------------------------------------
-- File     :  /cdimage/units/UEA0003/UEA0003_script.lua
-- Summary  :  UEF sACU Pod Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local TConstructionUnit = import("/lua/terranunits.lua").TConstructionUnit

---@class ZXA0001 : TConstructionUnit
ZXA0001 = ClassUnit(TConstructionUnit) {
    OnCreate = function(self)
        TConstructionUnit.OnCreate(self)
        
        self:SetUnSelectable(true)
        self:SetDoNotTarget(true)
        self:SetCollisionShape('None')
        self:SetVizToAllies('Never')
        self:SetVizToEnemies('Never')
        self:SetVizToFocusPlayer('Never')
        self:SetVizToNeutrals('Never')
    end,
}
    
TypeClass = ZXA0001
