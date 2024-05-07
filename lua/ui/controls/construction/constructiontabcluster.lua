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

local TabCheckboxes = {
    construction = Checkbox,
    selection = Checkbox,
    enhancement = Checkbox,
}

---@class ConstructionTabCluster : RadioCluster
ConstructionTabCluster = ClassUI(RadioCluster) {

    __init = function(self, parent, Callback)
        RadioCluster.__init(self, parent, TabCheckboxes)

        parent:AddOnSelectionCallback(self, self.OnSelection)
        import('/lua/ui/controls/construction/layouts/bottomMini/constructiontabcluster.lua').InitLayoutFunctions(self)
        self.Callback = Callback
    end,

    SetSelectedCheckbox = function(self, selectedKey)
        RadioCluster.SetSelectedCheckbox(self, selectedKey)
        self.Callback(self.parent, selectedKey)
    end,

    --ParentCallback = function(self, selectedKey)
        --To be overriden by the parent on init
        --self.parent:OnConstructionTabChanged(selectedKey)
    --end,

    OnSelection = function(self, data)

        -- Process our OnSelectionDataTable here and do stuff
        -- (enable/disable whatever tabs we have available based on the selected units)

        -- Hardcode for demo. This also updates the layout of the parent.
        self:SetSelectedCheckbox('construction')
    end,

}