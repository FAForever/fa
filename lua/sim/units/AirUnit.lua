
local MobileUnit = import("/lua/sim/units/mobileunit.lua").MobileUnit

local explosion = import("/lua/defaultexplosions.lua")
local EffectUtil = import("/lua/effectutilities.lua")
local EffectTemplate = import("/lua/effecttemplates.lua")
local ScenarioFramework = import("/lua/scenarioframework.lua")

---@class AirUnit : MobileUnit
AirUnit = ClassUnit(MobileUnit) {
    -- Contrails
    ContrailEffects = {'/effects/emitters/contrail_polytrail_01_emit.bp', },
    BeamExhaustCruise = '/effects/emitters/air_move_trail_beam_03_emit.bp',
    BeamExhaustIdle = '/effects/emitters/air_idle_trail_beam_01_emit.bp',

    -- DESTRUCTION PARAMS
    ShowUnitDestructionDebris = false,
    DestructionExplosionWaitDelayMax = 0,
    DestroyNoFallRandomChance = 0.5,

    ---@param self AirUnit
    OnCreate = function(self)
        MobileUnit.OnCreate(self)
        self.HasFuel = true
        self:AddPingPong()
    end,

    ---@param self AirUnit
    AddPingPong = function(self)
        local bp = self.Blueprint
        if bp.Display.PingPongScroller then
            bp = bp.Display.PingPongScroller
            if bp.Ping1 and bp.Ping1Speed and bp.Pong1 and bp.Pong1Speed and bp.Ping2 and bp.Ping2Speed
                and bp.Pong2 and bp.Pong2Speed then
                self:AddPingPongScroller(bp.Ping1, bp.Ping1Speed, bp.Pong1, bp.Pong1Speed,
                                         bp.Ping2, bp.Ping2Speed, bp.Pong2, bp.Pong2Speed)
            end
        end
    end,

    ---@param self AirUnit
    ---@param new string
    ---@param old string
    OnMotionVertEventChange = function(self, new, old)
        MobileUnit.OnMotionVertEventChange(self, new, old)

        if new == 'Down' then
            -- Turn off the ambient hover sound
            self:StopUnitAmbientSound('ActiveLoop')
        elseif new == 'Bottom' then
            -- While landed, planes can only see half as far
            local vis = self.Blueprint.Intel.VisionRadius / 2
            self:SetIntelRadius('Vision', vis)
            self:SetIntelRadius('WaterVision', 4)

            -- Turn off the ambient hover sound
            -- It will probably already be off, but there are some odd cases that
            -- make this a good idea to include here as well.
            self:StopUnitAmbientSound('ActiveLoop')
        elseif new == 'Up' or (new == 'Top' and (old == 'Down' or old == 'Bottom')) then
            -- Set the vision radius back to default
            local bpVision = self.Blueprint.Intel.VisionRadius
            if bpVision then
                self:SetIntelRadius('Vision', bpVision)
                self:SetIntelRadius('WaterVision', 0)
            else
                self:SetIntelRadius('Vision', 0)
            end
        end
    end,

    ---@param self AirUnit
    OnStartRefueling = function(self)
        self:PlayUnitSound('Refueling')
    end,

    ---@param self AirUnit
    OnRunOutOfFuel = function(self)
        self.HasFuel = false
        self:DestroyTopSpeedEffects()

        -- Penalize movement for running out of fuel
        self:SetSpeedMult(0.35) -- Change the speed of the unit by this mult
        self:SetAccMult(0.25) -- Change the acceleration of the unit by this mult
        self:SetTurnMult(0.25) -- Change the turn ability of the unit by this mult
    end,

    ---@param self AirUnit
    OnGotFuel = function(self)
        self.HasFuel = true
        -- Revert these values to the blueprint values
        self:SetSpeedMult(1)
        self:SetAccMult(1)
        self:SetTurnMult(1)
    end,

    -- Planes need to crash. Called by engine or by ShieldCollider projectile on collision with ground or water
    ---@param self AirUnit
    ---@param with string
    OnImpact = function(self, with)
        if self.GroundImpacted then return end

        -- Immediately destroy units outside the map
        if not ScenarioFramework.IsUnitInPlayableArea(self) then
            self:Destroy()
        end

        -- Only call this code once
        self.GroundImpacted = true

        -- Damage the area we hit. For damage, use the value which may have been adjusted by a shield impact
        if not self.deathWep or not self.DeathCrashDamage then -- Bail if stuff is missing
            WARN('defaultunits.lua OnImpact: did not find a deathWep on the plane! Is the weapon defined in the blueprint? ' .. self.UnitId)
        elseif self.DeathCrashDamage > 0 then -- It was completely absorbed by a shield!
            local deathWep = self.deathWep -- Use a local copy for speed and easy reading
            DamageArea(self, self:GetPosition(), deathWep.DamageRadius, self.DeathCrashDamage, deathWep.DamageType, deathWep.DamageFriendly)
            DamageArea(self, self:GetPosition(), deathWep.DamageRadius, 1, 'TreeForce', false)
        end

        if with == 'Water' then
            self:PlayUnitSound('AirUnitWaterImpact')
            EffectUtil.CreateEffectsOpti(self, self.Army, EffectTemplate.DefaultProjectileWaterImpact)
            self.shallSink = true
            self.colliderProj:Destroy()
            self.colliderProj = nil
        end

        self:DisableUnitIntel('Killed')
        self:DisableIntel('Vision') -- Disable vision seperately, it's not handled in DisableUnitIntel
        self:ForkThread(self.DeathThread, self.OverKillRatio)
    end,

    -- ONLY works for Terrain, not Water
    ---@param self AirUnit
    ---@param bone Bone
    ---@param x number
    ---@param y number
    ---@param z number
    OnAnimTerrainCollision = function(self, bone, x, y, z)
        self:OnImpact('Terrain')
    end,

    ---@param self AirUnit
    ShallSink = function(self)
        local layer = self.Layer
        local shallSink = (
            self.shallSink or -- Only the case when a bounced plane hits water. Overrides the fact that the layer is 'Air'
            ((layer == 'Water' or layer == 'Sub') and  -- In a layer for which sinking is meaningful
            not EntityCategoryContains(categories.STRUCTURE, self))  -- Exclude structures
        )
        return shallSink
    end,

    ---@param self AirUnit
    ---@param scale number
    CreateUnitAirDestructionEffects = function(self, scale)
        local scale = explosion.GetAverageBoundingXZRadius(self)
        local blueprint = self.Blueprint
        explosion.CreateDefaultHitExplosion(self, scale)

        if self.ShowUnitDestructionDebris then
            explosion.CreateDebrisProjectiles(self, scale, {blueprint.SizeX, blueprint.SizeY, blueprint.SizeZ})
        end
    end,

    --- Called when the unit is killed, but before it falls out of the sky and blows up.
    ---@param self AirUnit
    ---@param instigator Unit
    ---@param type string
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        -- A completed, flying plane expects an OnImpact event due to air crash.
        -- An incomplete unit in the factory still reports as being in layer "Air", so needs this
        -- stupid check.

        -- Additional stupidity: An idle transport, bot loaded and unloaded, counts as 'Land' layer so it would die with the wreck hovering.
        -- It also wouldn't call this code, and hence the cargo destruction. Awful!
        if self:GetFractionComplete() == 1 and (self.Layer == 'Air' or EntityCategoryContains(categories.TRANSPORTATION, self)) then
            self:CreateUnitAirDestructionEffects(1.0)
            self:DestroyTopSpeedEffects()
            self:DestroyBeamExhaust()
            self.OverKillRatio = overkillRatio
            self:PlayUnitSound('Killed')
            self:DoUnitCallbacks('OnKilled')
            self:DisableShield()

            -- Store our death weapon's damage on the unit so it can be edited remotely by the shield bouncer projectile
            local bp = self.Blueprint
            local i = 1
            for i, numweapons in bp.Weapon do
                if bp.Weapon[i].Label == 'DeathImpact' then
                    self.deathWep = bp.Weapon[i]
                    break
                end
            end

            if not self.deathWep or self.deathWep == {} then
                WARN(string.format('(%s) has no death weapon or the death weapon has an incorrect label!', tostring(bp.BlueprintId)))
            else
                self.DeathCrashDamage = self.deathWep.Damage
            end

            -- Create a projectile we'll use to interact with Shields
            local proj = self:CreateProjectileAtBone('/projectiles/ShieldCollider/ShieldCollider_proj.bp', 0)
            self.colliderProj = proj
            proj:Start(self, 0)
            self.Trash:Add(proj)

            self:VeterancyDispersal()
        else
            MobileUnit.OnKilled(self, instigator, type, overkillRatio)
        end
    end,

    --- Called when a unit collides with a projectile to check if the collision is valid, allows
    -- ASF to be destroyed when they impact with strategic missiles
    ---@param self AirUnit # The unit we're checking the collision for
    ---@param other Projectile # other The projectile we're checking the collision with
    ---@param firingWeapon Weapon # The weapon that the projectile originates from
    ---@return boolean
    OnCollisionCheck = function(self, other, firingWeapon)
        if self.DisallowCollisions then
            return false
        end

        local selfBlueprintCategoriesHashed = self.Blueprint.CategoriesHash
        local otherBlueprintCategoriesHashed = other.Blueprint.CategoriesHash

        -- allow regular air units to be destroyed by the projectiles of SMDs and SMLs
        if otherBlueprintCategoriesHashed["KILLAIRONCOLLISION"] and (not selfBlueprintCategoriesHashed["EXPERIMENTAL"]) then
            self:Kill()
            return false
        end

        -- disallow ASF to intercept certain projectiles
        if otherBlueprintCategoriesHashed["IGNOREASFONCOLLISION"] and selfBlueprintCategoriesHashed["ASF"] then
            return false
        end

        return MobileUnit.OnCollisionCheck(self, other, firingWeapon)
    end,
}