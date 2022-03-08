local lust = require"lust"

require"../lua/system/utils.lua"

lust.describe("test string.match and string.gmatch", function()
    local test='The quick brown FOX745 JUMPS over the lazy doge.'

    lust.it('matches exact string start', function()
        lust.expect(test:match'^The').to.equal'The'
        lust.expect(test:match'^quick').to.equal(nil)
    end)

    lust.it("matches exact offset string start", function()
        lust.expect(test:match('^quick',5)).to.equal'quick'
    end)

    lust.it("matches end of string capture", function()
        lust.expect(test:match'd(og)e%.$').to.equal'og'
        lust.expect(test:match'lazy$').to.equal(nil)
    end)

    lust.it("matches regex captures", function()
        lust.expect(test:match'%d').to.equal'7'
        lust.expect(test:match'%u+%d+').to.equal'FOX745'
    end)

    lust.it("matches multiple captures", function()
        local a,b,c = test:match'(%u+) (%l+)'
        lust.expect(a).to.equal'JUMPS'
        lust.expect(b).to.equal'over'
        lust.expect(c).to.equal(nil)
    end)

    local loctest = '<LOC arbitrary_loc_tag>The quick brown test string.'
    local balancetest = '< < > ><> <.>'

    lust.it("matches balanced regex", function()
        lust.expect(loctest:match'%b<>').to.equal'<LOC arbitrary_loc_tag>'
        lust.expect(balancetest:match'%b<>').to.equal'< < > >'
        lust.expect(balancetest:match'%b><').to.equal'><'
    end)

    lust.it("matches loc tag", function()
        lust.expect(loctest:match'<LOC ([^>]+)>').to.equal'arbitrary_loc_tag'
        lust.expect(loctest:match'<LOC [^>]+>(.*)').to.equal'The quick brown test string.'
        local a,b,c = loctest:match'<LOC ([^>]+)>(.*)'
        lust.expect(a).to.equal'arbitrary_loc_tag'
        lust.expect(b).to.equal'The quick brown test string.'
        lust.expect(c).to.equal(nil)
    end)

    lust.it("gmatch iterates over word pairs correctly", function()
        local iterator = test:gmatch'[^ ]+ [^ ]+'
        lust.expect(iterator).to.be.a'function'
        lust.expect(iterator()).to.equal'The quick'
        lust.expect(iterator()).to.equal'brown FOX745'
        lust.expect(iterator()).to.equal'JUMPS over'
        lust.expect(iterator()).to.equal'the lazy'
        lust.expect(iterator()).to.equal(nil)
    end)

    lust.it("gmatch correctly returns multiple arguments", function()
        local iterator = test:gmatch'([^ ]+) ([^ ]+)'
        lust.expect(iterator).to.be.a'function'
        local a,b,c = iterator()
        lust.expect(a).to.equal'The'
        lust.expect(b).to.equal'quick'
        lust.expect(c).to.equal(nil)
        a,b,c = iterator()
        lust.expect(a).to.equal'brown'
        lust.expect(b).to.equal'FOX745'
        lust.expect(c).to.equal(nil)
        a,b,c = iterator()
        lust.expect(a).to.equal'JUMPS'
        lust.expect(b).to.equal'over'
        lust.expect(c).to.equal(nil)
        a,b,c = iterator()
        lust.expect(a).to.equal'the'
        lust.expect(b).to.equal'lazy'
        lust.expect(c).to.equal(nil)
        lust.expect(iterator()).to.equal(nil)
    end)
end)

lust.finish()
