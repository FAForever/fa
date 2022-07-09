---@declare-global
---@class moho.movie_methods : moho.control_methods
local CMauiMovie = {}

---
function CMauiMovie:GetFrameRate()
end

---
--  int GetNumFrames() - returns the number of frames in the movie
function CMauiMovie:GetNumFrames()
end

---
--  bool Movie:InternalSet(filename)
function CMauiMovie:InternalSet(filename)
end

---
--  IsLoaded()
function CMauiMovie:IsLoaded()
end

---
--  Loop(bool)
function CMauiMovie:Loop(bool)
end

---
--  Play()
function CMauiMovie:Play()
end

---
--  Stop()
function CMauiMovie:Stop()
end

return CMauiMovie
