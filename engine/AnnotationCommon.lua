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
function Destroyable:OnDestroy() end

---@class OnDirtyListener
local OnDirtyListener = {}
function OnDirtyListener:OnDirty() end
