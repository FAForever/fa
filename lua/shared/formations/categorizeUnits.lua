local MathMax = math.max
local MathCeil = math.ceil

-- === LAND CATEGORIES ===
---@type EntityCategory
local DirectFire = (categories.DIRECTFIRE - (categories.CONSTRUCTION + categories.SNIPER + categories.WEAKDIRECTFIRE)) * categories.LAND
local Sniper = categories.SNIPER * categories.LAND
local Artillery = (categories.ARTILLERY + categories.INDIRECTFIRE - categories.SNIPER) * categories.LAND
local AntiAir = (categories.ANTIAIR - (categories.EXPERIMENTAL + categories.DIRECTFIRE + categories.SNIPER + Artillery)) * categories.LAND
local Construction = ((categories.COMMAND + categories.CONSTRUCTION + categories.ENGINEER) - (DirectFire + Sniper + Artillery)) * categories.LAND
local UtilityCat = (((categories.RADAR + categories.COUNTERINTELLIGENCE) - categories.DIRECTFIRE) + categories.SCOUT) * categories.LAND
---@type EntityCategory
ShieldCategory = categories.uel0307 + categories.ual0307 + categories.xsl0307
---@type EntityCategory
NonShieldCategory = categories.ALLUNITS - ShieldCategory

-- === TECH LEVEL LAND CATEGORIES ===
---@alias LandCategoryNames
---| "Shield"
---| "Bot1"
---| "Bot2"
---| "Bot3"
---| "Bot4"
---| "Tank1"
---| "Tank2"
---| "Tank3"
---| "Tank4"
---| "Sniper1"
---| "Sniper2"
---| "Sniper3"
---| "Sniper4"
---| "Art1"
---| "Art2"
---| "Art3"
---| "Art4"
---| "AA1"
---| "AA2"
---| "AA3"
---| "Com1"
---| "Com2"
---| "Com3"
---| "Com4"
---| "Util1"
---| "Util2"
---| "Util3"
---| "Util4"
---| "RemainingCategory"
---@type table<LandCategoryNames, EntityCategory>
LandCategories = {
    Shields = ShieldCategory,

    Bot1 = (DirectFire * categories.TECH1) * categories.BOT - categories.SCOUT,
    Bot2 = (DirectFire * categories.TECH2) * categories.BOT - categories.SCOUT,
    Bot3 = (DirectFire * categories.TECH3) * categories.BOT - categories.SCOUT,
    Bot4 = (DirectFire * categories.EXPERIMENTAL) * categories.BOT - categories.SCOUT,

    Tank1 = (DirectFire * categories.TECH1) - categories.BOT - categories.SCOUT,
    Tank2 = (DirectFire * categories.TECH2) - categories.BOT - categories.SCOUT,
    Tank3 = (DirectFire * categories.TECH3) - categories.BOT - categories.SCOUT,
    Tank4 = (DirectFire * categories.EXPERIMENTAL) - categories.BOT - categories.SCOUT,

    Sniper1 = (Sniper * categories.TECH1) - categories.SCOUT,
    Sniper2 = (Sniper * categories.TECH2) - categories.SCOUT,
    Sniper3 = (Sniper * categories.TECH3) - categories.SCOUT,
    Sniper4 = (Sniper * categories.EXPERIMENTAL) - categories.SCOUT,

    Art1 = Artillery * categories.TECH1,
    Art2 = Artillery * categories.TECH2,
    Art3 = Artillery * categories.TECH3,
    Art4 = Artillery * categories.EXPERIMENTAL,

    AA1 = AntiAir * categories.TECH1,
    AA2 = AntiAir * categories.TECH2,
    AA3 = AntiAir * categories.TECH3,

    Com1 = Construction * categories.TECH1,
    Com2 = Construction * categories.TECH2,
    Com3 = Construction - (categories.TECH1 + categories.TECH2 + categories.EXPERIMENTAL),
    Com4 = Construction * categories.EXPERIMENTAL,

    Util1 = (UtilityCat * categories.TECH1) + categories.OPERATION,
    Util2 = UtilityCat * categories.TECH2,
    Util3 = UtilityCat * categories.TECH3,
    Util4 = UtilityCat * categories.EXPERIMENTAL,

    RemainingCategory = categories.LAND - (DirectFire + Sniper + Construction + Artillery + AntiAir + UtilityCat + ShieldCategory)
}

