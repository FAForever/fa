---@declare-global
--------------------------------------------------------------------------------
-- Supreme Commander mod threat calculator
-- Copyright 2018-2022 Sean 'Balthazar' Wheeldon                       Lua 5.4.2
--------------------------------------------------------------------------------
-- Note this is largely unchanged from https://github.com/The-Balthazar/BrewLAN/blob/806a689792fa14e071ed679ee37b3e34d55ecbbf/mods/BrewLAN_Plenae/Logger/hook/lua/system/Blueprints.lua--L345

local ReportIssues = false

-- upvalue for performance
local TableFind = table.find
local TableGetn = table.getn

local MathMax = math.max
local MathFloor = math.floor

local StringFind = string.find

local TrueCats = {
    'FACTORY',
    'ENGINEER',
    'FIELDENGINEER',
    'CONSTRUCTION',
    'ENGINEERSTATION',
}

---@param bp UnitBlueprint
---@return boolean
local function TakeIntoAccountBuildrate(bp)
    if not bp.Economy.BuildRate or bp.CategoriesHash['WALL'] then
        return false
    end

    for _, v in TrueCats do
        if bp.CategoriesHash[v] then
            return true
        end
    end

    return not TableFind(bp.Economy.BuildableCategory or {'nahh'}, bp.General.UpgradesTo or 'nope') and not bp.Economy.BuildableCategory[2]
end

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

