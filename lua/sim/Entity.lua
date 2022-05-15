--****************************************************************************
--**  File     :  /lua/sim/Entity.lua
--**  Summary  : The Entity lua module
--**
--**  Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

-- From a performance perspective any changes to this file is strictly 
-- forbidden - if you do intend to make changes please contact the 
-- administrator of the repository to discuss your changes before assuming
-- that your changes will get merged in.

-- This file gets imported by UI mods sometimes, not sure why. But it prevents 
-- us from scoping this as an upvalue
-- local _c_CreateEntity = _c_CreateEntity 

Entity = Class(moho.entity_methods) {

    --- Called during class initialisation
    -- @param self The entity itself
    -- @param spec The specifications of the entity
    -- -  if 'spec.Owner' is set to a unit then the visibility of the entity matches that of the unit 
    __init = function(self, spec)
        _c_CreateEntity(self, spec)
    end,

    __post_init = function(self, spec)
        self.OnCreate(self, spec)
    end,

    -- kept for backwards compatibility with mods
    OnCreate = function(self, spec) end,
    OnDestroy = function(self) end,
}
