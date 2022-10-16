
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

--- Returns true when you can path from the origin to the destination
---@param layer NavLayers
---@param origin Vector
---@param destination Vector
---@return boolean?
---@return string?
function CanPathTo(layer, origin, destination)

    -- check layer argument
    local root = NavGenerator.LabelRoots[layer] --[[@as LabelRoot]]
    if not root then
        return nil, 'Invalid layer type - this is likely a typo. The layer is case sensitive'
    end

    -- check origin argument
    local originLeaf = root:FindLeafXZ(origin[1], origin[3])
    if not originLeaf then
        return nil, 'Origin is not inside the map'
    end

    if originLeaf.label == -1 then
        return nil, 'Origin is unpathable'
    end

    if originLeaf.label == 0 then
        return nil, 'Origin has no label assigned, report to the maintainers. This should not be possible'
    end

    -- check destination argument
    local destinationLeaf = root:FindLeafXZ(destination[1], destination[3])
    if not destinationLeaf then
        return nil, 'Destination is not inside the map'
    end

    if destinationLeaf.label == -1 then
        return nil, 'Destination is unpathable'
    end

    if destinationLeaf.label == 0 then
        return nil, 'Destination has no label assigned, report to the maintainers. This should not be possible'
    end

    if originLeaf.label == destinationLeaf.label then
        return true
    else
        return false, 'Labels do not match, you will need a transport ^^'
    end
end
