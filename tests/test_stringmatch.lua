local luft = require "luft"

require "../lua/system/utils.lua"

luft.describe("test string.match and string.gmatch", function()
    local test = "The quick brown FOX745 JUMPS over the lazy doge."

    luft.test("matches exact string start", function()
        luft.expect(test:match("^The")).to.equal "The"
        luft.expect(test:match("^quick")).to.be_nil()
    end)

    luft.test("matches exact offset string start", function()
        luft.expect(test:match("^quick", 5)).to.equal "quick"
    end)

    luft.test("matches end of string capture", function()
        luft.expect(test:match("d(og)e%.$")).to.equal "og"
        luft.expect(test:match("lazy$")).to.be_nil()
    end)

    luft.test("matches regex captures", function()
        luft.expect(test:match("%d")).to.equal "7"
        luft.expect(test:match("%u+%d+")).to.equal "FOX745"
    end)

    luft.test("matches multiple captures", function()
        luft.expect(test:match("(%u+) (%l+)")).to.equal("JUMPS", "over")
    end)

    local loctest = "<LOC arbitrary_loc_tag>The quick brown test string."
    local balancetest = "< < > ><> <.>"

    luft.test("matches balanced regex", function()
        luft.expect(loctest:match("%b<>")).to.equal "<LOC arbitrary_loc_tag>"
        luft.expect(balancetest:match("%b<>")).to.equal "< < > >"
        luft.expect(balancetest:match("%b><")).to.equal "><"
    end)

    luft.test("matches loc tag", function()
        luft.expect(loctest:match("<LOC ([^>]+)>")).to.equal "arbitrary_loc_tag"
        luft.expect(loctest:match("<LOC [^>]+>(.*)")).to.equal "The quick brown test string."
        luft.expect(loctest:match("<LOC ([^>]+)>(.*)"))
            .to.equal("arbitrary_loc_tag", "The quick brown test string.")
    end)

    luft.test("gmatch iterates over word pairs correctly", function()
        local iterator = test:gmatch("[^ ]+ [^ ]+")
        luft.expect(iterator).to.be.a "function"
        luft.expect(iterator()).to.equal "The quick"
        luft.expect(iterator()).to.equal "brown FOX745"
        luft.expect(iterator()).to.equal "JUMPS over"
        luft.expect(iterator()).to.equal "the lazy"
        luft.expect(iterator()).to.be_nil()
    end)

    luft.test("gmatch correctly returns multiple arguments", function()
        local iterator = test:gmatch("([^ ]+) ([^ ]+)")
        luft.expect(iterator).to.be.a "function"
        luft.expect(iterator()).to.equal("The", "quick")
        luft.expect(iterator()).to.equal("brown", "FOX745")
        luft.expect(iterator()).to.equal("JUMPS", "over")
        luft.expect(iterator()).to.equal("the", "lazy")
        luft.expect(iterator()).to.be_nil()
    end)
end)

luft.finish()
