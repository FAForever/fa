-- Automatically upvalued moho functions for performance
local EntityMethods = _G.moho.entity_methods
local EntityMethodsAttachBoneTo = EntityMethods.AttachBoneTo
local EntityMethodsSetDrawScale = EntityMethods.SetDrawScale
local EntityMethodsSetMesh = EntityMethods.SetMesh
local EntityMethodsSetParentOffset = EntityMethods.SetParentOffset
local EntityMethodsSetVizToAllies = EntityMethods.SetVizToAllies
local EntityMethodsSetVizToEnemies = EntityMethods.SetVizToEnemies
local EntityMethodsSetVizToNeutrals = EntityMethods.SetVizToNeutrals

local GlobalMethods = _G
local GlobalMethodsCreateAttachedEmitter = GlobalMethods.CreateAttachedEmitter
-- End of automatically upvalued moho functions

--#****************************************************************************
--#**
--#**  File     :  /cdimage/units/UEB0304/UEB0304_script.lua
--#**  Author(s):  John Comes, David Tomandl, Gordon Duclos
--#**
--#**  Summary  :  UEF Quantum Gate Script
--#**
--#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--#****************************************************************************
local TQuantumGateUnit = import('/lua/terranunits.lua').TQuantumGateUnit

UEB0304 = Class(TQuantumGateUnit)({
    GateEffectVerticalOffset = 0.35,
    GateEffectScale = 0.42,

    OnStopBeingBuilt = function(self, builder, layer)
        self.GateEffectEntity = import('/lua/sim/Entity.lua').Entity()
        EntityMethodsAttachBoneTo(self.GateEffectEntity, -1, self, 'UEB0304')
        EntityMethodsSetMesh(self.GateEffectEntity, '/effects/entities/ForceField01/ForceField01_mesh')
        EntityMethodsSetDrawScale(self.GateEffectEntity, self.GateEffectScale)
        EntityMethodsSetParentOffset(self.GateEffectEntity, Vector(0, 0, self.GateEffectVerticalOffset))
        EntityMethodsSetVizToAllies(self.GateEffectEntity, 'Intel')
        EntityMethodsSetVizToNeutrals(self.GateEffectEntity, 'Intel')
        EntityMethodsSetVizToEnemies(self.GateEffectEntity, 'Intel')
        self.Trash:Add(self.GateEffectEntity)

        GlobalMethodsCreateAttachedEmitter(self, 'Left_Gate_FX', self.Army, '/effects/emitters/terran_gate_01_emit.bp')
        GlobalMethodsCreateAttachedEmitter(self, 'Right_Gate_FX', self.Army, '/effects/emitters/terran_gate_01_emit.bp')

        TQuantumGateUnit.OnStopBeingBuilt(self, builder, layer)
    end,
})

TypeClass = UEB0304
