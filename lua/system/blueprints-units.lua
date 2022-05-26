
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
    local isShield = unit.categoriesHash['SHIELD']
    local isLand = unit.CategoriesHash['LAND']
    local isScout = unit.CategoriesHash['SCOUT']
    local isArtillery = unit.CategoriesHash['ARTILLERY']
    local isAir = unit.CategoriesHash['AIR']
    local isCommand = unit.CategoriesHash['COMMAND']
    local isBomber = unit.CategoriesHash['BOMBER']

    -- do not touch guard scan radius values of engineer-like units, as it is the reason we have
    -- the factory-reclaim-bug that we're keen in keeping that at this point
    if not isEngineer then 

        -- guarantee that the table exists
        unit.AI = unit.AI or { }

        -- structures do not need this value set
        if isStructure then 
            unit.AI.GuardScanRadius = 0

        -- exceptions as these are tweaked by balance team
        elseif isLand and isScout then 
            -- do nothing
        
        -- exceptions as these are tweaked by balance team
        elseif isCommand then 
            -- do nothing 

        else 
            -- check if we have a primary weapon
            local primaryWeapon = unit.Weapon[1]
            if primaryWeapon then 

                local isAntiAir = primaryWeapon.RangeCategory == 'UWRC_AntiAir'
                local maxRadius = primaryWeapon.MaxRadius
                
                -- allow them to engage on targets more easily when on patrol
                elseif isAir and isBomber then 
                    unit.AI.GuardScanRadius = 2 * maxRadius

                -- land to air and air to air units shouldn't get triggered too fast
                elseif (isLand or isAir) and isAntiAir then 
                    unit.AI.GuardScanRadius = 0.80 * maxRadius

                -- all other units have - roughly - the default value of 10% on top of their maximum radius
                    unit.AI.GuardScanRadius = 1.10 * maxRadius
                end

            -- units with no weaponry, like some scouts or spy planes
            else 
                unit.AI.GuardScanRadius = 0
            end
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
        PostProcessUnit(unit)
    end
end