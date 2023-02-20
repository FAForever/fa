
local weaponTargetCheckUpperLimit = 6000

---@param unit UnitBlueprint
---@param weapon WeaponBlueprint
local function ProcessWeapon(unit, weapon)
    -- pre-compute flags   
    local isAir = false
    local isStructure = false
    local isBomber = false
    local isExperimental = false
    local isTech3 = false
    local isTech2 = false
    if unit.Categories then
        for _, category in unit.Categories do
            isStructure = isStructure or category == "STRUCTURE"
            isAir = isAir or category == "AIR"
            isBomber = isBomber or category == "BOMBER"
            isTech2 = isTech2 or category == "TECH2"
            isTech3 = isTech3 or category == "TECH3"
            isExperimental = isExperimental or category == "EXPERIMENTAL"
        end
    end

    -- process weapon

    -- Death weapons of any kind
    if weapon.DamageType == "DeathExplosion" or weapon.Label == "DeathWeapon" or weapon.Label == "DeathImpact" then
        weapon.TargetCheckInterval = weaponTargetCheckUpperLimit
        weapon.AlwaysRecheckTarget = false
        weapon.TrackingRadius = 0.0
        return
    end

    -- Tactical, strategical missile defenses and torpedo defenses
    if weapon.RangeCategory == "UWRC_Countermeasure" then
        weapon.TargetCheckInterval = 0.4
        weapon.AlwaysRecheckTarget = false
        weapon.TrackingRadius = 1.10
        weapon.ManualFire = false
        return
    end

    -- manual launch of tactical and strategic missiles
    if weapon.ManualFire then
        weapon.TargetCheckInterval = weaponTargetCheckUpperLimit
        weapon.AlwaysRecheckTarget = false
        weapon.TrackingRadius = 0.0
        return
    end

    -- process target check interval

    -- if it is set then we use that - allows us to make adjustments as we see fit
    if weapon.TargetCheckInterval == nil then
        local intervalByRateOfFire = 0.5 / (weapon.RateOfFire or 1)
        local intervalByRadius = (weapon.MaxRadius or 10) / 30
        weapon.TargetCheckInterval = math.min(intervalByRateOfFire, intervalByRadius)

        -- clamp value to something sane
        if weapon.TargetCheckInterval < 0.4 and (not isExperimental) then
            weapon.TargetCheckInterval = 0.4
        end

        -- clamp value to something sane
        if weapon.TargetCheckInterval < 0.2 then
            weapon.TargetCheckInterval = 0.2
        end

        -- clamp value to something sane
        if weapon.TargetCheckInterval > 3 then
            weapon.TargetCheckInterval = 3
        end
    end

    -- process target tracking radius 

    -- if it is set then we use that - allows us to make adjustments as we see fit
    if weapon.TrackingRadius == nil then
        -- by default, give every unit a 5% target checking radius
        weapon.TrackingRadius = 1.05

        -- remove target tracking radius for non-aa weaponry part of structures
        if isStructure and weapon.RangeCategory ~= "UWRC_AntiAir" then
            weapon.TrackingRadius = 1.0
        end

        -- give anti air a larger track radius
        if weapon.RangeCategory == "UWRC_AntiAir" then
            weapon.TrackingRadius = 1.15
        end

        -- add significant target checking radius for bombers
        if isBomber then 
            weapon.TrackingRadius = 1.25
        end
    end

    -- # process target rechecking

    -- if it is set then we use that - allows us to make adjustments as we see fit
    if weapon.AlwaysRecheckTarget == nil then

        -- by default, do not recheck targets as that is expensive when a lot of units are stacked on top of another
        weapon.AlwaysRecheckTarget = false

        -- allow 
        if  weapon.RangeCategory == 'UWRC_DirectFire' or
            weapon.RangeCategory == "UWRC_IndirectFire" or
            weapon.MaxRadius > 50 and (weapon.RangeCategory ~= "UWRC_AntiNavy") then
            weapon.AlwaysRecheckTarget = true
        end

        -- always allow anti air weapons attached to structures to retarget, as otherwise they may be stuck on a scout
        if isStructure and weapon.RangeCategory == "UWRC_AntiAir" then
            weapon.AlwaysRecheckTarget = true
        end

        -- always allow experimentals to retarget
        if isExperimental then
            weapon.AlwaysRecheckTarget = true
        end
    end

    -- # sanitize values

    -- do not allow the 'bomb weapon' of bombers to suddenly retarget, as then they won't drop their bomb when they do
    if weapon.NeedToComputeBombDrop then
        weapon.AlwaysRecheckTarget = false
    end

    weapon.TargetCheckInterval = 0.1 * math.floor(10 * weapon.TargetCheckInterval)
    weapon.TrackingRadius = 0.1 * math.floor(10 * weapon.TrackingRadius)
end

---@param units UnitBlueprint[]
function ProcessWeapons(units)
    local StringLower = string.lower

    local unitsToSkip = {
        daa0206 = true,
    }

    for _, unit in units do
        if not unitsToSkip[StringLower(unit.Blueprint.BlueprintId or "")] then
            if unit.Weapon then
                for _, weapon in unit.Weapon do
                    if not weapon.DummyWeapon then
                        ProcessWeapon(unit, weapon)
                    end
                end
            end
        end
    end
end
