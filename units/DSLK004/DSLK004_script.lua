--****************************************************************************
--**
--**  Author(s):  Mikko Tyster, Atte Hulkkonen
--**
--**  Summary  :  Seraphim T3 Mobile Lightning Anti-Air
--**
--**  Copyright © 2008 Blade Braver!
--****************************************************************************

-- Automatically upvalued moho functions for performance
local CollisionBeamEntityMethods = _G.moho.CollisionBeamEntity
local CollisionBeamEntityMethodsSetBeamFx = CollisionBeamEntityMethods.SetBeamFx

local GlobalMethods = _G
local GlobalMethodsAttachBeamToEntity = GlobalMethods.AttachBeamToEntity
local GlobalMethodsCreateAttachedEmitter = GlobalMethods.CreateAttachedEmitter
local GlobalMethodsCreateSplat = GlobalMethods.CreateSplat
local GlobalMethodsDamageArea = GlobalMethods.DamageArea
-- End of automatically upvalued moho functions

local SLandUnit = import('/lua/seraphimunits.lua').SLandUnit
--local CollisionBeamFile = import('/lua/kirvesbeams.lua')
local DefaultBeamWeapon = import('/lua/sim/DefaultWeapons.lua').DefaultBeamWeapon
--local Dummy = import('/lua/kirvesweapons.lua').Dummy
local EffectTemplate = import('/lua/EffectTemplates.lua')

local CollisionBeam = import('/lua/sim/CollisionBeam.lua').CollisionBeam
local SCCollisionBeam = import('/lua/defaultcollisionbeams.lua').SCCollisionBeam



local PhasonCollisionBeam = Class(SCCollisionBeam)({

    FxBeamStartPoint = {
        '/Effects/Emitters/seraphim_experimental_phasonproj_muzzle_flash_01_emit.bp',
        '/Effects/Emitters/seraphim_experimental_phasonproj_muzzle_flash_02_emit.bp',
        '/Effects/Emitters/seraphim_experimental_phasonproj_muzzle_flash_03_emit.bp',
        '/Effects/Emitters/seraphim_experimental_phasonproj_muzzle_flash_04_emit.bp',
        '/Effects/Emitters/seraphim_experimental_phasonproj_muzzle_flash_05_emit.bp',
        '/Effects/Emitters/seraphim_experimental_phasonproj_muzzle_flash_06_emit.bp',
        '/units/DSLK004/effects/seraphim_electricity_emit.bp',
    },
    FxBeam = {
        '/units/DSLK004/effects/seraphim_lightning_beam_01_emit.bp',
    },
    FxBeamEndPoint = {
        '/units/DSLK004/effects/seraphim_lightning_hit_01_emit.bp',
        '/units/DSLK004/effects/seraphim_lightning_hit_02_emit.bp',
        '/units/DSLK004/effects/seraphim_lightning_hit_03_emit.bp',
        '/units/DSLK004/effects/seraphim_lightning_hit_04_emit.bp',
    },


    TerrainImpactType = 'LargeBeam01',
    TerrainImpactScale = 0.2,
    SplatTexture = 'czar_mark01_albedo',
    ScorchSplatDropTime = 0.25,

    OnImpact = function(self, impactType, targetEntity)
        CollisionBeam.OnImpact(self, impactType, targetEntity)
    end,

    OnDisable = function(self)
        CollisionBeam.OnDisable(self)
        KillThread(self.Scorching)
        self.Scorching = nil
    end,

    PassTarget = function(self, entity, position)
        self.TargetEntity = entity
        self.TargetPosition = position
    end,

    PassOrigin = function(self, originUnit, originBone)
        self.OriginUnit = originUnit
        self.OriginBone = originBone
    end,

    DoDamage = function(self, instigator, damageData, targetEntity)

        if self.TargetEntity then
            targetEntity = self.TargetEntity
        end

        local damage = damageData.DamageAmount or 0

        if self.Weapon.DamageModifiers then
            local dmgmod = 1
            for k, v in self.Weapon.DamageModifiers do
                dmgmod = v * dmgmod
            end
            damage = damage * dmgmod
        end

        if damage <= 0 then
            return
        end

        if instigator then
            local radius = damageData.DamageRadius
            local BeamEndPos = self:GetPosition(1)
            if targetEntity and targetEntity.GetPosition then
                BeamEndPos = targetEntity:GetPosition()
            end


            if radius and radius > 0 then
                if not damageData.DoTTime or damageData.DoTTime <= 0 then
                    GlobalMethodsDamageArea(instigator, BeamEndPos, radius, damage, damageData.DamageType or 'Normal', damageData.DamageFriendly or false)
                else
                    ForkThread(DefaultDamage.AreaDoTThread, instigator, BeamEndPos, damageData.DoTPulses or 1, (damageData.DoTTime / (damageData.DoTPulses or 1)), radius, damage, damageData.DamageType, damageData.DamageFriendly)
                end
            elseif targetEntity then
                if not damageData.DoTTime or damageData.DoTTime <= 0 then
                    Damage(instigator, self:GetPosition(), targetEntity, damage, damageData.DamageType)
                else
                    ForkThread(DefaultDamage.UnitDoTThread, instigator, targetEntity, damageData.DoTPulses or 1, (damageData.DoTTime / (damageData.DoTPulses or 1)), damage, damageData.DamageType, damageData.DamageFriendly)
                end
            else
                GlobalMethodsDamageArea(instigator, BeamEndPos, 0.25, damage, damageData.DamageType, damageData.DamageFriendly)
            end
        else
            LOG('*ERROR: THERE IS NO INSTIGATOR FOR DAMAGE ON THIS COLLISIONBEAM = ', repr(damageData))
        end
    end,

    CreateBeamEffects = function(self)
        -- Destructively overwriting this function to make it use AttachBeamEntityToEntity()
        for k, y in self.FxBeamStartPoint do
            local fx = CreateAttachedEmitter(self, 0, self.Army, y):ScaleEmitter(self.FxBeamStartPointScale)
            table.insert(self.BeamEffectsBag, fx)
            self.Trash:Add(fx)
        end
        for k, y in self.FxBeamEndPoint do
            local fx = CreateAttachedEmitter(self, 1, self.Army, y):ScaleEmitter(self.FxBeamEndPointScale)
            table.insert(self.BeamEffectsBag, fx)
            self.Trash:Add(fx)
        end
        if not table.empty(self.FxBeam) then

            local fxBeam
            local bp = self.FxBeam[Random(1, table.getn(self.FxBeam))]
            if self.TargetEntity then
                fxBeam = AttachBeamEntityToEntity(self.OriginUnit, self.OriginBone, self.TargetEntity, 0, self.Army, bp)
            else
                fxBeam = CreateBeamEmitter(bp, self.Army)
                GlobalMethodsAttachBeamToEntity(fxBeam, self, 0, self.Army)
            end

            -- collide on start if it's a continuous beam
            local weaponBlueprint = self.Weapon:GetBlueprint()
            local bCollideOnStart = weaponBlueprint.BeamLifetime <= 0
            CollisionBeamEntityMethodsSetBeamFx(self, fxBeam, bCollideOnStart)

            table.insert(self.BeamEffectsBag, fxBeam)
            self.Trash:Add(fxBeam)
        else
            LOG('*ERROR: THERE IS NO BEAM EMITTER DEFINED FOR THIS COLLISION BEAM ', repr(self.FxBeam))
        end
    end,
})

