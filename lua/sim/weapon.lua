-- ****************************************************************************
-- **
-- **  File     :  /lua/sim/Weapon.lua
-- **  Author(s):  John Comes
-- **
-- **  Summary  : The base weapon class for all weapons in the game.
-- **
-- **  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

local Entity = import('/lua/sim/Entity.lua').Entity
local NukeDamage = import('/lua/sim/NukeDamage.lua').NukeAOE
local Set = import('/lua/system/setutils.lua')
local ParseEntityCategoryProperly = import('/lua/sim/CategoryUtils.lua').ParseEntityCategoryProperly
local cachedPriorities = false

local function ParsePriorities()
    local idlist = EntityCategoryGetUnitList(categories.ALLUNITS)
    local finalPriorities = {}

    for _, id in idlist do
        local weapons = GetUnitBlueprintByName(id).Weapon

        for weaponNum, weapon in weapons or {} do
            for line, priority in weapon.TargetPriorities or {} do
                if not finalPriorities[priority] then
                    if string.find(priority, '%(') then
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

Weapon = Class(moho.weapon_methods) {
    __init = function(self, unit)
        self.unit = unit
    end,

    OnCreate = function(self)

        -- Common accessed (engine-related) values cached
        self.Blueprint = self:GetBlueprint()
        self.Army = self.unit:GetArmy()

        if not self.unit.Trash then
            self.unit.Trash = TrashBag()
        end
        self:SetValidTargetsForCurrentLayer(self.unit:GetCurrentLayer())
        local bp = self.Blueprint
        if bp.Turreted == true then
            self:SetupTurret()
        end
        self:SetWeaponPriorities()
        self.DisabledBuffs = {}
        self.DamageMod = 0
        self.DamageRadiusMod = 0
        self.NumTargets = 0
        local initStore = bp.InitialProjectileStorage
        if initStore and initStore > 0 then
            if bp.MaxProjectileStorage and bp.MaxProjectileStorage < initStore then
                initStore = bp.MaxProjectileStorage
            end
            local nuke = false
            if bp.NukeWeapon then
                nuke = true
            end
            self:ForkThread(self.AmmoThread, nuke, bp.InitialProjectileStorage)
        end

        self.CollideFriendly = bp.CollideFriendly == true
    end,

    AmmoThread = function(self, nuke, amount)
        WaitSeconds(0.1)
        if nuke then
            self.unit:GiveNukeSiloAmmo(amount)
        else
            self.unit:GiveTacticalSiloAmmo(amount)
        end
    end,

    SetupTurret = function(self)
        local bp = self.Blueprint
        local yawBone = bp.TurretBoneYaw
        local pitchBone = bp.TurretBonePitch
        local muzzleBone = bp.TurretBoneMuzzle
        local precedence = bp.AimControlPrecedence or 10
        local pitchBone2
        local muzzleBone2
        if bp.TurretBoneDualPitch and bp.TurretBoneDualPitch ~= '' then
            pitchBone2 = bp.TurretBoneDualPitch
        end
        if bp.TurretBoneDualMuzzle and bp.TurretBoneDualMuzzle ~= '' then
            muzzleBone2 = bp.TurretBoneDualMuzzle
        end
        if not (self.unit:ValidateBone(yawBone) and self.unit:ValidateBone(pitchBone) and self.unit:ValidateBone(muzzleBone)) then
            error('*ERROR: Bone aborting turret setup due to bone issues.', 2)
            return
        elseif pitchBone2 and muzzleBone2 then
            if not (self.unit:ValidateBone(pitchBone2) and self.unit:ValidateBone(muzzleBone2)) then
                error('*ERROR: Bone aborting turret setup due to pitch/muzzle bone2 issues.', 2)
                return
            end
        end
        if yawBone and pitchBone and muzzleBone then
            if bp.TurretDualManipulators then
                self.AimControl = CreateAimController(self, 'Torso', yawBone)
                self.AimRight = CreateAimController(self, 'Right', pitchBone, pitchBone, muzzleBone)
                self.AimLeft = CreateAimController(self, 'Left', pitchBone2, pitchBone2, muzzleBone2)
                self.AimControl:SetPrecedence(precedence)
                self.AimRight:SetPrecedence(precedence)
                self.AimLeft:SetPrecedence(precedence)
                if EntityCategoryContains(categories.STRUCTURE, self.unit) then
                    self.AimControl:SetResetPoseTime(9999999)
                end
                self:SetFireControl('Right')
                self.unit.Trash:Add(self.AimControl)
                self.unit.Trash:Add(self.AimRight)
                self.unit.Trash:Add(self.AimLeft)
            else
                self.AimControl = CreateAimController(self, 'Default', yawBone, pitchBone, muzzleBone)
                if EntityCategoryContains(categories.STRUCTURE, self.unit) then
                    self.AimControl:SetResetPoseTime(9999999)
                end
                self.unit.Trash:Add(self.AimControl)
                self.AimControl:SetPrecedence(precedence)
                if bp.RackSlavedToTurret and not table.empty(bp.RackBones) then
                    for k, v in bp.RackBones do
                        if v.RackBone ~= pitchBone then
                            local slaver = CreateSlaver(self.unit, v.RackBone, pitchBone)
                            slaver:SetPrecedence(precedence-1)
                            self.unit.Trash:Add(slaver)
                        end
                    end
                end
            end
        else
            error('*ERROR: Trying to setup a turreted weapon but there are yaw bones, pitch bones or muzzle bones missing from the blueprint.', 2)
        end


        local numbersexist = true
        local turretyawmin, turretyawmax, turretyawspeed
        local turretpitchmin, turretpitchmax, turretpitchspeed

        -- SETUP MANIPULATORS AND SET TURRET YAW, PITCH AND SPEED
        if bp.TurretYaw and bp.TurretYawRange then
            turretyawmin, turretyawmax = self:GetTurretYawMinMax()
        else
            numbersexist = false
        end
        if bp.TurretYawSpeed then
            turretyawspeed = self:GetTurretYawSpeed()
        else
            numbersexist = false
        end
        if bp.TurretPitch and bp.TurretPitchRange then
            turretpitchmin, turretpitchmax = self:GetTurretPitchMinMax()
        else
            numbersexist = false
        end
        if bp.TurretPitchSpeed then
            turretpitchspeed = self:GetTurretPitchSpeed()
        else
            numbersexist = false
        end
        if numbersexist then
            self.AimControl:SetFiringArc(turretyawmin, turretyawmax, turretyawspeed, turretpitchmin, turretpitchmax, turretpitchspeed)
            if self.AimRight then
                self.AimRight:SetFiringArc(turretyawmin/12, turretyawmax/12, turretyawspeed, turretpitchmin, turretpitchmax, turretpitchspeed)
            end
            if self.AimLeft then
                self.AimLeft:SetFiringArc(turretyawmin/12, turretyawmax/12, turretyawspeed, turretpitchmin, turretpitchmax, turretpitchspeed)
            end
        else
            local strg = '*ERROR: TRYING TO SETUP A TURRET WITHOUT ALL TURRET NUMBERS IN BLUEPRINT, ABORTING TURRET SETUP. WEAPON: ' .. bp.Label .. ' UNIT: '.. self.unit.UnitId
            error(strg, 2)
        end
    end,

    AimManipulatorSetEnabled = function(self, enabled)
        if self.AimControl then
            self.AimControl:SetEnabled(enabled)
        end
    end,

    GetAimManipulator = function(self)
        return self.AimControl
    end,

    SetTurretYawSpeed = function(self, speed)
        local turretyawmin, turretyawmax = self:GetTurretYawMinMax()
        local turretpitchmin, turretpitchmax = self:GetTurretPitchMinMax()
        local turretpitchspeed = self:GetTurretPitchSpeed()
        if self.AimControl then
            self.AimControl:SetFiringArc(turretyawmin, turretyawmax, speed, turretpitchmin, turretpitchmax, turretpitchspeed)
        end
    end,

    SetTurretPitchSpeed = function(self, speed)
        local turretyawmin, turretyawmax = self:GetTurretYawMinMax()
        local turretpitchmin, turretpitchmax = self:GetTurretPitchMinMax()
        local turretpitchspeed = self:GetTurretYawSpeed()
        if self.AimControl then
            self.AimControl:SetFiringArc(turretyawmin, turretyawmax, turretyawspeed, turretpitchmin, turretpitchmax, speed)
        end
    end,

    GetTurretYawMinMax = function(self)
        local bp = self.Blueprint
        local turretyawmin = bp.TurretYaw - bp.TurretYawRange
        local turretyawmax = bp.TurretYaw + bp.TurretYawRange
        return turretyawmin, turretyawmax
    end,

    GetTurretYawSpeed = function(self)
        return self.Blueprint.TurretYawSpeed
    end,

    GetTurretPitchMinMax = function(self)
        local bp = self.Blueprint
        local turretpitchmin = bp.TurretPitch - bp.TurretPitchRange
        local turretpitchmax = bp.TurretPitch + bp.TurretPitchRange
        return turretpitchmin, turretpitchmax
    end,

    GetTurretPitchSpeed = function(self)
        return self.Blueprint.TurretPitchSpeed
    end,

    OnFire = function(self)
        self:PlayWeaponSound('Fire')
        self:DoOnFireBuffs()
    end,

    OnEnableWeapon = function(self)
    end,

    OnGotTarget = function(self)
        if self.DisabledFiringBones and self.unit.Animator then
            for key, value in self.DisabledFiringBones do
                self.unit.Animator:SetBoneEnabled(value, false)
            end
        end
        self.NumTargets = self.NumTargets + 1
    end,

    OnLostTarget = function(self)
        if self.DisabledFiringBones and self.unit.Animator then
            for key, value in self.DisabledFiringBones do
                self.unit.Animator:SetBoneEnabled(value, true)
            end
        end

        self.NumTargets = self.NumTargets - 1
        if self.NumTargets < 0 then
            self.NumTargets = 0
        end
    end,

    OnStartTracking = function(self, label)
        self:PlayWeaponSound('BarrelStart')
        self:PlayWeaponAmbientSound('BarrelLoop')
    end,

    OnStopTracking = function(self, label)
        self:PlayWeaponSound('BarrelStop')
        self:StopWeaponAmbientSound('BarrelLoop')
        if EntityCategoryContains(categories.STRUCTURE, self.unit) then
            self.AimControl:SetResetPoseTime(9999999)
        end

    end,

    PlayWeaponSound = function(self, sound)
        local bp = self.Blueprint
        if not bp.Audio[sound] then return end
        self:PlaySound(bp.Audio[sound])
    end,

    PlayWeaponAmbientSound = function(self, sound)
        local bp = self.Blueprint
        if not bp.Audio[sound] then return end
        if not self.AmbientSounds then
            self.AmbientSounds = {}
        end
        if not self.AmbientSounds[sound] then
            local sndEnt = Entity {}
            self.AmbientSounds[sound] = sndEnt
            self.unit.Trash:Add(sndEnt)
            sndEnt:AttachTo(self.unit,-1)
        end
        self.AmbientSounds[sound]:SetAmbientSound(bp.Audio[sound], nil)
    end,

    StopWeaponAmbientSound = function(self, sound)
        if not self.AmbientSounds then return end
        if not self.AmbientSounds[sound] then return end
        local bp = self.Blueprint
        if not bp.Audio[sound] then return end
        self.AmbientSounds[sound]:Destroy()
        self.AmbientSounds[sound] = nil
    end,

    OnMotionHorzEventChange = function(self, new, old)
    end,

    GetDamageTableInternal = function(self)
        local weaponBlueprint = self.Blueprint
        local damageTable = {}
        damageTable.InitialDamageAmount = weaponBlueprint.InitialDamage or 0
        damageTable.DamageRadius = weaponBlueprint.DamageRadius + (self.DamageRadiusMod or 0)
        damageTable.DamageAmount = weaponBlueprint.Damage + (self.DamageMod or 0)
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

        return damageTable
    end,

    damageTableCache = false,
    GetDamageTable = function(self)
        if not self.damageTableCache then self.damageTableCache = self:GetDamageTableInternal() end
        return self.damageTableCache
    end,

    CreateProjectileForWeapon = function(self, bone)
        local proj = self:CreateProjectile(bone)
        local damageTable = self:GetDamageTable()

        if proj and not proj:BeenDestroyed() then
            proj:PassDamageData(damageTable)
            local bp = self.Blueprint

            if bp.NukeOuterRingDamage and bp.NukeOuterRingRadius and bp.NukeOuterRingTicks and bp.NukeOuterRingTotalTime and
                bp.NukeInnerRingDamage and bp.NukeInnerRingRadius and bp.NukeInnerRingTicks and bp.NukeInnerRingTotalTime then
                proj.InnerRing = NukeDamage()
                proj.InnerRing:OnCreate(bp.NukeInnerRingDamage, bp.NukeInnerRingRadius, bp.NukeInnerRingTicks, bp.NukeInnerRingTotalTime)
                proj.OuterRing = NukeDamage()
                proj.OuterRing:OnCreate(bp.NukeOuterRingDamage, bp.NukeOuterRingRadius, bp.NukeOuterRingTicks, bp.NukeOuterRingTotalTime)

                -- Need to store these three for later, in case the missile lands after the launcher dies
                proj.Launcher = self.unit
                proj.Army = self.unit.Army
                proj.Brain = self.unit:GetAIBrain()
            end
        end
        return proj
    end,

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

    OnDestroy = function(self)
    end,

    SetWeaponPriorities = function(self, priTable)

        if not cachedPriorities then
            cachedPriorities = ParsePriorities()
        end

        if not priTable then
            local bp = self.Blueprint.TargetPriorities
            if bp then
                local priorityTable = {}
                for k, v in bp do
                    if cachedPriorities[v] then
                        table.insert(priorityTable, cachedPriorities[v])
                    else
                        if string.find(v, '%(') then
                            cachedPriorities[v] = ParseEntityCategoryProperly(v)
                            table.insert(priorityTable, cachedPriorities[v])
                        else
                            cachedPriorities[v] = ParseEntityCategory(v)
                            table.insert(priorityTable, cachedPriorities[v])
                        end
                    end
                end
                self:SetTargetingPriorities(priorityTable)
            end
        else
            if type(priTable[1]) == 'string' then
                local priorityTable = {}
                for k, v in priTable do
                    table.insert(priorityTable, ParseEntityCategory(v))
                end
                self:SetTargetingPriorities(priorityTable)
            else
                self:SetTargetingPriorities(priTable)
            end
        end
    end,

    WeaponUsesEnergy = function(self)
        local bp = self.Blueprint
        if bp.EnergyRequired and bp.EnergyRequired > 0 then
            return true
        end
        return false
    end,

    ForkThread = function(self, fn, ...)
        if fn then
            local thread = ForkThread(fn, self, unpack(arg))
            self.unit.Trash:Add(thread)
            return thread
        else
            return nil
        end
    end,

    OnVeteranLevel = function(self, old, new)
        local bp = self.Blueprint.Buffs
        if not bp then return end

        local lvlkey = 'VeteranLevel' .. new
        for k, v in bp do
            if v.Add[lvlkey] == true then
                self:AddBuff(v)
            end
        end
    end,

    AddBuff = function(self, buffTbl)
        self.unit:AddWeaponBuff(buffTbl, self)
    end,

    AddDamageMod = function(self, dmgMod)
        self.DamageMod = self.DamageMod + dmgMod
        self.damageTableCache = false
    end,

    AddDamageRadiusMod = function(self, dmgRadMod)
        self.DamageRadiusMod = self.DamageRadiusMod + (dmgRadMod or 0)
        self.damageTableCache = false
    end,

    DoOnFireBuffs = function(self)
        local data = self.Blueprint
        if data.Buffs then
            for k, v in data.Buffs do
                if v.Add.OnFire == true then
                    self.unit:AddBuff(v)
                end
            end
        end
    end,

    DisableBuff = function(self, buffname)
        if buffname then
            self.DisabledBuffs[buffname] = true
        else
            -- Error
            error('ERROR: DisableBuff in weapon.lua does not have a buffname')
        end
        self.damageTableCache = false
    end,

    ReEnableBuff = function(self, buffname)
        if buffname then
            self.DisabledBuffs[buffname] = nil
        else
            -- Error
            error('ERROR: ReEnableBuff in weapon.lua does not have a buffname')
        end
        self.damageTableCache = false
    end,

    -- Method to mark weapon when parent unit gets loaded on to a transport unit
    SetOnTransport = function(self, transportstate)
        self.onTransport = transportstate
        if not transportstate then
            -- send a message to tell the weapon that the unit just got dropped and needs to restart aim
            self:OnLostTarget()
        end
        -- Disable weapon if on transport and not allowed to fire from it
        if not self.unit.Blueprint.Transport.CanFireFromTransport then
            if transportstate then
                self.WeaponDisabledOnTransport = true
                self:SetWeaponEnabled(false)
            else
                self:SetWeaponEnabled(true)
                self.WeaponDisabledOnTransport = false
            end
        end
    end,

    -- Method to retreive onTransport information. True if the parent unit has been loaded on to a transport unit
    GetOnTransport = function(self)
        return self.onTransport
    end,

    -- This is the function to set a weapon enabled.
    -- If the weapon is enhabled by an enhancement, this will check to see if the unit has the enhancement before
    -- allowing it to try to be enabled or disabled.
    SetWeaponEnabled = function(self, enable)
        if not enable then
            self:SetEnabled(enable)
            return
        end
        local bp = self.Blueprint.EnabledByEnhancement
        if bp then
            for k, v in SimUnitEnhancements[self.unit.EntityId] or {} do
                if v == bp then
                    self:SetEnabled(enable)
                    return
                end
            end
            -- Enhancement needed but doesn't have it, don't allow weapon to be enabled.
            return
        end
        self:SetEnabled(enable)
    end,
}
