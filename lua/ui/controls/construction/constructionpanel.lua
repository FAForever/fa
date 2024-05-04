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

local SkinnableFile = import('/lua/ui/uiutil.lua').SkinnableFile

local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Layouter = LayoutHelpers.ReusedLayoutFor

--------------------------------------------------------------------------------
-- Layout Terminology
--------------------------------------------------------------------------------

-- Body: the main part of a background element, generally has a cap on each end
-- Cap: end element, generally bookends a body. L/R/T/B == left/right/top/bottom
-- Alternate forms are denoted with $ORIGINALNAME_$ALTFORM (ex: bgMainCapL_TechTab)

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------

local textures = {
    bgMainBody = SkinnableFile('/game/construct-panel/construct-panel_bmp_m3.dds'),
    bgMainCapL = SkinnableFile('/game/construct-panel/construct-panel_s_bmp_l.dds'),
    bgMainCapL_TechTab = SkinnableFile('/game/construct-panel/construct-panel_bmp_l.dds'),
    bgMainCapR = SkinnableFile('/game/construct-panel/construct-panel_s_bmp_r.dds'),

    bgTechTabBody = SkinnableFile('/game/construct-panel/construct-panel_bmp_m1.dds'),
    bgTechTabCapR = SkinnableFile('/game/construct-panel/construct-panel_bmp_m2.dds'),

    leftBracketLower = SkinnableFile('/game/bracket-left-energy/bracket_bmp_t.dds'),
    leftBracketUpper = SkinnableFile('/game/bracket-left-energy/bracket_bmp_b.dds'),
    leftBracketMiddle = SkinnableFile('/game/bracket-left-energy/bracket_bmp_m.dds'),
    rightBracketLower = SkinnableFile('/game/bracket-right/bracket_bmp_t.dds'),
    rightBracketUpper = SkinnableFile('/game/bracket-right/bracket_bmp_b.dds'),
    rightBracketMiddle = SkinnableFile('/game/bracket-right/bracket_bmp_m.dds'),
}

