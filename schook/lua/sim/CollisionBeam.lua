#****************************************************************************
#**
#**  File     :  /lua/sim/collisionbeam.lua
#**  Author(s):
#**
#**  Summary  :
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
#
# CollisionBeam is the simulation (gameplay-relevant) portion of a beam. It wraps a special effect
# that may or may not exist depending on how the simulation is executing.
#
local DefaultDamage = import('/lua/sim/defaultdamage.lua')

CollisionBeam = Class(moho.CollisionBeamEntity) {

    FxBeam = {},
    FxBeamStartPoint = {},
    FxBeamStartPointScale = 1,
    FxBeamEndPoint = {},
    FxBeamEndPointScale = 1,

    FxImpactProp = {},
    FxImpactShield = {},    
    FxImpactNone = {},

    FxUnitHitScale = 1,
    FxLandHitScale = 1,
    FxWaterHitScale = 1,
    FxUnderWaterHitScale = 0.25,
    FxAirUnitHitScale = 1,
    FxPropHitScale = 1,
    FxShieldHitScale = 1,
    FxNoneHitScale = 1,

    TerrainImpactType = 'Default',
    TerrainImpactScale = 1,

    OnCreate = function(self)
        self.LastTerrainType = nil
        self.BeamEffectsBag = {}
        self.TerrainEffectsBag = {}
        self.Trash = TrashBag()
    end,

    OnDestroy = function(self)
        if self.Trash then
            self.Trash:Destroy()
        end
    end,

    OnEnable = function(self)
        self:CreateBeamEffects()
    end,

    OnDisable = function(self)
        self:DestroyBeamEffects()
        self:DestroyTerrainEffects()
        self.LastTerrainType = nil
    end,

    SetParentWeapon = function(self, weapon)
        self.Weapon = weapon
    end,
	
    DoDamage = function(self, instigator, damageData, targetEntity)
        local damage = damageData.DamageAmount or 0
        local dmgmod = 1
        if self.Weapon.DamageModifiers then
            for k, v in self.Weapon.DamageModifiers do
                dmgmod = v * dmgmod
            end
        end
		#this next line is new
		if targetEntity then
			local army = targetEntity:GetArmy()
			local pos = self:GetPosition()
			local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker
			local spec = {
				X = pos[1],
				Z = pos[3],
				Radius = 2, # was 5,
				LifeTime = 5, #was self.Data.Lifetime,
				Army = targetEntity:GetArmy(), #was self.Data.Army,
				Omni = false,
				WaterVision = false,
			}
			local vizEntity = VizMarker(spec)
			#self:Destroy()
		end
		#end new line
        damage = damage * dmgmod
        if instigator and damage > 0 then
            local radius = damageData.DamageRadius
            if radius and radius > 0 then
                if not damageData.DoTTime or damageData.DoTTime <= 0 then
                    DamageArea(instigator, self:GetPosition(1), radius, damage, damageData.DamageType or 'Normal', damageData.DamageFriendly or false)
                else
                    ForkThread(DefaultDamage.AreaDoTThread, instigator, self:GetPosition(1), damageData.DoTPulses or 1, (damageData.DoTTime / (damageData.DoTPulses or 1)), radius, damage, damageData.DamageType, damageData.DamageFriendly)
                end
            elseif targetEntity then
                if not damageData.DoTTime or damageData.DoTTime <= 0 then
                    Damage(instigator, self:GetPosition(), targetEntity, damage, damageData.DamageType)
                else
                    ForkThread(DefaultDamage.UnitDoTThread, instigator, targetEntity, damageData.DoTPulses or 1, (damageData.DoTTime / (damageData.DoTPulses or 1)), damage, damageData.DamageType, damageData.DamageFriendly)
                end
            else
                DamageArea(instigator, self:GetPosition(1), 0.25, damage, damageData.DamageType, damageData.DamageFriendly)
            end
        else
            LOG('*ERROR: THERE IS NO INSTIGATOR FOR DAMAGE ON THIS COLLISIONBEAM = ', repr(damageData))
        end
    end,

    CreateBeamEffects = function(self)
        local army = self:GetArmy()
        for k, y in self.FxBeamStartPoint do
            local fx = CreateAttachedEmitter(self, 0, army, y ):ScaleEmitter(self.FxBeamStartPointScale)
            table.insert( self.BeamEffectsBag, fx)
            self.Trash:Add(fx)
        end
        for k, y in self.FxBeamEndPoint do
            local fx = CreateAttachedEmitter(self, 1, army, y ):ScaleEmitter(self.FxBeamEndPointScale)
            table.insert( self.BeamEffectsBag, fx)
            self.Trash:Add(fx)
        end
        if table.getn(self.FxBeam) != 0 then
            local fxBeam = CreateBeamEmitter(self.FxBeam[Random(1, table.getn(self.FxBeam))], army)
            AttachBeamToEntity(fxBeam, self, 0, army)
            
            # collide on start if it's a continuous beam
            local weaponBlueprint = self.Weapon:GetBlueprint()
            local bCollideOnStart = weaponBlueprint.BeamLifetime <= 0
            self:SetBeamFx(fxBeam, bCollideOnStart)
            
            table.insert( self.BeamEffectsBag, fxBeam )
            self.Trash:Add(fxBeam)
        else
            LOG('*ERROR: THERE IS NO BEAM EMITTER DEFINED FOR THIS COLLISION BEAM ', repr(self.FxBeam))
        end
    end,

    DestroyBeamEffects = function(self)
        for k, v in self.BeamEffectsBag do
            v:Destroy()
        end
        self.BeamEffectsBag = {}
    end,

    CreateImpactEffects = function( self, army, EffectTable, EffectScale )
        local emit = nil
        EffectTable = EffectTable or {}
        EffectScale = EffectScale or 1
        for k, v in EffectTable do
            emit = CreateEmitterAtBone(self,1,army,v)
            if emit and EffectScale != 1 then
                emit:ScaleEmitter(EffectScale)
            end
        end
    end,

    CreateTerrainEffects = function( self, army, EffectTable, EffectScale )
        local emit = nil
        for k, v in EffectTable do
            emit = CreateAttachedEmitter(self,1,army,v)
            table.insert(self.TerrainEffectsBag, emit )
            if emit and EffectScale != 1 then
                emit:ScaleEmitter(EffectScale)
            end
        end
    end,

    DestroyTerrainEffects = function( self )
        for k, v in self.TerrainEffectsBag do
            v:Destroy()
        end
        self.TerrainEffectsBag = {}
    end,

    UpdateTerrainCollisionEffects = function( self, TargetType )
        local pos = self:GetPosition(1)
        local TerrainType = nil

        if self.TerrainImpactType != 'Default' then
            TerrainType = GetTerrainType( pos.x,pos.z )
        else
            TerrainType = GetTerrainType( -1, -1 )
        end

        local TerrainEffects = TerrainType.FXImpact[TargetType][self.TerrainImpactType] or nil

        if TerrainEffects and (self.LastTerrainType != TerrainType) then
            self:DestroyTerrainEffects()
            self:CreateTerrainEffects( self:GetArmy(), TerrainEffects, self.TerrainImpactScale )
            self.LastTerrainType = TerrainType
        end
    end,

    # This is called when the collision beam hits something new. Because the beam
    # is continuously detecting collisions it only executes this function when the
    # thing it is touching changes. Expect Impacts with non-physical things like
    # 'Air' (hitting nothing) and 'Underwater' (hitting nothing underwater).
    OnImpact = function(self, impactType, targetEntity)
        #LOG('*DEBUG: COLLISION BEAM ONIMPACT ', repr(self))
        #LOG('*DEBUG: COLLISION BEAM ONIMPACT, WEAPON =  ', repr(self.Weapon), 'Type = ', impactType)
        #LOG('CollisionBeam impacted with: ' .. impactType )
        # Possible 'type' values are:
        #  'Unit'
        #  'Terrain'
        #  'Water'
        #  'Air'
        #  'UnitAir'
        #  'Underwater'
        #  'UnitUnderwater'
        #  'Projectile'
        #  'Prop'
        #  'Shield'

        local instigator = self:GetLauncher()
        if not self.DamageTable then
            self:SetDamageTable()
        end

        local damageData = self.DamageTable

        # Buffs (Stun, etc)
        if targetEntity and IsUnit(targetEntity) then
            self:DoUnitImpactBuffs(targetEntity)
        end

        # Do Damage
        self:DoDamage( instigator, damageData, targetEntity)

        local ImpactEffects = {}
        local ImpactEffectScale = 1
        local army = self:GetArmy()

        if impactType == 'Water' then
            ImpactEffects = self.FxImpactWater
            ImpactEffectScale = self.FxWaterHitScale
        elseif impactType == 'Underwater' or impactType == 'UnitUnderwater' then
            ImpactEffects = self.FxImpactUnderWater
            ImpactEffectScale = self.FxUnderWaterHitScale
        elseif impactType == 'Unit' then
            ImpactEffects = self.FxImpactUnit
            ImpactEffectScale = self.FxUnitHitScale
        elseif impactType == 'UnitAir' then
            ImpactEffects = self.FxImpactAirUnit
            ImpactEffectScale = self.FxAirUnitHitScale
        elseif impactType == 'Terrain' then
            ImpactEffects = self.FxImpactLand
            ImpactEffectScale = self.FxLandHitScale
        elseif impactType == 'Air' or impactType == 'Projectile' then
            ImpactEffects = self.FxImpactNone
            ImpactEffectScale = self.FxNoneHitScale
        elseif impactType == 'Prop' then
            ImpactEffects = self.FxImpactProp
            ImpactEffectScale = self.FxPropHitScale
        elseif impactType == 'Shield' then
            ImpactEffects = self.FxImpactShield
            ImpactEffectScale = self.FxShieldHitScale            
        else
            LOG('*ERROR: CollisionBeam:OnImpact(): UNKNOWN TARGET TYPE ', repr(impactType))
        end

        self:CreateImpactEffects( army, ImpactEffects, ImpactEffectScale )
        self:UpdateTerrainCollisionEffects( impactType )
    end,

    GetCollideFriendly = function(self)
        return self.DamageData.CollideFriendly
    end,

    SetDamageTable = function(self)
        local weaponBlueprint = self.Weapon:GetBlueprint()
        self.DamageTable = {}
        self.DamageTable.DamageRadius = weaponBlueprint.DamageRadius
        self.DamageTable.DamageAmount = weaponBlueprint.Damage
        self.DamageTable.DamageType = weaponBlueprint.DamageType
        self.DamageTable.DamageFriendly = weaponBlueprint.DamageFriendly
        self.DamageTable.CollideFriendly = weaponBlueprint.CollideFriendly
        self.DamageTable.DoTTime = weaponBlueprint.DoTTime
        self.DamageTable.DoTPulses = weaponBlueprint.DoTPulses
        self.DamageTable.Buffs = weaponBlueprint.Buffs
    end,

    #When this beam impacts with the target, do any buffs that have been passed to it.
    DoUnitImpactBuffs = function(self, target)
        local data = self.DamageTable
        if data.Buffs then
            for k, v in data.Buffs do
                if v.Add.OnImpact == true and not EntityCategoryContains((ParseEntityCategory(v.TargetDisallow) or ''), target) 
                    and EntityCategoryContains((ParseEntityCategory(v.TargetAllow) or categories.ALLUNITS), target) then
                    
                    target:AddBuff(v)
                end
            end
        end
    end,

    ForkThread = function(self, fn, ...)
        if fn then
            local thread = ForkThread(fn, self, unpack(arg))
            self.Trash:Add(thread)
            return thread
        else
            return nil
        end
    end,
}
