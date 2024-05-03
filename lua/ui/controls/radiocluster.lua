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
---@field currentSelection string
RadioCluster = ClassUI(Group) {

    ---@param self RadioCluster
    ---@param parent Control
    ---@param checkboxes table<string, function> -- A table of checkboxes to create. The key is the name of the checkbox, the value is the Checkbox class.
    ---@param SelectionCallback function -- A function to call when a checkbox is selected. The key of the selected checkbox is passed as an argument.
    __init = function(self, parent, checkboxes, SelectionCallback)
        Group.__init(self, parent)

        -- Our callback function for when a checkbox is selected
        self.SelectionCallback = SelectionCallback

        -- Initialize our checkboxes 
        self.items = {}
        for key, CheckboxClass in checkboxes do
            local checkbox = CheckboxClass(self)
            checkbox.key = key
            checkbox.OnClick = function(cbox, eventModifiers)
                self:OnSelect(cbox.key)
            end
            self.items[key] = checkbox
        end

        self.currentSelection = nil
    end,

    Layout = function(self)
        -- Override this
    end,

    OnSelect = function(self, selectedKey)
        LOG('RadioCluster:OnSelect('..selectedKey..')')
        if selectedKey == self.currentSelection then
            return
        end
        self.currentSelection = selectedKey
        if self.SelectionCallback then
            self.SelectionCallback(selectedKey)
        end
        for key, checkbox in self.items do
            if key ~= selectedKey then
                checkbox:SetCheck(false, true)
            else
                checkbox:SetCheck(true, true)
            end
        end
    end,

    ---@param self RadioCluster
    ---@param keys? table<string, boolean>|boolean -- Hash table of checkboxes to enable. If false, all checkboxes are disabled. If nil, all checkboxes are enabled.
    EnableCheckboxes = function(self, keys)
        if keys then
            for key, checkbox in self.items do
                if keys[key] then
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