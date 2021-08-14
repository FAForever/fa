-- Class methods:
-- SetNewTexture(filename, hotspotX, hotspotY)
-- SetDefaultTexture(filename, hotspotX, hotspotY)
-- Reset() -- re-applies default texture

Cursor = Class(moho.cursor_methods) {
    __init = function(self, defaultTexture, defaultHotspotX, defaultHotspotY)
        _c_CreateCursor(self, nil)
        self:SetDefaultTexture(defaultTexture, defaultHotspotX, defaultHotspotY)
        self:ResetToDefault()

        self._hotspotX = 0
        self._hotspotY = 0

        self._filename = import('/lua/lazyvar.lua').Create()
        self._filename.OnDirty = function(var)
            self:SetNewTexture(var(), self._hotspotX, self._hotspotY)
        end

        self._animThread = nil
    end,

    SetTexture = function(self, filename, hotspotX, hotspotY, numFrames, fps)
        local hotspotX = hotspotX or 0
        local hotspotY = hotspotY or 0
        self._hotspotX = hotspotX
        self._hotspotY = hotspotY

        KillThread(self._animThread)
        if numFrames and numFrames ~= 1 then
            local curFrame = 1
            local extPos = string.find(filename, ".dds")
            filename = string.sub(filename, 1, extPos - 1)
            self._animThread = ForkThread(function()
                while true do
                    self._filename:Set(string.format("%s%02d.dds", filename, tostring(curFrame)))
                    curFrame = curFrame + 1
                    if curFrame > numFrames then
                        curFrame = 1
                    end
                    WaitSeconds(1/fps)
                end
            end)
        else
            self._filename:Set(filename)
        end
    end,

    Reset = function(self)
        if self._animThread then
            KillThread(self._animThread)
        end
        self:ResetToDefault()
    end
}
