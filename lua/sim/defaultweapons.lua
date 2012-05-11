do

local Game = import('/lua/game.lua')
local CalculateBallisticAcceleration = import('/lua/sim/CalcBallisticAcceleration.lua').CalculateBallisticAcceleration 


local CBFP_DefaultProjectileWeapon = DefaultProjectileWeapon
DefaultProjectileWeapon = Class(CBFP_DefaultProjectileWeapon) {		

    OnCreate = function(self)                                                  # [152]
        CBFP_DefaultProjectileWeapon.OnCreate( self)
        local bp = self:GetBlueprint()
        if bp.FixBombTrajectory then
            self.CBFP_CalcBallAcc = { Do = true, ProjectilesPerOnFire = (bp.ProjectilesPerOnFire or 1), }
        end
    end,

    CheckBallisticAcceleration = function(self, proj)                          # [152]
        if self.CBFP_CalcBallAcc and self.CBFP_CalcBallAcc.Do then
            local acc = CalculateBallisticAcceleration( self, proj, self.CBFP_CalcBallAcc.ProjectilesPerOnFire )
            proj:SetBallisticAcceleration( -acc) # change projectile trajectory so it hits the target, cure for engine bug
        end
    end,

    CreateProjectileAtMuzzle = function(self, muzzle)                          # [152]
        local proj = CBFP_DefaultProjectileWeapon.CreateProjectileAtMuzzle(self, muzzle)
        self:CheckBallisticAcceleration( proj)  # if weapon BP specifies fix bomb trajectory then that's what happens
        self:CheckCountedMissileLaunch()  # added by brute51 - provides a unit event function
        return proj
    end,

    CheckCountedMissileLaunch = function(self)
        # takes care of a unit event function added in CBFP v2. MOved it to here in v4, that way I can get rid of
        # a whole lot of other-mod-incompatible code
        local bp = self:GetBlueprint()
        if bp.CountedProjectile then
            if bp.NukeWeapon then
                self.unit:OnCountedMissileLaunch('nuke')
            else
                self.unit:OnCountedMissileLaunch('tactical')
            end
        end
    end,
}

local CBFP_DefaultBeamWeapon = DefaultBeamWeapon
DefaultBeamWeapon = Class(CBFP_DefaultBeamWeapon) {
    BeamLifetimeThread = function(self, beam, lifeTime) 
        WaitSeconds(lifeTime)
        WaitTicks(1) # added by brute51 fix for beam weapon DPS bug [101]
        self:PlayFxBeamEnd(beam) 
    end, 
}


end