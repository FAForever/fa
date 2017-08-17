local WeaponFile = import('/lua/sim/DefaultWeapons.lua')
local DefaultProjectileWeapon = WeaponFile.DefaultProjectileWeapon

ADFCannonOblivionNaval = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/oblivion_cannon_naval_01_emit.bp',  -- Stream effect
        '/effects/emitters/oblivion_cannon_naval_02_emit.bp',  -- Gas effect
        '/effects/emitters/oblivion_cannon_naval_03_emit.bp',  -- Sparkle effect
        '/effects/emitters/oblivion_cannon_naval_04_emit.bp',  -- Sphere effect
    },
}