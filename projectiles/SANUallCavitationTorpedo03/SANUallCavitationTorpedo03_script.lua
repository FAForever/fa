--******************************************************************************************************
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
--******************************************************************************************************

local SUallCavitationTorpedo = import('/lua/seraphimprojectiles.lua').SUallCavitationTorpedo
local SUallCavitationTorpedoOnCreate = SUallCavitationTorpedo.OnCreate
local SUallCavitationTorpedoOnEnterWater = SUallCavitationTorpedo.OnEnterWater

local EffectTemplate = import("/lua/effecttemplates.lua")

--- Uall Cavitation Torpedo Projectile script, XSB2109
---@class SANUallCavitationTorpedo01 : SUallCavitationTorpedo
SANUallCavitationTorpedo03 = ClassProjectile(SUallCavitationTorpedo) {

    FxEnterWater = EffectTemplate.WaterSplash01,

        ---@param self SANHeavyCavitationTorpedo02
    ---@param inWater boolean
    OnCreate = function(self, inWater)
        SUallCavitationTorpedoOnCreate(self, inWater)

        -- let gravity take over
        self:TrackTarget(false)
    end,

    ---@param self SANHeavyCavitationTorpedo02
    OnEnterWater = function(self)
        SUallCavitationTorpedoOnEnterWater(self)

        -- take over from gravity
        self:TrackTarget(true)
    end,

}
TypeClass = SANUallCavitationTorpedo03