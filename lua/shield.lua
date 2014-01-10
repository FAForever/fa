#****************************************************************************
#**
#**  File     :  /lua/shield.lua
#**  Author(s):  John Comes, Gordon Duclos
#**
#**  Summary  : Shield lua module
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local Entity = import('/lua/sim/Entity.lua').Entity
local EffectTemplate = import('/lua/EffectTemplates.lua')
local Util = import('utilities.lua')

Shield = Class(moho.shield_methods,Entity) {

    ShieldVerticalOffset = -1,

    __init = function(self,spec)
        _c_CreateShield(self,spec)
    end,

    OnCreate = function(self,spec)
        self.Trash = TrashBag()
        self.Owner = spec.Owner
        self.MeshBp = spec.Mesh
        self.MeshZBp = spec.MeshZ
        self.ImpactMeshBp = spec.ImpactMesh
        if spec.ImpactEffects != '' then
			self.ImpactEffects = EffectTemplate[spec.ImpactEffects]
		else
			self.ImpactEffects = {}
		end

		self:SetSize(spec.Size)
        self:SetMaxHealth(spec.ShieldMaxHealth)
        self:SetHealth(self,spec.ShieldMaxHealth)

        # Show our 'lifebar'
        self:UpdateShieldRatio(1.0)

        self:SetRechargeTime(spec.ShieldRechargeTime or 5, spec.ShieldEnergyDrainRechargeTime or 5)
        self:SetVerticalOffset(spec.ShieldVerticalOffset)

        self:SetVizToFocusPlayer('Always')
        self:SetVizToEnemies('Intel')
        self:SetVizToAllies('Always')
        self:SetVizToNeutrals('Intel')

        self:AttachBoneTo(-1,spec.Owner,-1)

        self:SetShieldRegenRate(spec.ShieldRegenRate)
        self:SetShieldRegenStartTime(spec.ShieldRegenStartTime)

		self.OffHealth = -1
		
		self.PassOverkillDamage = spec.PassOverkillDamage

        ChangeState(self, self.OnState)
    end,

    SetRechargeTime = function(self, rechargeTime, energyRechargeTime)
        self.ShieldRechargeTime = rechargeTime
        self.ShieldEnergyDrainRechargeTime = energyRechargeTime
    end,

    SetVerticalOffset = function(self, offset)
        self.ShieldVerticalOffset = offset
    end,

    SetSize = function(self, size)
        self.Size = size
    end,

    SetShieldRegenRate = function(self, rate)
        self.RegenRate = rate
    end,

    SetShieldRegenStartTime = function(self, time)
        self.RegenStartTime = time
    end,

    UpdateShieldRatio = function(self, value)        
        if value >= 0 then
            self.Owner:SetShieldRatio(value)
        else
            self.Owner:SetShieldRatio(self:GetHealth() / self:GetMaxHealth())
        end
    end,

    GetCachePosition = function(self)
        return self:GetPosition()
    end,
    
    # Note, this is called by native code to calculate spillover damage. The
    # damage logic will subtract this value from any damage it does to units
    # under the shield. The default is to always absorb as much as possible
    # but the reason this function exists is to allow flexible implementations
    # like shields that only absorb partial damage (like armor).
    OnGetDamageAbsorption = function(self,instigator,amount,type)
        #LOG('absorb: ', math.min( self:GetHealth(), amount ))
        
        # Like armor damage, first multiply by armor reduction, then apply handicap
        # See SimDamage.cpp (DealDamage function) for how this should work
        amount = amount * (self.Owner:GetArmorMult(type))
        amount = amount * ( 1.0 - ArmyGetHandicap(self:GetArmy()) )
        return math.min( self:GetHealth(), amount )
    end,



    OnCollisionCheckWeapon = function(self, firingWeapon)
		local weaponBP = firingWeapon:GetBlueprint()
        local collide = weaponBP.CollideFriendly
        if collide == false then
            if not ( IsEnemy(self:GetArmy(),firingWeapon.unit:GetArmy()) ) then
                return false
            end
        end
        #Check DNC list
        if weaponBP.DoNotCollideList then
			for k, v in pairs(weaponBP.DoNotCollideList) do
				if EntityCategoryContains(ParseEntityCategory(v), self) then
					return false
				end
			end
		end   
        
        return true
    end,
    
    GetOverkill = function(self,instigator,amount,type)
        #LOG('absorb: ', math.min( self:GetHealth(), amount ))
        
        # Like armor damage, first multiply by armor reduction, then apply handicap
        # See SimDamage.cpp (DealDamage function) for how this should work
        amount = amount * (self.Owner:GetArmorMult(type))
        amount = amount * ( 1.0 - ArmyGetHandicap(self:GetArmy()) )
        local finalVal =  amount - self:GetHealth()
        if finalVal < 0 then
            finalVal = 0
        end
        return finalVal
    end,    

	
	MakeOverlapDamage = function(self,  position, shield, amount)
		WaitSeconds(0.25)
		Damage(self.Owner, position, shield, amount * 0.5, "shieldOverlap")
	end,
	
    OnDamage =  function(self,instigator,amount,vector,type)

        local absorbed = self:OnGetDamageAbsorption(instigator,amount,type) 
        
        if self.PassOverkillDamage then
            local overkill = self:GetOverkill(instigator,amount,type)     
            if self.Owner and IsUnit(self.Owner) and overkill > 0 then
                self.Owner:DoTakeDamage(instigator, overkill, vector, type)
            end             
        end

		if type != "shieldOverlap" then		
			if self.MakeOverlapDamageThread then
				KillThread(self.MakeOverlapDamageThread)
				self.MakeOverlapDamageThread = nil
			end
			
			###### This code is to pass damage over overlapping shields.
			###### The biggest shield in the game is the UEF shield boat. This code must be adapted if there is a bigger one
			local position 		= self.Owner:GetPosition()
			local shieldbp 		= self.Owner:GetBlueprint().Defense.Shield
			local shieldRadius 	= (shieldbp.ShieldSize) / 2.0
			local offsetY 		= GetSurfaceHeight(position[1],position[3]) + GetTerrainTypeOffset(position[1], position[3])
			local shieldOffset 	= shieldRadius
			if (shieldRadius > offsetY) then
				shieldOffset 	= shieldOffset + offsetY			
				if shieldbp.ShieldVerticalOffset then
					shieldOffset = shieldOffset + shieldbp.ShieldVerticalOffset
				end
			
			end
			local aiBrain 		= self.Owner:GetAIBrain()
			local otherShields 	= aiBrain:GetUnitsAroundPoint(( categories.SHIELD * categories.DEFENSE), position, 120, 'Ally' )
			
			## the shield can have an offset, making it visually and effectively smaller than it really is.
			local surfaceRadius = math.sqrt((shieldRadius*(2*shieldOffset)) - (shieldOffset * shieldOffset))
		
			
			for k,v in otherShields do
				if self.Owner != v and v != instigator then
					local otherPosition 	= v:GetPosition()
					local othershieldbp 	= v:GetBlueprint().Defense.Shield

					
					local otherShieldRadius = (othershieldbp.ShieldSize) / 2.0
					
					local otherOffsetY 		= GetSurfaceHeight(otherPosition[1],otherPosition[3]) + GetTerrainTypeOffset(otherPosition[1], otherPosition[3])
					local otherShieldOffset 	= otherShieldRadius
					if (otherShieldRadius > otherOffsetY) then			
						otherShieldOffset 	= otherShieldOffset + otherOffsetY					
						if othershieldbp.ShieldVerticalOffset then
							otherShieldOffset = otherShieldOffset + othershieldbp.ShieldVerticalOffset
						end
					end

					local otherSurfaceRadius 	= math.sqrt((otherShieldRadius*(2*otherShieldOffset)) - (otherShieldOffset * otherShieldOffset))

					### Checking if the other shield is overlapping us.
					local overlapOffset =  (98*(surfaceRadius + otherSurfaceRadius)) / 100
					if self.Owner != v and VDist3(position, otherPosition) < (overlapOffset) then
						if v and v.MyShield  then
							if not v:IsDead() then
                                if v.MyShield:IsOn() then
    								damage = 0.5
    								if EntityCategoryContains(categories.STRUCTURE, v) then
    									damage = 0.1
    								end
    								self.MakeOverlapDamageThread = ForkThread(self.MakeOverlapDamage, self, position, v.MyShield, amount * damage , "shieldOverlap")
                                end
							end
						end
						
					end
				end

			end
		end

		
        self:AdjustHealth(instigator, -absorbed) 
        self:UpdateShieldRatio(-1)

        #LOG('Shield Health: ' .. self:GetHealth())
        if self.RegenThread then
           KillThread(self.RegenThread)
           self.RegenThread = nil
        end
        if self:GetHealth() <= 0 then
            ChangeState(self, self.DamageRechargeState)
        else
        
            if self.OffHealth < 0 then
                ForkThread(self.CreateImpactEffect, self, vector)
                if self.RegenRate > 0 then
                    self.RegenThread = ForkThread(self.RegenStartThread, self)
                    self.Owner.Trash:Add(self.RegenThread)
                end
            else
                self:UpdateShieldRatio(0)
            end
        end
    end,

    RegenStartThread = function(self)
        WaitSeconds(self.RegenStartTime)
        while self:GetHealth() < self:GetMaxHealth() do
        
            self:AdjustHealth(self.Owner, self.RegenRate)

            self:UpdateShieldRatio(-1)

            WaitSeconds(1)
        end
    end,

    CreateImpactEffect = function(self, vector)
        local army = self:GetArmy()
		local OffsetLength = Util.GetVectorLength(vector)
		local ImpactMesh = Entity { Owner = self.Owner }
		Warp( ImpactMesh, self:GetPosition())		
		
		if self.ImpactMeshBp != '' then
			ImpactMesh:SetMesh(self.ImpactMeshBp)
			ImpactMesh:SetDrawScale(self.Size)
			ImpactMesh:SetOrientation(OrientFromDir(Vector(-vector.x,-vector.y,-vector.z)),true)
		end

		for k, v in self.ImpactEffects do
			CreateEmitterAtBone( ImpactMesh, -1, army, v ):OffsetEmitter(0,0,OffsetLength)
		end

		WaitSeconds(5)
		ImpactMesh:Destroy()
    end,

    OnDestroy = function(self)
		self:SetMesh('')
		if self.MeshZ != nil then
			self.MeshZ:Destroy()
			self.MeshZ = nil
		end
		self:UpdateShieldRatio(0)
        ChangeState(self, self.DeadState)
    end,

    # Return true to process this collision, false to ignore it.
    OnCollisionCheck = function(self,other)
        if other:GetArmy() == -1 then
            return false
        end

        # allow strategic nuke missile to penetrate shields
        if EntityCategoryContains( categories.STRATEGIC, other ) and 
           EntityCategoryContains( categories.MISSILE, other ) then
            return false
        end

        if other:GetBlueprint().Physics.CollideFriendlyShield then
            return true
        end

        return IsEnemy(self:GetArmy(),other:GetArmy())
    end,

    TurnOn = function(self)
        ChangeState(self, self.OnState)
    end,

    TurnOff = function(self)
        ChangeState(self, self.OffState)
    end,

    IsOn = function(self)
        return false
    end,

    RemoveShield = function(self)
        self:SetCollisionShape('None')

		self:SetMesh('')
		if self.MeshZ != nil then
			self.MeshZ:Destroy()
			self.MeshZ = nil
		end
    end,

    CreateShieldMesh = function(self)
		self:SetCollisionShape( 'Sphere', 0, 0, 0, self.Size/2)

		self:SetMesh(self.MeshBp)
		self:SetParentOffset(Vector(0,self.ShieldVerticalOffset,0))
		self:SetDrawScale(self.Size)

		if self.MeshZ == nil then
			self.MeshZ = Entity { Owner = self.Owner }
			self.MeshZ:SetMesh(self.MeshZBp)
            Warp( self.MeshZ, self.Owner:GetPosition() )
			self.MeshZ:SetDrawScale(self.Size)
			self.MeshZ:AttachBoneTo(-1,self.Owner,-1)
			self.MeshZ:SetParentOffset(Vector(0,self.ShieldVerticalOffset,0))

			self.MeshZ:SetVizToFocusPlayer('Always')
			self.MeshZ:SetVizToEnemies('Intel')
			self.MeshZ:SetVizToAllies('Always')
			self.MeshZ:SetVizToNeutrals('Intel')
		end
    end,

    # Basically run a timer, but with visual bar movement
    ChargingUp = function(self, curProgress, time)
		local owner = self.Owner 
		local position = owner:GetPosition()
		local shieldbp = self.Owner:GetBlueprint().Defense.Shield
		local shieldRadius = shieldbp.ShieldSize
		local aiBrain = owner:GetAIBrain()
		local otherShields = aiBrain:GetUnitsAroundPoint(( categories.SHIELD * categories.DEFENSE), position, shieldRadius, 'Ally' )
		local rechargeTime = time + ((table.getn(otherShields) - 1) * .2 * time) 
		if rechargeTime > (time * 3) then
			rechargeTime = time
		else
		end
        while curProgress < rechargeTime do
            local fraction = self.Owner:GetResourceConsumed()
            curProgress = curProgress + ( fraction / 10 )
            curProgress = math.min( curProgress, rechargeTime )
            
            local workProgress = curProgress / rechargeTime
            
            self:UpdateShieldRatio( workProgress )
            WaitTicks(1)
        end    
    end,

    OnState = State {
        Main = function(self)

            # If the shield was turned off; use the recharge time before turning back on
            if self.OffHealth >= 0 then
                self.Owner:SetMaintenanceConsumptionActive()
                self:ChargingUp(0, self.ShieldEnergyDrainRechargeTime)
                
                # If the shield has less than full health, allow the shield to begin regening
                if self:GetHealth() < self:GetMaxHealth() and self.RegenRate > 0 then
                    self.RegenThread = ForkThread(self.RegenStartThread, self)
                    self.Owner.Trash:Add(self.RegenThread)
                end
            end
            
            # We are no longer turned off
            self.OffHealth = -1

            self:UpdateShieldRatio(-1)

            self.Owner:OnShieldEnabled()
			self:CreateShieldMesh()
			
			local aiBrain = self.Owner:GetAIBrain()

            WaitSeconds(1.0)
            local fraction = self.Owner:GetResourceConsumed()
            local on = true
            local test = false
            
            # Test in here if we have run out of power; if the fraction is ever not 1 we don't have full power
            while on do
                WaitTicks(1)

                self:UpdateShieldRatio(-1)
                
                fraction = self.Owner:GetResourceConsumed()
                if fraction != 1 and aiBrain:GetEconomyStored('ENERGY') <= 0 then
                    if test then
                        on = false
                    else
                        test = true
                    end
                else
                    on = true
                    test = false
                end
            end
            
            # Record the amount of health on the shield here so when the unit tries to turn its shield
            # back on and off it has the amount of health from before.
            #self.OffHealth = self:GetHealth()
            ChangeState(self, self.EnergyDrainRechargeState)
        end,

        IsOn = function(self)
            return true
        end,
    },

    # When manually turned off
    OffState = State {
        Main = function(self)

            # No regen during off state
            if self.RegenThread then
                KillThread(self.RegenThread)
                self.RegenThread = nil
            end

            # Set the offhealth - this is used basically to let the unit know the unit was manually turned off
      		self.OffHealth = self:GetHealth()

            # Get rid of teh shield bar
            self:UpdateShieldRatio(0)

            self:RemoveShield()
    		self.Owner:OnShieldDisabled()

            WaitSeconds(1)            
        end,
    },

    # This state happens when the shield has been depleted due to damage
    DamageRechargeState = State {
        Main = function(self)
            self:RemoveShield()
            
            # We must make the unit charge up before gettings its shield back
            self:ChargingUp(0, self.ShieldRechargeTime)
            
            # Fully charged, get full health
            self:SetHealth(self, self:GetMaxHealth())
            
            ChangeState(self, self.OnState)
        end
    },

    # This state happens only when the army has run out of power
    EnergyDrainRechargeState = State {
        Main = function(self)
            self:RemoveShield()
            
            self:ChargingUp(0, self.ShieldEnergyDrainRechargeTime)
            
            # If the unit is attached to a transport, make sure the shield goes to the off state
            # so the shield isn't turned on while on a transport
            if not self.Owner:IsUnitState('Attached') then
                ChangeState(self, self.OnState)
            else
                ChangeState(self, self.OffState)
            end
        end
    },

    DeadState = State {
        Main = function(self)
        end,
    },
}

