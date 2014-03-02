--Rating[] = Table contenant les Rating
--Player[] = Table contenant les Pseudo des Joueurs
--TeamA_Total = Addition de tout les Rating de la Team A
--TeamB_Total = Addition de tout les Rating de la Team B
--AB_Total = Addition de tout les Rating des deux Team
--TeamA_Purcent = Pourcentage de Balance comparer a la Team B
--TeamB_Purcent = Pourcentage de Balance comparer a la Team A
--AB_Purcent = Pourcentage de Balance entre les deux Team
--BEST_Lower = Difference de Rating entre les deux Team
--BEST_IndexA = Index de Table du meilleur Balance de la Team A
--BEST_IndexB = Index de Table du meilleur Balance de la Team B
--BEST_PlayerName_TeamA[] = Table contenant les Pseudo Balancé de la Team A
--BEST_PlayerName_TeamB[] = Table contenant les Pseudo Balancé de la Team B

--

function Combination(t,n)
	local n,max,tn,output=n,table.getn(t),{},{}
	for x=1,n do tn[x],output[x]=x,t[x] end -- Generate 1st Combination
	tn[n]=tn[n]-1 -- Needed to output 1st Combination
	return function() -- Iterator fn
		local t,tn,output,x,n,max=t,tn,output,n,n,max
		while tn[x]==max+x-n do x=x-1 end -- Locate update point
		if x==0 then return nil end -- Return if no update point
		tn[x]=tn[x]+1 -- Add 1 to update point (UP)
		output[x]=t[tn[x]] -- Update output at UP
		for i=x+1,n do 
			tn[i]=tn[i-1]+1 -- Update points to right of UP
			output[i]=t[tn[i]] -- Update output to refect change in points
		end
		return output
	end
end

--

function Start(Rating, Player)
	if not Rating and not Player then
		return false
	end
	--Rating = {'10', '20', '30', '40', '50', '60', '70', '80', '90', '100', '110', '120'}
	--Player = {'Xinnony', 'Vicarian', 'Patto', 'Gyzmo69', 'Quentin3620', 'Alex-le-portos', 'iPhone', 'Crock', 'Oceane', 'Dixie', 'Benji', 'Lyess'}
	--
	if table.getn(Rating) != table.getn(Player) then
		#--LOG('THE Table Rating is not equal to Table Player !')
		return false
	end
	--
	
	for i = 1, table.getn(Rating) do
		#--LOG('Rating:'..Rating[i])
		#--LOG('Player:'..Player[i])
	end
	#--LOG('Start Combination')
	result = Combination(Rating, table.getn(Rating)/2) -- Table, Size
	
	--
	
	tableresultTotal = {}
	#BEST_PlayerRating_TeamA = {}
	#BEST_PlayerRating_TeamB = {}
	i = 1
	for k, v in result do
		calc = 0
		for j = 1, table.getn(k) do
			--LOG('#k:'..table.getn(k)..' / calc:'..calc..' / k:'..k[j])
			#BEST_PlayerRating_TeamA[i] = k[j]
			#BEST_PlayerRating_TeamB[i] = k[j]
			calc = calc + tonumber(k[j])
		end
		--print('----------')
		
		tableresultTotal[i] = calc--k[1]+k[2]+k[3]+k[4]+k[5]+k[6]
		i = i + 1
	end

	--

	BEST_Lower = 9999999
	BEST_IndexA = nil
	BEST_IndexB = nil
	for i = 1, table.getn(tableresultTotal)-1 do
		TeamA_Total = tableresultTotal[i]
		TeamB_Total = tableresultTotal[table.getn(tableresultTotal)-i+1]
		if TeamA_Total > TeamB_Total then
			AB_Different = TeamA_Total - TeamB_Total
		else
			AB_Different = TeamB_Total - TeamA_Total
		end
		--
		if BEST_Lower > AB_Different then
			BEST_Lower = AB_Different
			BEST_IndexA = i
			BEST_IndexB = table.getn(tableresultTotal)-BEST_IndexA+1
			#--LOG('FINDED : '..AB_Different)
		else
			--LOG('no : '..AB_Different)
		end
	end

	--

	TeamA_Total = tableresultTotal[BEST_IndexA]
	TeamB_Total = tableresultTotal[BEST_IndexB]
	#--LOG('Best Index : '..BEST_IndexA..' / '..BEST_IndexB)
	AB_Total = TeamA_Total + TeamB_Total
	TeamA_Purcent = (TeamA_Total*100)/AB_Total
	TeamB_Purcent = (TeamB_Total*100)/AB_Total
	if TeamA_Purcent < TeamB_Purcent then
		AB_Purcent = (TeamA_Purcent/TeamB_Purcent)*100
	else
		AB_Purcent = (TeamB_Purcent/TeamA_Purcent)*100
	end

	LOG('----------------')
	LOG('The BEST % is : '..AB_Purcent)
	LOG('----------------')

	--

	result2 = Combination(Player, table.getn(Player)/2) -- Table, Size

	--

	BEST_PlayerName_TeamA = {}
	BEST_PlayerName_TeamB = {}
	i = 1
	for k, v in result2 do
		if i == BEST_IndexA then
			for j = 1, table.getn(k) do
				BEST_PlayerName_TeamA[j] = k[j]
			end
		elseif i == BEST_IndexB then
			for j = 1, table.getn(k) do
				BEST_PlayerName_TeamB[j] = k[j]
			end
		end
		i = i + 1
	end

	--

	#--for j = 1, table.getn(BEST_PlayerName_TeamA) do
		#--LOG('TeamA : '..BEST_PlayerName_TeamA[j]..'('..j..')')
	#--end
	#--LOG('VS')
	#--for j = 1, table.getn(BEST_PlayerName_TeamB) do
		#--LOG('TeamB : '..BEST_PlayerName_TeamB[j]..'('..j..')')
	#--end
	#--LOG('----------------')
	
	--
	
	#--for k, v in tableresultTotal do
		#--LOG('vXxx : '..tostring(v[BEST_IndexA]))
		#--LOG('kXxx : '..tostring(k[BEST_IndexA]))
	#--end
	
	Final_Result = {}
	Final_Result['A'] = tableresultTotal[BEST_IndexA]
	Final_Result['B'] = tableresultTotal[BEST_IndexB]
	Final_Result['TA'] = TeamA_Total -- Addition de tout les Rating de la Team A
	Final_Result['TB'] = TeamB_Total -- Addition de tout les Rating de la Team B
	Final_Result['TAB'] = AB_Total -- Addition de tout les Rating des deux Team
	Final_Result['PA'] = TeamA_Purcent -- Pourcentage de Balance comparer a la Team B
	Final_Result['PB'] = TeamB_Purcent -- Pourcentage de Balance comparer a la Team A
	Final_Result['PAB'] = AB_Purcent -- Pourcentage de Balance entre les deux Team
	Final_Result['BL'] = BEST_Lower -- Difference de Rating entre les deux Team
	Final_Result['BA'] = BEST_IndexA -- Index de Table du meilleur Balance de la Team A
	Final_Result['BB'] = BEST_IndexB -- Index de Table du meilleur Balance de la Team B
	Final_Result['NA'] = BEST_PlayerName_TeamA -- Table contenant les Pseudo Balancé de la Team A
	Final_Result['NB'] = BEST_PlayerName_TeamB -- Table contenant les Pseudo Balancé de la Team B
	Final_Result['nbA'] = table.getn(BEST_PlayerName_TeamA)
	Final_Result['nbB'] = table.getn(BEST_PlayerName_TeamB)
	
	--
	
	return Final_Result
end