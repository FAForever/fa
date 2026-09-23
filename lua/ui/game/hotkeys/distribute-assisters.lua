-- upvalue scope for performance
local SelectUnits = SelectUnits
local SimCallback = SimCallback
local GetSelectedUnits = GetSelectedUnits

-- cached for performance
local GetAssistersAndTargets = import("/lua/shared/commands/distribute-assisters.lua").GetAssistersAndTargets

--- Distributes guard orders for selected assisters across the remaining selected units.
function DistributeAssisters()
    local selection = GetSelectedUnits()

    if selection then
        local assisters, targets = GetAssistersAndTargets(selection)

        if assisters[1] and targets[1] then
            print(string.format("%d assisters assisting %d units", table.getn(assisters), table.getn(targets)))
            SimCallback({ Func = 'DistributeAssisters', Args = {} }, true)
            SelectUnits(targets)
        end
    end
end
