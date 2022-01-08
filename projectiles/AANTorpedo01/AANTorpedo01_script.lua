--
-- Sub-Based Torpedo Script
--
local ATorpedoSubProjectile = import('/lua/aeonprojectiles.lua').ATorpedoSubProjectile
AANTorpedo01 = Class(ATorpedoSubProjectile) {

    --OnCreate = function(self)
    --    ATorpedoSubProjectile.OnCreate(self)
    --    self:ForkThread(self.DirChange)
    --end,
    --
    --DirChange = function(self)
    --    WaitSeconds(2)
    --    self:SetTurnRate(45)
    --end,

}

TypeClass = AANTorpedo01

