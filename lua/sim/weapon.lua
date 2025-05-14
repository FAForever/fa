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
---@type false | EntityCategory[]
local cachedPriorities = false
local RecycledPriTable = {}

local DebugWeaponComponent = import("/lua/sim/weapons/components/debugweaponcomponent.lua").DebugWeaponComponent

--- Table of damage information passed from the weapon to the projectile
--- Can be assigned as a meta table to the projectile's damage table to reduce memory usage for unchanged values
---@class WeaponDamageTable
---@field DamageToShields number        # weaponBlueprint.DamageToShields
---@field InitialDamageAmount number    # weaponBlueprint.InitialDamage or 0
---@field DamageRadius number           # weaponBlueprint.DamageRadius + Weapon.DamageRadiusMod
---@field DamageAmount number           # weaponBlueprint.Damage + Weapon.DamageMod
---@field DamageType DamageType         # weaponBlueprint.DamageType
---@field DamageFriendly boolean        # weaponBlueprint.DamageFriendly or true
---@field CollideFriendly boolean       # weaponBlueprint.CollideFriendly or false
---@field DoTTime number                # weaponBlueprint.DoTTime
---@field DoTPulses number              # weaponBlueprint.DoTPulses
---@field MetaImpactAmount any          # weaponBlueprint.MetaImpactAmount
---@field MetaImpactRadius any          # weaponBlueprint.MetaImpactRadius
---@field ArtilleryShieldBlocks boolean # weaponBlueprint.ArtilleryShieldBlocks
---@field Buffs BlueprintBuff[]         # Active buffs for the weapon
---@field __index WeaponDamageTable

---@return EntityCategory[]
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

