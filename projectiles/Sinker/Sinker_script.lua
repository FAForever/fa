-- Automatically upvalued moho functions for performance
local EntityMethods = _G.moho.entity_methods
local EntityMethodsAttachBoneTo = EntityMethods.AttachBoneTo
local EntityMethodsSetVizToAllies = EntityMethods.SetVizToAllies
local EntityMethodsSetVizToFocusPlayer = EntityMethods.SetVizToFocusPlayer
local EntityMethodsSetVizToNeutrals = EntityMethods.SetVizToNeutrals

local GlobalMethods = _G
local GlobalMethodsWarp = GlobalMethods.Warp

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileMethodsSetBallisticAcceleration = ProjectileMethods.SetBallisticAcceleration
local ProjectileMethodsSetStayUpright = ProjectileMethods.SetStayUpright
-- End of automatically upvalued moho functions

local GetRandomFloat = import('/lua/utilities.lua').GetRandomFloat
local Projectile = import('/lua/sim/projectile.lua').Projectile

Sinker = Class(Projectile)({
    OnCreate = function(self)
        Projectile.OnCreate(self)

        EntityMethodsSetVizToFocusPlayer(self, 'Never')
        EntityMethodsSetVizToAllies(self, 'Never')
        EntityMethodsSetVizToNeutrals(self, 'Never')
        ProjectileMethodsSetStayUpright(self, false)
    end,

    --- Start the sinking after the given delay for the given entity/bone.
    -- Invokes sunkCallback when the unit reaches the bottom of the ocean.
    Start = function(self, delay, targEntity, targBone, sunkCallback)
        self.callback = sunkCallback
        if delay > 0 then
            -- Closure copies. Woot.
            local targetEntity = targEntity
            local targetBone = targBone
            local sinker = self
            local wait = delay

            self:ForkThread(function()

                WaitTicks(wait)
                sinker:StartSinking(targetEntity, targetBone)
            end)
        else
            self:StartSinking(targEntity, targBone)
        end
    end,

    StartSinking = function(self, targetEntity, targetBone)
        local pos = targetEntity:GetPosition(targetBone)
        local seafloor = GetTerrainHeight(pos[1], pos[3]) + GetTerrainTypeOffset(pos[1], pos[3])
        if pos[2] <= seafloor then
            self:Destroy()
            ForkThread(self.callback)
            return
        end

        GlobalMethodsWarp(self, pos, targetEntity:GetOrientation())
        EntityMethodsAttachBoneTo(targetEntity, targetBone, self, 'anchor')

        if not targetEntity:BeenDestroyed() then
            local bp = self:GetBlueprint()
            local acc = -bp.Physics.SinkSpeed
            ProjectileMethodsSetBallisticAcceleration(self, acc + GetRandomFloat(-0.02, 0.02))
        end
    end,

    --- Destroy the sinking unit when it hits the bottom of the ocean.
    OnImpact = function(self, targetType, targetEntity)
        if targetType == 'Terrain' then
            self:Destroy()
            if self.callback then
                ForkThread(self.callback)
            end
        end
    end,
})
TypeClass = Sinker
