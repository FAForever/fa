--****************************************************************************
--**
--**  File     :  /Env/Cybran/Props/CybranAdjacencyNodeTwo_script.lua
--**  Author(s):  Matt Vainio, Gordon Duclos
--**
--**  Summary  :  Cybran Adjacency Node Prop
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local Prop = import("/lua/sim/prop.lua").Prop

CybranAdjacencyNodeTwo = Class(Prop) {
    OnCreate = function(self)
        Prop.OnCreate(self)
        AttachBeamEntityToEntity( self, 'CybranAdjacencyNodeTwo01', self, 'CybranAdjacencyNodeTwo', -1, '/effects/emitters/adjacency_cybran_beam_01_emit.bp' )
    end,
}
TypeClass = CybranAdjacencyNodeTwo