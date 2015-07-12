local NinePatch = import('/lua/ui/controls/ninepatch.lua').NinePatch

-- A nine-patch without a background, useful for laying out around things. An eight-patch.
Border = Class(NinePatch) {
    __init = function(self, parent, topLeft, topRight, bottomLeft, bottomRight, left, right, top, bottom)
        NinePatch.__init(self, parent, nil, topLeft, topRight, bottomLeft, bottomRight, left, right, top, bottom)
    end
}
