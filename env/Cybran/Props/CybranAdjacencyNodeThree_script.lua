--****************************************************************************
--**
--**  File     :  /Env/Cybran/Props/CybranAdjacencyNodeThree_script.lua
--**  Author(s):  Matt Vainio
--**
--**  Summary  :  Cybran Adjacency Node Prop
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local Prop = import("/lua/sim/prop.lua").Prop

CybranAdjacencyNodeThree = Class(Prop) {
    OnCreate = function(self)
        Prop.OnCreate(self)
        AttachBeamEntityToEntity( self, 'CybranAdjacencyNodeThree01', self, 'CybranAdjacencyNodeThree', -1, '/effects/emitters/adjacency_cybran_beam_01_emit.bp' )
        AttachBeamEntityToEntity( self, 'CybranAdjacencyNodeThree02', self, 'CybranAdjacencyNodeThree03', -1, '/effects/emitters/adjacency_cybran_beam_01_emit.bp' )
    end,
}
TypeClass = CybranAdjacencyNodeThree