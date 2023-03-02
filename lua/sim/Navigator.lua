--*****************************************************************************
--* File: lua/sim/Navigator.lua
--*
--* Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

NAVSTATUS = {
    Idle = 0,
    Thinking = 1,
    Steering = 2,
}

---@class Navigator: moho.navigator_methods
Navigator = Class(moho.navigator_methods) {}
