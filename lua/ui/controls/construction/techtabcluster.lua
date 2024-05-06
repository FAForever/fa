--******************************************************************************************************
--** Copyright (c) 2024 FAForever
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

local RadioCluster = import('/lua/ui/controls/radiocluster.lua').RadioCluster
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local TableGetn = table.getn
local TableInsert = table.insert

-- Empty for now, we'll fill it with an ordered list of classes on init
local TechTabCheckboxes = {}

TabSubSets = {
    construction = {
        'tech1',
        'tech2',
        'tech3',
        'tech4',
        'templates',
    },
    enhancement = {
        'LCH',
        'RCH',
        'Back',
    }
}

---@class TechTabCluster : RadioCluster
TechTabCluster = ClassUI(RadioCluster) {

    __init = function(self, parent)

        -- We''ll need to find the longest subset to use as our max length for setting up the cluster
        local longestSubset
        for key, table in TabSubSets do
            if not longestSubset or TableGetn(table) > TableGetn(longestSubset) then
                longestSubset = table
            end
        end

        -- Right now this is hardcoded to use checkboxes, but flexibility otherwise isn't necessary at this point
        for i=1,TableGetn(longestSubset) do
            TableInsert(TechTabCheckboxes, Checkbox)
        end

        -- Call our RadioCluster constructor with our new list of checkboxes
        RadioCluster.__init(self, parent, TechTabCheckboxes)
        parent:AddOnSelectionCallback(self, self.OnSelection)

        import('/lua/ui/controls/construction/layouts/bottomMini/techtabcluster.lua').InitLayoutFunctions(self)
        self:SetSubset(longestSubset)
    end,

    SetSelectedCheckbox = function(self, selectedKey)
        RadioCluster.SetSelectedCheckbox(self, selectedKey)
        -- Only send our results back up to the parent if we're not hidden
        if not self:IsHidden() and selectedKey ~= self.parent.LastTechTabKey then
            self.parent:OnTechTabChanged(selectedKey)
        end
    end,

    ---For when the player has made a new selection and we need to update our construction UI
    ---param self TechTabCluster
    ---param data table
    OnSelection = function(self, data)
        LOG('TechTabCluster:OnSelection')

        -- Process our OnSelectionDataTable here and do stuff
        -- (enable/disable whatever tabs we have available based on the selected units)

        -- Hardcode for demo(?)
        self:SetSelectedCheckbox(1)
    end,

    ---Set the subset of tabs to display
    SetSubset = function(self, subset)
        if type(subset) == 'string' then
            subset = TabSubSets[subset]
        end
        for i, item in self.items do
            if subset[i] then
                item.key = subset[i]
            else
                item.key = nil
            end
        end
        self:OnLayout()
    end
}