
local GetEntityById = GetEntityById
local OkayToMessWithArmy = OkayToMessWithArmy

function ToggleSelfDestruct(data)
    -- Suppress self destruct in tutorial missions as they screw up the mission end
    if ScenarioInfo.tutorial and ScenarioInfo.tutorial == true then
        return
    end

    if data.owner ~= -1 then

        -- find and take them out
        for _, unitId in data.units do
            local unit = GetEntityById(unitId)
            if OkayToMessWithArmy(unit.Army) then
                if not (unit.Dead or unit:BeenDestroyed()) then 
                    unit:Kill()
                end
            end
        end
    end
end