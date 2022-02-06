
-- upvalue for performance
local TableFind = table.find
local TableGetn = table.getn

local MathMax = math.max
local MathFloor = math.floor

local StringFind = string.find

local function TakeIntoAccountBuildrate(bp)
    if not bp.Economy.BuildRate then
        return false
    end
    if TableFind(bp.Categories, 'HEAVYWALL') then
        return false
    end
    local TrueCats = {
        'FACTORY',
        'ENGINEER',
        'FIELDENGINEER',
        'CONSTRUCTION',
        'ENGINEERSTATION',
    }
    for i, v in TrueCats do
        if TableFind(bp.Categories, v) then
            return true
        end
    end

    return not TableFind(bp.Economy.BuildableCategory or {'nahh'}, bp.General.UpgradesTo or 'nope') and not bp.Economy.BuildableCategory[2]
end

local function CalculatedDamage(weapon)
    local ProjectileCount = MathMax(1, TableGetn(weapon.RackBones[1].MuzzleBones or {'nehh'} ), weapon.MuzzleSalvoSize or 1 )
    if weapon.RackFireTogether then
        ProjectileCount = ProjectileCount * MathMax(1, TableGetn(weapon.RackBones or {'nehh'} ) )
    end
    return ((weapon.Damage or 0) + (weapon.NukeInnerRingDamage or 0)) * ProjectileCount * (weapon.DoTPulses or 1)
end

local function CalculatedDPS(weapon)
    -- Base values
    local ProjectileCount
    if weapon.MuzzleSalvoDelay == 0 then
        ProjectileCount = MathMax(1, TableGetn(weapon.RackBones[1].MuzzleBones or {'nehh'} ) )
    else
        ProjectileCount = (weapon.MuzzleSalvoSize or 1)
    end
    if weapon.RackFireTogether then
        ProjectileCount = ProjectileCount * MathMax(1, TableGetn(weapon.RackBones or {'nehh'} ) )
    end
    -- Game logic rounds the timings to the nearest tick --  MathMax(0.1, 1 / (weapon.RateOfFire or 1)) for unrounded values
    local DamageInterval = MathFloor((MathMax(0.1, 1 / (weapon.RateOfFire or 1)) * 10) + 0.5) / 10 + ProjectileCount * (MathMax(weapon.MuzzleSalvoDelay or 0, weapon.MuzzleChargeDelay or 0) * (weapon.MuzzleSalvoSize or 1) )
    local Damage = ((weapon.Damage or 0) + (weapon.NukeInnerRingDamage or 0)) * ProjectileCount * (weapon.DoTPulses or 1)

    -- Beam calculations.
    if weapon.BeamLifetime and weapon.BeamLifetime == 0 then
        -- Unending beam. Interval is based on collision delay only.
        DamageInterval = 0.1 + (weapon.BeamCollisionDelay or 0)
    elseif weapon.BeamLifetime and weapon.BeamLifetime > 0 then
        -- Uncontinuous beam. Interval from start to next start.
        DamageInterval = DamageInterval + weapon.BeamLifetime
        -- Damage is calculated as a single glob
        Damage = Damage * (weapon.BeamLifetime / (0.1 + (weapon.BeamCollisionDelay or 0)))
    end

    return Damage * (1 / DamageInterval) or 0
end


