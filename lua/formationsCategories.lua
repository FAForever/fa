-- === LAND CATEGORIES ===
local DirectFire = (categories.DIRECTFIRE - (categories.CONSTRUCTION + categories.SNIPER + categories.WEAKDIRECTFIRE)) * categories.LAND
local Sniper = categories.SNIPER * categories.LAND
local Artillery = (categories.ARTILLERY + categories.INDIRECTFIRE - categories.SNIPER) * categories.LAND
local AntiAir = (categories.ANTIAIR - (categories.EXPERIMENTAL + categories.DIRECTFIRE + categories.SNIPER + Artillery)) * categories.LAND
local Construction = ((categories.COMMAND + categories.CONSTRUCTION + categories.ENGINEER) - (DirectFire + Sniper + Artillery)) * categories.LAND
local UtilityCat = (((categories.RADAR + categories.COUNTERINTELLIGENCE) - categories.DIRECTFIRE) + categories.SCOUT) * categories.LAND
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

    RemainingCategory = categories.LAND - (DirectFire + Sniper + Construction + Artillery + AntiAir + UtilityCat + ShieldCat)
}