-- === AIR CATEGORIES ===
local GroundAttackAir = (categories.AIR * categories.GROUNDATTACK) - categories.ANTIAIR
local TransportationAir = categories.AIR * categories.TRANSPORTATION - categories.GROUNDATTACK
local BomberAir = categories.AIR * categories.BOMBER
local AAAir = categories.AIR * categories.ANTIAIR
local AntiNavyAir = categories.AIR * categories.ANTINAVY
local IntelAir = categories.AIR * (categories.SCOUT + categories.RADAR)
local ExperimentalAir = categories.AIR * categories.EXPERIMENTAL
local EngineerAir = categories.AIR * categories.ENGINEER

-- === TECH LEVEL AIR CATEGORIES ===
---@alias AirCategoryNames
---| "Ground1"
---| "Ground2"
---| "Ground3"
---| "Trans1"
---| "Trans2"
---| "Trans3"
---| "Bomb1"
---| "Bomb2"
---| "Bomb3"
---| "AA1"
---| "AA2"
---| "AA3"
---| "AN1"
---| "AN2"
---| "AN3"
---| "AIntel1"
---| "AIntel2"
---| "AIntel3"
---| "AExper"
---| "AEngineer"
---| "RemainingCategory"
---@type table<AirCategoryNames, EntityCategory>
AirCategories = {
    Ground1 = GroundAttackAir * categories.TECH1,
    Ground2 = GroundAttackAir * categories.TECH2,
    Ground3 = GroundAttackAir * categories.TECH3,

    Trans1 = TransportationAir * categories.TECH1,
    Trans2 = TransportationAir * categories.TECH2,
    Trans3 = TransportationAir* categories.TECH3,

    Bomb1 = BomberAir * categories.TECH1,
    Bomb2 = BomberAir * categories.TECH2,
    Bomb3 = BomberAir * categories.TECH3,

    AA1 = AAAir * categories.TECH1,
    AA2 = AAAir * categories.TECH2,
    AA3 = AAAir * categories.TECH3,

    AN1 = AntiNavyAir * categories.TECH1,
    AN2 = AntiNavyAir * categories.TECH2,
    AN3 = AntiNavyAir * categories.TECH3,

    AIntel1 = IntelAir * categories.TECH1,
    AIntel2 = IntelAir * categories.TECH2,
    AIntel3 = IntelAir * categories.TECH3,

    AExper = ExperimentalAir,

    AEngineer = EngineerAir,

    RemainingCategory = categories.AIR - (GroundAttackAir + TransportationAir + BomberAir + AAAir + AntiNavyAir + IntelAir + ExperimentalAir + EngineerAir)
}

-- === NAVAL CATEGORIES ===
local LightAttackNaval = categories.LIGHTBOAT
local FrigateNaval = categories.FRIGATE
local SubNaval = categories.T1SUBMARINE + categories.T2SUBMARINE + (categories.TECH3 * categories.SUBMERSIBLE * categories.ANTINAVY * categories.NAVAL - categories.NUKE)
local DestroyerNaval = categories.DESTROYER
local CruiserNaval = categories.CRUISER
local BattleshipNaval = categories.BATTLESHIP
local CarrierNaval = categories.NAVALCARRIER
local NukeSubNaval = categories.NUKESUB - SubNaval
local MobileSonar = categories.MOBILESONAR
local DefensiveBoat = categories.DEFENSIVEBOAT
local RemainingNaval = categories.NAVAL - (LightAttackNaval + FrigateNaval + SubNaval + DestroyerNaval + CruiserNaval + BattleshipNaval +
                        CarrierNaval + NukeSubNaval + DefensiveBoat + MobileSonar)

