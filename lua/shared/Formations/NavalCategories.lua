local RemainingCategory = { 'RemainingCategory', }

local LightAttackNaval = categories.LIGHTBOAT
local FrigateNaval = categories.FRIGATE
local SubNaval = categories.T1SUBMARINE + categories.T2SUBMARINE +
    (categories.NUKESUB * categories.ANTINAVY - categories.NUKE)
local DestroyerNaval = categories.DESTROYER
local CruiserNaval = categories.CRUISER
local BattleshipNaval = categories.BATTLESHIP
local CarrierNaval = categories.NAVALCARRIER
local NukeSubNaval = categories.NUKESUB - SubNaval
local MobileSonar = categories.MOBILESONAR
local DefensiveBoat = categories.DEFENSIVEBOAT
local RemainingNaval = categories.NAVAL -
    (LightAttackNaval + FrigateNaval + SubNaval + DestroyerNaval + CruiserNaval + BattleshipNaval +
        CarrierNaval + NukeSubNaval + DefensiveBoat + MobileSonar)


-- === TECH LEVEL LAND CATEGORIES ===
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

SubCategories = {
    SubCount = SubNaval,
}

-- === SUB GROUP ORDERING ===
local Frigates = { 'FrigateCount', 'LightCount', }
local Destroyers = { 'DestroyerCount', }
local Cruisers = { 'CruiserCount', }
local Battleships = { 'BattleshipCount', }
local Subs = { 'SubCount', }
local NukeSubs = { 'NukeSubCount', }
local Carriers = { 'CarrierCount', }
local Sonar = { 'MobileSonarCount', }

-- === NAVAL BLOCK TYPES =
local FrigatesFirst = { Frigates, Destroyers, Battleships, Cruisers, Carriers, NukeSubs, Sonar, RemainingCategory }
local DestroyersFirst = { Destroyers, Frigates, Battleships, Cruisers, Carriers, NukeSubs, Sonar, RemainingCategory }
local CruisersFirst = { Cruisers, Carriers, Battleships, Destroyers, Frigates, NukeSubs, Sonar, RemainingCategory }
local LargestFirstDF = { Battleships, Carriers, Destroyers, Cruisers, Frigates, NukeSubs, Sonar, RemainingCategory }
local SmallestFirstDF = { Frigates, Destroyers, Cruisers, Sonar, Battleships, Carriers, NukeSubs, RemainingCategory }
local LargestFirstAA = { Carriers, Battleships, Cruisers, Destroyers, Frigates, NukeSubs, Sonar, RemainingCategory }
local SmallestFirstAA = { Cruisers, Frigates, Destroyers, Sonar, Carriers, Battleships, NukeSubs, RemainingCategory }
local Subs = { Subs, NukeSubs, RemainingCategory }
local SonarFirst = { Sonar, Carriers, Cruisers, Battleships, Destroyers, Frigates, NukeSubs, Sonar, RemainingCategory }

-------------------------------------------------------------------------------
--#region Naval growth formation

-- === Three Naval Growth Formation Block ==
ThreeNavalGrowthFormation = {
    LineBreak = 0.5,
    -- first row
    { FrigatesFirst, FrigatesFirst, FrigatesFirst },
    -- second row
    { LargestFirstDF, SonarFirst, LargestFirstDF },
    -- third row
    { DestroyersFirst, CruisersFirst, DestroyersFirst },
}

-- === Five Naval Growth Formation Block ==
FiveNavalGrowthFormation = {
    LineBreak = 0.5,
    -- first row
    { FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst },
    -- second row
    { FrigatesFirst, LargestFirstDF, DestroyersFirst, LargestFirstDF, FrigatesFirst },
    -- third row
    { DestroyersFirst, SmallestFirstDF, SonarFirst, SmallestFirstDF, DestroyersFirst },
    -- fourth row
    { DestroyersFirst, LargestFirstAA, CruisersFirst, LargestFirstAA, DestroyersFirst },
    -- fifth row
    { DestroyersFirst, SmallestFirstAA, CruisersFirst, SmallestFirstAA, DestroyersFirst },

}

-- === Seven Naval Growth Formation Block ==
SevenNavalGrowthFormation = {
    LineBreak = 0.5,
    -- first row
    { FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst },
    -- second row
    { FrigatesFirst, SmallestFirstDF, DestroyersFirst, DestroyersFirst, DestroyersFirst, SmallestFirstDF, FrigatesFirst },
    -- third row
    { DestroyersFirst, DestroyersFirst, LargestFirstDF, SonarFirst, LargestFirstDF, DestroyersFirst, DestroyersFirst },
    -- fourth row
    { DestroyersFirst, SmallestFirstAA, SmallestFirstAA, CruisersFirst, SmallestFirstAA, SmallestFirstAA, DestroyersFirst },
    -- fifth row
    { DestroyersFirst, CruisersFirst, LargestFirstAA, DestroyersFirst, LargestFirstAA, CruisersFirst, DestroyersFirst },
    -- sixth row
    { DestroyersFirst, SmallestFirstAA, SmallestFirstAA, SonarFirst, SmallestFirstAA, SmallestFirstAA, DestroyersFirst },
    -- seventh row
    { DestroyersFirst, CruisersFirst, LargestFirstDF, CruisersFirst, LargestFirstDF, CruisersFirst, DestroyersFirst },
}

