-- Transportutilities.lua --
-- This module is a core module of The LOUD Project and the work in it, is a creative work of Alexander W.G. Brown
-- Please feel free to use it, but please respect and preserve all the 'LOUD' references within

--- HOW IT WORKS --
-- By creating a 'pool' (TransportPool) just for transports - we can quickly find - and assemble - platoons of transports
-- A platoon of transports will be used to move platoons of units - the two entities remaining entirely separate from each other

-- Every transport created has a callback added that will return it back to the transport pool after a unit detach event
-- This 'ReturnTransportsToPool' process will separate out those which need fuel/repair - and return both groups to the nearest base
-- Transports which do not require fuel/repair are returned to the TransportPool
-- Transports which require fuel/repair will be assigned to the 'Refuel Pool' until that task is accomplished
-- The 'Refuel Pool' functionality (ProcessAirUnits) is NOT included in this module.  See LOUDUTILITIES for that.

local import = import

local TableCopy = table.copy
local EntityContains = EntityCategoryContains
local MathFloor = math.floor
local TableGetn = table.getn
local TableInsert = table.insert
local TableSort = table.sort
local ForkTo = ForkThread
local tostring = tostring
local type = type
local VDist2 = VDist2
local VDist3 = VDist3
local WaitTicks = coroutine.yield

local AssignUnitsToPlatoon = moho.aibrain_methods.AssignUnitsToPlatoon
local GetFuelRatio = moho.unit_methods.GetFuelRatio
local GetFractionComplete = moho.entity_methods.GetFractionComplete
local GetListOfUnits = moho.aibrain_methods.GetListOfUnits
local GetPosition = moho.entity_methods.GetPosition
local GetPlatoonPosition = moho.platoon_methods.GetPlatoonPosition
local GetPlatoonUnits = moho.platoon_methods.GetPlatoonUnits
local IsBeingBuilt = moho.unit_methods.IsBeingBuilt
local IsIdleState = moho.unit_methods.IsIdleState
local IsUnitState = moho.unit_methods.IsUnitState
local PlatoonExists = moho.aibrain_methods.PlatoonExists
local NavUtils = import("/lua/sim/navutils.lua")

local AIRTRANSPORTS = categories.AIR * categories.TRANSPORTFOCUS
local ENGINEERS = categories.ENGINEER
local TransportDialog = false

-- this function will create the TransportPool platoon and put the reference to it in the brain
function CreateTransportPool( aiBrain )
    
    if TransportDialog then
        LOG("*AI DEBUG "..aiBrain.Nickname.." Creates TRANSPORTPOOL" )
    end

    local transportplatoon = aiBrain:MakePlatoon( 'TransportPool', 'none' )
    transportplatoon:UniquelyNamePlatoon('TransportPool') 
    transportplatoon.BuilderName = 'TPool'
    transportplatoon.UsingTransport = true      -- never review this platoon during a merge

	aiBrain.TransportPool = transportplatoon

end

-- This utility should get called anytime a transport is built or created
-- it will force the transport into the Transport pool & pass control over to the ReturnToPool function
-- it not already done so, it will create the callback that fires when a transport unloads any unit
function AssignTransportToPool( unit, aiBrain )

    if not aiBrain.TransportPool then
        CreateTransportPool( aiBrain)
    end

    -- this sets up the OnTransportDetach callback so that this function runs EVERY time a transport drops units
	if not unit.EventCallbacks['OnTransportDetach'] then
		unit:AddUnitCallback( function(unit)
			if TransportDialog then
                LOG("*AI DEBUG TRANSPORT "..unit.PlatoonHandle.BuilderName.." Transport "..unit.EntityId.." Fires ReturnToPool callback" )
			end
			if TableGetn(unit:GetCargo()) == 0 then
				if unit.WatchUnloadThread then
					KillThread(unit.WatchUnloadThread)
					unit.WatchUnloadThread = nil
				end
				ForkTo( AssignTransportToPool, unit, aiBrain )
			end
		end, 'OnTransportDetach')
	end

    -- if the unit is not already in the transport Pool --
	if not unit.Dead and (not unit.PlatoonHandle != aiBrain.TransportPool) then
        if TransportDialog then
            LOG("*AI DEBUG TRANSPORT "..repr(unit.PlatoonHandle.BuilderName).." Transport "..unit.EntityId.." starts assigning to Transport Pool" )
        end
		IssueToUnitClearCommands(unit)
		-- if not in need of repair or fuel -- 
		if not ProcessAirUnits( unit, aiBrain ) then
            if aiBrain.TransportPool then
                AssignUnitsToPlatoon( aiBrain, aiBrain.TransportPool, {unit}, 'Support','')
            else
                return
            end
            unit.Assigning = false        
			unit.PlatoonHandle = aiBrain.TransportPool
            if not IsBeingBuilt(unit) then
                ForkTo( ReturnTransportsToPool, aiBrain, {unit}, true )
                return
            end
		end
    end
    
    unit.InUse = false
    unit.Assigning = false    
    
    if TransportDialog then
        LOG("*AI DEBUG TRANSPORT "..repr(unit.PlatoonHandle.BuilderName).." Transport "..unit.EntityId.." now available to Transport Pool" )
    end

end

-- This utility will traverse all true transports to insure they are in the TransportPool
-- and a perfunctory cleanup on the path requests reply table for dead platoons
function CheckTransportPool( aiBrain )

    if not aiBrain.TransportPool then
        CreateTransportPool( aiBrain)
    end
    
	local IsIdleState = IsIdleState
    local PlatoonExists = PlatoonExists

    local ArmyPool = aiBrain.ArmyPool

    local RefuelPool = aiBrain.RefuelPool or false
    local StructurePool = aiBrain.StructurePool or false
	local TransportPool = aiBrain.TransportPool
    
    local oldplatoonname, platoon

	-- get all idle, fully built transports except UEF gunship --
	local unitlist = GetListOfUnits( aiBrain, AIRTRANSPORTS - categories.uea0203, true, true)
	
	for k,v in unitlist do
		if v and v.PlatoonHandle != TransportPool and v.PlatoonHandle != RefuelPool and GetFractionComplete(v) == 1 then
			platoon = v.PlatoonHandle or false
			oldplatoonname = false
			if platoon then
				oldplatoonname = platoon.BuilderName or false
			end
			if (not IsIdleState(v)) or v.InUse or v.Assigning or (platoon and PlatoonExists(aiBrain,platoon)) then
				if not IsIdleState(v) then
					continue
				end
				--if platoon.CreationTime and (aiBrain.CycleTime - platoon.CreationTime) < 360 then
				--	continue
				--end
			end
			IssueToUnitClearCommands(v)
			if v.WatchLoadingThread then
                if TransportDialog then
                    LOG("*AI DEBUG "..aiBrain.Nickname.." Killing Watch Loading thread - transport "..v.EntityId.." in CheckTransportPool")
                end
				KillThread(v.WatchLoadingThread)
				v.WatchLoadingThread = nil
			end
			if v.WatchTravelThread then
                if TransportDialog then
                    LOG("*AI DEBUG "..aiBrain.Nickname.." Killing Watch Travel thread - transport "..v.EntityId.." in CheckTransportPool")
                end            
				KillThread(v.WatchTravelThread)
				v.WatchTravelThread = nil
			end
			if platoon and PlatoonExists(aiBrain,platoon) then
				if platoon != ArmyPool and platoon != RefuelPool and platoon != StructurePool then
					aiBrain:DisbandPlatoon(platoon)
				end
			end
            if TransportDialog then
                LOG("*AI DEBUG "..aiBrain.Nickname.." Assigning Transport "..v.EntityId.." to Pool in CheckTransportPool")
            end
            
			ForkTo( AssignTransportToPool, v, aiBrain )

        end
	end
	
	aiBrain.CheckTransportPoolThread = nil

end