---@param unitBPs UnitBlueprint[]
function SetUnitThreatValues(unitBPs)
    -- localize for performance
    local TableFind = TableFind
    local TableGetn = TableGetn

    local MathMax = MathMax
    local MathFloor = MathFloor

    local StringFind = StringFind

    -- re-use for performance
    local cache = {}

    for id, bp in unitBPs do
        -- used for debugging
        if ReportIssues then 
            LOG(tostring(bp.BlueprintId) .. ": " .. tostring(bp.Description))
        end

        -- not all units have this table set, an example is a Cybran build bot.
        if not bp.Defense then
            if ReportIssues then
                LOG(tostring(bp.BlueprintId) .. ": has no defense table in blueprint, skipped")
            end
            continue
        end

        -- not all units need dynamic threat calculations, such as the commanders
        if bp.Defense.SkipDynamicThreatCalculations then
            continue
        end

        --  default to 0
        cache.AirThreatLevel = 0
        cache.EconomyThreatLevel = 0
        cache.SubThreatLevel = 0
        cache.SurfaceThreatLevel = 0
        -- These are temporary to be merged into the others after calculations
        cache.HealthThreat = 0
        cache.PersonalShieldThreat = 0
        cache.UnknownWeaponThreat = 0

        -- define base health and shield values
        if bp.Defense.MaxHealth then
            cache.HealthThreat = bp.Defense.MaxHealth * 0.01
        end

        local mobileUnit = bp.CategoriesHash.MOBILE

        if bp.Defense.Shield then
            local shield = bp.Defense.Shield                                               -- ShieldProjectionRadius entirely only for the Pillar of Prominence
            local shieldarea = (shield.ShieldProjectionRadius or shield.ShieldSize or 0) * (shield.ShieldProjectionRadius or shield.ShieldSize or 0) * math.pi
            local skirtarea = (bp.Physics.SkirtSizeX or 3) * (bp.Physics.SkirtSizeY or 3)                                                              --  added so that transport shields dont count as personal shields.
            if (bp.Display.Abilities and TableFind(bp.Display.Abilities, '<LOC ability_personalshield>Personal Shield') or shieldarea < skirtarea) and not TableFind(bp.Categories, 'TRANSPORT') then
                cache.PersonalShieldThreat = (shield.ShieldMaxHealth or 0) * 0.01
            else
                cache.EconomyThreatLevel = cache.EconomyThreatLevel + ((shieldarea - skirtarea) * (shield.ShieldMaxHealth or 0) * (shield.ShieldRegenRate or 1)) / 250000000
            end
        end

        -- Define eco production values
        if bp.Economy.ProductionPerSecondMass then
            -- Mass prod + 5% of health
            cache.EconomyThreatLevel = cache.EconomyThreatLevel + bp.Economy.ProductionPerSecondMass * 10 + (cache.HealthThreat + cache.PersonalShieldThreat) * 5
        end

        if bp.Economy.ProductionPerSecondEnergy then
            -- Energy prod + 1% of health
            cache.EconomyThreatLevel = cache.EconomyThreatLevel + bp.Economy.ProductionPerSecondEnergy * 0.1 + cache.HealthThreat + cache.PersonalShieldThreat
        end

        -- remove health and shield because they're used
        if bp.Economy.ProductionPerSecondMass or bp.Economy.ProductionPerSecondEnergy then
            cache.HealthThreat = 0
            cache.PersonalShieldThreat = 0
        end

        -- calculate for build rates, ignore things that only upgrade
        if TakeIntoAccountBuildrate(bp) then
            -- non-mass producing energy production units that can build get off easy on the health calculation. Engineering reactor, we're looking at you
            if bp.Physics.MotionType == 'RULEUMT_None' then
                cache.EconomyThreatLevel = cache.EconomyThreatLevel + bp.Economy.BuildRate / (bp.Economy.BuilderDiscountMult or 1) * 2 + (cache.HealthThreat + cache.PersonalShieldThreat) * 2
            else
                cache.EconomyThreatLevel = cache.EconomyThreatLevel + bp.Economy.BuildRate + (cache.HealthThreat + cache.PersonalShieldThreat) * 3
            end
            -- 0 off the personal health values if we alreaady used them
            cache.HealthThreat = 0
            cache.PersonalShieldThreat = 0
        end

        -- calculate for storage values
        if bp.Economy.StorageMass then
            cache.EconomyThreatLevel = cache.EconomyThreatLevel + bp.Economy.StorageMass * 0.001 + cache.HealthThreat + cache.PersonalShieldThreat
        end
        if bp.Economy.StorageEnergy then
            cache.EconomyThreatLevel = cache.EconomyThreatLevel + bp.Economy.StorageEnergy * 0.001 + cache.HealthThreat + cache.PersonalShieldThreat
        end

        -- remove health and shield because they're used
        if bp.Economy.StorageMass or bp.Economy.StorageEnergy then
            cache.HealthThreat = 0
            cache.PersonalShieldThreat = 0
        end

        -- no one really cares about air staging, well maybe a little bit.
        if bp.Transport.DockingSlots then
            cache.EconomyThreatLevel = cache.EconomyThreatLevel + bp.Transport.DockingSlots
        end

        if bp.Weapon then
            for _, weapon in bp.Weapon do
                -- skip weapons part of an enhancement
                if weapon.EnabledByEnhancement then
                    continue
                end

                -- dps of weapon
                local dps = CalculatedDPS(weapon)

                -- multipliers to scale damage a bit
                local econMult = 1
                local surfaceMult = 0.1

                -- determines if we apply dps to economic or anti surface threat
                local weaponIsEconomicThreat = (weapon.DamageType == 'Nuke' or weapon.ArtilleryShieldBlocks) and (not mobileUnit or weapon.MinRadius > 80)

                -- Anti air
                if weapon.RangeCategory == 'UWRC_AntiAir' or weapon.TargetRestrictOnlyAllow == 'AIR' or StringFind(weapon.WeaponCategory or 'nope', 'Anti Air') then
                    cache.AirThreatLevel = cache.AirThreatLevel + dps / 10
                -- Anti submarine
                elseif weapon.RangeCategory == 'UWRC_AntiNavy' or StringFind(weapon.WeaponCategory or 'nope', 'Anti Navy') then
                    if StringFind(weapon.WeaponCategory or 'nope', 'Bomb') or StringFind(weapon.Label or 'nope', 'Bomb') or weapon.NeedToComputeBombDrop or bp.Air.Winged then
                        cache.SubThreatLevel = cache.SubThreatLevel + CalculatedDamage(weapon) / 100
                    else
                        cache.SubThreatLevel = cache.SubThreatLevel + dps / 10
                    end
                -- Direct fire or artillery
                elseif weapon.RangeCategory == 'UWRC_DirectFire' or StringFind(weapon.WeaponCategory or 'nope', 'Direct Fire')
                        or weapon.RangeCategory == 'UWRC_IndirectFire' or StringFind(weapon.WeaponCategory or 'nope', 'Artillery') then
                    if weaponIsEconomicThreat then
                        cache.EconomyThreatLevel = cache.EconomyThreatLevel + dps * econMult
                    else
                        cache.SurfaceThreatLevel = cache.SurfaceThreatLevel + dps * surfaceMult
                    end
                -- Bombers
                elseif StringFind(weapon.WeaponCategory or 'nope', 'Bomb') or StringFind(weapon.Label or 'nope', 'Bomb') or weapon.NeedToComputeBombDrop then
                    cache.SurfaceThreatLevel = cache.SurfaceThreatLevel + CalculatedDamage(weapon) / 100
                -- Death weapon
                elseif StringFind(weapon.WeaponCategory or 'nope', 'Death') then
                    cache.EconomyThreatLevel = MathFloor(cache.EconomyThreatLevel + dps / 200)
                else -- Unknown weapon threat (mods)
                    cache.UnknownWeaponThreat = cache.UnknownWeaponThreat + dps
                    if ReportIssues then
                        LOG(" * WARNING: Unknown weapon type on: " .. id .. " with the weapon label: " .. (weapon.Label or "nil") )
                    end
                    bp.Warnings = (bp.Warnings or 0) + 1
                end
            end
        end

        -- See if it has real threat yet
        local checkthreat = 0
        for _, v in { 'AirThreatLevel', 'EconomyThreatLevel', 'SubThreatLevel', 'SurfaceThreatLevel'} do
            checkthreat = checkthreat + cache[v]
        end

        -- Last ditch attempt to give it some threat
        if checkthreat < 1 then
            if cache.UnknownWeaponThreat > 0 then
                -- If we have no idea what it is still, it has threat equal to its unkown weapon DPS.
                cache.EconomyThreatLevel = cache.UnknownWeaponThreat
                cache.UnknownWeaponThreat = 0
            elseif bp.Economy.MaintenanceConsumptionPerSecondEnergy > 0 then
                -- If we STILL have no idea what it's threat is, and it uses power, its obviously doing something fucky, so we'll use that.
                cache.EconomyThreatLevel = bp.Economy.MaintenanceConsumptionPerSecondEnergy * 0.0175
            end
        end

        -- Get rid of unused threat values
        for _, v in {'HealthThreat','PersonalShieldThreat', 'UnknownWeaponThreat'} do
            if cache[v] and cache[v] ~= 0 then
                if ReportIssues then
                    LOG("Unused " .. v .. " " .. cache[v])
                end
                cache[v] = nil
            end
        end

        -- Sanitise the table
        for i, v in cache do
            -- Round appropriately
            if v < 1 then
                cache[i] = 0
            else
                cache[i] = MathFloor(v + 0.5)
            end
        end

        -- transfer information to blueprint table
        for k, v in cache do
            bp.Defense[k] = v
        end
    end
end
