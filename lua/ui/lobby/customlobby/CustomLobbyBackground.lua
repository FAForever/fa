--******************************************************************************************************
--** Copyright (c) 2026 FAForever
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

-- The lobby's full-window background surface: a single Bitmap that paints the selected background
-- image (CustomLobbyBackgrounds) so it **covers** the whole parent while keeping the texture's
-- aspect ratio — scaled to the larger of the two axis ratios, centred, with the overflow cropped by
-- the screen edge. Falls back to a solid backdrop when no image is selected or the file can't be
-- read.
--
-- It subscribes to the reactive selection itself (the controller never touches it — it's a local
-- cosmetic choice) and re-covers automatically when the window resizes, because Width/Height are
-- bound as functions of the parent rect.

local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Backgrounds = import("/lua/ui/lobby/customlobby/customlobbybackgrounds.lua")

local LazyVarCreate = import("/lua/lazyvar.lua").Create
local LazyVarDerive = import("/lua/lazyvar.lua").Derive

local Layouter = LayoutHelpers.ReusedLayoutFor

--- The backdrop shown when no image is selected, or a selected file can't be read.
local FallbackColor = 'ff0a0a0a'

---@class UICustomLobbyBackground : Bitmap
---@field Trash TrashBag
---@field AspectLazy LazyVar           # { Width, Height } of the current texture in pixels (0 when none)
---@field SelectedObserver LazyVar
local CustomLobbyBackground = ClassUI(Bitmap) {

    ---@param self UICustomLobbyBackground
    ---@param parent Control
    __init = function(self, parent)
        Bitmap.__init(self, parent)
        self:DisableHitTest()
        self:SetSolidColor(FallbackColor)

        self.Trash = TrashBag()
        -- texture pixel size drives the cover math; 0 means "no texture -> solid fallback"
        self.AspectLazy = self.Trash:Add(LazyVarCreate({ Width = 0, Height = 0 }))

        -- react to the per-peer background choice (fires once on creation, then on each change)
        self.SelectedObserver = self.Trash:Add(
            LazyVarDerive(Backgrounds.GetSelectedLazy(), function(pathLazy)
                self:SetBackground(pathLazy())
            end))
    end,

    ---@param self UICustomLobbyBackground
    ---@param parent Control
    __post_init = function(self, parent)
        -- Cover the parent while keeping the texture's aspect ratio: scale to the LARGER of the two
        -- axis ratios so the image fills the window and overflows (is cropped) on the other axis,
        -- then centre it. Raw pixels throughout — we fill the physical frame, so no ui_scale here.
        -- Both edges are bound as functions of the parent rect, so a window resize re-covers for
        -- free.
        self.Width:Set(function()
            local aspect = self.AspectLazy()
            local parentWidth, parentHeight = parent.Width(), parent.Height()
            if aspect.Width <= 0 or aspect.Height <= 0 then
                return parentWidth
            end
            local scale = math.max(parentWidth / aspect.Width, parentHeight / aspect.Height)
            return aspect.Width * scale
        end)
        self.Height:Set(function()
            local aspect = self.AspectLazy()
            local parentWidth, parentHeight = parent.Width(), parent.Height()
            if aspect.Width <= 0 or aspect.Height <= 0 then
                return parentHeight
            end
            local scale = math.max(parentWidth / aspect.Width, parentHeight / aspect.Height)
            return aspect.Height * scale
        end)
        -- AtCenterIn only sets Left/Top (reading the Width/Height bound above) — no conflict.
        Layouter(self):AtCenterIn(parent):End()
    end,

    --- Paints `path` as a cover-fit background. Falls back to the solid backdrop when `path` is
    --- false or the file can't be read (a stale prefs entry pointing at a deleted image).
    ---@param self UICustomLobbyBackground
    ---@param path FileName | false
    SetBackground = function(self, path)
        if path then
            local width, height = GetTextureDimensions(path)
            if width and height and width > 0 and height > 0 then
                self:SetTexture(path)
                self.AspectLazy:Set({ Width = width, Height = height })
                return
            end
            WARN("CustomLobby: background image could not be read: " .. tostring(path))
        end
        self:SetSolidColor(FallbackColor)
        self.AspectLazy:Set({ Width = 0, Height = 0 })
    end,

    ---@param self UICustomLobbyBackground
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

---@param parent Control
---@return UICustomLobbyBackground
Create = function(parent)
    return CustomLobbyBackground(parent)
end
