--****************************************************************************
--**  File     :  /lua/sim/Entity.lua
--**  Summary  : The Entity lua module
--**
--**  Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

-- From a performance perspective any changes to this file is strictly forbidden.

-- We can't scope this as an upvalue because this file is touched upon by UI code.
-- - unitview.lua -> import of game.lua (ui file)
-- - game.lua -> import of BuffField.lua (sim file)
-- - BuffField.lua -> import of Entity (sim file)
-- local _c_CreateEntity = _c_CreateEntity 

Entity = Class(moho.entity_methods) {

    --- Called when the entity is allocated
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
