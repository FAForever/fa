
--******************************************************************************************************
--** The code in this file is licensed using GNU GPL v3. You can find more information here:
--** - https://www.gnu.org/licenses/gpl-3.0.en.html
--**
--** You can find an informal description of this license here:
--** - https://www.youtube.com/watch?v=sQIVclmxvdQ
--** 
--** This file is maintained by members of and contributors to the Forged Alliance Forever association. 
--** You can find more information here:
--** - www.faforever.com
--**
--** In particular, the following people made significant contributions to this file:
--** - Jip @ https://github.com/Garanas
--******************************************************************************************************

local Shared = import('/lua/shared/NavGenerator.lua')
local NavGenerator = import('/lua/sim/NavGenerator.lua')
local NavUtils = import('/lua/sim/NavUtils.lua')

local scanLand = false
local scanHover = false
local scanWater = false
local scanAmph = false
local scanAir = false

function ToggleLandScan()
    scanLand = not scanLand
end

function ToggleHoverScan()
    scanHover = not scanHover
end

function ToggleWaterScan()
    scanWater = not scanWater
end

function ToggleAmphScan()
    scanAmph = not scanAmph
end

function ToggleAirScan()
    scanAir = not scanAir
end

local CanPathToDataOrigin = nil
local CanPathToDataDestination = nil
local CanPathToDataLayer = nil

function CanPathToLayer(data)
    CanPathToDataLayer = data.Layer
end

function CanPathToOrigin(data)
    CanPathToLayer(data)
    CanPathToDataOrigin = data.Location
end

function CanPathToDestination(data)
    CanPathToLayer(data)
    CanPathToDataDestination = data.Location
end

function CanPathToRerun(data)
    CanPathToLayer(data)
end

function CanPathToReset()
    CanPathToDataOrigin = nil
    CanPathToDataDestination = nil
    CanPathToDataLayer = nil
end

function ScanOver(mouse, layer)
    NavGenerator.LabelRoots[layer]:Draw()
    local over = NavGenerator.LabelRoots[layer]:FindLeaf(mouse)
    if over then 
        if over.label > 0 then
            local color = Shared.labelColors[over.label]
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

--- Scans and draws the navigational mesh, is controllable by the UI for debugging purposes
function Scan()
    while true do

        -- re-import it to catch disk ejections
        local NavGenerator = import('/lua/sim/NavGenerator.lua')

        -- we can only work with it once it is finished generating
        if NavGenerator.IsGenerated() then

            local mouse = GetMouseWorldPos()

            if scanLand then
                ScanOver(mouse, 'Land')
            end

            if scanHover then
                ScanOver(mouse, 'Hover')
            end

            if scanWater then
                ScanOver(mouse, 'Water')
            end

            if scanAmph then
                ScanOver(mouse, 'Amphibious')
            end

            if scanAir then
                ScanOver(mouse, 'Air')
            end
        end

        if CanPathToDataOrigin then
            DrawCircle(CanPathToDataOrigin, 3.9, '000000')
            DrawCircle(CanPathToDataOrigin, 4, Shared.colors[CanPathToDataLayer] or 'ffffff')
            DrawCircle(CanPathToDataOrigin, 4.1, '000000')
        end

        if CanPathToDataDestination then
            DrawCircle(CanPathToDataDestination, 3.9, '000000')
            DrawCircle(CanPathToDataDestination, 4, Shared.colors[CanPathToDataLayer] or 'ffffff')
            DrawCircle(CanPathToDataDestination, 4.1, '000000')
        end

        if CanPathToDataOrigin and CanPathToDataDestination and CanPathToDataLayer then 
            local ok, msg = NavUtils.CanPathTo(CanPathToDataLayer, CanPathToDataOrigin, CanPathToDataDestination)

            if ok then 
                DrawLinePop(CanPathToDataOrigin, CanPathToDataDestination, 'ffffff')
            else 
                DrawLinePop(CanPathToDataOrigin, CanPathToDataDestination, 'ff0000')
            end

            Sync.NavCanPathToDebug = {
                Ok = ok,
                Msg = msg,
                Origin = CanPathToDataOrigin,
                Destination = CanPathToDataDestination,
            }
        end

        WaitTicks(2)
    end
end

local ScanningThread = ForkThread(Scan)

--- Called by the module manager when this module is dirty due to a disk change
function __OnDirtyModule()
    if ScanningThread then
        ScanningThread:Destroy()
    end
end