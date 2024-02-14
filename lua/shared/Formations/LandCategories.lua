-- =========================================
-- ================ LAND DATA ==============
-- =========================================

local RemainingCategory = { 'RemainingCategory', }

-- === LAND CATEGORIES ===
local DirectFire = (categories.DIRECTFIRE - (categories.SNIPER + categories.WEAKDIRECTFIRE)) *
    categories.LAND
local Sniper = categories.SNIPER * categories.LAND
local Artillery = (categories.ARTILLERY + categories.INDIRECTFIRE - categories.SNIPER) * categories.LAND
local AntiAir = (categories.ANTIAIR - (categories.EXPERIMENTAL + categories.DIRECTFIRE + categories.SNIPER + Artillery))
    * categories.LAND
local Construction = (
    (categories.COMMAND + categories.CONSTRUCTION + categories.ENGINEER) - (DirectFire + Sniper + Artillery)) *
    categories.LAND
local UtilityCat = (((categories.RADAR + categories.COUNTERINTELLIGENCE) - categories.DIRECTFIRE) + categories.SCOUT) *
    categories.LAND
local ShieldCat = categories.uel0307 + categories.ual0307 + categories.xsl0307

-- === TECH LEVEL LAND CATEGORIES ===
LandCategories = {
    Shields = ShieldCat,

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

    RemainingCategory = categories.LAND -
        (DirectFire + Sniper + Construction + Artillery + AntiAir + UtilityCat + ShieldCat)
}

-- === SUB GROUP ORDERING ===
local Bots = { 'Bot4', 'Bot3', 'Bot2', 'Bot1', }
local Tanks = { 'Tank4', 'Tank3', 'Tank2', 'Tank1', }
local DF = { 'Tank4', 'Bot4', 'Tank3', 'Bot3', 'Tank2', 'Bot2', 'Tank1', 'Bot1', }
local Art = { 'Art4', 'Sniper4', 'Art3', 'Sniper3', 'Art2', 'Sniper2', 'Art1', 'Sniper1', }
local T1Art = { 'Sniper1', 'Art1', 'Sniper2', 'Art2', 'Sniper3', 'Art3', 'Sniper4', 'Art4', }
local AA = { 'AA3', 'AA2', 'AA1', }
local Util = { 'Util4', 'Util3', 'Util2', 'Util1', }
local Com = { 'Com4', 'Com3', 'Com2', 'Com1', }
local Shield = { 'Shields', }

-- === LAND BLOCK TYPES =
local DFFirst = { DF, T1Art, AA, Shield, Com, Util, RemainingCategory }
local ShieldFirst = { Shield, AA, DF, T1Art, Com, Util, RemainingCategory }
local AAFirst = { AA, DF, T1Art, Shield, Com, Util, RemainingCategory }
local ArtFirst = { Art, DF, AA, Shield, Com, Util, RemainingCategory }
local T1ArtFirst = { T1Art, DF, AA, Shield, Com, Util, RemainingCategory }
local UtilFirst = { Util, AA, Shield, DF, T1Art, Com, RemainingCategory }


-------------------------------------------------------------------------------
--#region Land attack formation

-- === 3 Wide Attack Block / 3 Units ===
ThreeWideAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, },
}

-- === 4 Wide Attack Block / 12 Units ===
FourWideAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, },
    -- second row
    { UtilFirst, ShieldFirst, ShieldFirst, UtilFirst, },
    -- third Row
    { AAFirst, ArtFirst, ArtFirst, AAFirst, },
}

-- === 5 Wide Attack Block ===
FiveWideAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, },
    -- second row
    { DFFirst, ShieldFirst, DFFirst, ShieldFirst, DFFirst, },
    -- third row
    { UtilFirst, ShieldFirst, DFFirst, ShieldFirst, UtilFirst, },
    -- fourth row
    { AAFirst, DFFirst, ArtFirst, DFFirst, AAFirst, },
}

-- === 6 Wide Attack Block ===
SixWideAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, },
    -- second row
    { DFFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, DFFirst, },
    -- third row
    { UtilFirst, AAFirst, DFFirst, DFFirst, AAFirst, UtilFirst, },
    -- fourth row
    { AAFirst, ShieldFirst, ArtFirst, ArtFirst, ShieldFirst, AAFirst, },
    -- fifth row
    { DFFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, DFFirst, },
}