-- === TECH LEVEL LAND CATEGORIES ===
---@alias NavalCategoryNames
---| "LightCount"
---| "FrigateCount"
---| "CruiserCount"
---| "DestroyerCount"
---| "BattleshipCount"
---| "CarrierCount"
---| "NukeSubCount"
---| "MobileSonarCount"
---| "RemainingCategory"
---@type table<NavalCategoryNames, EntityCategory>
NavalCategories = {
    LightCount = LightAttackNaval,
    FrigateCount = FrigateNaval,

    CruiserCount = CruiserNaval,
    DestroyerCount = DestroyerNaval,

    BattleshipCount = BattleshipNaval,
    CarrierCount = CarrierNaval,

    NukeSubCount = NukeSubNaval,
    MobileSonarCount = MobileSonar + DefensiveBoat,

    RemainingCategory = RemainingNaval,
}

---@alias SubCategoryNames
---| "SubCount"
---@type table<SubCategoryNames, EntityCategory>
SubCategories = {
    SubCount = SubNaval,
}

---@alias FormationLayerFootprintData table<number, FootprintSizeCategoryData>
---@alias FormationLayerCommonData { FootprintSizes: table<number, integer>, FootprintCounts: table<number, integer>, UnitTotal: integer, AreaTotal: number, Scale: number? }
---@alias FootprintSizeCategoryData { Count: integer, Filter: EntityCategory }

---@class FormationData
---@field Land table<LandCategoryNames, FormationLayerFootprintData> | FormationLayerCommonData
---@field Air table<AirCategoryNames, FormationLayerFootprintData> | FormationLayerCommonData
---@field Naval table<NavalCategoryNames, FormationLayerFootprintData> | FormationLayerCommonData
---@field Subs table<SubCategoryNames, FormationLayerFootprintData> | FormationLayerCommonData
-- reusable table for categorizing units in a formation
local UnitsList = {Land = {}, Air = {}, Naval = {}, Subs = {}}
-- map layers to categories
local CategoryTables = {Land = LandCategories, Air = AirCategories, Naval = NavalCategories, Subs = SubCategories}
-- initialize the layer tables
for unitType, categoriesForType in pairs(CategoryTables) do
    local typeData = UnitsList[unitType]
    for unitTypeCategory, _ in pairs(categoriesForType) do
        typeData[unitTypeCategory] = {}
    end
    typeData.FootprintCounts = {}
    typeData.FootprintSizes = {}
end

-- place units into formation categories, accumulate (unit type) & (unit type footprint counts by size), and map unit type category footprint size categories from blueprint id to global category of blueprint id
---@param formationUnits Unit[]
---@return FormationData
function CategorizeUnits(formationUnits)
    local categoryTables = CategoryTables

    -- flush the table
    for unitType, categoriesForType in pairs(categoryTables) do
        local typeData = UnitsList[unitType]
        for unitTypeCategory, _ in pairs(categoriesForType) do
            local typeDataCategory = typeData[unitTypeCategory]
            for k in pairs(typeDataCategory) do
                typeDataCategory[k] = nil
            end
        end

        local footprintCounts = typeData.FootprintCounts
        for k in pairs(footprintCounts) do
            footprintCounts[k] = nil
        end

        local footprintSizes = typeData.FootprintSizes
        for k in pairs(footprintSizes) do
            footprintSizes[k] = nil
        end

        typeData.UnitTotal = 0
        typeData.AreaTotal = 0
        typeData.Scale = nil -- set elsewhere in formations logic
    end

    -- Loop through each unit to get its category and size
    for _, unit in pairs(formationUnits) do
        local identified = false
        for type, table in pairs(categoryTables) do
            local typeData = UnitsList[type]
            for cat, _ in pairs(table) do
                if EntityCategoryContains(table[cat], unit) then
                    local bp = unit:GetBlueprint()
                    local fs = MathMax(bp.Footprint.SizeX, bp.Footprint.SizeZ)

                    if not fs then
                        WARN('*FORMATION DEBUG: Unit ' .. tostring(unit:GetBlueprint().BlueprintId) .. ' does not have any footprint size X or Z data. Overriding to 0')
                        fs = 0
                    end

                    local id = bp.BlueprintId

                    ---@type FormationLayerFootprintData
                    local categoryData = typeData[cat]

                    if not categoryData[fs] then
                        categoryData[fs] = {Count = 0, Filter = categories[id]}
                    end
                    ---@type FootprintSizeCategoryData
                    local footprintSizeData = categoryData[fs]

                    footprintSizeData.Count = footprintSizeData.Count + 1
                    footprintSizeData.Filter = footprintSizeData.Filter + categories[id]
                    typeData.FootprintCounts[fs] = (typeData.FootprintCounts[fs] or 0) + 1

                    if cat == "RemainingCategory" then
                        LOG('*FORMATION DEBUG: Unit ' .. tostring(unit:GetBlueprint().BlueprintId) .. ' does not match any ' .. type .. ' categories.')
                    end
                    typeData.UnitTotal = typeData.UnitTotal + 1
                    identified = true
                    break
                end
            end

            if identified then
                break
            end
        end
        if not identified then
            WARN('*FORMATION DEBUG: Unit ' .. unit.UnitId .. ' was excluded from the formation because its layer could not be determined.')
        end
    end

    CalculateSizes(UnitsList)

    return UnitsList
