--******************************************************************************************************
--** Copyright (c) 2024 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

local DirectFireFirst = import("/lua/shared/Formations/FormationGroups.lua").LandDirectFireFirst
local MissileFirst = import("/lua/shared/Formations/FormationGroups.lua").LandMissileFirst
local ArtilleryFirst = import("/lua/shared/Formations/FormationGroups.lua").LandArtilleryFirst
local ShieldFirst = import("/lua/shared/Formations/FormationGroups.lua").LandShieldFirst
local SniperFirst = import("/lua/shared/Formations/FormationGroups.lua").LandSniperFirst
local AntiAirFirst = import("/lua/shared/Formations/FormationGroups.lua").LandAntiAirFirst
local CounterintelligenceFirst = import("/lua/shared/Formations/FormationGroups.lua").LandCounterintelligenceFirst
local IntelligenceFirst = import("/lua/shared/Formations/FormationGroups.lua").LandIntelligenceFirst
local EngineeringFirst = import("/lua/shared/Formations/FormationGroups.lua").LandEngineeringFirst

--- A small attack formation for up to 27 units.
SmallLandFormation = {
    [1] = {
        DirectFireFirst, -- 1 y
        DirectFireFirst, -- 2 y
        DirectFireFirst, -- 3 y
        DirectFireFirst, -- 4 y
        DirectFireFirst, -- 5 y
        DirectFireFirst, -- 6 y
        DirectFireFirst, -- 7 y
        DirectFireFirst, -- 8 y
        DirectFireFirst -- 9 y
    },
    [2] = {
        DirectFireFirst, -- 10 y
        MissileFirst, -- 11 y
        ShieldFirst, -- 12 y
        AntiAirFirst, -- 13 y
        CounterintelligenceFirst, -- 14 y
        AntiAirFirst, -- 15 n
        ShieldFirst, -- 16 y
        MissileFirst, -- 17 n
        DirectFireFirst -- 18 y
    },
    [3] = {
        DirectFireFirst, -- 19 y
        IntelligenceFirst, -- 20 y
        ArtilleryFirst, -- 21 n
        SniperFirst, -- 22 n
        EngineeringFirst, -- 23 n
        SniperFirst, -- 24 ?
        ArtilleryFirst, -- 25 y
        IntelligenceFirst, -- 26 y
        DirectFireFirst -- 27
    },
}
