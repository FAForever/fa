local MobileUnit = import('/lua/sim/units/MobileUnit.lua').MobileUnit

AirUnit = Class(MobileUnit) {
    -- Contrails
    ContrailEffects = {'/effects/emitters/contrail_polytrail_01_emit.bp',},
    BeamExhaustCruise = '/effects/emitters/air_move_trail_beam_03_emit.bp',
    BeamExhaustIdle = '/effects/emitters/air_idle_trail_beam_01_emit.bp',

    -- DESTRUCTION PARAMS
    ShowUnitDestructionDebris = false,
    DestructionExplosionWaitDelayMax = 0,
    DestroyNoFallRandomChance = 0.5,

    OnCreate = function(self)
        MobileUnit.OnCreate(self)
        self.HasFuel = true
        self:AddPingPong()
    end,

    OnStopBeingBuilt = function(self,builder,layer)
        MobileUnit.OnStopBeingBuilt(self,builder,layer)
        local bp = self:GetBlueprint()
        if bp.SizeSphere then
            self:SetCollisionShape(
                'Sphere',
                bp.CollisionSphereOffsetX or 0,
                bp.CollisionSphereOffsetY or 0,
                bp.CollisionSphereOffsetZ or 0,
                bp.SizeSphere
            )
        end
    end,

    AddPingPong = function(self)
        local bp = self:GetBlueprint()
        if bp.Display.PingPongScroller then
            bp = bp.Display.PingPongScroller
            if bp.Ping1 and bp.Ping1Speed and bp.Pong1 and bp.Pong1Speed and bp.Ping2 and bp.Ping2Speed
                    and bp.Pong2 and bp.Pong2Speed then
                self:AddPingPongScroller(bp.Ping1, bp.Ping1Speed, bp.Pong1, bp.Pong1Speed,
                    bp.Ping2, bp.Ping2Speed, bp.Pong2, bp.Pong2Speed)
            end
        end
    end,

    OnMotionVertEventChange = function( self, new, old )
        MobileUnit.OnMotionVertEventChange( self, new, old )
        --LOG( 'OnMotionVertEventChange, new = ', new, ', old = ', old )
        local army = self:GetArmy()
        if (new == 'Down') then
            -- Turn off the ambient hover sound
            self:StopUnitAmbientSound( 'ActiveLoop' )
        elseif (new == 'Bottom') then
            -- While landed, planes can only see half as far
            local vis = self:GetBlueprint().Intel.VisionRadius / 2
            self:SetIntelRadius('Vision', vis)

            -- Turn off the ambient hover sound
            -- It will probably already be off, but there are some odd cases that
            -- make this a good idea to include here as well.
            self:StopUnitAmbientSound( 'ActiveLoop' )
        elseif (new == 'Up' or ( new == 'Top' and ( old == 'Down' or old == 'Bottom' ))) then
            -- Set the vision radius back to default
            local bpVision = self:GetBlueprint().Intel.VisionRadius
            if bpVision then
                self:SetIntelRadius('Vision', bpVision)
            else
                self:SetIntelRadius('Vision', 0)
            end
        end
    end,

    OnStartRefueling = function(self)
        self:PlayUnitSound('Refueling')
    end,

    OnRunOutOfFuel = function(self)
        self.HasFuel = false
        self:DestroyTopSpeedEffects()

        -- penalize movement for running out of fuel
        self:SetSpeedMult(0.35)     -- change the speed of the unit by this mult
        self:SetAccMult(0.25)       -- change the acceleration of the unit by this mult
        self:SetTurnMult(0.25)      -- change the turn ability of the unit by this mult
    end,

    OnGotFuel = function(self)
        self.HasFuel = true
        -- revert these values to the blueprint values
        self:SetSpeedMult(1)
        self:SetAccMult(1)
        self:SetTurnMult(1)
    end,

    OnImpact = function(self, with, other)
        if self.DeathBounce then
            return
        end
        self.DeathBounce = true

        -- Damage the area we have impacted with.
        local bp = self:GetBlueprint()
        local i = 1
        local numWeapons = table.getn(bp.Weapon)

        for i, numWeapons in bp.Weapon do
            if(bp.Weapon[i].Label == 'DeathImpact') then
                DamageArea(self, self:GetPosition(), bp.Weapon[i].DamageRadius, bp.Weapon[i].Damage, bp.Weapon[i].DamageType, bp.Weapon[i].DamageFriendly)
                break
            end
        end

        if(with == 'Water') then
            self:PlayUnitSound('AirUnitWaterImpact')
            EffectUtil.CreateEffects( self, self:GetArmy(), EffectTemplate.DefaultProjectileWaterImpact )
        end
        self:ForkThread(self.DeathThread, self.OverKillRatio )
    end,

    CreateUnitAirDestructionEffects = function( self, scale )
        local army = self:GetArmy()
        local scale = explosion.GetAverageBoundingXZRadius(self)
        explosion.CreateDefaultHitExplosion( self, scale)
        if(self.ShowUnitDestructionDebris) then
            explosion.CreateDebrisProjectiles(self, scale, {self:GetUnitSizes()})
        end
    end,

    -- ON KILLED: THIS FUNCTION PLAYS WHEN THE UNIT TAKES A MORTAL HIT.  IT PLAYS ALL THE DEFAULT DEATH EFFECT
    -- IT ALSO SPAWNS THE WRECKAGE BASED UPON HOW MUCH IT WAS OVERKILLED. UNIT WILL SPIN OUT OF CONTROL TOWARDS
    -- GROUND AND WHEN IT IMPACTS IT WILL DESTROY ITSELF
    OnKilled = function(self, instigator, type, overkillRatio)
        local bp = self:GetBlueprint()
        if self:GetCurrentLayer() == 'Air' then
            self.CreateUnitAirDestructionEffects( self, 1.0 )
            self:DestroyTopSpeedEffects()
            self:DestroyBeamExhaust()
            self.OverKillRatio = overkillRatio
            self:PlayUnitSound('Killed')
            self:DoUnitCallbacks('OnKilled')
            if instigator and IsUnit(instigator) then
                instigator:OnKilledUnit(self)
            end
        else
            self.DeathBounce = 1
            MobileUnit.OnKilled(self, instigator, type, overkillRatio)
        end
    end
}
