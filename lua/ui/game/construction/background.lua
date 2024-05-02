local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')

local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Layouter = LayoutHelpers.ReusedLayoutFor

-- Putting these here for now, need to be moved to somewhere where
-- they can be dynamically updated when the skin changes
local txrs = {
    bgLeftCapTech = UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_l.dds'),
    bgLeftCap = UIUtil.UIFile('/game/construct-panel/construct-panel_s_bmp_l.dds'),
    bgRightCap = UIUtil.UIFile('/game/construct-panel/construct-panel_s_bmp_r.dds'),
    bgTechTab = UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_m1.dds'),
    bgTechTabCap = UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_m2.dds'),
    bgMain = UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_m3.dds'),

    leftBracketLower = UIUtil.UIFile('/game/bracket-left-energy/bracket_bmp_t.dds'),
    leftBracketUpper = UIUtil.UIFile('/game/bracket-left-energy/bracket_bmp_b.dds'),
    leftBracketMiddle = UIUtil.UIFile('/game/bracket-left-energy/bracket_bmp_m.dds'),
    rightBracketLower = UIUtil.UIFile('/game/bracket-right/bracket_bmp_t.dds'),
    rightBracketUpper = UIUtil.UIFile('/game/bracket-right/bracket_bmp_b.dds'),
    rightBracketMiddle = UIUtil.UIFile('/game/bracket-right/bracket_bmp_m.dds'),
}

---@class ConstructionPanel: Group
---@field bgLeftCap Bitmap
---@field bgRightCap Bitmap
---@field bgTechTab Bitmap
---@field bgTechTabCap Bitmap
---@field bgMain Bitmap
---@field leftBracketLower Bitmap
---@field leftBracketUpper Bitmap
---@field leftBracketMiddle Bitmap
---@field rightBracketLower Bitmap
---@field rightBracketUpper Bitmap
---@field rightBracketMiddle Bitmap
ConstructionPanel = ClassUI(Group) {

    __init = function(self, parent)
        Group.__init(self, parent)

        self.bgLeftCap = Bitmap(self)
        self.bgRightCap = Bitmap(self)
        self.bgTechTab = Bitmap(self)
        self.bgTechTabCap = Bitmap(self)
        self.bgMain = Bitmap(self)

        self.leftBracketLower = Bitmap(self)
        self.leftBracketUpper = Bitmap(self)
        self.leftBracketMiddle = Bitmap(self)

        self.rightBracketLower = Bitmap(self)
        self.rightBracketUpper = Bitmap(self)
        self.rightBracketMiddle = Bitmap(self)

    end,

    Layout = function(self)

        LOG('background.lua/ConstructionPanel:Layout')
        Layouter(self.bgLeftCap)
            :Texture(txrs.bgLeftCapTech)
            :AtLeftBottomIn(self, 67, 4)

        Layouter(self.bgRightCap)
            :Texture(txrs.bgRightCap)
            :AtBottomIn(self.bgLeftCap)
            :AtRightIn(self, 2)

        Layouter(self.bgTechTab)
            :Texture(txrs.bgTechTab)
            :AnchorToRight(self.bgLeftCap)
            :FillVertically(self.bgLeftCap)

        Layouter(self.bgTechTabCap)
            :Texture(txrs.bgTechTabCap)
            :DimensionsFromTexture(txrs.bgTechTabCap)
            :RightOf(self.bgTechTab)

        Layouter(self.bgMain)
            :Texture(txrs.bgMain)
            :AnchorToRight(self.bgTechTabCap)
            :AnchorToLeft(self.bgRightCap)
            :FillVertically(self.bgRightCap)

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
                techTabAlignTestValue = self.bgLeftCap.Right() + width
            end

            -- Change our left cap texture to the tall tech tab version
            Layouter(self.bgLeftCap)
                :Texture(txrs.bgLeftCapTech)
                -- We get taller/wider, so we need to update our size
                :DimensionsFromTexture(txrs.bgLeftCapTech)
            -- Set the width of the tech tab background bitmap
            Layouter(self.bgTechTab)
                :Right(techTabAlignTestValue)
            -- Anchor the left edge of our main background, to end of the cap, on the right of the tech tab
            Layouter(self.bgMain)
                :AnchorToRight(self.bgTechTabCap)

            -- Show our tech tab elements
            self.bgTechTab:Show()
            self.bgTechTabCap:Show()
        else
            LOG('background.lua/ConstructionPanel:TechTabLayout{ controlToAlignTo == nil')
            -- Change our left cap texture to the short version
            Layouter(self.bgLeftCap)
                :Texture(txrs.bgLeftCap)
                -- We need to update our size, because we got shorter/narrower
                :DimensionsFromTexture(txrs.bgLeftCap)
            -- Anchor our main background to the left cap, bypassing the tech tab elements
            Layouter(self.bgMain)
                :AnchorToRight(self.bgLeftCap)
            
            -- Hide our tech tab elements
            self.bgTechTab:Hide()
            self.bgTechTabCap:Hide()
        end
    end,

    ---Handles the laying out of brackets
    BracketLayout = function(self)
        -- The left brackets are positioned with respect to the build/select/cargo tab buttons, which
        -- aren't included here (yet). If they end up elsewhere, it's probably appropriate to create these
        -- tabs there instead of here.
        Layouter(self.leftBracketLower)
            :Texture(txrs.leftBracketLower)
            :AtLeftIn(self, 4)
            :AtTopIn(self, 21)

        Layouter(self.leftBracketUpper)
            :Texture(txrs.leftBracketUpper)
            :AtLeftIn(self.leftBracketLower)
            :AtBottomIn(self, 2)

        Layouter(self.leftBracketMiddle)
            :Texture(txrs.leftBracketMiddle)
            :AtLeftIn(self.leftBracketLower)
            :Bottom(self.leftBracketUpper.Top)
            :Top(self.leftBracketLower.Bottom)

        -- 
        Layouter(self.rightBracketLower)
            :Texture(txrs.rightBracketLower)
            :AtRightIn(self.bgRightCap, -21)
            :AtTopIn(self.bgRightCap, -6)

        Layouter(self.rightBracketUpper)
            :Texture(txrs.rightBracketUpper)
            :AtRightIn(self.bgRightCap, -21)
            :AtBottomIn(self.bgRightCap, -5)

        Layouter(self.rightBracketMiddle)
            :Texture(txrs.rightBracketMiddle)
            :AtRightIn(self.bgRightCap, -14)
            :Bottom(self.rightBracketUpper.Top)
            :Top(self.rightBracketLower.Bottom)
    end,
}