#****************************************************************************
#**
#**  File     :  /cdimage/units/XRB0204/XRB0204_script.lua
#**  Author(s):  Dru Staltman
#**
#**  Summary  :  Cybran Engineering tower
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local CConstructionStructureUnit = import('/lua/cybranunits.lua').CConstructionStructureUnit
local EffectUtil = import('/lua/EffectUtilities.lua')

SSB0304 = Class(CConstructionStructureUnit) 
{
    CreateBuildEffects = function( self, unitBeingBuilt, order )
        EffectUtil.CreateSeraphimUnitEngineerBuildingEffects( self, unitBeingBuilt, self:GetBlueprint().General.BuildBones.BuildEffectBones, self.BuildEffectsBag )
    end,
}
TypeClass = SSB0304
