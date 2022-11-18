--**************************************************************************************************
--** Shared under the MIT license
--**************************************************************************************************
---@meta

---@class EntityCategory : userdata, moho.EntityCategory
---@operator add(EntityCategory): EntityCategory
---@operator mul(EntityCategory): EntityCategory
---@operator sub(EntityCategory): EntityCategory

---@class moho.EntityCategory
local EntityCategory = {}

---@alias UnparsedCategory string

--- Return the union between two categories
---@param augend moho.EntityCategory
---@param addend moho.EntityCategory
---@return moho.EntityCategory
function EntityCategory.__add(augend, addend)
end

--- Return the intersection between two categories
---@param multiplier moho.EntityCategory
---@param multiplicand moho.EntityCategory
---@return moho.EntityCategory
function EntityCategory.__mul(multiplier, multiplicand)
end

--- Return the relative complement (set subtraction) of `minuend` over `subtrahend`
---@param minuend moho.EntityCategory
---@param subtrahend moho.EntityCategory
---@return moho.EntityCategory
function EntityCategory.__sub(minuend, subtrahend)
end

return EntityCategory