-- This function attempts to locate the required number of transports to move the platoon.
-- if insufficient transport available, the brain is marked with needing to build more transport
-- restricts the use of out/low fuel transports and to keep transports moving back to a base when not in use
-- Will now also limit transport selection to those within 16 km
function GetTransports( platoon, aiBrain)

    if platoon.UsingTransport then
        return false, false
    end
    
    if not aiBrain.TransportPool then
        CreateTransportPool(aiBrain)
    end

	local IsEngineer = platoon:PlatoonCategoryCount( ENGINEERS ) > 0
	-- GATHER PHASE -- gather info on all available transports
	local Special = false
	
	if aiBrain.FactionIndex == 1 then
		Special = true      -- notes if faction has 'special' transport units - ie. UEF T2 gunship
	end
	
    local transportpool = aiBrain.TransportPool
	local armypool = aiBrain.ArmyPool
	local armypooltransports = {}
	local TransportPoolTransports = false
	
	-- build table of transports to use
    -- engineers - only use T1/T2 - T3 is not permitted for them
	if IsEngineer then
		TransportPoolTransports = EntityCategoryFilterDown( AIRTRANSPORTS - categories.TECH3 - categories.EXPERIMENTAL, GetPlatoonUnits(transportpool) )
    else
		TransportPoolTransports = EntityCategoryFilterDown( AIRTRANSPORTS, GetPlatoonUnits(transportpool) )
    end
    
	-- get special transports from the army pool
	if Special then
		armypooltransports = EntityCategoryFilterDown( categories.uea0203, GetPlatoonUnits(armypool) )
	end
    
    -- if there are no transports available at all - we're done
    if (armypooltransports and TableGetn(armypooltransports) < 1) and (TransportPoolTransports and TableGetn(TransportPoolTransports) < 1) then
    
        if TransportDialog then
            LOG("*AI DEBUG "..aiBrain.Nickname.." "..platoon.BuilderName.." there are no transports at all")
        end
        aiBrain.TransportRequested = true   -- turn on need flag
        return false, false
    end


    -- REQUIREMENT PHASE - determine what transports are required to move the unit platoon
    
	local CanUseTransports = false 	-- used to indicate if units in the platoon can actually use transports

    -- this is a table of 'slots' required
	local neededTable = { Small = 0, Medium = 0, Large = 0, Total = 0 }
	
    -- loop thru the unit platoon and summarize the number of slots required 
    -- take into account the flex of slots required - so larger units add extra Small/Medium requirements
    -- this sometimes means we'll select one extra transport above what we may actually need but we're never short
	for _, v in GetPlatoonUnits(platoon) do
	
		if v and not v.Dead then
			
			if v.Blueprint.Transport.TransportClass == 1 then
				CanUseTransports = true
				neededTable.Small = neededTable.Small + 1.0
                neededTable.Total = neededTable.Total + 1
				
			elseif v.Blueprint.Transport.TransportClass == 2 then
				CanUseTransports = true
				neededTable.Small = neededTable.Small + 0.34
				neededTable.Medium = neededTable.Medium + 1.0
                neededTable.Total = neededTable.Total + 1                    
				
			elseif v.Blueprint.Transport.TransportClass == 3 then
                CanUseTransports = true
				neededTable.Small = neededTable.Small + 0.5
				neededTable.Medium = neededTable.Medium + 0.25
				neededTable.Large = neededTable.Large + 1.0
                neededTable.Total = neededTable.Total + 1

			else
				LOG("*AI DEBUG "..aiBrain.Nickname.." "..platoon.BuilderName.." during GetTransports - "..v:GetBlueprint().Description.." has no transportClass value")
			end
		end	
	end

    if not CanUseTransports then
    
        if TransportDialog then
            LOG("*AI DEBUG "..aiBrain.Nickname.." "..platoon.BuilderName.." no units in platoon can use transports")
        end
        
        return false, false
    end
    
    
    -- COLLECTION PHASE - collect and count available transports

    local GetPlatoonPosition = GetPlatoonPosition
	local TableCopy = TableCopy
	local EntityContains = EntityContains
    local VDist2 = VDist2
	local WaitTicks = WaitTicks
    
	platoon.UsingTransport = true	-- this will keep the platoon from doing certain things while it's looking for transport
	
	-- OK - so we now have 2 lists of units and we want to make sure the 'specials' get utilized first
	-- so we'll add the specials to the Available list first, and then the standard ones
	-- in this way, the specials will get utilized first, making good use of both the UEF T2 gunship
	-- and the Cybran Gargantuan, if available
	local AvailableTransports = {}
    local transportcount = 0

    -- if the unit platoon is still available collect a list of all available transports
	if PlatoonExists(aiBrain,platoon) then
    
        if TransportDialog then
            LOG("*AI DEBUG "..aiBrain.Nickname.." "..platoon.BuilderName.." getting available transports")
        end

        -- move upto 15 army pool transports into the transport pool
		if armypooltransports[1] then

			for _,trans in armypooltransports do
            
                if IsBeingBuilt(trans) then
                    continue
                end
			
				if not trans.InUse then
                
                    if not trans.Assigning then
                    
                        transportcount = transportcount + 1				
                        AvailableTransports[transportcount] = trans

                        -- this puts specials into the transport pool -- occurs to me that they
                        -- may get stuck in here if it turns out we cant use transports
                        AssignUnitsToPlatoon( aiBrain, transportpool, {trans}, 'Support','none')
                    
                        -- limit collection of armypool transports to 15
                        if transportcount == 15 then
                            break
                        end
                    end
                    
				else
                    if TransportDialog then
                        LOG("*AI DEBUG "..aiBrain.Nickname.." "..platoon.BuilderName.." transport "..trans.EntityId.." in ArmyPool in Use or Assigning during collection")
                    end
                end
			end
		end

        -- count the total number of transports now fully available
		if TransportPoolTransports[1] then

			for _,trans in TransportPoolTransports do
            
                if IsBeingBuilt(trans) then
                    continue
                end
                
				if not trans.InUse then
                
                    if not trans.Assigning then
                
                        transportcount = transportcount + 1
                        AvailableTransports[transportcount] = trans

                    end
                    
				else
                
                    if TransportDialog then
                    
                        if trans.InUse then
                            LOG("*AI DEBUG "..aiBrain.Nickname.." "..platoon.BuilderName.." transport "..trans.EntityId.." in Use during collection")
                        end
                        if trans.Assigning then
                            LOG("*AI DEBUG "..aiBrain.Nickname.." "..platoon.BuilderName.." transport "..trans.EntityId.." Assigning during collection")
                        end
                        
                    end
                end
			end
		end

	end
	
    -- we no longer need the source lists
	armypooltransports = nil
	TransportPoolTransports = nil

    -- the platoon may have died while we did all this
	local location = false
	
    -- recheck the platoon again and store it's location
    -- if no location then platoon may be dead/disbanded
	if PlatoonExists(aiBrain,platoon) then
		for _,u in GetPlatoonUnits(platoon) do
			if not u.Dead then
                location = TableCopy(GetPlatoonPosition(platoon))
                break
			end
		end
	end	
	
	-- if we cant find any transports or platoon has no location - exit
	if transportcount < 1 or not location then
		if not location then
            if TransportDialog then
                LOG("*AI DEBUG "..aiBrain.Nickname.." "..platoon.BuilderName.." finds no platoon position")
            end
       		if transportcount > 0 then
                -- send all transports back into pool - which covers the specials (ie. UEF Gunships) 
                ForkThread( ReturnTransportsToPool, aiBrain, AvailableTransports, true )
            end
		end
		if transportcount < 1 then
            if TransportDialog then
                LOG("*AI DEBUG "..aiBrain.Nickname.." "..platoon.BuilderName.." no transports available")
            end
            aiBrain.TransportRequested = true
        end
		platoon.UsingTransport = false
		return false, false
	end

	
	-- Returns the number of slots the transport has available
	-- Originally, this function just counted the number of attachpoint bones of each size on the model
	-- however, this does not seem to work correctly - ie. UEF T3 Transport
	-- says it has 12 Large Attachpoints but will only carry 8 large units
	-- so I replaced that with some hardcoded values to improve performance, as each new transport
	-- unit comes into play, I'll cache those values on the brain so I never have to look them up again
	-- setup global table to contain Transport values - in this way we always have a reference to them
	-- without having to reread the bones or do all the EntityCategory checks from below
	local function GetNumTransportSlots( unit )
	
		if not aiBrain.TransportSlotTable then
			aiBrain.TransportSlotTable = {}
		end
	
		local id = unit.UnitId
		if aiBrain.TransportSlotTable[id] then
			return aiBrain.TransportSlotTable[id]
		else
			local EntityCategoryContains = EntityCategoryContains
			local bones = { Large = 0, Medium = 0, Small = 0,}
			if EntityCategoryContains( categories.xea0306, unit) then
				bones.Large = 8
				bones.Medium = 10
				bones.Small = 24
			elseif EntityCategoryContains( categories.uea0203, unit) then
				bones.Large = 0
				bones.Medium = 1
				bones.Small = 1
			elseif EntityCategoryContains( categories.uea0104, unit) then
				bones.Large = 3
				bones.Medium = 6
				bones.Small = 14
			elseif EntityCategoryContains( categories.uea0107, unit) then
				bones.Large = 1
				bones.Medium = 2
				bones.Small = 6
			elseif EntityCategoryContains( categories.uaa0107, unit) then
				bones.Large = 1
				bones.Medium = 3
				bones.Small = 6
			elseif EntityCategoryContains( categories.uaa0104, unit) then
				bones.Large = 3
				bones.Medium = 6
				bones.Small = 12
			elseif EntityCategoryContains( categories.ura0107, unit) then
				bones.Large = 1
				bones.Medium = 2
				bones.Small = 6
			elseif EntityCategoryContains( categories.ura0104, unit) then
				bones.Large = 2
				bones.Medium = 4
				bones.Small = 10
			elseif EntityCategoryContains( categories.xsa0107, unit) then
				bones.Large = 1
				bones.Medium = 4
				bones.Small = 8
			elseif EntityCategoryContains( categories.xsa0104, unit) then
				bones.Large = 4
				bones.Medium = 8
				bones.Small = 16
			-- BO Aeon transport
			elseif bones.Small == 0 and (categories.baa0309 and EntityCategoryContains( categories.baa0309, unit)) then
				bones.Large = 6
				bones.Medium = 10
				bones.Small = 16
			-- BO Cybran transport
			elseif bones.Small == 0 and (categories.bra0309 and EntityCategoryContains( categories.bra0309, unit)) then
				bones.Large = 3
				bones.Medium = 12
				bones.Small = 14
			-- BrewLan Cybran transport
			elseif bones.Small == 0 and (categories.sra0306 and EntityCategoryContains( categories.sra0306, unit)) then
				bones.Large = 4
				bones.Medium = 8
				bones.Small = 16
			-- Gargantua
			elseif bones.Small == 0 and (categories.bra0409 and EntityCategoryContains( categories.bra0409, unit)) then
				bones.Large = 20
				bones.Medium = 4
				bones.Small = 4
			-- BO Sera transport
			elseif bones.Small == 0 and (categories.bsa0309 and EntityCategoryContains( categories.bsa0309, unit)) then
				bones.Large = 8
				bones.Medium = 10
				bones.Small = 28
			-- BrewLAN Seraphim transport
			elseif bones.Small == 0 and (categories.ssa0306 and EntityCategoryContains( categories.ssa0306, unit)) then
				bones.Large = 7
				bones.Medium = 15
				bones.Small = 32
			end
			aiBrain.TransportSlotTable[id] = bones
			return bones
		end
	end
    
    -- ASSIGNMENT PHASE - assign transports to the task until the requirements are met
	
	-- we'll accumulate the slots from transports as we assign them
	-- this will allow us to save a bunch of effort if we simply dont have enough transport capacity

	local GetFuelRatio = GetFuelRatio
	local GetPosition = GetPosition
	local IsBeingBuilt = IsBeingBuilt
    local IsUnitState = IsUnitState	

    -- this flag signifies the end of the assignment phase when we have enough transports to do the job
    -- if we cannot fulfill a request for transports then the brain is marked as needing to build transport
	CanUseTransports = false

	local Collected = { Large = 0, Medium = 0, Small = 0 }
    local counter = 0
    local transports = {}			-- this will hold the data for all of the eligible transports    
	local out_of_range = false
    local FuelRequired = .5
    local HealthRequired = .30

    local id, range, unitPos

	-- loop thru all transports and filter out those that dont pass muster
	for k,transport in AvailableTransports do
        -- we have enough transport collected
        if CanUseTransports then
            break
        end
		if not transport.Dead then
			-- use only those that are not in use, not being built and have > 50% fuel and > 70% health
			if (not transport.InUse) and (not transport.Assigning) and (not IsBeingBuilt(transport)) and ( GetFuelRatio(transport) == -1 or GetFuelRatio(transport) > FuelRequired) and transport:GetHealthPercent() > HealthRequired  then
				-- use only those which are not already busy or are not loading already
				if (not IsUnitState( transport, 'Busy')) and (not IsUnitState( transport, 'TransportLoading')) then
					-- deny use of T1 transport to platoons needing more than 1 large transport
					if (not IsEngineer) and EntityContains( categories.TECH1, transport ) and neededTable.Large > 1 then
						continue
					-- insert available transport into list of usable transports
					else
						unitPos = GetPosition(transport)
						range = VDist2( unitPos[1],unitPos[3], location[1], location[3] )
						-- limit to 18 km range -- this insures that transport wont expire before loading takes place
						-- as loading has a 120 second time limit --
						if range < 1800 then
                            -- mark the transport as being assigned 
                            -- to prevent it from being picked up in another transport collection
                            if TransportDialog then
                                LOG("*AI DEBUG "..aiBrain.Nickname.." "..platoon.BuilderName.." transport "..transport.EntityId.." marked for assignment")
                            end
                            
                            transport.Assigning = true
							id = transport.UnitId
                            -- add the transports slots to the collected table
							if not aiBrain.TransportSlotTable[id] then
								GetNumTransportSlots( transport )
							end

							counter = counter + 1
							transports[counter] = { Unit = transport, Distance = range, Slots = TableCopy(aiBrain.TransportSlotTable[id]) }
							Collected.Large = Collected.Large + transports[counter].Slots.Large
							Collected.Medium = Collected.Medium + transports[counter].Slots.Medium
							Collected.Small = Collected.Small + transports[counter].Slots.Small
							-- if we have enough collected capacity for each type then CanUseTransports is true which will break us out of collection
							if Collected.Large >= neededTable.Large and Collected.Medium >= neededTable.Medium and Collected.Small >= neededTable.Small then
								CanUseTransports = true
							end
						else
                            if TransportDialog then
                                LOG("*AI DEBUG "..aiBrain.Nickname.." "..platoon.BuilderName.." transport "..transport.EntityId.." rejected - out of range at "..range)
                            end
							out_of_range = true
						end
					end
				end
			else
                if TransportDialog then
                    LOG("*AI DEBUG "..aiBrain.Nickname.." "..platoon.BuilderName.." transport "..transport.EntityId.." rejected -  In Use "..repr(transport.InUse).." - Assigning "..repr(transport.Assigning).." - BeingBuilt "..repr(IsBeingBuilt(transport)).." or Low Fuel/Health")
                end
                if not transport.Dead then
                    ForkThread( ReturnTransportsToPool, aiBrain, {transport}, true )
                end
                AvailableTransports[k] = nil
            end
		end
	end

	if not CanUseTransports then
		if not out_of_range then
			-- let the brain know we couldn't fill a transport request by a ground platoon
			aiBrain.TransportRequested = true
		end
        
        if TransportDialog then
            LOG("*AI DEBUG "..aiBrain.Nickname.." "..platoon.BuilderName.." unable to locate enough transport")
        end
		
        AvailableTransports = aiBrain:RebuildTable(AvailableTransports)
		-- send all transports back into pool - which covers the specials (ie. UEF Gunships) 
		ForkThread( ReturnTransportsToPool, aiBrain, AvailableTransports, true )
		platoon.UsingTransport = false
        return false, false
	end
	
	Collected = nil
	
	-- ASSIGNMENT PHASE -- 
	-- at this point we have a list of all the eligible transports in range in the TRANSPORTS table
	AvailableTransports = nil	-- we dont need this anymore
	local transportplatoon = false	
	
    if CanUseTransports and counter > 0 then
		CanUseTransports = false
		counter = 0
		
		-- sort the available transports by range --
		TableSort(transports, function(a,b) return a.Distance < b.Distance end )
        
        if TransportDialog then
            LOG("*AI DEBUG "..aiBrain.Nickname.." "..platoon.BuilderName.." assigning units to transports")
        end
		
        -- loop thru the transports and assess how many units of each size can be carried
		-- assign each transport to the transport platoon until the needs are filled
		-- after that, mark each remaining transport as not InUse
        for _,v in transports do
			local transport = v.Unit
			local AvailableSlots = v.Slots

			-- if we still need transport capacity and this transport is in the Transport or Army Pool
            if not transport.Dead and (not CanUseTransports) and (transport.PlatoonHandle == aiBrain.TransportPool or transport.PlatoonHandle == aiBrain.ArmyPool ) then
				-- mark the transport as InUse
				transport.InUse = true
				-- count the number of transports used
				counter = counter + 1
				-- create a platoon for the transports
				if not transportplatoon then
					local ident = Random(10000,99999)
					transportplatoon = aiBrain:MakePlatoon('TransportPlatoon '..tostring(ident),'none')
					transportplatoon.PlanName = 'TransportUnits '..tostring(ident)
					transportplatoon.BuilderName = 'Load and Transport '..tostring(ident)
                    transportplatoon.UsingTransport = true      -- keep this platoon from being reviewed in a merge
                    
                    if TransportDialog then
                        LOG("*AI DEBUG "..aiBrain.Nickname.." "..platoon.BuilderName.." "..transportplatoon.BuilderName.." created for service ")
                    end
				end
				
                if TransportDialog then
                    LOG("*AI DEBUG "..aiBrain.Nickname.." "..platoon.BuilderName.." "..transportplatoon.BuilderName.." adds transport "..transport.EntityId)
                end
                
				AssignUnitsToPlatoon( aiBrain, transportplatoon, {transport}, 'Support', 'BlockFormation')
				IssueToUnitClearCommands(transport)
				IssueToUnitMove(transport, location )

                while neededTable.Large >= 1 and AvailableSlots.Large >= 1 do
                    neededTable.Large = neededTable.Large - 1.0
                    AvailableSlots.Large = AvailableSlots.Large - 1.0
					AvailableSlots.Medium = AvailableSlots.Medium - 0.25
                    AvailableSlots.Small = AvailableSlots.Small - 0.34
				end
                while neededTable.Medium >= 1 and AvailableSlots.Medium >= 1 do
                    neededTable.Medium = neededTable.Medium - 1.0
                    AvailableSlots.Medium = AvailableSlots.Medium - 1.0
					AvailableSlots.Small = AvailableSlots.Small - 0.34
                end
                while neededTable.Small >= 1 and AvailableSlots.Small >= 1 do
                    neededTable.Small = neededTable.Small - 1.0
					if Special then
						AvailableSlots.Medium = AvailableSlots.Medium - .10 -- yes .1 so that UEF Gunship wont be able to carry more than 1 unit
					end
                    AvailableSlots.Small = AvailableSlots.Small - 1.0
                end
				-- if no more slots are needed signal that we have all the transport we require
                if neededTable.Small < 1 and neededTable.Medium < 1 and neededTable.Large < 1 then
                    CanUseTransports = true
                end
			end
            -- mark each transport (used or not) as no longer in Assignment
            transport.Assigning = false
        end
    end

	-- one last check for the validity of both unit and transport platoons
	if CanUseTransports and counter > 0 then
		counter = 0
		local location = false
		if PlatoonExists(aiBrain, platoon) then
			for _,u in GetPlatoonUnits(platoon) do
				if not u.Dead then
					counter = counter + 1
				end
			end
			if counter > 0 then
				location = TableCopy(GetPlatoonPosition(platoon))
			end
		end
		if not transportplatoon or counter < 1 then
            if TransportDialog then
                if not transportplatoon then
                    LOG("*AI DEBUG "..aiBrain.Nickname.." "..platoon.BuilderName.." transport platoon dead after assignmnet "..repr(transportplatoon))
                else
                    LOG("*AI DEBUG "..aiBrain.Nickname.." "..platoon.BuilderName.." unit platoon dead after assignment ")
                end
            end
			CanUseTransports = false
		end
	end
	
	transports = nil
	
	-- if we need more transport then fail (I no longer permit partial transportation)
	-- or if some other situation (dead units) -- send the transports back to the pool
    if not CanUseTransports or counter < 1 then

		if transportplatoon then
            if TransportDialog then
                LOG("*AI DEBUG "..aiBrain.Nickname.." "..platoon.BuilderName.." cannot be serviced by "..transportplatoon.BuilderName )
            end
            for _,transport in GetPlatoonUnits(transportplatoon) do
                -- unmark the transport
                --transport.InUse = false
                if not transport.Dead then
                    -- and return it to the transport pool
                    ForkTo( ReturnTransportsToPool, aiBrain, {transport}, true )
                end
            end
		end
		platoon.UsingTransport = false
        return false, false
    else
        if TransportDialog then
            LOG("*AI DEBUG "..aiBrain.Nickname.." "..platoon.BuilderName.." "..transportplatoon.BuilderName.." authorized for use" )
        end
        return counter, transportplatoon
    end
	
