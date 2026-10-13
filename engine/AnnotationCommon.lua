--**************************************************************************************************
--** Shared under the MIT license
--**************************************************************************************************
---@meta

---@alias nonnil boolean | number | thread | table | string | userdata | lightuserdata | function

---@class cfunction : function
---@class CScriptObject : userdata

---@class InternalObject : Destroyable
---@field _c_object CScriptObject

---@class Destroyable
local Destroyable = {}
function Destroyable:Destroy() end

--- Called by the engine when an engine object (entity, UI control, platoon, weapon, ...) is
--- destroyed. Entities get it from the deletion queue at the end of the tick. Lua classes that
--- only implement `Destroyable` call it themselves.
---@type nil | fun(self: Destroyable)
Destroyable.OnDestroy = nil

---@class OnDirtyListener
local OnDirtyListener = {}
function OnDirtyListener:OnDirty() end
