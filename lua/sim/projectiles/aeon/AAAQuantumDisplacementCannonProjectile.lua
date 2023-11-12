--**********************************************************************************
--** Copyright (c) 2023 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--**********************************************************************************

local EffectTemplate = import("/lua/effecttemplates.lua")
local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell
local NullShellOnCreate = NullShell.OnCreate

-- upvalue scope for performance
local ForkThread = ForkThread
local WaitTicks = WaitTicks
local CreateTrail = CreateTrail
local CreateEmitterAtEntity = CreateEmitterAtEntity
local CreateEmitterOnEntity = CreateEmitterOnEntity

--- AEON AA PROJECTILES
---@class AAAQuantumDisplacementCannonProjectile : NullShell
---@field TrailEmitters moho.IEffect[]
AAAQuantumDisplacementCannonProjectile = ClassProjectile(NullShell) {
    PolyTrail = '/effects/emitters/quantum_displacement_cannon_polytrail_01_emit.bp',
    FxImpactUnit = EffectTemplate.AQuantumDisplacementHit01,
    FxImpactProp = EffectTemplate.AQuantumDisplacementHit01,
    FxImpactAirUnit = EffectTemplate.AQuantumDisplacementHit01,
    FxImpactLand = EffectTemplate.AQuantumDisplacementHit01,
    FxImpactNone = EffectTemplate.AQuantumDisplacementHit01,
    FxTeleport = EffectTemplate.AQuantumDisplacementTeleport01,
    FxInvisible = '/effects/emitters/sparks_08_emit.bp',

    ---@param self AAAQuantumDisplacementCannonProjectile
    OnCreate = function(self)
        NullShellOnCreate(self)
        self.Trash:Add(ForkThread(self.UpdateThread, self))
    end,

    --- Create a warp-like effect
    ---@param self AAAQuantumDisplacementCannonProjectile
    UpdateThread = function(self)
        -- local scope for performance
        local army = self.Army
        local polyTrail = self.PolyTrail
        local fxTeleport = self.FxTeleport
        local fxInvisible = self.FxInvisible

        -- initial trail
        local trail = CreateTrail(self, -1, army, polyTrail)

        WaitTicks(1)
        if IsDestroyed(self) then
            return
        end

        -- start of warp
        trail:Destroy()

        for i in fxTeleport do
            CreateEmitterAtEntity(self, army, fxTeleport[i])
        end

        local emit = CreateEmitterOnEntity(self, army, fxInvisible)

        WaitTicks(2)
        if IsDestroyed(self) then
            return
        end

        -- end of warp
        emit:Destroy()

        for i in fxTeleport do
            CreateEmitterAtEntity(self, army, fxTeleport[i])
        end

        CreateTrail(self, -1, army, polyTrail)
    end,
}
