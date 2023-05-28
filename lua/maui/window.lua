----------------------------------------------------------------------------------------------------
----   Generic Window ClassUI
----------------------------------------------------------------------------------------------------


local UIUtil = import("/lua/ui/uiutil.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Text = import("/lua/maui/text.lua").Text
local Button = import("/lua/maui/button.lua").Button
local Dragger = import("/lua/maui/dragger.lua").Dragger
local Checkbox = import("/lua/maui/checkbox.lua").Checkbox
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Prefs = import("/lua/user/prefs.lua")

-- default style set
styles = {
    backgrounds = {
        notitle = {
            tl = UIUtil.SkinnableFile('/game/mini-map-brd01/mini-map_brd_ul.dds'),
            tr = UIUtil.SkinnableFile('/game/mini-map-brd01/mini-map_brd_ur.dds'),
            tm = UIUtil.SkinnableFile('/game/mini-map-brd01/mini-map_brd_horz_um.dds'),
            ml = UIUtil.SkinnableFile('/game/mini-map-brd01/mini-map_brd_vert_l.dds'),
            m = UIUtil.SkinnableFile('/game/mini-map-brd01/mini-map_brd_m.dds'),
            mr = UIUtil.SkinnableFile('/game/mini-map-brd01/mini-map_brd_vert_r.dds'),
            bl = UIUtil.SkinnableFile('/game/mini-map-brd01/mini-map_brd_ll.dds'),
            bm = UIUtil.SkinnableFile('/game/mini-map-brd01/mini-map_brd_lm.dds'),
            br = UIUtil.SkinnableFile('/game/mini-map-brd01/mini-map_brd_lr.dds'),
            borderColor = 'ff415055',
        },
        title = {
            tl = UIUtil.SkinnableFile('/game/options_brd/options_brd_ul.dds'),
            tr = UIUtil.SkinnableFile('/game/options_brd/options_brd_ur.dds'),
            tm = UIUtil.SkinnableFile('/game/options_brd/options_brd_horz_um.dds'),
            ml = UIUtil.SkinnableFile('/game/options_brd/options_brd_vert_l.dds'),
            m = UIUtil.SkinnableFile('/game/options_brd/options_brd_m.dds'),
            mr = UIUtil.SkinnableFile('/game/options_brd/options_brd_vert_r.dds'),
            bl = UIUtil.SkinnableFile('/game/options_brd/options_brd_ll.dds'),
            bm = UIUtil.SkinnableFile('/game/options_brd/options_brd_lm.dds'),
            br = UIUtil.SkinnableFile('/game/options_brd/options_brd_lr.dds'),
            borderColor = 'ff415055',
        },
    },
    closeButton = {
        up = UIUtil.SkinnableFile('/game/menu-btns/close_btn_up.dds'),
        down = UIUtil.SkinnableFile('/game/menu-btns/close_btn_down.dds'),
        over = UIUtil.SkinnableFile('/game/menu-btns/close_btn_over.dds'),
        dis = UIUtil.SkinnableFile('/game/menu-btns/close_btn_dis.dds'),
    },
    pinButton = {
        up = UIUtil.SkinnableFile('/game/menu-btns/pin_btn_up.dds'),
        upSel = UIUtil.SkinnableFile('/game/menu-btns/pinned_btn_up.dds'),
        over = UIUtil.SkinnableFile('/game/menu-btns/pin_btn_over.dds'),
        overSel = UIUtil.SkinnableFile('/game/menu-btns/pinned_btn_over.dds'),
        dis = UIUtil.SkinnableFile('/game/menu-btns/pin_btn_dis.dds'),
        disSel = UIUtil.SkinnableFile('/game/menu-btns/pinned_btn_dis.dds'),
    },
    configButton = {
        up = UIUtil.SkinnableFile('/game/menu-btns/config_btn_up.dds'),
        down = UIUtil.SkinnableFile('/game/menu-btns/config_btn_down.dds'),
        over = UIUtil.SkinnableFile('/game/menu-btns/config_btn_over.dds'),
        dis = UIUtil.SkinnableFile('/game/menu-btns/config_btn_dis.dds'),
    },
    title = {
        font = UIUtil.titleFont,
        color = UIUtil.fontColor,
        size = 14,
    },
    cursorFunc = UIUtil.GetCursor,
}

---@class Window : Group
Window = ClassUI(Group) {
    __init = function(self, parent, title, icon, pin, config, lockSize, lockPosition, prefID, defaultPosition, textureTable)
        Group.__init(self, parent, tostring(title) .. "-window")

        self:DisableHitTest()

        self._resizeGroup = Group(self, 'window resize group')
        LayoutHelpers.FillParent(self._resizeGroup, self)
        self._resizeGroup.Depth:Set(function() return self.Depth() + 100 end)
        self._resizeGroup:DisableHitTest()
        self._pref = prefID

        self._windowGroup = Group(self, 'window texture group')
        LayoutHelpers.FillParent(self._windowGroup, self)
        self._windowGroup:DisableHitTest()

        self.tl = Bitmap(self._resizeGroup)
        self.tr = Bitmap(self._resizeGroup)
        self.bl = Bitmap(self._resizeGroup)
        self.br = Bitmap(self._resizeGroup)
        self.tm = Bitmap(self._resizeGroup)
        self.bm = Bitmap(self._resizeGroup)
        self.ml = Bitmap(self._resizeGroup)
        self.mr = Bitmap(self._resizeGroup)

        self._borderSize = 5
        self._cornerSize = 8
        self._sizeLock = false
        self._lockPosition = lockPosition or false
        self._lockSize = lockSize or false
        self._xMin = 0
        self._yMin = 0

        --Set alpha of resize controls to 0 so that they still get resize events, but are not seen

        self.tl:SetAlpha(0)
        self.tr:SetAlpha(0)
        self.bl:SetAlpha(0)
        self.br:SetAlpha(0)
        self.tm:SetAlpha(0)
        self.bm:SetAlpha(0)
        self.ml:SetAlpha(0)
        self.mr:SetAlpha(0)

        self.tl.Height:Set(self._cornerSize)
        self.tl.Width:Set(self._cornerSize)
        self.tl.Top:Set(self.Top)
        self.tl.Left:Set(self.Left)

        self.tr.Height:Set(self._cornerSize)
        self.tr.Width:Set(self._cornerSize)
        self.tr.Top:Set(self.Top)
        self.tr.Right:Set(self.Right)

        self.bl.Height:Set(self._cornerSize)
        self.bl.Width:Set(self._cornerSize)
        self.bl.Bottom:Set(self.Bottom)
        self.bl.Left:Set(self.Left)

        self.br.Height:Set(self._cornerSize)
        self.br.Width:Set(self._cornerSize)
        self.br.Bottom:Set(self.Bottom)
        self.br.Right:Set(self.Right)

        self.tm.Height:Set(self._borderSize)
        self.tm.Left:Set(self.tl.Right)
        self.tm.Right:Set(self.tr.Left)
        self.tm.Top:Set(self.tl.Top)

        self.bm.Height:Set(self._borderSize)
        self.bm.Left:Set(self.bl.Right)
        self.bm.Right:Set(self.br.Left)
        self.bm.Top:Set(self.bl.Top)

        self.ml.Width:Set(self._borderSize)
        self.ml.Left:Set(self.tl.Left)
        self.ml.Top:Set(self.tl.Bottom)
        self.ml.Bottom:Set(self.bl.Top)

        self.mr.Width:Set(self._borderSize)
        self.mr.Right:Set(self.tr.Right)
        self.mr.Top:Set(self.tr.Bottom)
        self.mr.Bottom:Set(self.br.Top)

        local texturekey = 'notitle'
        if textureTable then
            texturekey = prefID
            styles.backgrounds[prefID] = textureTable
        elseif title then
            texturekey = 'title'
        end

        self.tl:SetSolidColor(styles.backgrounds[texturekey].borderColor)
        self.tr:SetSolidColor(styles.backgrounds[texturekey].borderColor)
        self.bl:SetSolidColor(styles.backgrounds[texturekey].borderColor)
        self.br:SetSolidColor(styles.backgrounds[texturekey].borderColor)
        self.tm:SetSolidColor(styles.backgrounds[texturekey].borderColor)
        self.bm:SetSolidColor(styles.backgrounds[texturekey].borderColor)
        self.ml:SetSolidColor(styles.backgrounds[texturekey].borderColor)
        self.mr:SetSolidColor(styles.backgrounds[texturekey].borderColor)

        self.window_tl = Bitmap(self._windowGroup, styles.backgrounds[texturekey].tl)
        self.window_tr = Bitmap(self._windowGroup, styles.backgrounds[texturekey].tr)
        self.window_tm = Bitmap(self._windowGroup, styles.backgrounds[texturekey].tm)
        self.window_ml = Bitmap(self._windowGroup, styles.backgrounds[texturekey].ml)
        self.window_m = Bitmap(self._windowGroup, styles.backgrounds[texturekey].m)
        self.window_mr = Bitmap(self._windowGroup, styles.backgrounds[texturekey].mr)
        self.window_bl = Bitmap(self._windowGroup, styles.backgrounds[texturekey].bl)
        self.window_bm = Bitmap(self._windowGroup, styles.backgrounds[texturekey].bm)
        self.window_br = Bitmap(self._windowGroup, styles.backgrounds[texturekey].br)

        self.window_tl.Top:Set(self.Top)
        self.window_tl.Left:Set(self.Left)

        self.window_tr.Top:Set(self.Top)
        self.window_tr.Right:Set(self.Right)

        self.window_bl.Bottom:Set(self.Bottom)
        self.window_bl.Left:Set(self.Left)

        self.window_br.Bottom:Set(self.Bottom)
        self.window_br.Right:Set(self.Right)

        self.window_tm.Left:Set(self.window_tl.Right)
        self.window_tm.Right:Set(self.window_tr.Left)
        self.window_tm.Top:Set(self.window_tl.Top)

        self.window_bm.Left:Set(self.window_bl.Right)
        self.window_bm.Right:Set(self.window_br.Left)
        self.window_bm.Top:Set(self.window_bl.Top)

        self.window_ml.Left:Set(self.window_tl.Left)
        self.window_ml.Top:Set(self.window_tl.Bottom)
        self.window_ml.Bottom:Set(self.window_bl.Top)

        self.window_mr.Right:Set(self.window_tr.Right)
        self.window_mr.Top:Set(self.window_tr.Bottom)
        self.window_mr.Bottom:Set(self.window_br.Top)

        self.window_m.Top:Set(self.window_tm.Bottom)
        self.window_m.Left:Set(self.window_ml.Right)
        self.window_m.Right:Set(self.window_mr.Left)
        self.window_m.Bottom:Set(self.window_bm.Top)

        self.TitleGroup = Group(self, 'window title group')
        self.TitleGroup.Top:Set(self.tm.Top)
        self.TitleGroup.Left:Set(self.tl.Left)
        self.TitleGroup.Right:Set(self.tr.Right)
        self.TitleGroup.Height:Set(30)
        self.TitleGroup.Depth:Set(function() return self._windowGroup.Depth() + 2 end)

        if icon then
            self._titleIcon = Bitmap(self.TitleGroup, icon)
            LayoutHelpers.AtLeftTopIn(self._titleIcon, self.TitleGroup, 2, 2)
        end

        self._title = Text(self.TitleGroup)
        if title then
            self._title:SetFont(styles.title.font, styles.title.size)
            self._title:SetColor(styles.title.color)
            self._title:SetText(LOC(title))
        end
        if icon then
            self._title.Left:Set(function() return self._titleIcon.Right() + 5 end)
            LayoutHelpers.AtVerticalCenterIn(self._title, self._titleIcon)
        else
            LayoutHelpers.AtLeftTopIn(self._title, self.TitleGroup, 20, 7)
        end

        self._closeBtn = Button(self.TitleGroup,
            styles.closeButton.up,
            styles.closeButton.down,
            styles.closeButton.over,
            styles.closeButton.dis)
        LayoutHelpers.AtRightTopIn(self._closeBtn, self.TitleGroup, 10, 5)
        self._closeBtn.OnClick = function(control)
            self:OnClose(control)
        end

        if pin then
            self._pinBtn = Checkbox(self.TitleGroup,
                styles.pinButton.up,
                styles.pinButton.upSel,
                styles.pinButton.over,
                styles.pinButton.overSel,
                styles.pinButton.dis,
                styles.pinButton.disSel)
            LayoutHelpers.LeftOf(self._pinBtn, self._closeBtn)
            self._pinBtn.OnCheck = function(control, checked)
                self:OnPinCheck(checked)
            end
        end

        if config then
            self._configBtn = Button(self.TitleGroup,
                styles.configButton.up,
                styles.configButton.down,
                styles.configButton.over,
                styles.configButton.dis)
            if pin then
                LayoutHelpers.LeftOf(self._configBtn, self._pinBtn)
            else
                LayoutHelpers.LeftOf(self._configBtn, self._closeBtn)
            end
            self._configBtn.OnClick = function(control)
                self:OnConfigClick()
            end
        end

        self.ClientGroup = Group(self, 'window client group')
        LayoutHelpers.Layouter(self.ClientGroup)
            :Top(self.TitleGroup.Bottom)
            :Left(self.ml.Right)
            :Height(function() return self.bm.Top() - self.TitleGroup.Bottom() end)
            :Width(function() return self.mr.Left() - self.ml.Right() end)
            :Right(self.mr.Left)
            :Bottom(self.bm.Top)
            :Over(self.window_m)

        self.StartSizing = function(event, xControl, yControl)
            local drag = Dragger()
            local x_max = true
            local y_max = true
            if event.MouseX < self.tl.Right() then
                x_max = false
            end
            if event.MouseY < self.tl.Bottom() then
                y_max = false
            end
            drag.OnMove = function(dragself, x, y)
                if xControl then
                    local newX
                    if x_max then
                        newX = math.min(math.max(x, self.Left() + self._xMin), parent.Right())
                        newX = math.max(newX, self.Left() + self._title.Width() + self._closeBtn.Width() + (2*self.window_tl.Width()))
                    else
                        newX = math.min(math.max(x, 0), self.Right() - self._xMin)
                    end
                    xControl:Set(newX)
                end
                if yControl then
                    local newY
                    if y_max then
                        newY = math.min(math.max(y, self.Top() + self._yMin), parent.Bottom())
                        newY = math.max(newY, self.Top() + self.window_bm.Height() + self.window_tm.Height())
                    else
                        newY = math.min(math.max(y, 0), self.Bottom() - self._yMin)
                    end
                    yControl:Set(newY)
                end
                self:OnResize(x, y, not self._sizeLock)
                if not self._sizeLock then
                    self._sizeLock = true
                end
            end
            drag.OnRelease = function(dragself)
                self._sizeLock = false
                self._resizeGroup:SetAlpha(0, true)
                GetCursor():Reset()
                drag:Destroy()
                self:SaveWindowLocation()
                self:OnResizeSet()
            end
            drag.OnCancel = function(dragself)
                self._sizeLock = false
                GetCursor():Reset()
                drag:Destroy()
            end
            PostDragger(self:GetRootFrame(), event.KeyCode, drag)
        end

        self.RolloverHandler = function(control, event, xControl, yControl, cursor, controlID)
            if self._lockSize then return end
            if not self._sizeLock then
                if event.Type == 'MouseEnter' then
                    self._resizeGroup:SetAlpha(1, true)
                    GetCursor():SetTexture(styles.cursorFunc(cursor))
                elseif event.Type == 'MouseExit' then
                    self._resizeGroup:SetAlpha(0, true)
                    GetCursor():Reset()
                elseif event.Type == 'ButtonPress' then
                    self.StartSizing(event, xControl, yControl)
                end
            end
        end

        self.br.HandleEvent = function(control, event)
            self.RolloverHandler(control, event, self.Right, self.Bottom, 'NW_SE', 'br')
        end
        self.bl.HandleEvent = function(control, event)
            self.RolloverHandler(control, event, self.Left, self.Bottom, 'NE_SW', 'bl')
        end
        self.bm.HandleEvent = function(control, event)
            self.RolloverHandler(control, event, nil, self.Bottom, 'N_S', 'bm')
        end
        self.tr.HandleEvent = function(control, event)
            self.RolloverHandler(control, event, self.Right, self.Top, 'NE_SW', 'tr')
        end
        self.tl.HandleEvent = function(control, event)
            self.RolloverHandler(control, event, self.Left, self.Top, 'NW_SE', 'tl')
        end
        self.tm.HandleEvent = function(control, event)
            self.RolloverHandler(control, event, nil, self.Top, 'N_S', 'tm')
        end
        self.mr.HandleEvent = function(control, event)
            self.RolloverHandler(control, event, self.Right, nil, 'W_E', 'mr')
        end
        self.ml.HandleEvent = function(control, event)
            self.RolloverHandler(control, event, self.Left, nil, 'W_E', 'ml')
        end

        self.TitleGroup.HandleEvent = function(control, event)
            if not self._sizeLock then
                if event.Type == 'ButtonPress' then
                    if self._lockPosition then return end
                    local drag = Dragger()
                    local offX = event.MouseX - self.Left()
                    local offY = event.MouseY - self.Top()
                    local height = self.Height()
                    local width = self.Width()
                    drag.OnMove = function(dragself, x, y)
                        self.Left:Set(math.min(math.max(x-offX, parent.Left()), parent.Right() - self.Width()))
                        self.Top:Set(math.min(math.max(y-offY, parent.Top()), parent.Bottom() - self.Height()))
                        local tempRight = self.Left() + width
                        local tempBottom = self.Top() + height
                        self.Right:Set(tempRight)
                        self.Bottom:Set(tempBottom)
                        self:OnMove(x, y, not self._sizeLock)
                        if not self._sizeLock then
                            GetCursor():SetTexture(styles.cursorFunc('MOVE_WINDOW'))
                            self._sizeLock = true
                        end
                    end
                    drag.OnRelease = function(dragself)
                        self._sizeLock = false
                        GetCursor():Reset()
                        drag:Destroy()
                        self:SaveWindowLocation()
                        self:OnMoveSet()
                    end
                    drag.OnCancel = function(dragself)
                        self._sizeLock = false
                        GetCursor():Reset()
                        drag:Destroy()
                    end
                    PostDragger(self:GetRootFrame(), event.KeyCode, drag)
                end
            end
        end

        self.HandleEvent = function(control, event)
            if event.Type == 'WheelRotation' then
                self:OnMouseWheel(event.WheelRotation)
            end
        end
        self.OnHide = function(control, hidden)
            control._resizeGroup:SetHidden(hidden)
            control:OnHideWindow(control, hidden)
        end

        local OldHeightOnDirty = parent.Height.OnDirty
        local OldWidthOnDirty = parent.Width.OnDirty
        parent.Height.OnDirty = function(var)
            if self.Bottom() > parent.Bottom() then
                local Height = math.min(self.Height(), parent.Height())
                self.Bottom:Set(parent.Bottom())
                self.Top:Set(self.Bottom() - Height)
            end
            if OldHeightOnDirty then
                OldHeightOnDirty(var)
            end
            self:SaveWindowLocation()
        end
        parent.Width.OnDirty = function(var)
            if self.Right() > parent.Right() then
                local Width = math.min(self.Width(), parent.Width())
                self.Right:Set(parent.Right())
                self.Left:Set(self.Right() - Width)
            end
            if OldWidthOnDirty then
                OldWidthOnDirty(var)
            end
            self:SaveWindowLocation()
        end

        -- attempt to retrieve location of window in preference file
        local location = Prefs.GetFromCurrentProfile(prefID)
        if location then

            -- old version in preference file that doesn't support UI scaling
            if not (location.width and location.height) then 
                local oldHeight = location.bottom - location.top
                local oldWidth = location.right - location.left
                self.Top:Set(math.max(location.top, parent.Top()))
                self.Left:Set(math.max(location.left, parent.Left()))
                self.Right:Set(math.min(location.right, parent.Right()))
                self.Bottom:Set(math.min(location.bottom, parent.Bottom()))
                if self.Bottom() - self.Top() ~= oldHeight then
                    self.Top:Set(math.max(math.min(location.bottom, parent.Bottom()) - oldHeight), parent.Top())
                end
                if self.Right() - self.Left() ~= oldWidth then
                    self.Left:Set(math.max(math.min(location.right, parent.Right()) - oldWidth), parent.Left())
                end
            -- new version in preference file that does support UI scaling
            else 
                local top = location.top 
                local left = location.left 
                local width = location.width 
                local height = location.height 

                self.Left:Set(left)
                self.Top:Set(top)

                -- we can scale these accordingly as we applied the inverse on saving
                self.Right:Set(LayoutHelpers.ScaleNumber(width) + left)
                self.Bottom:Set(LayoutHelpers.ScaleNumber(height) + top)
            end
        elseif defaultPosition then
            -- Scale only if it's a number, else it's already scaled lazyvar
            if type(defaultPosition.Left) == 'number' then
                self.Left:Set(LayoutHelpers.ScaleNumber(defaultPosition.Left))
                self.Top:Set(LayoutHelpers.ScaleNumber(defaultPosition.Top))
                self.Bottom:Set(LayoutHelpers.ScaleNumber(defaultPosition.Bottom))
                self.Right:Set(LayoutHelpers.ScaleNumber(defaultPosition.Right))
            else
                self.Left:Set(defaultPosition.Left)
                self.Top:Set(defaultPosition.Top)
                self.Bottom:Set(defaultPosition.Bottom)
                self.Right:Set(defaultPosition.Right)
            end
        end
    end,

    ---@param self Window
    ---@param alpha number
    ---@param affectChildren boolean
    SetAlpha = function(self, alpha, affectChildren)
        affectChildren = affectChildren or false
        Group.SetAlpha(self, alpha, affectChildren)

        -- guarantee that the resize bars remain transparent
        self._resizeGroup:SetAlpha(0, true)
    end,

    SaveWindowLocation = function(self)
        if self._pref then
            Prefs.SetToCurrentProfile(
                self._pref, 
                {
                    top = self.Top(), 
                    left = self.Left(), 

                    -- backwards compatibility with the FAF branch
                    right = self.Right(),
                    bottom = self.Bottom(),

                    -- invert the scale on these numbers, that allows us to apply the scale again when we read it from the preference file
                    width = LayoutHelpers.InvScaleNumber(self.Width()), 
                    height = LayoutHelpers.InvScaleNumber(self.Height())
                }
            )
        end
    end,

    ApplyWindowTextures = function(self, textures)
        self.window_tl:SetTexture(textures.tl)
        self.window_tr:SetTexture(textures.tr)
        self.window_tm:SetTexture(textures.tm)
        self.window_ml:SetTexture(textures.ml)
        self.window_m:SetTexture(textures.m)
        self.window_mr:SetTexture(textures.mr)
        self.window_bl:SetTexture(textures.bl)
        self.window_bm:SetTexture(textures.bm)
        self.window_br:SetTexture(textures.br)
    end,

    GetClientGroup = function(self)
        return self.ClientGroup
    end,

    SetSizeLock = function(self, locked)
        self._lockSize = locked
    end,

    SetPositionLock = function(self, locked)
        self._lockPosition = locked
    end,

    SetMinimumResize = function(self, xDimension, yDimension)
        self._xMin = LayoutHelpers.ScaleNumber(xDimension) or 0
        self._yMin = LayoutHelpers.ScaleNumber(yDimension) or 0
    end,

    SetWindowAlpha = function(self, alpha)
        self._windowGroup:SetAlpha(alpha, true)
    end,

    SetTitle = function(self, text)
        self._title:SetText(LOC(text))
    end,

    IsPinned = function(self)
        if self._pinBtn then
            return self._pinBtn:IsChecked()
        else
            return false
        end
    end,

    OnDestroy = function(self)
        self._resizeGroup:Destroy()
    end,

    -- The following are functions that can be overloaded
    OnResize = function(self, x, y, firstFrame) end,
    OnResizeSet = function(self) end,

    OnMove = function(self, x, y, firstFrame) end,
    OnMoveSet = function(self) end,

    OnPinCheck = function(self, checked) end,
    OnConfigClick = function(self) end,

    OnMouseWheel = function(self, rotation) end,

    OnClose = function(self) end,
    OnHideWindow = function(self, hidden) end,
}