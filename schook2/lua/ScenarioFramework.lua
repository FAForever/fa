OldSetPlayableArea = SetPlayableArea


function SetPlayableArea( rect, voFlag )
	OldSetPlayableArea(rect, voFlag )
	ForkThread(GenerateOffMapAreas)

end



function GenerateOffMapAreas()
	local playablearea = {}
	local OffMapAreas = {}
	
	if  ScenarioInfo.MapData.PlayableRect then
		playablearea = ScenarioInfo.MapData.PlayableRect
	else
		#local x0,y0,x1,y1 = {0,ScenarioInfo.size[1],0,ScenarioInfo.size[2]}
		playablearea = {0,0,ScenarioInfo.size[1],ScenarioInfo.size[2]}
	end
	#local playablearea = {x0,y0,x1,y1}
	
	WARN('playable area coordinates are ' .. repr(playablearea))
	
	local x0 = playablearea[1]
	local y0 = playablearea[2]
	local x1 = playablearea[3]
	local y1 = playablearea[4]
	
	#This is a rectangle above the playable area that is longer, left to right, than the playable area
	local OffMapArea1 = {}
	OffMapArea1.x0 = (x0 - 100) 
	OffMapArea1.y0 = (y0 - 100)
	OffMapArea1.x1 = (x1 + 100)
	OffMapArea1.y1 = y0
	
	#This is a rectangle below the playable area that is longer, left to right, than the playable area
	local OffMapArea2 = {}
	OffMapArea2.x0 = (x0 - 100) 
	OffMapArea2.y0 = (y1)
	OffMapArea2.x1 = (x1 + 100)
	OffMapArea2.y1 = (y1 + 100)
	
	#This is a rectangle to the left of the playable area, that is the same height (up to down) as the playable area
	local OffMapArea3 = {}
	OffMapArea3.x0 = (x0 - 100) 
	OffMapArea3.y0 = y0
	OffMapArea3.x1 = x0
	OffMapArea3.y1 = y1
	
	#This is a rectangle to the right of the playable area, that is the same height (up to down) as the playable area
	local OffMapArea4 = {}
	OffMapArea4.x0 = x1 
	OffMapArea4.y0 = y0
	OffMapArea4.x1 = (x1 + 100)
	OffMapArea4.y1 = y1 
	
	OffMapAreas = {OffMapArea1,OffMapArea2,OffMapArea3,OffMapArea4}
	
	ScenarioInfo.OffMapAreas = OffMapAreas
	ScenarioInfo.PlayableArea = playablearea
	
	WARN('Offmapareas are ' .. repr(OffMapAreas))
	
end

function AntiOffMapMainThread()
	WaitTicks(10)
	
	GenerateOffMapAreas()
	local OffMapAreas = {}
	local UnitsThatAreOffMap = {}
	
	while ScenarioInfo.OffMapPreventionThreadAllowed == true do
		OffMapAreas = ScenarioInfo.OffMapAreas
		NewUnitsThatAreOffMap = {}
		
		for index,OffMapArea in OffMapAreas do
			local UnitsThatAreInOffMapRect = GetUnitsInRect(OffMapArea)
				if UnitsThatAreInOffMapRect then
					for index, UnitThatIsOffMap in  UnitsThatAreInOffMapRect do
						if not UnitThatIsOffMap.IAmOffMapThread then
							table.insert(NewUnitsThatAreOffMap,UnitThatIsOffMap)
						end
					end
				else
				
				end
		end
		
		local NumberOfUnitsOffMap = table.getn(NewUnitsThatAreOffMap)
		
		#WARN('the number of new units that are off map is ' .. repr(NumberOfUnitsOffMap))
		
		for index,NewUnitThatIsOffMap in NewUnitsThatAreOffMap do
			if not NewUnitThatIsOffMap.IAmOffMap then
				NewUnitThatIsOffMap.IAmOffMap = true
			end
			#this is to make sure that we only do this check for air units
			if not NewUnitThatIsOffMap.IAmOffMapThread and EntityCategoryContains( categories.AIR, NewUnitThatIsOffMap) then
				NewUnitThatIsOffMap.IAmOffMapThread = NewUnitThatIsOffMap:ForkThread(IAmOffMap)
			
			end
		end
		
		
		WaitSeconds(1)
		NewUnitsThatAreOffMap = nil
	end
	

