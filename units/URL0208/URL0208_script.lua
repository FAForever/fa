--****************************************************************************
--**
--**  File     :  /cdimage/units/URL0208/URL0208_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Cybran Tier 2 Engineer Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CConstructionUnit = import("/lua/cybranunits.lua").CConstructionUnit

---@class URL0208 : CConstructionUnit
URL0208 = ClassUnit(CConstructionUnit) {
    Treads = {
        ScrollTreads = true,
        BoneName = 'URL0208',
        TreadMarks = 'tank_treads_albedo',
        TreadMarksSizeX = 0.65,
        TreadMarksSizeZ = 0.4,
        TreadMarksInterval = 0.3,
        TreadOffset = { 0, 0, 0 },
    },
}

TypeClass = URL0208