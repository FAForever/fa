require '../tests/testutils.lua'
require '../system/class.lua'


local LOG = print


function test_1()
    C1 = Class {
        a=1,
        b=2,
        c=3,
    }

    C2 = Class {
        a=3,
        d=4,
        e=5
    }

    C3 = Class(C1,C2) {
        a=6,
        b=7,
        e=8
    }

    c3 = C3()

    expect_equal(c3.a, 6)
    expect_equal(c3.b, 7)
    expect_equal(c3.c, 3)
    expect_equal(c3.d, 4)
    expect_equal(c3.e, 8)

    expect_error("Class specification contains indexed elements", Class, { C1, a=1 })
    expect_error("State specification contains indexed elements", State, { C1, a=1 })

    local function setz(c)
        c.z = 3
    end
    expect_error('Attempted to add field "z" after class was defined', setz, C1)
end

function test_2()
    C1 = Class {
        x = 1
    }
    C2a = Class {
        x = 2
    }
    C2b = Class(C1) {
        x = 2
    }
    expect_error("field 'x' is ambiguous", Class(C1,C2a), { })

    C3 = Class(C1,C2a) { x=6 }
    expect_equal(C3.x, 6)

    C4 = Class(C2a,C2b) {}
    expect_equal(C4.x, 2)
end

function test_ambiguous_inheritance()
    C1 = Class {
        x = 'C1',
        S = State { x = 'S1' }
    }
    expect_equal(C1.x, 'C1')
    expect_equal(C1.S.x, 'S1')

    C2 = Class(C1) {}
    expect_equal(C2.x, 'C1')
    expect_equal(C2.S.x, 'S1')

    C3 = Class(C1) { S={x='S3'} }
    expect_equal(C3.x, 'C1')
    expect_equal(C3.S.x, 'S3')

    C4 = Class(C1) { x='S1' }
    expect_equal(C4.x, 'S1')
    expect_equal(C4.S.x, 'S1')

    -- x is not ambiguous within the new class here, but is ambiguous within the new state S
    C5 = Class(C1) { x='C5' }
    expect_equal(C5.x, 'C5')
    expect_equal(C5.S.x, 'S1')
end

function test_state_switching()

    SM1 = Class {
        common = 11,
        what = 'SM1',

        __init = function(self)
            self.log = LogBuffer('',' ')
        end,

        OnEnterState = function(self)
            self.log('<',self.what)
        end,

        OnExitState = function(self)
            self.log(self.what,'>')
        end,

        One = State { what = 'one' },
        Two = State { what = 'two' },
        Three = State {
            OnEnterState = function(self)
                self.log('<enter state Three. How special.')
            end
        },
    }

    expect_equal(SM1.__state, nil)
    expect_equal(SM1.One.__state, 'One')
    expect_equal(SM1.Two.__state, 'Two')
    expect_equal(SM1.Three.__state, 'Three')

    local obj=SM1()
    ChangeState(obj, obj.One)
    ChangeState(obj, 'Two')
    ChangeState(obj, 'Two')
    ChangeState(obj, obj.Three)
    ChangeState(obj, 'One')
    expect_equal(obj.log:Get(), "SM1> <one one> <two two> <enter state Three. How special. SM1> <one ")

    SM2 = Class(SM1) {
        what = 'SM2',
        One = State { }, -- don't inherit from SM1.One, so what='SM2'
        Three = State(SM1.Three) {
            what = 3,
        },
    }
    expect_equal(SM2.what, 'SM2')
    expect_equal(SM2.One.what, 'SM2')
    expect_equal(SM2.Two.what, 'two')
    expect_equal(SM2.Three.what, 3)

    expect_equal(SM2.__state, nil)
    expect_equal(SM2.One.__state, 'One')
    expect_equal(SM2.Two.__state, 'Two')
    expect_equal(SM2.Three.__state, 'Three')

    obj=SM2()
    ChangeState(obj, obj.One)
    ChangeState(obj, 'Two')
    ChangeState(obj, 'Two')
    ChangeState(obj, obj.Three)
    ChangeState(obj, 'One')
    expect_equal(obj.log:Get(), "SM2> <SM2 SM2> <two two> <enter state Three. How special. 3> <SM2 ")
end

function test_gc()

    C1 = Class {
        __mode = 'kv',
        one = {1},
    }

    obj = C1()
    obj.two = {2}

    collectgarbage()

    expect_equal(obj.one[1], 1)
    expect_equal(obj.two, nil)
end


auto_run_unit_tests()
