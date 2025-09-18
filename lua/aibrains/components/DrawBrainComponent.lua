--******************************************************************************************************
--** Copyright (c) 2024 Willem 'Jip' Wijnia
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

local DrawParams = import("/lua/shared/DrawParams.lua")

---@class DrawOffer 
---@field InitiatedAt number

---@class DrawBrainComponent
---@field DrawOffer? DrawOffer
DrawBrainComponent = ClassSimple {

    --- Initiates a draw offer.
    ---@param self DrawBrainComponent | AIBrain
    OfferDraw = function(self)
        self.DrawOffer = {
            InitiatedAt = GetGameTick(),
        }

        print("Draw offered by " .. self.Nickname)
    end,

    --- Withdraws a draw offer.
    ---@param self DrawBrainComponent | AIBrain
    WithdrawDrawOffer = function(self)
        self.DrawOffer = nil

        print("Draw withdrawn by " .. self.Nickname)
    end,

    --- Returns whether a draw offer is currently active.
    ---@param self DrawBrainComponent | AIBrain
    ---@return boolean
    WantsToDraw = function(self)
        local drawOffer = self.DrawOffer
        if not drawOffer then
            return false
        end

        if (drawOffer.InitiatedAt) + DrawParams.VoteTime < GetGameTick() then
            return false
        end

        return true
    end,

    ---@param self AIBrain
    OnDraw = function(self)
        self.Status = 'Draw'
    end,
}