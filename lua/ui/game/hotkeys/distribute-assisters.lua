-- upvalue scope for performance
local SelectUnits = SelectUnits
local SimCallback = SimCallback
local GetSelectedUnits = GetSelectedUnits

-- cached for performance
local GetAssistersAndTargets = import("/lua/shared/commands/distribute-assisters.lua").GetAssistersAndTargets

---@class DistributeAssistersData
---@field AssisterIds EntityId[]
---@field TargetIds EntityId[]

--- Distributes guard orders for selected assisters across the remaining selected units.
---@param assisterCategory? EntityCategory
---@param targetCategory? EntityCategory
function DistributeAssisters(assisterCategory, targetCategory)
    local selection = GetSelectedUnits()

    if selection then
        local assisters, targets = GetAssistersAndTargets(selection, assisterCategory, targetCategory)

        if assisters[1] and targets[1] then
            local assisterIds = {}
            local targetIds = {}

            for i = 1, table.getn(assisters) do
                assisterIds[i] = assisters[i]:GetEntityId()
            end
            for i = 1, table.getn(targets) do
                targetIds[i] = targets[i]:GetEntityId()
            end

            print(string.format("%d assisters assisting %d units", table.getn(assisters), table.getn(targets)))
            SimCallback({
                Func = 'DistributeAssisters',
                Args = {
                    AssisterIds = assisterIds,
                    TargetIds = targetIds,
                },
            })
            SelectUnits(targets)
        end
    end
end
