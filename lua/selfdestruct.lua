
local GetEntityById = GetEntityById
local OkayToMessWithArmy = OkayToMessWithArmy
local StartCountdown = StartCountdown
local CancelCountdown = CancelCountdown
local ForkThread = ForkThread
local KillThread = KillThread

local TableInsert = table.insert


-- prevent magic numbers
local countdownDuration = 5

function ToggleSelfDestruct(data)
    -- suppress self destruct in tutorial missions as they screw up the mission end
    if ScenarioInfo.tutorial and ScenarioInfo.tutorial == true then
        return
    end

    -- do not allow observers to use this
    if data.owner ~= -1 then

        -- just take them all out
        if data.noDelay then 
            for _, unitId in data.units do
                local unit = GetEntityById(unitId)
                if OkayToMessWithArmy(unit.Army) then
                    if not (unit.Dead or unit:BeenDestroyed()) then 
                        unit:Kill()
                    end
                end
            end

        -- wait a few seconds, then destroy
        else 

            -- gather units
            local unitEntities = { }
            for _, unitId in data.units do
                local unit = GetEntityById(unitId)
                if OkayToMessWithArmy(unit.Army) then
                    TableInsert(unitEntities, unit)
                end
            end

            -- if one is in the process of being destroyed, remove all destruction threads
            local togglingOff = false
            for _, unit in unitEntities do
                if unit.SelfDestructThread then
                    togglingOff = true
                    KillThread(unit.SelfDestructThread)
                    unit.SelfDestructThread = false
                    CancelCountdown(unit.EntityId)                          -- as defined in SymSync.lua
                end
            end

            -- if none are in the process of being destroyed, destroy them after a delay
            if not togglingOff then
                for _, unit in unitEntities do

                    -- allows fire beetle to be destroyed immediately
                    if unit.Blueprint.General.InstantDeathOnSelfDestruct then 
                        unit:Kill()

                    -- destroy everything else after five seconds
                    else 
                        StartCountdown(unit.EntityId, countdownDuration)    -- as defined in SymSync.lua
                        unit.SelfDestructThread = ForkThread(
                            function(unit)
                                WaitSeconds(countdownDuration)
                                if unit:BeenDestroyed() then 
                                    return 
                                end

                                unit:Kill()
                            end,
                            unit 
                        )
                    end
                end
            end
        end
    end
end