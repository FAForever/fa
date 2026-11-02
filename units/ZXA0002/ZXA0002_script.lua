-----------------------------------------------------------------
-- File     :  /cdimage/units/UEA0003/UEA0003_script.lua
-- Summary  :  UEF sACU Pod Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local TConstructionUnit = import("/lua/terranunits.lua").TConstructionUnit

---@class ZXA0002 : TConstructionUnit
ZXA0002 = ClassUnit(TConstructionUnit) {
    ---@param self ZXA0002
    OnCreate = function(self)
        TConstructionUnit.OnCreate(self)
    end,
}

TypeClass = ZXA0002
