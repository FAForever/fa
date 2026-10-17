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
---@see moho.movie_methods.OnFinished # Called when the movie ends
function CMauiMovie:Play()
end

---
---@see moho.movie_methods.OnStopped # Called on the next frame
function CMauiMovie:Stop()
end

--- Called by the engine when the movie reaches its end without looping
---@see moho.movie_methods.Play # Plays the movie
---@type nil | fun(self: Movie)
CMauiMovie.OnFinished = nil

--- Called by the engine on the frame after the movie is stopped with `Stop`
---@see moho.movie_methods.Stop # Stops the movie
---@type nil | fun(self: Movie)
CMauiMovie.OnStopped = nil

--- Called by the engine when the subtitle text of the movie changes
---@type nil | fun(self: Movie, text: string)
CMauiMovie.OnSubtitle = nil

return CMauiMovie
