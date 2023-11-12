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
---@field isSniperFiringMode boolean -- Whether the sniper mode is active for next shot
XSL0305 = ClassUnit(SLandUnit) {
    Weapons = {
        -- used for both modes of operation
        MainGun = ClassWeapon(SDFSihEnergyRifleNormalMode) {
            RackSalvoFiringState = State(SDFSihEnergyRifleNormalMode.RackSalvoFiringState) {
                Main = function(self)
                    if self.unit.isSniperFiringMode ~= nil then
                        self.unit:ScheduleMovementChange(0, true)
                        self.unit:ScheduleMovementChange(1 / self:GetWeaponRoF(), false)
                    end
                    SDFSihEnergyRifleNormalMode.RackSalvoFiringState.Main(self)
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
            self:SetSniperMode(true)
        end
    end,

    ---@param self XSL0305
    ---@param bit integer
    OnScriptBitClear = function(self, bit)
        SLandUnit.OnScriptBitClear(self, bit)
        if bit == 1 then
            self:SetSniperMode(false)
        end
    end,

    ---@param self XSL0305
    ---@param delaySeconds number
    ---@param mode boolean -- true activates the slowdown, false deactivates it.
    ScheduleMovementChange = function(self, delaySeconds, mode)
        local switchToMoveMode = function(mode)
            local speedMult = self.Blueprint.Physics.LandSpeedMultiplier or 1 -- left for compatability
            if mode then
                speedMult = speedMult * (self.Blueprint.Physics.SniperModeSpeedMultiplier or 0.75)
                self:SetSpeedMult(speedMult)
                if not self.TrashSniperFx[1] then
                    self.TrashSniperFx:Add(CreateAttachedEmitter(self, "XSL0305", self.Army,
                            "/effects/emitters/seraphim_being_built_ambient_01_emit.bp"))
                end
            else
                self:SetSpeedMult(speedMult)
                self.TrashSniperFx:Destroy()
            end
        end

        if delaySeconds == 0 then
            switchToMoveMode(mode)
        elseif self.isChangingMoveMode == nil then 
            self.Trash:Add(ForkThread(function()
                self.isChangingMoveMode = true
                WaitSeconds(delaySeconds)
                switchToMoveMode(mode)
                self.isChangingMoveMode = nil
                end))
        end
    end,

    ---@param self XSL0305
    ---@param mode boolean
    SetSniperMode = function(self, mode)
        local label
        self.isSniperFiringMode = mode
        if mode then
            label = "SniperGun"
            self.isSniperFiringMode = true
        else
            label = "MainGun"
            self.isSniperFiringMode = nil
        end
        
        local weapon = self:GetWeaponByLabel("MainGun")
        local bp = self:GetWeaponByLabel(label):GetBlueprint()
        -- a lot of the firing sequence relies on the stored blueprint - we'll store the current
        -- weapon blueprint so that it works
        weapon.Blueprint = bp
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
