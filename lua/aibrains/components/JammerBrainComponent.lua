--******************************************************************************************************
--** Copyright (c) 2024 Willem 'Jip' Wijnia
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

---@class AIBrainJammerComponent
---@field JammerResetTime number
---@field Jammers table<EntityId, Unit>
AIBrainJammerComponent = ClassSimple {

    JammerResetTime = 15,

    ---@param self HQAIBrainComponent | AIBrain
    CreateBrainShared = function(self)
        self.Jammers = {}
        setmetatable(self.Jammers, { __mode = 'v' })
        ForkThread(self.JammingToggleThread, self)
    end,

    --- Adds a unit to a list of all units with jammers
    ---@param self AIBrain
    ---@param unit Unit Jammer unit
    TrackJammer = function(self, unit)
        self.Jammers[unit.EntityId] = unit
    end,

    --- Removes a unit to a list of all units with jammers
    ---@param self AIBrain
    ---@param unit Unit Jammer unit
    UntrackJammer = function(self, unit)
        self.Jammers[unit.EntityId] = nil
    end,

    --- Creates a thread that interates over all jammer units to reset them when vision is lost on them
    ---@param self AIBrain
    JammingToggleThread = function(self)
        while true do
            for i, jammer in self.Jammers do
                if jammer.ResetJammer == 0 then
                    self:ForkThread(self.JammingFollowUpThread, jammer)
                    jammer.ResetJammer = -1
                else
                    if jammer.ResetJammer > 0 then
                        jammer.ResetJammer = jammer.ResetJammer - 1
                    end
                end
            end
            WaitSeconds(1)
        end
    end,

    --- Toggles a given unit's jammer
    ---@param self AIBrain
    ---@param unit Unit Jammer to be toggled
    JammingFollowUpThread = function(self, unit)
        unit:DisableUnitIntel('AutoToggle', 'Jammer')
        WaitSeconds(1)
        if not unit:BeenDestroyed() then
            unit:EnableUnitIntel('AutoToggle', 'Jammer')
            unit.ResetJammer = -1
        end
    end,

    ---@param self AIBrain
    ---@param blip Blip
    ---@param reconType ReconTypes
    ---@param val boolean
    OnIntelChange = function(self, blip, reconType, val)
        if reconType == 'LOSNow' or reconType == 'Omni' then
            if not val then
                local unit = blip:GetSource()
                if unit.Blueprint.Intel.JammerBlips > 0 then
                    unit.ResetJammer = self.JammerResetTime
                end
            end
        end
    end,
}
