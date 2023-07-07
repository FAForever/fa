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
            RackSalvoFireReadyState = State(SDFSihEnergyRifleNormalMode.RackSalvoFireReadyState) {
                Main = function(self)
                    -- doesn't appear to be quite the right place to set the scheduled mode
                    local scheduledMode = self.unit.ScheduledForSniperMode
                    if scheduledMode ~= nil then
                        self.unit:SetSniperMode(scheduledMode)
                        self.unit.ScheduledForSniperMode = nil
                    end
                    SDFSihEnergyRifleNormalMode.RackSalvoFireReadyState.Main(self)
                end,
            },

            RackSalvoFiringState = State(SDFSihEnergyRifleNormalMode.RackSalvoFiringState) {
                -- The regular clock always uses the last projectile to get the next rof - this
                -- isn't good for a weapon that can change what projectile it fires.
                -- Unfortunately, while the underlying numbers of ticks to reach 100% is correct,
                -- the output of GetFireClockPct() is scaled to reach it by the current rate of fire,
                -- so it will be a little off when first changing it.
                RenderClockThread = function(self, rof)
                    local unit = self.unit
                    while not self:BeenDestroyed() and not unit.Dead do
                        local prog = self:GetFireClockPct()
                        unit:SetWorkProgress(prog)

                        WaitSeconds(0.1)
                        if prog >= 1 then
                            break
                        end
                    end
                end,
            }
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
        if weapon:GetFireClockPct() == 1 then -- idle, ready to switch now
            self:SetSniperMode(mode)
        else
            if self.ScheduledForSniperMode ~= nil and self.ScheduledForSniperMode ~= mode then
                self.ScheduledForSniperMode = nil -- cancel a double toggle
            else
                self.ScheduledForSniperMode = mode
            end
        end

        -- The engine needs the next rate of fire set before the projectile launches and there
        -- doesn't seem to be a any other time we get until that happens to set it.
        -- Interferes with the clock - oh well.
        local bp
        if mode then
            bp = self:GetWeaponByLabel("SniperGun").Blueprint
        else
            bp = self:GetWeaponByLabel("MainGun"):GetBlueprint()
        end
        weapon:ChangeRateOfFire(bp.RateOfFire)
    end,

    ---@param self XSL0305
    ---@param mode boolean
    SetSniperMode = function(self, mode)
        local speedMult = self.Blueprint.Physics.LandSpeedMultiplier or 1 -- left for compatability
        local label, otherLabel = "SniperGun", "MainGun"
        if mode then
            speedMult = speedMult * (self.Blueprint.Physics.SniperModeSpeedMultiplier or 0.75)
            if not self.TrashSniperFx[1] then
                self.TrashSniperFx:Add(
                    CreateAttachedEmitter(self, "XSL0305", self.Army, "/effects/emitters/seraphim_being_built_ambient_01_emit.bp")
                )
            end
        else
            label, otherLabel = otherLabel, label
            self.TrashSniperFx:Destroy()
        end

        local activeWeapon = self:GetWeaponByLabel("MainGun")
        local bp = self:GetWeaponByLabel(label):GetBlueprint()
        -- a lot of the firing sequence relies on this - we'll store the current weapon blueprint
        -- here so that works (except for the rate of fire, which won't anyway)
        activeWeapon.Blueprint = bp
        activeWeapon.FxMuzzleFlash = self.Weapons[label].FxMuzzleFlash
        activeWeapon:ChangeProjectileBlueprint(bp.ProjectileId)
        activeWeapon:ChangeDamage(bp.Damage)
        activeWeapon.damageTableCache = false
        activeWeapon:ChangeFiringTolerance(bp.FiringTolerance)
        activeWeapon:ChangeMinRadius(bp.MinRadius)
        activeWeapon:ChangeMaxRadius(bp.MaxRadius)
        activeWeapon:ChangeRateOfFire(bp.RateOfFire)
        activeWeapon:SetTurretYawSpeed(bp.TurretYawSpeed)
        self:SetSpeedMult(speedMult)

        -- old dummy weapon introduced to make the sniper bot go to the correct attack distance
        -- (orders use the first weapon in the blueprint) back when both weapons were used - since
        -- we change the range of the main gun now, we could use that instead, but we don't for
        -- compatability
        self:GetWeaponByLabel("DummyWeapon"):ChangeMaxRadius(bp.MaxRadius)
    end,
}
TypeClass = XSL0305

--- Kept for mod support
local EffectUtil = import("/lua/effectutilities.lua")