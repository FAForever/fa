--****************************************************************************
--**
--**  File     :  /lua/defaultvizmarkers.lua
--**
--**  Summary  :  Visibility Markers
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local Entity = import('/lua/sim/Entity.lua').Entity

VizMarker = Class(Entity) {
    __init = function(self, spec)
        Entity.__init(self, spec)
        self.X = spec.X
        self.Z = spec.Z
        self.LifeTime = spec.LifeTime
        self.Radius = spec.Radius
        self.Army = spec.Army
        self.Omni = spec.Omni
        self.Radar = spec.Radar
        self.Vision = spec.Vision
        self.WaterVision = spec.WaterVision
    end,

    OnCreate = function(self)
        Entity.OnCreate(self)
        Warp(self, Vector(self.X, 0, self.Z))
        if self.Omni then
            self:InitIntel(self.Army, 'Omni', self.Radius)
            self:EnableIntel('Omni')
        end
        if self.Radar then
            self:InitIntel(self.Army, 'Radar', self.Radius)
            self:EnableIntel('Radar')
        end
        if self.Vision then
            self:InitIntel(self.Army, 'Vision', self.Radius)
            self:EnableIntel('Vision')
        end
        if self.WaterVision then
            self:InitIntel(self.Army, 'WaterVision', self.Radius)
            self:EnableIntel('WaterVision')
        end
        if self.LifeTime > 0 then
            self.LifeTimeThread = ForkThread(self.VisibleLifeTimeThread, self)
        end
    end,

    VisibleLifeTimeThread = function(self)
        WaitSeconds(self.LifeTime)
        self:Destroy()
    end,

    OnDestroy = function(self)
        Entity.OnDestroy(self)
        if self.LifeTimeThread then
            self.LifeTimeThread:Destroy()
        end
    end

}