local PhasonCollisionBeam2 = Class(PhasonCollisionBeam)({

    FxBeam = {
        '/units/DSLK004/effects/seraphim_lightning_beam_02_emit.bp',
    },
    TerrainImpactScale = 0.1,

    OnImpact = function(self, impactType, targetEntity)
        if impactType == 'Terrain' then
            if self.Scorching == nil then
                self.Scorching = self:ForkThread(self.ScorchThread)
            end
        elseif not impactType == 'Unit' then
            KillThread(self.Scorching)
            self.Scorching = nil
        end
        PhasonCollisionBeam.OnImpact(self, impactType, targetEntity)
    end,

    OnDisable = function(self)
        PhasonCollisionBeam.OnDisable(self)
        KillThread(self.Scorching)
        self.Scorching = nil
    end,

    ScorchThread = function(self)
        local size = 1 + (Random() * 1.1)
        local CurrentPosition = self:GetPosition(1)
        local LastPosition = Vector(0, 0, 0)
        local skipCount = 1
        local Util = import('/lua/utilities.lua')

        while true do
            if Util.GetDistanceBetweenTwoVectors(CurrentPosition, LastPosition) > 0.25 or skipCount > 100 then
                GlobalMethodsCreateSplat(CurrentPosition, Util.GetRandomFloat(0, 2 * math.pi), self.SplatTexture, size, size, 100, 100, self.Army)
                LastPosition = CurrentPosition
                skipCount = 1
            else
                skipCount = skipCount + self.ScorchSplatDropTime
            end

            WaitSeconds(self.ScorchSplatDropTime)
            size = 1 + (Random() * 1.1)
            CurrentPosition = self:GetPosition(1)
        end
    end,
})

local PhasonBeam = Class(DefaultBeamWeapon)({
    BeamType = PhasonCollisionBeam,
    FxMuzzleFlash = {},
    FxChargeMuzzleFlash = {},
    FxUpackingChargeEffects = EffectTemplate.CMicrowaveLaserCharge01,
    FxUpackingChargeEffectScale = 0.2,

    PlayFxBeamStart = function(self, muzzle)
        local beam
        for k, v in self.Beams do
            if v.Muzzle == muzzle then
                beam = v.Beam
                break
            end
        end
        if beam and not beam:IsEnabled() then
            beam:PassOrigin(self.unit, muzzle)
            beam:PassTarget(self:GetCurrentTarget(), self:GetCurrentTargetPos())
        end
        return DefaultBeamWeapon.PlayFxBeamStart(self, muzzle)
    end,
})

DSLK004 = Class(SLandUnit)({
    Weapons = {
        PhasonBeamAir = Class(PhasonBeam)({}),
        PhasonBeamGround = Class(PhasonBeam)({
            BeamType = PhasonCollisionBeam2,
            FxBeamEndPointScale = 0.01,
        }),
    },

    OnStopBeingBuilt = function(self, builder, layer)
        SLandUnit.OnStopBeingBuilt(self, builder, layer)

        local EfctTempl = {
            '/units/DSLK004/effects/orbeffect_01.bp',
            '/units/DSLK004/effects/orbeffect_02.bp',


        }
        for k, v in EfctTempl do
            GlobalMethodsCreateAttachedEmitter(self, 'Orb', self.Army, v)
        end
    end,
})
TypeClass = DSLK004
