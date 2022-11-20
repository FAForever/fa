
--******************************************************************************************************
--** Copyright (c) 2022  Willem 'Jip' Wijnia
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

local Shared = import("/lua/shared/navgenerator.lua")
local NavGenerator = import("/lua/sim/navgenerator.lua")
local NavUtils = import("/lua/sim/navutils.lua")

local ScanState = {
    LandLayer = false,
    AirLayer = false,
    NavalLayer = false,
    HoverLayer = false,
    AmphibiousLayer = false,

    LandLabels = false,
    AirLabels = false,
    NavalLabels = false,
    HoverLabels = false,
    AmphibiousLabels = false,
}

function ToggleScanLayer(data)
    local keyLayer = string.format('%sLayer', data.Layer)
    local keyLabels = string.format('%sLabels', data.Layer)
    ScanState[keyLayer] = not ScanState[keyLayer]
    ScanState[keyLabels] = false
end

function ToggleScanLabels(data)
    local keyLayer = string.format('%sLayer', data.Layer)
    local keyLabels = string.format('%sLabels', data.Layer)
    ScanState[keyLabels] = not ScanState[keyLabels]
    ScanState[keyLayer] = false
end

---@type NavDebugCanPathToState
local CanPathToState = { }

function CanPathTo(data)
    CanPathToState =  data
end

---@type NavDebugPathToState
local PathToState = { }

function PathTo(data)
    PathToState = data
end

---@type NavDebugGetLabelState
local GetLabelState = { }

function GetLabel(data)
    GetLabelState = data
end

function ScanOver(mouse, layer)
    if mouse then
        local over = NavGenerator.NavGrids[layer]:FindLeaf(mouse)
        if over then 
            if over.label > 0 then
                local color = Shared.LabelToColor(over.label)
                over:Draw(color, 0.1)
                over:Draw(color, 0.15)
                over:Draw(color, 0.2)

                if over.neighbors then
                    for _, neighbor in over.neighbors do
                        neighbor:Draw(color, 0.25)
                    end
                end
            else
                over:Draw('ff0000', 0.1)
                over:Draw('ff0000', 0.15)
                over:Draw('ff0000', 0.2)
            end
        end
    end
end

--- Scans and draws the navigational mesh, is controllable by the UI for debugging purposes
function Scan()
    while true do

        -- re-import it to catch disk ejections
        local NavGenerator = import("/lua/sim/navgenerator.lua")

        -- we can only work with it once it is finished generating
        if NavGenerator.IsGenerated() then

            local mouse = nil
            if rawget(_G, 'GetMouseWorldPos') then
                mouse = GetMouseWorldPos()
            end

            if ScanState.LandLayer then
                local layer = 'Land'
                NavGenerator.NavGrids[layer]:Draw()
                ScanOver(mouse, layer)
            end

            if ScanState.HoverLayer then
                local layer = 'Hover'
                NavGenerator.NavGrids[layer]:Draw()
                ScanOver(mouse, layer)
            end

            if ScanState.WaterLayer then
                local layer = 'Water'
                NavGenerator.NavGrids[layer]:Draw()
                ScanOver(mouse, layer)
            end

            if ScanState.AmphibiousLayer then
                local layer = 'Amphibious'
                NavGenerator.NavGrids[layer]:Draw()
                ScanOver(mouse, layer)
            end

            if ScanState.AirLayer then
                local layer = 'Air'
                NavGenerator.NavGrids[layer]:Draw()
                ScanOver(mouse, layer)
            end

            if ScanState.LandLabels then
                NavGenerator.NavGrids['Land']:DrawLabels()
            end

            if ScanState.HoverLabels then
                NavGenerator.NavGrids['Hover']:DrawLabels()
            end

            if ScanState.WaterLabels then
                NavGenerator.NavGrids['Water']:DrawLabels()
            end

            if ScanState.AmphibiousLabels then
                NavGenerator.NavGrids['Amphibious']:DrawLabels()
            end

            if ScanState.AirLabels then
                NavGenerator.NavGrids['Air']:DrawLabels()
            end
        end

        if CanPathToState.Origin then
            DrawCircle(CanPathToState.Origin, 3.9, '000000')
            DrawCircle(CanPathToState.Origin, 4, Shared.LayerColors[CanPathToState.Layer] or 'ffffff')
            DrawCircle(CanPathToState.Origin, 4.1, '000000')
        end

        if CanPathToState.Destination then
            DrawCircle(CanPathToState.Destination, 3.9, '000000')
            DrawCircle(CanPathToState.Destination, 4, Shared.LayerColors[CanPathToState.Layer] or 'ffffff')
            DrawCircle(CanPathToState.Destination, 4.1, '000000')
        end

        if CanPathToState.Origin and CanPathToState.Destination and CanPathToState.Layer then 
            local ok, msg = NavUtils.CanPathTo(CanPathToState.Layer, CanPathToState.Origin, CanPathToState.Destination)

            if ok then 
                DrawLinePop(CanPathToState.Origin, CanPathToState.Destination, 'ffffff')
            else 
                DrawLinePop(CanPathToState.Origin, CanPathToState.Destination, 'ff0000')
            end

            Sync.NavCanPathToDebug = {
                Ok = ok,
                Msg = msg
            }
        end

        if PathToState.Origin then
            DrawCircle(PathToState.Origin, 3.9, '000000')
            DrawCircle(PathToState.Origin, 4, Shared.LayerColors[PathToState.Layer] or 'ffffff')
            DrawCircle(PathToState.Origin, 4.1, '000000')
        end

        if PathToState.Destination then
            DrawCircle(PathToState.Destination, 3.9, '000000')
            DrawCircle(PathToState.Destination, 4, Shared.LayerColors[PathToState.Layer] or 'ffffff')
            DrawCircle(PathToState.Destination, 4.1, '000000')
        end

        if PathToState.Origin and PathToState.Destination then
            local path, n, label = NavUtils.PathTo(PathToState.Layer, PathToState.Origin, PathToState.Destination, nil)

            if not path then
                DrawLinePop(PathToState.Origin, PathToState.Destination, 'ff0000')
            else
                if n >= 2 then
                    local last = path[1]
                    for k = 2, n do
                        DrawLinePop(last, path[k], 'ff0000')
                        last = path[k]
                    end
                end
            end
        end

        if GetLabelState.Position then
            local label, msg = NavUtils.GetLabel(GetLabelState.Layer, GetLabelState.Position)
            if label then
                local color = Shared.LabelToColor(label) or 'ffffff'
                DrawCircle(GetLabelState.Position, 3.9, color)
                DrawCircle(GetLabelState.Position, 4.0, color)
                DrawCircle(GetLabelState.Position, 4.1, color)
            else
                DrawCircle(GetLabelState.Position, 3.9, '000000')
                DrawCircle(GetLabelState.Position, 4.0, 'ffffff')
                DrawCircle(GetLabelState.Position, 4.1, '000000')
            end

            Sync.NavDebugGetLabel = {
                Label = label,
                Msg = msg
            }
        end

        WaitTicks(2)
    end
end

local ScanningThread = ForkThread(Scan)

--- Called by the module manager when this module is dirty due to a disk change
function __moduleinfo.OnDirty()
    if ScanningThread then
        ScanningThread:Destroy()
    end
end