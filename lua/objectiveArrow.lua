local Entity = import('/lua/sim/Entity.lua').Entity

ObjectiveArrow = Class(Entity) {

    OnCreate = function(self,spec)
        self.BounceTime = 0.0
        self.Size = spec.Size or 1.0
        self:SetVizToFocusPlayer('Always')
        self:SetVizToEnemies('Intel')
        self:SetVizToAllies('Never')
        self:SetVizToNeutrals('Intel')

        self:SetMesh('/meshes/game/arrow_mesh')

        local unitScale = 1.0

        if spec.AttachTo then
            spec.AttachTo.Trash:Add(self)
            self:AttachBoneTo(-1,spec.AttachTo,-1)

            -- Position at the top of the parent's collision box
            local yOff = 0
            local extents = spec.AttachTo:GetCollisionExtents()
            if extents then
                -- scale up arrow based on unit's size
                unitScale = math.min( extents.Max.x - extents.Min.x, extents.Max.z - extents.Min.z)
                unitScale = math.max( unitScale, 1.0 )

                yOff = (self.Size * unitScale) / 2.0 + extents.Max.y - spec.AttachTo:GetPosition().y
                yOff = yOff + 0.5
            else
                yOff = spec.Size / 2.0 + 0.5
            end

            self:SetParentOffset(Vector(0,yOff,0))
            self.SavedOffset = yOff;
            ForkThread(self.BounceThread,self)
        end

        -- magic 0.4 scaling so spec.Size can be specified in OGrid units
        self:SetDrawScale(0.4 * self.Size * unitScale)
    end,

    BounceThread = function(self)
        while true do
            if self:BeenDestroyed() then
                return
            end

            --LOG('sin =',math.sin(self.BounceTime))
            local yOff = self.SavedOffset + math.sin(self.BounceTime) / 4

            self:SetParentOffset( Vector(0,yOff,0) )

            WaitSeconds(0.1)
            self.BounceTime = self.BounceTime + math.pi * 0.25
        end
    end,
}
