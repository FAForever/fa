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

local Group = import('/lua/maui/group.lua').Group

---@class RadioCluster : Group
---@field items table<string, Checkbox>
---@field currentSelection? string
---@field parent Control
---@field SelectionCallback function -- When a checkbox is selected, this function is called with the parent as the first parameter and the key of the selected checkbox as the second.
RadioCluster = ClassUI(Group) {

    ---@param self RadioCluster
    ---@param parent Control
    ---@param checkboxes table<string, function> -- A table of checkboxes to create. The key is the name of the checkbox, the value is the Checkbox class.
    __init = function(self, parent, checkboxes)
        Group.__init(self, parent)

        self.parent = parent

        -- Initialize our checkboxes 
        self.items = {}
        for key, CheckboxClass in checkboxes do
            local checkbox = CheckboxClass(self)
            checkbox.key = key
            checkbox:UseAlphaHitTest(false)
            checkbox.OnClick = function(cbox, eventModifiers)
                self:SetSelectedCheckbox(cbox.key)
            end
            self.items[key] = checkbox
        end

        self.lastSelection = nil
    end,

    ---@param self RadioCluster
    Layout = function(self)
        -- To be overriden by layout of inheriting class
    end,

    ---Sets checkboxes. For the internal state of the radio selector only.
    ---@param self RadioCluster
    ---@param selectedKey? string -- Key of selected checkbox. Pass nil to clear selection.
    SetSelectedCheckbox = function(self, selectedKey)

        -- If we're given an index, convert it to a string key
        if type(selectedKey) == 'number' then
            if self.items[selectedKey] then
                selectedKey = self.items[selectedKey].key
            end
        end

        LOG('RadioCluster:OnSelect('..tostring(selectedKey)..')')
        if selectedKey == self.lastSelection then
            return
        end
        self.lastSelection = selectedKey
        for key, checkbox in self.items do
            if checkbox.key ~= selectedKey then
                checkbox:SetCheck(false, true)
            else
                checkbox:SetCheck(true, true)
            end
        end
    end,

    GetSelected = function(self)
        return self.lastSelection
    end,

    ---@param self RadioCluster
    ---@param keys? table<string, boolean>|boolean -- Hash table of checkboxes to enable. If false, all checkboxes are disabled. If nil, all checkboxes are enabled.
    EnableCheckboxes = function(self, keys)
        if keys then
            for _, checkbox in self.items do
                if keys[checkbox.key] then
                    checkbox:Enable()
                else
                    checkbox:Disable()
                end
            end
        elseif keys == false then
            for _, checkbox in self.items do
                checkbox:Disable()
            end
        else
            for _, checkbox in self.items do
                checkbox:Enable()
            end
        end
    end,

}