
local FactoryUnit = import("/lua/sim/units/factoryunit.lua").FactoryUnit
local FactoryUnitCalculateRollOffPoint = FactoryUnit.CalculateRollOffPoint

---@class SeaFactoryUnit : FactoryUnit
SeaFactoryUnit = ClassUnit(FactoryUnit) {

    ---@param self SeaFactoryUnit
    DestroyUnitBeingBuilt = function(self)
        local unitBeingBuilt = self.UnitBeingBuilt
        if unitBeingBuilt and not unitBeingBuilt.Dead and unitBeingBuilt:GetFractionComplete() < 1 then
            unitBeingBuilt:Destroy()
        end
    end,

    ---@param self SeaFactoryUnit
    CalculateRollOffPoint = function(self)
        -- backwards compatible, don't try and fix mods that rely on the old logic
        if not self.Blueprint.Physics.ComputeRollOffPoint then
            return FactoryUnitCalculateRollOffPoint(self)
        end

        -- retrieve our position
        local px, py, pz = self:GetPositionXYZ()

        -- retrieve roll off points
        local bp = self.Blueprint.Physics.RollOffPoints
        if not bp then
            return 0, px, py, pz
        end

        -- retrieve rally point
        local rallyPoint = self:GetRallyPoint()
        if not rallyPoint then
            return 0, px, py, pz
        end

        -- find the attachpoint for the build location
        local bone = (self:IsValidBone('Attachpoint') and 'Attachpoint') or (self:IsValidBone('Attachpoint01') and 'Attachpoint01')
        local bx, by, bz = self:GetPositionXYZ(bone)
        local ropx = bx - px
        local modz = 1.0 + 0.1 * self.UnitBeingBuilt.Blueprint.SizeZ

        -- find the nearest roll off point
        local bpKey = 1
        local distance, lowest = nil, nil
        for k, rolloffPoint in bp do

            local ropz = modz * rolloffPoint.Z
            distance = VDist2(rallyPoint[1], rallyPoint[3], ropx + px, ropz + pz)
            if not lowest or distance < lowest then
                bpKey = k
                lowest = distance
            end
        end

        -- finalize the computation
        local fx, fy, fz, spin
        local bpP = bp[bpKey]
        local unitBP = self.UnitBeingBuilt.Blueprint.Display.ForcedBuildSpin
        if unitBP then
            spin = unitBP
        else
            spin = bpP.UnitSpin
        end

        fx = ropx + px
        fy = bpP.Y + py
        fz = modz * bpP.Z + pz

        return spin, fx, fy, fz
    end,

}
