function ToggleSelfDestruct(data)
    -- supress self destruct in tutorial missions as they screw up the mission end
    if ScenarioInfo.tutorial and ScenarioInfo.tutorial == true then
        return
    end
    if data.owner != -1 then
        local unitEntities = {}
        for _, unitId in data.units do
            local unit = GetEntityById(unitId)
            if OkayToMessWithArmy(unit:GetArmy()) then
                table.insert(unitEntities, unit)
            end
        end
        if table.getsize(unitEntities) > 0 then
            local togglingOff = false
            for _, unit in unitEntities do
                if unit.SelfDestructThread then
                    togglingOff = true
                    KillThread(unit.SelfDestructThread)
                    unit.SelfDestructThread = false
                    local entityId = unit:GetEntityId()
                    CancelCountdown(entityId)
                end
            end
            if not togglingOff then
                for _, unitEnt in unitEntities do
                    local unit = unitEnt

                    # added by brute51 - makes selfdestruct alterable through BP files
                    # instant kill if InstantDeathOnSelfDestruct = true variable set in units general table
                    # fires weapons with FireOnSelfDestruct = true in units weapon table

                    local bp = unit:GetBlueprint()
                    if bp.General.InstantDeathOnSelfDestruct then
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
                        unit:Kill()
                    else

                    # regular self destruct cycle
                        local entityId = unit:GetEntityId()
                        StartCountdown(entityId)
                        unit.SelfDestructThread = ForkThread(function()
                            WaitSeconds(5)
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
                            unit:Kill()
                        end)
                    end


                end
            end
        end
    end
end

