-- Automatically upvalued moho functions for performance
local GlobalMethods = _G
local GlobalMethodsCreateAttachedEmitter = GlobalMethods.CreateAttachedEmitter
-- End of automatically upvalued moho functions

--#****************************************************************************
--#**
--#**  File     :  /cdimage/units/UAB5202/UAB5202_script.lua
--#**  Author(s):  John Comes, David Tomandl
--#**
--#**  Summary  :  Aeon Air Staging Platform
--#**
--#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--#****************************************************************************
local SAirStagingPlatformUnit = import('/lua/seraphimunits.lua').SAirStagingPlatformUnit
local SeraphimAirStagePlat02 = import('/lua/EffectTemplates.lua').SeraphimAirStagePlat02
local SeraphimAirStagePlat01 = import('/lua/EffectTemplates.lua').SeraphimAirStagePlat01

XSB5202 = Class(SAirStagingPlatformUnit)({
    OnStopBeingBuilt = function(self, builder, layer)
        for k, v in SeraphimAirStagePlat02 do
            GlobalMethodsCreateAttachedEmitter(self, 'XSB5202', self.Army, v)
        end

        for k, v in SeraphimAirStagePlat01 do
            GlobalMethodsCreateAttachedEmitter(self, 'Pod01', self.Army, v)
            GlobalMethodsCreateAttachedEmitter(self, 'Pod02', self.Army, v)
            GlobalMethodsCreateAttachedEmitter(self, 'Pod03', self.Army, v)
            GlobalMethodsCreateAttachedEmitter(self, 'Pod04', self.Army, v)
            GlobalMethodsCreateAttachedEmitter(self, 'Pod05', self.Army, v)
            GlobalMethodsCreateAttachedEmitter(self, 'Pod06', self.Army, v)
        end

        SAirStagingPlatformUnit.OnStopBeingBuilt(self, builder, layer)
    end,
})

TypeClass = XSB5202
