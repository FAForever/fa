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

local Debug = true

local DirectFireFirst = import("/lua/shared/Formations/FormationGroups.lua").LandDirectFireFirst
local MissileFirst = import("/lua/shared/Formations/FormationGroups.lua").LandMissileFirst
local ArtilleryFirst = import("/lua/shared/Formations/FormationGroups.lua").LandArtilleryFirst
local ShieldFirst = import("/lua/shared/Formations/FormationGroups.lua").LandShieldFirst
local SniperFirst = import("/lua/shared/Formations/FormationGroups.lua").LandSniperFirst
local AntiAirFirst = import("/lua/shared/Formations/FormationGroups.lua").LandAntiAirFirst
local CounterintelligenceFirst = import("/lua/shared/Formations/FormationGroups.lua").LandCounterintelligenceFirst
local IntelligenceFirst = import("/lua/shared/Formations/FormationGroups.lua").LandIntelligenceFirst
local EngineeringFirst = import("/lua/shared/Formations/FormationGroups.lua").LandEngineeringFirst

OneRowLandFormation = {
    Identifier = 'OneRowLandFormation',
    [1] = {
        DirectFireFirst,
        DirectFireFirst,
        ArtilleryFirst,
        IntelligenceFirst,
        ArtilleryFirst,
        DirectFireFirst,
        DirectFireFirst
    },
}

TwoRowLandFormation = {
    Identifier = 'TwoRowLandFormation',
    [1] = {
        DirectFireFirst,
        DirectFireFirst,
        DirectFireFirst,
        DirectFireFirst,
        DirectFireFirst,
        DirectFireFirst,
        DirectFireFirst
    },
    [2] = {
        DirectFireFirst,
        MissileFirst,
        AntiAirFirst,
        CounterintelligenceFirst,
        AntiAirFirst,
        MissileFirst,
        DirectFireFirst
    },
}

ThreeRowLandFormation = {
    Identifier = 'ThreeRowLandFormation',
    [1] = {
        DirectFireFirst,
        DirectFireFirst,
        DirectFireFirst,
        DirectFireFirst,
        DirectFireFirst,
        DirectFireFirst,
        DirectFireFirst,
        DirectFireFirst,
        DirectFireFirst
    },
    [2] = {
        DirectFireFirst,
        MissileFirst,
        ShieldFirst,
        AntiAirFirst,
        CounterintelligenceFirst,
        AntiAirFirst,
        ShieldFirst,
        MissileFirst,
        DirectFireFirst
    },
    [3] = {
        DirectFireFirst,
        IntelligenceFirst,
        ArtilleryFirst,
        SniperFirst,
        EngineeringFirst,
        SniperFirst,
        ArtilleryFirst,
        IntelligenceFirst,
        DirectFireFirst
    },
}

FourRowLandFormation = {
    Identifier = 'FourRowLandFormation',
    [1] = {
        DirectFireFirst,
        DirectFireFirst,
        DirectFireFirst,
        DirectFireFirst,
        DirectFireFirst,
        DirectFireFirst,
        DirectFireFirst,
        DirectFireFirst,
        DirectFireFirst,
        DirectFireFirst,
        DirectFireFirst
    },
    [2] = {
        DirectFireFirst,
        DirectFireFirst,
        MissileFirst,
        ShieldFirst,
        AntiAirFirst,
        CounterintelligenceFirst,
        AntiAirFirst,
        ShieldFirst,
        MissileFirst,
        DirectFireFirst,
        DirectFireFirst,
    },
    [3] = {
        DirectFireFirst,
        IntelligenceFirst,
        ArtilleryFirst,
        ArtilleryFirst,
        SniperFirst,
        EngineeringFirst,
        SniperFirst,
        ArtilleryFirst,
        ArtilleryFirst,
        IntelligenceFirst,
        DirectFireFirst
    },
    [4] = {
        DirectFireFirst,
        IntelligenceFirst,
        ArtilleryFirst,
        MissileFirst,
        SniperFirst,
        EngineeringFirst,
        SniperFirst,
        MissileFirst,
        ArtilleryFirst,
        IntelligenceFirst,
        DirectFireFirst
    },
}

LandFormations = {
    OneRowLandFormation,
    TwoRowLandFormation,
    ThreeRowLandFormation,
    FourRowLandFormation,
}

for k = 1, table.getn(LandFormations) do
    local formation = LandFormations[k]

    -- compute the number of units in the formation
    local count = 0
    for r = 1, table.getn(formation) do
        for c = 1, table.getn(formation[r]) do
            if not table.empty(formation[r][c]) then
                count = count + 1
            end
        end
    end

    if Debug then
        local identifier = formation.Identifier
        if not identifier then
            WARN(string.format('Invalid attack land formation identifier for %d', k))
        else
            SPEW(string.format("Attack land formation %s with %d units", identifier, count))
        end
    end

    formation.Count = count
end
