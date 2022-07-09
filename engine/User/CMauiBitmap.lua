---@declare-global
---@class moho.bitmap_methods : moho.control_methods
local CMauiBitmap = {}

---
function CMauiBitmap:GetNumFrames()
end

---
function CMauiBitmap:GetFrame()
end

---
function CMauiBitmap:InternalSetSolidColor(color)
end

---
function CMauiBitmap:Loop(bool)
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
function CMauiBitmap:SetFrame(int)
end

---
function CMauiBitmap:SetFramePattern(pattern)
end

---
function CMauiBitmap:SetFrameRate(float)
end

---
function CMauiBitmap:SetLoopPingPongPattern()
end

---
function CMauiBitmap:SetNewTexture(filename(s), border=1)
end

---
function CMauiBitmap:SetPingPongPattern()
end

---
function CMauiBitmap:SetTiled(bool)
end

--- TODO
---@param u0 number
---@param v0 number
---@param u1 number
---@param v1 number
function CMauiBitmap:SetUV(u0, v0, u1, v1)
end

--- Allow two bitmaps to use the same textures
function CMauiBitmap:ShareTextures(bitmap)
end

---
function CMauiBitmap:Stop()
end

---
function CMauiBitmap:UseAlphaHitTest(bool)
end

return CMauiBitmap
