----****************************************************************************
----**
----**  File     :  /cdimage/units/UAB5202/UAB5202_script.lua
----**  Author(s):  John Comes, David Tomandl
----**
----**  Summary  :  Aeon Air Staging Platform
----**
----**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
----****************************************************************************
local SAirStagingPlatformUnit = import("/lua/seraphimunits.lua").SAirStagingPlatformUnit
local SeraphimAirStagePlat02 = import("/lua/effecttemplates.lua").SeraphimAirStagePlat02
local SeraphimAirStagePlat01 = import("/lua/effecttemplates.lua").SeraphimAirStagePlat01

---@class XSB5202 : SAirStagingPlatformUnit
XSB5202 = ClassUnit(SAirStagingPlatformUnit) {
    OnStopBeingBuilt = function(self,builder,layer)
        for k, v in SeraphimAirStagePlat02 do
            CreateAttachedEmitter(self, 'XSB5202', self.Army, v)
        end

        for k, v in SeraphimAirStagePlat01 do
            CreateAttachedEmitter(self, 'Pod01', self.Army, v)
            CreateAttachedEmitter(self, 'Pod02', self.Army, v)
            CreateAttachedEmitter(self, 'Pod03', self.Army, v)
            CreateAttachedEmitter(self, 'Pod04', self.Army, v)
            CreateAttachedEmitter(self, 'Pod05', self.Army, v)
            CreateAttachedEmitter(self, 'Pod06', self.Army, v)
        end

        SAirStagingPlatformUnit.OnStopBeingBuilt(self, builder, layer)
    end,
}

TypeClass = XSB5202
