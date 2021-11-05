-- Test framework
local lust = require "lust"

-- Functions are imported to the global scope...
require "../lua/system/utils.lua"

lust.describe("test utils", function()
  lust.describe("string", function()
    lust.it("StringSplit empty", function()
      lust.expect(StringSplit("")).to.equal({})
    end)

    lust.it("StringSplit default", function()
      lust.expect(StringSplit("Hello:World")).to.equal({"Hello", "World"})
      lust.expect(StringSplit("Hello:foo:World"))
        .to.equal({"Hello", "foo", "World"})
    end)

    lust.it("StringSplit separator", function()
      lust.expect(StringSplit("Hello World", " "))
        .to.equal({"Hello", "World"})
      lust.expect(StringSplit("Hello foo World", " "))
        .to.equal({"Hello", "foo", "World"})
      lust.expect(StringSplit("Hello |foo| World", "|"))
        .to.equal({"Hello ", "foo", " World"})
    end)

    lust.it("StringStartsWith", function()
      lust.expect(StringStartsWith("Hello, World", "Hello")).to.equal(true)
    end)

    lust.it("StringExtract", function()
      lust.expect(StringExtract("/path/name_end.lua", "/", "_end", true))
        .to.equal("name")
    end)

    lust.it("StringComma", function()
      lust.expect(StringComma(100)).to.equal("100")
      lust.expect(StringComma(1000)).to.equal("1,000")
      lust.expect(StringComma(10000)).to.equal("10,000")
      -- Maybe not desired, but included for documentation purposes
      lust.expect(StringComma(100000)).to.equal("1e+05")
      lust.expect(StringComma(1000000)).to.equal("1e+06")
    end)

    lust.it("StringPrepend", function()
      lust.expect(StringPrepend("foo")).to.equal(" foo")
      lust.expect(StringPrepend("foo", "bar")).to.equal("barfoo")
    end)

    lust.it("StringSplitCamel", function()
      lust.expect(StringSplitCamel("SupportCommanderUnit"))
        .to.equal("Support Commander Unit")
      lust.expect(StringSplitCamel("supportCommanderUnit"))
        .to.equal("Support Commander Unit")
    end)

    lust.it("StringReverse", function()
      lust.expect(StringReverse("abc123")).to.equal("321cba")
    end)

    lust.it("StringCapitalize", function()
      lust.expect(StringCapitalize("hello supreme commander"))
        .to.equal("Hello Supreme Commander")
    end)

    lust.it("StringStarts", function()
      lust.expect(StringStarts("Hello, World", "Hello")).to.equal(true)
      lust.expect(StringStarts("Hello, World", "World")).to.equal(false)
    end)

    lust.it("StringEnds", function()
      lust.expect(StringEnds("Hello, World", "Hello")).to.equal(false)
      lust.expect(StringEnds("Hello, World", "World")).to.equal(true)
    end)

  end)
end)

-- Make sure to call finish so that any errors will fail the CI!
lust.finish()