-- === Nine Naval Growth Formation Block ==
NineNavalGrowthFormation = {
    LineBreak = 0.5,
    -- first row
    { FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst,
        FrigatesFirst, FrigatesFirst },
    -- second row
    { FrigatesFirst, LargestFirstDF, SonarFirst, LargestFirstDF, DestroyersFirst, LargestFirstDF, SonarFirst,
        LargestFirstDF, FrigatesFirst },
    -- third row
    { SmallestFirstDF, DestroyersFirst, SmallestFirstAA, SmallestFirstAA, SonarFirst, SmallestFirstAA, SmallestFirstAA,
        DestroyersFirst, SmallestFirstDF },
    -- fourth row
    { DestroyersFirst, LargestFirstAA, CruisersFirst, LargestFirstAA, CruisersFirst, LargestFirstAA, CruisersFirst,
        LargestFirstAA, DestroyersFirst },
    -- fifth row
    { DestroyersFirst, DestroyersFirst, SmallestFirstAA, SmallestFirstAA, CruisersFirst, SmallestFirstAA, SmallestFirstAA,
        DestroyersFirst, DestroyersFirst },
}

--#endregion

-------------------------------------------------------------------------------
--#region Naval attack formation

-- === Five Wide Naval Attack Formation Block ==
FiveWideNavalAttackFormation = {
    LineBreak = 0.5,
    -- first row
    { FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst },
    -- second row
    { DestroyersFirst, LargestFirstDF, CruisersFirst, LargestFirstDF, DestroyersFirst },
}

-- === Seven Wide Naval Attack Formation Block ==
SevenWideNavalAttackFormation = {
    LineBreak = 0.5,
    -- first row
    { FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst },
    -- second row
    { DestroyersFirst, SonarFirst, LargestFirstDF, DestroyersFirst, LargestFirstDF, SonarFirst, DestroyersFirst },
    -- third row
    { SmallestFirstDF, SmallestFirstAA, SmallestFirstDF, CruisersFirst, SmallestFirstDF, SmallestFirstAA, SmallestFirstDF },
}

-- === Nine Wide Naval Attack Formation Block ==
NineWideNavalAttackFormation = {
    LineBreak = 0.5,
    -- first row
    { FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst,
        FrigatesFirst, FrigatesFirst },
    -- second row
    { DestroyersFirst, LargestFirstDF, SonarFirst, LargestFirstDF, DestroyersFirst, LargestFirstDF, SonarFirst,
        LargestFirstDF, DestroyersFirst },
    -- third row
    { SmallestFirstDF, DestroyersFirst, SmallestFirstAA, SmallestFirstAA, SonarFirst, SmallestFirstAA, SmallestFirstAA,
        DestroyersFirst, SmallestFirstDF },
    -- fourth row
    { DestroyersFirst, SmallestFirstDF, CruisersFirst, LargestFirstAA, CruisersFirst, LargestFirstAA, CruisersFirst,
        SmallestFirstDF, DestroyersFirst },
}

-- === Eleven Wide Naval Attack Formation Block ==
ElevenWideNavalAttackFormation = {
    LineBreak = 0.5,
    -- first row
    { FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst,
        FrigatesFirst, FrigatesFirst, FrigatesFirst, FrigatesFirst },
    -- second row
    { DestroyersFirst, DestroyersFirst, LargestFirstDF, SmallestFirstDF, LargestFirstDF, DestroyersFirst, LargestFirstDF,
        SmallestFirstDF, LargestFirstDF, DestroyersFirst, DestroyersFirst },
    -- third row
    { SmallestFirstDF, DestroyersFirst, SmallestFirstAA, SmallestFirstAA, SmallestFirstAA, SonarFirst, SmallestFirstAA,
        SmallestFirstAA, SmallestFirstAA, DestroyersFirst, SmallestFirstDF },
    -- fourth row
    { DestroyersFirst, SmallestFirstAA, LargestFirstDF, SonarFirst, LargestFirstAA, CruisersFirst, LargestFirstAA,
        SonarFirst, LargestFirstDF, SmallestFirstAA, DestroyersFirst },
}

--#endregion

-------------------------------------------------------------------------------
--#region Submarine growth formation

-- === Four Wide Growth Subs Formation ===
FourWideSubGrowthFormation = {
    LineBreak = 0.5,
    { Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs },
}

-- === Six Wide Subs Formation ===
SixWideSubGrowthFormation = {
    LineBreak = 0.5,
    { Subs, Subs, Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs, Subs, Subs },
}

-- === Eight Wide Subs Formation ===
EightWideSubGrowthFormation = {
    LineBreak = 0.5,
    { Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs },
}

--#endregion

-------------------------------------------------------------------------------
--#region Submarine attack formations

-- === Four Wide Subs Formation ===
FourWideSubAttackFormation = {
    LineBreak = 0.5,
    { Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs },
}

-- === Six Wide Subs Formation ===
SixWideSubAttackFormation = {
    LineBreak = 0.5,
    { Subs, Subs, Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs, Subs, Subs },
}

-- === Eight Wide Subs Formation ===
EightWideSubAttackFormation = {
    LineBreak = 0.5,
    { Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs },
}

-- === Ten Wide Subs Formation ===
TenWideSubAttackFormation = {
    LineBreak = 0.5,
    { Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs },
    { Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs, Subs },
}

--#endregion
