-- ****************************************************************************
-- **
-- **  File     :  /lua/sim/Weapon.lua
-- **  Author(s):  John Comes
-- **
-- **  Summary  : The base weapon class for all weapons in the game.
-- **
-- **  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

local Entity = import("/lua/sim/entity.lua").Entity
local NukeDamage = import("/lua/sim/nukedamage.lua").NukeAOE
local ParseEntityCategoryProperly = import("/lua/sim/categoryutils.lua").ParseEntityCategoryProperly
local cachedPriorities = false
local RecycledPriTable = {}

local function ParsePriorities()
    local idlist = EntityCategoryGetUnitList(categories.ALLUNITS)
    local finalPriorities = {}
    local StringFind = string.find
    local ParseEntityCategoryProperly = ParseEntityCategoryProperly
    local ParseEntityCategory = ParseEntityCategory

    for _, id in idlist do
        local weapons = GetUnitBlueprintByName(id).Weapon
        if not weapons then
            continue
        end
        for _, weapon in weapons do
            local priorities = weapon.TargetPriorities
            if not priorities then
                continue
            end
            for _, priority in priorities do
                if not finalPriorities[priority] then
                    if StringFind(priority, '%(', 1, true) then
                        finalPriorities[priority] = ParseEntityCategoryProperly(priority)
                    else
                        finalPriorities[priority] = ParseEntityCategory(priority)
                    end
                end
            end
        end
    end
    return finalPriorities
end

local WeaponMethods = moho.weapon_methods

