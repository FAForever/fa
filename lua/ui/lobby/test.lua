team1 = {}

if not team1["test"] then
	print("no test")
	team1["test"] = {}
	team1["test"]["youpi"] = team1["test"]["youpi"] + 1
end





 for k,v in pairs(team1) do  for i,j in pairs(v) do print(k,i,j) end end