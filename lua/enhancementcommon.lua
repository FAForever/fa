#****************************************************************************
#**  File     :  /lua/enhancementcommon.lua
#**  Author(s): Ted Snook
#**
#**  Summary  : Common enhancement functions for sim / user sides
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

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