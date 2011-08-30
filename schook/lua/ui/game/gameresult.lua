do

local originalDoGameResult = DoGameResult

function DoGameResult(armyIndex, result)	
	if not announced[armyIndex] then		
		if armyIndex == GetFocusArmy() then
			local armies = GetArmiesTable().armiesTable
			if result == 'defeat' then
				SimCallback({Func="GiveResourcesToPlayer", Args={ From=GetFocusArmy(), To=GetFocusArmy(), Mass=0, Energy=0, Loser=armies[armyIndex].nickname},} , true)
			elseif result == 'victory' then
				SimCallback({Func="GiveResourcesToPlayer", Args={ From=GetFocusArmy(), To=GetFocusArmy(), Mass=0, Energy=0, Winner=armies[armyIndex].nickname},} , true)
			elseif result == 'draw' then
				SimCallback({Func="GiveResourcesToPlayer", Args={ From=GetFocusArmy(), To=GetFocusArmy(), Mass=0, Energy=0, Draw=armies[armyIndex].nickname},} , true)
			end
		else
			local armies = GetArmiesTable().armiesTable
			if result == 'defeat' then
				SimCallback({Func="GiveResourcesToPlayer", Args={ From=GetFocusArmy(), To=GetFocusArmy(), Mass=0, Energy=0, Loser=armies[armyIndex].nickname},} , true)
			elseif result == 'victory' then
				SimCallback({Func="GiveResourcesToPlayer", Args={ From=GetFocusArmy(), To=GetFocusArmy(), Mass=0, Energy=0, Winner=armies[armyIndex].nickname},} , true)
			elseif result == 'draw' then
				SimCallback({Func="GiveResourcesToPlayer", Args={ From=GetFocusArmy(), To=GetFocusArmy(), Mass=0, Energy=0, Draw=armies[armyIndex].nickname},} , true)
			end
		end
	end
	originalDoGameResult(armyIndex, result)
end

end