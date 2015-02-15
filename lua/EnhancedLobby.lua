function GetAIList()
	--Table of AI Names to return
	local aitypes = {
        {
            key = 'easy',
            name = "<LOC lobui_0347>AI: Easy"
        },
        {
            key = 'medium',
            name = "<LOC lobui_0349>AI: Normal"
        },
        {
            key = 'adaptive',
            name = "<LOC lobui_0368>AI: Adaptive"
        },
        {
            key = 'rush',
            name = "<LOC lobui_0360>AI: Rush"
        },
        {
            key = 'turtle',
            name = "<LOC lobui_0372>AI: Turtle"
        },
        {
            key = 'tech',
            name = "<LOC lobui_0370>AI: Tech"
        },
        {
            key = 'random',
            name = "<LOC lobui_0374>AI: Random"
        }
    }
	
	--Defualt GPG AIs
	
	local AIFiles = DiskFindFiles('/lua/AI/CustomAIs_v2', '*.lua')
	local AIFilesold = DiskFindFiles('/lua/AI/CustomAIs', '*.lua')
	
	--Load Custom AIs - old style
	for i, v in AIFilesold do
        local tempfile = import(v).AIList
		for s, t in tempfile do	
			table.insert(aitypes, { key = t.key, name = t.name })
		end
	end
	
	--Load Custom AIs
	for i, v in AIFiles do
        local tempfile = import(v).AI
		if tempfile.AIList then
			for s, t in tempfile.AIList do	
				table.insert(aitypes, { key = t.key, name = t.name })
			end
		end
	end
	
	--Default GPG Cheating AIs
    table.insert(aitypes, { key = 'adaptivecheat', name = "<LOC lobui_0379>AIx: Adaptive" })
    table.insert(aitypes, { key = 'rushcheat', name = "<LOC lobui_0380>AIx: Rush" })
    table.insert(aitypes, { key = 'turtlecheat', name = "<LOC lobui_0384>AIx: Turtle" })
    table.insert(aitypes, { key = 'techcheat', name = "<LOC lobui_0385>AIx: Tech" })
    table.insert(aitypes, { key = 'randomcheat', name = "<LOC lobui_0395>AIx: Random" })
	
    --Load Custom Cheating AIs - old style
	for i, v in AIFilesold do
        local tempfile = import(v).CheatAIList
		for s, t in tempfile do	
			table.insert(aitypes, { key = t.key, name = t.name })
		end
	end
	
	--Load Custom Cheating AIs
    for i, v in AIFiles do
        local tempfile = import(v).AI
		if tempfile.CheatAIList then
			for s, t in tempfile.CheatAIList do	
				table.insert(aitypes, { key = t.key, name = t.name })
			end
		end
	end
	
	return aitypes
end

--- Checks a map for Land Path nodes.
--
-- @param scenario Scenario info
-- @return true if the map has Land Path nodes, false otherwise.
function CheckMapHasMarkers(scenario)
	if not DiskGetFileInfo(scenario.save) then
		return false
	end
    local saveData = {}
    doscript('/lua/dataInit.lua', saveData)
    doscript(scenario.save, saveData)

    if saveData and saveData.Scenario and saveData.Scenario.MasterChain and
    saveData.Scenario.MasterChain['_MASTERCHAIN_'] and saveData.Scenario.MasterChain['_MASTERCHAIN_'].Markers then
               for marker,data in saveData.Scenario.MasterChain['_MASTERCHAIN_'].Markers do
                           if string.find( string.lower(marker), 'landpn') then
				return true
			end
		end
	else
		WARN('Map '..scenario.name..' has no marker chain')
	end
	return false
end
