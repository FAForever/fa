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
-- us from scoping this as an upvalue as this function doesn't exist UI-side.
-- local _c_CreateEntity = _c_CreateEntity


--- This class is only a Lua encapsulation for the basic abstract entity object
--- provided by the engine. Even though units, props, and projectiles are
--- considered entities, they do not inherit this class through Lua because the
--- heirarchy starts in the engine and it provides to us its own set of methods
--- for those kinds of objects for us to create base classes for.
---
--- That means this class should only be used for light-weight objects that
--- still require a C-object, but aren't units, props, projectile etc, such as
--- vision markers, flares, or other effects. 
---@class Entity : moho.entity_methods, InternalObject
Entity = Class(moho.entity_methods) {

    --- Called during class initialization
    ---@param self Entity
    ---@param spec? EntitySpec specs to resolve owner's army index from; defaults to resolving to -1
    __init = function(self, spec)
        -- An unnecessary, but informative comment that fits nowhere else:

        -- This cfunction requires exactly two arguments to be passed into it
        -- or else it will complain. However, it can literally be anything
        -- including nil, so the spec arg ends up being optional (as it will be
        -- adjusted to nil). This is a general quirk of how cfunctions have to
        -- be written explicitly to require a certain number of arguments, and
        -- isn't particular to this cfunction.
        --
        --    _c_CreateEntity(self, nil) -- fine, owner resolves to -1
        --    _c_CreateEntity(self)      -- complains
        --
        -- The only way you could possibly emulate this kind of behavior in Lua
        -- is with 5.0's odd way of handling variadic functions; the generated
        -- `arg` local variable stores the exact number of arguments passed in
        -- the `n` field.
        _c_CreateEntity(self, spec)
    end,

    ---@param self Entity
    ---@param spec? EntitySpec
    __post_init = function(self, spec)
        self:OnCreate(spec)
    end,

    --- kept for backwards compatibility with mods
    ---@param self Entity
    ---@param spec? EntitySpec
    OnCreate = function(self, spec)
    end,

    ---@param self Entity
    OnDestroy = function(self)
    end,
}
