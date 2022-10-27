-- Test framework
local luft = require "luft"

-- Functions are imported to the global scope...
require "../lua/system/utils.lua"

luft.describe("test utils", function()
    luft.describe("string", function()
        luft.test("StringSplit empty", function()
            luft.expect(StringSplit("")).to.equal({})
        end)

        luft.test("StringSplit default", function()
            luft.expect(StringSplit("Hello:World")).to.equal({"Hello", "World"})
            luft.expect(StringSplit("Hello:foo:World"))
                .to.equal({"Hello", "foo", "World"})
        end)

        luft.test("StringSplit separator", function()
            luft.expect(StringSplit("Hello World", " "))
                .to.equal({"Hello", "World"})
            luft.expect(StringSplit("Hello foo World", " "))
                .to.equal({"Hello", "foo", "World"})
            luft.expect(StringSplit("Hello |foo| World", "|"))
                .to.equal({"Hello ", "foo", " World"})
        end)

        luft.test("StringStartsWith", function()
            luft.expect(StringStartsWith("Hello, World", "Hello")).to.equal(true)
        end)

        luft.test("StringExtract", function()
            luft.expect(StringExtract("/path/name_end.lua", "/", "_end", true))
                .to.equal("name")
        end)

        luft.test("StringComma", function()
            luft.expect(StringComma(100)).to.equal("100")
            luft.expect(StringComma(1000)).to.equal("1,000")
            luft.expect(StringComma(10000)).to.equal("10,000")
            -- Maybe not desired, but included for documentation purposes
            luft.expect(StringComma(100000)).to.equal("1e+05")
            luft.expect(StringComma(1000000)).to.equal("1e+06")
        end)

        luft.test("StringPrepend", function()
            luft.expect(StringPrepend("foo")).to.equal(" foo")
            luft.expect(StringPrepend("foo", "bar")).to.equal("barfoo")
        end)

        luft.test("StringSplitCamel", function()
            luft.expect(StringSplitCamel("SupportCommanderUnit"))
                .to.equal("Support Commander Unit")
            luft.expect(StringSplitCamel("supportCommanderUnit"))
                .to.equal("Support Commander Unit")
        end)

        luft.test("StringReverse", function()
            luft.expect(StringReverse("abc123")).to.equal("321cba")
        end)

        luft.test("StringCapitalize", function()
            luft.expect(StringCapitalize("hello supreme commander"))
                .to.equal("Hello Supreme Commander")
        end)

        luft.test("StringStarts", function()
            luft.expect(StringStarts("Hello, World", "Hello")).to.equal(true)
            luft.expect(StringStarts("Hello, World", "World")).to.equal(false)
        end)

        luft.test("StringEnds", function()
            luft.expect(StringEnds("Hello, World", "Hello")).to.equal(false)
            luft.expect(StringEnds("Hello, World", "World")).to.equal(true)
        end)
    end)
end)

-- Make sure to call finish so that any errors will fail the CI!
luft.finish()
