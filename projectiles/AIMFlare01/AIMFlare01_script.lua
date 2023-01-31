------------------------------------------------------------------------
--  File     :  /lua/AIMFlare01/AIMFlare01_script.lua
--  Author(s):  John Comes
--  Summary  : Aeon Flare
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------
local Flare = import("/lua/defaultantiprojectile.lua").Flare
local AIMFlareProjectile = import("/lua/aeonprojectiles.lua").AIMFlareProjectile

AIMFlare01 = ClassProjectile(AIMFlareProjectile) {
    OnCreate = function(self)
        AIMFlareProjectile.OnCreate(self)
        self.MyShield = Flare {
            Owner = self,
            Radius = self.Blueprint.Physics.FlareRadius,
        }
        self.Trash:Add(self.MyShield)
        self:TrackTarget(false)
        self:SetVelocity(0, -1, 0)
    end,
    -- We only destroy when we hit the ground/water.
    OnImpact = function(self,type,other)
        if type == 'Terrain' or type == 'Water' then
            AIMFlareProjectile.OnImpact(self,type,other)
        end
    end,
}
TypeClass = AIMFlare01