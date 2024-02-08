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
local DefaultProjectileWeaponCreateProjectileAtMuzzle = DefaultProjectileWeapon.CreateProjectileAtMuzzle

---@class TIFCarpetBombWeapon : DefaultProjectileWeapon
TIFCarpetBombWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = { '/effects/emitters/antiair_muzzle_fire_02_emit.bp', },

    -- We adapt this function because it will call every time a projectile is created,
    -- so we can retarget the weapon to where we want the projectile to go instead
    -- of the unit AI targeting the weapon for us during that one projectile firing.
    --- This function creates the projectile, and happens when the unit is trying to fire
    --- Called from inside RackSalvoFiringState
    ---@param self TIFCarpetBombWeapon
    ---@param muzzle string
    ---@return Projectile
    CreateProjectileAtMuzzle = function(self, muzzle)
        local data = self.CurrentSalvoData
        if data then -- check if we fired once
            if data.target then
                -- last shot we calculated where to drop bombs to hit a certain target
                -- we don't want to keep updating this location, so remove the target.
                data.target = nil
            end
            self:SetTargetGround(data.targetPos)
        end
        return DefaultProjectileWeaponCreateProjectileAtMuzzle(self, muzzle)
    end,
}
