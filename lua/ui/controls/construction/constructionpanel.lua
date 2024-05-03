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

        self.bgMainCapL = Bitmap(self)
        self.bgMainCapR = Bitmap(self)
        self.bgTechTabBody = Bitmap(self)
        self.bgTechTabCapR = Bitmap(self)
        self.bgMainBody = Bitmap(self)

        self.rightBracketLower = Bitmap(self)
        self.rightBracketUpper = Bitmap(self)
        self.rightBracketMiddle = Bitmap(self)

        -- These are our functional button groups
        -- The callback passed to the radio button clusters will be called with 
        -- the parent (this panel) and selected key as parameters
        self.constructionTabCluster = ConstructionTabCluster(self, self.ConstructionClusterCallback)
        self.techTabCluster = TechTabCluster(self, self.TechClusterCallback)
        self.enhancementTabCluster = EnhancementTabCluster(self, self.EnhancementClusterCallback)

    end,

    Layout = function(self)

        LOG('background.lua/ConstructionPanel:Layout')

        -- Right cap bitmap, at the rightmost edge of the panel
        Layouter(self.bgMainCapR)
            :Texture(textures.bgMainCapR)
            :AtRightBottomIn(self, 2, 5)

        -- Left cap bitmap, under the pause/repeat build buttons
        Layouter(self.bgMainCapL)
            :Texture(textures.bgMainCapL)
            :AtLeftIn(self, 69)
            :AtBottomIn(self.bgMainCapR)

        -- Background element that pops up behind the tech level radio buttons
        Layouter(self.bgTechTabBody)
            :Texture(textures.bgTechTabBody)
            :AnchorToRight(self.bgMainCapL)
            :FillVertically(self.bgMainCapL)

        -- Rightside cap for the tech tab background (bgMainCapL is the left cap)
        Layouter(self.bgTechTabCapR)
            :Texture(textures.bgTechTabCapR)
            :RightOf(self.bgTechTabBody)

        -- Main body of our background
        Layouter(self.bgMainBody)
            :Texture(textures.bgMainBody)
            :AnchorToRight(self.bgTechTabCapR)
            :AnchorToLeft(self.bgMainCapR)
            :FillVertically(self.bgMainCapR)

        -- Align the construction tab cluster to the left of the panel
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

        -- With no arguments, this will apply the default tech tab layout (no tab visible)
        --self:MorphLayout('selection')

        -- Brackets in a separate function to keep things organized
        self:BracketLayout()
    end,

    ConstructionClusterCallback = function(self, key)
        LOG('background.lua/ConstructionPanel:ConstructionClusterCallback(\''..key..'\')')
        self:MorphLayout(key)
    end,

    TechClusterCallback = function(self, key)
        LOG('background.lua/ConstructionPanel:TechTabClusterCallback(\''..key..'\')')
    end,

    EnhancementClusterCallback = function(self, key)
        LOG('background.lua/ConstructionPanel:EnhancementTabClusterCallback(\''..key..'\')')
    end,

    ---Morph us into a layout that shows the tech tab, or not, along with the enhancement panel tabs
    ---@param self ConstructionPanel
    ---@param key string
    MorphLayout = function(self, key)
        --LOG('background.lua/ConstructionPanel:MorphLayout(\''..key..'\')')
        self.lastKey = key
        if key == 'construction' or key == 'enhancement' then

            -- Show our tech tab elements and get our width for the tech tab body
            local techTabBgRight
            self.bgTechTabBody:Show()
            self.bgTechTabCapR:Show()
            if key == 'construction' then
                self.techTabCluster:Show()
                self.enhancementTabCluster:Hide()
                --techTabBgRight = self.techTabCluster.Right
                self.bgTechTabBody.Right:Set(self.techTabCluster.Right)
            else
                self.techTabCluster:Hide()
                self.enhancementTabCluster:Show()
                --techTabBgRight = self.enhancementTabCluster.Right
                self.bgTechTabBody.Right:Set(self.enhancementTabCluster.Right)
            end

            -- Change our left cap texture to the tall tech tab version
            Layouter(self.bgMainCapL)
                :Texture(textures.bgMainCapL_TechTab)
                -- We get taller/wider, so we need to update our size
                :DimensionsFromTexture(textures.bgMainCapL_TechTab)
                -- Textures align differently (ouch) so we also need to adjust our offset
                :AtBottomIn(self.bgMainCapR, -1)
                :AtLeftIn(self, 67)
            -- Set the width of the tech tab background bitmap
            --Layouter(self.bgTechTabBody)
            --    :Right(techTabBgRight)
            -- Anchor the left edge of our main background, to end of the cap, on the right of the tech tab
            Layouter(self.bgMainBody)
                :AnchorToRight(self.bgTechTabCapR)
            -- Reanchor the construction tab, because the textures don't align properly otherwise
            Layouter(self.constructionTabCluster)
                :AnchorToLeft(self.bgMainCapL, -7)

        elseif key == 'selection' then
            --LOG('background.lua/ConstructionPanel:TechTabLayout{ controlToAlignTo == nil')
            -- Change our left cap texture to the short version
            Layouter(self.bgMainCapL)
                :Texture(textures.bgMainCapL)
                -- We need to update our size, because we got shorter/narrower
                :DimensionsFromTexture(textures.bgMainCapL)
                :AtBottomIn(self.bgMainCapR)
                :AtLeftIn(self, 69)
            -- Anchor our main background to the left cap, bypassing the tech tab elements
            Layouter(self.bgMainBody)
                :AnchorToRight(self.bgMainCapL)
            Layouter(self.constructionTabCluster)
                :AnchorToLeft(self.bgMainCapL, -5)

            -- Hide our tech tab elements
            self.bgTechTabBody:Hide()
            self.bgTechTabCapR:Hide()
            self.techTabCluster:Hide()
            self.enhancementTabCluster:Hide()
        end
    end,

    ---Handles the laying out of brackets on the sides of the construction panel
    ---@param self ConstructionPanel
    BracketLayout = function(self)
        -- Brackets on the right side
        Layouter(self.rightBracketLower)
            :Texture(textures.rightBracketLower)
            :AtRightIn(self.bgMainCapR, -21)
            :AtTopIn(self.bgMainCapR, -6)

        Layouter(self.rightBracketUpper)
            :Texture(textures.rightBracketUpper)
            :AtRightIn(self.bgMainCapR, -21)
            :AtBottomIn(self.bgMainCapR, -5)

        Layouter(self.rightBracketMiddle)
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
                self:MorphLayout(self.lastKey or 'selection')
            end
        end
    end,
}