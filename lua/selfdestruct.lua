
local OkayToMessWithArmy = OkayToMessWithArmy
local StartCountdown = StartCountdown
local CancelCountdown = CancelCountdown
local ForkThread = ForkThread
local KillThread = KillThread

-- prevent magic numbers
local countdownDuration = 5

--- Destroys the given unit after a set duration
---@param unit Unit
local function SelfDestructThread(unit)
    WaitSeconds(countdownDuration)
    if unit:BeenDestroyed() then
        return
    end

    unit:Kill()
end

--- Toggles the destruction of the units
---@param data { owner: number, noDelay: boolean, allUnits: boolean }
---@param units Unit[]
function ToggleSelfDestruct(data, units)

    -- suppress self destruct in tutorial missions as they screw up the mission end
    if ScenarioInfo.tutorial and ScenarioInfo.tutorial == true then
        return
    end

    -- do not allow observers to use this
    if data.owner ~= -1 and OkayToMessWithArmy(data.owner) then

        -- if we want to destroy all units
        if data.allUnits then
            units = GetArmyBrain(data.owner):GetListOfUnits(categories.ALLUNITS, false, false)
        end

        -- just take them all out
        if data.noDelay then
            for _, unit in units do
                if OkayToMessWithArmy(unit.Army) then
                    if not (unit.Dead or unit:BeenDestroyed()) then
                        unit:Kill()
                    end
                end
            end

        -- wait a few seconds, then destroy
        else

            -- if one is in the process of being destroyed, remove all destruction threads
            local togglingOff = false
            for _, unit in units do
                if OkayToMessWithArmy(unit.Army) then
                    if unit.SelfDestructThread then
                        togglingOff = true
                        KillThread(unit.SelfDestructThread)
                        unit.SelfDestructThread = false
                        CancelCountdown(unit.EntityId) -- as defined in SymSync.lua
                    end
                end
            end

            -- if none are in the process of being destroyed, destroy them after a delay
            if not togglingOff then
                for _, unit in units do
                    if OkayToMessWithArmy(unit.Army) then

                        -- allows fire beetle to be destroyed immediately
                        if unit.Blueprint.General.InstantDeathOnSelfDestruct then
                            unit:Kill()

                            -- destroy everything else after five seconds
                        else
                            StartCountdown(unit.EntityId, countdownDuration) -- as defined in SymSync.lua
                            unit.SelfDestructThread = ForkThread(SelfDestructThread, unit)
                        end
                    end
                end
            end
        end
    end
end
