--****************************************************************************
--**
--**  File     :  /lua/ScenarioStrings.lua
--**  Author(s):  Jessica St. Croix
--**
--**  Summary  :  Strings for use in scenarios
--**
--**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

-- -------------
-- Map Expansion
-- -------------
MapExpansion = {
    {text = '<LOC ScenStr_0000>Operation area expanded',},
}

-- --------------
-- New Objectives
-- --------------
NewObj = {
    {text = '<LOC ScenStr_0001>New objective',},
}
NewPObj = {
    {text = '<LOC ScenStr_0002>New primary objective',},
}
NewSObj = {
    {text = '<LOC ScenStr_0003>New secondary objective',},
}

-- --------------------
-- Completed Objectives
-- --------------------
ObjComp = {
    {text = '<LOC ScenStr_0004>Objective completed',},
}
PObjComp = {
    {text = '<LOC ScenStr_0005>Primary objective completed',},
}
SObjComp = {
    {text = '<LOC ScenStr_0006>Secondary objective completed',},
}
HObjComp = {
    {text = '<LOC ScenStr_0007>Hidden objective completed',},
}
BObjComp = {
    {text = '<LOC ScenStr_0008>Bonus objective completed',},
}

-- -----------------
-- Failed Objectives
-- -----------------
ObjFail = {
    {text = '<LOC ScenStr_0009>Objective failed',},
}
PObjFail = {
    {text = '<LOC ScenStr_0010>Primary objective failed',},
}
SObjFail = {
    {text = '<LOC ScenStr_0011>Secondary objective failed',},
}
-- -----------------------
-- Operation Progress
-- -----------------------
ObjProgress = '(%s/%s)'
-- ------------------
-- Updated Objectives
-- ------------------
ObjUpdate = {
    {text = '<LOC ScenStr_0012>Objective updated',},
}
PObjUpdate = {
    {text = '<LOC ScenStr_0013>Primary objective updated',},
}
SObjUpdate = {
    {text = '<LOC ScenStr_0014>Secondary objective updated',},
}

-- -----------------------------------
-- Mission Complete/Operation Complete
-- -----------------------------------
MissionSuccessDialogue = {
    {text = '<LOC ScenStr_0015>All Primary Objectives Completed. Mission Successful.',},
}
OperationSuccessDialogue = {
    {text = '<LOC ScenStr_0016>All Primary Objectives Completed. Operation Successful.',},
}

-- -----------------------
-- Operation Complete/Fail
-- -----------------------
OpComp = {
    {text = '<LOC ScenStr_0017>Operation completed',},
}
OpFail = {
    {text = '<LOC ScenStr_0018>Operation failed',},
}


-- -----------------------
-- Commander Killed
-- -----------------------
CDRKilled = {
    {text = '<LOC ScenStr_0019>Commander Destroyed. Mission Failed.',},
}

---------------------------
-- Needed aliases for player
---------------------------

-- '<LOC PlayerName>{g PlayerName}'
-- '<LOC CDR_Player>CDR {g PlayerName}'