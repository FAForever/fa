----  File     : PrefetchUtilities.lua
----  Author(s): Robert Oates
----  Summary  : Functions to simplify prefetching by base, unit, etc...
----  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.

local TableGetn = table.getn
local TableInsert = table.insert

---@class PrefetchSet
---@field d3d_textures string[]
---@field batch_textures string[]
---@field models string[]
---@field anims string[]
---@field UnitCache table<UnitBlueprint, boolean>

---@param ids BlueprintId[]
---@return PrefetchSet
function CreatePrefetchSetFromBlueprints(ids)
    local PrefetchInfo = { Set = { d3d_textures = {}, batch_textures = {}, models = {}, anims = {} }, UnitCache = {} }
    local blueprints = __blueprints
    for _, id in ids do
        local blueprint = blueprints[id]
        if blueprint then

            if not PrefetchInfo.UnitCache[id] then
                local commonPath = '/units/' .. blueprint.BlueprintId .. '/' .. blueprint.BlueprintId

                TableInsert(PrefetchInfo.Set.d3d_textures, commonPath .. '_albedo.dds')
                TableInsert(PrefetchInfo.Set.d3d_textures, commonPath .. '_specteam.dds')
                TableInsert(PrefetchInfo.Set.d3d_textures, commonPath .. '_normalsts.dds')

                TableInsert(PrefetchInfo.Set.models, commonPath .. '_lod0.scm')

                if blueprint.Display.Mesh and blueprint.Display.Mesh.LODs and TableGetn(blueprint.Display.Mesh.LODs) > 0 then
                    for lodNum, lod in blueprint.Display.Mesh.LODs do
                        --Mesh for this LOD
                        if lodNum > 1 then
                            TableInsert(PrefetchInfo.Set.models, commonPath .. '_lod' .. (lodNum - 1) .. '.scm')
                        end

                        if lod.AlbedoName and lod.AlbedoName ~= "" then
                            TableInsert(PrefetchInfo.Set.d3d_textures, lod.AlbedoName)
                        end

                        if lod.SpecularName and lod.SpecularName ~= "" then
                            TableInsert(PrefetchInfo.Set.d3d_textures, lod.SpecularName)
                        end
                    end
                end

                PrefetchInfo.UnitCache[id] = true
            end
        end

    end

    local count = 0
    count = count + table.getsize(PrefetchInfo.Set.d3d_textures)
    count = count + table.getsize(PrefetchInfo.Set.batch_textures)
    count = count + table.getsize(PrefetchInfo.Set.models)
    count = count + table.getsize(PrefetchInfo.Set.anims)
    LOG(string.format("Prefetching %d files", count))

    return PrefetchInfo.Set
end
