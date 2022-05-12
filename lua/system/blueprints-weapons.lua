
--- We don't want to change certain unit categories as they are quite sensitive to change
local categoriesToSkip = { }
categoriesToSkip.COMMAND = true 

local weaponTargetCheckUpperLimit = 6000

-- Multiplier depending on range category
local weaponTargetCheckMultiplier = { }
weaponTargetCheckMultiplier.UWRC_Countermeasure = 0.5
weaponTargetCheckMultiplier.UWRC_IndirectFire = 1.5
weaponTargetCheckMultiplier.UWRC_AntiNavy = 1.2
weaponTargetCheckMultiplier.UWRC_DirectFire = 1.2
weaponTargetCheckMultiplier.UWRC_AntiAir = 1.2

local function ProcessWeapon(unit, weapon)

    -- - pre-compute flags   

    local isAir = false
    local isStructure = false
    local isBomber = false 
    local isExperimental = false
    local isTech3 = false 
    local isTech2 = false 
    if unit.Categories then 
        for k, category in unit.Categories do 
            isStructure = isStructure or (category == "STRUCTURE")
            isAir = isAir or (category == "AIR")
            isBomber = isBomber or (category == "BOMBER")
            isTech2 = isTech2 or (category == "TECH2")
            isTech3 = isTech3 or (category == "TECH3")
            isExperimental = isExperimental or (category == "EXPERIMENTAL")
        end
    end

    -- - process weapon

    -- Death weapons of any kind
    if weapon.DamageType == "DeathExplosion" or weapon.Label == "DeathWeapon" or weapon.Label == "DeathImpact" then 
        weapon.TargetCheckInterval = weaponTargetCheckUpperLimit
        weapon.AlwaysRecheckTarget = false 
        weapon.DummyWeapon = true 
        weapon.ManualFire = true 
        weapon.TrackingRadius = 1.0
        return 
    end

    -- Tactical, strategical missile defenses and torpedo defenses
    if weapon.RangeCategory == "UWRC_Countermeasure" then 
        weapon.TargetCheckInterval = 0.25
        weapon.AlwaysRecheckTarget = false 
        weapon.TrackingRadius = 1.15
        weapon.DummyWeapon = false 
        weapon.ManualFire = false
        return 
    end

    -- - process target check interval

    weapon.TargetCheckInterval = math.min(
            0.5 * (1 / (weapon.RateOfFire or 1))    -- based on attack rate
        ,   (weapon.MaxRadius or 10) / 40           -- based on attack range
    )   

    -- except for counter measure weaponry
    if weapon.RangeCategory == "UWRC_Countermeasure" then 
        weapon.TargetCheckInterval = 0.5 
    end

    -- clamp value to something sane
    if weapon.TargetCheckInterval < 0.5 and (not isExperimental) then 
        weapon.TargetCheckInterval = 0.5 
    end

    -- clamp value to something sane
    if weapon.TargetCheckInterval < 0.1 then 
        weapon.TargetCheckInterval = 0.1 
    end

    -- clamp value to something sane
    if weapon.TargetCheckInterval > 10 then 
        weapon.TargetCheckInterval = 10 
    end

    -- sanitize it
    weapon.TargetCheckInterval = 0.1 * math.floor(10 * weapon.TargetCheckInterval)

    -- - process target tracking radius 

    -- by default, give every unit a 15% target checking radius
    weapon.TrackingRadius = 1.15

    -- remove target tracking radius for non-aa weaponry part of structures
    if isStructure and (weapon.RangeCategory ~= "UWRC_AntiAir") then 
        weapon.TrackingRadius = 1.0
    end

    -- give anti air a larger track radius
    if weapon.RangeCategory == "UWRC_AntiAir" then 
        weapon.TrackingRadius = 1.3 
    end
    
    -- add significant target checking radius for bombers
    if isBomber then 
        weapon.TrackingRadius = 1.5
    end

    -- - process target rechecking

    -- by default, do not recheck targets as that is expensive when a lot of units are stacked on top of another
    weapon.AlwaysRecheckTarget = false 

    -- allow target rechecking for artillery and weapons with a very large attack radius
    if  weapon.RangeCategory == "UWRC_IndirectFire" or 
        weapon.MaxRadius > 50 and (weapon.RangeCategory ~= "UWRC_AntiNavy") then 
        weapon.AlwaysRecheckTarget = true 
    end

    -- always allow anti air weapons attached to structures to retarget, as otherwise they may be stuck on a scout
    if isStructure and weapon.RangeCategory == "UWRC_AntiAir" then 
        weapon.AlwaysRecheckTarget = true 
    end

    -- always allow experimentals to retarget
    if isExperimental then 
        weapon.AlwaysRecheckTarget = true 
    end

    -- do not allow bombers to suddenly retarget, as then they won't drop their bomb then
    if isBomber then 
        weapon.AlwaysRecheckTarget = false 
    end
end

function ProcessWeapons(units)
    for k, unit in units do 

        -- check if we should skip this unit
        local skip = false 
        for k, category in unit.Categories do 
            skip = skip or categoriesToSkip[category]
        end

        if not skip then 
            if unit.Weapon then 
                LOG("Processing: " .. unit.BlueprintId .. " (" .. tostring(unit.General.UnitName) .. ")")
                for k, weapon in unit.Weapon do 
                    local TargetCheckInterval = weapon.TargetCheckInterval
                    local AlwaysRecheckTarget = weapon.AlwaysRecheckTarget 
                    local TrackingRadius = weapon.TrackingRadius

                    ProcessWeapon(unit, weapon)

                    LOG(" - Weapon label: " .. tostring(weapon.DisplayName))
                    LOG(" - - WeaponCheckinterval: " .. tostring(TargetCheckInterval) .. " -> " .. tostring(weapon.TargetCheckInterval))
                    LOG(" - - AlwaysRecheckTarget: " .. tostring(AlwaysRecheckTarget) .. " -> " .. tostring(weapon.AlwaysRecheckTarget))
                    LOG(" - - TrackingRadius: " .. tostring(TrackingRadius) .. " -> " .. tostring(weapon.TrackingRadius))
                end
            end
        end
    end
end
