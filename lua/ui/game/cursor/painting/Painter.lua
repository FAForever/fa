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

local Painting = import("/lua/ui/game/cursor/painting/Painting.lua").Painting

local clients = GetSessionClients()
local armies = GetArmiesTable().armiesTable
local durationInSeconds = 10

local KeyCodeAlt = 18
local KeyCodeCtrl = 17
local KeyCodeShift = 16

---@class UIPainter
---@field __Trash TrashBag
---@field __Paintings UIPainting[]
Painter = ClassSimple {

    ---@param self UIPainter
    __init = function(self)
        self.__Trash = TrashBag()
        self.__Trash:Add(ForkThread(self.__UpdateThread, self))

        self.__Paintings = { }
    end,

    ---@param self UIPainter
    __post_init = function(self)

    end,

    --- Publishes the painting to all allies and observers.
    __PublishPainting = function(self, painting)

    end,

    ---@param self UIPainter
    __UpdateThread = function(self)

        -- local scope for performance
        local painting = {}
        local wasKeyDown = false
        local lastWorldPosition = { 0, 0, 0 }

        while true do

            -- retrieve game state for this frame
            local isKeyDown = IsKeyDown(KeyCodeAlt)
            local mouseWorldPosition = GetMouseWorldPos()

            if isKeyDown and mouseWorldPosition and mouseWorldPosition[1] then

                if not wasKeyDown then
                    -- we hit this point when the player starts painting

                    -- clean up any previous painting
                    for k = 1, table.getn(painting) do
                        painting[k] = nil
                    end

                    table.setn(painting, 0)

                    -- start at the current mouse position
                    table.insert(painting, mouseWorldPosition)
                    lastWorldPosition = mouseWorldPosition

                    wasKeyDown = true
                else
                    -- we hit this point when the player is painting

                    -- update the painting if we've moved sufficiently
                    local dx = lastWorldPosition[1] - mouseWorldPosition[1]
                    local dz = lastWorldPosition[3] - mouseWorldPosition[3]
                    if (dx * dx + dz * dz > 1) then
                        table.insert(painting)
                    end
                end
            else
                if wasKeyDown then

                    local painting = self:__SimplifyPainting(painting)

                end
            end

            -- always wait at least one frame
            WaitFrames(1)
        end
    end,



    ---------------------------------------------------------------------------
    --#region Public API

    ---@param self UIPainter
    Destroy = function(self)
        self.__Trash:Destroy()
    end,

    ---@param self UIPainter
    ---@param painting Vector[]
    ---@param sender string
    ReceivePainting = function(self, painting, sender)

    end,

    --#endregion
}

---@type UIPainter | false
local instance = Painter()