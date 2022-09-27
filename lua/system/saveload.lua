-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- 
-- This is the code that registers the things that need to be
-- serialized by name instead of by value.  Any C functions need to be
-- in here because they cannot be serialized by value.  Also, any other
-- tables (or whatever) that are created by the C code need to be
-- serialized by name.
-- 

__serialize_name_for_object = {}
__serialize_object_for_name = {}


local function export_name(name, thing)
    __serialize_object_for_name[name] = thing
    __serialize_name_for_object[thing] = name
end    

local function export_funs(name, t)
    export_name(name,t)
    name = name .. '.'
    for fname, f in t do
        if type(fname)=='string' and iscallable(f) then
            export_name(name .. fname, f)
        end
    end
end


export_funs('_G', _G)
export_funs('string', string)
export_funs('table', table)
export_funs('serialize', serialize)
export_funs('math', math)
export_funs('debug', debug)
export_funs('coroutine', coroutine)

for cname, cls in moho do
    export_funs('moho.'..cname, cls)
end

export_name('Class',Class)
export_name('State',State)

export_name('__serialize_name_for_object',__serialize_name_for_object)
export_name('__serialize_object_for_name',__serialize_object_for_name)

export_funs('vector', getmetatable(Vector(0,0,0)))
