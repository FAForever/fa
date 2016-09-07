--****************************************************************************
--**
--**  File     :  /projectiles/ShieldCollider_script.lua
--**  Author(s):  Exotic_Retard, made for Equilibrium Balance Mod
--**
--**  Summary  : Companion projectile enabling air units to hit shields
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************


local GetRandomFloat = import('/lua/utilities.lua').GetRandomFloat
local Projectile = import('/lua/sim/projectile.lua').Projectile

ShieldCollider = Class(Projectile) {
    OnCreate = function(self)
        Projectile.OnCreate(self)

        self:SetVizToFocusPlayer('Never') --set to always to see a nice box
        self:SetVizToAllies('Never')
        self:SetVizToNeutrals('Never')
        self:SetStayUpright(false)
        self:SetCollision(true)
    end,
    
    --- Shields only detect projectiles, so we attach one to keep track of the unit.
    -- Invokes ShieldCallback when hitting a shield, and nothing else.
    Start = function(self, targEntity, targBone, ShieldCallback)
        self.callback = ShieldCallback
        self.PlaneBone = targBone
        self.Plane = targEntity
        self:StartFalling(targEntity, targBone)
    end,

    StartFalling = function(self, targetEntity, targetBone)
    
        local vx, vy, vz = self.Plane:GetVelocity()
        self:SetVelocity(10*vx, 10*vy, 10*vz) --for now we just follow the plane along, not attaching so it can rotate
        Warp(self, self.Plane:CalculateWorldPositionFromRelative({0, 0, 0}) , self.Plane:GetOrientation() )
    end,

    OnCollisionCheck = function(self, other)
        --we intercept this just incase the projectile collides with something it shouldn't
        WARN('shield collision projectile checking collision! fix me!')
        Projectile.OnCollisionCheck(self, other)
    end,
    
    OnDestroy = function(self)
    self:DetachAll('anchor') --if our projectile is getting destroyed we never want to have anything attached
        if self.Trash then
            self.Trash:Destroy()
        end
    end,
    
    --- Destroy the sinking unit when it hits the ground.
    OnImpact = function(self, targetType, targetEntity)
        if targetType == 'Terrain' then
            --all this absurdity is just because we have our plane attached to our projectile
            if self.AlreadyHit and not self.AlreadyHitGround  and not EntityCategoryContains( categories.EXPERIMENTAL, self.Plane ) then
                --here it should be noted that bone 0 IS NOT what the ground checks for, so if you have a projectile at that bone
                --and the units centre is below it, then its below the ground and that can cause it to hit water instead.
                --all this is just to prevent that, because falling planes are stupid.
                self.AlreadyHitGround = true
                
                local pos = self:GetPosition()
                local groundlevel = GetTerrainHeight(pos[1], pos[3]) + 0.25 --move a little up so it doesnt sink through the ground
                pos[2] = groundlevel
                self:SetPosition(pos, true)
                self.Plane:SetPosition(pos, true) --make sure the plane is above ground if its not
                self:SetVelocity(0,0,0) --the plane is attached to our projectile, so no funny business, just stick it onto the land layer
                
                self.Plane:OnImpact('Terrain') --tell the plane we hit land, as soon as possible
            end
            
            if not self.LifeTime then
                    self.LifeTime = self:ForkThread(self.LifeTimeThread)
            end
            --incase our bone 0 is in a retarded location, in which case the unit wont collide with ground, sometimes
        end
        if targetType == 'Water' then
            self:DetachAll('anchor')
            self:Destroy()
        end
        if targetType == 'Shield' then --callback in here for the crash damage code to catch
        
            if not self.AlreadyHit and not EntityCategoryContains( categories.EXPERIMENTAL, self.Plane ) then
            
                if not EntityCategoryContains( categories.EXPERIMENTAL, self.Plane ) then
                    Warp(self, self.Plane:GetPosition(self.PlaneBone) , self.Plane:GetOrientation() ) --warp to the BONE not the unit location
                    self.Plane:AttachBoneTo(self.PlaneBone, self, 'anchor') --we attach our bone at the very last moment when we need it
                    --by the way, if you try to deattach the plane, it has retarded game code that makes it continue falling in its original direction
                    self:ShieldBounce()
                end
                self.AlreadyHit = true -- we dont want it to hit the shield 500 times, (also it gets stuck there if you try that so yeah)
                ForkThread(self.callback)
            end
        end
    end,
    
    ShieldBounce = function(self)
        --lets do some maths that will make the units bounce off shields.
        
        local planebp = self.Plane:GetBlueprint()
        local volume = planebp.SizeX*planebp.SizeY*planebp.SizeZ --we will use this to *guess* how much force to apply
        
        local spin = math.min (4/volume, 2) -- less for larger planes; also 2 is a nice number
        self:SetLocalAngularVelocity(spin,spin,spin)
        --ideally i would just set this to whatever the plane had but i dont know how.
        
        local vx, vy, vz = self.Plane:GetVelocity() --speed of our projectile, or rather our plane
        local wx, wy, wz = self.ShieldCollVector[1], self.ShieldCollVector[2], self.ShieldCollVector[3] --get values from table
        --self.ShieldCollVector is passed to us from our shield, telling us the direction of the surface
        --convert our speed values from units per tick to units per second (or whatevever else why theyre 10 times smaller)
        vx = 10*vx 
        vy = 10*vy
        vz = 10*vz
        
        local Speed = math.sqrt(vx*vx + vy*vy + vz*vz) --the length of our vector
        local ShieldMag = math.sqrt(wx*wx + wy*vy + wz*wz) --the length of our other vector
        
        
        local KE = 0.5*volume*Speed*Speed*1 --our kinetic energy, used to scale the stoppingpower
        local StoppingPower = math.min(((80/KE)) ,2) --2 is a perfect bounce, anything less is the shield starting to give, 0 is unaffected velocity.
        --WARN('kinetic energy: ' .. KE .. ' stopping power: ' .. StoppingPower) --for tuning constants
        local ForceScalar = 0.5 -- 0.5 is our bounciness coefficient. i set it to my taste; 1.0 is a 'perfect' bounce
        --TODO: make this coefficient dependent on angle - 1.0 or more for glancing hits and 0.2 or sth for direct hits
        --TODO: make KE affect the vector properly, so more means less affected speed. you know - physics.
        --normalizing all our shield vector, so we dont need to deal with scalar nonsense
        wx = wx/ShieldMag
        wy = wy/ShieldMag
        wz = wz/ShieldMag
        
        -- get our dot products going
        local DotProduct = vx*wx + vy*wy + vz*wz
        
        --applying our bounce velocity
        vx = -StoppingPower*wx*DotProduct + vx 
        vy = -StoppingPower*wy*DotProduct + vy
        vz = -StoppingPower*wz*DotProduct + vz
        
        --so sometimes absurd values pop up, probably due to rounding errors or something, so we prevent huge speeds here
        vx = math.min(7,vx)
        vy = math.min(4,vy) -- less for y so we dont get planes flying into space
        vz = math.min(7,vz)
        self:SetVelocity(ForceScalar*vx, ForceScalar*vy, ForceScalar*vz)
    end,
    
    LifeTimeThread = function(self)
        --because setting lifetime doesnt actually kill our projectile, only add it to trash (or something), this makes sure its gone
        WaitSeconds(1)
        WARN('wait time elapsed; force killing companion projectile')
        self:Destroy()
    end,
    
}
TypeClass = ShieldCollider
