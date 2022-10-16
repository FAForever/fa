
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

local scanLand = false
local scanHover = false
local scanNaval = false
local scanAmph = false
local scanAir = false

function ToggleLandScan()
    scanLand = not scanLand
end

function ToggleHoverScan()
    scanHover = not scanHover
end

function ToggleNavalScan()
    scanNaval = not scanNaval
end

function ToggleAmphScan()
    scanAmph = not scanAmph
end

function ToggleAirScan()
    scanAir = not scanAir
end

--- Scans and draws the navigational mesh, is controllable by the UI for debugging purposes
function Scan()
    while true do

        -- re-import it to catch disk ejections
        local NavGenerator = import('/lua/sim/NavGenerator.lua')

        -- we can only work with it once it is finished generating
        if NavGenerator.IsGenerated() then

            LOG("Scanning!")

            if scanLand then
                NavGenerator.LabelRoots['Land']:Draw()
            end

            if scanHover then
                NavGenerator.LabelRoots['Hover']:Draw()
            end

            if scanNaval then
                NavGenerator.LabelRoots['Naval']:Draw()
            end

            if scanAmph then
                NavGenerator.LabelRoots['Amphibious']:Draw()
            end

            if scanAir then
                NavGenerator.LabelRoots['Air']:Draw()
            end

            -- local mouse = GetMouseWorldPos()

            -- LabelRoots['land']:Draw()
            -- LabelRoots['naval']:Draw()

            -- local over = LabelRoots['land']:FindLeaf(mouse)
            -- if over then 
            --     if over.label > 0 then
            --         over:Draw(Shared.labelColors[over.label], 0.1)
            --         over:Draw(Shared.labelColors[over.label], 0.15)
            --         over:Draw(Shared.labelColors[over.label], 0.2)
            --     else
            --         over:Draw('ff0000', 0.1)
            --         over:Draw('ff0000', 0.15)
            --         over:Draw('ff0000', 0.2)
            --     end

            --     over:GenerateNeighbors(LabelRoots['land'])
            --     if over.neighbors then
            --         for _, neighbor in over.neighbors do
            --             neighbor:Draw('22ff22', 0.25)
            --         end
            --     end
            -- end
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