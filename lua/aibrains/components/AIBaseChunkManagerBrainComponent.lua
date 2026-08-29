--******************************************************************************************************
--** Copyright (c) 2025 Willem 'Jip' Wijnia
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

local TableInsert = table.insert
local VerifyBaseChunk = import("/lua/shared/AIBrain/AIBaseChunkSharedUtils.lua").VerifyBaseChunk

--- Responsible for managing the available chunks of a brain.
---@class AIChunkBrainComponent
---@field IsChunkModuleLoaded table<string, boolean>    # Quick lookup whether the given chunk is already loaded
---@field ChunksBySize table<number, AIChunkTemplate[]>
AIChunkTemplateBrainComponent = ClassSimple {

    --- Populates the necessary state
    ---@param self AIChunkBrainComponent | moho.aibrain_methods
    OnCreateAI = function(self)
        self.IsChunkModuleLoaded = {}
        self.Chunks = {}
    end,

    --- Loads in a chunk. Function is idempotent - loading in the same chunk twice won't do anything.
    ---@param self AIChunkBrainComponent | moho.aibrain_methods
    ---@return 'AlreadyLoaded' | 'NoChunkInModule' | 'ChunkIsInvalid'?
    LoadChunk = function(self, modulePath)
        if self.IsChunkModuleLoaded[module] then
            return 'AlreadyLoaded'
        end

        -- we intentionally use `import` here and not `doscript`. Modules that are
        -- loaded via `import` are cached. That means even if multiple AIBrains load
        -- the same chunk, they'll all have the same reference to that chunk. This
        -- is fine since chunks are read-only.

        local module = import(modulePath)
        local chunk = module.Chunk
        if not chunk then
            return 'NoChunkInModule'
        end

        -- validity check
        if not VerifyBaseChunk(chunk) then
            WARN(string.format("Invalid chunk: %s", modulePath))
            return 'ChunkIsInvalid'
        end

        -- keep track that this chunk is loaded
        self.IsChunkModuleLoaded[module] = true
        TableInsert(self.ChunksBySize[chunk.Size], chunk)
    end,

    --- Retrieves a random base chunk of a given chunk size.
    ---@param self AIChunkBrainComponent | moho.aibrain_methods
    ---@param chunkSize number           # a number between 1 and 16
    ---@return AIBaseChunk?
    ---@return 'NoChunksOfSize' | 'InvalidInput' | nil
    GetChunkBySize = function(self, chunkSize)
        -- todo
        return nil
    end,

    --- Retrieves a base chunk of a given chunk size that has at least one building site that has a type preference that matches the given unitId.
    ---@param self AIChunkBrainComponent | moho.aibrain_methods
    ---@param chunkSize number
    ---@param unitId UnitId
    ---@return AIBaseChunk?
    GetChunkByUnitId = function(self, chunkSize, unitId, force)
        -- todo 
        return nil
    end,
}
