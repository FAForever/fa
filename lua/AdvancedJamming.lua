#****************************************************************************
#**
#**  File     :  /lua/AdvancedJammer.lua
#**  Author(s):  Resin_Smoker
#**
#**  Summary  :  Advanced Jammer ability script:  Creates realistic hologram unit
#**              AdvancedJammerBlip:              Unit class used to control hologram units
#**
#**  Copyright © 2009 4th Dimension
#**
#****************************************************************************
#**
#**  The following is required in the units script for Advanced Jamming
#**  This calls into action the Advanced Jammer scripts for TWalkingLandUnit
#**
#**  TWalkingLandUnit = import('/mods/4th_Dimension 191/hook/lua/AdvancedJamming.lua').AdvancedJamming( TWalkingLandUnit )
#**
#****************************************************************************
#**
#**  The following is required in the unit blueprints for Advanced Jamming
#**  This sets the parimeters of each jamming unit.
#**
#**  UNIT BP:
#**
#**    Intel = {
#**        AltJamming = {
#**            DisabledInTransport = true,
#**            MaxDistance = 10,
#**            NumAirBlips = 5,
#**            NumGroundBlips = 0,
#**            NumSeaBlips = 0,
#**            StartEnabled = true,
#**        },
#**    },
#**
#**    ToggleCaps = {
#**        RULEUTC_IntelToggle = true, # abusing the intel toggle here, so we can use the onintelenabled events
#**    },
#**    OrderOverrides = {
#**        RULEUTC_IntelToggle = { # faking the jamming icon
#**            bitmapId = 'advanced jamming',
#**            helpText = 'toggle_jamming',
#**        },
#**    },
#**
#****************************************************************************
#**
#**    This script snippet is required to be within the /lua/sim/Units.lua. This is borrowed from the CBFP. It
#**    adds a unit event that's fired when the unit is picked up by a transport or when it's dropped from one.
#**
#**    OnTransportAttach = function(self, attachBone, unit)
#**        oldUnit.OnTransportAttach(self, attachBone, unit)
#**        unit:OnAttachedToTransport(self)
#**    end,
#**
#**    OnAttachedToTransport = function(self, transport)
#**    end,
#**
#**    OnTransportDetach = function(self, attachBone, unit)
#**        oldUnit.OnTransportDetach(self, attachBone, unit)
#**        unit:OnDetachedToTransport(self)
#**    end,
#**
#**    OnDetachedToTransport = function(self, transport)
#**    end,   
#**
#****************************************************************************

