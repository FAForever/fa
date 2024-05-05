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
local ConstructionTabCluster = import('/lua/ui/controls/construction/constructiontabcluster.lua').ConstructionTabCluster
local TechTabCluster = import('/lua/ui/controls/construction/techtabcluster.lua').TechTabCluster
local EnhancementTabCluster = import('/lua/ui/controls/construction/techtabcluster.lua').EnhancementTabCluster

-- We only have one selection, so we only need one of these
local selectionDataTable = {}

---@class ConstructionPanel: Group
---@field constructionTabCluster ConstructionTabCluster
---@field techTabCluster TechTabCluster
---@field enhancementTabCluster EnhancementTabCluster
---@field OnSelectionCallbacks table<Control, function>
---@field selectionDataTable table
ConstructionPanel = ClassUI(Group) {

    __init = function(self, parent)
        Group.__init(self, parent)

        -- These are our functional button groups
        -- The callback passed to these radio button clusters will
        -- be called with (cluster.parent, selectedKey) as parameters
        self.constructionTabCluster = ConstructionTabCluster(self)
        self.techTabCluster = TechTabCluster(self)
        self.enhancementTabCluster = EnhancementTabCluster(self)

        self.OnSelectionCallbacks = {}

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

    ----------------------------------------------------------------------------------------------------------------
    -- These methods should only be overriden by their respective sub element, and are shown here for readability
    PauseToggle = function(self, pause) WARN('ConstructionPanel:PauseToggle called but not overriden!') end,
    RepeatBuildToggle = function(self, repeatBuild) WARN('ConstructionPanel:RepeatBuildToggle called but not overriden!') end,
    OnConstructionTabSelected = function(self, key) WARN('ConstructionPanel:OnConstructionTabSelected called but not overriden!') end,
    OnTechTabSelected = function(self, key) WARN('ConstructionPanel:OnTechTabSelected called but not overriden!') end,
    OnEnhancementTabSelected = function(self, key) LOG('ConstructionPanel:OnEnhancementTabSelected called but not overriden!') end,
    ----------------------------------------------------------------------------------------------------------------

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
        LOG('ConstructionPanel:OnSelection')
        selectionDataTable.noUnitsSelected = noUnitsSelected
        -- We'll assume(!) that OnSelectionCallbacks are only relevant when the panel is shown
        for element, OnSelectionCallback in self.OnSelectionCallbacks do
            element:OnSelectionCallback(selectionDataTable)
        end
    end,
}