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

local DefaultProjectileWeapon = import('/lua/sim/defaultweapons.lua').DefaultProjectileWeapon

---@class TIFCarpetBombWeapon : DefaultProjectileWeapon
TIFCarpetBombWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/antiair_muzzle_fire_02_emit.bp',},

    --- This function creates the projectile, and happens when the unit is trying to fire
    --- Called from inside RackSalvoFiringState
    ---@param self TIFCarpetBombWeapon
    ---@param muzzle string
    ---@return Projectile
    CreateProjectileAtMuzzle = function(self, muzzle)
        -- Adapt this function to keep the correct target lock during carpet bombing
        local data = self.CurrentSalvoData
        if data and data.usestore then
            local pos = data.targetpos
            if pos then -- We are repeating, and have lost our original target
                self:SetTargetGround(pos)
            end
        end

        return DefaultProjectileWeapon.CreateProjectileAtMuzzle(self, muzzle)
    end,
}