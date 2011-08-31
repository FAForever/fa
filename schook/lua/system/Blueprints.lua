local oldModBlueprints = ModBlueprints   ###added for shipwreck mod

function ModBlueprints(all_bps)
	oldModBlueprints(all_bps)
	
	for id,bp in pairs(all_bps.Unit) do				
		local cats = {}
		for k,cat in pairs(bp.Categories) do
			cats[cat] = true
		end
		if cats.NAVAL and not bp.Wreckage then
			LOG("Adding wreckage information to ", bp.Description)
			bp.Wreckage = {
				Blueprint = '/props/DefaultWreckage/DefaultWreckage_prop.bp',
				EnergyMult = 0,
				HealthMult = 0.9,
				MassMult = 0.9,
				ReclaimTimeMultiplier = 1,
				WreckageLayers = {
					Air = false,
					Land = false,
					Seabed = true,
					Sub = true,
					Water = true,
				};
			}
		end
	end
end

