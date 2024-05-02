local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')

local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Layouter = LayoutHelpers.ReusedLayoutFor

ConstructionPanel = ClassUI(Group) {

    __init = function(self, parent)
        Group.__init(self, parent)

        LOG('Background Init')
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

        Layouter(self.bgLeftCap)
            :Texture(UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_l.dds'))
            :AtBottomIn(self, 4)
            :AtLeftIn(self, 67)
            :ResetRight()
            :ResetTop()
            :Dimensions(self.bgLeftCap.BitmapWidth(), self.bgLeftCap.BitmapHeight())

        Layouter(self.bgRightCap)
            :Texture(UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_r.dds'))
            :AtBottomIn(self.bgLeftCap, 1)
            :AtRightIn(self, 2)
            :ResetLeft()
            :ResetTop()

        Layouter(self.leftBracketLower)
            :Texture(UIUtil.UIFile('/game/bracket-left-energy/bracket_bmp_t.dds'))
            :AtLeftIn(self, 4)
            :AtTopIn(self, 21)

        Layouter(self.leftBracketUpper)
            :Texture(UIUtil.UIFile('/game/bracket-left-energy/bracket_bmp_b.dds'))
            :AtLeftIn(self.leftBracketLower)
            :AtBottomIn(self, 2)

        Layouter(self.leftBracketMiddle)
            :Texture(UIUtil.UIFile('/game/bracket-left-energy/bracket_bmp_m.dds'))
            :AtLeftIn(self.leftBracketLower)
            :Bottom(self.leftBracketUpper.Top)
            :Top(self.leftBracketLower.Bottom)

        Layouter(self.rightBracketLower)
            :Texture(UIUtil.UIFile('/game/bracket-right/bracket_bmp_t.dds'))
            :AtRightIn(self.bgRightCap, -21)
            :AtTopIn(self.bgRightCap, -6)

        Layouter(self.rightBracketUpper)
            :Texture(UIUtil.UIFile('/game/bracket-right/bracket_bmp_b.dds'))
            :AtRightIn(self.bgRightCap, -21)
            :AtBottomIn(self.bgRightCap, -5)

        Layouter(self.rightBracketMiddle)
            :Texture(UIUtil.UIFile('/game/bracket-right/bracket_bmp_m.dds'))
            :AtRightIn(self.bgRightCap, -14)
            :Bottom(self.rightBracketUpper.Top)
            :Top(self.rightBracketLower.Bottom)

        Layouter(self.bgTechTab)
            :Texture(UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_m1.dds'))
            :Left(self.bgLeftCap.Right)
            :Bottom(self.bgLeftCap.Bottom)
            :Dimensions(self.bgTechTab.BitmapWidth(), self.bgTechTab.BitmapHeight())
            :ResetTop()

        Layouter(self.bgTechTabCap)
            :Texture(UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_m2.dds'))
            :Left(self.bgTechTab.Right)
            :Bottom(self.bgLeftCap.Bottom)
            :Dimensions(self.bgTechTabCap.BitmapWidth(), self.bgTechTabCap.BitmapHeight())
            :ResetTop()

        Layouter(self.bgMain)
            :Texture(UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_m3.dds'))
            :Dimensions(self.bgMain.BitmapWidth(), self.bgMain.BitmapHeight())
            :Left(self.bgTechTabCap.Right)
            :Right(self.bgRightCap.Left)
            :Bottom(self.bgRightCap.Bottom)
            :Height(self.bgMain.BitmapHeight())
            :ResetWidth()
            :ResetTop()
    end,

    TechTabLayout = function(self, controlToAlignTo)
        if controlToAlignTo then
            LOG('controlToAlignTo present')
            Layouter(self.bgLeftCap) -- minBG
                :Texture(UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_l.dds'))
                :Dimensions(self.bgLeftCap.BitmapWidth(), self.bgLeftCap.BitmapHeight())
                :AtLeftBottomIn(self, 67, 4)
            Layouter(self.bgTechTab) -- BG1
                :Texture(UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_m1.dds'))
                :Dimensions(self.bgTechTab.BitmapWidth(), self.bgTechTab.BitmapHeight())
                :RightOf(self.bgLeftCap.Right)
                :Right(controlToAlignTo.Right)
            Layouter(self.bgTechTabCap) -- BG2
                :Texture(UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_m2.dds'))
                :Dimensions(self.bgTechTabCap.BitmapWidth(), self.bgTechTabCap.BitmapHeight())
                :RightOf(self.bgTechTab.Right)
            Layouter(self.bgMain) -- BG3
                :Left(self.bgTechTabCap.Right)
            --controls.midBG1:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_m1.dds'))
            --controls.midBG1.Right:Set(prevControl.Right)
            --controls.midBG2:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_m2.dds'))
            --controls.midBG3:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_m3.dds'))
            --controls.minBG:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_l.dds'))
            --LayoutHelpers.SetDimensions(controls.minBG, controls.minBG.BitmapWidth(), controls.minBG.BitmapHeight()) -- TODO: This is an ugly hack for the problem described above
            --LayoutHelpers.SetDimensions(controls.midBG1, controls.midBG1.BitmapWidth(), controls.midBG1.BitmapHeight()) -- TODO
            --LayoutHelpers.SetDimensions(controls.midBG2, controls.midBG2.BitmapWidth(), controls.midBG2.BitmapHeight()) -- TODO
            --LayoutHelpers.SetDimensions(controls.midBG3, controls.midBG3.BitmapWidth(), controls.midBG3.BitmapHeight()) -- TODO
            --LayoutHelpers.AtLeftIn(controls.minBG, controls.constructionGroup, 67)
            --LayoutHelpers.AtBottomIn(controls.maxBG, controls.minBG, 1)
            --LayoutHelpers.AtBottomIn(controls.minBG, controls.constructionGroup, 4)
        else
            LOG('controlToAlignTo present')
            Layouter(self.bgLeftCap)
                :Texture(UIUtil.UIFile('/game/construct-panel/construct-panel_s_bmp_l.dds'))
                :Dimensions(self.bgLeftCap.BitmapWidth(), self.bgLeftCap.BitmapHeight())
                :AtLeftBottomIn(self, 69, 5)
            Layouter(self.bgTechTab)
                :Texture(UIUtil.UIFile('/game/construct-panel/construct-panel_s_bmp_m.dds'))
                :Dimensions(self.bgTechTab.BitmapWidth(), self.bgTechTab.BitmapHeight())
                :RightOf(self.bgLeftCap.Right)
            Layouter(self.bgTechTabCap)
                :Texture(UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_m2.dds'))
                :Dimensions(self.bgTechTabCap.BitmapWidth(), self.bgTechTabCap.BitmapHeight())
                :RightOf(self.bgTechTab.Right)
            Layouter(self.bgMain)
                :Left(self.bgTechTabCap.Right)
            --controls.midBG1:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_s_bmp_m.dds'))
            --controls.midBG2:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_s_bmp_m.dds'))
            --controls.midBG3:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_s_bmp_m.dds'))
            --controls.minBG:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_s_bmp_l.dds'))
            --LayoutHelpers.SetDimensions(controls.minBG, controls.minBG.BitmapWidth(), controls.minBG.BitmapHeight()) -- TODO
            --LayoutHelpers.SetDimensions(controls.midBG1, controls.midBG1.BitmapWidth(), controls.midBG1.BitmapHeight()) -- TODO
            --LayoutHelpers.SetDimensions(controls.midBG2, controls.midBG2.BitmapWidth(), controls.midBG2.BitmapHeight()) -- TODO
            --LayoutHelpers.SetDimensions(controls.midBG3, controls.midBG3.BitmapWidth(), controls.midBG3.BitmapHeight()) -- TODO
            --LayoutHelpers.AtLeftIn(controls.minBG, controls.constructionGroup, 69)
            --LayoutHelpers.AtBottomIn(controls.maxBG, controls.minBG, 0)
            --LayoutHelpers.AtBottomIn(controls.minBG, controls.constructionGroup, 5)
        end
    end,
}