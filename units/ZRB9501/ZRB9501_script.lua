#****************************************************************************
#**
#**  File     :  /cdimage/units/ZRB9501/ZRB9501_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  Cybran T2 Land Factory Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local CLandFactoryUnit = import('/lua/cybranunits.lua').CLandFactoryUnit

ZRB9501 = Class(CLandFactoryUnit)({
    BuildAttachBone = 'Attachpoint',
    UpgradeThreshhold1 = 0.267,
    UpgradeThreshhold2 = 0.53,
})
TypeClass = ZRB9501
