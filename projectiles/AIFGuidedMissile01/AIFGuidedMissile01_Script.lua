-------------------------------------------------------------------------------------
-- File     :  /data/projectiles/AIFGuidedMissile01/AIFGuidedMissile01_script.lua
-- Author(s):  Matt Vainio, Gordon Duclos
-- Summary  :  Aeon Guided Missile, DAA0206
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------------
local AGuidedMissileProjectile = import("/lua/aeonprojectiles.lua").AGuidedMissileProjectile
local RandF = import("/lua/utilities.lua").GetRandomFloat
local EffectTemplate = import("/lua/effecttemplates.lua")

AIFGuidedMissile = ClassProjectile(AGuidedMissileProjectile) {
    OnCreate = function(self)
		AGuidedMissileProjectile.OnCreate(self)
        local launcher = self.Launcher
        if launcher and not launcher:IsDead() then
            launcher:ProjectileFired()
        end		
		self.Trash:Add(ForkThread( self.SplitThread,self ))
    end,

    SplitThread = function(self)
        ------Create/play the split effects.
		for k,v in EffectTemplate.AMercyGuidedMissileSplit do
            CreateEmitterOnEntity(self,self.Army,v)
        end
        WaitTicks(2)
        -- Create several other projectiles in a dispersal pattern
        local vx, vy, vz = self:GetVelocity()
        local velocity = 16		
        local numProjectiles = 8
        local angle = (2*math.pi) / numProjectiles
        local angleInitial = RandF( 0, angle )
        local ChildProjectileBP = '/projectiles/AIFGuidedMissile02/AIFGuidedMissile02_proj.bp'          
        local spreadMul = 0.4 -- Adjusts the width of the dispersal        
        local xVec = 0 
        local yVec = vy*0.8
        local zVec = 0
        
        -- Adjust damage by number of split projectiles
        self.DamageData.DamageAmount = self.DamageData.DamageAmount / numProjectiles

        -- Launch projectiles at semi-random angles away from split location
        for i = 0, (numProjectiles -1) do
            xVec = vx + math.sin(angleInitial + (i*angle) ) * spreadMul * RandF( 0.6, 1.3 )
            zVec = vz + math.cos(angleInitial + (i*angle) ) * spreadMul * RandF( 0.6, 1.3 )
            local proj = self:CreateChildProjectile(ChildProjectileBP)
            proj:SetVelocity( xVec, yVec, zVec )
            proj:SetVelocity( velocity * RandF( 0.8, 1.2 ) )
            proj.DamageData = self.DamageData
        end
        self:Destroy()
    end,
}
TypeClass = AIFGuidedMissile