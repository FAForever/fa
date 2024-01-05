--------------------------------------------------------------------------------
--  File     :  /data/units/XSL0305/XSL0305_script.lua
--
--  Summary  :  Seraphim Sniper Bot Script
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------------

local SeraphimWeapons = import("/lua/seraphimweapons.lua")
local SLandUnit = import("/lua/seraphimunits.lua").SLandUnit
local SLandUnitOnCreate = SLandUnit.OnCreate
local SLandUnitOnScriptBitSet = SLandUnit.OnScriptBitSet
local SLandUnitOnScriptBitClear = SLandUnit.OnScriptBitClear

local SDFSihEnergyRifleNormalMode = SeraphimWeapons.SDFSniperShotNormalMode
local SDFSihEnergyRifleSniperMode = SeraphimWeapons.SDFSniperShotSniperMode

-- upvalue scope for performance
local WaitTicks = WaitTicks
local ForkThread = ForkThread
local CreateAttachedEmitter = CreateAttachedEmitter

---@class XSL0305 : SLandUnit
---@field TrashSniperFx TrashBag
---@field IsChangingMoveMode boolean
---@field IsSniperFiringMode boolean # Whether the sniper mode is active for next shot
XSL0305 = ClassUnit(SLandUnit) {
    Weapons = {
        -- used for both modes of operation
        MainGun = ClassWeapon(SDFSihEnergyRifleNormalMode) {
            RackSalvoFiringState = State(SDFSihEnergyRifleNormalMode.RackSalvoFiringState) {
                Main = function(self)
                    local unit = self.unit
                    if unit.IsSniperFiringMode ~= nil then
                        unit:ScheduleMovementChange(0, true)
                        unit:ScheduleMovementChange(1 / self:GetWeaponRoF(), false)
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
        SLandUnitOnCreate(self)

        self:SetWeaponEnabledByLabel("SniperGun", false)
        self.TrashSniperFx = TrashBag()
    end,

    ---@param self XSL0305
    ---@param bit integer
    OnScriptBitSet = function(self, bit)
        SLandUnitOnScriptBitSet(self, bit)

        if bit == 1 then
            self:SetSniperMode(true)
        end
    end,

    ---@param self XSL0305
    ---@param bit integer
    OnScriptBitClear = function(self, bit)
        SLandUnitOnScriptBitClear(self, bit)

        if bit == 1 then
            self:SetSniperMode(false)
        end
    end,

    ---@param self XSL0305
    ---@param delaySeconds number
    ---@param mode boolean -- true activates the slowdown, false deactivates it.
    ScheduleMovementChange = function(self, delaySeconds, mode)
        if delaySeconds == 0 then
            self:SwitchMoveMode(mode)
        elseif self.IsChangingMoveMode == nil then
            self.Trash:Add(ForkThread(self.ChangeMoveModeThread, self, delaySeconds, mode))
        end
    end,

    ---@param self XSL0305
    ---@param delaySeconds number
    ---@param mode boolean -- true activates the slowdown, false deactivates it.
    ChangeMoveModeThread = function(self, delaySeconds, mode)
        self.IsChangingMoveMode = true
        WaitTicks(10 * delaySeconds + 1)
        self:SwitchMoveMode(mode)
        self.IsChangingMoveMode = nil
    end,

    ---@param self XSL0305
    ---@param mode boolean -- true activates the slowdown, false deactivates it.
    SwitchMoveMode = function(self, mode)
        local blueprintPhysics = self.Blueprint.Physics

        local speedMult = blueprintPhysics.LandSpeedMultiplier or 1 -- left for compatability
        self.TrashSniperFx:Destroy()

        if mode then
            speedMult = speedMult * (blueprintPhysics.SniperModeSpeedMultiplier or 0.75)
            self:SetSpeedMult(speedMult)
            self.TrashSniperFx:Add(
                CreateAttachedEmitter(
                    self, "XSL0305", self.Army,
                    "/effects/emitters/seraphim_being_built_ambient_01_emit.bp"
                )
            )
        else
            self:SetSpeedMult(speedMult)
        end
    end,

    ---@param self XSL0305
    ---@param mode boolean
    SetSniperMode = function(self, mode)
        local label
        if mode then
            label = "SniperGun"
            self.IsSniperFiringMode = true
        else
            label = "MainGun"
            self.IsSniperFiringMode = nil
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

--- backwards compatibility with mods
local EffectUtil = import("/lua/effectutilities.lua")
