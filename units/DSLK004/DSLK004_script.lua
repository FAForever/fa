------------------------------------------------------------------------------
-- Author(s):  Mikko Tyster, Atte Hulkkonen
-- Summary  :  Seraphim T3 Mobile Lightning Anti-Air
-- Copyright © 2008 Blade Braver!
------------------------------------------------------------------------------

local SLandUnit = import("/lua/seraphimunits.lua").SLandUnit
--local CollisionBeamFile = import("/lua/kirvesbeams.lua")
local DefaultBeamWeapon = import("/lua/sim/defaultweapons.lua").DefaultBeamWeapon
--local Dummy = import("/lua/kirvesweapons.lua").Dummy
local EffectTemplate = import("/lua/effecttemplates.lua")

local CollisionBeam = import("/lua/sim/collisionbeam.lua").CollisionBeam
local SCCollisionBeam = import("/lua/defaultcollisionbeams.lua").SCCollisionBeam

local PhasonCollisionBeam = ClassWeapon(SCCollisionBeam) {

    FxBeamStartPoint = {
        '/Effects/Emitters/seraphim_experimental_phasonproj_muzzle_flash_01_emit.bp',
        '/Effects/Emitters/seraphim_experimental_phasonproj_muzzle_flash_02_emit.bp',
        '/Effects/Emitters/seraphim_experimental_phasonproj_muzzle_flash_03_emit.bp',
        '/Effects/Emitters/seraphim_experimental_phasonproj_muzzle_flash_04_emit.bp',
        '/Effects/Emitters/seraphim_experimental_phasonproj_muzzle_flash_05_emit.bp',
        '/Effects/Emitters/seraphim_experimental_phasonproj_muzzle_flash_06_emit.bp',
        '/Effects/Emitters/seraphim_electricity_emit.bp'
    },
    FxBeam = {
        '/Effects/Emitters/seraphim_lightning_beam_01_emit.bp',
    },
    FxBeamEndPoint = {
        '/Effects/Emitters/seraphim_lightning_hit_01_emit.bp',
        '/Effects/Emitters/seraphim_lightning_hit_02_emit.bp',
        '/Effects/Emitters/seraphim_lightning_hit_03_emit.bp',
        '/Effects/Emitters/seraphim_lightning_hit_04_emit.bp',
    },


    TerrainImpactType = 'LargeBeam01',
    TerrainImpactScale = 0.2,
    SplatTexture = 'czar_mark01_albedo',
    ScorchSplatDropTime = 0.25,
}

local PhasonCollisionBeam2 = ClassWeapon(PhasonCollisionBeam) {

    FxBeam = { '/Effects/Emitters/seraphim_lightning_beam_02_emit.bp', },
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
        local LastPosition = Vector(0,0,0)
        local skipCount = 1
        local Util = import("/lua/utilities.lua")

        while true do
            if Util.GetDistanceBetweenTwoVectors(CurrentPosition, LastPosition) > 0.25 or skipCount > 100 then
                CreateSplat(CurrentPosition, Util.GetRandomFloat(0,2*math.pi), self.SplatTexture, size, size, 100, 100, self.Army)
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
}

local PhasonBeam = ClassWeapon(DefaultBeamWeapon) {
    BeamType = PhasonCollisionBeam,
    FxMuzzleFlash = import("/lua/effecttemplates.lua").NoEffects,
    FxChargeMuzzleFlash = import("/lua/effecttemplates.lua").NoEffects,
    FxUpackingChargeEffects = EffectTemplate.CMicrowaveLaserCharge01,
    FxUpackingChargeEffectScale = 0.2,
}

---@class DSLK004 : SLandUnit
DSLK004 = ClassUnit(SLandUnit) {
    Weapons = {
        PhasonBeamAir = ClassWeapon(PhasonBeam) {},
        PhasonBeamGround = ClassWeapon(PhasonBeam) {
            BeamType = PhasonCollisionBeam2,
            FxBeamEndPointScale = 0.01,
        },
    },

    OnStopBeingBuilt = function(self,builder,layer)
        SLandUnit.OnStopBeingBuilt(self,builder,layer)

        local EfctTempl = {
            '/Effects/Emitters/orbeffect_01.bp',
            '/Effects/Emitters/orbeffect_02.bp',
        }
        for k, v in EfctTempl do
            CreateAttachedEmitter(self, 'Orb', self.Army, v)
        end
    end,
}
TypeClass = DSLK004