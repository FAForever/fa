-- Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--
-- Unit tests for /lua/system/config.lua


require '../tests/testutils.lua'
require '../system/config.lua'


local LOG = print


function test_table_merged()
    local t1 = { x=1, y=2, sub1={z=3}, sub2={w=4} }
    local t2 = { y=5, sub1={a=6}, sub2="Fred" }
    local m12 = table.merged(t1,t2)
    local m21 = table.merged(t2,t1)

    -- check result of merge
    expect_equal(repr(m12), '{ sub1={ a=6, z=3 }, sub2="Fred", x=1, y=5 }')
    expect_equal(repr(m21), '{ sub1={ a=6, z=3 }, sub2={ w=4 }, x=1, y=2 }')

    -- t1 and t2 should not be modified
    expect_equal(repr(t1), '{ sub1={ z=3 }, sub2={ w=4 }, x=1, y=2 }')
    expect_equal(repr(t2), '{ sub1={ a=6 }, sub2="Fred", y=5 }')

    -- state should be shared where possible
    m21.sub2.w = 99
    expect_equal(t1.sub2.w, 99)
end


auto_run_unit_tests()
