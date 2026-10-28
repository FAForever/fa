-- Test framework
local luft = require "./tests/packages/luft"

-- Vector2 is needed in utils but not provided outside the game, so it has to be created here
local Vector2Meta = {
    __index = function(t, k)
        if k == 'x' then
            return t[1]
        elseif k == 'y' then
            return t[2]
        elseif k == 'z' then
            return t[3]
        else
            error("bad argument #2 to `?' ('x', 'y', or 'z' expected)", 1)
        end
    end,

    __newindex = function(t, k, v)
        if k == 'x' then
            t[1] = v
        elseif k == 'y' then
            t[2] = v
        elseif k == 'z' then
            t[3] = v
        else
            error("bad argument #2 to `?' ('x', 'y', or 'z' expected)", 1)
        end
    end,
}
Vector2 = function(...)
    if arg.n ~= 2 then
        error("expected 2 args, but got " .. arg.n)
    end
    if not type(arg[1]) == "number" then
        error("number expected but got " .. type(arg[1]))
    end
    if not type(arg[2]) == "number" then
        error("number expected but got " .. type(arg[2]))
    end

    local newVector2 = {arg[1], arg[2]}
    setmetatable(newVector2, Vector2Meta)
    return newVector2
end

-- These functions are imported to the global scope in globalInit and RuleInit
require "./lua/system/utils.lua"

luft.describe("Utils", function()
    luft.describe("string.split", function()
        luft.test("Empty", function()
            luft.expect(string.split("")).to.equal({})
        end)

        luft.test("Default", function()
            luft.expect(string.split("Hello:World")).to.equal({ "Hello", "World" })
            luft.expect(string.split("Hello:foo:World"))
                .to.equal({ "Hello", "foo", "World" })
        end)

        luft.test("Separator", function()
            luft.expect(string.split("Hello World", ' '))
                .to.equal({ "Hello", "World" })
            luft.expect(string.split("Hello foo World", ' '))
                .to.equal({ "Hello", "foo", "World" })
            luft.expect(string.split("Hello |foo| World", '|'))
                .to.equal({ "Hello ", "foo", " World" })
        end)
    end)

    luft.test("string.extractBetween", function()
        luft.expect(string.extractBetween("/path/name_end.lua", '/', "_end", true))
            .to.equal("name")
    end)

    luft.test("string.commaFormat", function()
        luft.expect(string.commaFormat(100)).to.equal("100")
        luft.expect(string.commaFormat(1000)).to.equal("1,000")
        luft.expect(string.commaFormat(10000)).to.equal("10,000")
        if luft.environment == "FA" then
            luft.expect(string.commaFormat(100000)).to.equal("100,000")
            luft.expect(string.commaFormat(1000000)).to.equal("1,000,000")
        else
            luft.expect(string.commaFormat(100000)).to.equal("1e+05")
            luft.expect(string.commaFormat(1000000)).to.equal("1e+06")
        end
    end)

    luft.test("string.prepend", function()
        luft.expect(string.prepend("foo")).to.equal(" foo")
        luft.expect(string.prepend("foo", "bar")).to.equal("barfoo")
    end)

    luft.test("string.splitCamelCase", function()
        luft.expect(string.splitCamelCase("SupportCommanderUnit"))
            .to.equal("Support Commander Unit")
        luft.expect(string.splitCamelCase("supportCommanderUnit"))
            .to.equal("Support Commander Unit")
    end)

    luft.test("string.reverse", function()
        luft.expect(string.reverse("abc123")).to.equal("321cba")
    end)

    luft.test("string.capitalize", function()
        luft.expect(string.capitalize("hello supreme commander"))
            .to.equal("Hello Supreme Commander")
    end)

    luft.test("string.startsWith", function()
        luft.expect(string.startsWith("Hello, World", "Hello")).to.equal(true)
        luft.expect(string.startsWith("Hello, World", "World")).to.equal(false)
    end)

    luft.test("string.endsWith", function()
        luft.expect(string.endsWith("Hello, World", "Hello")).to.equal(false)
        luft.expect(string.endsWith("Hello, World", "World")).to.equal(true)
    end)

    local test = "The quick brown FOX745 JUMPS over the lazy doge."

    luft.describe("string.match and string.gmatch", function()

        luft.test("Matches exact string start", function()
            luft.expect(test:match("^The")).to.equal "The"
            luft.expect(test:match("^quick")).to.be_nil()
        end)

        luft.test("Matches exact offset string start", function()
            luft.expect(test:match("^quick", 5)).to.equal "quick"
        end)

        luft.test("Matches end of string capture", function()
            luft.expect(test:match("d(og)e%.$")).to.equal "og"
            luft.expect(test:match("lazy$")).to.be_nil()
        end)

        luft.test("Matches regex captures", function()
            luft.expect(test:match("%d")).to.equal "7"
            luft.expect(test:match("%u+%d+")).to.equal "FOX745"
        end)

        luft.test("Matches multiple captures", function()
            luft.expect(test:match("(%u+) (%l+)")).to.equal("JUMPS", "over")
        end)

        local loctest = "<LOC arbitrary_loc_tag>The quick brown test string."
        local balancetest = "< < > ><> <.>"

        luft.test("Matches balanced regex", function()
            luft.expect(loctest:match("%b<>")).to.equal "<LOC arbitrary_loc_tag>"
            luft.expect(balancetest:match("%b<>")).to.equal "< < > >"
            luft.expect(balancetest:match("%b><")).to.equal "><"
        end)

        luft.test("Matches loc tag", function()
            luft.expect(loctest:match("<LOC ([^>]+)>")).to.equal "arbitrary_loc_tag"
            luft.expect(loctest:match("<LOC [^>]+>(.*)")).to.equal "The quick brown test string."
            luft.expect(loctest:match("<LOC ([^>]+)>(.*)"))
                .to.equal("arbitrary_loc_tag", "The quick brown test string.")
        end)
    end)

    luft.test("string.gmatch iterates over word pairs correctly", function()
        local iterator = test:gmatch("[^ ]+ [^ ]+")
        luft.expect(iterator).to.be_function()
        luft.expect(iterator()).to.equal "The quick"
        luft.expect(iterator()).to.equal "brown FOX745"
        luft.expect(iterator()).to.equal "JUMPS over"
        luft.expect(iterator()).to.equal "the lazy"
        luft.expect(iterator()).to.be_nil()
    end)

    luft.test("string.gmatch correctly returns multiple arguments", function()
        local iterator = test:gmatch("([^ ]+) ([^ ]+)")
        luft.expect(iterator).to.be_function()
        luft.expect(iterator()).to.equal("The", "quick")
        luft.expect(iterator()).to.equal("brown", "FOX745")
        luft.expect(iterator()).to.equal("JUMPS", "over")
        luft.expect(iterator()).to.equal("the", "lazy")
        luft.expect(iterator()).to.be_nil()
    end)
end)

-- Make sure to call finish so that any errors will fail the CI!
luft.finish()
