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
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local IconButton = import('/lua/maui/button.lua').IconButton
local IconCheckbox = import('/lua/maui/checkbox.lua').IconCheckbox
local ConstructionTabCluster = import('/lua/ui/controls/construction/constructiontabcluster.lua').ConstructionTabCluster
local TechTabCluster = import('/lua/ui/controls/construction/techtabcluster.lua').TechTabCluster

-- We only have one selection, so we only need one of these
local selectionDataTable = {}

---@class ConstructionPanel: Group
---@field OnSelectionCallbacks table<Control, function>
---@field constructionTabCluster ConstructionTabCluster
---@field techTabCluster TechTabCluster
---@field pauseButton IconCheckbox
---@field repeatBuildTemplateButton IconCheckbox
ConstructionPanel = ClassUI(Group) {

    __init = function(self, parent)
        Group.__init(self, parent)

        self.OnSelectionCallbacks = {}

        -- These are our functional button groups
        -- The callback passed to these radio button clusters will
        -- be called with (cluster.parent, selectedKey) as parameters
        self.constructionTabCluster = ConstructionTabCluster(self, self.OnConstructionTabChanged)
        self.techTabCluster = TechTabCluster(self, self.OnTechTabChanged)

        self.pauseButton = IconCheckbox(self)
        self.pauseButton.OnCheck = function(checkbox, checked)
            self:OnPauseButtonChecked(checked)
        end
        self.repeatBuildTemplateButton = IconCheckbox(self)
        self.repeatBuildTemplateButton.OnCheck = function(checkbox, checked)
            self:OnRepeatBuildTemplateButtonChecked(checked, checkbox.key)
        end

        -- Right now the specific layout is hardcoded, but that can change obviously
        import('/lua/ui/controls/construction/layouts/bottomMini/constructionpanel.lua').InitLayoutFunctions(self)

    end,

    ----------------------------------------------------------------------------------------------------------------
    -- These methods should only be overriden by the layout, and are shown here for demonstration/readability purposes
    OnLayout = function(self)
        -- Overriden by layouter
    end,

    Layout = function(self, key)
        -- Overriden by layouter
    end,

    subLayouts = nil, -- Defined by layouter
    ----------------------------------------------------------------------------------------------------------------

    ---Called by the pause button when it's clicked
    OnPauseButtonChecked = function(self, pause)
        LOG('ConstructionPanel:OnPauseButtonClicked('..tostring(pause)..')')
    end,

    ---Called by the repeat build button when it's clicked
    OnRepeatBuildTemplateButtonChecked = function(self, repeatBuild)
        LOG('ConstructionPanel:OnRepeatBuildButtonClicked('..tostring(repeatBuild)..')')
    end,

    ---Called by the construction tab when a change is made
    OnConstructionTabChanged = function(self, key)
        LOG('ConstructionPanel:OnConstructionTabChanged('..tostring(key)..')')
        self.techTabCluster:SetSubset(key)
        self:Layout(key)
    end,

    ---Called by the tech/enchancement tab when a change is made
    OnTechTabChanged = function(self, key)
        LOG('ConstructionPanel:OnTechTabChanged('..tostring(key)..')')
    end,

    ---A method for any interested elements to get a callback called when selection is changed (UI side, so tables as keys is ok?)
    AddOnSelectionCallback = function(self, element, Callback)
        self.OnSelectionCallbacks[element] = Callback
    end,

    ---Provisional function for hiding/showing the construction panel based on selection
    ---Eventually we'll pass this function more info (if desired), and it will do more processing
    ---which can be reflected in the data table (which is passed to the OnSelection callbacks)
    ---@param self ConstructionPanel
    ---@param noUnitsSelected boolean
    OnSelection = function(self, noUnitsSelected)
        -- Hide and return if we have no units selected
        if noUnitsSelected then
            self:Hide()
            return
        end
        self:Show()
        selectionDataTable.noUnitsSelected = noUnitsSelected
        -- We'll assume(!) that OnSelectionCallbacks are only relevant when the panel is shown
        for element, OnSelectionCallback in self.OnSelectionCallbacks do
            OnSelectionCallback(element, selectionDataTable)
        end
    end,
}