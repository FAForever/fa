#****************************************************************************
#**
#**  File     :  /lua/defaultvizmarkers.lua
#**
#**  Summary  :  Visibility Markers
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local ForkThread = ForkThread
local entity_methodsDestroy = moho.entity_methods.Destroy
local Vector = Vector
local Warp = Warp
local entity_methodsInitIntel = moho.entity_methods.InitIntel
local entity_methodsEnableIntel = moho.entity_methods.EnableIntel

local Entity = import('/lua/sim/Entity.lua').Entity

VizMarker = Class(Entity) {
    __init = function(self, spec)
        #LOG('__VizMarker')
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
        #LOG('VizMarker OnCreate')
        Warp(self, Vector(self.X, 0, self.Z))
        if self.Omni != false then
            entity_methodsInitIntel(self, self.Army, 'Omni', self.Radius)
            entity_methodsEnableIntel(self, 'Omni')
        end
        if self.Radar != false then
            entity_methodsInitIntel(self, self.Army, 'Radar', self.Radius)
            entity_methodsEnableIntel(self, 'Radar')
        end        
        if self.Vision != false then
            entity_methodsInitIntel(self, self.Army, 'Vision', self.Radius)
            entity_methodsEnableIntel(self, 'Vision')
        end
        if self.WaterVision != false then
            entity_methodsInitIntel(self, self.Army, 'WaterVision', self.Radius)
            entity_methodsEnableIntel(self, 'WaterVision')
        end
        if self.LifeTime > 0 then
            self.LifeTimeThread = ForkThread(self.VisibleLifeTimeThread, self)
        end
    end,

    VisibleLifeTimeThread = function(self)
        WaitSeconds(self.LifeTime)
        entity_methodsDestroy(self)
    end,

    OnDestroy = function(self)
        Entity.OnDestroy(self)
        if self.LifeTimeThread then
            self.LifeTimeThread:Destroy()
        end
    end

}
