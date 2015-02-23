function PrintText(textData)
    if textData then
        local data = textData
        if type(textData) == 'string' then
            data = {text = textData, size = 14, color = 'ffffffff', duration = 5, location = 'center'}
        end
        import('/lua/ui/game/textdisplay.lua').PrintToScreen(data)
    end
end

local replayID = import('/lua/ui/uiutil.lua').GetReplayId()
if replayID then
    LOG("REPLAY ID: " .. replayID)
end
