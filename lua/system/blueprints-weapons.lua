
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
    if unit.Categories then 
        for k, category in unit.Categories do 
            isStructure = isStructure or (category == "STRUCTURE")
            isAir = isAir or (category == "AIR")
        end
    end

    -- - process weapon

    -- these should never do a target check, and always be a manual fire solution
    if weapon.DamageType == "DeathExplosion" then 
        weapon.TargetCheckInterval = weaponTargetCheckUpperLimit
        weapon.AlwaysRecheckTarget = false 
        weapon.DummyWeapon = true 
        weapon.ManualFire = true 
        return 
    end

    -- - process target check interval

    -- default formula for target check interval
    weapon.TargetCheckInterval = (weapon.MaxRadius or 20) / 20
    weapon.TargetCheckInterval = weapon.TargetCheckInterval * (weaponTargetCheckMultiplier[weapon.RangeCategory] or 1.2)

    if isStructure then 
        weapon.TargetCheckInterval = 0.70 * weapon.TargetCheckInterval
    end

    -- clamp value
    if weapon.TargetCheckInterval < 1.0 then 
        weapon.TargetCheckInterval = 1.0 
    end

    if weapon.TargetCheckInterval > 10 then 
        weapon.TargetCheckInterval = 10 
    end

    -- - process target tracking radius 

    weapon.TrackingRadius = 1.15
    if isStructure and not weapon.RangeCategory == "UWRC_AntiAir" then 
        weapon.TrackingRadius = 1.0
    end

    -- - process target rechecking

    weapon.AlwaysRecheckTarget = false 
    if  weapon.RangeCategory == "UWRC_IndirectFire" or 
        (weapon.MaxRadius > 50 and not weapon.RangeCategory == "UWRC_AntiNavy") then 
        weapon.AlwaysRecheckTarget = true 
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
                for k, weapon in unit.Weapon do 
                    LOG("Processing: " .. unit.BlueprintId)
                    ProcessWeapon(unit, weapon)
                end
            end
        end
    end
end
