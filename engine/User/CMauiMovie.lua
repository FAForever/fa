---@meta

---@class moho.movie_methods : moho.control_methods
local CMauiMovie = {}

---
function CMauiMovie:GetFrameRate()
end

--- Returns the number of frames in the movie
---@return number
function CMauiMovie:GetNumFrames()
end

---
---@param filename string
---@return boolean
function CMauiMovie:InternalSet(filename)
end

---
---@return boolean
function CMauiMovie:IsLoaded()
end

---
---@param loop boolean
function CMauiMovie:Loop(loop)
end

---
function CMauiMovie:Play()
end

---
function CMauiMovie:Stop()
end

return CMauiMovie