end

-- whenever the AI cannot find enough transports to move a platoon it sets a value on the brain indicating that need
-- this function is run whenever a factory responds to that need and starts building them - clearing the need flag
function ResetBrainNeedsTransport( aiBrain )
    aiBrain.TransportRequested = nil
end

--  This routine should get transports on the way back to an existing base 
--  BEFORE marking them as not 'InUse' and adding them to the Transport Pool
function ReturnTransportsToPool( aiBrain, units, move )


    local RandomLocation = import('/lua/ai/aiutilities.lua').RandomLocation
    local VDist3 = VDist3
    local unitcount = 0
    local baseposition, reason, returnpool, safepath, unitposition

    -- cycle thru the transports, insure unloaded and assign to correct pool
    for k,v in units do
        if IsBeingBuilt(v) then     -- ignore under construction
            units[v] = nil
            continue
        end
        if not v.Dead and TransportDialog then
            LOG("*AI DEBUG "..aiBrain.Nickname.." transport "..v.EntityId.." "..v:GetBlueprint().Description.." Returning to Pool  InUse is "..repr(v.InUse) )
        end
        if v.WatchLoadingThread then
            KillThread( v.WatchLoadingThread)
            v.WatchLoadingThread = nil
        end
        if v.WatchTravelThread then
            KillThread( v.WatchTravelThread)
            v.WatchTravelThread = nil
        end
        if v.WatchUnloadThread then
            KillThread( v.WatchUnloadThread)
            v.WatchUnloadThread = nil
        end
        if v.Dead then
            if TransportDialog then
                LOG("*AI DEBUG "..aiBrain.Nickname.." transport "..v.EntityId.." dead during Return to Pool")
            end
            units[v] = nil
            continue
        end
        
        unitcount = unitcount + 1

		-- unload any units it might have and process for repair/refuel
		if EntityCategoryContains( categories.TRANSPORTFOCUS + categories.uea0203, v ) then
            if TableGetn(v:GetCargo()) > 0 then
                if TransportDialog then
                    LOG("*AI DEBUG "..aiBrain.Nickname.." transport "..v.EntityId.." has unloaded units")
                end
                local unloadedlist = v:GetCargo()
                IssueTransportUnload(v, v:GetPosition())
                WaitTicks(3)
                for _,unloadedunit in unloadedlist do
                    ForkTo( ReturnUnloadedUnitToPool, aiBrain, unloadedunit )
                end
            end
            v.InUse = nil
            v.Assigning = nil
            -- if the transport needs refuel/repair - remove it from further processing
            if ProcessAirUnits( v, aiBrain) then
                units[k] = nil
            end
        end
    end

    -- process whats left, getting them moving, and assign back to correct pool
	if unitcount > 0 and move then
		units = aiBrain:RebuildTable(units)     -- remove those sent for repair/refuel 
		for k,v in units do
			if v and not v.Dead and (not v.InUse) and (not v.Assigning) then
                returnpool = aiBrain:MakePlatoon('TransportRTB'..tostring(v.EntityId), 'none')
                returnpool.BuilderName = 'TransportRTB'..tostring(v.EntityId)
                returnpool.PlanName = returnpool.BuilderName
                AssignUnitsToPlatoon( aiBrain, returnpool, {v}, 'Unassigned', '')
                if TransportDialog then
                    LOG("*AI DEBUG "..aiBrain.Nickname.." "..returnpool.BuilderName.." Transport "..v.EntityId.." assigned" )
                end
                v.PlatoonHandle = returnpool
                unitposition = v:GetPosition()
                baseposition = aiBrain:FindClosestBuilderManagerPosition(unitposition)
				local x, z
                if baseposition then
                    x = baseposition[1]
                    z = baseposition[3]
                else
                    return
                end
                baseposition = RandomLocation(x,z)
                IssueToUnitClearCommands(v)
                if VDist3( baseposition, unitposition ) > 100 then
                    -- this requests a path for the transport with a threat allowance of 20 - which is kinda steep sometimes
					local safePath, reason = NavUtils.PathToWithThreatThreshold('Air', unitposition, baseposition, aiBrain, NavUtils.ThreatFunctions.AntiAir, 50, aiBrain.IMAPConfig.Rings)
                    if safePath then
                        if TransportDialog then
                            LOG("*AI DEBUG "..aiBrain.Nickname.." "..returnpool.BuilderName.." Transport "..v.EntityId.." gets RTB path of "..repr(safePath))
                        end
                        -- use path
                        for _,p in safePath do
                            IssueToUnitMove(v, p )
                        end
                    else
                        if TransportDialog then
                            LOG("*AI DEBUG "..aiBrain.Nickname.." "..returnpool.BuilderName.." Transport "..v.EntityId.." no safe path for RTB -- home -- after drop - going direct")
                        end
                        -- go direct -- possibly bad
                        IssueToUnitMove(v, baseposition )
                    end
                else
                    IssueToUnitMove(v, baseposition)
                end

				-- move the unit to the correct pool - pure transports to Transport Pool
				-- all others -- including temporary transports (UEF T2 gunship) to Army Pool
				if not v.Dead then
					if EntityContains( categories.TRANSPORTFOCUS - categories.uea0203, v ) then
                        if v.PlatoonHandle != aiBrain.TransportPool then
                            if TransportDialog then
                                LOG("*AI DEBUG "..aiBrain.Nickname.." "..v.PlatoonHandle.BuilderName.." transport "..v.EntityId.." now in the Transport Pool  InUse is "..repr(v.InUse))
                            end
                            AssignUnitsToPlatoon( aiBrain, aiBrain.TransportPool, {v}, 'Support', '' )
                            v.PlatoonHandle = aiBrain.TransportPool
                            v.InUse = false
                            v.Assigning = false                            
                        end
					else
                        if TransportDialog then
                            LOG("*AI DEBUG "..aiBrain.Nickname.." "..v.PlatoonHandle.BuilderName.." assigned unit "..v.EntityId.." "..v:GetBlueprint().Description.." to the Army Pool" )
                        end
						AssignUnitsToPlatoon( aiBrain, aiBrain.ArmyPool, {v}, 'Unassigned', '' )
						v.PlatoonHandle = aiBrain.ArmyPool
       					v.InUse = false
                        v.Assigning = false
					end
				end
			end
		end
	end
	if not aiBrain.CheckTransportPoolThread then
		aiBrain.CheckTransportPoolThread = ForkThread( CheckTransportPool, aiBrain )
	end