-- === 7 Wide Attack Block ===
SevenWideAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, },
    -- second Row
    { DFFirst, ShieldFirst, DFFirst, ShieldFirst, DFFirst, ShieldFirst, DFFirst, },
    -- third row
    { DFFirst, UtilFirst, AAFirst, DFFirst, AAFirst, UtilFirst, DFFirst, },
    -- fourth row
    { DFFirst, ShieldFirst, AAFirst, T1ArtFirst, AAFirst, ShieldFirst, DFFirst, },
    -- fifth row
    { DFFirst, T1ArtFirst, AAFirst, ShieldFirst, AAFirst, T1ArtFirst, DFFirst, },
    -- sixth row
    { ArtFirst, UtilFirst, ArtFirst, AAFirst, ArtFirst, UtilFirst, ArtFirst, },
}

-- === 8 Wide Attack Block ===
EightWideAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, },
    -- second Row
    { DFFirst, ShieldFirst, DFFirst, ShieldFirst, ShieldFirst, DFFirst, ShieldFirst, DFFirst, },
    -- third row
    { DFFirst, UtilFirst, AAFirst, DFFirst, DFFirst, AAFirst, UtilFirst, DFFirst, },
    -- fourth row
    { DFFirst, ShieldFirst, T1ArtFirst, AAFirst, AAFirst, T1ArtFirst, ShieldFirst, DFFirst, },
    -- fifth row
    { DFFirst, T1ArtFirst, AAFirst, T1ArtFirst, T1ArtFirst, AAFirst, T1ArtFirst, DFFirst, },
    -- sixth row
    { DFFirst, ShieldFirst, UtilFirst, ShieldFirst, ShieldFirst, UtilFirst, ShieldFirst, DFFirst, },
    -- seventh row
    { DFFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, DFFirst, },
}

-- === 2 Row Attack Block - 8 units wide ===
TwoRowAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst },
    -- second row
    { AAFirst, UtilFirst, ShieldFirst, ArtFirst, ArtFirst, ShieldFirst, UtilFirst, AAFirst },
}

-- === 3 Row Attack Block - 10 units wide ===
ThreeRowAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst },
    -- second row
    { AAFirst, ShieldFirst, UtilFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, UtilFirst, ShieldFirst, AAFirst },
    -- third row
    { DFFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, DFFirst },
}

-- === 4 Row Attack Block - 12 units wide ===
FourRowAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst },
    -- second row
    { DFFirst, ShieldFirst, DFFirst, UtilFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, UtilFirst, DFFirst,
        ShieldFirst, DFFirst },
    -- third row
    { DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst },
    -- fourth row
    { AAFirst, ShieldFirst, DFFirst, ArtFirst, ShieldFirst, ArtFirst, ArtFirst, ShieldFirst, ArtFirst, DFFirst,
        ShieldFirst, AAFirst },
}

-- === 5 Row Attack Block - 14 units wide ===
FiveRowAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst,
        DFFirst },
    -- second row
    { UtilFirst, ShieldFirst, DFFirst, ShieldFirst, UtilFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, UtilFirst,
        ShieldFirst, DFFirst, ShieldFirst, UtilFirst },
    -- third row
    { DFFirst, AAFirst, DFFirst, AAFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, AAFirst, DFFirst, AAFirst,
        DFFirst },
    -- fourth row
    { AAFirst, ShieldFirst, DFFirst, ShieldFirst, DFFirst, ShieldFirst, AAFirst, AAFirst, ShieldFirst, DFFirst,
        ShieldFirst, DFFirst, ShieldFirst, AAFirst },
    -- five row
    { ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst,
        AAFirst, ArtFirst },
}

