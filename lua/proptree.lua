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

Tree = Class(Prop) {

    OnCollisionCheck = function(self, other)
        return true
    end,

    OnCollision = function(self, other, nx, ny, nz, depth)
        self.Motor = self.Motor or self:FallDown()
        self.Motor:Whack(nx, ny, nz, depth, true)
        self:PlayUprootingEffect(other)
        ChangeState(self, self.FallingState)
    end,

    OnDamage = function(self, instigator, armormod, direction, type)
        Prop.OnDamage(self, instigator, armormod, direction, type)
        if type == 'Force' then
            self.Motor = self.Motor or self:FallDown()
            self.Motor:Whack(direction[1], direction[2], direction[3], 1, true)
            local bp = self.Blueprint
            self:SetMesh(bp.Display.MeshBlueprintWrecked)
            ChangeState(self, self.FallingState)
        elseif type == 'Nuke' then
            if Random(1, 250) < 5 then
                ChangeState(self, self.BurningState)
                self.BurnFromNuke = true
            end
        elseif type == 'Disintegrate' then
            self:Destroy()
        else
            if Random(1, 8) <= 1 then
                ChangeState(self, self.BurningState)
            end
        end
    end,

    OnKilled = function(self)
        Prop.OnKilled(self)
        ChangeState(self, self.DeadState)
    end,

    OnDestroy = function(self)
        Prop.OnDestroy(self)
        ChangeState(self, self.DeadState)
    end,

    PlayUprootingEffect = function(self, instigator)
		local pos = self:GetCachePosition()
		local army = -1
        if instigator then
            army = instigator.Army
        end
		local TerrainType = GetTerrainType( pos.x,pos.z )

		if TerrainType.FXOther.Land.TreeRootDirt01 == nil then
			TerrainType = GetTerrainType( -1, -1 )
		end

		if TerrainType.FXOther.Land.TreeRootDirt01 != nil then
			for k, v in TerrainType.FXOther.Land.TreeRootDirt01 do
				CreateEmitterAtEntity( self, army, v )
			end
		end
        self:PlayPropSound('TreeFall')
    end,


    BurningState = State {

        Main = function(self)
            local effects = {}
            local fx
            local bp = self.Blueprint
            for k, v in FireEffects do
                fx = CreateEmitterAtEntity(self, -1, v ):OffsetEmitter(0, 0.5, 0):ScaleEmitter(4)
                table.insert(effects, fx)
                self.Trash:Add(fx)
            end
            fx = CreateLightParticleIntel( self, -1, -1, 1.5, 10, 'glow_03', 'ramp_flare_02' )
            table.insert(effects, fx)
            self.Trash:Add(fx)

            self:PlayPropSound('BurnStart')
            self:PlayPropAmbientSound('BurnLoop')

            WaitSeconds(0.5)
            self:SetMesh(bp.Display.MeshBlueprintWrecked)
            for i = 5, 1, -1 do
                for k, v in effects do
                    v:Destroy()
                end
                for k, v in FireEffects do
                    local fx = CreateAttachedEmitter(self, -2, -1, v ):OffsetEmitter(0, 0, 0.3):ScaleEmitter(i * 0.5)
                    table.insert(effects, fx)
                    self.Trash:Add(fx)
                end
                WaitSeconds(3 + Random(1, 10) * 0.1)
                if not self.BurnFromNuke and i == 3 then
                    DamageArea(self, self:GetCachePosition(), 1, 1, 'Fire', true)
                end
            end
            self.Motor = self.Motor or self:FallDown()
            self.Motor:Whack(GetRandomFloat(-1, 1), 0, GetRandomFloat(-1, 1), 0.25, true)
            WaitSeconds(5)
            DefaultExplosions.CreateScorchMarkSplat( self, 0.5, -1 )
            DamageArea(self, self:GetCachePosition(), 1, 1, 'Fire', true)
            self:PlayPropAmbientSound(nil)
            for k, v in effects do
                v:Destroy()
            end
            self:SinkAway(-.1)
            self.Motor = nil
            WaitSeconds(10)
            self:Destroy()
        end,

        OnCollisionCheck = function(self, other)
            if IsUnit(other) then
                return true
            else
                return false
            end
        end,

        OnCollision = function(self, other, nx, ny, nz, depth)
            self.Motor = self.Motor or self:FallDown()

            local otherbp = other.Blueprint
            local is_big = (otherbp.SizeX * otherbp.SizeZ) > 0.2
            if is_big then
                self.Motor:Whack(nx, ny, nz, depth, true)
            else
                self.Motor:Whack(nx, ny, nz, .05, false)
            end
        end,

        OnDamage = function(self, instigator, armormod, direction, type)
            if type == 'Force' then
                self.Motor = self:FallDown()
                self.Motor:Whack(direction[1], direction[2], direction[3], 1, true)
            elseif type == 'Disintegrate' then
                self:Destroy()
            end
        end,

    },

    FallingState = State {

        Main = function(self)
            local bp = self.Blueprint
            WaitSeconds(30)
            self:SinkAway(-.1)
            self.Motor = nil
            WaitSeconds(10)
            self:Destroy()
        end,

        OnDamage = function(self, instigator, armormod, direction, type)
            if type == 'Disintegrate' then
                self:Destroy()
            end
        end,
    },

    DeadState = State {
        Main = function(self)
        end,

        OnCollisionCheck = function(self, other)
            return false
        end,

        OnCollision = function(self, other, nx, ny, nz, depth)

        end,

        OnDamage = function(self, instigator, armormod, direction, type)

        end,
    },
}



TreeGroup = Class(Prop) {

    OnCollisionCheck = function(self, other)
        self:Breakup()
        return false
    end,

    OnCollision = function(self, other, vec)
        self:Breakup()
    end,

    OnDamage = function(self, instigator, armormod, direction, type)
        if type != 'Force' then
            if Random(1, 10) <= 1 then
                self:Breakup()
            end
        else
            self:Breakup()
        end
    end,

    Breakup = function(self)
        if self:BeenDestroyed() then
            return
        end

        -- If the blueprint defines a SingleTreeBlueprint, we turn every bone into
        -- a copy of that blueprint
        if self.Blueprint.SingleTreeBlueprint then
            return SplitProp(self, self.Blueprint.SingleTreeBlueprint)
        end

        -- Otherwise, we use the bone names to create a different prop for each bone
        return self:SplitOnBonesByName(self.Blueprint.SingleTreeDir)
    end,
}
