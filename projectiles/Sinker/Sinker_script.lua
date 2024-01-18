local GetRandomFloat = import("/lua/utilities.lua").GetRandomFloat
local Projectile = import("/lua/sim/projectile.lua").Projectile

---@class Sinker : Projectile
Sinker = ClassProjectile(Projectile) {

    ---@param self Sinker    
    OnCreate = function(self)
        Projectile.OnCreate(self)
        self:SetVizToFocusPlayer('Never')
        self:SetVizToAllies('Never')
        self:SetVizToNeutrals('Never')
        self:SetStayUpright(false)
    end,

    --- Start the sinking after the given delay for the given entity/bone.
    -- Invokes sunkCallback when the unit reaches the bottom of the ocean.
    ---@param self Sinker
    ---@param delay number
    ---@param targEntity Prop|Unit
    ---@param targBone Bone
    ---@param sunkCallback any
    Start = function(self, delay, targEntity, targBone, sunkCallback)
        self.callback = sunkCallback
        if delay > 0 then
            -- Closure copies. Woot.
            local targetEntity = targEntity
            local targetBone = targBone
            local sinker = self
            local wait = delay

            self:ForkThread(
                function()
                    WaitTicks(wait)
                    sinker:StartSinking(targetEntity, targetBone)
                end
            )
        else
            self:StartSinking(targEntity, targBone)
        end
    end,

    ---@param self Sinker
    ---@param targetEntity Prop|Unit
    ---@param targetBone Bone
    StartSinking = function(self, targetEntity, targetBone)
        local pos = targetEntity:GetPosition(targetBone)
        local seafloor = GetTerrainHeight(pos[1], pos[3]) + GetTerrainTypeOffset(pos[1], pos[3])
        if pos[2] <= seafloor then
            self:Destroy()
            ForkThread(self.callback)
            return
        end

        Warp(self, pos, targetEntity:GetOrientation())
        targetEntity:AttachBoneTo(targetBone, self, 'anchor')

        if not targetEntity:BeenDestroyed() then
            local bp = self.Blueprint
            local acc = -bp.Physics.SinkSpeed
            self:SetBallisticAcceleration(acc + GetRandomFloat(-0.02, 0.02))
        end
    end,

    --- Destroy the sinking unit when it hits the bottom of the ocean.
    ---@param self Sinker
    ---@param targetType string
    ---@param targetEntity Prop|Unit
    OnImpact = function(self, targetType, targetEntity)
        if targetType == 'Terrain' or targetType == 'Underwater' then
            self:Destroy()
            if self.callback then
                ForkThread(self.callback)
            end
        end
    end,
}
TypeClass = Sinker