end

-- This gets called whenever a unit failed to unload properly - rare
-- Forces the unload & RTB the unit
function ReturnUnloadedUnitToPool( aiBrain, unit )

	local attached = true
	
	if not unit.Dead then
		IssueToUnitClearCommands(unit)
		local ident = Random(1,999999)
		local returnpool = aiBrain:MakePlatoon('ReturnToPool'..tostring(ident), 'none')
		AssignUnitsToPlatoon( aiBrain, returnpool, {unit}, 'Unassigned', 'None' )
		returnpool.PlanName = 'ReturnToBaseAI'
		returnpool.BuilderName = 'FailedUnload'
		while attached and not unit.Dead do
			attached = false
			if IsUnitState( unit, 'Attached') then
				attached = true
                WaitTicks(20)
			end
		end
		returnpool:SetAIPlan('ReturnToBaseAI', aiBrain )
	end
	return
end

-- Find enough transports and move the platoon to its destination 
    -- destination - the destination location
    -- attempts - how many tries will be made to get transport
    -- bSkipLastMove - make drop at closest safe marker rather than at destination
    -- platoonpath - source platoon can optionally feed it's current travel path in order to provide additional alternate drop points if the destination is not good
function SendPlatoonWithTransports(aiBrain, platoon, destination, attempts, bSkipLastMove, platoonpath )

    -- destination must be in playable areas --
    if not InPlayableArea(destination) then
        return false
    end

	if (not platoon.MovementLayer) then
        import("/lua/ai/aiattackutilities.lua").GetMostRestrictiveLayer(platoon)
    end

    local MovementLayer = platoon.MovementLayer    

	if MovementLayer == 'Land' or MovementLayer == 'Amphibious' then
		local AIGetMarkersAroundLocation = import('/lua/ai/aiutilities.lua').AIGetMarkersAroundLocation
        local CalculatePlatoonThreat = moho.platoon_methods.CalculatePlatoonThreat
        local GetPlatoonPosition = GetPlatoonPosition
        local GetPlatoonUnits = GetPlatoonUnits
        local GetSurfaceHeight = GetSurfaceHeight
        local GetTerrainHeight = GetTerrainHeight
        local GetThreatAtPosition = moho.aibrain_methods.GetThreatAtPosition
		local GetUnitsAroundPoint = moho.aibrain_methods.GetUnitsAroundPoint
        local PlatoonCategoryCount = moho.platoon_methods.PlatoonCategoryCount
        local PlatoonExists = PlatoonExists

        local TableCat = table.cat
        local TableCopy = TableCopy
        local TableEqual = table.equal
        local MathFloor = MathFloor
        local MathLog10 = math.log10
        local VDist2Sq = VDist2Sq
        local VDist3 = VDist3
        local WaitTicks = WaitTicks

        local surthreat = 0
        local airthreat = 0
        local counter = 0
		local bUsedTransports = false
		local transportplatoon = false    

		local IsEngineer = PlatoonCategoryCount( platoon, ENGINEERS ) > 0

        local ALLUNITS = categories.ALLUNITS
        local TESTUNITS = ALLUNITS - categories.FACTORY - categories.ECONOMIC - categories.SHIELD - categories.WALL

		local airthreat, airthreatMax, Defense, markerrange, mythreat, path, reason, pathlength, surthreat, transportcount,units, transportLocation

		-- prohibit LAND platoons from traveling to water locations
		if MovementLayer == 'Land' then
			if GetTerrainHeight(destination[1], destination[3]) < GetSurfaceHeight(destination[1], destination[3]) - 1 then 
                if TransportDialog then	
                    LOG("*AI DEBUG "..aiBrain.Nickname.." SendPlatWTrans "..repr(platoon.BuilderName).." "..repr(platoon.BuilderInstance).." trying to go to WATER destination "..repr(destination) )
                end
				return false
			end
		end

		-- make the requested number of attempts to get transports - 12 second delay between attempts
		for counter = 1, attempts do
			if PlatoonExists( aiBrain, platoon ) then
				-- check if we can get enough transport and how many transports we are using
				-- this call will return the # of units transported (true) or false, if true, the platoon holding the transports or false
				bUsedTransports, transportplatoon = GetTransports( platoon, aiBrain )
				if bUsedTransports or counter == attempts then
					break
				end
				WaitTicks(120)
			end
		end

		-- if we didnt use transports
		if (not bUsedTransports) then
			if transportplatoon then
				ForkTo( ReturnTransportsToPool, aiBrain, GetPlatoonUnits(transportplatoon), true)
			end
			return false
		end
			
			-- a local function to get the real surface and air threat at a position based on known units rather than using the threat map
			-- we also pull the value from the threat map so we can get an idea of how often it's a better value
			-- I'm thinking of mixing the two values so that it will error on the side of caution
			local GetRealThreatAtPosition = function( position, range )
                
				local IMAPblocks = aiBrain.IMAPConfig.Rings or 1
				local sfake = GetThreatAtPosition( aiBrain, position, IMAPblocks, true, 'AntiSurface' )
				local afake = GetThreatAtPosition( aiBrain, position, IMAPblocks, true, 'AntiAir' )
                airthreat = 0
                surthreat = 0
				local eunits = GetUnitsAroundPoint( aiBrain, TESTUNITS, position, range,  'Enemy')
				if eunits then
					for _,u in eunits do
						if not u.Dead then
                            Defense = u.Blueprint.Defense
							airthreat = airthreat + Defense.AirThreatLevel
							surthreat = surthreat + Defense.SurfaceThreatLevel
						end
					end
                end
				
                -- if there is IMAP threat and it's greater than what we actually see
                -- use the sum of both * .5
				if sfake > 0 and sfake > surthreat then
					surthreat = (surthreat + sfake) * .5
				end
				
				if afake > 0 and afake > airthreat then
					airthreat = (airthreat + afake) * .5
				end
                
                return surthreat, airthreat
			end

			-- a local function to find an alternate Drop point which satisfies both transports and platoon for threat and a path to the goal
			local FindSafeDropZoneWithPath = function( platoon, transportplatoon, markerTypes, markerrange, destination, threatMax, airthreatMax, threatType, layer)
				
				local markerlist = {}
                local atest, stest
                local landpath,  landpathlength, landreason, lastlocationtested, path, pathlength, reason
				-- locate the requested markers within markerrange of the supplied location	that the platoon can safely land at
				for _,v in markerTypes do
					markerlist = TableCat( markerlist, AIGetMarkersAroundLocation(aiBrain, v, destination, markerrange, 0, threatMax, 0, 'AntiSurface') )
				end
				-- sort the markers by closest distance to final destination
				TableSort( markerlist, function(a,b) local VDist2Sq = VDist2Sq return VDist2Sq( a.Position[1],a.Position[3], destination[1],destination[3] ) < VDist2Sq( b.Position[1],b.Position[3], destination[1],destination[3] )  end )

				-- loop thru each marker -- see if you can form a safe path on the surface 
				-- and a safe path for the transports -- use the first one that satisfies both
				for _, v in markerlist do
                    if lastlocationtested and TableEqual(lastlocationtested, v.Position) then
                        continue
                    end

                    lastlocationtested = TableCopy( v.Position )
					-- test the real values for that position
					stest, atest = GetRealThreatAtPosition( lastlocationtested, 80 )
			
                    if TransportDialog then                    
                        LOG("*AI DEBUG "..aiBrain.Nickname.." "..transportplatoon.BuilderName.." examines position "..repr(v.Name).." "..repr(lastlocationtested).."  Surface threat "..stest.." -- Air threat "..atest)
                    end
		
					if stest <= threatMax and atest <= airthreatMax then
                        landpath = false
                        landpathlength = 0
						-- can the platoon path safely from this marker to the final destination 
						landpath, landreason, landpathlength = NavUtils.PathToWithThreatThreshold(layer, destination, lastlocationtested, aiBrain, NavUtils.ThreatFunctions.AntiAir, threatMax, aiBrain.IMAPConfig.Rings)
						-- can the transports reach that marker ?
						if landpath then
                            path = false
                            pathlength = 0
                            path, reason, pathlength = NavUtils.PathToWithThreatThreshold('Air', lastlocationtested, GetPlatoonPosition(platoon), aiBrain, NavUtils.ThreatFunctions.AntiAir, airthreatMax, aiBrain.IMAPConfig.Rings)
							if path then
                                if TransportDialog then
                                    LOG("*AI DEBUG "..aiBrain.Nickname.." "..repr(platoon.BuilderName).." gets path to "..repr(destination).." from landing at "..repr(lastlocationtested).." path length is "..pathlength.." using threatmax of "..threatMax)
                                    LOG("*AI DEBUG "..aiBrain.Nickname.." "..repr(platoon.BuilderName).." path reason "..landreason.." route is "..repr(landpath))
                                end
								return lastlocationtested, v.Name
							else
                                if TransportDialog then
                                    LOG("*AI DEBUG "..aiBrain.Nickname.." "..repr(platoon.BuilderName).." got transports but they cannot find a safe drop point")
                                end
                            end
						end
                        if platoonpath then
                            lastlocationtested = false
                            for k,v in platoonpath do
                                stest, atest = GetRealThreatAtPosition( v, 80 )
                                if stest <= threatMax and atest <= airthreatMax then
                                    lastlocationtested = TableCopy(v)
                                end
                            end
                            if lastlocationtested then
                                if TransportDialog then
                                    LOG("*AI DEBUG "..aiBrain.Nickname.." "..repr(platoon.BuilderName).." using platoon path position "..repr(v) )
                                end
                                return lastlocationtested, 'booga'
                            end
                        end
					end
				end
				return false, nil
			end
	

		-- FIND A DROP ZONE FOR THE TRANSPORTS
		-- this is based upon the enemy threat at the destination and the threat of the unit platoon and the transport platoon

		-- a threat value for the transports based upon the number of transports
		transportcount = TableGetn( GetPlatoonUnits(transportplatoon))
		airthreatMax = transportcount * 5
		airthreatMax = airthreatMax + ( airthreatMax * MathLog10(transportcount))

        if TransportDialog then
            LOG("*AI DEBUG "..aiBrain.Nickname.." "..repr(platoon.BuilderName).." "..transportplatoon.BuilderName.." with "..transportcount.." airthreatMax = "..repr(airthreatMax).." extra calc was "..math.log10(transportcount).." seeking dropzone" )
        end

		-- this is the desired drop location
		transportLocation = TableCopy(destination)

		-- the threat of the unit platoon
		mythreat = CalculatePlatoonThreat( platoon, 'Surface', ALLUNITS)

		if not mythreat or mythreat < 5 then 
			mythreat = 5
		end

		-- get the real known threat at the destination within 80 grids
		surthreat, airthreat = GetRealThreatAtPosition( destination, 80 )

		-- if the destination doesn't look good, use alternate or false
		if surthreat > mythreat or airthreat > airthreatMax then
            if (mythreat * 1.5) > surthreat then
                -- otherwise we'll look for a safe drop zone at least 50% closer than we already are
                markerrange = VDist3( GetPlatoonPosition(platoon), destination ) * .5
                if TransportDialog then
                    LOG("*AI DEBUG "..aiBrain.Nickname.." "..repr(platoon.BuilderName).." carried by "..transportplatoon.BuilderName.." seeking alternate landing zone within "..markerrange.." of destination "..repr(destination))
                end
                transportLocation = false
                -- If destination is too hot -- locate the nearest movement marker that is safe
                if MovementLayer == 'Amphibious' then
                    transportLocation = FindSafeDropZoneWithPath( platoon, transportplatoon, {'Amphibious Path Node','Land Path Node','Transport Marker'}, markerrange, destination, mythreat, airthreatMax, 'AntiSurface', MovementLayer)
                else
                    transportLocation = FindSafeDropZoneWithPath( platoon, transportplatoon, {'Land Path Node','Transport Marker'}, markerrange, destination, mythreat, airthreatMax, 'AntiSurface', MovementLayer)
                end
                if transportLocation then
                    if TransportDialog then
                        if surthreat > mythreat then
                            LOG("*AI DEBUG "..aiBrain.Nickname.." "..transportplatoon.BuilderName.." finds alternate landing position at "..repr(transportLocation).." surthreat is "..surthreat.." vs. mine "..mythreat)
                        else
                            LOG("*AI DEBUG "..aiBrain.Nickname.." "..transportplatoon.BuilderName.." finds alternate landing position at "..repr(transportLocation).." AIRthreat is "..airthreat.." vs. my max of "..airthreatMax)
                        end
                    end
                end
            else
                transportLocation = false
                if TransportDialog then
                    LOG("*AI DEBUG "..aiBrain.Nickname.." "..repr(platoon.BuilderName).." says simply too much threat for me - "..surthreat.." vs "..mythreat.." - aborting transport call")
                end
            end
        end

		-- if no alternate, or either platoon has died, return the transports and abort transport
		if not transportLocation or (not PlatoonExists(aiBrain, platoon)) or (not PlatoonExists(aiBrain,transportplatoon)) then
			if PlatoonExists(aiBrain,transportplatoon) then
                if TransportDialog then
                    LOG("*AI DEBUG "..aiBrain.Nickname.." "..repr(platoon.BuilderName).." "..transportplatoon.BuilderName.." cannot find safe transport position to "..repr(destination).." - "..MovementLayer.." - transport request denied")
                end
				ForkTo( ReturnTransportsToPool, aiBrain, GetPlatoonUnits(transportplatoon), true)
			end

            if PlatoonExists(aiBrain,platoon) then
                platoon.UsingTransport = false
            end
			return false
		end

		-- correct drop location for surface height
		transportLocation[2] = GetSurfaceHeight(transportLocation[1], transportLocation[3])

		if platoon.MoveThread then
			platoon:KillMoveThread()
		end

		-- LOAD THE TRANSPORTS AND DELIVER --
		-- we stay in this function until we load, move and arrive or die
		-- we'll get a false return if then entire unit platoon cannot be transported
		-- note how we pass the IsEngineer flag -- alters the behaviour of the transport
		if platoon.LogDebug then
			platoon:LogDebug(string.format('Raid Platoon using transports'))
		end
		bUsedTransports = UseTransports( aiBrain, transportplatoon, transportLocation, platoon, IsEngineer )

		-- if platoon died or we couldn't use transports -- exit
		if (not platoon) or (not PlatoonExists(aiBrain, platoon)) or (not bUsedTransports) then
			-- if transports RTB them --
			if PlatoonExists(aiBrain,transportplatoon) then
				ForkTo( ReturnTransportsToPool, aiBrain, GetPlatoonUnits(transportplatoon), true)
			end
			return false
		end

		-- PROCESS THE PLATOON AFTER LANDING --
		-- if we used transports then process any unlanded units
		-- seriously though - UseTransports should have dealt with that
		-- anyhow - forcibly detach the unit and re-enable standard conditions
		units = GetPlatoonUnits(platoon)

		for _,v in units do
			if not v.Dead and IsUnitState( v, 'Attached' ) then
				v:DetachFrom()
				v:SetCanTakeDamage(true)
				v:SetDoNotTarget(false)
				v:SetReclaimable(true)
				v:SetCapturable(true)
				v:ShowBone(0, true)
				v:MarkWeaponsOnTransport(v, false)
			end
		end

		if platoon.LogDebug then
			platoon:LogDebug(string.format('Raid Platoon getting commands post drop off'))
		end

		-- set path to destination if we landed anywhere else but the destination
		-- All platoons except engineers (which move themselves) get this behavior
		if (not IsEngineer) and GetPlatoonPosition(platoon) != destination then
			if not PlatoonExists( aiBrain, platoon ) or not GetPlatoonPosition(platoon) then
				return false
			end

			-- path from where we are to the destination - use inflated threat to get there --
			path = NavUtils.PathToWithThreatThreshold(MovementLayer, GetPlatoonPosition(platoon), destination, aiBrain, NavUtils.ThreatFunctions.AntiSurface,  mythreat * 1.25, aiBrain.IMAPConfig.Rings)

			if PlatoonExists( aiBrain, platoon ) then
				-- if no path then fail otherwise use it
				if not path and destination != nil then
					return false
				elseif path then
					platoon.MoveThread = platoon:ForkThread( platoon.MovePlatoon, path, 'AttackFormation', true )
				end
			end
		end
	end
    if platoon.LogDebug then
		platoon:LogDebug(string.format('Raid Platoon existing transport function'))
	end
	return PlatoonExists( aiBrain, platoon )
    
