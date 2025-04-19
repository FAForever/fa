local luft = require "./tests/packages/luft"

-- color library
dofile "./lua/shared/statistics.lua"

local testSets = {
    { -- subtest 1
        list = {},
        sum = 0, mean = 0, deviation = 0, skewness = 0,
        remove_outliers = {},
    }, { -- subtest 2
        list = {0},
        sum = 0, mean = 0, deviation = 0, skewness = 0,
        remove_outliers = {0},
    }, { -- subtest 3
        list = {1},
        sum = 1, mean = 1, deviation = 0, skewness = 0,
        remove_outliers = {1},
    }, { -- subtest 4
        list = {2},
        sum = 2, mean = 2, deviation = 0, skewness = 0,
        remove_outliers = {2},
    }, { -- subtest 5
        list = {1, 2},
        sum = 3, mean = 1.5, deviation = math.sqrt(1 / 2), skewness = 0,
        remove_outliers = {1, 2},
    }, { -- subtest 6
        list = {2, -4},
        sum = -2, mean = -1, deviation = 3 * math.sqrt(2), skewness = 0,
        remove_outliers = {-4, 2},
    }, { -- subtest 7
        list = {1, 9, -5},
        sum = 5, mean = 5/3, deviation = 2 * math.sqrt(37 / 3), skewness = 110 / 111 / math.sqrt(111),
        remove_outliers = {-5, 1, 9},
    }, { -- subtest 8
        list = {1, 2, 3, 8},
        sum = 14, mean = 3.5, deviation = math.sqrt(29 / 3), skewness = 54 / 29 * math.sqrt(3 / 29),
        remove_outliers = {1, 2, 3, 8},
    }, { -- subtest 9
        list = {1, 2, 3, 4, 15},
        sum = 25, mean = 5, deviation = math.sqrt(65 / 2), skewness = 72 / 13 * math.sqrt(2 / 65),
        remove_outliers = {1, 2, 3, 4},
    },
}

luft.describe("Stat functions", function()
    luft.test_all("Summation", testSets, function(set)
        luft.expect(Sum(set.list)).to.be(set.sum)
    end)
    luft.test_all("Mean", testSets, function(set)
        luft.expect(Mean(set.list)).to.be(set.mean)
    end)
    luft.test_all("Deviation", testSets, function(set)
        luft.expect(Deviation(set.list)).to.be.close.to(set.deviation)
    end)
    luft.test_all("Skewness", testSets, function(set)
        luft.expect(Skewness(set.list)).to.be.close.to(set.skewness)
    end)
    luft.test_all("Remove Outliers", testSets, function(set)
        local removedOutliers, n = RemoveOutliers(set.list)
        luft.expect(removedOutliers).to.equal(set.remove_outliers)
    end)
end)

luft.finish()
