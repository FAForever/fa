-- Automatically upvalued moho functions for performance
local EntityMethods = _G.moho.entity_methods
local EntityMethodsAttachBoneTo = EntityMethods.AttachBoneTo
local EntityMethodsEnableIntel = EntityMethods.EnableIntel
local EntityMethodsInitIntel = EntityMethods.InitIntel
local EntityMethodsRequestRefreshUI = EntityMethods.RequestRefreshUI

local GlobalMethods = _G
local GlobalMethodsCreateRotator = GlobalMethods.CreateRotator

local UnitMethods = _G.moho.unit_methods
local UnitMethodsSetScriptBit = UnitMethods.SetScriptBit
-- End of automatically upvalued moho functions

--#****************************************************************************
--#**
--#**  File     :  /cdimage/units/URL0101/URL0101_script.lua
--#**  Author(s):  John Comes, David Tomandl
--#**
--#**  Summary  :  Cybran Land Scout Script
--#**
--#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--#****************************************************************************
local CWalkingLandUnit = import('/lua/cybranunits.lua').CWalkingLandUnit
local Entity = import('/lua/sim/Entity.lua').Entity

URL0101 = Class(CWalkingLandUnit)({
    OnStopBeingBuilt = function(self, builder, layer)
        CWalkingLandUnit.OnStopBeingBuilt(self, builder, layer)
        --entity used for radar
        local bp = self:GetBlueprint()
        self.RadarEnt = Entity({})
        self.Trash:Add(self.RadarEnt)
        EntityMethodsInitIntel(self.RadarEnt, self.Army, 'Radar', bp.Intel.RadarRadius)
        EntityMethodsEnableIntel(self.RadarEnt, 'Radar')
        EntityMethodsAttachBoneTo(self.RadarEnt, -1, self, 0)
        --antena spinner
        GlobalMethodsCreateRotator(self, 'Spinner', 'y', nil, 90, 5, 90)
        --enable cloaking economy
        self:SetMaintenanceConsumptionInactive()
        UnitMethodsSetScriptBit(self, 'RULEUTC_CloakToggle', true)
        EntityMethodsRequestRefreshUI(self)
    end,
})

TypeClass = URL0101