end

-- This function actually loads and moves units on transports using a safe path to the location desired
-- Just a personal note - this whole transport thing is a BITCH
-- This was one of the first tasks I tackled and years later I still find myself coming back to it again and again - argh
function UseTransports( aiBrain, transports, location, UnitPlatoon, IsEngineer )

	local TableCopy = TableCopy
	local EntityContains = EntityContains
	local TableGetn = TableGetn
	local TableInsert = TableInsert

	local WaitTicks = WaitTicks
	
	local PlatoonExists = PlatoonExists
	local GetBlueprint = moho.entity_methods.GetBlueprint
    local GetPlatoonPosition = GetPlatoonPosition
    local GetPlatoonUnits = GetPlatoonUnits

    local transportTable = {}	
	local counter = 0
	
	-- check the transport platoon and count - load the transport table
	-- process any toggles (stealth, etc.) the transport may have
	if PlatoonExists( aiBrain, transports ) then

		for _,v in GetPlatoonUnits(transports) do
			if not v.Dead then
				if v:TestToggleCaps('RULEUTC_StealthToggle') then
					v:SetScriptBit('RULEUTC_StealthToggle', false)
				end
				if v:TestToggleCaps('RULEUTC_CloakToggle') then
					v:SetScriptBit('RULEUTC_CloakToggle', false)
				end
				if v:TestToggleCaps('RULEUTC_IntelToggle') then
					v:SetScriptBit('RULEUTC_IntelToggle', false)
				end
			
				local slots = TableCopy( aiBrain.TransportSlotTable[v.UnitId] )
				counter = counter + 1
				transportTable[counter] = {	Transport = v, LargeSlots = slots.Large, MediumSlots = slots.Medium, SmallSlots = slots.Small, Units = { ["Small"] = {}, ["Medium"] = {}, ["Large"] = {} } }
			end
		end
	end
	
	if counter < 1 then
    
        UnitPlatoon.UsingTransport = false
        
		return false
    end

	-- This routine allocates the units to specific transports
	-- Units are injected on a TransportClass basis ( 3 - 2 - 1 )
	-- As each unit is assigned - the transport has its remaining slot count
	-- reduced & the unit is added to the list assigned to that transport
	local function SortUnitsOnTransports( transportTable, unitTable )
        
		local leftoverUnits = {}
        local count = 0
	
		for num, unit in unitTable do
			local transSlotNum = 0
			local remainingLarge = 0
			local remainingMed = 0
			local remainingSml = 0
			local TransportClass = 	unit.Blueprint.Transport.TransportClass
			
			-- pick the transport with the greatest number of appropriate slots left
			for tNum, tData in transportTable do
				if tData.LargeSlots >= remainingLarge and TransportClass == 3 then
					transSlotNum = tNum
					remainingLarge = tData.LargeSlots
					remainingMed = tData.MediumSlots
					remainingSml = tData.SmallSlots
				elseif tData.MediumSlots >= remainingMed and TransportClass == 2 then
					transSlotNum = tNum
					remainingLarge = tData.LargeSlots
					remainingMed = tData.MediumSlots
					remainingSml = tData.SmallSlots
				elseif tData.SmallSlots >= remainingSml and TransportClass == 1 then
					transSlotNum = tNum
					remainingLarge = tData.LargeSlots
					remainingMed = tData.MediumSlots
					remainingSml = tData.SmallSlots
				end
			end
			if transSlotNum > 0 then
				-- assign the large units
				-- notice how we reduce the count of the lower slots as we use up larger ones
				-- and we do the same to larger slots as we use up smaller ones - this was not the 
				-- case before - and caused errors leaving units unassigned - or over-assigned
				if TransportClass == 3 and remainingLarge >= 1.0 then
					transportTable[transSlotNum].LargeSlots = transportTable[transSlotNum].LargeSlots - 1.0
					transportTable[transSlotNum].MediumSlots = transportTable[transSlotNum].MediumSlots - 0.25
					transportTable[transSlotNum].SmallSlots = transportTable[transSlotNum].SmallSlots - 0.50
					-- add the unit to the Large list for this transport
					TableInsert( transportTable[transSlotNum].Units.Large, unit )
				elseif TransportClass == 2 and remainingMed >= 1.0 then
					transportTable[transSlotNum].LargeSlots = transportTable[transSlotNum].LargeSlots - 0.1
					transportTable[transSlotNum].MediumSlots = transportTable[transSlotNum].MediumSlots - 1.0
					transportTable[transSlotNum].SmallSlots = transportTable[transSlotNum].SmallSlots - 0.34
					-- add the unit to the Medium list for this transport
					TableInsert( transportTable[transSlotNum].Units.Medium, unit )
				elseif TransportClass == 1 and remainingSml >= 1.0 then
					transportTable[transSlotNum].MediumSlots = transportTable[transSlotNum].MediumSlots - 0.1	-- yes .1 - for UEF T2 gunships
					transportTable[transSlotNum].SmallSlots = transportTable[transSlotNum].SmallSlots - 1
					-- add the unit to the list for this transport
					TableInsert( transportTable[transSlotNum].Units.Small, unit )
				else
					count = count + 1
					leftoverUnits[count] = unit
				end
			else
                count = count + 1
				leftoverUnits[count] = unit
			end
		end
		return transportTable, leftoverUnits
	end	

	-- tables that hold those units which are NOT loaded yet
	-- broken down by their TransportClass size
    local remainingSize3 = {}
    local remainingSize2 = {}
    local remainingSize1 = {}
	
	counter = 0

	-- check the unit platoon, load the unit remaining tables, and count
	if PlatoonExists( aiBrain, UnitPlatoon) then
		-- load the unit remaining tables according to TransportClass size
		for k, v in GetPlatoonUnits(UnitPlatoon) do
			if v and not v.Dead then
				counter = counter + 1
				if v.Blueprint.Transport.TransportClass == 3 then
					TableInsert( remainingSize3, v )
				elseif v.Blueprint.Transport.TransportClass == 2 then
					TableInsert( remainingSize2, v )
				elseif v.Blueprint.Transport.TransportClass == 1 then
					TableInsert( remainingSize1, v )
				else
					WARN("*AI DEBUG "..aiBrain.Nickname.." Cannot transport "..GetBlueprint(v).Description)
					counter = counter - 1  -- take it back
					
				end
				if IsUnitState( v, 'Attached') then
					--LOG("*AI DEBUG unit "..v:GetBlueprint().Description.." is attached at "..repr(v:GetPosition()))
					v:DetachFrom()
					v:SetCanTakeDamage(true)
					v:SetDoNotTarget(false)
					v:SetReclaimable(true)
					v:SetCapturable(true)
					v:ShowBone(0, true)
					v:MarkWeaponsOnTransport(v, false)
				end
			end
		end
	end

	-- if units were assigned - sort them and tag them for specific transports
	if counter > 0 then
	
		-- flag the unit platoon as busy
		UnitPlatoon.UsingTransport = true
		local leftoverUnits = {}
		local currLeftovers = {}
        counter = 0
	
		-- assign the large units - note how we come back with leftoverunits here
		transportTable, leftoverUnits = SortUnitsOnTransports( transportTable, remainingSize3 )
		-- assign the medium units - but this time we come back with currleftovers
		transportTable, currLeftovers = SortUnitsOnTransports( transportTable, remainingSize2 )
		-- and we move any currleftovers into the leftoverunits table
		for k,v in currLeftovers do
		
			if not v.Dead then
                counter = counter + 1
				leftoverUnits[counter] = v
			end
		end
		
		currLeftovers = {}
	
		-- assign the small units - again coming back with currleftovers
		transportTable, currLeftovers = SortUnitsOnTransports( transportTable, remainingSize1 )
	
		-- again adding currleftovers to the leftoverunits table
		for k,v in currLeftovers do
		
			if not v.Dead then
                counter = counter + 1
				leftoverUnits[counter] = v
			end
		end
		
		currLeftovers = {}
	
		if leftoverUnits[1] then
			transportTable, currLeftovers = SortUnitsOnTransports( transportTable, leftoverUnits )
		end
	
		-- send any leftovers to RTB --
		if currLeftovers[1] then
			for _,v in currLeftovers do
				IssueToUnitClearCommands(v)
			end
			local ident = Random(1,999999)
			local returnpool = aiBrain:MakePlatoon('RTB - Excess in SortingOnTransport'..tostring(ident), 'none')
			AssignUnitsToPlatoon( aiBrain, returnpool, currLeftovers, 'Unassigned', 'None' )
			returnpool.PlanName = 'ReturnToBaseAI'
			returnpool.BuilderName = 'SortUnitsOnTransportsLeftovers'..tostring(ident)
			returnpool:SetAIPlan('ReturnToBaseAI',aiBrain)
		end
	end

	remainingSize3 = nil
    remainingSize2 = nil
    remainingSize1 = nil

	-- At this point all units should be assigned to a given transport or dismissed
	local loading = false
    local loadissued, unitstoload, transport
	
	-- loop thru the transports and order the units to load onto them	
    for k, data in transportTable do
		loadissued = false
		unitstoload = false
		counter = 0
		-- look for dead/missing units in this transports unit list
		-- and those that may somehow be attached already
        for size,unitlist in data.Units do
			for u,v in unitlist do
				if v and not v.Dead then
					if not unitstoload then
						unitstoload = {}
					end
					counter = counter + 1					
					unitstoload[counter] = v
				else
					data.Units[size][u] = nil
				end
			end
		end

		-- if units are assigned to this transport
        if data.Units["Large"][1] then
            IssueClearCommands( data.Units["Large"] )
			loadissued = true
		end
		
		if data.Units["Medium"][1] then
            IssueClearCommands( data.Units["Medium"] )
			loadissued = true
		end
		
		if data.Units["Small"][1] then
            IssueClearCommands( data.Units["Small"] )
			loadissued = true
		end
		
		if not loadissued or not unitstoload then
            if TransportDialog then
                LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..repr(transports.BuilderName).." transport "..data.Transport.EntityId.." no load issued or units to load")
            end
			-- RTP any transport with nothing to load
			ForkTo( ReturnTransportsToPool, aiBrain, {data.Transport}, true )
		else
			transport = data.Transport
			transport.InUse = true
            transport.Assigning = false
			transport.WatchLoadingThread = transport:ForkThread( WatchUnitLoading, unitstoload, aiBrain, UnitPlatoon )
			loading = true
		end
    end
	
	-- if loading has been issued watch it here
	if loading then
        if TransportDialog then
            LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transports.BuilderName.." loadwatch begins" )
        end    
		if UnitPlatoon.WaypointCallback then
			KillThread( UnitPlatoon.WaypointCallback )
			UnitPlatoon.WaypointCallback = nil
            if UnitPlatoon.MovingToWaypoint then
                --LOG("*AI DEBUG "..aiBrain.Nickname.." "..repr(UnitPlatoon.BuilderName).." "..repr(UnitPlatoon.BuilderInstance).." MOVINGTOWAYPOINT cleared by transport ")
                UnitPlatoon.MovingToWaypoint = nil
            end
		end
	
		local loadwatch = true	
		
		while loadwatch do
			WaitTicks(8)
			loadwatch = false
			if PlatoonExists( aiBrain, transports) then
				for _,t in GetPlatoonUnits(transports) do
					if not t.Dead and t.Loading then
						loadwatch = true
					else
                        if t.WatchLoadingThread then
                            KillThread (t.WatchLoadingThread)
                            t.WatchLoadingThread = nil
                        end
                    end
				end
			end
		end
	end

    if TransportDialog then
        LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transports.BuilderName.." loadwatch complete")
	end

	if not PlatoonExists(aiBrain, transports) then
        UnitPlatoon.UsingTransport = false
		return false
	end

	-- Any units that failed to load send back to pool thru RTB
    -- this one really only occurs when an inbound transport is killed
	if PlatoonExists( aiBrain, UnitPlatoon ) then
		local returnpool = false
		for k,v in GetPlatoonUnits(UnitPlatoon) do
			if v and (not v.Dead) then
				if not IsUnitState( v, 'Attached') then
					if not returnpool then
						local ident = Random(100000,999999)
						returnpool = aiBrain:MakePlatoon('FailTransportLoad'..tostring(ident), 'none' )
						returnpool.PlanName = 'ReturnToBaseAI'
						if not string.find(UnitPlatoon.BuilderName, 'FailLoad') then
							returnpool.BuilderName = 'FailLoad '..UnitPlatoon.BuilderName
						else
							returnpool.BuilderName = UnitPlatoon.BuilderName
						end
					end
					IssueToUnitClearCommands(v)
					AssignUnitsToPlatoon( aiBrain, returnpool, {v}, 'Attack', 'None' )
				end
			end
		end
		if returnpool then
			returnpool:SetAIPlan('ReturnToBaseAI', aiBrain )
		end
	end

	counter = 0
	
	-- count number of loaded transports and send empty ones home
	if PlatoonExists( aiBrain, transports ) then
		for k,v in GetPlatoonUnits(transports) do
			if v and (not v.Dead) and TableGetn(v:GetCargo()) == 0 then
				ForkTo( ReturnTransportsToPool, aiBrain, {v}, true )
				transports[k] = nil
			else
				counter = counter + 1
			end
		end	
	end

	-- plan the move and send them on their way
	if counter > 0 then
		local platpos = GetPlatoonPosition(transports) or false
		if platpos then
			local airthreatMax = counter * 4.2
			airthreatMax = airthreatMax + ( airthreatMax * math.log10(counter))
            local safePath, reason, pathlength = NavUtils.PathToWithThreatThreshold('Air', platpos, location, aiBrain, NavUtils.ThreatFunctions.AntiAir,  airthreatMax, aiBrain.IMAPConfig.Rings)
            if TransportDialog then
                if not safePath then
                    LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transports.BuilderName.." no safe path to "..repr(location).." using threat of "..airthreatMax)
                else
                    LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transports.BuilderName.." has path to "..repr(location).." - length "..repr(pathlength).." - reason "..reason)
                end
            end
		
			if PlatoonExists( aiBrain, transports) then
				IssueClearCommands( GetPlatoonUnits(transports) )
				IssueMove( GetPlatoonUnits(transports), GetPlatoonPosition(transports))
				if safePath then 
					local prevposition = GetPlatoonPosition(transports) or false
                    local Direction
					for _,p in safePath do
						if prevposition then
							local base = Vector( 0, 0, 1 )
                            local direction = import('/lua/utilities.lua').GetDirectionVector(Vector(prevposition[1], prevposition[2], prevposition[3]), Vector(p[1], p[2], p[3]))
							Direction = import('/lua/utilities.lua').GetAngleCCW( base, direction )
							IssueFormMove( GetPlatoonUnits(transports), p, 'AttackFormation', Direction)
							prevposition = p
						end
					end
                    
				else
					if TransportDialog then
                        LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transports.BuilderName.." goes direct to "..repr(location))
                    end
					-- go direct ?? -- what ?
					local base = Vector( 0, 0, 1 )
					local transPos = GetPlatoonPosition(transports)
                    local direction = import('/lua/utilities.lua').GetDirectionVector(Vector(transPos[1], transPos[2], transPos[3]), Vector(location[1], location[2], location[3]))
					IssueFormMove( GetPlatoonUnits(transports), location, 'AttackFormation', import('/lua/utilities.lua').GetAngleCCW( base, direction )) 
				end

				if TransportDialog then
                    LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transports.BuilderName.." starts travelwatch to "..repr(location))
                end
			
				for _,v in GetPlatoonUnits(transports) do
					if not v.Dead then
						v.WatchTravelThread = v:ForkThread(WatchTransportTravel, location, aiBrain, UnitPlatoon)		
					end
                end
			end
            
		end
	end
	
	local transporters = GetPlatoonUnits(transports) or false
	
	-- if there are loaded, moving transports, watch them while traveling
	if transporters and TableGetn(transporters) != 0 then
		-- this sets up the transports platoon ability to call for help and to detect major threats to itself
		-- we'll also use it to signal an 'abort transport' capability using the DistressCall field
        -- threat trigger is based on number of transports
		transports:ForkThread( transports.PlatoonCallForHelpAI, aiBrain, TableGetn(transporters) )
		transports.AtGoal = false -- flag to allow unpathed unload of the platoon
		local travelwatch = true
		-- loop here until all transports signal travel complete
		-- each transport should be running the WatchTravel thread
		-- until it dies, the units it is carrying die or it gets to target
		while travelwatch and PlatoonExists( aiBrain, transports ) do
			travelwatch = false
			WaitTicks(4)
			for _,t in GetPlatoonUnits(transports) do
				if t.Travelling and not t.Dead then
					travelwatch = true
				end
			end
		end

        if TransportDialog then
            LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transports.BuilderName.." travelwatch complete")
        end
    end

	transporters = GetPlatoonUnits(transports) or false
	
	-- watch the transports until they signal unloaded or dead
	if transporters and TableGetn(transporters) != 0 then
    
        if TransportDialog then
            LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transports.BuilderName.." unloadwatch begins")
        end    
		
		local unloadwatch = true
        local unloadcount = 0 
		
		while unloadwatch do
			WaitTicks(5)
            unloadcount = unloadcount + .4
			unloadwatch = false
			for _,t in GetPlatoonUnits(transports) do
				if t.Unloading and not t.Dead then
					unloadwatch = true
                else
                    if t.WatchUnloadThread then
                        KillThread(t.WatchUnloadThread)
                        t.WatchUnloadThread = nil
                    end
				end
			end
		end

        if TransportDialog then
            LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transports.BuilderName.." unloadwatch complete after "..unloadcount.." seconds")
        end
        
        for _,t in GetPlatoonUnits(transports) do
            if not t.EventCallbacks['OnTransportDetach'] then
                ForkTo( ReturnTransportsToPool, aiBrain, {t}, true )
            end
        end
    end
	
	if not PlatoonExists(aiBrain,UnitPlatoon) then
        return false
    end
	
	UnitPlatoon.UsingTransport = false

    if TransportDialog then
        LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." Transport complete ")
    end
	
	return true
