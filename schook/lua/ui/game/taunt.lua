do
local AIChatS = import('/lua/AIChatSorian.lua')

function RecieveAITaunt(sender, msg)
    if Prefs.GetOption('mp_taunt_head_enabled') == 'true' then
        local taunt = taunts[msg.data]
        if taunt and msg.aisender then
            StopSound(prevHandle)
            prevHandle = PlayVoice(Sound({Cue = taunt.cue, Bank = taunt.bank}))
            import('/lua/ui/game/chat.lua').ReceiveChat(sender, {Chat = true, text = LOC(taunt.text), to = "all", aisender = msg.aisender})
		elseif taunt then
            StopSound(prevHandle)
            prevHandle = PlayVoice(Sound({Cue = taunt.cue, Bank = taunt.bank}))
            import('/lua/ui/game/chat.lua').ReceiveChat(sender, {Chat = true, text = LOC(taunt.text), to = "all"})
        end
    end
end

function SendTaunt(tauntIndex, sender)
    if sender then
		AIChatS.AISendChatMessage(nil, {Taunt = true, data = tauntIndex, aisender = sender})
	else
		SessionSendChatMessage({Taunt = true, data = tauntIndex})
	end
end

-- if this returns true, taunt found and handled, else return false so chat handling can continue
function CheckForAndHandleTaunt(text, sender)
    -- taunts start with /
    if (string.len(text) > 1) and (string.sub(text, 1, 1) == "/") then
        local tauntIndex = tonumber(string.sub(text, 2))
        if tauntIndex and taunts[tauntIndex] then
			if sender then
				SendTaunt(tauntIndex, sender)
			else
				SendTaunt(tauntIndex)
			end
            return true
        end
    end
    return false
end

end