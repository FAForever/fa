-- File     :  /data/projectiles/SANUallCavitationTorpedo03/SANUallCavitationTorpedo03_script.lua
-- Author(s):  Gordon Duclos, Aaron Lundquist
-- Summary  :  Uall Cavitation Torpedo Projectile script, XSB2109
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------------------------------------

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