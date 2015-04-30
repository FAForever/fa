#****************************************************************************
#**
#**  File     :  /cdimage/units/UEA0203/UEA0203_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix, Gordon Duclos
#**
#**  Summary  :  UEF Gunship Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local TAirUnit = import('/lua/terranunits.lua').TAirUnit
local TDFRiotWeapon = import('/lua/terranweapons.lua').TDFRiotWeapon

UEA0203 = Class(TAirUnit) {
    EngineRotateBones = {'Jet_Front', 'Jet_Back',},

    Weapons = {
        Turret01 = Class(TDFRiotWeapon) {},
    },

    OnStopBeingBuilt = function(self,builder,layer)
        TAirUnit.OnStopBeingBuilt(self,builder,layer)
        self.EngineManipulators = {}

        # create the engine thrust manipulators
        for key, value in self.EngineRotateBones do
            table.insert(self.EngineManipulators, CreateThrustController(self, "thruster", value))
        end

        # set up the thursting arcs for the engines
        for key,value in self.EngineManipulators do
            #                          XMAX, XMIN, YMAX,YMIN, ZMAX,ZMIN, TURNMULT, TURNSPEED
            value:SetThrustingParam( -0.0, 0.0, -0.25, 0.25, -0.1, 0.1, 1.0,      0.25 )
        end
        
        for k, v in self.EngineManipulators do
            self.Trash:Add(v)
        end

    end,
    
    OnTransportAttach = function(self, attachBone, unit)
        TAirUnit.OnTransportAttach(self, attachBone, unit)
        if not self.AttachedUnits then
            self.AttachedUnits = {}
        end
        table.insert( self.AttachedUnits, unit )
    end,
    
    OnTransportDetach = function(self, attachBone, unit)
        TAirUnit.OnTransportDetach( self, attachBone, unit )
        if self.AttachedUnits then
            for k,v in self.AttachedUnits do
                if v == unit then
                    self.AttachedUnits[k] = nil
                    break
                end                    
            end
        end
    end,
    
    DestroyedOnTransport = function(self)
        if self.AttachedUnits then
            for k,v in self.AttachedUnits do
                v:Destroy()
            end
        end
    end,
}

TypeClass = UEA0203