
--**************************************************************************************************
--** Shared under the MIT license
--**************************************************************************************************

--- Constructs an empty table that the profiler can populate.
function CreateEmptyProfilerTable() 
    return {
        -- what
        Lua = {
            -- namewhat
              ["global"]    = { }
            , ["upval"]     = { }
            , ["local"]     = { }
            , ["method"]    = { }
            , ["field"]     = { }
            , ["other"]     = { }
        },

        -- what
        C = {
            -- namewhat
              ["global"]    = { }
            , ["upval"]     = { }
            , ["local"]     = { }
            , ["method"]    = { }
            , ["field"]     = { }
            , ["other"]     = { }
        },

        -- what
        main = {
            -- namewhat
              ["global"]    = { }
            , ["upval"]     = { }
            , ["local"]     = { }
            , ["method"]    = { }
            , ["field"]     = { }
            , ["other"]     = { }
        },

        -- what
        unknown = {
          -- namewhat
            ["global"]    = { }
          , ["upval"]     = { }
          , ["local"]     = { }
          , ["method"]    = { }
          , ["field"]     = { }
          , ["other"]     = { }
      },
    }
end