end

-- Ok -- this routine allowed me to get some control over the reliability of loading units onto transport
-- I have to say, the lack of a GETUNITSTATE function really made this tedious but here is the jist of what I've found
-- Some transports will randomly report false to TransportHasSpaceFor even when completely empty -- causing them to fail to load units
-- just to note, the same also seems to apply to AIRSTAGINGPLATFORMS

-- I was eventually able to determine that two states are most important in this process --
-- TransportLoading for the transports
-- WaitingForTransport for the units 

-- Essentially if the transport isn't Moving or TransportLoading then something is wrong
-- If a unit is not WaitingForTransport then it too has had loading interrupted 
-- however - I have noticed that transports will continue to report 'loading' even when all the units to be loaded are dead 
function WatchUnitLoading( transport, units, aiBrain, UnitPlatoon)
	
	local unitsdead = true
	local loading = false
	local reloads = 0
	local reissue = 0
	local newunits = TableCopy(units)
	local GetPosition = GetPosition
	local watchcount = 0
    transport.Loading = true

	IssueStop( {transport} )
    
    if TransportDialog then
        LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." transport "..transport.EntityId.." moving to "..repr(units[1]:GetPosition()).." for pickup - distance "..VDist3( transport:GetPosition(), units[1]:GetPosition()))
    end
	
    -- At this point we really should safepath to the position
    -- and we should probably use a movement thread 
	IssueToUnitMove(transport, GetPosition(units[1]) )
	WaitTicks(5)
	
	for _,u in newunits do
		if not u.Dead then
			unitsdead = false
			loading = true
			-- here is where we issue the Load command to the transport --
			safecall("Unable to IssueTransportLoad units are "..repr(units), IssueTransportLoad, newunits, transport )
			break
		end
	end

	local tempunits = {}
	local counter = 0
	
    if TransportDialog then
        LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transport.PlatoonHandle.BuilderName.." Transport "..transport.EntityId.." begins loading")
    end
    
	-- loop here while the transport is alive and loading is underway
	-- there is another trigger (watchcount) which will force loading
	-- to false after 210 seconds
	while (not unitsdead) and loading do
		watchcount = watchcount + 1.3
		if watchcount > 210 then
            WARN("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transport.PlatoonHandle.BuilderName.." Transport "..transport.EntityId.." ABORTING LOAD - watchcount "..watchcount)
			loading = false
            transport.Loading = nil
            ForkTo ( ReturnTransportsToPool, aiBrain, {transport}, true )
			break
		end
		
		WaitTicks(14)
		
		tempunits = {}
		counter = 0

        -- check for death of transport - and verify that units are still awaiting load
		if (not transport.Dead) and transport.Loading and ( not IsUnitState(transport,'Moving') or IsUnitState(transport,'TransportLoading') ) then
			unitsdead = true
			loading = false
			-- loop thru the units and pick out those that are not yet 'attached'
			-- also detect if all units to be loaded are dead
			for _,u in newunits do
				if not u.Dead then
					-- we have some live units
					unitsdead = false
					if not IsUnitState( u, 'Attached') then
						loading = true
						counter = counter + 1
						tempunits[counter] = u
					end
				end
			end
		
			-- if all dead or all loaded or unit platoon no longer exists, RTB the transport
			if unitsdead or (not loading) or reloads > 20 then
				if unitsdead then
                    transport.Loading = nil
					ForkTo ( ReturnTransportsToPool, aiBrain, {transport}, true )
                    return
				end
				
				loading = false
			end
		end

		-- issue reloads to unloaded units if transport is not moving and not loading units
		if (not transport.Dead) and (loading and not (IsUnitState( transport, 'Moving') or IsUnitState( transport, 'TransportLoading'))) then

			reloads = reloads + 1
			reissue = reissue + 1
			newunits = false
			counter = 0
			
			for k,u in tempunits do
				if (not u.Dead) and not IsUnitState( u, 'Attached') then
					-- if the unit is not attached and the transport has space for it or it's a UEF Gunship (TransportHasSpaceFor command is unreliable)
					if (not transport.Dead) and transport:TransportHasSpaceFor(u) then
						IssueStop({u})
						if reissue > 1 then
							if TransportDialog then
                                LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transport.PlatoonHandle.BuilderName.." Transport"..transport.EntityId.." Warping unit "..u.EntityId.." to transport ")
							end
							Warp( u, GetPosition(transport) )
							reissue = 0
						end
						if not newunits then
							newunits = {}
						end
						counter = counter + 1						
						newunits[counter] = u
					-- if the unit is not attached and the transport does NOT have space for it - turn off loading flag and clear the tempunits list
					elseif (not transport.Dead) and (not transport:TransportHasSpaceFor(u)) and (not EntityCategoryContains(categories.uea0203,transport)) then
						loading = false
						newunits = false
						break
					elseif (not transport.Dead) and EntityCategoryContains(categories.uea0203,transport) then
						loading = false
						newunits = false
						break
					end	
				end
			end
			
			if newunits and counter > 0 then
				if reloads > 1 and TransportDialog then
					LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transport.PlatoonHandle.BuilderName.." Transport "..transport.EntityId.." Reloading "..counter.." units - reload "..reloads)
				end
				IssueStop( newunits )
				IssueStop( {transport} )
				local goload = safecall("Unable to IssueTransportLoad", IssueTransportLoad, newunits, transport )
				if goload and TransportDialog then
					LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transport.PlatoonHandle.BuilderName.." Transport "..transport.EntityId.." reloads is "..reloads.." goload is "..repr(goload).." for "..transport:GetBlueprint().Description)
				end
			else
				loading = false
			end
		end
	end

    if TransportDialog then
        if transport.Dead then
            -- at this point we should find a way to reprocess the units this transport was responsible for
            LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." Transport "..transport.EntityId.." dead during WatchLoading")
        else
            LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transport.PlatoonHandle.BuilderName.." Transport "..transport.EntityId.." completes load in "..watchcount)
        end
    end

    if transport.InUse then
        IssueStop( {transport} )
        if (not transport.Dead) then
            if not unitsdead then
                -- have the transport guard his loading spot until everyone else has loaded up
                IssueGuard( {transport}, GetPosition(transport) )
                if TransportDialog then
                    LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transport.PlatoonHandle.BuilderName.." Transport "..transport.EntityId.." begins to loiter after load")
                end
            else
                transport.Loading = nil
                if TransportDialog then
                    LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transport.PlatoonHandle.BuilderName.." Transport "..transport.EntityId.." aborts load - unitsdead is "..repr(unitsdead).." watchcount is "..watchcount)
                end
                ForkTo ( ReturnTransportsToPool, aiBrain, {transport}, true )
                return
            end
        end
    end
	transport.Loading = nil
