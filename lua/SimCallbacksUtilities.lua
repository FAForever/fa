-- local references, for some performance benefit?
-- SimCallbacks.lua used this, not sure if it still holds for imports?
local IsEntity = IsEntity
local GetEntityById = GetEntityById
local OkayToMessWithArmy = OkayToMessWithArmy
local TableInsert = table.insert

--- Utility function to retrieve actual unit entities.
-- @units Unit ids or unit entities to check. 
-- @checkarmy If only modifyable units should be returned, default = true.
-- @return A table of unit entities that are currently valid.
function SecureUnits(units, checkarmy)
    -- could add checkalive optional argument to only return alive units?
    if checkarmy == nil then checkarmy = true end

    local secure = {}
    if units and type(units) ~= 'table' then
        units = {units}
    end

    for _, u in units or {} do
        if not IsEntity(u) then
            u = GetEntityById(u)
        end
        -- verify again as GetEntityByID can return nil
        if IsEntity(u) then
            if checkarmy then
                if OkayToMessWithArmy(u.Army) then
                    TableInsert(secure, u)
                end
            else
                TableInsert(secure, u)
            end
        end
    end

    return secure
end