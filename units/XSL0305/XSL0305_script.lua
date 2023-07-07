--------------------------------------------------------------------------------
--  File     :  /data/units/XSL0305/XSL0305_script.lua
--
--  Summary  :  Seraphim Sniper Bot Script
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------------

local SeraphimWeapons = import("/lua/seraphimweapons.lua")
local SLandUnit = import("/lua/seraphimunits.lua").SLandUnit

local SDFSihEnergyRifleNormalMode = SeraphimWeapons.SDFSniperShotNormalMode
local SDFSihEnergyRifleSniperMode = SeraphimWeapons.SDFSniperShotSniperMode

---@class XSL0305 : SLandUnit
---@field TrashSniperFx TrashBag
XSL0305 = ClassUnit(SLandUnit) {
    Weapons = {
        -- used for both modes of operation
        MainGun = ClassWeapon(SDFSihEnergyRifleNormalMode) {
            -- used to determine the reload time after a shot (the next shot's RoF should be used)
            ---@param self SDFSniperShotNormalMode
            GetWeaponRoF = function(self)
                local baseRoF = self.NextBlueprint.RateOfFire or self.Blueprint.RateOfFire
                return baseRoF / (self.AdjRoFMod or 1)
            end,

            RackSalvoFireReadyState = State(SDFSihEnergyRifleNormalMode.RackSalvoFireReadyState) {
                Main = function(self)
                    -- it will keep looping through this state - we only want to check the first
                    -- time (immediately after a shot)
                    if self.FiredAShot then
                        self.FiredAShot = nil
                        local scheduledMode = self.unit.ScheduledForSniperMode
                        if scheduledMode ~= nil then
                            self.unit:SetSniperMode(scheduledMode)
                            self.unit.ScheduledForSniperMode = nil
                        end
                    end
                    SDFSihEnergyRifleNormalMode.RackSalvoFireReadyState.Main(self)
                end,
            },

            RackSalvoFiringState = State(SDFSihEnergyRifleNormalMode.RackSalvoFiringState) {
                Main = function(self)
                    self.FiredAShot = true
                    SDFSihEnergyRifleNormalMode.RackSalvoFiringState.Main(self)
                end,
            },
        },
        -- kind of a dummy weapon that carries the data of the sniper mode for the main gun
        SniperGun = ClassWeapon(SDFSihEnergyRifleSniperMode) {},
    },

    ---@param self XSL0305
    OnCreate = function(self)
        SLandUnit.OnCreate(self)
        self:SetWeaponEnabledByLabel("SniperGun", false)
        self.TrashSniperFx = TrashBag()
    end,

    ---@param self XSL0305
    ---@param bit integer
    OnScriptBitSet = function(self, bit)
        SLandUnit.OnScriptBitSet(self, bit)
        if bit == 1 then
            self:ScheduleSniperMode(true)
        end
    end,

    ---@param self XSL0305
    ---@param bit integer
    OnScriptBitClear = function(self, bit)
        SLandUnit.OnScriptBitClear(self, bit)
        if bit == 1 then
            self:ScheduleSniperMode(false)
        end
    end,

    ---@param self XSL0305
    ---@param mode boolean
    ScheduleSniperMode = function(self, mode)
        local weapon = self:GetWeaponByLabel("MainGun")
        -- The engine needs the next rate of fire set before the projectile launches and there
        -- doesn't seem to be any other time we get before that happens to set it.
        local nextBp
        if mode then
            nextBp = self:GetWeaponByLabel("SniperGun").Blueprint
        else
            nextBp = weapon:GetBlueprint()
        end
        weapon:ChangeRateOfFire(nextBp.RateOfFire)
        weapon.NextBlueprint = nextBp -- keep around to properly get the RoF of the next shot

        if weapon:GetFireClockPct() == 1 then -- idle, ready to switch now
            self:SetSniperMode(mode)
        else
            if self.ScheduledForSniperMode ~= nil and self.ScheduledForSniperMode ~= mode then
                self.ScheduledForSniperMode = nil -- cancel a double toggle
                weapon.NextBlueprint = nil
            else
                self.ScheduledForSniperMode = mode
            end
        end
    end,

    ---@param self XSL0305
    ---@param mode boolean
    SetSniperMode = function(self, mode)
        local speedMult = self.Blueprint.Physics.LandSpeedMultiplier or 1 -- left for compatability
        local label
        if mode then
            label = "SniperGun"
            speedMult = speedMult * (self.Blueprint.Physics.SniperModeSpeedMultiplier or 0.75)
            if not self.TrashSniperFx[1] then
                self.TrashSniperFx:Add(CreateAttachedEmitter(self, "XSL0305", self.Army,
                        "/effects/emitters/seraphim_being_built_ambient_01_emit.bp"))
            end
        else
            label = "MainGun"
            self.TrashSniperFx:Destroy()
        end

        self:SetSpeedMult(speedMult)

        local weapon = self:GetWeaponByLabel("MainGun")
        local bp = weapon.NextBlueprint or self:GetWeaponByLabel(label):GetBlueprint()
        -- a lot of the firing sequence relies on the stored blueprint - we'll store the current
        -- weapon blueprint so that it works
        weapon.Blueprint = bp
        weapon.NextBlueprint = nil
        weapon.FxMuzzleFlash = self.Weapons[label].FxMuzzleFlash
        weapon.damageTableCache = false
        weapon:ChangeProjectileBlueprint(bp.ProjectileId)
        weapon:ChangeFiringTolerance(bp.FiringTolerance)
        weapon:ChangeMaxRadius(bp.MaxRadius)
        weapon:ChangeRateOfFire(bp.RateOfFire)
        weapon:SetTurretYawSpeed(bp.TurretYawSpeed)

        -- old dummy weapon introduced to make the sniper bot go to the correct attack distance
        -- (orders use the max range of the first weapon in the blueprint) back when both weapons
        -- were used - since we change the range of the main gun now, we could use that instead,
        -- but we don't for compatability
        self:GetWeaponByLabel("DummyWeapon"):ChangeMaxRadius(bp.MaxRadius)
    end,
}
TypeClass = XSL0305

--- Kept for mod support
local EffectUtil = import("/lua/effectutilities.lua")