function AdvancedJamming(SuperClass)
    return Class(SuperClass) {
    
    OnCreate = function(self,builder,layer)
        ### Sets up table
        if not self.BlipsTable then
            self.BlipsTable = {}
        end                          
        SuperClass.OnCreate(self)
    end,

    OnStopBeingBuilt = function(self,builder,layer)             
        ### Ensures the jammer comes on if specified within the units BP
        if self:GetBlueprint().Intel.AltJamming.StartEnabled == true then
            if self.JammingActive == false or table.getn(self.BlipsTable) <= 0 then
                self:SetJammingStatus(true)
            end
        end      
        self.Sync.Abilities = self:GetBlueprint().Abilities
        self:RequestRefreshUI()         
        SuperClass.OnStopBeingBuilt(self,builder,layer)     
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        if self:GetJammingStatus() then 
            self:SetJammingStatus(false)
        end
        SuperClass.OnKilled(self, instigator, type, overkillRatio)
    end,

    OnIntelEnabled = function(self)
        SuperClass.OnIntelEnabled(self)
        if not self:GetJammingStatus() then 
            self:SetJammingStatus(true)
        end
    end,

    OnIntelDisabled = function(self)   
        SuperClass.OnIntelDisabled(self)
        if self:GetJammingStatus() then      
            self:SetJammingStatus(false)
        end
    end,

    OnAttachedToTransport = function(self, transport) # new event, borrowed from CBFP v3 (and up)
        SuperClass.OnAttachedToTransport(self, transport)
        self.PrevJammingStatus = self:GetJammingStatus()
        if self:GetBlueprint().Intel.AltJamming.DisabledInTransport then
            self:SetJammingStatus(false)
        end
    end,

    OnDetachedToTransport = function(self, transport) # new event, borrowed from CBFP v3 (and up)
        SuperClass.OnDetachedToTransport(self, transport)
        self:SetJammingStatus(self.PrevJammingStatus)
    end,
    
    GetJammingStatus = function(self)
        return self.JammingActive
    end,   

    SetJammingStatus = function(self, enabled)
        self.JammingActive = enabled
        if enabled then
            ### Add holograms and economy on jammer enable        
            self:SetMaintenanceConsumptionActive()           
            self:CreateHolograms()
        else
            ### Remove holograms and economy on jammer disable      
            self:SetMaintenanceConsumptionInactive()
            if table.getn(self.BlipsTable) > 0 then
                for k, blip in self.BlipsTable do
                    if blip:GetParent() == self then
                       blip:Destroy()
                    end
                end
            end 
            ### Reset hologram table
            self.BlipsTable = {}
        end
    end,
 
    ### Add hologram BPs here
    BlipBPs = {
        air = {
             't1_fighter_blip','t1_bomber_blip','t2_gunship_blip','t2_fighter_bomber_blip',
        },
        ground = {
            't1_anti_air_blip','t1_artillery_blip','t1_bot_blip','t1_scout_blip','t1_tank_blip',
        },
        sea = {
            't1_frigate_blip','t1_sub_blip',
        },
    },      
    
    CreateHolograms = function(self)
        local spawnHologram
        local BasePos = self:GetPosition()
        local bp = self:GetBlueprint().Intel.AltJamming
        local dist = bp.MaxDistance or 5
        local NumAirBlips = bp.NumAirBlips or 0
        local NumGroundBlips = bp.NumGroundBlips or 0
        local NumSeaBlips = bp.NumSeaBlips or 0
        local NumTotalBlips = NumAirBlips + NumGroundBlips + NumSeaBlips
                
        # this function creates blips. determines what blip should be created, creates it and then returns that unit
        local function CreateBlipUnit(BlipNum)
            local BlipBP
            if BlipNum <= NumAirBlips then
                BlipBP = self.BlipBPs['air'][ Random( 1, table.getn( self.BlipBPs['air'] )) ]
            elseif BlipNum <= (NumAirBlips + NumGroundBlips) then
                BlipBP = self.BlipBPs['ground'][ Random( 1, table.getn( self.BlipBPs['ground'] )) ]
            elseif BlipNum <= (NumAirBlips + NumGroundBlips + NumSeaBlips) then
                BlipBP = self.BlipBPs['sea'][ Random( 1, table.getn( self.BlipBPs['sea'] )) ]
            else
                return nil
            end
            return CreateUnitHPR(BlipBP, self:GetArmy(), BasePos[1]+Random(-dist, dist), BasePos[2], BasePos[3]+ Random(-dist, dist), 0, 0, 0)
        end

        # creates blips and assigns a patrol path to them
        for i = 1, NumTotalBlips do
            spawnHologram = CreateBlipUnit(i)
            spawnHologram:SetCreator(self)
            spawnHologram:SetParent(self)
            spawnHologram:SetAllWeaponsEnabled(false)
            spawnHologram:SetUnSelectable(true)
            #spawnHologram:SetVizToAllies('Never')
            #spawnHologram:SetVizToFocusPlayer('Never')            
            table.insert(self.BlipsTable, spawnHologram) # this can cause problems with multiple jammer units if not handled carefully! It's a bug in FA                     
            spawnHologram:DoRandomPatrol()
            self.Trash:Add(spawnHologram)
        end
    end,
    
    ReplaceHologram = function(self, hologram)
        if not self:IsDead() then
            local spawnHologram
            local bp = self:GetBlueprint().Intel.AltJamming
            local basePos = self:GetPosition()
            local dist = bp.MaxDistance or 5
            spawnHologram = CreateUnitHPR(hologram, self:GetArmy(), basePos[1]+Random(-dist, dist), basePos[2], basePos[3]+ Random(-dist, dist), 0, 0, 0)     
            spawnHologram:SetCreator(self)
            spawnHologram:SetParent(self)
            spawnHologram:SetAllWeaponsEnabled(false)
            spawnHologram:SetUnSelectable(true)
            #spawnHologram:SetVizToAllies('Never')
            #spawnHologram:SetVizToFocusPlayer('Never')            
            table.insert(self.BlipsTable, spawnHologram)
            spawnHologram:DoRandomPatrol()
        end           
    end, 
     
}
end ### End of AdvancedJamming(SuperClass)


