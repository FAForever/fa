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
local SkinnableFile = import('/lua/ui/uiutil.lua').SkinnableFile
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Layouter = LayoutHelpers.ReusedLayoutFor
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap

local EnhancementTabCheckboxClasses = {
    LCH = Checkbox,
    RCH = Checkbox,
    Back = Checkbox,
}

--This is the function we'll add to our parent and call when we're clicked
local OnEnhancementTabSelected = function(self, key)
    LOG('ConstructionPanel:OnEnhancementTabSelection('..key..')')
end

---@class EnhancementTabCluster : RadioCluster
EnhancementTabCluster = ClassUI(RadioCluster) {

    __init = function(self, parent)
        RadioCluster.__init(self, parent, EnhancementTabCheckboxClasses)

        parent:AddOnSelectionCallback(self, self.OnSelection)
        parent.OnEnhancementTabSelected = OnEnhancementTabSelected

        import('/lua/ui/controls/construction/layouts/bottomMini/enhancementtabcluster.lua').InitLayoutFunctions(self)
    end,

    SetSelectedCheckbox = function(self, selectedKey)
        RadioCluster.SetSelectedCheckbox(self, selectedKey)
        -- Only send our results back up to the parent if we're not hidden
        if not self.IsHidden() then
            self.parent:OnEnhancementTabSelection(selectedKey)
        end
    end,

    OnSelection = function(self, data)
        LOG('TechTabCluster:OnSelection')

        -- Process our OnSelectionDataTable here and do stuff
        -- (enable/disable whatever tabs we have available based on the selected units)

        -- Hardcode for demo. This also updates the layout of the parent.
        self:SetSelectedCheckbox('LCH')
    end,
}