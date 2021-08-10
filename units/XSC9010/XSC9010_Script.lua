--****************************************************************************
--** 
--**  File     :  /cdimage/units/XSC9002/XSC9002_script.lua 
--**  Author   :  Greg Kohne
--**  Summary  :  Jamming Crystal
--** 
--**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local SLandUnit = import('/lua/seraphimunits.lua').SLandUnit
local SSJammerCrystalAmbient = import('/lua/EffectTemplates.lua').SJammerCrystalAmbient


XSC9010 = Class(SLandUnit) {

    OnCreate = function(self, builder, layer)
        SLandUnit.OnCreate(self)
    end,



}


TypeClass = XSC9010


