---@meta

---@class moho.bitmap_methods : moho.control_methods
---@field BitmapWidth LazyVar<number>
---@field BitmapHeight LazyVar<number>
local CMauiBitmap = {}

---
function CMauiBitmap:GetNumFrames()
end

---
function CMauiBitmap:GetFrame()
end

---
---@param color string
function CMauiBitmap:InternalSetSolidColor(color)
end

---
---@param loop boolean
function CMauiBitmap:Loop(loop)
end

---
function CMauiBitmap:Play()
end

---
function CMauiBitmap:SetBackwardPattern()
end

---
function CMauiBitmap:SetForwardPattern()
end

---
---@param frame number
function CMauiBitmap:SetFrame(frame)
end

---
---@param pattern number[] an array of integers reflecting texture indicies
function CMauiBitmap:SetFramePattern(pattern)
end

---
---@param frameRate number
function CMauiBitmap:SetFrameRate(frameRate)
end

---
function CMauiBitmap:SetLoopPingPongPattern()
end

---
---@param filename string | string[]
---@param border? number defaults to `1`
function CMauiBitmap:SetNewTexture(filename, border)
end

---
function CMauiBitmap:SetPingPongPattern()
end

---
---@param tiled boolean
function CMauiBitmap:SetTiled(tiled)
end

---
---@param u0 number
---@param v0 number
---@param u1 number
---@param v1 number
function CMauiBitmap:SetUV(u0, v0, u1, v1)
end

--- Allows two bitmaps to use the same textures
---@param bitmap Bitmap
function CMauiBitmap:ShareTextures(bitmap)
end

---
function CMauiBitmap:Stop()
end

---
---@param doHit boolean
function CMauiBitmap:UseAlphaHitTest(doHit)
end

--- Defines the color mask to be applied to bitmap during rendering (white images will get this color for example).
--- Introduced by [binary patch #42](https://github.com/FAForever/FA-Binary-Patches/pull/42)
---@param color string
function CMauiBitmap:SetColorMask(color)
end

--- Called by the engine when an animation reaches the end of its frame pattern, whether or not
--- it loops.
---@type nil | fun(self: Bitmap)
CMauiBitmap.OnAnimationFinished = nil

--- Called by the engine on every frame change of an animation, with the 0-based position in the
--- frame pattern.
---@type nil | fun(self: Bitmap, frameNumber: number)
CMauiBitmap.OnAnimationFrame = nil

--- Called by the engine when an animation with more than one frame is stopped with `Stop`.
---@type nil | fun(self: Bitmap)
CMauiBitmap.OnAnimationStopped = nil

return CMauiBitmap
