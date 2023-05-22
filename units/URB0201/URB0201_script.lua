--****************************************************************************
--**
--**  File     :  /cdimage/units/URB0201/URB0201_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Cybran T2 Land Factory Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local CLandFactoryUnit = import("/lua/cybranunits.lua").CLandFactoryUnit

---@class URB0201 : CLandFactoryUnit
URB0201 = ClassUnit(CLandFactoryUnit) {
    BuildAttachBone = 'Attachpoint',
    UpgradeThreshhold1 = 0.267,
    UpgradeThreshhold2 = 0.53,
}
TypeClass = URB0201
