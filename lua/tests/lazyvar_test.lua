require '../tests/testutils.lua'
require '../modules/lazyvar.lua'

local expect_equal
local Create

function test_lazyvars()

    local v0 = Create(5)
    expect_equal(v0(), 5)

    v0:SetValue(10)

    expect_equal(v0(), 10)

    local plus_two_calls = 0

    local v1 = Create()
    v1:SetFunction(function () plus_two_calls = plus_two_calls+1; return v0() + 2 end)

    expect_equal(v1(), 12)
    expect_equal(plus_two_calls, 1)

    expect_equal(v1(), 12)
    expect_equal(plus_two_calls, 1)

    v0:SetValue(20)
    expect_equal(v0(), 20)
    expect_equal(plus_two_calls, 1)
    expect_equal(v1(), 22)
    expect_equal(plus_two_calls, 2)
    expect_equal(v1(), 22)
    expect_equal(plus_two_calls, 2)

    local minus_two_calls = 0

    v1:SetFunction(function () minus_two_calls = minus_two_calls+1; return v0() - 2 end)

    expect_equal(minus_two_calls, 0)

    expect_equal(v1(), 18)
    expect_equal(plus_two_calls, 2)
    expect_equal(minus_two_calls, 1)

    expect_equal(v1(), 18)
    expect_equal(plus_two_calls, 2)
    expect_equal(minus_two_calls, 1)
end

auto_run_unit_tests()