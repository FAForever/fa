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

local Textures = {
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
ConstructionPanel = ClassUI(Group) {

    __init = function(self, parent)
        Group.__init(self, parent)

        self.bgMainCapL = Bitmap(self)
        self.bgMainCapR = Bitmap(self)
        self.bgTechTabBody = Bitmap(self)
        self.bgTechTabCapR = Bitmap(self)
        self.bgMainBody = Bitmap(self)

        self.leftBracketLower = Bitmap(self)
        self.leftBracketUpper = Bitmap(self)
        self.leftBracketMiddle = Bitmap(self)

        self.rightBracketLower = Bitmap(self)
        self.rightBracketUpper = Bitmap(self)
        self.rightBracketMiddle = Bitmap(self)

        --ALERT: test field for toggling displays
        self.flipFlop = false

    end,

    Layout = function(self)

        LOG('background.lua/ConstructionPanel:Layout')
        
        -- Left cap bitmap, under the pause/repeat build buttons
        Layouter(self.bgMainCapL)
            :Texture(Textures.bgMainCapL)
            :AtLeftBottomIn(self, 67, 4)

        -- Right cap bitmap, at the rightmost edge of the panel
        Layouter(self.bgMainCapR)
            :Texture(Textures.bgMainCapR)
            :AtBottomIn(self.bgMainCapL)
            :AtRightIn(self, 2)

        -- Background element that pops up behind the tech level radio buttons
        Layouter(self.bgTechTabBody)
            :Texture(Textures.bgTechTabBody)
            :AnchorToRight(self.bgMainCapL)
            :FillVertically(self.bgMainCapL)

        -- Rightside cap for the tech tab background (bgMainCapL is the left cap)
        Layouter(self.bgTechTabCapR)
            :Texture(Textures.bgTechTabCapR)
            :RightOf(self.bgTechTabBody)

        -- Main body of our background
        Layouter(self.bgMainBody)
            :Texture(Textures.bgMainBody)
            :AnchorToRight(self.bgTechTabCapR)
            :AnchorToLeft(self.bgMainCapR)
            :FillVertically(self.bgMainCapR)

        -- With no arguments, this will apply the default tech tab layout (no tab visible)
        self:TechTabLayout()

        -- Brackets in a separate function to keep things organized
        self:BracketLayout()
    end,

    ---Morph us into a layout that shows the tech tab, or not
    ---@param self ConstructionPanel
    ---@param controlToAlignTo? Control
    ---@param width? number -- Hard parameter, just for testing
    TechTabLayout = function(self, controlToAlignTo, width)
        LOG('background.lua/ConstructionPanel:TechTabLayout')
        if controlToAlignTo or width then
            LOG('background.lua/ConstructionPanel:TechTabLayout{ controlToAlignTo|width != nil')

            -- This is just for testing, because we don't have a proper tech control to pass yet
            local techTabAlignTestValue
            if controlToAlignTo and controlToAlignTo.Right then
                techTabAlignTestValue = controlToAlignTo.Right
            else
                techTabAlignTestValue = self.bgMainCapL.Right() + width
            end

            -- Change our left cap texture to the tall tech tab version
            Layouter(self.bgMainCapL)
                :Texture(Textures.bgMainCapL_TechTab)
                -- We get taller/wider, so we need to update our size
                :DimensionsFromTexture(Textures.bgMainCapL_TechTab)
            -- Set the width of the tech tab background bitmap
            Layouter(self.bgTechTabBody)
                :Right(techTabAlignTestValue)
            -- Anchor the left edge of our main background, to end of the cap, on the right of the tech tab
            Layouter(self.bgMainBody)
                :AnchorToRight(self.bgTechTabCapR)

            -- Show our tech tab elements
            self.bgTechTabBody:Show()
            self.bgTechTabCapR:Show()
        else
            LOG('background.lua/ConstructionPanel:TechTabLayout{ controlToAlignTo == nil')
            -- Change our left cap texture to the short version
            Layouter(self.bgMainCapL)
                :Texture(Textures.bgMainCapL)
                -- We need to update our size, because we got shorter/narrower
                :DimensionsFromTexture(Textures.bgMainCapL)
            -- Anchor our main background to the left cap, bypassing the tech tab elements
            Layouter(self.bgMainBody)
                :AnchorToRight(self.bgMainCapL)
            
            -- Hide our tech tab elements
            self.bgTechTabBody:Hide()
            self.bgTechTabCapR:Hide()
        end
    end,

    ---Handles the laying out of brackets on the left and right side of the construction panel
    ---@param self ConstructionPanel
    BracketLayout = function(self)
        -- The left brackets are positioned with respect to the build/select/cargo tab buttons, which
        -- aren't handled here. If those tabs end up elsewhere, it's probably appropriate to handle these
        -- brackets there instead of here.
        Layouter(self.leftBracketLower)
            :Texture(Textures.leftBracketLower)
            :AtLeftTopIn(self, 4, 21)
            --:AtTopIn(self, 21)

        Layouter(self.leftBracketUpper)
            :Texture(Textures.leftBracketUpper)
            :AtLeftIn(self.leftBracketLower)
            :AtBottomIn(self, 2)

        Layouter(self.leftBracketMiddle)
            :Texture(Textures.leftBracketMiddle)
            :AtLeftIn(self.leftBracketLower)
            :Bottom(self.leftBracketUpper.Top)
            :Top(self.leftBracketLower.Bottom)

        -- Brackets on the right side. These are with respect to bgMainCapR, so they belong here.
        Layouter(self.rightBracketLower)
            :Texture(Textures.rightBracketLower)
            :AtRightIn(self.bgMainCapR, -21)
            :AtTopIn(self.bgMainCapR, -6)

        Layouter(self.rightBracketUpper)
            :Texture(Textures.rightBracketUpper)
            :AtRightIn(self.bgMainCapR, -21)
            :AtBottomIn(self.bgMainCapR, -5)

        Layouter(self.rightBracketMiddle)
            :Texture(Textures.rightBracketMiddle)
            :AtRightIn(self.bgMainCapR, -14)
            :Bottom(self.rightBracketUpper.Top)
            :Top(self.rightBracketLower.Bottom)
    end,

    ---Provisional function for hiding/showing the construction panel based on selection
    ---@param self ConstructionPanel
    ---@param noUnitsSelected boolean
    OnSelection = function(self, noUnitsSelected)
        if not noUnitsSelected then
            if self:IsHidden() then
                LOG('showing ConstructionPanel')
                self:Show()
                if not self.flipFlop then
                    self.flipFlop = true
                    self:TechTabLayout(nil, 500)
                else
                    self.flipFlop = false
                    self:TechTabLayout()
                end
            end
        else
            if not self:IsHidden() then
                self:Hide()
            end
        end
    end,
}