function CheckAllUnitThreatValues(unitBPs)
    
    for id, bp in unitBPs do
        --  default to 0
        bp.Defense.AirThreatLevel = 0
        bp.Defense.EconomyThreatLevel = 0
        bp.Defense.SubThreatLevel = 0
        bp.Defense.SurfaceThreatLevel = 0
        -- These are temporary to be merged into the others after calculations
        bp.Defense.HealthThreat = 0
        bp.Defense.PersonalShieldThreat = 0
        bp.Defense.UnknownWeaponThreat = 0

        -- define base health and shield values
        if bp.Defense.MaxHealth then
            bp.Defense.HealthThreat = bp.Defense.MaxHealth * 0.01
        end
        if bp.Defense.Shield then
            local shield = bp.Defense.Shield                                               -- ShieldProjectionRadius entirely only for the Pillar of Prominence
            local shieldarea = (shield.ShieldProjectionRadius or shield.ShieldSize or 0) * (shield.ShieldProjectionRadius or shield.ShieldSize or 0) * math.pi
            local skirtarea = (bp.Physics.SkirtSizeX or 3) * (bp.Physics.SkirtSizeY or 3)                                                              --  Added so that transport shields dont count as personal shields.
            if (bp.Display.Abilities and TableFind(bp.Display.Abilities,'<LOC ability_personalshield>Personal Shield') or shieldarea < skirtarea) and not TableFind(bp.Categories, 'TRANSPORT') then
                bp.Defense.PersonalShieldThreat = (shield.ShieldMaxHealth or 0) * 0.01
            else
                bp.Defense.EconomyThreatLevel = bp.Defense.EconomyThreatLevel + ((shieldarea - skirtarea) * (shield.ShieldMaxHealth or 0) * (shield.ShieldRegenRate or 1)) / 250000000
            end
        end

        -- Define eco production values
        if bp.Economy.ProductionPerSecondMass then
            -- Mass prod + 5% of health
            bp.Defense.EconomyThreatLevel = bp.Defense.EconomyThreatLevel + bp.Economy.ProductionPerSecondMass * 10 + (bp.Defense.HealthThreat + bp.Defense.PersonalShieldThreat) * 5
        end
        if bp.Economy.ProductionPerSecondEnergy then
            -- Energy prod + 1% of health
            bp.Defense.EconomyThreatLevel = bp.Defense.EconomyThreatLevel + bp.Economy.ProductionPerSecondEnergy * 0.1 + bp.Defense.HealthThreat + bp.Defense.PersonalShieldThreat
        end
        -- 0 off the personal health values if we alreaady used them
        if bp.Economy.ProductionPerSecondMass or bp.Economy.ProductionPerSecondEnergy then
            bp.Defense.HealthThreat = 0
            bp.Defense.PersonalShieldThreat = 0
        end

        -- Calculate for build rates, ignore things that only upgrade
        if TakeIntoAccountBuildrate(bp) then
            -- non-mass producing energy production units that can build get off easy on the health calculation. Engineering reactor, we're looking at you
            if bp.Physics.MotionType == 'RULEUMT_None' then
                bp.Defense.EconomyThreatLevel = bp.Defense.EconomyThreatLevel + bp.Economy.BuildRate * 1 / (bp.Economy.BuilderDiscountMult or 1) * 2 + (bp.Defense.HealthThreat + bp.Defense.PersonalShieldThreat) * 2
            else
                bp.Defense.EconomyThreatLevel = bp.Defense.EconomyThreatLevel + bp.Economy.BuildRate  + (bp.Defense.HealthThreat + bp.Defense.PersonalShieldThreat) * 3
            end
            -- 0 off the personal health values if we alreaady used them
            bp.Defense.HealthThreat = 0
            bp.Defense.PersonalShieldThreat = 0
        end

        -- Calculate for storage values.
        if bp.Economy.StorageMass then
            bp.Defense.EconomyThreatLevel = bp.Defense.EconomyThreatLevel + bp.Economy.StorageMass * 0.001 + bp.Defense.HealthThreat + bp.Defense.PersonalShieldThreat
        end
        if bp.Economy.StorageEnergy then
            bp.Defense.EconomyThreatLevel = bp.Defense.EconomyThreatLevel + bp.Economy.StorageEnergy * 0.001 + bp.Defense.HealthThreat + bp.Defense.PersonalShieldThreat
        end
        -- 0 off the personal health values if we alreaady used them
        if bp.Economy.StorageMass or bp.Economy.StorageEnergy then
            bp.Defense.HealthThreat = 0
            bp.Defense.PersonalShieldThreat = 0
        end

        -- Arbitrary high bonus threat for special high pri
        if TableFind(bp.Categories, 'SPECIALHIGHPRI') then
            bp.Defense.EconomyThreatLevel = bp.Defense.EconomyThreatLevel + 250
        end

        -- No one really cares about air staging, well maybe a little bit.
        if bp.Transport.DockingSlots then
            bp.Defense.EconomyThreatLevel = bp.Defense.EconomyThreatLevel + bp.Transport.DockingSlots
        end

        -- Weapons
        if bp.Weapon then
            for i, weapon in bp.Weapon do
                if weapon.RangeCategory == 'UWRC_AntiAir' or weapon.TargetRestrictOnlyAllow == 'AIR' or StringFind(weapon.WeaponCategory or 'nope', 'Anti Air') then
                    bp.Defense.AirThreatLevel = bp.Defense.AirThreatLevel + CalculatedDPS(weapon) / 10
                elseif weapon.RangeCategory == 'UWRC_AntiNavy' or StringFind(weapon.WeaponCategory or 'nope', 'Anti Navy') then
                    if StringFind(weapon.WeaponCategory or 'nope', 'Bomb') or StringFind(weapon.Label or 'nope', 'Bomb') or weapon.NeedToComputeBombDrop or bp.Air.Winged then
                        LOG("Bomb drop damage value " .. CalculatedDamage(weapon))
                        bp.Defense.SubThreatLevel = bp.Defense.SubThreatLevel + CalculatedDamage(weapon) / 100
                    else
                        bp.Defense.SubThreatLevel = bp.Defense.SubThreatLevel + CalculatedDPS(weapon) / 10
                    end
                elseif weapon.RangeCategory == 'UWRC_DirectFire' or StringFind(weapon.WeaponCategory or 'nope', 'Direct Fire')
                or weapon.RangeCategory == 'UWRC_IndirectFire' or StringFind(weapon.WeaponCategory or 'nope', 'Artillery') then
                    -- Range cutoff for artillery being considered eco and surface threat is 100
                    local wepDPS = CalculatedDPS(weapon)
                    local rangeCutoff = 50
                    local econMult = 1
                    local surfaceMult = 0.1
                    if weapon.MinRadius and weapon.MinRadius >= rangeCutoff then
                        bp.Defense.EconomyThreatLevel = bp.Defense.EconomyThreatLevel + wepDPS * econMult
                    elseif weapon.MaxRadius and weapon.MaxRadius <= rangeCutoff then
                        bp.Defense.SurfaceThreatLevel = bp.Defense.SurfaceThreatLevel + wepDPS * surfaceMult
                    else
                        local distr = (rangeCutoff - (weapon.MinRadius or 0)) / (weapon.MaxRadius - (weapon.MinRadius or 0))
                        bp.Defense.EconomyThreatLevel = bp.Defense.EconomyThreatLevel + wepDPS * (1 - distr) * econMult
                        bp.Defense.SurfaceThreatLevel = bp.Defense.SurfaceThreatLevel + wepDPS * distr * surfaceMult
                    end
                elseif StringFind(weapon.WeaponCategory or 'nope', 'Bomb') or StringFind(weapon.Label or 'nope', 'Bomb') or weapon.NeedToComputeBombDrop then
                    LOG("Bomb drop damage value " .. CalculatedDamage(weapon))
                    bp.Defense.SurfaceThreatLevel = bp.Defense.SurfaceThreatLevel + CalculatedDamage(weapon) / 100
                elseif StringFind(weapon.WeaponCategory or 'nope', 'Death') then
                    bp.Defense.EconomyThreatLevel = MathFloor(bp.Defense.EconomyThreatLevel + CalculatedDPS(weapon) / 200)
                else
                    bp.Defense.UnknownWeaponThreat = bp.Defense.UnknownWeaponThreat + CalculatedDPS(weapon)
                    LOG(" * WARNING: Unknown weapon type on: " .. id .. " with the weapon label: " .. (weapon.Label or "nil") )
                    bp.Warnings = (bp.Warnings or 0) + 1
                end
                -- LOG(id .. " - " .. LOC(bp.General.UnitName or bp.Description) .. ' --  ' .. (weapon.DisplayName or '<Unnamed weapon>') .. ' ' .. weapon.RangeCategory .. " DPS: " .. CalculatedDPS(weapon))
            end
        end

        -- See if it has real threat yet
        local checkthreat = 0
        for k, v in { 'AirThreatLevel', 'EconomyThreatLevel', 'SubThreatLevel', 'SurfaceThreatLevel',} do
            checkthreat = checkthreat + bp.Defense[v]
        end

        -- Last ditch attempt to give it some threat
        if checkthreat < 1 then
            if bp.Defense.UnknownWeaponThreat > 0 then
                -- If we have no idea what it is still, it has threat equal to its unkown weapon DPS.
                bp.Defense.EconomyThreatLevel = bp.Defense.UnknownWeaponThreat
                bp.Defense.UnknownWeaponThreat = 0
            elseif bp.Economy.MaintenanceConsumptionPerSecondEnergy > 0 then
                -- If we STILL have no idea what it's threat is, and it uses power, its obviously doing something fucky, so we'll use that.
                bp.Defense.EconomyThreatLevel = bp.Economy.MaintenanceConsumptionPerSecondEnergy * 0.0175
            end
        end

        -- Get rid of unused threat values
        for i, v in {'HealthThreat','PersonalShieldThreat', 'UnknownWeaponThreat'} do
            if bp.Defense[v] and bp.Defense[v] ~= 0 then
                LOG("Unused " .. v .. " " .. bp.Defense[v])
                bp.Defense[v] = nil
            end
        end

        -- Sanitise the table
        checkthreat = 0
        for i, v in bp.Defense do
            -- Round appropriately
            if v < 1 then
                bp.Defense[i] = 0
            else
                bp.Defense[i] = MathFloor(v + 0.5)
            end
            -- Only report numbers if they aren't the same as on file.
            if bp.Defense[i] == (bp.Defense[i] or 0) then
                bp.Defense[i] = nil
            end
            if bp.Defense[i] then
                checkthreat = checkthreat + bp.Defense[i]
            end
        end
        --  If we have nothing to tell, tell nothing.
        if checkthreat == 0 then
            bp = nil
        end
    end
end
