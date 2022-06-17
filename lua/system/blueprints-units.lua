
-- Post process a unit
local function PostProcessUnit(unit)

    -- -- create hash tables for quick lookup

    unit.CategoriesCount = 0
    unit.CategoriesHash = { }
    if unit.Categories then 
        unit.CategoriesCount = table.getn(unit.Categories)
        for k, category in unit.Categories do 
            unit.CategoriesHash[category] = true 
        end
    end

    -- -- create hash tables for quick lookup

    unit.DoNotCollideListCount = 0 
    unit.DoNotCollideListHash = { }
    if unit.DoNotCollideList then 
        unit.DoNotCollideListCount = table.getn(unit.DoNotCollideList)
        for k, category in unit.DoNotCollideList do 
            unit.DoNotCollideListHash[category] = true 
        end
    end

    -- -- sanitize guard scan radius

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

    local isTech1 = unit.CategoriesHash['TECH1']
    local isTech2 = unit.CategoriesHash['TECH2']
    local isTech3 = unit.CategoriesHash['TECH3']
    local isExperimental = unit.CategoriesHash['EXPERIMENTAL']

    -- do not touch guard scan radius values of engineer-like units, as it is the reason we have
    -- the factory-reclaim-bug that we're keen in keeping that at this point
    if not isEngineer then 

        -- guarantee that the table exists
        unit.AI = unit.AI or { }

        -- if it is set then we use that - allows us to make adjustments as we see fit
        if unit.AI.GuardScanRadius == nil then 

            -- structures don't need this value set
            if isStructure or isDummy then 
                unit.AI.GuardScanRadius = 0

            -- engineers need their factory reclaim bug
            elseif isEngineer then 
                unit.AI.GuardScanRadius = 26 -- allows for factory reclaim bug 

            -- mobile units do need this value set
            else 
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

                    -- land to air units shouldn't get triggered too fast
                    if isLand and isAntiAir then 
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
    end

    -- -- sanitize air unit footprints

    -- value used by formations to determine the distance between other air units. Note
    -- that the value must be of type unsigned integer!

    if isAir and not (isExperimental or isStructure) then 
        unit.Footprint = unit.Footprint or { }
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
    end

    if unit.CategoriesHash['FACTORY'] and unit.CategoriesHash['NAVAL'] then 
        unit.Physics.CorrectNavalRollOffPoints = true
    end
end

--- Post-processes all units
function PostProcessUnits(units)
    for k, unit in units do 

        -- local oldGuardScanRadius = unit.AI.GuardScanRadius
        -- local oldGuardScanRadiusWasSet = true
        -- if not oldGuardScanRadius then 
        --     oldGuardScanRadiusWasSet = false
        --     local primaryWeapon = unit.Weapon[1]
        --     if primaryWeapon then 
        --         local maxRadius = primaryWeapon.MaxRadius or 0
        --         local trackingRadius = primaryWeapon.TrackingRadius or 1.0
        --         oldGuardScanRadius = trackingRadius * maxRadius
        --     else 
        --         oldGuardScanRadius = 25 -- default value
        --     end
        -- end

        PostProcessUnit(unit)

        -- LOG("Processing: " .. unit.BlueprintId .. " - GuardScanRadius: " .. tostring(oldGuardScanRadius) .. " -> " .. tostring(unit.AI.GuardScanRadius) .. " (" .. tostring(unit.General.UnitName) .. ")")
    end
end