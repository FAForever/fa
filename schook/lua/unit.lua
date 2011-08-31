-- provide a new implementation of CreateWreckage that returns the wreckage prop   ###This file added for shipwreck mod

function Unit:CreateWreckage(overkillRatio)
	if overkillRatio and overkillRatio > 1.0 then
		return
	end

	if self:GetBlueprint().Wreckage.WreckageLayers[self:GetCurrentLayer()] then
		return self:CreateWreckageProp(overkillRatio)
	end
end
