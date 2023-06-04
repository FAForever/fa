------------------------------------------------------------------------------
-- File : /lua/ui/campaign/operationvars.lua
-- Author(s): Evan Pongress
-- Summary : function to generate the vars for operationselect.lua and operationbriefing.lua.
--			 uses the ID set in /maps/*_operation.lua, e.g. SCCA_E01.
-- Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------

function MakeOpVars(thisID, factionKey, sequenceID)
	local opStrings = import('/maps/' .. thisID .. '/' .. thisID .. '_strings.lua')
	
	-- if briefing data exists (use 'rawget' to bypass missing global error if it doesn't exist)
	if rawget(opStrings, 'BriefingData') then											
		op_text = opStrings.BriefingData
	else
		op_text = {{phase = 1, character = 'NO_DATA', text = 'ERROR - NO BRIEFING DATA'}}
	end
	
	if rawget(opStrings, string.format("%s%02d_DB01_010", factionKey, sequenceID)) then
		op_success = opStrings[string.format("%s%02d_DB01_010", factionKey, sequenceID)]
	else
		op_success = {{phase = 1, character = 'NO_DATA', text = 'ERROR - NO SUCCESS DATA'}}
	end
	
	
	if rawget(opStrings, string.format("%s%02d_DB01_020", factionKey, sequenceID)) then
		op_fail = opStrings[string.format("%s%02d_DB01_020", factionKey, sequenceID)]
	else
		op_fail = {{phase = 1, character = 'NO_DATA', text = 'ERROR - NO FAILURE DATA'}}
	end
	
	return {op_long_name = opStrings.OPERATION_NAME	,
			op_num = sequenceID,
			op_movies = import("/lua/ui/campaign/campaignmoviedata.lua").campaignData[thisID],
			op_text = op_text,
			op_map = '/maps/' .. thisID .. '/' .. thisID .. '_scenario.lua',
			op_debrief_success = op_success,
			op_debrief_failure = op_fail,
			}
end