end

---@alias FormationLayers "Land" | "Air" | "Naval" | "Subs"
---@alias TypeGroupData { GridSizeFraction: number, GridSizeAbsolute: integer, MinSeparationFraction: number, Types: table<integer, FormationLayers> }
---@type { Land: TypeGroupData, Air: TypeGroupData, Sea: TypeGroupData  }
local TypeGroups = {
    Land = {
        GridSizeFraction = 2.75,
        GridSizeAbsolute = 2,
        MinSeparationFraction = 2.25,
        Types = {'Land'}
    },

    Air = {
        GridSizeFraction = 1.3,
        GridSizeAbsolute = 2,
        MinSeparationFraction = 1,
        Types = {'Air'}
    },

    Sea = {
        GridSizeFraction = 1.75,
        GridSizeAbsolute = 4,
        MinSeparationFraction = 1.15,
        Types = {'Naval', 'Subs'}
    },
}

---@param unitsList FormationData
---@return FormationData
function CalculateSizes(unitsList)
    local largestFootprint = 1
    local smallestFootprints = {}

    for group, data in pairs(TypeGroups) do
        local groupFootprintCounts = {}
        local largestForGroup = 1
        local numSizes = 0
        local unitTotal = 0
        for _, type in pairs(data.Types) do
            local typeData = unitsList[type]

            unitTotal = unitTotal + typeData.UnitTotal
            for fs, count in pairs(typeData.FootprintCounts) do
                groupFootprintCounts[fs] = (groupFootprintCounts[fs] or 0) + count
                largestFootprint = MathMax(largestFootprint, fs)
                largestForGroup = MathMax(largestForGroup, fs)
                numSizes = numSizes + 1
            end
        end

        smallestFootprints[group] = largestForGroup
        if numSizes > 0 then
            local minCount = unitTotal / 2
            local smallerUnitCount = 0
            for fs, count in pairs(groupFootprintCounts) do
                smallerUnitCount = smallerUnitCount + count
                if smallerUnitCount >= minCount then
                    smallestFootprints[group] = fs -- Base the grid size on the median unit size to avoid a few small units shrinking a formation of large untis
                    break
                end
            end
        end
    end

    for group, data in pairs(TypeGroups) do
        local gridSize = MathMax(smallestFootprints[group] * data.GridSizeFraction, smallestFootprints[group] + data.GridSizeAbsolute)
        for _, type in pairs(data.Types) do
            local unitData = unitsList[type]

             -- A distance of 1 in formation coordinates translates to (largestFootprint + 2) in world coordinates.
             -- Unfortunately the engine separates land/naval units from air units and calls the formation function separately for both groups.
             -- That means if a CZAR and some light tanks are selected together, the tank formation will be scaled by the CZAR's size and we can't compensate.
            unitData.Scale = gridSize / (largestFootprint + 2)

            for fs, count in pairs(unitData.FootprintCounts) do
                local size = MathCeil(fs * data.MinSeparationFraction / gridSize)
                unitData.FootprintSizes[fs] = size
                unitData.AreaTotal = unitData.AreaTotal + count * size * size
            end
        end
    end

    return unitsList
end
