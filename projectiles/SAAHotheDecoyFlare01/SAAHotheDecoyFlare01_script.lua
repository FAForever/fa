-- File     :  /lua/SAAHotheDecoyFlare01/SAAHotheDecoyFlare01_script.lua
-- Author(s):  Gordon Duclos
-- Summary  : Seraphim Hothe Decoy Flare
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------
local Flare = import("/lua/defaultantiprojectile.lua").Flare
local SAAHotheFlareProjectile = import("/lua/seraphimprojectiles.lua").SAAHotheFlareProjectile

SAAHotheDecoyFlare01 = ClassProjectile(SAAHotheFlareProjectile) {
    OnCreate = function(self)
        SAAHotheFlareProjectile.OnCreate(self)
        self.MyShield = Flare {
            Owner = self,
            Radius = self.Blueprint.Physics.FlareRadius,
        }
        self.Trash:Add(self.MyShield)
        self:TrackTarget(false)
        self:SetVelocity(0, -1, 0)
    end,
}
TypeClass = SAAHotheDecoyFlare01

