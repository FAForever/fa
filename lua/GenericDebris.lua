--****************************************************************************
--**
--**  File     : /lua/GenericDebris.lua
--**  Summary  : Supreme Commander specific debris
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local BaseGenericDebris = import("/lua/sim/defaultprojectiles.lua").BaseGenericDebris
local EffectTemplates = import("/lua/EffectTemplates.lua")

---@class GenericDebris : BaseGenericDebris
GenericDebris = ClassDummyProjectile( BaseGenericDebris ){
    FxImpactLand = EffectTemplates.GenericDebrisLandImpact01,
    FxTrails = EffectTemplates.GenericDebrisTrails01,
}