end

function IsUnitInPlayableArea(unit)

	local playableArea = ScenarioInfo.PlayableArea
	local position = unit:GetPosition()
	#WARN('unit position is ' .. repr(position))
	#format is x0,y0,x1,y1 for rect, x,y,z for position
	if  position[1] > playableArea[1] and position[1] < playableArea[3] and  position[3] > playableArea[2] and position[3] < playableArea[4] then
		#WARN('unit is in playable area')
		return true
	else 
		#WARN('unit remains in unplayable area')
		return false
	end
	
end

#this is for bad units, who choose to go off map, shame on them
function IAmOffMap(self)
	self.TimeIHaveBeenOffMap = 0
	self.TimeIHaveBeenOnMap = 0
	self.TimeIAmAllowedToBeOffMap = GetTimeIAmAllowedToBeOffMap(self)
	while not self:IsDead() do
		#local playableArea = ScenarioInfo.PlayableArea
		if IsUnitInPlayableArea(self) then
			self.TimeIHaveBeenOnMap = (self.TimeIHaveBeenOnMap + 1)
			
			if self.TimeIHaveBeenOnMap > 5 then 
				self:ForkThread(KillIAmOffMapThread)
			end
		else
			self.TimeIHaveBeenOffMap = (self.TimeIHaveBeenOffMap + 1)
			#WARN('time I have been off map is ' .. repr(self.TimeIHaveBeenOffMap))
		end
		
		if self.TimeIHaveBeenOffMap > self.TimeIAmAllowedToBeOffMap then
			self:ForkThread(IAmABadUnit)
		end
		
		WaitSeconds(1)
	end
end


function IAmABadUnit(self)
	local position = self:GetPosition()
	local playableArea = ScenarioInfo.PlayableArea
	local NearestOnPlayableAreaPointToMe = {}
	
	#format is x0,y0,x1,y1 for rect, x,y,z for position
	#to conver position to rect, z is y, and y is height
		
	NearestOnPlayableAreaPointToMe[2] = position[2]	
		
	if position[1] > playableArea[1] and position[1] < playableArea[3] then
		NearestOnPlayableAreaPointToMe[1] = position[1]
	elseif position[1] < playableArea[1] then
		NearestOnPlayableAreaPointToMe[1] = (playableArea[1] + 5)
	elseif position[1] > playableArea[3] then
		NearestOnPlayableAreaPointToMe[1] = (playableArea[3] - 5)
	end
	
	
	if position[3] > playableArea[2] and position[3] < playableArea[4] then
		NearestOnPlayableAreaPointToMe[3] = position[3]
	elseif position[3] < playableArea[2] then
		NearestOnPlayableAreaPointToMe[3] = (playableArea[2] + 5)
	elseif position[3] > playableArea[4] then
		NearestOnPlayableAreaPointToMe[3] = (playableArea[4] - 5)
	end
	
	IssueClearCommands({self})
	IssueMove({self},position)
	WARN('Unit was off map too long, so has been cleared of all orders')
	
end

function GetTimeIAmAllowedToBeOffMap(self)
	local PrimaryWeapon = self:GetWeapon(1)
	if PrimaryWeapon and PrimaryWeapon:GetCurrentTarget() then
		#WARN('the air unit has a target, allowed to be off map for 20 seconds')
		return 20
	else
		#WARN('the air unit does not have a target, allowed to be off map for 2 seconds')
		#WARN('the primary weapon is  ' .. repr(PrimaryWeapon))
		return 2
	end

end

function KillIAmOffMapThread(self)

	KillThread(self.IAmOffMapThread)
	self.IAmOffMapThread = nil
	self.TimeIHaveBeenOffMap = 0
	self.TimeIHaveBeenOnMap = 0
end
