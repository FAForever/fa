-- upvalue globals for performance
local IsEntity = IsEntity
local GetEntityById = GetEntityById
local OkayToMessWithArmy = OkayToMessWithArmy

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

    local index = 1
    for _, u in units or {} do
        if not IsEntity(u) then
            u = GetEntityById(u)
        end
        -- verify again as GetEntityByID can return nil
        if IsEntity(u) then
            if checkarmy then
                if OkayToMessWithArmy(u.Army) then
                    secure[index] = u
                    index = index + 1
                end
            else
                secure[index] = u
                index = index + 1
            end
        end
    end

    return secure
end