end

function WatchTransportTravel( transport, destination, aiBrain, UnitPlatoon )

	local unitsdead = false
	local watchcount = 0
	local GetPosition = GetPosition
    local VDist2 = VDist2
    local WaitTicks = WaitTicks
	
	transport.StuckCount = 0
	transport.LastPosition = TableCopy(GetPosition(transport))
    transport.Travelling = true
    
    if TransportDialog then
        LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transport.PlatoonHandle.BuilderName.." Transport "..transport.EntityId.." starts travelwatch")
    end
	
	while (not transport.Dead) and (not unitsdead) and transport.Travelling do
			-- major distress call -- 
			if transport.PlatoonHandle.DistressCall then
				-- reassign destination and begin immediate drop --
				-- this really needs to be sensitive to the platoons layer
				-- and find an appropriate marker to drop at -- 
                if TransportDialog then
                    LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transport.PlatoonHandle.BuilderName.." Transport "..transport.EntityId.." DISTRESS ends travelwatch after "..watchcount)
                end
				destination = GetPosition(transport)
                break
			end
			
			-- someone in transport platoon is close - begin the drop -
			if transport.PlatoonHandle.AtGoal then
                if TransportDialog then
                    LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transport.PlatoonHandle.BuilderName.." Transport "..transport.EntityId.." signals ARRIVAL after "..watchcount)
                end
				break
			end
        
			unitsdead = true

			for _,u in transport:GetCargo() do
				if not u.Dead then
					unitsdead = false
					break
				end
			end

			-- if all dead except UEF Gunship RTB the transport
			if unitsdead and not EntityCategoryContains(categories.uea0203,transport) then
				transport.StuckCount = nil
				transport.LastPosition = nil
				transport.Travelling = false

                if TransportDialog then
                    LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transport.PlatoonHandle.BuilderName.." Transport "..transport.EntityId.." UNITS DEAD ends travelwatch after "..watchcount)
                end

				ForkTo( ReturnTransportsToPool, aiBrain, {transport}, true )
                return
			end
		
			-- is the transport still close to its last position bump the stuckcount
			if transport.LastPosition then
				if VDist2(transport.LastPosition[1], transport.LastPosition[3], GetPosition(transport)[1],GetPosition(transport)[3]) < 6 then
					transport.StuckCount = transport.StuckCount + 0.5
				else
					transport.StuckCount = 0
				end
			end

			if ( IsIdleState(transport) or transport.StuckCount > 8 ) then
				if transport.StuckCount > 8 then
                    LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transport.PlatoonHandle.BuilderName.." Transport "..transport.EntityId.." StuckCount in WatchTransportTravel to "..repr(destination) )				
					transport.StuckCount = 0
				end

				IssueToUnitClearCommands(transport)
				IssueToUnitMove(transport, destination )
			end
		
			-- this needs some examination -- it should signal the entire transport platoon - not just itself --
			if VDist2(GetPosition(transport)[1], GetPosition(transport)[3], destination[1],destination[3]) < 100 then
				transport.PlatoonHandle.AtGoal = true
			else
                transport.LastPosition = TableCopy(transport:GetPosition())
            end
    
            if not transport.PlatoonHandle.AtGoal then
                WaitTicks(11)
                watchcount = watchcount + 1
            end

	end

	if not transport.Dead then
		IssueToUnitClearCommands(transport)
		if not transport.Dead then
            if TransportDialog then
                LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transport.PlatoonHandle.BuilderName.." Transport "..transport.EntityId.." ends travelwatch ")
            end
		
			transport.StuckCount = nil
			transport.LastPosition = nil
			transport.Travelling = nil

			transport.WatchUnloadThread = transport:ForkThread( WatchUnitUnload, transport:GetCargo(), destination, aiBrain, UnitPlatoon )
		end
	end
	
