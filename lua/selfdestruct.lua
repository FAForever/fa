local ipairs = ipairs
local OkayToMessWithArmy = OkayToMessWithArmy
local tableEmpty = table.empty
local KillThread = KillThread
local unit_methodsGetWeapon = moho.unit_methods.GetWeapon
local GetEntityById = GetEntityById
local ForkThread = ForkThread
local tableInsert = table.insert
local next = next

function ToggleSelfDestruct(data)
    -- Suppress self destruct in tutorial missions as they screw up the mission end
    if ScenarioInfo.tutorial and ScenarioInfo.tutorial == true then
        return
    end

    if data.owner ~= -1 then
        local unitEntities = {}
        for _, unitId in data.units do
            local unit = GetEntityById(unitId)
            if OkayToMessWithArmy(unit.Army) then
                tableInsert(unitEntities, unit)
            end
        end
        if not tableEmpty(unitEntities) then
            if data.noDelay then -- Kill these units instantly
                for _, unit in unitEntities do
                    if unit:BeenDestroyed() or unit.Dead then return end

                    FireSelfdestructWeapons(unit)
                    unit.SelfDestructed = true
                    unit:Kill()
                end
            else
                local togglingOff = false
                for _, unit in unitEntities do -- Rescue anything in the process of dying, and skip the next bit
                    if unit.SelfDestructThread then
                        togglingOff = true
                        KillThread(unit.SelfDestructThread)
                        unit.SelfDestructThread = false
                        CancelCountdown(unit.EntityId)
                    end
                end

                if not togglingOff then
                    for _, unitEnt in unitEntities do
                        local unit = unitEnt

                        -- Unit and weapon bp flags can be used to control behaviour on SelfDestruct
                        -- Instant kill if InstantDeathOnSelfDestruct = true variable set in units general table
                        -- Fires weapons with FireOnSelfDestruct = true in units weapon table
                        local bp = unit:GetBlueprint()
                        if bp.General.InstantDeathOnSelfDestruct then
                            FireSelfdestructWeapons(unit)
                            unit.SelfDestructed = true
                            unit:Kill()
                        else
                            -- Regular self destruct cycle
                            StartCountdown(unit.EntityId)
                            unit.SelfDestructThread = ForkThread(function()
                                WaitSeconds(5)
                                if unit:BeenDestroyed() then return end
                                FireSelfdestructWeapons(unit)
                                unit.SelfDestructed = true
                                unit:Kill()
                            end)
                        end
                    end
                end
            end
        end
    end
end

function FireSelfdestructWeapons(unit)
    local wepCount = unit:GetWeaponCount()
    for i = 1, wepCount do
        local wep = unit_methodsGetWeapon(unit, i)
        local wepBP = wep:GetBlueprint()
        if wepBP.FireOnSelfDestruct then
            if wep.Fire then
                wep.Fire()
            else
                wep.OnFire(wep)
            end
        end
    end
end
