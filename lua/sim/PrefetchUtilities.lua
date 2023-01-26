----  File     : PrefetchUtilities.lua                                           
----  Author(s): Robert Oates                                                    
----  Summary  : Functions to simplify prefetching by base, unit, etc...                  
----  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.          

local TableGetn = table.getn

---@param armyName string
---@return table
function CreatePrefetchSetFromArmy(armyName)
    local BPList = {}

    ParseForUnits(armyName, Scenario.Armies[armyName].Units, BPList)

    --duplicate units here are handled in CreatePrefetchSetFromBlueprints
    return CreatePrefetchSetFromBlueprints(BPList)
end

---@param armyName string
---@param inTable table
---@param outTable table
function ParseForUnits(armyName, inTable, outTable)

    if not inTable.type or inTable.type == "GROUP" then
        --Parse groups
        for k,v in inTable do
            if type(v) == 'table' then
                ParseForUnits(armyName, v, outTable)
            end
        end
    else
        --Add unit
        table.insert(outTable, GetUnitBlueprintByName(inTable.type))
    end
end

---@param blueprintList table
---@return table
function CreatePrefetchSetFromBlueprints(blueprintList)
    local PrefetchInfo = {Set = {d3d_textures = {}, batch_textures= {}, models = {}, anims = {}}, UnitCache = {}}
    for bpNum, bp in blueprintList do
        if not PrefetchInfo.UnitCache[bp] then           
            local commonPath = '/units/'.. bp.BlueprintId ..'/'.. bp.BlueprintId

            table.insert(PrefetchInfo.Set.d3d_textures, commonPath ..'_albedo.dds')
            table.insert(PrefetchInfo.Set.d3d_textures, commonPath ..'_specteam.dds')
            table.insert(PrefetchInfo.Set.d3d_textures, commonPath ..'_normalsts.dds')

            table.insert(PrefetchInfo.Set.models, commonPath ..'_lod0.scm')

            if bp.Display.Mesh and bp.Display.Mesh.LODs and TableGetn(bp.Display.Mesh.LODs) > 0 then
                for lodNum, lod in bp.Display.Mesh.LODs do
                    --Mesh for this LOD
                    if lodNum > 1 then
                        table.insert(PrefetchInfo.Set.models, commonPath ..'_lod'.. (lodNum-1) ..'.scm')
                    end

                    if lod.AlbedoName and lod.AlbedoName ~= "" then
                        table.insert(PrefetchInfo.Set.d3d_textures, lod.AlbedoName)
                    end

                    if lod.SpecularName and lod.SpecularName ~= "" then
                        table.insert(PrefetchInfo.Set.d3d_textures, lod.SpecularName)
                    end
                end
            end

            PrefetchInfo.UnitCache[bp] = true
        end

    end

    return PrefetchInfo.Set
end

---@param unitList table
---@return table
function CreatePrefetchSetFromUnits(unitList)
    local BPs = {}

    for i,unit in unitList do
        table.insert(BPs, unit:GetBlueprint())
    end

    return CreatePrefetchSetFromBlueprints(BPs)
end