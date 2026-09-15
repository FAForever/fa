-- upvalue scope for performance
local SelectUnits = SelectUnits
local SimCallback = SimCallback
local GetSelectedUnits = GetSelectedUnits
local EntityCategoryFilterDown = EntityCategoryFilterDown
local EntityCategoryFilterOut = EntityCategoryFilterOut

local TableEmpty = table.empty

-- cached for performance
local CategoriesAssisters = categories.BUILTBYTIER3FACTORY * (
    categories.MOBILE * categories.SHIELD
    + categories.SCOUT
    + categories.STEALTHFIELD
)

--- Distributes guard orders for selected assisters across the remaining selected units.
function DistributeAssisters()
    local selection = GetSelectedUnits()

    if selection then
        local assisters = EntityCategoryFilterDown(CategoriesAssisters, selection)
        local targets = EntityCategoryFilterOut(CategoriesAssisters, selection)

        if not TableEmpty(assisters) and not TableEmpty(targets) then
            SimCallback({ Func = 'DistributeAssisters', Args = {} }, true)
            SelectUnits(targets)
        end
    end
end
