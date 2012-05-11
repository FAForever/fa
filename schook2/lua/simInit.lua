
local originalBeginSessionOffMap = BeginSession

function OnStartOffMapPreventionThread()
	OffMappingPreventThread = ForkThread( import('/lua/ScenarioFramework.lua').AntiOffMapMainThread)
	ScenarioInfo.OffMapPreventionThreadAllowed = true
	#WARN('success')
end


function BeginSession()
LOG('beginning sim')
originalBeginSessionOffMap()
LOG('Begin the hunt')
OnStartOffMapPreventionThread()

end