---@class ConstructionPanel: Group
---@field bgMainBody Bitmap
---@field bgMainCapL Bitmap
---@field bgMainCapR Bitmap
---@field bgTechTabBody Bitmap
---@field bgTechTabCapR Bitmap
---@field leftBracketLower Bitmap
---@field leftBracketUpper Bitmap
---@field leftBracketMiddle Bitmap
---@field rightBracketLower Bitmap
---@field rightBracketUpper Bitmap
---@field rightBracketMiddle Bitmap
---@field constructionTabCluster ConstructionTabCluster
---@field techTabCluster TechTabCluster
---@field enhancementTabCluster EnhancementTabCluster
ConstructionPanel = ClassUI(Group) {

    __init = function(self, parent)
        Group.__init(self, parent)

        self.bgMainCapL = Bitmap(self) -- Left cap bitmap, under the pause/repeat build buttons
        self.bgMainCapR = Bitmap(self) -- Right cap bitmap, at the rightmost edge of the panel
        self.bgTechTabBody = Bitmap(self) -- Background element that pops up behind the tech level radio buttons
        self.bgTechTabCapR = Bitmap(self) -- Rightside cap for the tech tab background (bgMainCapL is the left cap)
        self.bgMainBody = Bitmap(self) -- Main body of our background

        self.rightBracketLower = Bitmap(self) -- Brackets at the right edge of the panel
        self.rightBracketUpper = Bitmap(self)
        self.rightBracketMiddle = Bitmap(self)

        -- These are our functional button groups
        -- The callback passed to these radio button clusters will
        -- be called with (cluster.parent, selectedKey) as parameters
        self.constructionTabCluster = ConstructionTabCluster(self, self.ConstructionClusterCallback)
        self.techTabCluster = TechTabCluster(self, self.TechClusterCallback)
        self.enhancementTabCluster = EnhancementTabCluster(self, self.EnhancementClusterCallback)

    end,

    Layout = function(self)

        LOG('background.lua/ConstructionPanel:Layout')

        -- Initial layout and texture setup
        Layouter(self.bgMainCapR)
            :Texture(textures.bgMainCapR)
            :AtRightBottomIn(self, 2, 5)

        Layouter(self.bgMainCapL)
            :Texture(textures.bgMainCapL)
            :AtLeftIn(self, 69)
            :AtBottomIn(self.bgMainCapR)

        Layouter(self.bgTechTabBody)
            :Texture(textures.bgTechTabBody)
            :AnchorToRight(self.bgMainCapL)
            :FillVertically(self.bgMainCapL)

        Layouter(self.bgTechTabCapR)
            :Texture(textures.bgTechTabCapR)
            :RightOf(self.bgTechTabBody)

        Layouter(self.bgMainBody)
            :Texture(textures.bgMainBody)
            :AnchorToRight(self.bgTechTabCapR)
            :AnchorToLeft(self.bgMainCapR)
            :FillVertically(self.bgMainCapR)

        Layouter(self.constructionTabCluster)
            :AnchorToLeft(self.bgMainCapL, -7)
            :AtBottomIn(self.bgMainBody, -11)
            :End()

        Layouter(self.techTabCluster)
            :RightOf(self.bgMainCapL)
            :End()

        Layouter(self.enhancementTabCluster)
            :RightOf(self.bgMainCapL)
            :End()

        -- Brackets in a separate function to keep things organized
        self:BracketLayout()
    end,

    ConstructionClusterCallback = function(self, key)
        LOG('background.lua/ConstructionPanel:ConstructionClusterCallback(\''..key..'\')')
        self:SetLayoutByKey(key)
    end,

    TechClusterCallback = function(self, key)
        LOG('background.lua/ConstructionPanel:TechTabClusterCallback(\''..key..'\')')
    end,

    EnhancementClusterCallback = function(self, key)
        LOG('background.lua/ConstructionPanel:EnhancementTabClusterCallback(\''..key..'\')')
    end,

    ---This method morphs our layout to show the tech tab bg (or not), along
    ---with the enhancement/tech level selection tabs, based on the key passed
    ---@param self ConstructionPanel
    ---@param key string
    SetLayoutByKey = function(self, key)
        LOG('background.lua/ConstructionPanel:SetLayoutByKey(\''..key..'\')')
        self.lastKey = key
        if key == 'construction' or key == 'enhancement' then -- Show our tech tab elements and layout the tech background elements
            self.bgTechTabBody:Show()
            self.bgTechTabCapR:Show()
            if key == 'construction' then -- we need the tech level selector
                self.techTabCluster:Show()
                self.enhancementTabCluster:Hide()
                self.bgTechTabBody.Right:Set(self.techTabCluster.Right)
            else -- we need the enhancement slot selector
                self.techTabCluster:Hide()
                self.enhancementTabCluster:Show()
                self.bgTechTabBody.Right:Set(self.enhancementTabCluster.Right)
            end
            Layouter(self.bgMainCapL) -- Change our left cap texture to the tall tech tab version
                :Texture(textures.bgMainCapL_TechTab)
                :DimensionsFromTexture(textures.bgMainCapL_TechTab) -- We get taller/wider, so we need to update our size
                :AtBottomIn(self.bgMainCapR, -1) -- Textures align differently (ouch) so we also need to adjust our offset
                :AtLeftIn(self, 67)
            Layouter(self.bgMainBody) -- Anchor the left edge of our main background, to end of the cap, on the right of the tech tab
                :AnchorToRight(self.bgTechTabCapR)
            Layouter(self.constructionTabCluster) -- Reanchor the construction tab, because the textures don't align properly otherwise
                :AnchorToLeft(self.bgMainCapL, -7)

        elseif key == 'selection' then -- Hide our tech tab elements and layout our background and selector clusters
            self.bgTechTabBody:Hide()
            self.bgTechTabCapR:Hide()
            self.techTabCluster:Hide()
            self.enhancementTabCluster:Hide()
            Layouter(self.bgMainCapL) -- Change our left cap texture to the short version
                :Texture(textures.bgMainCapL)
                :DimensionsFromTexture(textures.bgMainCapL) -- We need to update our size, because we got shorter/narrower
                :AtBottomIn(self.bgMainCapR)
                :AtLeftIn(self, 69)
            Layouter(self.bgMainBody) -- Anchor our main background to the left cap, bypassing the tech tab elements
                :AnchorToRight(self.bgMainCapL)
            Layouter(self.constructionTabCluster)
                :AnchorToLeft(self.bgMainCapL, -5)
        end
    end,

    ---Handles the laying out of brackets on the sides of the construction panel
    ---@param self ConstructionPanel
    BracketLayout = function(self)
        -- Brackets on the right side
        Layouter(self.rightBracketLower) -- bottom
            :Texture(textures.rightBracketLower)
            :AtRightIn(self.bgMainCapR, -21)
            :AtTopIn(self.bgMainCapR, -6)
        Layouter(self.rightBracketUpper) -- upper
            :Texture(textures.rightBracketUpper)
            :AtRightIn(self.bgMainCapR, -21)
            :AtBottomIn(self.bgMainCapR, -5)
        Layouter(self.rightBracketMiddle) -- middle that fills the gap
            :Texture(textures.rightBracketMiddle)
            :AtRightIn(self.bgMainCapR, -14)
            :Bottom(self.rightBracketUpper.Top)
            :Top(self.rightBracketLower.Bottom)
    end,

    ---Provisional function for hiding/showing the construction panel based on selection
    ---@param self ConstructionPanel
    ---@param noUnitsSelected boolean
    OnSelection = function(self, noUnitsSelected)
        LOG('ConstructionPanel:OnSelection('..tostring(noUnitsSelected)..')')
        if noUnitsSelected then
            if not self:IsHidden() then
                self:Hide()
            end
        else
            if self:IsHidden() then
                self:Show()
                self.techTabCluster:SetSelection(nil)
                self.enhancementTabCluster:SetSelection(nil)
                self.constructionTabCluster:SetSelection('construction', true)
                self.constructionTabCluster:EnableCheckboxes({construction = true, enhancement = true})
            end
        end
    end,
}