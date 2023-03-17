local Entity = import("/lua/sim/entity.lua").Entity

---@class ObjectiveArrowSpec
---@field AttachTo? Object
---@field Size? number defaults to `1.0`

---@class ObjectiveArrow : Entity
ObjectiveArrow = Class(Entity) {

    ---@param self ObjectiveArrow
    ---@param spec ObjectiveArrowSpec
    OnCreate = function(self, spec)
        -- unpack specs
        local size = spec.Size or 1.0
        local attachTo = spec.AttachTo

        local arrowSize = size
        self:SetVizToFocusPlayer('Always')
        self:SetVizToEnemies('Intel')
        self:SetVizToAllies('Never')
        self:SetVizToNeutrals('Intel')

        self:SetMesh('/meshes/game/arrow_mesh')

        if attachTo then
            attachTo.Trash:Add(self)
            self:AttachBoneTo(-1, attachTo, -1)

            -- Position at the top of the parent's collision box
            local yOff = 0
            local extents = attachTo:GetCollisionExtents()
            if extents then
                local extentsMax, extentsMin = extents.Max, extents.Min
                local unitSize = math.min(extentsMax.x - extentsMin.x, extentsMax.z - extentsMin.z)
                -- scale up arrow size based on unit's extents if it ends up making it larger
                if unitSize > 1 then
                    arrowSize = arrowSize * unitSize
                end
                yOff = extentsMax.y - attachTo:GetPosition().y
            end
            yOff = yOff + arrowSize * 0.5 + 0.5

            ForkThread(self.BounceThread, self, yOff) -- handles the first `SetParentOffset` from the y offset
        end

        -- magic 0.4 scaling so spec.Size can be specified in OGrid units
        self:SetDrawScale(0.4 * arrowSize)
    end,

    ---@param self ObjectiveArrow
    ---@param yOff number
    BounceThread = function(self, yOff)
        local vec = Vector(0, yOff, 0)
        -- since the bounce change is pi/4, this will end up oscillating with a frequency of 8 like
        -- 0 --> sqrt(2)/2 --> 1 --> sqrt(2)/2 --> 0 --> -sqrt(2)/2 --> -1 --> -sqrt(2)/2 --> 0
        local bounceTime = 0
        local bounceChng = math.pi * 0.25
        while not self:BeenDestroyed() do
            vec.y = yOff + math.sin(bounceTime) * 0.25
            self:SetParentOffset(vec)
            WaitSeconds(0.1)

            bounceTime = bounceTime + bounceChng
        end
    end,
}
