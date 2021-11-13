#****************************************************************************
#**  File     :  /lua/sim/Entity.lua
#**  Summary  : The Entity lua module
#**
#**  Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local entity_methodsGetEntityId = moho.entity_methods.GetEntityId
local entity_methodsGetArmy = moho.entity_methods.GetArmy

Entity = Class(moho.entity_methods) {

    __init = function(self,spec)
        _c_CreateEntity(self,spec)
    end,

    __post_init = function(self,spec)
        self:OnCreate(spec)
    end,

    OnCreate = function(self,spec)
        self.Spec = spec
        self.EntityId = entity_methodsGetEntityId(self)
        self.Army = entity_methodsGetArmy(self)
    end,

    OnDestroy = function(self)

    end,
}
