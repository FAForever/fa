
-- Override

This folder contains overrides to various UI globals as they are inefficient with their current implementation. As an example say we have the function `GetSessionClients`. It returns a table in a similar format to:

```lua
{
  {
    authorizedCommandSources={ 1 },
    connected=true,
    ejectedBy={ },
    local=true,
    name="Jip",
    ping=0,
    quiet=0,
    uid="0"
  }
}
```

The table grows linearly with the number of players. Rough indications of the amount of memory this consumes per call:
 - 1 table pointer:         40 bytes
 - 1 table pointer:         40 bytes per player
   - 8 hash table entries:      8x 40 bytes per player
   - 2 table pointers:          2x 40 bytes per player
   - 1 index table entry:       1x 16 bytes per player

Therefore a call is expensive. A unique table is returned regardles of the Lua state. As an example, when we do:

```lua
LOG(GetSessionClients())
LOG(GetSessionClients())
LOG(GetSessionClients())
```

Then the output is:

```yaml
table: 11E9C488
table: 11E9C370
table: 11E9C870
```

And these are unique, as the memory adres they point to are unique too. That shows us that, even when we're on the same frame, it returns a new table because the memory address of the tables are unique. Therefore we cache it and provide an interface for the UI to be updated when the clients are updated.

-- Functions that we Override

Due to the memory argument:
 - GetArmiesTable
 - GetSessionClients

-- Sources

The number of bytes per entry is based on this article:
 - https://wowwiki-archive.fandom.com/wiki/Lua_object_memory_sizes

And a quote of the relevant section in case the link is no longer available:

Tables behave in different ways depending on how much data is put in them, and the style of indexing used. A new, empty table will consume 40 bytes. As indexes are added, the table will allocate space for new indexes at an exponential rate. For example:

```lua
local t = {}  -- 40 bytes
t[1] = true   -- alloc 1 index
t[2] = true   -- alloc 1 index
t[3] = true   -- alloc 2 indexes
t[4] = true
t[5] = true   -- alloc 4 indexes
...
```

If a table is indexed by sequential integers, each index will take 16 bytes (not including any memory allocated for the value). If the becomes a hash, the index size will jump to 40 bytes each. Lua is "smart" and will allocate at the 16 byte rate as much as it can. If the int sequence is broken, the new values will allocate at the 40 byte rate. For example:

```lua
local t = {}  -- 40 bytes
t[1] = true   -- 16 bytes
t[2] = true   -- 16 bytes
t[3] = true   -- 32 bytes
t[4] = true
t[8] = true   -- 40 bytes
t[9] = true   -- 40 bytes
t[10] = true  -- 80 bytes
t["x"] = true
t["y"] = true -- 160 bytes
...
```

Note that sequential-int and hash allocation can be intermixed. Lua will continue to allocate at the 16-byte rate as long as it possibly can.

```lua
local t = {}  -- 40 bytes
t[1] = true   -- 16 bytes
t["1"] = true -- 40 bytes
t[2] = true   -- 16 bytes
t["2"] = true -- 40 bytes
t[3] = true   -- 32 bytes
t["3"] = true -- 80 bytes
```

Erasing values from a table will not deallocate space used for indexes. Thus, tables don't "shrink back" when erased. However, if a value is written into the table on a new index, the table will deallocate back to fit it's new data. This is not delayed until a GC step, but rather an immediate effect. To erase and shrink a table, one can use:

```lua
for i,v in pairs(t) do t[i] = nil end
t.reset = 1
t.reset = nil
```

It should be noted that erasing a table is generally more expensive than collecting the table during GC. One may wish to simply allocate a new empty table.