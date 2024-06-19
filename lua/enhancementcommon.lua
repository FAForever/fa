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
--| UEFSCUEnhancementBuffType # there are none
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
--| UEFSCUEnhancementBuffName # there are none
---| SeraphimSCUEnhancementBuffName


local enhancementTable = {}
local restrictedList = {}

function SetEnhancementTable(entry)
    enhancementTable = entry
end

function RestrictList(table)
    restrictedList = table
end

function GetRestricted()
    return restrictedList
end

function GetEnhancements(entityID)
    return enhancementTable[tostring(entityID)]
end