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

local CDFMissileRedirectWeapon01 = import("/lua/sim/weapons/cybran/CDFMissileRedirectWeapon01.lua").CDFMissileRedirectWeapon01
local CDFMissileRedirectWeapon01OnCreate = CDFMissileRedirectWeapon01.OnCreate
local CDFMissileRedirectWeapon01OnLostTarget = CDFMissileRedirectWeapon01.OnLostTarget

local CDFMissileRedirectWeapon01IdleState = CDFMissileRedirectWeapon01.IdleState
local CDFMissileRedirectWeapon01IdleStateOnGotTarget = CDFMissileRedirectWeapon01.IdleState.OnGotTarget

---@class CDFMissileRedirectWeapon02 : CDFMissileRedirectWeapon01
CDFMissileRedirectWeapon02 = ClassWeapon(CDFMissileRedirectWeapon01) {

    SphereEffectIdleMesh = '/effects/entities/cybranphalanxsphere01/cybranphalanxsphere03_mesh',
    SphereEffectActiveMesh = '/effects/entities/cybranphalanxsphere01/cybranphalanxsphere02_mesh',
    SphereEffectBp = '/effects/emitters/zapper_electricity_02_emit.bp',

    ---@param self CDFMissileRedirectWeapon02
    OnCreate = function(self)
        CDFMissileRedirectWeapon01OnCreate(self)

        local unit = self.unit
        local trash = self.Trash
        local bp = self.Blueprint
        local muzzle = bp.RackBones[1].MuzzleBones[1]

        local sphereEffectEntity = import("/lua/sim/entity.lua").Entity()
        self.SphereEffectEntity = trash:Add(sphereEffectEntity)

        sphereEffectEntity:AttachBoneTo(-1, unit, muzzle)
        sphereEffectEntity:SetMesh(self.SphereEffectIdleMesh)
        sphereEffectEntity:SetDrawScale(0.28)
        sphereEffectEntity:SetVizToAllies('Intel')
        sphereEffectEntity:SetVizToNeutrals('Intel')
        sphereEffectEntity:SetVizToEnemies('Intel')

        local emit = CreateAttachedEmitter(unit, muzzle, unit.Army, self.SphereEffectBp)
        trash:Add(emit)
    end,

    IdleState = State(CDFMissileRedirectWeapon01IdleState) {
        OnGotTarget = function(self)
            CDFMissileRedirectWeapon01IdleStateOnGotTarget(self)
            self.SphereEffectEntity:SetMesh(self.SphereEffectActiveMesh)
        end,
    },

    ---@param self CAMZapperWeapon03
    OnLostTarget = function(self)
        CDFMissileRedirectWeapon01OnLostTarget(self)
        self.SphereEffectEntity:SetMesh(self.SphereEffectIdleMesh)
    end,

}
