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
--- Called by engine for UnitWeapon, ScriptTask, Entity, Platoon, MauiControl
---@type nil | fun(self: Destroyable)
Destroyable.OnDestroy = nil

---@class OnDirtyListener
local OnDirtyListener = {}
function OnDirtyListener:OnDirty() end
