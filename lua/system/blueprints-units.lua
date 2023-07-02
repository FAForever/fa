-- upvalue for performance
local TableFind = table.find
local TableGetn = table.getn

local MathMax = math.max
local MathFloor = math.floor

local StringFind = string.find

local BlueprintNameToIntel = {
    Cloak = 'Cloak',
    CloakField = 'CloakField',
    CloakFieldRadius = 'CloakField',
    JammerBlips = 'Jammer',
    OmniRadius = 'Omni',

    RadarRadius = 'Radar',
    RadarStealth = 'RadarStealth',
    RadarStealthField = 'RadarStealthField',
    RadarStealthFieldRadius = 'RadarStealthField',

    Sonar = 'Sonar',
    SonarRadius = 'Sonar',
    SonarStealth = 'SonarStealth',
    SonarStealthFieldRadius = 'SonarStealthField',
}

local LabelToVeterancyUse = {
    ['DeathWeapon'] = true,
    ['DeathImpact'] = true,
}

local TechToVetMultipliers = {
    TECH1 = 2,
    TECH2 = 1.5,
    TECH3 = 1.25,
    SUBCOMMANDER = 2,
    EXPERIMENTAL = 2,
    COMMAND = 2,
}

---@param weapon WeaponBlueprint
local function CalculatedDamage(weapon)
    local ProjectileCount = MathMax(1, TableGetn(weapon.RackBones[1].MuzzleBones or {'nehh'}), weapon.MuzzleSalvoSize or 1)
    if weapon.RackFireTogether then
        ProjectileCount = ProjectileCount * MathMax(1, TableGetn(weapon.RackBones or {'nehh'}))
    end
    return ((weapon.Damage or 0) + (weapon.NukeInnerRingDamage or 0)) * ProjectileCount * (weapon.DoTPulses or 1)
end

---@param weapon WeaponBlueprint
---@return number
local function CalculatedDPS(weapon)
    -- Base values
    local ProjectileCount
    if weapon.MuzzleSalvoDelay == 0 then
        ProjectileCount = MathMax(1, TableGetn(weapon.RackBones[1].MuzzleBones or {'nehh'}))
    else
        ProjectileCount = (weapon.MuzzleSalvoSize or 1)
    end
    if weapon.RackFireTogether then
        ProjectileCount = ProjectileCount * MathMax(1, TableGetn(weapon.RackBones or {'nehh'}))
    end
    -- Game logic rounds the timings to the nearest tick --  MathMax(0.1, 1 / (weapon.RateOfFire or 1)) for unrounded values
    local DamageInterval = MathFloor((MathMax(0.1, 1 / (weapon.RateOfFire or 1)) * 10) + 0.5) / 10 + ProjectileCount * (MathMax(weapon.MuzzleSalvoDelay or 0, weapon.MuzzleChargeDelay or 0) * (weapon.MuzzleSalvoSize or 1))
    local Damage = ((weapon.Damage or 0) + (weapon.NukeInnerRingDamage or 0)) * ProjectileCount * (weapon.DoTPulses or 1)

    -- Beam calculations.
    if weapon.BeamLifetime and weapon.BeamLifetime == 0 then
        -- Unending beam. Interval is based on collision delay only.
        DamageInterval = 0.1 + (weapon.BeamCollisionDelay or 0)
    elseif weapon.BeamLifetime and weapon.BeamLifetime > 0 then
        -- Uncontinuous beam. Interval from start to next start.
        DamageInterval = DamageInterval + weapon.BeamLifetime
        -- Damage is calculated as a single glob, beam weapons are typically underappreciated
        Damage = Damage * (weapon.BeamLifetime / (0.1 + (weapon.BeamCollisionDelay or 0)))
    end

    return Damage / DamageInterval or 0
end

