
This is a dummy file to help work with init files as they have a limited lua functionality available to them.

```lua
local function repr(t, indent, seen)
    if type(t) == "table" then 
        for k, v in t do 
            if k != "_G" then 
                seen[k] = true
                LOG(indent .. tostring(k) .. ": " .. tostring(v))
                repr(v, indent .. " - ")
            end
        end
    end
end

repr(_G, "", { })
```

```yaml
string: table: 10020208
 - sub: cfunction: 101C88C0
 - lualex: cfunction: 101C8B80
 - gfind: cfunction: 101C8B00
 - rep: cfunction: 101C89C0
 - gsub: cfunction: 101C8B40
 - char: cfunction: 101C8980
 - dump: cfunction: 101C8A80
 - find: cfunction: 101C8AC0
 - upper: cfunction: 101C8940
 - len: cfunction: 101C8880
 - format: cfunction: 101C8A40
 - byte: cfunction: 101C8A00
 - lower: cfunction: 101C8900
tostring: cfunction: 100504C0
gcinfo: cfunction: 10050700
_ALERT: cfunction: 101CAF80
loadlib: cfunction: 101CAE80
os: table: 10020168
 - exit: cfunction: 101C8C80
 - setlocale: cfunction: 101C8D80
 - execute: cfunction: 101C8C40
 - getenv: cfunction: 101C8CC0
 - difftime: cfunction: 101C8C00
 - remove: cfunction: 101C8D00
 - time: cfunction: 101C8DC0
 - clock: cfunction: 101C8040
 - tmpname: cfunction: 101C8E00
 - rename: cfunction: 101C8D40
 - date: cfunction: 101C8000
unpack: cfunction: 10050580
require: cfunction: 101C83C0
getfenv: cfunction: 10050B00
serialize: table: 100201E0
 - fromstring: cfunction: 101C8840
 - tostring: cfunction: 101C8800
setmetatable: cfunction: 10050AC0
next: cfunction: 10050B80
_TRACEBACK: cfunction: 101CAE40
assert: cfunction: 10050540
tonumber: cfunction: 10050480
io: table: 100201B8
 - popen: cfunction: 101C91E0
 - write: cfunction: 101C90F0
 - close: cfunction: 101C9280
 - flush: cfunction: 101C9320
 - open: cfunction: 101C9230
 - output: cfunction: 101C9370
 - dir: cfunction: 101C90A0
 - read: cfunction: 101C9190
 - stderr: file (101C7B38)
 - stdin: file (101C7B08)
 - input: cfunction: 101C93C0
 - stdout: file (101C7B20)
 - lines: cfunction: 101C92D0
 - tmpfile: cfunction: 101C9140
rawequal: cfunction: 100505C0
collectgarbage: cfunction: 100506C0
getmetatable: cfunction: 10050A80
InitFileDir: C:\ProgramData\FAForever\bin
_LOADED: table: 10020668
rawset: cfunction: 10050640
LuaDumpBinary: cfunction: 101CAF00
LaunchDir: C:\ProgramData\FAForever\bin
SHGetFolderPath: cfunction: 101CAFC0
LOG: cfunction: 101CAF40
math: table: 10020230
 - log: cfunction: 101C87C0
 - atan: cfunction: 101C8540
 - ldexp: cfunction: 101C86C0
 - deg: cfunction: 101CA340
 - tan: cfunction: 101C8480
 - cos: cfunction: 101C8440
 - pi: 3.1415927410126
 - random: cfunction: 101CA280
 - randomseed: cfunction: 101CA240
 - frexp: cfunction: 101C8680
 - ceil: cfunction: 101C85C0
 - floor: cfunction: 101C8600
 - rad: cfunction: 101CA2C0
 - max: cfunction: 101C8780
 - sqrt: cfunction: 101C8700
 - pow: cfunction: 101CA300
 - asin: cfunction: 101C84C0
 - min: cfunction: 101C8740
 - mod: cfunction: 101C8640
 - exp: cfunction: 101CA380
 - log10: cfunction: 101CA3C0
 - atan2: cfunction: 101C8580
 - acos: cfunction: 101C8500
 - sin: cfunction: 101C8400
 - abs: cfunction: 101C8BC0
import: cfunction: 101CAEC0
pcall: cfunction: 10050680
debug: table: 10020258
 - listlocals: cfunction: 101CACC0
 - allocatedsize: cfunction: 101CAE00
 - gethook: cfunction: 101CA140
 - traceback: cfunction: 101CAC00
 - getlocal: cfunction: 101CA1C0
 - getupvalue: cfunction: 101CA100
 - listcode: cfunction: 101CAC40
 - debug: cfunction: 101CA000
 - listk: cfunction: 101CAC80
 - allobjects: cfunction: 101CAD40
 - sethook: cfunction: 101CA0C0
 - trackallocations: cfunction: 101CADC0
 - getinfo: cfunction: 101CA180
 - setupvalue: cfunction: 101CA040
 - allocinfo: cfunction: 101CAD80
 - profiledata: cfunction: 101CAD00
 - setlocal: cfunction: 101CA080
__pow: cfunction: 101CA200
type: cfunction: 10050500
newproxy: cfunction: 10053AA0
table: table: 10020690
 - setn: cfunction: 101C8140
 - insert: cfunction: 101C80C0
 - getn: cfunction: 101C8180
 - foreachi: cfunction: 101C81C0
 - foreach: cfunction: 101C8200
 - sort: cfunction: 101C8100
 - remove: cfunction: 101C8080
 - concat: cfunction: 101C8240
coroutine: table: 10020640
 - resume: cfunction: 101C8300
 - yield: cfunction: 101C82C0
 - status: cfunction: 101C8280
 - wrap: cfunction: 101C8340
 - create: cfunction: 101C8380
print: cfunction: 10050440
rawget: cfunction: 10050600
loadstring: cfunction: 100507C0
_VERSION: Lua 5.0.1
dofile: cfunction: 10050780
setfenv: cfunction: 10050B40
pairs: cfunction: 10050400
ipairs: cfunction: 10050BC0
error: cfunction: 10050A40
loadfile: cfunction: 10050740
```