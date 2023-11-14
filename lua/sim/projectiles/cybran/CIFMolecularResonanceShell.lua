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

local SinglePolyTrailProjectile = import("/lua/sim/defaultprojectiles.lua").SinglePolyTrailProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")

---  CYBRAN MOLECULAR RESONANCE SHELL PROJECTILE
---@class CIFMolecularResonanceShell : SinglePolyTrailProjectile
CIFMolecularResonanceShell = ClassProjectile(SinglePolyTrailProjectile) {
    PolyTrail = '/effects/emitters/default_polytrail_01_emit.bp',
    FxImpactUnit = EffectTemplate.CMolecularResonanceHitUnit01,
    FxImpactProp = EffectTemplate.CMolecularResonanceHitUnit01,
    FxImpactLand = EffectTemplate.CMolecularResonanceHitUnit01,
    DestroyOnImpact = false,

    ---@param self CIFMolecularResonanceShell
    OnCreate = function(self)
        SinglePolyTrailProjectile.OnCreate(self)
        self.Impacted = false
    end,

    ---@param self CIFMolecularResonanceShell
    DelayedDestroyThread = function(self)
        WaitTicks(4)
        self:CreateImpactEffects(self.Army, self.FxImpactUnit, self.FxUnitHitScale)
        self:Destroy()
    end,

    ---@param self CIFMolecularResonanceShell
    ---@param TargetType string
    ---@param TargetEntity Unit
    OnImpact = function(self, TargetType, TargetEntity)
        if self.Impacted == false then
            self.Impacted = true
            if TargetType == 'Terrain' then
                SinglePolyTrailProjectile.OnImpact(self, TargetType, TargetEntity)
                self.Trash:Add(ForkThread(self.DelayedDestroyThread,self))
            else
                SinglePolyTrailProjectile.OnImpact(self, TargetType, TargetEntity)
                self:Destroy()
            end
        end
    end,
}