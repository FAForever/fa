--****************************************************************************
--**
--**  File     :  /data/units/XAB3301/XAB3301_script.lua
--**  Author(s):  Jessica St. Croix, Ted Snook, Dru Staltman
--**
--**  Summary  :  Aeon Quantum Optics Facility Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local AStructureUnit = import("/lua/aeonunits.lua").AStructureUnit

local AQuantumGateAmbient = import("/lua/effecttemplates.lua").AQuantumGateAmbient

-- Setup as RemoteViewing child of AStructureUnit
local RemoteViewing = import("/lua/remoteviewing.lua").RemoteViewing
AStructureUnit = RemoteViewing( AStructureUnit )

XAB3301 = ClassUnit( AStructureUnit ) {

    OnStopBeingBuilt = function(self, builder, layer)
        AStructureUnit.OnStopBeingBuilt(self, builder, layer)

        self.Trash:Add(CreateRotator(self, 'spin02', 'x', nil, 0, 15, 60 + Random(0, 20)))
        self.Trash:Add(CreateRotator(self, 'spin02', 'y', nil, 0, 15, 60 + Random(0, 20)))
        self.Trash:Add(CreateRotator(self, 'spin02', 'z', nil, 0, 15, 60 + Random(0, 20)))

        self.Animator = CreateAnimator(self)
        self.Animator:PlayAnim("/units/xab3301/XAB3301_activate.sca")
        self.Animator:SetRate(0)
        self.Trash:Add(self.Animator)

        self.RotatorBot = CreateRotator(self, 'spin01', 'y', nil, 0, 3, 6)
        self.RotatorTop = CreateRotator(self, 'spin03', 'y', nil, 0, -2, -4)

        self.TrashAmbientEffects = TrashBag()
    end,

    CreateVisibleEntity = function(self)
        AStructureUnit.CreateVisibleEntity(self)

        if self.RemoteViewingData.VisibleLocation and self.RemoteViewingData.DisableCounter == 0 and self.RemoteViewingData.IntelButton then

            if self.ScryEnabled then 
                CreateLightParticle(self, "spin02", self.Army, 1, 20, 'glow_02', 'ramp_blue_16')
            else 
                CreateLightParticle(self, "spin02", self.Army, 10, 20, 'glow_02', 'ramp_blue_22')
            end

            if not self.ScryEnabled then
                self.ScryEnabled = true 
                
                self.Animator:SetRate(1)
                self.RotatorBot:SetTargetSpeed(12)
                self.RotatorTop:SetTargetSpeed(-8)

                for k, v in AQuantumGateAmbient do
                    self.TrashAmbientEffects:Add(CreateAttachedEmitter(self, 'spin02', self.Army, v):ScaleEmitter(0.6))
                end
            end
        end

    end,

    DisableVisibleEntity = function(self)
        AStructureUnit.DisableVisibleEntity(self)

        self.Animator:SetRate(-1)
        self.RotatorBot:SetTargetSpeed(6)
        self.RotatorTop:SetTargetSpeed(-4)

        self.TrashAmbientEffects:Destroy()
        self.ScryEnabled = false 
    end,
}

TypeClass = XAB3301