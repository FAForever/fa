do

local scoreOption = sessionInfo.Options.Score or "yes"
if scoreOption == "no" then
	function _OnBeat()
		if sessionInfo.Options.GameSpeed and sessionInfo.Options.GameSpeed == 'adjustable' then
			controls.time:SetText(string.format("%s (%+d)", GetGameTime(), gameSpeed))
		else
			controls.time:SetText(GetGameTime())
		end
		if sessionInfo.Options.NoRushOption and sessionInfo.Options.NoRushOption != 'Off' then
			if tonumber(sessionInfo.Options.NoRushOption) * 60 > GetGameTimeSeconds() then
				local time = (tonumber(sessionInfo.Options.NoRushOption) * 60) - GetGameTimeSeconds()
				controls.time:SetText(LOCF('%02d:%02d:%02d', math.floor(time / 3600), math.floor(time/60), math.mod(time, 60)))
			end
			if not issuedNoRushWarning and tonumber(sessionInfo.Options.NoRushOption) * 60 == math.floor(GetGameTimeSeconds()) then
				import('/lua/ui/game/announcement.lua').CreateAnnouncement('<LOC score_0001>No Rush Time Elapsed', controls.time)
				issuedNoRushWarning = true
			end
		end
		local armiesInfo = GetArmiesTable().armiesTable
		if currentScores then
			for index, scoreData in currentScores do
				for _, line in controls.armyLines do
					if line.armyID == index then
						if line.OOG then break end
						line.score:SetText(LOC("<LOC _Playing>Playing"))
						if GetFocusArmy() == index then
							line.name:SetColor('ffff7f00')
							line.score:SetColor('ffff7f00')
							line.name:SetFont('Arial Bold', 14)
							line.score:SetFont('Arial Bold', 14)
							if scoreData.general.currentcap.count > 0 then
								SetUnitText(scoreData.general.currentunits.count, scoreData.general.currentcap.count)
							end
						else
							line.name:SetColor('ffffffff')
							line.score:SetColor('ffffffff')
							line.name:SetFont(UIUtil.bodyFont, 14)
							line.score:SetFont(UIUtil.bodyFont, 14)
						end
						if armiesInfo[index].outOfGame then
							line.score:SetText(LOC("<LOC _Defeated>Defeated"))
							line.OOG = true
							line.faction:SetTexture(UIUtil.UIFile('/game/unit-over/icon-skull_bmp.dds'))
							line.color:SetSolidColor('ff000000')
							line.name:SetColor('ffa0a0a0')
							line.score:SetColor('ffa0a0a0')
						end
						break
					end
				end
			end
		end
		if observerLine then
			if GetFocusArmy() == -1 then
				observerLine.name:SetColor('ffff7f00')
				observerLine.name:SetFont('Arial Bold', 14)
			else
				observerLine.name:SetColor('ffffffff')
				observerLine.name:SetFont(UIUtil.bodyFont, 14)
			end
		end
		table.sort(controls.armyLines, function(a,b)
			return a.armyID >= b.armyID
		end)
		import(UIUtil.GetLayoutFilename('score')).LayoutArmyLines()
	end	
end

end