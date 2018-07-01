--****************************************************************************
--**
--**  File     :  /units/ZXB0307/ZXB0307_script.lua
--**  Author(s):  [e]Exotic_Retard
--**
--**  Summary  :  Dummy unit for allowing players to cancel teleportation by killing it.
--**
--**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local MobileUnit = import('/lua/defaultunits.lua').MobileUnit

ZXB0307 = Class(MobileUnit) {

    OnCreate = function(self)
        MobileUnit.OnCreate(self)
        --make our box invisible
        self:HideBone(0, true)
        --make projectile impacts on it look less square
        self:SetCollisionShape('Sphere', 0, 0.7, 0, 0.6)
        --if its spawned on its own for some reason it should go away after a while
        if not self.LifeTimeThread then
            self.LifeTimeThread = self:ForkThread(self.ManageLifeTime)
        end
        
        --remove destruction effects on death since they dont fit in
        self.PlayDestructionEffects = false
        self.PlayEndAnimDestructionEffects = false
        self.ShowUnitDestructionDebris = false
    end,

    --if we are all alone then we should disappear after a while.
    ManageLifeTime = function(self)
        WaitSeconds(60) --definitely longer than teleportation charge time
        self:Destroy()
    end,
    
    OnKilled = function(self, instigator, type, overkillRatio)
        --insert some custom destruction effects
        local army = self:GetArmy()
        CreateLightParticle(self, -1, army, 7, 12, 'glow_03', 'ramp_flare_02')
        
        --cancel teleportation if we are killed
        if self.Parent and not self.Parent.Dead then
            self.Parent:OnFailedTeleport() --cancel the teleportation
        end
        MobileUnit.OnKilled(self, instigator, type, overkillRatio)
    end,
}

TypeClass = ZXB0307
