
-- Post process a unit
local function PostProcessUnit(unit)

    -- create hash tables for quick lookup

    unit.CategoriesCount = 0
    unit.CategoriesHash = { }
    if unit.Categories then 
        unit.CategoriesCount = table.getn(unit.Categories)
        for k, category in unit.Categories do 
            unit.CategoriesHash[category] = true 
        end
    end

    -- create hash tables for quick lookup

    unit.DoNotCollideListCount = 0 
    unit.DoNotCollideListHash = { }
    if unit.DoNotCollideList then 
        unit.DoNotCollideListCount = table.getn(unit.DoNotCollideList)
        for k, category in unit.DoNotCollideList do 
            unit.DoNotCollideListHash[category] = true 
        end
    end

    -- sanitize guard scan radius

    -- The guard scan radius is used when:
    -- - A unit attack moves, it determines how far the unit remains from its target
    -- - A unit patrols, it determines when the unit decides to engage

    -- All of the decisions below are made based on when a unit attack moves, as that is
    -- the default meta to use in competitive play. This is by all means not perfect,
    -- but it is the best we can do

    local isEngineer = unit.CategoriesHash['ENGINEER']
    local isStructure = unit.CategoriesHash['STRUCTURE']
    local isLand = unit.CategoriesHash['LAND']

    local isTech1 = unit.CategoriesHash['TECH1']
    local isTech2 = unit.CategoriesHash['TECH2']
    local isTech3 = unit.CategoriesHash['TECH3']
    local isExperimental = unit.CategoriesHash['EXPERIMENTAL']

    -- do not touch guard scan radius values of engineer-like units, as it is the reason we have
    -- the factory-reclaim-bug that we're keen in keeping that at this point
    if not isEngineer then 

        -- guarantee that the table exists
        unit.AI = unit.AI or { }

        -- if it is set then we use that - allows balance team to make adjustments as they see fit
        if not unit.AI.GuardScanRadius then 

            -- check if we have a primary weapon that is actually a weapon
            local primaryWeapon = unit.Weapon[1]
            if primaryWeapon and not 
                (
                    primaryWeapon.DummyWeapon or 
                    primaryWeapon.WeaponCategory == 'Death' or
                    primaryWeapon.Label == 'DeathImpact' or
                    primaryWeapon.DisplayName == 'Air Crash'
                )
            then 

                local isAntiAir = primaryWeapon.RangeCategory == 'UWRC_AntiAir'
                local maxRadius = primaryWeapon.MaxRadius or 0
                
                -- structures don't need this value set
                if isStructure then 
                    unit.AI.GuardScanRadius = 0 

                -- land to air units shouldn't get triggered too fast
                elseif isLand and isAntiAir then 
                    unit.AI.GuardScanRadius = 0.80 * maxRadius

                -- all other units will have the default value of 10% on top of their maximum attack radius
                else
                    unit.AI.GuardScanRadius = 1.10 * maxRadius
                end

            -- units with no weaponry don't need this value set
            else 
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

    -- sanitize air staging radius

    local isAirStaging = unit.CategoriesHash['AIRSTAGINGPLATFORM']

    if not isAirStaging then 

        -- guarantee that the table exists
        unit.AI = unit.AI or { }

        -- set the scan radius to 0, as this value is only used by an air staging platform
        unit.AI.StagingPlatformScanRadius = 0
    end
end

--- Post-processes all units
function PostProcessUnits(units)
    for k, unit in units do 

        local oldGuardScanRadius = unit.AI.GuardScanRadius
        if not oldGuardScanRadius then 
            local primaryWeapon = unit.Weapon[1]
            if primaryWeapon then 
                local maxRadius = primaryWeapon.MaxRadius or 0
                local trackingRadius = primaryWeapon.TrackingRadius or 1.0
                oldGuardScanRadius = trackingRadius * maxRadius
            else 
                oldGuardScanRadius = 25 -- default value
            end
        end

        PostProcessUnit(unit)

        LOG("Processing: " .. unit.BlueprintId .. " - GuardScanRadius: " .. tostring(oldGuardScanRadius) .. " -> " .. tostring(unit.AI.GuardScanRadius) .. " (" .. tostring(unit.General.UnitName) .. ")")
    end
end