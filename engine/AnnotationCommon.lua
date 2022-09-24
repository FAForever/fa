---@meta

---@alias nonnil boolean | number | thread | table | string | userdata | lightuserdata | function

---@alias Function<T, R> fun(arg: T): R
---@alias Supplier<T> fun(): T
---@alias Consumer<T> fun(arg: T)

---@alias BiFunction<T, U, R> fun(arg1: T, arg2: U): R
---@alias BiConsumer<T> fun(arg1: T, arg2: U)
---@alias BiSupplier<T, U> fun(): T, U

---@alias Predicate<T> Function<T, boolean>
---@alias BiPredicate<T, U> BiFunction<T, U, boolean>

---@class cfunction : function
---@class CScriptObject : userdata

---@class InternalObject : Destroyable
---@field _c_object CScriptObject

---@class Destroyable
local Destroyable = {}
function Destroyable:Destroy() end
function Destroyable:OnDestroy() end

---@class OnDirtyListener
local OnDirtyListener = {}
function OnDirtyListener:OnDirty() end
