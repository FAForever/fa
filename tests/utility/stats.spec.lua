local luft = require "./tests/packages/luft"

-- color library
dofile "./lua/shared/statistics.lua"

local testSets = {
    { -- subtest 1
        list = {},
        sum = 0, mean = 0, deviation = 0, skewness = 0,
        quartiles = {nil, nil, nil, nil, nil},
        remove_outliers = {},
    }, { -- subtest 2
        list = {0},
        sum = 0, mean = 0, deviation = 0, skewness = 0,
        quartiles = {nil, nil, nil, nil, nil},
        remove_outliers = {0},
    }, { -- subtest 3
        list = {1},
        sum = 1, mean = 1, deviation = 0, skewness = 0,
        quartiles = {nil, nil, nil, nil, nil},
        remove_outliers = {1},
    }, { -- subtest 4
        list = {2},
        sum = 2, mean = 2, deviation = 0, skewness = 0,
        quartiles = {nil, nil, nil, nil, nil},
        remove_outliers = {2},
    }, { -- subtest 5
        list = {1, 2},
        sum = 3, mean = 1.5, deviation = math.sqrt(1 / 2), skewness = 0,
        quartiles = {nil, nil, nil, nil, nil},
        remove_outliers = {1, 2},
    }, { -- subtest 6
        list = {2, -4},
        sum = -2, mean = -1, deviation = 3 * math.sqrt(2), skewness = 0,
        quartiles = {nil, nil, nil, nil, nil},
        remove_outliers = {2, -4},
    }, { -- subtest 7
        list = {1, 9, -5},
        sum = 5, mean = 5/3, deviation = 2 * math.sqrt(37 / 3), skewness = 110 / 111 / math.sqrt(111),
        quartiles = {nil, nil, nil, nil, nil},
        remove_outliers = {1, 9, -5},
    }, { -- subtest 8
        list = {1, 2, 3, 8},
        sum = 14, mean = 3.5, deviation = math.sqrt(29 / 3), skewness = 54 / 29 * math.sqrt(3 / 29),
        quartiles = {nil, nil, nil, nil, nil},
        remove_outliers = {1, 2, 3, 8},
    }, { -- subtest 9
        list = {1, 2, 3, 4, 15},
        sum = 25, mean = 5, deviation = math.sqrt(65 / 2), skewness = 72 / 13 * math.sqrt(2 / 65),
        quartiles = {1, 1.5, 3, 9.5, 15},
        remove_outliers = {1, 2, 3, 4, 15},
    }, { -- subtest 10
        list = {9, 9, 9, 9, 9, 9, 9},
        sum = 63, mean = 9, deviation = 0, skewness = 0,
        quartiles = {9, 9, 9, 9, 9},
        remove_outliers = {9, 9, 9, 9, 9, 9, 9},
    }, { -- subtest 11
        list = {-2, 0, 0, 1, 15},
        quartiles = {-2, -1, 0, 8, 15},
        remove_outliers = {-2, 0, 0, 1},
    }, { -- subtest 12
        list = {-3, -2, -1, 1, 2, 22},
        quartiles = {-3, -2.5, 0, 12, 22},
        remove_outliers = {-3, -2, -1, 1, 2},
    }, { -- subtest 13
        list = {-4, 1, 2, 3, 4, 5, 9},
        quartiles = {-4, 1, 3, 5, 9},
        remove_outliers = {1, 2, 3, 4, 5, 9},
    }, { -- subtest 14
        list = {-6, 0, 1, 3, 4, 5, 6, 12},
        quartiles = {-6, 0, 3.5, 6, 12},
        remove_outliers = {0, 1, 3, 4, 5, 6, 12},
    },
}

luft.describe("Stat functions", function()
    luft.test_all("Summation", testSets, function(set)
        if set.sum then
            luft.expect(Sum(set.list)).to.be(set.sum)
        end
    end)
    luft.test_all("Mean", testSets, function(set)
        if set.mean then
            luft.expect(Mean(set.list)).to.be(set.mean)
        end
    end)
    luft.test_all("Deviation", testSets, function(set)
        if set.deviation then
            luft.expect(Deviation(set.list)).to.be.close.to(set.deviation)
        end
    end)
    luft.test_all("Skewness", testSets, function(set)
        if set.skewness then
            luft.expect(Skewness(set.list)).to.be.close.to(set.skewness)
            if set.deviation then
                luft.expect(Skewness(set.list, nil, nil, set.deviation)).to.be.close.to(set.skewness)
            end
        end
    end)
    luft.test_all("Quartile", testSets, function(set)
        if set.quartiles then
            luft.expect({GetQuartiles(set.list)}).to.equal(set.quartiles)
        end
    end)
    luft.test_all("Remove Outliers", testSets, function(set)
        if set.remove_outliers then
            local removedOutliers, n = RemoveOutliers(set.list)
            luft.expect(removedOutliers).to.equal(set.remove_outliers)
            luft.expect(removedOutliers).to.not_be(set.remove_outliers) -- should copy the list
        end
    end)
end)

luft.finish()