---@class Weapon : moho.weapon_methods
---@field AimControl? moho.AimManipulator
---@field AimLeft? moho.AimManipulator
---@field AimRight? moho.AimManipulator
---@field Army Army
---@field Blueprint WeaponBlueprint
---@field Brain AIBrain
---@field CollideFriendly boolean
---@field DamageMod number
---@field DamageRadiusMod number
---@field DisabledBuffs table
---@field EnergyRequired? number
---@field EnergyDrainPerSecond? number
---@field Label string
---@field NumTargets number
---@field Trash TrashBag
---@field unit Unit
---@field MaxRadius? number
---@field MinRadius? number
Weapon = ClassWeapon(WeaponMethods) {

    -- stored here for mods compatibility, overridden in the inner table when written to
    DamageMod = 0,
    DamageRadiusMod = 0,

    ---@param self Weapon
    ---@param unit Unit
    __init = function(self, unit)
        self.unit = unit
    end,

    ---@param self Weapon
    OnCreate = function(self)
        -- Store blueprint for improved access pattern, see benchmark on blueprints
        local bp = self:GetBlueprint()
        self.Blueprint = bp

        -- Legacy information stored for backwards compatibility
        self.Label = bp.Label
        self.EnergyRequired = bp.EnergyRequired
        self.EnergyDrainPerSecond = bp.EnergyDrainPerSecond

        local unit = self.unit
        self.Brain = unit:GetAIBrain()
        self.Army = unit:GetArmy()
        self.Trash = unit.Trash

        self:SetValidTargetsForCurrentLayer(unit.Layer)

        if bp.Turreted then
            self:SetupTurret(bp)
        end

        self:SetWeaponPriorities()
        self.DisabledBuffs = {}
        local initStore = bp.InitialProjectileStorage
        if initStore and initStore > 0 then
            local maxProjStore = bp.MaxProjectileStorage
            if maxProjStore and maxProjStore < initStore then
                initStore = maxProjStore
            end
            self:ForkThread(self.AmmoThread, bp.NukeWeapon, initStore)
        end

        self.CollideFriendly = bp.CollideFriendly or false
    end,

    ---@param self Weapon
    ---@param nuke NukeProjectile
    ---@param amount number
    AmmoThread = function(self, nuke, amount)
        WaitSeconds(0.1)
        if nuke then
            self.unit:GiveNukeSiloAmmo(amount)
        else
            self.unit:GiveTacticalSiloAmmo(amount)
        end
    end,

    ---@param self Weapon
    ---@param bp? WeaponBlueprint
    SetupTurret = function(self, bp)
        bp = bp or self.Blueprint -- defensive programming

        local yawBone = bp.TurretBoneYaw
        local pitchBone = bp.TurretBonePitch
        local muzzleBone = bp.TurretBoneMuzzle
        local precedence = bp.AimControlPrecedence or 10
        local pitchBone2, muzzleBone2

        local boneDualPitch = bp.TurretBoneDualPitch
        if boneDualPitch and boneDualPitch ~= '' then
            pitchBone2 = boneDualPitch
        end
        local boneDualMuzzle = bp.TurretBoneDualMuzzle
        if boneDualMuzzle and boneDualMuzzle ~= '' then
            muzzleBone2 = boneDualMuzzle
        end
        local unit = self.unit
        if not (unit:ValidateBone(yawBone) and unit:ValidateBone(pitchBone) and unit:ValidateBone(muzzleBone)) then
            error('*ERROR: Bone aborting turret setup due to bone issues.', 2)
            return
        elseif pitchBone2 and muzzleBone2 then
            if not (unit:ValidateBone(pitchBone2) and unit:ValidateBone(muzzleBone2)) then
                error('*ERROR: Bone aborting turret setup due to pitch/muzzle bone2 issues.', 2)
                return
            end
        end
        local aimControl, aimRight, aimLeft
        if yawBone and pitchBone and muzzleBone then
            local trashManipulators = self.Trash
            if bp.TurretDualManipulators then
                aimControl = CreateAimController(self, 'Torso', yawBone)
                aimRight = CreateAimController(self, 'Right', pitchBone, pitchBone, muzzleBone)
                aimLeft = CreateAimController(self, 'Left', pitchBone2, pitchBone2, muzzleBone2)
                self.AimRight = aimRight
                self.AimLeft = aimLeft
                aimControl:SetPrecedence(precedence)
                aimRight:SetPrecedence(precedence)
                aimLeft:SetPrecedence(precedence)
                if EntityCategoryContains(categories.STRUCTURE, unit) then
                    aimControl:SetResetPoseTime(9999999)
                end
                self:SetFireControl('Right')
                trashManipulators:Add(aimControl)
                trashManipulators:Add(aimRight)
                trashManipulators:Add(aimLeft)
            else
                aimControl = CreateAimController(self, 'Default', yawBone, pitchBone, muzzleBone)
                if EntityCategoryContains(categories.STRUCTURE, unit) then
                    aimControl:SetResetPoseTime(9999999)
                end
                trashManipulators:Add(aimControl)
                aimControl:SetPrecedence(precedence)
                if bp.RackSlavedToTurret and not table.empty(bp.RackBones) then
                    for _, v in bp.RackBones do
                        local rackBone = v.RackBone
                        if rackBone ~= pitchBone then
                            local slaver = CreateSlaver(unit, rackBone, pitchBone)
                            slaver:SetPrecedence(precedence - 1)
                            trashManipulators:Add(slaver)
                        end
                    end
                end
            end
        else
            error('*ERROR: Trying to setup a turreted weapon but there are yaw bones, pitch bones or muzzle bones missing from the blueprint.', 2)
        end
        self.AimControl = aimControl

        local numbersExist = true
        local turretyawmin, turretyawmax, turretyawspeed
        local turretpitchmin, turretpitchmax, turretpitchspeed

        -- SETUP MANIPULATORS AND SET TURRET YAW, PITCH AND SPEED
        if bp.TurretYaw and bp.TurretYawRange then
            turretyawmin, turretyawmax = self:GetTurretYawMinMax(bp)
        else
            numbersExist = false
        end
        if bp.TurretYawSpeed then
            turretyawspeed = self:GetTurretYawSpeed(bp)
        else
            numbersExist = false
        end
        if bp.TurretPitch and bp.TurretPitchRange then
            turretpitchmin, turretpitchmax = self:GetTurretPitchMinMax(bp)
        else
            numbersExist = false
        end
        if bp.TurretPitchSpeed then
            turretpitchspeed = self:GetTurretPitchSpeed(bp)
        else
            numbersExist = false
        end
        if numbersExist then
            aimControl:SetFiringArc(turretyawmin, turretyawmax, turretyawspeed, turretpitchmin, turretpitchmax, turretpitchspeed)
            if aimRight and aimLeft then -- although, they should both exist if either one does
                turretyawmin = turretyawmin / 12
                turretyawmax = turretyawmax / 12
                aimRight:SetFiringArc(turretyawmin, turretyawmax, turretyawspeed, turretpitchmin, turretpitchmax, turretpitchspeed)
                aimLeft:SetFiringArc(turretyawmin, turretyawmax, turretyawspeed, turretpitchmin, turretpitchmax, turretpitchspeed)
            end
        else
            local strg = '*ERROR: TRYING TO SETUP A TURRET WITHOUT ALL TURRET NUMBERS IN BLUEPRINT, ABORTING TURRET SETUP. WEAPON: ' .. bp.Label .. ' UNIT: '.. unit.UnitId
            error(strg, 2)
        end
    end,

    ---@param self Weapon
    ---@param enabled boolean
    AimManipulatorSetEnabled = function(self, enabled)
        local aimControl = self.AimControl
        if aimControl then
            aimControl:SetEnabled(enabled)
        end
    end,

    ---@param self Weapon
    GetAimManipulator = function(self)
        return self.AimControl
    end,

    ---@param self Weapon
    ---@param speed number
    SetTurretYawSpeed = function(self, speed)
        local aimControl = self.AimControl
        if aimControl then
            local turretyawmin, turretyawmax = self:GetTurretYawMinMax()
            local turretpitchmin, turretpitchmax = self:GetTurretPitchMinMax()
            local turretpitchspeed = self:GetTurretPitchSpeed()
            aimControl:SetFiringArc(turretyawmin, turretyawmax, speed, turretpitchmin, turretpitchmax, turretpitchspeed)
        end
    end,

    ---@param self Weapon
    ---@param speed number
    ---@param bp WeaponBlueprint
    SetTurretPitchSpeed = function(self, speed, bp)
        local aimControl = self.AimControl
        if aimControl then
            bp = bp or self.Blueprint -- backwards compatibility for mods
            local turretyawmin, turretyawmax = self:GetTurretYawMinMax(bp)
            local turretpitchmin, turretpitchmax = self:GetTurretPitchMinMax(bp)
            local turretyawspeed = self:GetTurretYawSpeed(bp)
            aimControl:SetFiringArc(turretyawmin, turretyawmax, turretyawspeed, turretpitchmin, turretpitchmax, speed)
        end
    end,

    --- Retrieves the min / max yaw values of the weapon
    ---@param self Weapon
    ---@param bp? WeaponBlueprint Optional blueprint value that is manually retrieved if not present
    GetTurretYawMinMax = function(self, bp)
        bp = bp or self.Blueprint -- backwards compatibility for mods
        local turretyawmin = bp.TurretYaw - bp.TurretYawRange
        local turretyawmax = bp.TurretYaw + bp.TurretYawRange
        return turretyawmin, turretyawmax
    end,

    --- Retrieves the yaw speed of the weapon
    ---@param self Weapon
    ---@param bp? WeaponBlueprint Optional blueprint value that is manually retrieved if not present
    GetTurretYawSpeed = function(self, bp)
        bp = bp or self.Blueprint -- backwards compatibility for mods
        return bp.TurretYawSpeed
    end,

    --- Retrieves the min / max pitch values of the weapon
    ---@param self Weapon
    ---@param bp? WeaponBlueprint Optional blueprint value that is manually retrieved if not present
    GetTurretPitchMinMax = function(self, bp)
        bp = bp or self.Blueprint -- backwards compatibility for mods
        local turretpitchmin = bp.TurretPitch - bp.TurretPitchRange
        local turretpitchmax = bp.TurretPitch + bp.TurretPitchRange
        return turretpitchmin, turretpitchmax
    end,

    --- Retrieves the pitch speed of the weapon
    ---@param self Weapon
    ---@param bp? WeaponBlueprint Optional blueprint value that is manually retrieved if not present
    GetTurretPitchSpeed = function(self, bp)
        bp = bp or self.Blueprint -- backwards compatibility for mods
        return bp.TurretPitchSpeed
    end,

    ---@param self Weapon
    OnFire = function(self)
        self:PlayWeaponSound('Fire')
        self:DoOnFireBuffs()
    end,

    ---@param self Weapon
    OnEnableWeapon = function(self)
    end,

    ---@param self Weapon
    OnGotTarget = function(self)
        local animator = self.unit.Animator
        if self.DisabledFiringBones and animator then
            for _, value in self.DisabledFiringBones do
                animator:SetBoneEnabled(value, false)
            end
        end
    end,

    ---@param self Weapon
    OnLostTarget = function(self)
        local animator = self.unit.Animator
        if self.DisabledFiringBones and animator then
            for _, value in self.DisabledFiringBones do
                animator:SetBoneEnabled(value, true)
            end
        end
    end,

    ---@param self Weapon
    ---@param label string
    OnStartTracking = function(self, label)
        self:PlayWeaponSound('BarrelStart')
        self:PlayWeaponAmbientSound('BarrelLoop')
    end,

    ---@param self Weapon
    ---@param label string
    OnStopTracking = function(self, label)
        self:PlayWeaponSound('BarrelStop')
        self:StopWeaponAmbientSound('BarrelLoop')
        if EntityCategoryContains(categories.STRUCTURE, self.unit) then
            self.AimControl:SetResetPoseTime(9999999)
        end
    end,

    ---@param self Weapon
    ---@param sound SoundBlueprint
    PlayWeaponSound = function(self, sound)
        local weaponSound = self.Blueprint.Audio[sound]
        if not weaponSound then return end
        self:PlaySound(weaponSound)
    end,

    ---@param self Weapon
    ---@param sound SoundBlueprint
    PlayWeaponAmbientSound = function(self, sound)
        local audio = self.Blueprint.Audio[sound]
        if not audio then return end
        local ambientSounds = self.AmbientSounds
        if not self.AmbientSounds then
            ambientSounds = {}
            self.AmbientSounds = ambientSounds
        end
        local ambientSound = ambientSounds[sound]
        if not ambientSound then
            ambientSound = Entity {}
            ambientSounds[sound] = ambientSound
            self.Trash:Add(ambientSound)
            ambientSound:AttachTo(self.unit, -1)
        end
        ambientSound:SetAmbientSound(audio, nil)
    end,

    ---@param self Weapon
    ---@param sound SoundBlueprint
    StopWeaponAmbientSound = function(self, sound)
        local ambientSounds = self.AmbientSounds
        if not ambientSounds then return end
        local ambientSound = ambientSounds[sound]
        if not ambientSound then return end
        if not self.Blueprint.Audio[sound] then return end
        ambientSound:Destroy()
        ambientSounds[sound] = nil
    end,

    ---@param self Weapon
    ---@param new any
    ---@param old any
    OnMotionHorzEventChange = function(self, new, old)
    end,

    ---@param self Weapon
    GetDamageTableInternal = function(self)
        local weaponBlueprint = self.Blueprint
        local damageTable = {}
        damageTable.InitialDamageAmount = weaponBlueprint.InitialDamage or 0
        damageTable.DamageRadius = weaponBlueprint.DamageRadius + self.DamageRadiusMod
        damageTable.DamageAmount = weaponBlueprint.Damage + self.DamageMod
        damageTable.DamageType = weaponBlueprint.DamageType
        damageTable.DamageFriendly = weaponBlueprint.DamageFriendly
        if damageTable.DamageFriendly == nil then
            damageTable.DamageFriendly = true
        end
        damageTable.CollideFriendly = weaponBlueprint.CollideFriendly or false
        damageTable.DoTTime = weaponBlueprint.DoTTime
        damageTable.DoTPulses = weaponBlueprint.DoTPulses
        damageTable.MetaImpactAmount = weaponBlueprint.MetaImpactAmount
        damageTable.MetaImpactRadius = weaponBlueprint.MetaImpactRadius
        damageTable.ArtilleryShieldBlocks = weaponBlueprint.ArtilleryShieldBlocks

        -- Add buff
        damageTable.Buffs = {}
        if weaponBlueprint.Buffs ~= nil then
            for k, v in weaponBlueprint.Buffs do
                if not self.DisabledBuffs[v.BuffType] then
                    damageTable.Buffs[k] = v
                end
            end
        end

        damageTable.__index = damageTable

        return damageTable
    end,

    damageTableCache = false,
    ---@param self Weapon
    ---@return table | boolean
    GetDamageTable = function(self)
        if not self.damageTableCache then
            self.damageTableCache = self:GetDamageTableInternal()
        end
        return self.damageTableCache
    end,

    ---@param self Weapon
    ---@param bone Bone
    ---@return Projectile
    CreateProjectileForWeapon = function(self, bone)
        local proj = self:CreateProjectile(bone)

        -- store the original target, can be nil if ground firing
        proj.OriginalTarget = self:GetCurrentTarget()
        if proj.OriginalTarget.GetSource then
            proj.OriginalTarget = proj.OriginalTarget:GetSource()
        end

        local damageTable = self:GetDamageTable()
        if proj and not proj:BeenDestroyed() then
            proj:PassMetaDamage(damageTable)
            local bp = self.Blueprint

            if bp.NukeOuterRingDamage and bp.NukeOuterRingRadius and bp.NukeOuterRingTicks and bp.NukeOuterRingTotalTime and
                bp.NukeInnerRingDamage and bp.NukeInnerRingRadius and bp.NukeInnerRingTicks and bp.NukeInnerRingTotalTime then
                proj.InnerRing = NukeDamage()
                proj.InnerRing:OnCreate(bp.NukeInnerRingDamage, bp.NukeInnerRingRadius, bp.NukeInnerRingTicks, bp.NukeInnerRingTotalTime)
                proj.OuterRing = NukeDamage()
                proj.OuterRing:OnCreate(bp.NukeOuterRingDamage, bp.NukeOuterRingRadius, bp.NukeOuterRingTicks, bp.NukeOuterRingTotalTime)

                -- Need to store these three for later, in case the missile lands after the launcher dies
                proj.Launcher = self.unit
                proj.Army = self.Army
                proj.Brain = self.Brain
            end
        end
        return proj
    end,

    ---@param self Weapon
    ---@param newLayer Layer
    SetValidTargetsForCurrentLayer = function(self, newLayer)
        -- LOG('SetValidTargetsForCurrentLayer, layer = ', newLayer)
        local weaponBlueprint = self.Blueprint
        if weaponBlueprint.FireTargetLayerCapsTable then
            if weaponBlueprint.FireTargetLayerCapsTable[newLayer] then
                -- LOG('Setting Target Layer Caps to ', weaponBlueprint.FireTargetLayerCapsTable[newLayer])
                self:SetFireTargetLayerCaps(weaponBlueprint.FireTargetLayerCapsTable[newLayer])
            else
                -- LOG('Setting Target Layer Caps to None')
                self:SetFireTargetLayerCaps('None')
            end
        end
    end,

    ---@param self Weapon
    OnDestroy = function(self)
    end,

    ---@param self Weapon
    ---@param priorities number
    SetWeaponPriorities = function(self, priorities)
        if priorities then
            if type(priorities[1]) == 'string' then
                local count = 1
                local priorityTable = RecycledPriTable
                for _, v in priorities do
                    priorityTable[count] = ParseEntityCategory(v)
                    count = count + 1
                end
                self:SetTargetingPriorities(priorityTable)
                for i = 1, count - 1 do
                    priorityTable[i] = nil
                end
            else
                self:SetTargetingPriorities(priorities)
            end
        else
            priorities = cachedPriorities
            if not priorities then
                priorities = ParsePriorities()
                cachedPriorities = priorities
            end
            local bp = self.Blueprint.TargetPriorities
            if bp then
                local count = 0
                local priorityTable = RecycledPriTable
                for _, v in bp do
                    count = count + 1
                    if priorities[v] then
                        priorityTable[count] = priorities[v]
                    else
                        if string.find(v, '%(') then
                            cachedPriorities[v] = ParseEntityCategoryProperly(v)
                            priorityTable[count] = priorities[v]
                        else
                            cachedPriorities[v] = ParseEntityCategory(v)
                            priorityTable[count] = priorities[v]
                        end
                    end
                end
                self:SetTargetingPriorities(priorityTable)
                for i = 1, count do
                    priorityTable[i] = nil
                end
            end
        end
    end,

    ---@param self Weapon
    WeaponUsesEnergy = function(self)
        return self.EnergyRequired and self.EnergyRequired > 0
    end,

    ---@param self Weapon
    ---@param fn function
    ---@param ... any
    ---@return thread|nil
    ForkThread = function(self, fn, ...)
        if fn then
            local thread = ForkThread(fn, self, unpack(arg))
            self.Trash:Add(thread)
            return thread
        else
            return nil
        end
    end,

    ---@param self Weapon
    ---@param old number
    ---@param new number
    OnVeteranLevel = function(self, old, new)
        local bp = self.Blueprint.Buffs
        if not bp then return end

        local lvlkey = 'VeteranLevel' .. new
        for _, v in bp do
            if v.Add[lvlkey] == true then
                self:AddBuff(v)
            end
        end
    end,

    ---@param self Weapon
    ---@param buffTbl BlueprintBuff
    AddBuff = function(self, buffTbl)
        self.unit:AddWeaponBuff(buffTbl, self)
    end,

    ---@param self Weapon
    ---@param dmgMod number 
    AddDamageMod = function(self, dmgMod)
        self.DamageMod = self.DamageMod + dmgMod
        self.damageTableCache = false
    end,

    ---@param self Weapon
    ---@param dmgRadMod? number This is optional
    AddDamageRadiusMod = function(self, dmgRadMod)
        if dmgRadMod then
            self.DamageRadiusMod = self.DamageRadiusMod + dmgRadMod
        end
        self.damageTableCache = false
    end,

    ---@param self Weapon
    DoOnFireBuffs = function(self)
        local data = self.Blueprint
        if data.Buffs then
            for _, buff in data.Buffs do
                if buff.Add.OnFire then
                    self.unit:AddBuff(buff)
                end
            end
        end
    end,

    ---@param self Weapon
    ---@param buffname string
    DisableBuff = function(self, buffname)
        if buffname then
            self.DisabledBuffs[buffname] = true
        else
            -- Error
            error('ERROR: DisableBuff in weapon.lua does not have a buffname')
        end
        self.damageTableCache = false
    end,

    ---@param self Weapon
    ---@param buffname string
    ReEnableBuff = function(self, buffname)
        if buffname then
            self.DisabledBuffs[buffname] = nil
        else
            -- Error
            error('ERROR: ReEnableBuff in weapon.lua does not have a buffname')
        end
        self.damageTableCache = false
    end,

    --- Method to mark weapon when parent unit gets loaded on to a transport unit
    ---@param self Weapon
    ---@param transportstate boolean
    SetOnTransport = function(self, transportstate)
        self.onTransport = transportstate
        if not transportstate then
            -- send a message to tell the weapon that the unit just got dropped and needs to restart aim
            self:OnLostTarget()
        end
        -- Disable weapon if on transport and not allowed to fire from it
        if not self.unit:GetBlueprint().Transport.CanFireFromTransport then
            if transportstate then
                self.WeaponDisabledOnTransport = true
                self:SetWeaponEnabled(false)
            else
                self:SetWeaponEnabled(true)
                self.WeaponDisabledOnTransport = false
            end
        end
    end,

    --- Method to retreive onTransport information. True if the parent unit has been loaded on to a transport unit.
    ---@param self Weapon
    GetOnTransport = function(self)
        return self.onTransport
    end,

    --- This is the function to set a weapon enabled.
    --- If the weapon is enhabled by an enhancement, this will check to see if the unit has the
    --- enhancement before allowing it to try to be enabled or disabled.
    ---@param self Weapon
    ---@param enable boolean
    SetWeaponEnabled = function(self, enable)
        if not enable then
            self:SetEnabled(enable)
            return
        end
        local enabledByEnh = self.Blueprint.EnabledByEnhancement
        if enabledByEnh then
            local enhancements = SimUnitEnhancements[self.unit.EntityId]
            if enhancements then
                for _, enh in enhancements do
                    if enh == enabledByEnh then
                        self:SetEnabled(enable)
                        return
                    end
                end
            end
            -- enhancement needed, but doesn't have it; don't allow weapon to be enabled
            return
        end
        self:SetEnabled(enable)
    end,

    ---------------------------------------------------------------------------
    --#region Properties

    ---@param self Weapon
    ---@return number
    GetMaxRadius = function(self)
        return self.MaxRadius or self.Blueprint.MaxRadius
    end,

    ---@param self Weapon
    GetMinRadius = function(self)
        return self.MinRadius or self.Blueprint.MinRadius
    end,

    ---------------------------------------------------------------------------
    --#region Hooks

    ---@param self Weapon
    ---@param radius number
    ChangeMaxRadius = function(self, radius)
        WeaponMethods.ChangeMaxRadius(self, radius)
        self.MaxRadius = radius
    end,

    ---@param self Weapon
    ---@param radius number
    ChangeMinRadius = function(self, radius)
        WeaponMethods.ChangeMinRadius(self, radius)
        self.MinRadius = radius
    end,
}
