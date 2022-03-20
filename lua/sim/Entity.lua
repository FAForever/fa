#****************************************************************************
#**  File     :  /lua/sim/Entity.lua
#**  Summary  : The Entity lua module
#**
#**  Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

Entity = Class(moho.entity_methods) {

    --- Called when the entity is created
    -- @param self The entity itself
    -- @param spec The specifications of the entity
    -- -  if 'spec.Owner' is set to a unit then the visibility of the entity matches that of the unit 
    __init = function(self, spec)
        _c_CreateEntity(self, spec)
    end,

    __post_init = function(self, spec)
        self:OnCreate(spec)
    end,

    OnCreate = function(self, spec)
        self.Spec = spec
        self.EntityId = self:GetEntityId()
        self.Army = self:GetArmy()
    end,

    OnDestroy = function(self)

    end,
}
