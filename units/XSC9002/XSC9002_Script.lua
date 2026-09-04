-----------------------------------------------------------------
-- File     :  /cdimage/units/XSC9002/XSC9002_script.lua
-- Author   :  Greg Kohne
-- Summary  :  Jamming Crystal
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local SStructureUnit = import("/lua/seraphimunits.lua").SStructureUnit
local SSJammerCrystalAmbient = import("/lua/effecttemplates.lua").SJammerCrystalAmbient

local CreateUnitHPR = CreateUnitHPR
local IssuePatrol = IssuePatrol
local Random = Random
local WaitSeconds = WaitSeconds
local Vector = Vector

---@class XSC9002 : SStructureUnit
---@field AirChildUnit? XSC9011
---@field LandChildUnit? XSC9010
XSC9002 = ClassUnit(SStructureUnit) {
    ---@param self XSC9002
    ---@param builder Unit
    ---@param layer Layer
    OnCreate = function(self, builder, layer)
        -- Place emitters on certain light bones on the mesh.
        for _, v in SSJammerCrystalAmbient do
            CreateAttachedEmitter(self, 'XSC9002', self.Army, v)
        end

        self:ForkThread(self.LandBlipThread)
        self:ForkThread(self.AirBlipThread)

        -- Make unit uncapturable
        self:SetCapturable(false)

        SStructureUnit.OnCreate(self)
    end,

    ---@param self XSC9002
    LandBlipThread = function(self)
        local position = self:GetPosition()
        while not self.Dead do
            -- Spawn land blips
            self.LandChildUnit = CreateUnitHPR('XSC9010', self.Army, position[1], position[2], position[3], 0, 0, 0)--[[@as XSC9010]]
            self.LandChildUnit.parentCrystal = self

            WaitSeconds(Random(7, 13))

            self.LandChildUnit:Destroy()
            self.LandChildUnit = nil
        end
    end,

    ---@param self XSC9002
    AirBlipThread = function(self)
        local position = self:GetPosition()
        while not self.Dead do
            -- Spawn air blips
            self.AirChildUnit = CreateUnitHPR('XSC9011', self.Army, position[1], position[2], position[3], 0, 0, 0)--[[@as XSC9011]]
            self.AirChildUnit.parentCrystal = self

            local unitTbl = {self.AirChildUnit}
            local patrolPos = Vector(position[1] + Random(-10, 10), position[2], position[3] + Random(-10, 10))
            IssuePatrol(unitTbl, patrolPos)
            patrolPos[1] = position[1] + Random(-10, 10)
            patrolPos[3] = position[3] + Random(-10, 10)
            IssuePatrol(unitTbl, patrolPos)
            patrolPos[1] = position[1] + Random(-10, 10)
            patrolPos[3] = position[3] + Random(-10, 10)
            IssuePatrol(unitTbl, patrolPos)
            patrolPos[1] = position[1] + Random(-10, 10)
            patrolPos[3] = position[3] + Random(-10, 10)
            IssuePatrol(unitTbl, patrolPos)

            WaitSeconds(Random(7, 13))

            self.AirChildUnit:Destroy()
            self.AirChildUnit = nil
        end
    end,

    ---@param self XSC9002
    OnDestroy = function(self)
        if self.AirChildUnit then self.AirChildUnit:Destroy() end
        if self.LandChildUnit then self.LandChildUnit:Destroy() end

        SStructureUnit.OnDestroy(self)
    end,
}

TypeClass = XSC9002
