--- Post process a unit
---@param unit Unit
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
        (isTransport and not isGunship) -- uef tech 2 gunship is also a transport :)
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
                    WARN(string.format("Overriding the size of the collision sphere of unit ( %s ), it should be atleast 10 percent ( %s ) of the maximum speed ( %s ) to guarantee proper functioning beam weapons", tostring(unit.BlueprintId), tostring(0.1 * speed), tostring(speed)))
                    unit.SizeSphere = 0.1 * speed
                end
            else
                if unit.SizeX < 0.1 * speed then
                    WARN(string.format("Overriding the x axis of collision box of unit ( %s ), it should be atleast 10 percent ( %s ) of the maximum speed ( %s ) to guarantee proper functioning beam weapons", tostring(unit.BlueprintId), tostring(0.1 * speed), tostring(speed)))
                    unit.SizeX = 0.1 * speed
                end

                if unit.SizeZ < 0.1 * speed then
                    WARN(string.format("Overriding the z axis of collision box of unit ( %s ), it should be atleast 10 percent ( %s ) of the maximum speed ( %s ) to guarantee proper functioning beam weapons", tostring(unit.BlueprintId), tostring(0.1 * speed), tostring(speed)))
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
        unit.General = {CommandCapsHash = {}}
    end
end

--- Post-processes all units
---@param units UnitBlueprint[]
function PostProcessUnits(units)
    for _, unit in units do
        PostProcessUnit(unit)
    end
end
