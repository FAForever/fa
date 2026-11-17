--****************************************************************************
--**  File     :  /lua/enhancementcommon.lua
--**  Author(s): Ted Snook
--**
--**  Summary  : Common enhancement functions for sim / user sides
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

---@alias EnhancementBuffType
---| ACUEnhancementBuffType
---| SCUEnhancementBuffType
---@alias ACUEnhancementBuffType
---| AeonACUEnhancementBuffType
---| CybranACUEnhancementBuffType
---| UEFACUEnhancementBuffType
---| SeraphimACUEnhancementBuffType
---@alias SCUEnhancementBuffType
---| AeonSCUEnhancementBuffType
---| CybranSCUEnhancementBuffType
---| UEFSCUEnhancementBuffType
---| SeraphimSCUEnhancementBuffType

-- These buffs are only created when needed
---@alias EnhancementBuffName
---| ACUEnhancementBuffName
---| SCUEnhancementBuffName
---@alias ACUEnhancementBuffName
---| AeonACUEnhancementBuffName
---| CybranACUEnhancementBuffName
---| UEFACUEnhancementBuffName
---| SeraphimACUEnhancementBuffName
---@alias SCUEnhancementBuffName
---| AeonSCUEnhancementBuffName
---| CybranSCUEnhancementBuffName
---| UEFSCUEnhancementBuffName
---| SeraphimSCUEnhancementBuffName

---@type EnhancementSyncTable
local enhancementTable = {}
---@type table<Enhancement, true>
local restrictedList = {}

---@param table EnhancementSyncTable
function SetEnhancementTable(table)
    enhancementTable = table
end

---@param table table<Enhancement, true>
function RestrictList(table)
    restrictedList = table
end

---@return table<Enhancement, true>
function GetRestricted()
    return restrictedList
end

---@param entityID EntityId
---@return EnhancementSyncData?
function GetEnhancements(entityID)
    return enhancementTable[tostring(entityID)]
end