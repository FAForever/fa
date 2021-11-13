local entity_methodsSetVizToFocusPlayer = moho.entity_methods.SetVizToFocusPlayer
local entity_methodsSetMesh = moho.entity_methods.SetMesh
local entity_methodsSetParentOffset = moho.entity_methods.SetParentOffset
local entity_methodsSetVizToEnemies = moho.entity_methods.SetVizToEnemies
local ForkThread = ForkThread
local entity_methodsSetDrawScale = moho.entity_methods.SetDrawScale
local mathSin = math.sin
local entity_methodsSetVizToAllies = moho.entity_methods.SetVizToAllies
local Vector = Vector
local mathMax = math.max
local entity_methodsAttachBoneTo = moho.entity_methods.AttachBoneTo
local entity_methodsBeenDestroyed = moho.entity_methods.BeenDestroyed
local mathMin = math.min
local entity_methodsSetVizToNeutrals = moho.entity_methods.SetVizToNeutrals

local Entity = import('/lua/sim/Entity.lua').Entity

ObjectiveArrow = Class(Entity) {

    OnCreate = function(self,spec)
        self.BounceTime = 0.0
        self.Size = spec.Size or 1.0
        entity_methodsSetVizToFocusPlayer(self, 'Always')
        entity_methodsSetVizToEnemies(self, 'Intel')
        entity_methodsSetVizToAllies(self, 'Never')
        entity_methodsSetVizToNeutrals(self, 'Intel')

        entity_methodsSetMesh(self, '/meshes/game/arrow_mesh')

        local unitScale = 1.0

        if spec.AttachTo then
            spec.AttachTo.Trash:Add(self)
            entity_methodsAttachBoneTo(self, -1,spec.AttachTo,-1)

            # Position at the top of the parent's collision box
            local yOff = 0
            local extents = spec.AttachTo:GetCollisionExtents()
            if extents then
                # scale up arrow based on unit's size
                unitScale = mathMin( extents.Max.x - extents.Min.x, extents.Max.z - extents.Min.z)
                unitScale = mathMax( unitScale, 1.0 )

                yOff = (self.Size * unitScale) / 2.0 + extents.Max.y - spec.AttachTo:GetPosition().y
                yOff = yOff + 0.5
            else
                yOff = spec.Size / 2.0 + 0.5
            end

            entity_methodsSetParentOffset(self, Vector(0,yOff,0))
            self.SavedOffset = yOff;
            ForkThread(self.BounceThread,self)
        end

        # magic 0.4 scaling so spec.Size can be specified in OGrid units
        entity_methodsSetDrawScale(self, 0.4 * self.Size * unitScale)
    end,

    BounceThread = function(self)
        while true do
            if entity_methodsBeenDestroyed(self) then
                return
            end

            #LOG('sin =',math.sin(self.BounceTime))
            local yOff = self.SavedOffset + mathSin(self.BounceTime) / 4

            entity_methodsSetParentOffset(self,  Vector(0,yOff,0) )

            WaitSeconds(0.1)
            self.BounceTime = self.BounceTime + math.pi * 0.25
        end
    end,
}
