do
	local FactionsIcon = {
		"/widgets/faction-icons-alpha_bmp/uef_ico.dds",
		"/widgets/faction-icons-alpha_bmp/aeon_ico.dds",
		"/widgets/faction-icons-alpha_bmp/cybran_ico.dds",
		"/widgets/faction-icons-alpha_bmp/seraphim_ico.dds",
		"/widgets/faction-icons-alpha_bmp/observer_ico.dds",		
	}

	function SetupChatScroll()
		GUI.chatContainer.top = 1
		GUI.chatContainer.scroll = UIUtil.CreateVertScrollbarFor(GUI.chatContainer)
		
		local numLines = function() return table.getsize(GUI.chatLines) end
		GUI.chatContainer.prevtabsize = 0
		GUI.chatContainer.prevsize = 0
		
		local function IsValidEntry(entryData)
			local result = true
			if entryData.camera then
				result = ChatOptions.links
			else
				result = ChatOptions[entryData.armyID]
			end
			return result
		end
		
		local function DataSize()
			if GUI.chatContainer.prevtabsize != table.getn(chatHistory) then
				local size = 0
				for i, v in chatHistory do
					if IsValidEntry(v) then
						size = size + table.getn(v.wrappedtext)
					end
				end
				GUI.chatContainer.prevtabsize = table.getn(chatHistory)
				GUI.chatContainer.prevsize = size
			end
			return GUI.chatContainer.prevsize
		end
		
		-- called when the scrollbar for the control requires data to size itself
		-- GetScrollValues must return 4 values in this order:
		-- rangeMin, rangeMax, visibleMin, visibleMax
		-- aixs can be "Vert" or "Horz"
		GUI.chatContainer.GetScrollValues = function(self, axis)
			local size = DataSize()
			--LOG(size, ":", self.top, ":", math.min(self.top + numLines(), size))
			return 1, size, self.top, math.min(self.top + numLines(), size)
		end
	
		-- called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
		GUI.chatContainer.ScrollLines = function(self, axis, delta)
			self:ScrollSetTop(axis, self.top + math.floor(delta))
		end
	
		-- called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
		GUI.chatContainer.ScrollPages = function(self, axis, delta)
			self:ScrollSetTop(axis, self.top + math.floor(delta) * numLines())
		end
	
		-- called when the scrollbar wants to set a new visible top line
		GUI.chatContainer.ScrollSetTop = function(self, axis, top)
			top = math.floor(top)
			if top == self.top then return end
			local size = DataSize()
			self.top = math.max(math.min(size - numLines()+1, top), 1)
			self:CalcVisible()
		end
	
		-- called to determine if the control is scrollable on a particular access. Must return true or false.
		GUI.chatContainer.IsScrollable = function(self, axis)
			return true
		end
		
		GUI.chatContainer.ScrollToBottom = function(self)
			--LOG(DataSize())
			GUI.chatContainer:ScrollSetTop(nil, DataSize())
		end
		
		-- determines what controls should be visible or not
		GUI.chatContainer.CalcVisible = function(self)
			GUI.bg.curTime = 0
			local index = 1
			local tempTop = self.top
			local curEntry = 1
			local curTop = 1
			local tempsize = 0
			for i, v in chatHistory do
				if IsValidEntry(v) then
					if tempsize + table.getsize(v.wrappedtext) < tempTop then
						tempsize = tempsize + table.getsize(v.wrappedtext)
					else
						curEntry = i
						for h, x in v.wrappedtext do
							if h + tempsize == tempTop then
								curTop = h
								break
							end
						end
						break
					end
				end
			end
			while GUI.chatLines[index] do
				if not chatHistory[curEntry].wrappedtext[curTop] then
					if chatHistory[curEntry].new then chatHistory[curEntry].new = nil end
					curTop = 1
					curEntry = curEntry + 1
					while chatHistory[curEntry] and not IsValidEntry(chatHistory[curEntry]) do
						curEntry = curEntry + 1
					end
				end
				if chatHistory[curEntry] then
					local Index = index
					if curTop == 1 then
						GUI.chatLines[index].name:SetText(chatHistory[curEntry].name)
						if chatHistory[curEntry].armyID == GetFocusArmy() then
							GUI.chatLines[index].nameBG:Disable()
						else
							GUI.chatLines[index].nameBG:Enable()
						end
						GUI.chatLines[index].text:SetText(chatHistory[curEntry].wrappedtext[curTop] or "")
						GUI.chatLines[index].teamColor:SetSolidColor(chatHistory[curEntry].color)
						GUI.chatLines[index].factionIcon:SetTexture(UIUtil.UIFile(FactionsIcon[chatHistory[curEntry].faction]))
						GUI.chatLines[index].topBG.Right:Set(GUI.chatLines[index].Right)
						GUI.chatLines[index].IsTop = true
						GUI.chatLines[index].chatID = chatHistory[curEntry].armyID
						if chatHistory[curEntry].camera and not GUI.chatLines[index].camIcon then
							GUI.chatLines[index].camIcon = Bitmap(GUI.chatLines[index].textBG, UIUtil.UIFile('/game/camera-btn/pinned_btn_up.dds'))
							GUI.chatLines[index].camIcon.Height:Set(16)
							GUI.chatLines[index].camIcon.Width:Set(20)
							LayoutHelpers.AtVerticalCenterIn(GUI.chatLines[index].camIcon, GUI.chatLines[index].teamColor)
							GUI.chatLines[index].camIcon.Left:Set(function() return GUI.chatLines[Index].name.Right() + 4 end)
							GUI.chatLines[index].text.Left:Set(function() return GUI.chatLines[Index].camIcon.Right() + 4 end)
						elseif not chatHistory[curEntry].camera and GUI.chatLines[index].camIcon then
							GUI.chatLines[index].camIcon:Destroy()
							GUI.chatLines[index].camIcon = false
							GUI.chatLines[index].text.Left:Set(function() return GUI.chatLines[Index].nameBG.Right() + 2 end)
						end
					else
						GUI.chatLines[index].topBG.Right:Set(GUI.chatLines[index].teamColor.Right)
						GUI.chatLines[index].nameBG:Disable()
						GUI.chatLines[index].name:SetText('')
						GUI.chatLines[index].text:SetText(chatHistory[curEntry].wrappedtext[curTop] or "")
						GUI.chatLines[index].teamColor:SetSolidColor('00000000')
						GUI.chatLines[index].factionIcon:SetSolidColor('00000000')
						GUI.chatLines[index].IsTop = false
						if GUI.chatLines[index].camIcon then
							GUI.chatLines[index].camIcon:Destroy()
							GUI.chatLines[index].camIcon = false
							GUI.chatLines[index].text.Left:Set(function() return GUI.chatLines[Index].nameBG.Right() + 2 end)
						end
					end
					if chatHistory[curEntry].camera then
						GUI.chatLines[index].cameraData = chatHistory[curEntry].camera
						GUI.chatLines[index].textBG:Enable()
						GUI.chatLines[index].text:SetColor(chatColors[ChatOptions.link_color])
					else
						GUI.chatLines[index].textBG:Disable()
						GUI.chatLines[index].text:SetColor('ffc2f6ff')
						GUI.chatLines[index].text:SetColor(chatColors[ChatOptions[chatHistory[curEntry].tokey]])
					end
					if not GUI.bg:IsHidden() then
						GUI.chatLines[index].rightBG:Show()
						GUI.chatLines[index].leftBG:Show()
					end
					GUI.chatLines[index].textBG:SetSolidColor('00000000')
					GUI.chatLines[index].nameBG:SetSolidColor('00000000')
					GUI.chatLines[index].EntryID = curEntry
					if chatHistory[curEntry].new and GUI.bg:IsHidden() then 
						GUI.chatLines[index]:Show()
						GUI.chatLines[index].topBG:Hide()
						GUI.chatLines[index].rightBG:Hide()
						GUI.chatLines[index].leftBG:Hide()
						if GUI.chatLines[index].name:GetText() == '' then
							GUI.chatLines[index].teamColor:Hide()
						end
						GUI.chatLines[index].time = 0
						GUI.chatLines[index].OnFrame = function(self, delta)
							self.time = self.time + delta
							if self.time > ChatOptions.fade_time then
								if GUI.bg:IsHidden() then
									self:Hide()
								end
								self:SetNeedsFrameUpdate(false)
							end
						end
						GUI.chatLines[index]:SetNeedsFrameUpdate(true)
					end
				else
					GUI.chatLines[index].nameBG:Disable()
					GUI.chatLines[index].name:SetText('')
					GUI.chatLines[index].text:SetText('')
					GUI.chatLines[index].teamColor:SetSolidColor('00000000')
					GUI.chatLines[index].textBG:SetSolidColor('00000000')
					GUI.chatLines[index].nameBG:SetSolidColor('00000000')
					GUI.chatLines[index].topBG:SetSolidColor('00000000')
					GUI.chatLines[index].leftBG:SetSolidColor('00000000')
					GUI.chatLines[index].rightBG:SetSolidColor('00000000')
				end
				GUI.chatLines[index]:SetAlpha(ChatOptions.win_alpha, true)
				curTop = curTop + 1
				index = index + 1
			end
		end
	end
	
	function FindClients(id)
		local t = GetArmiesTable()
		local focus = t.focusArmy
		local result = {}
		if focus == -1 then
			for index,client in GetSessionClients() do
				if not client.connected then
					continue
				end
				local playerIsObserver = true
				for id, player in GetArmiesTable().armiesTable do
					if player.outOfGame and player.human and player.nickname == client.name then						
						table.insert(result, index)
						playerIsObserver = false
						break
					elseif player.nickname == client.name then
						playerIsObserver = false
						break
					end
				end
				if playerIsObserver then
					table.insert(result, index)
				end
			end
		else
			local srcs = {}
			for army,info in t.armiesTable do
				if id then
					if army == id then
						for k,cmdsrc in info.authorizedCommandSources do
							srcs[cmdsrc] = true
						end
						break
					end
				else
					if IsAlly(focus, army) then
						for k,cmdsrc in info.authorizedCommandSources do
							srcs[cmdsrc] = true
						end
					end
				end
			end
			for index,client in GetSessionClients() do
				for k,cmdsrc in client.authorizedCommandSources do
					if srcs[cmdsrc] then
						table.insert(result, index)
						break
					end
				end
			end
		end
		return result
	end

	function CreateChatEdit()
		local parent = GUI.bg:GetClientGroup()
		local group = Group(parent)
		
		group.Bottom:Set(parent.Bottom)
		group.Right:Set(parent.Right)
		group.Left:Set(parent.Left)
		group.Top:Set(function() return group.Bottom() - group.Height() end)
		
		local toText = UIUtil.CreateText(group, '', 14, 'Arial')
		toText.Bottom:Set(function() return group.Bottom() - 1 end)
		toText.Left:Set(function() return group.Left() + 35 end)
		
		ChatTo.OnDirty = function(self)
			if ToStrings[self()] then
				toText:SetText(LOC(ToStrings[self()].caps))
			else
				toText:SetText(LOCF('%s %s:', ToStrings['to'].caps, GetArmyData(self()).nickname))
			end
		end
		
		group.edit = Edit(group)
		group.edit.Left:Set(function() return toText.Right() + 5 end)
		group.edit.Right:Set(function() return group.Right() - 38 end)
		group.edit.Depth:Set(function() return GUI.bg:GetClientGroup().Depth() + 200 end)
		group.edit.Bottom:Set(function() return group.Bottom() - 1 end)
		group.edit.Height:Set(function() return group.edit:GetFontHeight() end)
		UIUtil.SetupEditStd(group.edit, "ff00ff00", nil, "ffffffff", UIUtil.highlightColor, UIUtil.bodyFont, 14, 200)
		group.edit:SetDropShadow(true)
		group.edit:ShowBackground(false)
		
		group.edit:SetText('')
		
		group.Height:Set(function() return group.edit.Height() end)
		
		local function CreateTestBtn(text)
			local btn = UIUtil.CreateCheckboxStd(group, '/dialogs/toggle_btn/toggle')
			btn.Depth:Set(function() return group.Depth() + 10 end)
			btn.OnClick = function(self, modifiers)
				if self._checkState == "unchecked" then
					self:ToggleCheck()
				end
			end
			btn.txt = UIUtil.CreateText(btn, text, 12, UIUtil.bodyFont)
			LayoutHelpers.AtCenterIn(btn.txt, btn)
			btn.txt:SetColor('ffffffff')
			btn.txt:DisableHitTest()
			return btn
		end
		
		group.camData = UIUtil.CreateCheckbox(group,
			UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_up.dds'),
			UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_down.dds'),
			UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_over.dds'),
			UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_over.dds'),
			UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_dis.dds'),
			UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_dis.dds'))
		
		LayoutHelpers.AtRightIn(group.camData, group, 5)
		LayoutHelpers.AtVerticalCenterIn(group.camData, group.edit, -1)
		
		group.chatBubble = Button(group,
			UIUtil.UIFile('/game/chat-box_btn/radio_btn_up.dds'),
			UIUtil.UIFile('/game/chat-box_btn/radio_btn_down.dds'),
			UIUtil.UIFile('/game/chat-box_btn/radio_btn_over.dds'),
			UIUtil.UIFile('/game/chat-box_btn/radio_btn_dis.dds'))
		group.chatBubble.OnClick = function(self, modifiers)
			if not self.list then
				self.list = CreateChatList(self)
				LayoutHelpers.Above(self.list, self, 15)
				LayoutHelpers.AtLeftIn(self.list, self, 15)
			else
				self.list:Destroy()
				self.list = nil
			end
		end
		
		toText.HandleEvent = function(self, event)
			if event.Type == 'ButtonPress' then
				group.chatBubble:OnClick(event.Modifiers)
			end
		end
		
		LayoutHelpers.AtLeftIn(group.chatBubble, group, 3)
		LayoutHelpers.AtVerticalCenterIn(group.chatBubble, group.edit)
		
		group.edit.OnNonTextKeyPressed = function(self, charcode, event)
			GUI.bg.curTime = 0
			local function RecallCommand(entryNumber)
				self:SetText(commandHistory[self.recallEntry].text)
				if commandHistory[self.recallEntry].camera then
					self.tempCam = commandHistory[self.recallEntry].camera
					group.camData:Disable()
					group.camData:SetCheck(true)
				else
					self.tempCam = nil
					group.camData:Enable()
					group.camData:SetCheck(false)
				end
			end
			if charcode == UIUtil.VK_NEXT then
				local mod = 10
				if event.Modifiers.Shift then
					mod = 1
				end
				ChatPageDown(mod)
				return true
			elseif charcode == UIUtil.VK_PRIOR then
				local mod = 10
				if event.Modifiers.Shift then
					mod = 1
				end
				ChatPageUp(mod)
				return true
			elseif charcode == UIUtil.VK_UP then
				if table.getsize(commandHistory) > 0 then
					if self.recallEntry then
						self.recallEntry = math.max(self.recallEntry-1, 1)
					else
						self.recallEntry = table.getsize(commandHistory)
					end
					RecallCommand(self.recallEntry)
				end
			elseif charcode == UIUtil.VK_DOWN then
				if table.getsize(commandHistory) > 0 then
					if self.recallEntry then
						self.recallEntry = math.min(self.recallEntry+1, table.getsize(commandHistory))
						RecallCommand(self.recallEntry)
						if self.recallEntry == table.getsize(commandHistory) then
							self.recallEntry = nil
						end
					else
						self:SetText('')
					end
				end
			else
				return true
			end
		end
		
		group.edit.OnCharPressed = function(self, charcode)
			local charLim = self:GetMaxChars()
			if charcode == 9 then
				return true
			end
			GUI.bg.curTime = 0
			if STR_Utf8Len(self:GetText()) >= charLim then
				local sound = Sound({Cue = 'UI_Menu_Error_01', Bank = 'Interface',})
				PlaySound(sound)
			end
		end
		
		group.edit.OnEnterPressed = function(self, text)
			GUI.bg.curTime = 0
			if group.camData:IsDisabled() then
				group.camData:Enable()
			end
			if text == "" then
				ToggleChat()
			else
				local gnBegin, gnEnd = string.find(text, "%s+")
				if gnBegin and (gnBegin == 1 and gnEnd == string.len(text)) then
					return
				end
				if import('/lua/ui/game/taunt.lua').CheckForAndHandleTaunt(text) then
					return
				end
	
				msg = { to = ChatTo(), Chat = true }
				if self.tempCam then
					msg.camera = self.tempCam
				elseif group.camData:IsChecked() then
					msg.camera = GetCamera('WorldCamera'):SaveSettings()
				end
				msg.text = text
				if ChatTo() == 'allies' then
					if GetFocusArmy() != -1 then
						SessionSendChatMessage(FindClients(), msg)
					else
						msg.Observer = true
						SessionSendChatMessage(FindClients(), msg)
					end
				elseif type(ChatTo()) == 'number' then
					if GetFocusArmy() != -1 then
						SessionSendChatMessage(FindClients(ChatTo()), msg)
						msg.echo = true
						msg.from = GetArmyData(GetFocusArmy()).nickname
						ReceiveChat(GetArmyData(ChatTo()).nickname, msg)
					end
				else
					if GetFocusArmy() == -1 then
						msg.Observer = true
						SessionSendChatMessage(FindClients(), msg)
					else
						SessionSendChatMessage(msg)
					end
				end
				table.insert(commandHistory, msg)
				self.recallEntry = nil
				self.tempCam = nil
			end
		end
		
		ChatTo:Set('all')
		group.edit:AcquireFocus()
		
		return group
	end
		
	function ReceiveChat(sender, msg)
		if not msg.ConsoleOutput then
			SimCallback({Func="GiveResourcesToPlayer", Args={ From=GetFocusArmy(), To=GetFocusArmy(), Mass=0, Energy=0, Sender=sender, Msg=msg},} , true)
		end
		if not SessionIsReplay() then
			ReceiveChatFromSim(sender, msg)
		end
	end

	function ReceiveChatFromSim(sender, msg)		
		sender = sender or "nil sender"
		if msg.ConsoleOutput then
			print(LOCF("%s %s", sender, msg.ConsoleOutput))
			return
		end
		if not msg.Chat then			
			return
		end
		if type(msg) == 'string' then
			msg = { text = msg }
		elseif type(msg) != 'table' then
			msg = { text = repr(msg) }
		end
		local armyData = GetArmyData(sender)
		if not armyData and GetFocusArmy() != -1 and not SessionIsReplay() then
			return
		end
		local towho = LOC(ToStrings[msg.to].text) or LOC(ToStrings['private'].text)		
		local tokey = ToStrings[msg.to].colorkey or ToStrings['private'].colorkey
		if msg.Observer then
			towho = LOC("<LOC lobui_0592>to observes:")
			tokey = "link_color"			
		end
		if msg.Observer and armyData.faction then
			armyData.faction = 4
		end
		if type(msg.to) == 'number' and SessionIsReplay() then
			towho = string.format("%s %s:", LOC(ToStrings.to.text), GetArmyData(msg.to).nickname)
		end
		local name = sender .. ' ' .. towho
		if msg.echo then			
			if msg.from and SessionIsReplay() then
				name = string.format("%s %s:", LOC(ToStrings.to.text), sender)
				name = msg.from.." "..name
			else
				name = string.format("%s %s:", LOC(ToStrings.to.caps), sender)
			end
		end		
		local tempText = WrapText({text = msg.text, name = name})
		-- if text wrap produces no lines (ie text is all white space) then add a blank line
		if table.getn(tempText) == 0 then
			tempText = {""}
		end
		local entry = {name = name,
			tokey = tokey,
			color = (armyData.color or "ffffffff"),
			armyID = (armyData.ArmyID or 1),
			faction = (armyData.faction or 4)+1,
			text = msg.text,
			wrappedtext = tempText,
			new = true}
		if msg.camera then
			entry.camera = msg.camera
		end
		table.insert(chatHistory, entry)
		if ChatOptions[entry.armyID] then
			if table.getsize(chatHistory) == 1 then
				GUI.chatContainer:CalcVisible()
			else
				GUI.chatContainer:ScrollToBottom()
			end
		end
		if SessionIsReplay() then
			PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Diplomacy_Close'}))
		end
	end
	
	function ToggleChat()
		if GUI.bg:IsHidden() then			
			GUI.bg:Show()
			GUI.chatEdit.edit:AcquireFocus()
			if not GUI.bg.pinned then
				GUI.bg:SetNeedsFrameUpdate(true)
				GUI.bg.curTime = 0
			end
			for i, v in GUI.chatLines do
				v:SetNeedsFrameUpdate(false)
				v:Show()
				v.OnFrame = nil
			end			
		else
			GUI.bg:Hide()
			GUI.chatEdit.edit:AbandonFocus()
			GUI.bg:SetNeedsFrameUpdate(false)
		end
	end
	
	function ActivateChat(modifiers)		
		if type(ChatTo()) != 'number' then
			if modifiers.Shift then
				ChatTo:Set('allies')
			else
				ChatTo:Set('all')
			end
		end
		ToggleChat()		
	end
end