local Unit = import('/lua/sim/Unit.lua').Unit
AdvancedJammerBlip = Class(Unit) {

    SetParent = function(self, parent)
        self.Parent = parent
    end, 

    GetParent = function(self)
        return self.Parent or nil
    end,

    DoRandomPatrol = function(self) 
        self.ParentBP = self.Parent:GetBlueprint().Intel.AltJamming
                        
        ### Have holograms guard the parent directly if its  parent is
        ### an air unit Otherwise have them patrol around the parents postion
        if EntityCategoryContains(categories.AIR, self.Parent) then  
            IssueGuard({self}, self.Parent)
        else                     
            ### Periodically issues random patrol to holigrams   
            self:ForkThread(self.KeepPatrolingThread)
        
            ### periodically checks distance to parent    
            self:ForkThread(self.KeepCloseToParentThread) 
        end
    end,
     
    KeepPatrolingThread = function(self)
        ### time in seconds before check
        local checkInterval = 15        
                        
        while not self:IsDead() and not self.Parent:IsDead() do
            ### Start a new patrol
            self:IssueRandomPatrol()
            
            ### Random delay before checking again
            WaitSeconds(Random(5, checkInterval-1))
        end
    end,

    KeepCloseToParentThread = function(self)    
        ### ticks between distance checks in ticks
        local checkInterval = 5   
                                                        
        ### multi-purpuse boolean, used to prevent issuing same orders twice                                              
        local toggle = true  
        
        while not self:IsDead() and not self.Parent:IsDead() do
            local pos = self:GetPosition()
            local parentPos = self.Parent:GetPosition()
            dist = VDist2(pos[1], pos[3], parentPos[1], parentPos[3])
            if dist <= self.ParentBP.MaxDistance * 0.5 then
                ### when unit comes back in range
                if not toggle then         
                    self:SetSpeedMult(1.0)
                    self:SetAccMult(1.0)
                    self:IssueRandomPatrol() 
                    toggle = true
                end
            else 
                ### Unit too far from parent
                if toggle then
                    IssueClearCommands({self})
                    self:SetSpeedMult(1.25)
                    self:SetAccMult(1.25)
                    local parentPos = self.Parent:CalculateWorldPositionFromRelative({0, 0, Random(3, self.ParentBP.MaxDistance * 0.25)})
                    IssueMove({self}, parentPos)
                    toggle = false
                end
            end
            WaitTicks(Random(1, checkInterval-1))
        end
    end,

    IssueRandomPatrol = function(self)
        if not self:IsDead() and not self.Parent:IsDead() then    
            local BasePos = self.Parent:GetPosition()
            local dist = self.ParentBP.MaxDistance * 0.75 or 15
            local numPatrols = Random(4, 8)
            IssueClearCommands({self})
            if Random(1, 5) <= 3 then
                for k=1,numPatrols do
                    IssuePatrol({self}, Vector( (BasePos[1]+Random(-dist, dist)), BasePos[2], (BasePos[3]+Random(-dist, dist)) ) )
                end
            else
                IssueGuard({self}, self.Parent)
            end
        end
    end,
     
    OnDamage = function(self, instigator, amount, vector, damagetype) 
        if not self:IsDead() then 
            self:Destroy()
        end 
        Unit.OnDamage(self, instigator, amount, vector, damagetype)
    end, 

    OnCollisionCheck = function(self, other, firingWeapon)
        if not self.Parent:IsDead() then
            self:Destroy()     
        end
    end,          
    
    OnDestroy = function(self, instigator, type, overkillRatio)
        ### Clears the current hologram commands if any
        IssueClearCommands(self)       

        ### Clears the offending hologram from the parents table
        if not self.Parent:IsDead() and self.Parent:GetJammingStatus() then
            table.removeByValue(self.Parent.BlipsTable, self)
            local hologram = self:GetUnitId() 
            self.Parent:ReplaceHologram(hologram)
            self.Parent = nil
        end
    end,                             
}### End of AdvancedJammerBlip