-- === 6 Row Attack Block - 16 units wide ===
SixRowAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst,
        DFFirst, DFFirst, DFFirst },
    -- second row
    { UtilFirst, ShieldFirst, DFFirst, ShieldFirst, DFFirst, UtilFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst,
        UtilFirst, DFFirst, ShieldFirst, DFFirst, ShieldFirst, UtilFirst },
    -- third row
    { DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst,
        DFFirst, AAFirst, DFFirst },
    -- fourth row
    { AAFirst, ShieldFirst, AAFirst, DFFirst, AAFirst, AAFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, AAFirst,
        AAFirst, DFFirst, AAFirst, ShieldFirst, AAFirst },
    -- fifth row
    { DFFirst, AAFirst, DFFirst, UtilFirst, ShieldFirst, DFFirst, DFFirst, AAFirst, AAFirst, DFFirst, DFFirst,
        ShieldFirst, UtilFirst, DFFirst, AAFirst, DFFirst },
    -- sixth row
    { AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst,
        AAFirst, ArtFirst, ArtFirst, AAFirst },
}

-- === 7 Row Attack Block - 18 units wide ===
SevenRowAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst,
        DFFirst, DFFirst, DFFirst, DFFirst, DFFirst },
    -- second row
    { UtilFirst, ShieldFirst, DFFirst, ShieldFirst, DFFirst, ShieldFirst, UtilFirst, ShieldFirst, DFFirst, DFFirst,
        ShieldFirst, UtilFirst, ShieldFirst, DFFirst, ShieldFirst, DFFirst, ShieldFirst, UtilFirst },
    -- third row
    { DFFirst, DFFirst, AAFirst, DFFirst, AAFirst, DFFirst, DFFirst, DFFirst, AAFirst, AAFirst, DFFirst, DFFirst, DFFirst,
        AAFirst, DFFirst, AAFirst, DFFirst, DFFirst },
    -- fourth row
    { DFFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, DFFirst, AAFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst,
        AAFirst, DFFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, DFFirst },
    -- fifth row
    { UtilFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst,
        DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, UtilFirst },
    -- sixth row
    { DFFirst, ShieldFirst, AAFirst, DFFirst, ShieldFirst, UtilFirst, DFFirst, ShieldFirst, AAFirst, AAFirst, ShieldFirst,
        DFFirst, UtilFirst, ShieldFirst, DFFirst, AAFirst, ShieldFirst, DFFirst },
    -- seventh row
    { ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst,
        AAFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst },
}

-- === 8 Row Attack Block - 20 units wide ===
EightRowAttackFormationBlock = {
    -- first row
    { DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst,
        DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst, DFFirst },
    -- second row
    { DFFirst, ShieldFirst, UtilFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, UtilFirst, ShieldFirst, DFFirst,
        DFFirst, ShieldFirst, UtilFirst, ShieldFirst, DFFirst, DFFirst, ShieldFirst, UtilFirst, ShieldFirst, DFFirst },
    -- third row
    { DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst,
        DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst },
    -- fourth row
    { DFFirst, ShieldFirst, DFFirst, AAFirst, ShieldFirst, DFFirst, ShieldFirst, AAFirst, ShieldFirst, DFFirst, DFFirst,
        ShieldFirst, AAFirst, ShieldFirst, DFFirst, ShieldFirst, AAFirst, DFFirst, ShieldFirst, DFFirst },
    -- fifth row
    { DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst, AAFirst, AAFirst, DFFirst, AAFirst,
        DFFirst, DFFirst, AAFirst, DFFirst, DFFirst, AAFirst, DFFirst },
    -- sixth row
    { UtilFirst, ShieldFirst, ArtFirst, ShieldFirst, ArtFirst, UtilFirst, ShieldFirst, ArtFirst, ShieldFirst, AAFirst,
        AAFirst, ShieldFirst, ArtFirst, ShieldFirst, UtilFirst, ArtFirst, ShieldFirst, ArtFirst, ShieldFirst, UtilFirst },
    -- seventh row
    { DFFirst, AAFirst, DFFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, ArtFirst, AAFirst,
        ArtFirst, ArtFirst, ArtFirst, AAFirst, ArtFirst, DFFirst, AAFirst, DFFirst },
    -- eight row
    { AAFirst, ShieldFirst, ArtFirst, AAFirst, ShieldFirst, ArtFirst, ShieldFirst, AAFirst, ShieldFirst, ArtFirst,
        ArtFirst, ShieldFirst, AAFirst, ShieldFirst, ArtFirst, ShieldFirst, AAFirst, ArtFirst, ShieldFirst, AAFirst },
}

--#endregion
