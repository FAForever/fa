-- Class methods:
-- SetTexture(filename(s), border=1)
-- SetSolidColor(color)
-- SetUV(float u0, float v0, float u1, float v1)
-- SetTiled(bool)
-- UseAlphaHitTest(bool)
-- Loop(bool)
-- Play()
-- Stop()
-- SetFrame(int)
-- int GetFrame()
-- int GetNumFrames()
-- SetFrameRate(float fps)
-- SetFramePattern(pattern)
    -- pattern is an array of integers reflecting texture indicies
-- SetForwardPattern()
-- SetBackwardPattern()
-- SetPingPongPattern()
-- SetLoopPingPongPattern()
-- ShareTextures(bitmap) -- allows two bitmaps to share the same textures

-- Frame patterns are arrays that indicate what texture to play at a particular frame index
-- Textures are indexed by the order you pass them in to SetTexture. Note that frames are
-- 0 based, not 1 based.

-- related global function (returns nil if file not found)
-- width, height GetTextureDimensions(filename)


local Control = import("/lua/maui/control.lua").Control
local ScaleNumber = import("/lua/maui/layouthelpers.lua").ScaleNumber

---@class BitmapTexture
---@field _texture LazyVar<FileName>
---@field _border number

---@class Bitmap : moho.bitmap_methods, Control, InternalObject
---@field _filename BitmapTexture
---@field _color LazyVar<Color>
Bitmap = ClassUI(moho.bitmap_methods, Control) {
    ---@param self Bitmap
    ---@param parent Control
    ---@param filename Lazy<FileName>
    ---@param debugname? string
    __init = function(self, parent, filename, debugname)
        InternalCreateBitmap(self, parent)
        if debugname then
            self:SetName(debugname)
        end

        local LazyVar = import("/lua/lazyvar.lua")
        self._filename = {_texture = LazyVar.Create(), _border = 1}
        self._color = LazyVar.Create()
        self._color.OnDirty = function(var)
            self:InternalSetSolidColor(self._color())
        end
        self._filename._texture.OnDirty = function(var)
            self:SetNewTexture(self._filename._texture(), self._filename._border)
        end

        if filename then
            self:SetTexture(filename)
        end
    end,

    ---@param self Bitmap
    ---@param texture Lazy<FileName>
    ---@param border? number defaults to 1
    SetTexture = function(self, texture, border)
        if self._filename then
            border = border or 1
            self._filename._border = border
            self._filename._texture:Set(texture)
        end
    end,

    ---@param self Bitmap
    ---@param color Lazy<Color>
    SetSolidColor = function(self, color)
        self._color:Set(color)
    end,

    ---@param self Bitmap
    ResetLayout = function(self)
        Control.ResetLayout(self)
        self.Width:SetFunction(function() return ScaleNumber(self.BitmapWidth()) end)
        self.Height:SetFunction(function() return ScaleNumber(self.BitmapHeight()) end)
    end,

    ---@param self Bitmap
    OnDestroy = function(self)
        if self._filename and self._filename._texture then
            self._filename._texture:Destroy()
        end
        self._filename = nil
        if self._color then
            self._color:Destroy()
        end
    end,

    -- callback scripts
    ---@param self Bitmap
    OnAnimationFinished = function(self) end,
    ---@param self Bitmap
    OnAnimationStopped = function(self) end,
    ---@param self Bitmap
    ---@param frameNumber number
    OnAnimationFrame = function(self, frameNumber) end,
}

