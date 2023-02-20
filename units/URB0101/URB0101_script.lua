--****************************************************************************
--**
--**  File     :  /cdimage/units/URB0101/URB0101_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Cybran T1 Land Factory Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local CLandFactoryUnit = import("/lua/cybranunits.lua").CLandFactoryUnit

---@class URB0101 : CLandFactoryUnit
URB0101 = ClassUnit(CLandFactoryUnit) {
    BuildAttachBone = 'Attachpoint',
    UpgradeThreshhold1 = 0.167,
    UpgradeThreshhold2 = 0.5,
}
TypeClass = URB0101