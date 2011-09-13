do
	local oldCreateUI = CreateUI
	CreateUI = function(isReplay)
		oldCreateUI(isReplay)
		import("/modules/displayrings.lua").Init()	##added for acu and engineer build radius ui mod
		if SessionIsReplay() then
			ForkThread(SendChat)
		end
	end

	local sendChat = import('/lua/ui/game/chat.lua').ReceiveChatFromSim
	local oldData = {}

	SendChat = function()
		while true do
			if UnitData.Chat then
				if table.getn(UnitData.Chat) > 0 then
					for index, chat in UnitData.Chat do
						local newChat = true
						if table.getn(oldData) > 0 then
							for index, old in oldData do
								if (old.oldTime + 3) < GetGameTimeSeconds() then
									oldData[index] = nil
								elseif old.msg.text == chat.msg.text and old.sender == chat.sender and chat.msg.to == old.msg.to then
									newChat = false
								elseif type(chat.msg.to) == 'number' and chat.msg.to == old.msg.to and old.msg.text == chat.msg.text then
									newChat = false
								end
							end
						end						
						if newChat then							
							chat.oldTime = GetGameTimeSeconds()
							table.insert(oldData, chat)
							sendChat(chat.sender, chat.msg)
						end
					end
					UnitData.Chat = {}
				end
			end
			WaitSeconds(0.1)
		end
	end
end