end

function WatchUnitUnload( transport, unitlist, destination, aiBrain, UnitPlatoon )

    local WaitTicks = WaitTicks
	local unitsdead = false
	local unloading = true
    transport.Unloading = true
    
    if TransportDialog then
        LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transport.PlatoonHandle.BuilderName.." Transport "..transport.EntityId.." unloadwatch begins at "..repr(destination) )
    end
	
	IssueTransportUnload( {transport}, destination)
    WaitTicks(4)
	local watchcount = 0.3

	while (not unitsdead) and unloading and (not transport.Dead) do
		unitsdead = true
		unloading = false
	
        if not transport.Dead then
			-- do we have loaded units
			for _,u in unitlist do
				if not u.Dead then
					unitsdead = false
					if IsUnitState( u, 'Attached') then
						unloading = true
						break
					end
				end
			end

            -- in this case unitsdead can mean that OR that we've unloaded - either way we're done
			if unitsdead or not unloading then
                if TransportDialog then
                    if not transport.Dead then
                        LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transport.PlatoonHandle.BuilderName.." transport "..transport.EntityId.." unloadwatch complete after "..watchcount.." seconds")
                        --transport.InUse = false
                        transport.Unloading = nil
                        if not transport.EventCallbacks['OnTransportDetach'] then
                            ForkTo( ReturnTransportsToPool, aiBrain, {transport}, true )
                        end
                    else
                        LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transport.PlatoonHandle.BuilderName.." transport "..transport.EntityId.." dead during unload")
                    end
                end
			end
            -- watch the count and try to force the unload
			if unloading and (not transport:IsUnitState('TransportUnloading')) then
				if watchcount >= 12 then
					LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transport.PlatoonHandle.BuilderName.." transport "..transport.EntityId.." FAILS TO UNLOAD after "..watchcount.." seconds")
					break			
				elseif watchcount >= 8 then
					LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transport.PlatoonHandle.BuilderName.." transport "..transport.EntityId.." watched unload for "..watchcount.." seconds")
					IssueTransportUnload( {transport}, GetPosition(transport))
				elseif watchcount > 4 then
					IssueTransportUnload( {transport}, GetPosition(transport))
				end
			end
		end
        
		WaitTicks(6)
		watchcount = watchcount + 0.5
    
        if TransportDialog then
            LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transport.PlatoonHandle.BuilderName.." Transport "..transport.EntityId.." unloadwatch cycles "..watchcount )
        end
	end
    
    if TransportDialog then
        LOG("*AI DEBUG "..aiBrain.Nickname.." "..UnitPlatoon.BuilderName.." "..transport.PlatoonHandle.BuilderName.." Transport "..transport.EntityId.." unloadwatch ends" )
    end
    transport.Unloading = nil
end

-- Processes air units at the end of work.
function ProcessAirUnits( unit, aiBrain )
	if (not unit.Dead) and (not IsBeingBuilt(unit)) then
        local fuel = GetFuelRatio(unit)
		local health = unit:GetHealthPercent()
		if ( fuel > -1 and fuel < .75 ) or health < .30 then
            if not unit.InRefit then
                if TransportDialog then
                    LOG("*AI DEBUG "..aiBrain.Nickname.." Air Unit "..unit.Sync.id.." assigned to TransportReturnToBase ")
                end
                -- and send it off to the refit thread --
                unit:ForkThread( TransportReturnToBase, aiBrain )
                return true
            else
				if TransportDialog then
                    LOG("*AI DEBUG "..aiBrain.Nickname.." Air Unit "..unit.Sync.id.." "..unit:GetBlueprint().Description.." already in return to base thread")
				end
            end
		end
	end
	return false    -- unit did not need processing
end

function TransportReturnToBase(unit, aiBrain)
	if unit.Dead or unit.InRefit then
        return
    end
	local NavUtils = import("/lua/sim/navutils.lua")

	local ident = Random(100000,999999)
	local rtbissued = false
	local fuellimit = .75
	local healthlimit = .30
	local returnPos
	local killUnitOnReturn = false
	local fuel
	local health

	local returnpool = aiBrain:MakePlatoon('AirRefit'..tostring(ident), 'none')
	if not unit.Dead then
		AssignUnitsToPlatoon( aiBrain, returnpool, {unit}, 'Unassigned', '')
		unit.PlatoonHandle = returnpool
	end
	while (not unit.Dead) do
		fuel = GetFuelRatio(unit)
		health = unit:GetHealthPercent()
		if ( fuel > -1 and fuel < fuellimit ) or health < healthlimit then
			if health < healthlimit then
				killUnitOnReturn = true
			end
			if not rtbissued then
				-- find closest base
				local bestBaseName
				local bestDistSq
				local platPos = returnpool:GetPlatoonPosition()
				
				for baseName, base in aiBrain.BuilderManagers do
					if base.Layer ~= 'Water' and base.EngineerManager and base.EngineerManager:GetNumCategoryUnits('Engineers', categories.ALLUNITS) > 0 then
						local distSq = VDist2Sq(platPos[1], platPos[3], base.Position[1], base.Position[3])
						if not bestDistSq or distSq < bestDistSq then
							bestBaseName = baseName
							bestDistSq = distSq
						end
					end
				end
				if bestBaseName then
					unit.InRefit = true
					rtbissued = true
					if ScenarioInfo.TransportDialog then
						LOG("*AI DEBUG "..aiBrain.Nickname.." Air Unit "..unit.Sync.id.." returning to base ")
					end
					returnPos = aiBrain.BuilderManagers[bestBaseName].Position
					IssueStop ( {unit} )
					IssueClearCommands( {unit} )
					local safePath, reason = NavUtils.PathToWithThreatThreshold('Air', platPos, returnPos, aiBrain, NavUtils.ThreatFunctions.AntiAir, 50, aiBrain.IMAPConfig.Rings)
					if safePath then
						-- use path
						for _,p in safePath do
							IssueMove( {unit}, p )
						end
						IssueMove( {unit}, returnPos)
					else
						-- go direct -- possibly bad
						IssueMove( {unit}, returnPos )
					end
				end
			end
		-- otherwise we may have refueled/repaired ourselves or don't need it
		else
			unit.InRefit = nil
			break
		end
		if rtbissued then
			WaitTicks(21)
			if not IsDestroyed(returnpool) and killUnitOnReturn and returnPos then
				local origin = returnpool:GetPlatoonPosition()
				local dx = origin[1] - returnPos[1]
                local dz = origin[3] -returnPos[3]
                if dx * dx + dz * dz < 1225 then
					unit:Kill()
				end
			end
		else
			break
		end
	end
end

-- Supporting function. Should be replaced by navutils equivalent.
function InPlayableArea(pos)
    local playableArea = ScenarioInfo.PlayableArea or {0, 0, ScenarioInfo.size[1], ScenarioInfo.size[2]}
    if playableArea then
        return pos[1] > playableArea[1] and
            pos[1] < playableArea[3] and
            pos[3] > playableArea[2] and
            pos[3] < playableArea[4]
    end
    return true
end

