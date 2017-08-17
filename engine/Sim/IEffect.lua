--- Class IEffect
-- @classmod Sim.IEffect

---
--  Effect:OffsetEmitter(x,y,z)
function IEffect:OffsetEmitter(x, y, z)
end

---
--  Effect:ResizeEmitterCurve(parameter, time_in_ticks)Resize the emitter curve to the number of ticks passed in.This is so if we change the lifetime of the emitter we can rescale some of the curves to match if needed.Arguably this should happen automatically to all curves but the original design was screwed up.returns the effect so you can chain calls like:effect:SetEmitterParam('x',1):ScaleEmitter(3.7)
function IEffect:ResizeEmitterCurve(parameter,  time_in_ticks)
end

---
--  effect:ScaleEmitter(param, scale)returns the effect so you can chain calls like:effect:SetEmitterParam('x',1):ScaleEmitter(3.7)
function IEffect:ScaleEmitter(param,  scale)
end

---
--  effect:SetBeamParam('name', value)
function IEffect:SetBeamParam('name',  value)
end

---
--  Effect:SetEmitterCurveParam(param_name, height, size)
function IEffect:SetEmitterCurveParam(param_name,  height,  size)
end

---
--  effect:SetEmitterParam('name', value)returns the effect so you can chain calls like:effect:SetEmitterParam('x',1):ScaleEmitter(3.7)
function IEffect:SetEmitterParam('name',  value)
end

---
--
function IEffect:moho.IEffect()
end

