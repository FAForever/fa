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

local KamikazeWeapon = import('/lua/sim/defaultweapons.lua').KamikazeWeapon
local CMobileKamikazeBombExplosion = import('/lua/effecttemplates.lua').CMobileKamikazeBombExplosion

---@class CMobileKamikazeBombWeapon : KamikazeWeapon
---@field transportDrop boolean
CMobileKamikazeBombWeapon = ClassWeapon(KamikazeWeapon) {
    FxDeath = CMobileKamikazeBombExplosion,

    ---@param self CMobileKamikazeBombWeapon
    OnFire = function(self)
        local army = self.unit.Army

        for k, v in self.FxDeath do
            CreateEmitterAtBone(self.unit, -2, army, v)
        end

        if not self.unit.transportDrop then
            local pos = self.unit:GetPosition()
            local rotation = math.random(0, 6.28)

            DamageArea(self.unit, pos, 6, 1, 'Force', true)
            DamageArea(self.unit, pos, 6, 1, 'Force', true)

            CreateDecal(pos, rotation, 'scorch_010_albedo', '', 'Albedo', 11, 11, 250, 120, army)
        end

        KamikazeWeapon.OnFire(self)
    end,
}
