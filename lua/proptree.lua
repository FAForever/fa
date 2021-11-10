--****************************************************************************
--**
--**  File     : /lua/proptree.lua
--**
--**  Summary  : Class for tree props that can burn and fall down and such
--**
--**  Copyright 2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local Prop = import('/lua/sim/Prop.lua').Prop
local FireEffects = import('/lua/EffectTemplates.lua').TreeBurning01
local DefaultExplosions = import('/lua/defaultexplosions.lua')
local GetRandomFloat = import('/lua/utilities.lua').GetRandomFloat

-- upvalue for performance
local Random = Random
local WaitTicks = coroutine.yield

Tree = Class(Prop) {

    --- Initialize the tree
    OnCreate = function (self, spec)
        Prop.OnCreate(self, spec)
        self.Burning = false 
        self.Fallen = false
        self.Dead = false 
    end,

    --- Collision check with projectiles
    OnCollisionCheck = function(self, other)
        return not self.Dead
    end,

    --- Collision check with units
    OnCollision = function(self, other, nx, ny, nz, depth)
        if not self.Dead then 
            if not self.Fallen then 
                -- change internal state
                self.Fallen = true
                self.Trash:Add(ForkThread(self.FallThread, self, nx, ny, nz, depth))
                self:PlayUprootingEffect(other)
            end
        end
    end,

    --- When damaged in some fashion - note that the tree can only be destroyed by disintegrating 
    -- damage and that the base class is not called accordingly.
    OnDamage = function(self, instigator, amount, direction, type)
        if not self.Dead then 
            if type == 'Force' then
                if not self.Fallen then 
                    -- change internal state
                    self.Fallen = true
                    self.Trash:Add(ForkThread(self.FallThread, self, direction[1], direction[2], direction[3], 0.5))

                    -- change the mesh
                    self:SetMesh(self.Blueprint.Display.MeshBlueprintWrecked)
                end

            elseif type == 'Nuke' and not self.Burning then
                -- slight chance we catch fire
                if Random(1, 250) < 5 then
                    self.Burning = true
                    self.Trash:Add(ForkThread(self.BurnThread, self))
                end

            elseif type == 'Disintegrate' then
                -- we just got obliterated
                self:Destroy()

            elseif type == 'Fire' and not self.Burning then 
                -- fire type damage, slightly higher odds to catch fire
                if Random(1, 12) <= 2 then
                    self.Burning = true
                    self.Trash:Add(ForkThread(self.BurnThread, self))
                end
            end
            
            if type ~= 'Force' and not self.Burning then 
                -- any damage type but force can cause a burn
                if Random(1, 8) <= 1 then
                    self.Burning = true
                    self.Trash:Add(ForkThread(self.BurnThread, self))
                end
            end
        end
    end,

    --- Uprooting effect when the tree falls over
    PlayUprootingEffect = function(self, instigator)
        CreateEmitterAtEntity( self, -1, '/effects/emitters/tree_uproot_01_emit.bp' )
        self:PlayPropSound('TreeFall')
    end,

    --- Contains all the falling logic
    FallThread = function(self, dx, dy, dz, depth)
        -- make it fall down
        local motor = self:FallDown()
        motor:Whack(dx, dy, dz, depth, true)

        -- destroy remaining effects after a while
        WaitTicks(150)

        -- make it sink after a while
        WaitTicks(150)
        self:SinkAway(-.1)

        -- get rid of it when it is completely below the terrain
        WaitTicks(100)
        self:Destroy()
    end,

    --- Contains all the burning logic
    BurnThread = function(self)

        -- used throughout this function
        local trash = self.Trash
        local position = self.CachePosition

        local effect = false 
        local effects = { }
        local effectsHead = 1

        local fireSize = 0.75 * Random() + 0.25

        -- fire effect
        for k, v in FireEffects do

            effect = CreateEmitterAtEntity(self, -1, v )
            effect:OffsetEmitter(0, 0.15, 0)
            effect:ScaleEmitter(3)

            -- keep track
            effects[effectsHead] = effect
            effectsHead = effectsHead + 1

            -- add it to trash bag
            trash:Add(effect)
        end

        -- light splash
        effect = CreateLightParticleIntel( self, -1, -1, 1.5, 10, 'glow_03', 'ramp_flare_02' )

        -- sounds
        self:PlayPropSound('BurnStart')
        self:PlayPropAmbientSound('BurnLoop')

        -- wait a bit before we change to a scorched tree
        WaitTicks(50)
        self:SetMesh(self.Blueprint.Display.MeshBlueprintWrecked)

        -- more fire effects
        for i = 5, 1, -1 do

            -- do not change the distort effect
            effects[1]:ScaleEmitter(3 + fireSize * (5 - i))
            effects[3]:ScaleEmitter(3 + fireSize * (5 - i))

            -- hold up a bit
            WaitTicks(20 + Random(10, 50))

            -- try and spread out the fire
            if i == 3 then
                DamageArea(self, position, 1, 1, 'Fire', true)
            end
        end

        -- wait a bit before we make a scorch mark
        WaitTicks(50)
        DefaultExplosions.CreateScorchMarkSplat( self, 0.5, -1 )

        -- try and spread the fire
        DamageArea(self, position, 1, 1, 'Fire', true)

        -- stop all sound
        self:PlayPropAmbientSound(nil)

        -- destroy all effects
        for k = 1, effectsHead - 1 do 
            effects[k]:Destroy()
        end

        -- add smoke effect removed when the tree is destroyed
        effect = CreateEmitterAtEntity(self, -1, FireEffects[3] )
        effect:ScaleEmitter(1 + Random())
        self.Trash:Add(effect)

        -- fall down in a random direction if we didn't before
        if not self.Fallen then 
            self.FallThread(self, Random() * 2 - 1, 0, Random() * 2 - 1, 0.25)
        end

    end,
}

TreeGroup = Class(Prop) {

    --- Break when colliding with a projectile of some sort
    OnCollisionCheck = function(self, other)
        self.Breakup(self)
        return false
    end,

    --- Break when colliding with something / someone
    OnCollision = function(self, other, vec)
        self.Breakup(self)
    end,

    --- Break when receiving damage
    OnDamage = function(self, instigator, amount, direction, type)
        self.Breakup(self)
    end,

    --- Breaks up the tree group into smaller trees
    Breakup = function(self, instigator, amount, direction, type)
        -- can't do much when we're destroyed
        if self:BeenDestroyed() then
            return
        end

        -- data required to retrieve sub props
        local props = false
        local blueprint = self.Blueprint

        -- a group with a single prop type in it
        if blueprint.SingleTreeBlueprint then
            props = SplitProp(self, blueprint.SingleTreeBlueprint)
        -- a group with multiple prop types in it
        else 
            props = self:SplitOnBonesByName(blueprint.SingleTreeDir)
        end
    end,
}
