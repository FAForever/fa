#****************************************************************************
#**
#**  File     : /lua/proptree.lua
#**
#**  Summary  : Class for tree props that can burn and fall down and such
#**
#**  Copyright 2006 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local prop_methodsSetMesh = moho.prop_methods.SetMesh
local prop_methodsFallDown = moho.prop_methods.FallDown
local IsUnit = IsUnit
local prop_methodsDestroy = moho.prop_methods.Destroy
local DamageArea = DamageArea
local prop_methodsBeenDestroyed = moho.prop_methods.BeenDestroyed
local GetTerrainType = GetTerrainType
local CreateLightParticleIntel = CreateLightParticleIntel
local MotorFallDownWhack = moho.MotorFallDown.Whack
local tableInsert = table.insert
local next = next
local ipairs = ipairs
local CreateEmitterAtEntity = CreateEmitterAtEntity
local CreateAttachedEmitter = CreateAttachedEmitter
local SplitProp = SplitProp
local prop_methodsSinkAway = moho.prop_methods.SinkAway
local prop_methodsGetBlueprint = moho.prop_methods.GetBlueprint
local Random = Random

local Prop = import('/lua/sim/Prop.lua').Prop
local FireEffects = import('/lua/EffectTemplates.lua').TreeBurning01
local DefaultExplosions = import('/lua/defaultexplosions.lua')
local GetRandomFloat = import('/lua/utilities.lua').GetRandomFloat

Tree = Class(Prop) {

    OnCollisionCheck = function(self, other)
        return true
    end,

    OnCollision = function(self, other, nx, ny, nz, depth)
        self.Motor = self.Motor or prop_methodsFallDown(self)
        MotorFallDownWhack(self.Motor, nx, ny, nz, depth, true)
        self:PlayUprootingEffect(other)
        ChangeState(self, self.FallingState)
    end,

    OnDamage = function(self, instigator, armormod, direction, type)
        Prop.OnDamage(self, instigator, armormod, direction, type)
        if type == 'Force' then
            self.Motor = self.Motor or prop_methodsFallDown(self)
            MotorFallDownWhack(self.Motor, direction[1], direction[2], direction[3], 1, true)
            local bp = prop_methodsGetBlueprint(self)
            prop_methodsSetMesh(self, bp.Display.MeshBlueprintWrecked)
            ChangeState(self, self.FallingState)
        elseif type == 'Nuke' then
            if Random(1, 250) < 5 then
                ChangeState(self, self.BurningState)
                self.BurnFromNuke = true
            end
        elseif type == 'Disintegrate' then
            prop_methodsDestroy(self)
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
            local bp = prop_methodsGetBlueprint(self)
            for k, v in FireEffects do
                fx = CreateEmitterAtEntity(self, -1, v ):OffsetEmitter(0, 0.5, 0):ScaleEmitter(4)
                tableInsert(effects, fx)
                self.Trash:Add(fx)
            end
            fx = CreateLightParticleIntel( self, -1, -1, 1.5, 10, 'glow_03', 'ramp_flare_02' )
            tableInsert(effects, fx)
            self.Trash:Add(fx)

            self:PlayPropSound('BurnStart')
            self:PlayPropAmbientSound('BurnLoop')

            WaitSeconds(0.5)
            prop_methodsSetMesh(self, bp.Display.MeshBlueprintWrecked)
            for i = 5, 1, -1 do
                for k, v in effects do
                    v:Destroy()
                end
                for k, v in FireEffects do
                    local fx = CreateAttachedEmitter(self, -2, -1, v ):OffsetEmitter(0, 0, 0.3):ScaleEmitter(i * 0.5)
                    tableInsert(effects, fx)
                    self.Trash:Add(fx)
                end
                WaitSeconds(3 + Random(1, 10) * 0.1)
                if not self.BurnFromNuke and i == 3 then
                    DamageArea(self, self:GetCachePosition(), 1, 1, 'Fire', true)
                end
            end
            self.Motor = self.Motor or prop_methodsFallDown(self)
            MotorFallDownWhack(self.Motor, GetRandomFloat(-1, 1), 0, GetRandomFloat(-1, 1), 0.25, true)
            WaitSeconds(5)
            DefaultExplosions.CreateScorchMarkSplat( self, 0.5, -1 )
            DamageArea(self, self:GetCachePosition(), 1, 1, 'Fire', true)
            self:PlayPropAmbientSound(nil)
            for k, v in effects do
                v:Destroy()
            end
            prop_methodsSinkAway(self, -.1)
            self.Motor = nil
            WaitSeconds(10)
            prop_methodsDestroy(self)
        end,

        OnCollisionCheck = function(self, other)
            if IsUnit(other) then
                return true
            else
                return false
            end
        end,

        OnCollision = function(self, other, nx, ny, nz, depth)
            self.Motor = self.Motor or prop_methodsFallDown(self)

            local otherbp = other:GetBlueprint()
            local is_big = (otherbp.SizeX * otherbp.SizeZ) > 0.2
            if is_big then
                MotorFallDownWhack(self.Motor, nx, ny, nz, depth, true)
            else
                MotorFallDownWhack(self.Motor, nx, ny, nz, .05, false)
            end
        end,

        OnDamage = function(self, instigator, armormod, direction, type)
            if type == 'Force' then
                self.Motor = prop_methodsFallDown(self)
                MotorFallDownWhack(self.Motor, direction[1], direction[2], direction[3], 1, true)
            elseif type == 'Disintegrate' then
                prop_methodsDestroy(self)
            end
        end,

    },

    FallingState = State {

        Main = function(self)
            local bp = prop_methodsGetBlueprint(self)
            WaitSeconds(30)
            prop_methodsSinkAway(self, -.1)
            self.Motor = nil
            WaitSeconds(10)
            prop_methodsDestroy(self)
        end,

        OnDamage = function(self, instigator, armormod, direction, type)
            if type == 'Disintegrate' then
                prop_methodsDestroy(self)
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
        if prop_methodsBeenDestroyed(self) then
            return
        end

        # If the blueprint defines a SingleTreeBlueprint, we turn every bone into
        # a copy of that blueprint
        if prop_methodsGetBlueprint(self).SingleTreeBlueprint then
            return SplitProp(self, prop_methodsGetBlueprint(self).SingleTreeBlueprint)
        end

        # Otherwise, we use the bone names to create a different prop for each bone
        return self:SplitOnBonesByName(prop_methodsGetBlueprint(self).SingleTreeDir)
    end,
}
