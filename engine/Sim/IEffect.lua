---@declare-global
---@class moho.IEffect
local IEffect = {}


---
function IEffect:Destroy()
end

---
---@param x any
---@param y any
---@param z any
---@return moho.IEffect
function IEffect:OffsetEmitter(x, y, z)
end

--- Resize the emitter curve to the number of ticks passed in.This is so if we change the lifetime of the emitter we can rescale some of the curves to match if needed.Arguably this should happen automatically to all curves but the original design was screwed up.returns the effect so you can chain calls like:effect:SetEmitterParam('x',1):ScaleEmitter(3.7)
function IEffect:ResizeEmitterCurve(param, timeInTicks)
end

--- Returns the effect so you can chain calls like:effect:SetEmitterParam('x',1):ScaleEmitter(3.7)
function IEffect:ScaleEmitter(param, scale)
end

---
---@param name string
---@param value number
function IEffect:SetBeamParam(name, value)
end

--- 
function IEffect:SetEmitterCurveParam(param, height, size)
end

--- Returns the effect so you can chain calls like `effect:SetEmitterParam('x',1):ScaleEmitter(3.7)`
---@param param string
---@param value number
---@return moho.IEffect
function IEffect:SetEmitterParam(param, value)
end

return IEffect
