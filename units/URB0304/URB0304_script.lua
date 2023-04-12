-- File     :  /cdimage/units/URB0304/URB0304_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  Cybran Quantum Gate
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------
local CQuantumGateUnit = import("/lua/cybranunits.lua").CQuantumGateUnit
local EffectUtil = import("/lua/effectutilities.lua")

---@class URB0304 : CQuantumGateUnit
URB0304 = ClassUnit(CQuantumGateUnit) {
    GateBones = {
        {
            'Gate01_Left_FX',
            'Gate01_Right_FX',
        },
        {
            'Gate02_Left_FX',
            'Gate02_Right_FX',
        },
        {
            'Gate03_Left_FX',
            'Gate03_Right_FX',
        },
    },

    GateEffects = {
        '/effects/emitters/cybran_gate_01_emit.bp',
        '/effects/emitters/cybran_gate_02_emit.bp',
    },

    OnStopBeingBuilt = function(self, builder, layer)
        CQuantumGateUnit.OnStopBeingBuilt(self, builder, layer)
        local trash = self.Trash
        local gateBones = self.GateBones
        trash:Add(ForkThread(EffectUtil.CreateCybranQuantumGateEffect, self, gateBones[1][1], gateBones[1][2],
            trash, 0.1))
        trash:Add(ForkThread(EffectUtil.CreateCybranQuantumGateEffect, self, gateBones[2][1], gateBones[2][2],
            trash, 0.5))
        trash:Add(ForkThread(EffectUtil.CreateCybranQuantumGateEffect, self, gateBones[3][1], gateBones[3][2],
            trash, 1.1))
        trash:Add(ForkThread(EffectUtil.CreateCybranQuantumGateEffect, self, gateBones[1][1], gateBones[1][2],
            trash, 0.6))
        trash:Add(ForkThread(EffectUtil.CreateCybranQuantumGateEffect, self, gateBones[2][1], gateBones[2][2],
            trash, 1.2))
        trash:Add(ForkThread(EffectUtil.CreateCybranQuantumGateEffect, self, gateBones[3][1], gateBones[3][2],
            trash, 1.8))
        trash:Add(ForkThread(EffectUtil.CreateCybranQuantumGateEffect, self, gateBones[1][1], gateBones[1][2],
            trash, 2.3))
        trash:Add(ForkThread(EffectUtil.CreateCybranQuantumGateEffect, self, gateBones[2][1], gateBones[2][2],
            trash, 2.7))
        trash:Add(ForkThread(EffectUtil.CreateCybranQuantumGateEffect, self, gateBones[3][1], gateBones[3][2],
            trash, 3.1))

        local army = self.Army
        local gateEffects = self.GateEffects
        for kBonesSet, vBoneSet in gateBones do
            for kBone, vBone in vBoneSet do
                for kEffect, vEffect in gateEffects do
                    self.Trash:Add(CreateAttachedEmitter(self, vBone, army, vEffect))
                end
            end
        end
    end,
}

TypeClass = URB0304