--- Post process a unit
---@param unit UnitBlueprint
local function PostProcessUnit(unit)
    if table.find(unit.Categories, "SUBCOMMANDER") then
        table.insert(unit.Categories, "SACU_BEHAVIOR")
    end

    -- create hash tables for quick lookup
    unit.CategoriesCount = 0
    unit.CategoriesHash = {}
    if unit.Categories then
        unit.CategoriesCount = table.getn(unit.Categories)
        for k, category in unit.Categories do
            unit.CategoriesHash[category] = true
        end
    end

    unit.CategoriesHash[unit.BlueprintId] = true

    -- create hash tables for quick lookup
    unit.DoNotCollideListCount = 0
    unit.DoNotCollideListHash = {}
    if unit.DoNotCollideList then
        unit.DoNotCollideListCount = table.getn(unit.DoNotCollideList)
        for _, category in unit.DoNotCollideList do
            unit.DoNotCollideListHash[category] = true
        end
    end

    -- sanitize guard scan radius

    -- The guard scan radius is used when:
    -- - A unit attack moves, it determines how far the unit remains from its target
    -- - A unit patrols, it determines when the unit decides to engage

    -- All of the decisions below are made based on when a unit attack moves, as that is
    -- the default meta to use in competitive play. This is by all means not perfect,
    -- but it is the best we can do when we need to consider the performance of it all

    local isEngineer = unit.CategoriesHash['ENGINEER']
    local isStructure = unit.CategoriesHash['STRUCTURE']
    local isDummy = unit.CategoriesHash['DUMMYUNIT']
    local isLand = unit.CategoriesHash['LAND']
    local isAir = unit.CategoriesHash['AIR']
    local isBomber = unit.CategoriesHash['BOMBER']
    local isGunship = unit.CategoriesHash['GUNSHIP']
    local isTransport = unit.CategoriesHash['TRANSPORTATION']

    local isTech1 = unit.CategoriesHash['TECH1']
    local isTech2 = unit.CategoriesHash['TECH2']
    local isTech3 = unit.CategoriesHash['TECH3']
    local isExperimental = unit.CategoriesHash['EXPERIMENTAL']

    -- do not touch guard scan radius values of engineer-like units, as it is the reason we have
    -- the factory-reclaim-bug that we're keen in keeping that at this point
    if not isEngineer then
        -- guarantee that the table exists
        unit.AI = unit.AI or {}

        -- if it is set then we use that - allows us to make adjustments as we see fit
        if unit.AI.GuardScanRadius == nil then
            -- structures don't need this value set
            if isStructure or isDummy then
                unit.AI.GuardScanRadius = 0
            elseif isEngineer then -- engineers need their factory reclaim bug
                unit.AI.GuardScanRadius = 26 -- allows for factory reclaim bug
            else -- mobile units do need this value set
                -- check if we have a primary weapon that is actually a weapon
                local primaryWeapon = unit.Weapon[1]
                if primaryWeapon and not (
                    primaryWeapon.DummyWeapon or
                        primaryWeapon.WeaponCategory == 'Death' or
                        primaryWeapon.Label == 'DeathImpact' or
                        primaryWeapon.DisplayName == 'Air Crash'
                    ) then
                    local isAntiAir = primaryWeapon.RangeCategory == 'UWRC_AntiAir'
                    local maxRadius = primaryWeapon.MaxRadius or 0

                    -- land to air units shouldn't get triggered too fast
                    if isLand and isAntiAir then
                        unit.AI.GuardScanRadius = 0.80 * maxRadius
                    else -- all other units will have the default value of 10% on top of their maximum attack radius
                        unit.AI.GuardScanRadius = 1.10 * maxRadius
                    end
                else -- units with no weaponry don't need this value set
                    unit.AI.GuardScanRadius = 0
                end

                -- cap it, some units have extreme values based on their attack radius
                if isTech1 and unit.AI.GuardScanRadius > 40 then
                    unit.AI.GuardScanRadius = 40
                elseif isTech2 and unit.AI.GuardScanRadius > 80 then
                    unit.AI.GuardScanRadius = 80
                elseif isTech3 and unit.AI.GuardScanRadius > 120 then
                    unit.AI.GuardScanRadius = 120
                elseif isExperimental and unit.AI.GuardScanRadius > 160 then
                    unit.AI.GuardScanRadius = 160
                end

                -- sanitize it
                unit.AI.GuardScanRadius = math.floor(unit.AI.GuardScanRadius)
            end
        end
    end

    -- sanitize air unit footprints

    -- value used by formations to determine the distance between other air units. Note
    -- that the value must be of type unsigned integer!
    if isAir and not (
        isExperimental or
            isStructure or
            (isTransport and not isGunship)-- uef tech 2 gunship is also a transport :)
        ) then
        unit.Footprint = unit.Footprint or {}

        -- determine footprint size based on type
        if isBomber then
            unit.Footprint.SizeX = 4
            unit.Footprint.SizeZ = 4
        elseif isGunship then
            unit.Footprint.SizeX = 3
            unit.Footprint.SizeZ = 3
        else
            unit.Footprint.SizeX = 2
            unit.Footprint.SizeZ = 2
        end

        -- limit their footprint size based on tech
        if isTech1 then
            unit.Footprint.SizeX = math.min(unit.Footprint.SizeX, 2)
            unit.Footprint.SizeZ = math.min(unit.Footprint.SizeZ, 2)
        elseif isTech2 then
            unit.Footprint.SizeX = math.min(unit.Footprint.SizeX, 3)
            unit.Footprint.SizeZ = math.min(unit.Footprint.SizeZ, 3)
        elseif isTech3 then
            unit.Footprint.SizeX = math.min(unit.Footprint.SizeX, 4)
            unit.Footprint.SizeZ = math.min(unit.Footprint.SizeZ, 4)
        end
    end

    -- Allow naval factories to correct their roll off points, as they are critical for ships not being stuck
    if unit.CategoriesHash['FACTORY'] and unit.CategoriesHash['NAVAL'] then
        unit.Physics.CorrectNavalRollOffPoints = true
    end

    -- Check size of collision boxes
    if not isDummy then
        -- find maximum speed
        local speed = unit.Physics.MaxSpeed
        if unit.Air and unit.Air.MaxAirspeed then
            speed = unit.Air.MaxAirspeed
        end

        -- determine if collision box is fine
        if speed then
            if unit.SizeSphere then
                if unit.SizeSphere < 0.1 * speed then
                    WARN(string.format("Overriding the size of the collision sphere of unit ( %s ), it should be atleast 10 percent ( %s ) of the maximum speed ( %s ) to guarantee proper functioning beam weapons"
                        , tostring(unit.BlueprintId), tostring(0.1 * speed), tostring(speed)))
                    unit.SizeSphere = 0.1 * speed
                end
            else
                if unit.SizeX < 0.1 * speed then
                    WARN(string.format("Overriding the x axis of collision box of unit ( %s ), it should be atleast 10 percent ( %s ) of the maximum speed ( %s ) to guarantee proper functioning beam weapons"
                        , tostring(unit.BlueprintId), tostring(0.1 * speed), tostring(speed)))
                    unit.SizeX = 0.1 * speed
                end

                if unit.SizeZ < 0.1 * speed then
                    WARN(string.format("Overriding the z axis of collision box of unit ( %s ), it should be atleast 10 percent ( %s ) of the maximum speed ( %s ) to guarantee proper functioning beam weapons"
                        , tostring(unit.BlueprintId), tostring(0.1 * speed), tostring(speed)))
                    unit.SizeZ = 0.1 * speed
                end
            end
        end
    end

    -- Fix being able to check for command caps
    local unitGeneral = unit.General
    if unitGeneral then
        local commandCaps = unitGeneral.CommandCaps
        if commandCaps then
            unitGeneral.CommandCapsHash = table.deepcopy(commandCaps)
        else
            unitGeneral.CommandCapsHash = {}
        end
    else
        unit.General = { CommandCapsHash = {} }
    end

    -- Pre-compute various elements
    unit.SizeVolume = (unit.SizeX or 1) * (unit.SizeY or 1) * (unit.SizeZ or 1)
    unit.SizeDamageEffects = 1
    unit.SizeDamageEffectsScale = 1
    if unit.SizeVolume > 10 then
        unit.SizeDamageEffects = 2
        unit.SizeDamageEffectsScale = 1.5
        if unit.SizeVolume > 20 then
            unit.SizeDamageEffects = 3
            unit.SizeDamageEffectsScale = 2.0
        end
    end

    unit.Footprint = unit.Footprint or {}
    unit.Footprint.SizeMax = math.max(unit.Footprint.SizeX or 1, unit.Footprint.SizeZ or 1)

    -- Pre-compute intel state

    -- gather data
    local economyBlueprint = unit.Economy
    local intelBlueprint = unit.Intel
    local enhancementBlueprints = unit.Enhancements
    if intelBlueprint or enhancementBlueprints then

        ---@type UnitIntelStatus
        local status = {}

        -- life is good, intel is funded by the government
        local allIntelIsFree = false
        if intelBlueprint.FreeIntel or (
            not enhancementBlueprints and
                (
                (not economyBlueprint) or
                    (not economyBlueprint.MaintenanceConsumptionPerSecondEnergy) or
                    economyBlueprint.MaintenanceConsumptionPerSecondEnergy == 0
                )
            ) then
            allIntelIsFree = true
            status.AllIntelMaintenanceFree = {}
        end

        -- special case: unit has intel that is considered free
        if intelBlueprint.ActiveIntel then
            status.AllIntelMaintenanceFree = status.AllIntelMaintenanceFree or {}
            for intel, _ in intelBlueprint.ActiveIntel do
                status.AllIntelMaintenanceFree[intel] = true
            end
        end

        -- special case: unit has enhancements and therefore can have any intel type
        if enhancementBlueprints then
            status.AllIntelFromEnhancements = {}
        end

        -- usual case: find all remaining intel
        status.AllIntel = {}
        for name, value in intelBlueprint do

            if value == true or value > 0 then
                local intel = BlueprintNameToIntel[name]
                if intel then
                    if allIntelIsFree then
                        status.AllIntelMaintenanceFree[intel] = true
                    else
                        status.AllIntel[intel] = true
                    end
                end
            end
        end

        -- check if we have any intel
        if not (table.empty(status.AllIntel) and table.empty(status.AllIntelMaintenanceFree) and not enhancementBlueprints) then
            -- cache it
            status.AllIntelDisabledByEvent = {}
            status.AllIntelRecharging = {}
            unit.Intel = unit.Intel or {}
            unit.Intel.State = status
        end
    end

    -- Pre-compute use of veterancy

    if (not unit.Weapon[1]) or unit.General.ExcludeFromVeterancy then
        unit.VetEnabled = false
    else
        for index, wep in unit.Weapon do
            if not LabelToVeterancyUse[wep.Label] then
                unit.VetEnabled = true
            end
        end
    end

    unit.VetThresholds = {
        0, 0, 0, 0, 0
    }

    if unit.VeteranMass then
        unit.VetThresholds[1] = unit.VeteranMass[1]
        unit.VetThresholds[2] = unit.VeteranMass[2] + unit.VetThresholds[1]
        unit.VetThresholds[3] = unit.VeteranMass[3] + unit.VetThresholds[2]
        unit.VetThresholds[4] = unit.VeteranMass[4] + unit.VetThresholds[3]
        unit.VetThresholds[5] = unit.VeteranMass[5] + unit.VetThresholds[4]
    else
        local multiplier = unit.VeteranMassMult or TechToVetMultipliers[unit.TechCategory] or 2
        unit.VetThresholds[1] = 1 * multiplier * (unit.Economy.BuildCostMass or 1)
        unit.VetThresholds[2] = 2 * multiplier * (unit.Economy.BuildCostMass or 1)
        unit.VetThresholds[3] = 3 * multiplier * (unit.Economy.BuildCostMass or 1)
        unit.VetThresholds[4] = 4 * multiplier * (unit.Economy.BuildCostMass or 1)
        unit.VetThresholds[5] = 5 * multiplier * (unit.Economy.BuildCostMass or 1)
    end

    -- Pre-compute weak secondary weapons

    local weapons = unit.Weapon
    if weapons then
        LOG(unit.BlueprintId .. " - " .. unit.Description)

        -- determine total dps per category
        local damagePerRangeCategory = {
            UWRC_DirectFire = 0,
            UWRC_IndirectFire = 0,
            UWRC_AntiAir = 0,
            UWRC_AntiNavy = 0,
            UWRC_Countermeasure = 0,
        }

        for k, weapon in weapons do
            local dps = CalculatedDPS(weapon)
            if weapon.RangeCategory then
                damagePerRangeCategory[weapon.RangeCategory] = damagePerRangeCategory[weapon.RangeCategory] + dps
            else
                if weapon.WeaponCategory != 'Death' then
                    -- WARN("Invalid weapon on " .. unit.BlueprintId)
                end
            end
        end

        local array = {
            {
                RangeCategory = "UWRC_DirectFire",
                Damage = damagePerRangeCategory["UWRC_DirectFire"]
            },
            {
                RangeCategory = "UWRC_IndirectFire",
                Damage = damagePerRangeCategory["UWRC_IndirectFire"]
            },
            {
                RangeCategory = "UWRC_AntiAir",
                Damage = damagePerRangeCategory["UWRC_AntiAir"]
            }
            ,
            {
                RangeCategory = "UWRC_AntiNavy",
                Damage = damagePerRangeCategory["UWRC_AntiNavy"]
            }
            ,
            {
                RangeCategory = "UWRC_Countermeasure",
                Damage = damagePerRangeCategory["UWRC_Countermeasure"]
            }
        }

        table.sort(array, function(e1, e2) return e1.Damage > e2.Damage end)

        local factor = array[1].Damage

        for category, damage in damagePerRangeCategory do
            if damage > 0 and damage < 0.2 * factor then
                LOG(" - Weak in: " .. category)
            end
        end
    end
end

--- Post-processes all units
---@param units UnitBlueprint[]
function PostProcessUnits(units)
    for _, unit in units do
        PostProcessUnit(unit)
    end
end