---@class Weapon : moho.weapon_methods, InternalObject, DebugWeaponComponent
---@field AimControl? moho.AimManipulator
---@field AimLeft? moho.AimManipulator
---@field AimRight? moho.AimManipulator
---@field Army Army
---@field AmbientSounds table<SoundBlueprint, Entity>
---@field Blueprint WeaponBlueprint
---@field Brain AIBrain
---@field CollideFriendly boolean
---@field DamageMod number
---@field DamageModifiers number[] # Set of damage multipliers used by collision beams for the weapon
---@field DamageRadiusMod number
---@field damageTableCache WeaponDamageTable | false # Set to false when the weapon's damage is modified
---@field DisabledBuffs table
---@field DisabledFiringBones Bone[] # Bones that `Unit.Animator` cannot move when this weapon has a target
---@field EnergyRequired? number
---@field EnergyDrainPerSecond? number
---@field Label string
---@field NumTargets number
---@field Trash TrashBag
---@field unit Unit
---@field MaxRadius? number
---@field MinRadius? number
---@field onTransport boolean # True if the parent unit has been loaded on to a transport unit.
Weapon = ClassWeapon(WeaponMethods, DebugWeaponComponent) {

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

        local unit = self.unit
        local precedence = bp.AimControlPrecedence or 10

        local yawBone = bp.TurretBoneYaw
        local pitchBone = bp.TurretBonePitch
        local muzzleBone = bp.TurretBoneMuzzle
        local useDualManipulators = bp.TurretDualManipulators
        local pitchBone2, muzzleBone2
        if useDualManipulators then
            pitchBone2, muzzleBone2 = bp.TurretBoneDualPitch, bp.TurretBoneDualMuzzle
        end
        local yawBone2 = bp.TurretBoneDualYaw

        -- verify bones so that issues are easier to debug, since `CreateAimController` fails silently.
        local issues = ''
        if not yawBone then issues = issues .. 'TurretBoneYaw missing from blueprint, '
        elseif not unit:ValidateBone(yawBone) then issues = issues .. 'TurretBoneYaw "' .. tostring(yawBone) .. '" does not exist in unit mesh, ' end
        if not pitchBone then issues = issues .. 'TurretBonePitch missing from blueprint, '
        elseif not unit:ValidateBone(pitchBone) then issues = issues .. 'TurretBonePitch "' .. tostring(pitchBone) .. '" does not exist in unit mesh, ' end
        if not muzzleBone then issues = issues .. 'TurretBoneMuzzle missing from blueprint, '
        elseif not unit:ValidateBone(muzzleBone) then issues = issues .. 'TurretBoneMuzzle "' .. tostring(muzzleBone) .. '" does not exist in unit mesh, ' end

        if useDualManipulators then
            if not pitchBone then issues = issues .. 'TurretBonePitch missing from blueprint, '
            elseif not unit:ValidateBone(pitchBone2) then issues = issues .. 'TurretBoneDualPitch "' .. tostring(pitchBone2) .. '" does not exist in unit mesh, ' end
            if not muzzleBone then issues = issues .. 'TurretBoneMuzzle missing from blueprint, '
            elseif not unit:ValidateBone(muzzleBone2) then issues = issues .. 'TurretBoneDualMuzzle "' .. tostring(muzzleBone2) .. '" does not exist in unit mesh, ' end
        end

        if yawBone2 and not unit:ValidateBone(yawBone2) then issues = issues .. 'TurretBoneDualYaw "' .. tostring(yawBone2) .. '" does not exist in unit mesh, ' end

        if issues ~= '' then
            WARN(string.format('Weapon "%s" aborting turret setup due to the following bone issues: %s.\n'
                    , tostring(bp.BlueprintId or bp.Label)
                    , string.sub(issues, 1, -3)
                )
                , debug.traceback()
            )
            return
        end

        -- Set up turret aim controllers if bones are valid.

        local aimControl, aimRight, aimLeft, aimYaw2
        local selfTrash = self.Trash
        if useDualManipulators then
            ---@diagnostic disable-next-line: param-type-mismatch
            aimControl = CreateAimController(self, 'Torso', yawBone)
            ---@diagnostic disable-next-line: param-type-mismatch
            aimRight = CreateAimController(self, 'Right', pitchBone, pitchBone, muzzleBone)
            ---@diagnostic disable-next-line: param-type-mismatch
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
            selfTrash:Add(aimControl)
            selfTrash:Add(aimRight)
            selfTrash:Add(aimLeft)
        else
            ---@diagnostic disable-next-line: param-type-mismatch
            aimControl = CreateAimController(self, 'Default', yawBone, pitchBone, muzzleBone)
            if EntityCategoryContains(categories.STRUCTURE, unit) then
                aimControl:SetResetPoseTime(9999999)
            end
            selfTrash:Add(aimControl)
            aimControl:SetPrecedence(precedence)
            if bp.RackSlavedToTurret and not table.empty(bp.RackBones) then
                for _, v in bp.RackBones do
                    local rackBone = v.RackBone
                    if rackBone ~= pitchBone then
                        ---@diagnostic disable-next-line: param-type-mismatch
                        local slaver = CreateSlaver(unit, rackBone, pitchBone)
                        slaver:SetPrecedence(precedence - 1)
                        selfTrash:Add(slaver)
                    end
                end
            end
        end

        if yawBone2 then
            aimYaw2 = CreateAimController(self, 'Yaw2', yawBone2)
            aimYaw2:SetPrecedence(precedence - 1)
            if EntityCategoryContains(categories.STRUCTURE, unit) then
                aimYaw2:SetResetPoseTime(9999999)
            end
            selfTrash:Add(aimYaw2)
        end
        self.AimControl = aimControl

        -- Validate turret yaw, pitch, and speeds

        if not bp.TurretYaw then issues = issues .. 'TurretYaw missing from blueprint, ' end
        if not bp.TurretYawRange then issues = issues .. 'TurretYawRange missing from blueprint, ' end
        if not bp.TurretYawSpeed then issues = issues .. 'TurretYawSpeed missing from blueprint, ' end
        if not bp.TurretPitch then issues = issues .. 'TurretPitch missing from blueprint, ' end
        if not bp.TurretPitchRange then issues = issues .. 'TurretPitchRange missing from blueprint, ' end
        if not bp.TurretPitchSpeed then issues = issues .. 'TurretPitchSpeed missing from blueprint, ' end

        if issues ~= '' then
            WARN(string.format('Weapon "%s" aborting turret setup due to the following turret number issues: %s.\n'
                    , tostring(bp.BlueprintId or bp.Label)
                    , string.sub(issues, 1, -3)
                )
                , debug.traceback()
            )
            return
        end

        -- Set up turret yaw, pitch, and speeds if they're valid.

        local turretyawmin, turretyawmax = self:GetTurretYawMinMax(bp)
        local turretyawspeed = self:GetTurretYawSpeed(bp)
        local turretpitchmin, turretpitchmax = self:GetTurretPitchMinMax(bp)
        local turretpitchspeed = self:GetTurretPitchSpeed(bp)

        aimControl:SetFiringArc(turretyawmin, turretyawmax, turretyawspeed, turretpitchmin, turretpitchmax, turretpitchspeed)
        if aimRight and aimLeft then -- although, they should both exist if either one does
            turretyawmin = turretyawmin / 12
            turretyawmax = turretyawmax / 12
            aimRight:SetFiringArc(turretyawmin, turretyawmax, turretyawspeed, turretpitchmin, turretpitchmax, turretpitchspeed)
            aimLeft:SetFiringArc(turretyawmin, turretyawmax, turretyawspeed, turretpitchmin, turretpitchmax, turretpitchspeed)
        end

        if aimYaw2 then
            local turretYawMin2 = turretyawmin
            local turretYawMax2 = turretyawmax
            if bp.TurretDualYaw and bp.TurretDualYawRange then
                turretYawMin2 = bp.TurretDualYaw - bp.TurretDualYawRange
                turretYawMax2 = bp.TurretDualYaw + bp.TurretDualYawRange
            end

            local turretYawSpeed2 = bp.TurretDualYawSpeed or turretyawspeed
            aimYaw2:SetFiringArc(turretYawMin2, turretYawMax2, turretYawSpeed2, 0, 0, 0)
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
    ---@param bp? WeaponBlueprint
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
        -- a few non-walker units may use `Animator` as well
        local animator = self.unit--[[@as WalkingLandUnit]] .Animator
        if self.DisabledFiringBones and animator then
            for _, value in self.DisabledFiringBones do
                animator:SetBoneEnabled(value, false)
            end
        end
    end,

    ---@param self Weapon
    OnLostTarget = function(self)
        -- a few non-walker units may use `Animator` as well
        local animator = self.unit--[[@as WalkingLandUnit]] .Animator
        if self.DisabledFiringBones and animator then
            for _, value in self.DisabledFiringBones do
                animator:SetBoneEnabled(value, true)
            end
        end
    end,

    ---@param self Weapon
    ---@param label string # label of the aim controller that started tracking
    OnStartTracking = function(self, label)
        self:PlayWeaponSound('BarrelStart')
        self:PlayWeaponAmbientSound('BarrelLoop')
    end,

    ---@param self Weapon
    ---@param label string # label of the aim controller that stopped tracking
    OnStopTracking = function(self, label)
        self:PlayWeaponSound('BarrelStop')
        self:StopWeaponAmbientSound('BarrelLoop')
        if EntityCategoryContains(categories.STRUCTURE, self.unit) then
            self.AimControl:SetResetPoseTime(9999999)
        end
    end,

    ---@param self Weapon
    ---@param sound SoundBlueprint | string # The string is the key for the audio in the weapon blueprint
    PlayWeaponSound = function(self, sound)
        local weaponSound = self.Blueprint.Audio[sound]
        if not weaponSound then return end
        self:PlaySound(weaponSound)
    end,

    ---@param self Weapon
    ---@param sound SoundBlueprint | string # The string is the key for the audio in the weapon blueprint
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
            ---@type Entity
            ambientSound = Entity {}
            ambientSounds[sound] = ambientSound
            self.Trash:Add(ambientSound)
            ambientSound:AttachTo(self.unit, -1)
        end
        ambientSound:SetAmbientSound(audio, nil)
    end,

    ---@param self Weapon
    ---@param sound SoundBlueprint | string # The string is the key for the audio in the weapon blueprint
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
    ---@param new HorizontalMovementState
    ---@param old HorizontalMovementState
    OnMotionHorzEventChange = function(self, new, old)
    end,

    ---@param self Weapon
    GetDamageTableInternal = function(self)
        local weaponBlueprint = self.Blueprint
        ---@type WeaponDamageTable
        local damageTable = {}

        damageTable.DamageToShields = weaponBlueprint.DamageToShields
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
    ---@return WeaponDamageTable
    GetDamageTable = function(self)
        if not self.damageTableCache then
            self.damageTableCache = self:GetDamageTableInternal()
        end
        return self.damageTableCache --[[@as WeaponDamageTable]]
    end,

    ---@param self Weapon
    ---@param bone Bone
    ---@return Projectile
    CreateProjectileForWeapon = function(self, bone)
        local proj = self:CreateProjectile(bone)

        -- used for the retargeting feature
        proj.CreatedByWeapon = self

        -- used for tactical / strategic defenses to ignore all other collisions
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
    ---@param priorities? EntityCategory[] | UnparsedCategory[] | false
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
            self.damageTableCache = false
        else
            error('DisableBuff in weapon.lua does not have a buffname')
        end
    end,

    ---@param self Weapon
    ---@param buffname string
    ReEnableBuff = function(self, buffname)
        if buffname then
            self.DisabledBuffs[buffname] = nil
            self.damageTableCache = false
        else
            error('ReEnableBuff in weapon.lua does not have a buffname')
        end
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
        if not IsDestroyed(self) then
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
        end
    end,

    ---@param self Weapon
    ---@param rateOfFire number
    DisabledWhileReloadingThread = function(self, rateOfFire)

        -- attempts to fix weapons that intercept projectiles to being stuck on a projectile while reloading, preventing
        -- other weapons from targeting that projectile. Is a side effect of the blueprint field `DesiredShooterCap`. This
        -- is the more aggressive variant of `TargetResetWhenReady` as it completely disables the weapon.

        local reloadTime = math.floor(10 * rateOfFire) - 1
        if reloadTime > 4 then
            if IsDestroyed(self) then
                return
            end

            self:SetEnabled(false)
            WaitTicks(reloadTime)

            if IsDestroyed(self) then
                return
            end

            self:SetEnabled(true)
        end
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
