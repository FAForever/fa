
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

    -- these should never do a target check, and always be a manual fire solution
    if weapon.DamageType == "DeathExplosion" or weapon.Label == "DeathWeapon" or weapon.Label == "DeathImpact" then 
        weapon.TargetCheckInterval = weaponTargetCheckUpperLimit
        weapon.AlwaysRecheckTarget = false 
        weapon.DummyWeapon = true 
        weapon.ManualFire = true 
        weapon.TrackingRadius = 1.0
        return 
    end

    -- - process target check interval

    -- default formula for target check interval
    weapon.TargetCheckInterval = (weapon.MaxRadius or 20) / 40
    weapon.TargetCheckInterval = weapon.TargetCheckInterval * (weaponTargetCheckMultiplier[weapon.RangeCategory] or 1.2)

    -- lower check interval for structures and experimentals and non-air tech 3 units
    if isStructure or isExperimental or (isTech3 and not isAir) then 
        weapon.TargetCheckInterval = 0.50 * weapon.TargetCheckInterval
    end

    -- lower check interval for non-air tech 2 units
    if isTech2 and not isAir then 
        weapon.TargetCheckInterval = 0.75 * weapon.TargetCheckInterval
    end

    -- clamp value
    if weapon.TargetCheckInterval < 0.5 then 
        weapon.TargetCheckInterval = 0.5 
    end

    if weapon.TargetCheckInterval > 10 then 
        weapon.TargetCheckInterval = 10 
    end

    -- - process target tracking radius 

    -- by default, give every unit a 15% target checking radius
    weapon.TrackingRadius = 1.15

    -- remove target tracking radius for non-aa weaponry part of structures
    if isStructure and (weapon.RangeCategory ~= "UWRC_AntiAir") then 
        weapon.TrackingRadius = 1.0
    end
    
    -- add significant target checking radius for bombers
    if isBomber then 
        weapon.TrackingRadius = 2.0
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
                -- LOG("Processing: " .. unit.BlueprintId .. " (" .. tostring(unit.General.UnitName) .. ")")
                for k, weapon in unit.Weapon do 
                    -- LOG(" - Weapon label: " .. tostring(weapon.DisplayName))
                    -- LOG(" - - WeaponCheckinterval (prev): " .. tostring(weapon.TargetCheckInterval or 3.0))
                    ProcessWeapon(unit, weapon)
                    -- LOG(" - - WeaponCheckinterval (post): " .. tostring(weapon.TargetCheckInterval))
                    -- LOG(" - - AlwaysRecheckTarget (post): " .. tostring(weapon.AlwaysRecheckTarget))
                    -- LOG(" - - TrackingRadius (post): " .. tostring(weapon.TrackingRadius))
                end
            end
        end
    end
end