UnitShield = Class(Shield){

    OnCreate = function(self,spec)
        self.Trash = TrashBag()
        self.Owner = spec.Owner
        self.ImpactEffects = EffectTemplate[spec.ImpactEffects]        
        self.CollisionSizeX = spec.CollisionSizeX or 1
		self.CollisionSizeY = spec.CollisionSizeY or 1
		self.CollisionSizeZ = spec.CollisionSizeZ or 1
		self.CollisionCenterX = spec.CollisionCenterX or 0
		self.CollisionCenterY = spec.CollisionCenterY or 0
		self.CollisionCenterZ = spec.CollisionCenterZ or 0
		self.OwnerShieldMesh = spec.OwnerShieldMesh or ''

		self:SetSize(spec.Size)

        self:SetMaxHealth(spec.ShieldMaxHealth)
        self:SetHealth(self,spec.ShieldMaxHealth)

        # Show our 'lifebar'
        self:UpdateShieldRatio(1.0)
        
        self:SetRechargeTime(spec.ShieldRechargeTime or 5, spec.ShieldEnergyDrainRechargeTime or 5)
        self:SetVerticalOffset(spec.ShieldVerticalOffset)

        self:SetVizToFocusPlayer('Always')
        self:SetVizToEnemies('Intel')
        self:SetVizToAllies('Always')
        self:SetVizToNeutrals('Always')

        self:AttachBoneTo(-1,spec.Owner,-1)

        self:SetShieldRegenRate(spec.ShieldRegenRate)
        self:SetShieldRegenStartTime(spec.ShieldRegenStartTime)

        self.PassOverkillDamage = spec.PassOverkillDamage
        
        ChangeState(self, self.OnState)
    end,

    CreateImpactEffect = function(self, vector)
        local army = self:GetArmy()
		local OffsetLength = Util.GetVectorLength(vector)
		local ImpactEnt = Entity { Owner = self.Owner }

		Warp( ImpactEnt, self:GetPosition())
		ImpactEnt:SetOrientation(OrientFromDir(Vector(-vector.x,-vector.y,-vector.z)),true)

		for k, v in self.ImpactEffects do
			CreateEmitterAtBone( ImpactEnt, -1, army, v ):OffsetEmitter(0,0,OffsetLength)
		end
		WaitSeconds(1)

		ImpactEnt:Destroy()
    end,

    CreateShieldMesh = function(self)
		self:SetCollisionShape( 'Box', self.CollisionCenterX, self.CollisionCenterY, self.CollisionCenterZ, self.CollisionSizeX, self.CollisionSizeY, self.CollisionSizeZ)
		self.Owner:SetMesh(self.OwnerShieldMesh,true)
    end,

    RemoveShield = function(self)
        self:SetCollisionShape('None')
		self.Owner:SetMesh(self.Owner:GetBlueprint().Display.MeshBlueprint, true)
    end,

    OnDestroy = function(self)
        if not self.Owner.MyShield or self.Owner.MyShield:GetEntityId() == self:GetEntityId() then
	        self.Owner:SetMesh(self.Owner:GetBlueprint().Display.MeshBlueprint, true)
		end
		self:UpdateShieldRatio(0)
        ChangeState(self, self.DeadState)
    end,
        
}

AntiArtilleryShield = Class(Shield){
    OnCollisionCheckWeapon = function(self, firingWeapon)
        local bp = firingWeapon:GetBlueprint()
        if bp.CollideFriendly == false then
            if self:GetArmy() == firingWeapon.unit:GetArmy() then
                return false
            end
        end
        # Check DNC list
		if bp.DoNotCollideList then
			for k, v in pairs(bp.DoNotCollideList) do
				if EntityCategoryContains(ParseEntityCategory(v), self) then
					return false
				end
			end
		end           
        if bp.ArtilleryShieldBlocks then
            return true
        end
        return false
    end,

    # Return true to process this collision, false to ignore it.
    OnCollisionCheck = function(self,other)
        if other:GetArmy() == -1 then
            return false
        end

        if other:GetBlueprint().Physics.CollideFriendlyShield and other.DamageData.ArtilleryShieldBlocks then
            return true
        end
        
        if other.DamageData.ArtilleryShieldBlocks and IsEnemy(self:GetArmy(),other:GetArmy()) then
            return true
        end

        return false
    end,
}
