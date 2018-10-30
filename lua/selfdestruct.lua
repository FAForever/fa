function ToggleSelfDestruct(data)
    -- Suppress self destruct in tutorial missions as they screw up the mission end
    if ScenarioInfo.tutorial and ScenarioInfo.tutorial == true then
        return
    end

    if data.owner ~= -1 then
        local unitEntities = {}
        for _, unitId in data.units do
            local unit = GetEntityById(unitId)
            if OkayToMessWithArmy(unit:GetArmy()) then
                table.insert(unitEntities, unit)
            end
        end

        local off = false
        for _, unit in unitEntities do
            if data.noDelay or unit:GetBlueprint().General.InstantDeathOnSelfDestruct then -- Kill these units instantly
                TriggerDestruction(unit)
            elseif unit.SelfDestructThread then
                KillThread(unit.SelfDestructThread)
                unit.SelfDestructThread = false
                CancelCountdown(unit:GetEntityId())

                off = true
            end
        end

        if off then return end

        -- Begin regular self destruct cycle
        for _, unit in unitEntities do
            if unit:BeenDestroyed() or unit.Dead then continue end

            local u = unit -- Save the looped entity for the forked thread to work
            StartCountdown(u:GetEntityId())
            u.SelfDestructThread = ForkThread(
            function()
                WaitTicks(50)
                TriggerDestruction(u)
            end)
        end
    end
end

function TriggerDestruction(unit)
    if unit:BeenDestroyed() or unit.Dead then return end

    FireSelfdestructWeapons(unit)
    unit:Kill()
end

function FireSelfdestructWeapons(unit)
    local wepCount = unit:GetWeaponCount()
    for i = 1, wepCount do
        local wep = unit:GetWeapon(i)
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
