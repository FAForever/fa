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

local SinglePolyTrailProjectile = import('/lua/sim/defaultprojectiles.lua').SinglePolyTrailProjectile

---@class CNeutronClusterBombProjectile : SinglePolyTrailProjectile
CNeutronClusterBombProjectile = ClassProjectile(SinglePolyTrailProjectile) {
    PolyTrail = '/effects/emitters/default_polytrail_03_emit.bp',
    ChildProjectile = '/projectiles/CIFNeutronClusterBomb02/CIFNeutronClusterBomb02_proj.bp',

    ---@param self CNeutronClusterBombProjectile
    OnCreate = function(self)
        SinglePolyTrailProjectile.OnCreate(self)
        self.Impacted = false
    end,

    --- Note: Damage is done once in AOE by main projectile. Secondary projectiles
    --- are just visual.
    ---@param self CNeutronClusterBombProjectile
    ---@param targetType string
    ---@param targetEntity Unit
    OnImpact = function(self, targetType, targetEntity)
        if self.Impacted == false and targetType ~= 'Air' then
            self.Impacted = true
            local Random = Random 
            self:CreateChildProjectile(self.ChildProjectile):SetVelocity(0,Random(1,3),Random(1.5,3))
            self:CreateChildProjectile(self.ChildProjectile):SetVelocity(Random(1,2),Random(1,3),Random(1,2))
            self:CreateChildProjectile(self.ChildProjectile):SetVelocity(0,Random(1,3),-Random(1.5,3))
            self:CreateChildProjectile(self.ChildProjectile):SetVelocity(Random(1.5,3),Random(1,3),0)
            self:CreateChildProjectile(self.ChildProjectile):SetVelocity(-Random(1,2),Random(1,3),-Random(1,2))
            self:CreateChildProjectile(self.ChildProjectile):SetVelocity(-Random(1.5,2.5),Random(1,3),0)
            self:CreateChildProjectile(self.ChildProjectile):SetVelocity(-Random(1,2),Random(1,3),Random(2,4))
            SinglePolyTrailProjectile.OnImpact(self, targetType, targetEntity)
        end
    end,

    --- Overiding Destruction
    ---@param self CNeutronClusterBombProjectile
    ---@param targetType string
    ---@param targetEntity Unit
    OnImpactDestroy = function(self, targetType, targetEntity)
        self.Trash:Add(ForkThread(self.DelayedDestroyThread, self))
    end,

    ---@param self CNeutronClusterBombProjectile
    DelayedDestroyThread = function(self)
        WaitTicks(6)
        self:Destroy()
    end,
}
