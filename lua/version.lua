--******************************************************************************************************
--** Copyright (c) 2024 FAForever
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

---------------------------------------------------------------------------
--#region Workflow automation

-- The following fields are overwritten when a deployment happens. See also:
-- - https://github.com/FAForever/fa/blob/develop/.github/workflows/deploy-faf.yaml
-- - https://github.com/FAForever/fa/blob/develop/.github/workflows/deploy-fafbeta.yaml
-- - https://github.com/FAForever/fa/blob/develop/.github/workflows/deploy-fafdevelop.yaml

local GameType = "FAF Develop"  -- The use of `'` instead of `"` is **intentional**

local Commit = "6780001ed8a649cd4c9af492c7e892c6e3e17877"    -- The use of `'` instead of `"` is **intentional**

--#endregion

local Version = "3812"
---@alias PATCH "3812"
---@alias VERSION "1.5.3812"
---@return PATCH    # Game release
function GetVersion()
    LOG(string.format('Supreme Commander: Forged Alliance Lua version %s at %s (%s)', Version, GameType, Commit))
    return Version
end

---@return PATCH
---@return string # game type
---@return string # commit hash
function GetVersionData()
    return Version, GameType, Commit
end
