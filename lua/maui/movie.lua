-- Class methods:
-- Set(string filename)
-- Play()
-- Stop()
-- Loop(bool loop)
-- number GetFrameRate()
-- int GetNumFrames()

local Control = import("/lua/maui/control.lua").Control

---@class Movie : moho.movie_methods, Control, InternalObject
Movie = ClassUI(moho.movie_methods, Control) {

    __init = function(self, parent, filename, sound, voice)
        InternalCreateMovie(self, parent)
        if filename then
            self:Set(filename, sound, voice)
        end
    end,

    ResetLayout = function(self)
        Control.ResetLayout(self)
        self.Width:SetFunction(function() return self.MovieWidth() end)
        self.Height:SetFunction(function() return self.MovieHeight() end)
    end,

    OnInit = function(self)
        Control.OnInit(self)
    end,
    
    Set = function(self,filename,sound,voice) -- sound and voice are optional
        self:Reset()
        local ok = self:InternalSet(filename)
        if ok then
            self.soundHandle = sound and PlaySound(sound, true)
            self.voiceHandle = voice and PlayVoice(voice, false, true)
            self.soundsStarted = false
            self.loadThread = ForkThread(
                function()
                    while true do
                        if self:IsLoaded()
                                and (not self.soundHandle or SoundIsPrepared(self.soundHandle))
                                and (not self.voiceHandle or SoundIsPrepared(self.voiceHandle)) then
                            self:OnLoaded()
                            return
                        end
                        WaitSeconds(0.01)
                    end
                end
            )
        else
            -- Force calls to OnStopped()
            self:OnStopped()
        end
    end,

    Play = function(self)
        moho.movie_methods.Play(self)
        if not self.soundsStarted then
            if self.soundHandle then StartSound(self.soundHandle) end
            if self.voiceHandle then StartSound(self.voiceHandle) end
            self.soundsStarted = true
        end
        if self.loadThread then
            KillThread(self.loadThread)
            self.loadThread = nil
        end
    end,

    GetLength = function(self)
        return self:GetNumFrames() / self:GetFrameRate()
    end,

    -- callback scripts
    OnFinished = function(self) end,
    OnStopped = function(self) end,

    -- Called when a subtitle changes. string should be LOC()'d for display
    OnSubtitle = function(self,string) end,

    -- Called when the movie is loaded and ready to play immediately
    OnLoaded = function(self)
    end,

    Reset = function(self)
        if self.soundHandle then
            StopSound(self.soundHandle,true)
            self.soundHandle = nil
        end
        if self.voiceHandle then
            StopSound(self.voiceHandle,true)
            self.voiceHandle = nil
        end
        if self.loadThread then
            KillThread(self.loadThread)
            self.loadThread = nil
        end
        self:Stop()
    end,

    OnDestroy = function(self)
        self:Reset()
        Control.OnDestroy(self)
    end,
}
