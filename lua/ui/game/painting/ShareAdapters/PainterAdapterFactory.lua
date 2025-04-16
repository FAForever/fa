--******************************************************************************************************
--** Copyright (c) 2025 FAForever
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

local PainterObserverAdapter = import("/lua/ui/game/painting/ShareAdapters/PainterAdapterForObservers.lua")
local PainterPlayerAdapter = import("/lua/ui/game/painting/ShareAdapters/PainterAdapterForPlayers.lua")
local PainterReplayAdapter = import("/lua/ui/game/painting/ShareAdapters/PainterAdapterForReplays.lua")

--- Creates the correct adapter instance based on the game state of the local peer.
---@param painter UIPainter
---@return UIPainterAdapter
GetPainterAdapter = function(painter)

    -- A factory pattern that helps manage how brush strokes are shared. This is complicated. To keep
    -- the painting canvas simple and about painting we use this (network) adapter class to
    -- encapsulate all the logic. In general, it mimics the following rules:
    --
    -- - If watching a replay, painting should not be shared across the network at all.
    -- - If playing skirmish, painting should be shared through SimCallback.
    -- - If playing multiplayer, but you're a player - painting should be shared through SimCallback.
    -- - If playing multiplayer, but you're an observer - painting should be shared through SendChatMessage.
    --
    -- Note that all brush strokes shared through sim callbacks become part of a replay and can therefore
    -- be replayed and moderated.

    if SessionIsReplay() then
        return PainterReplayAdapter.CreatePainterAdapterForReplays(painter)
    elseif IsObserver() then
        return PainterObserverAdapter.CreatePainterAdapterForObservers(painter)
    else
        return PainterPlayerAdapter.CreatePainterAdapterForPlayers(painter)
    end
end
