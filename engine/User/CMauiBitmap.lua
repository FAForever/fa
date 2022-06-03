---@declare-global
---@class moho.bitmap_methods
local CMauiBitmap = {}

---
--  GetNumFrames()
function CMauiBitmap:GetNumFrames()
end

---
--  Bitmap:InternalSetSolidColor(color)
function CMauiBitmap:InternalSetSolidColor(color)
end

---
--  Loop(bool)
function CMauiBitmap:Loop(bool)
end

---
--  Play()
function CMauiBitmap:Play()
end

---
--  SetBackwardPattern()
function CMauiBitmap:SetBackwardPattern()
end

---
--  SetForwardPattern()
function CMauiBitmap:SetForwardPattern()
end

---
--  SetFrame(int)
function CMauiBitmap:SetFrame(int)
end

---
--  SetFramePattern(pattern)
function CMauiBitmap:SetFramePattern(pattern)
end

---
--  SetFrameRate(float)
function CMauiBitmap:SetFrameRate(float)
end

---
--  SetLoopPingPongPattern()
function CMauiBitmap:SetLoopPingPongPattern()
end

---
--  Bitmap:SetNewTexture(filename(s), border=1)
function CMauiBitmap:SetNewTexture(filenames)
end

---
--  SetPingPongPattern()
function CMauiBitmap:SetPingPongPattern()
end

---
--  SetTiled(bool)
function CMauiBitmap:SetTiled(bool)
end

---todo
---@param u0 number float
---@param v0  number float
---@param u1  number float
---@param v1  number float
function CMauiBitmap:SetUV(u0, v0, u1, v1)
end

---
--  ShareTextures(bitmap) - allows two bitmaps to use the same textures
function CMauiBitmap:ShareTextures(bitmap)
end

---
--  Stop()
function CMauiBitmap:Stop()
end

---
--  UseAlphaHitTest(bool)
function CMauiBitmap:UseAlphaHitTest(bool)
end

---
--  derived from CMauiControl
function CMauiBitmap:base()
end

return CMauiBitmap
