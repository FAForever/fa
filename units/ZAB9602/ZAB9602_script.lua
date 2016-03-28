#****************************************************************************
#**
#**  File     :  /cdimage/units/ZAB9602/ZAB9602_script.lua 
#**  Author(s):  John Comes, David Tomandl, Gordon Duclos
#**
#**  Summary  :  Aeon Unit Script 
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local AAirFactoryUnit = import('/lua/aeonunits.lua').AAirFactoryUnit
local SupportFactoryUnit = import('/lua/defaultunits.lua').SupportFactoryUnit

ZAB9602 = Class(AAirFactoryUnit, SupportFactoryUnit) {}

TypeClass = ZAB9602
