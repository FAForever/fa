-- Test framework
local luft = require "luft"

-- Functions are imported to the global scope...
require "../lua/system/class.lua"
require "../lua/sim/NavDatastructures.lua"

---@param cost number
local function AsLeaf(cost)
    -- Heap computes value of current node using this value
    return { TotalCosts = cost }
end

luft.describe("NavDatastructures", function()
    luft.test("Empty", function()
        local heap = NavHeap()
        luft.expect(heap:IsEmpty()).to.equal(true)
        luft.expect(heap:ExtractMin()).to.be_nil()
    end)

    luft.test("Insert", function()
        local heap = NavHeap()
        local leaf = AsLeaf(42)
        heap:Insert(leaf)

        luft.expect(heap:IsEmpty()).to.equal(false)
        luft.expect(heap:ExtractMin()).to.equal(leaf)
        luft.expect(heap:IsEmpty()).to.equal(true)
    end)

    luft.test("Extract duplicates", function()
        local heap = NavHeap()
        local leaf = AsLeaf(42)

        for _ = 1, 5, 1 do
            heap:Insert(leaf)
        end

        for _ = 1, 5, 1 do
            luft.expect(heap:ExtractMin()).to.equal(leaf)
        end
        luft.expect(heap:IsEmpty()).to.equal(true)
    end)

    luft.test("Extract sorted", function()
        local heap = NavHeap()

        local values = { 25, 16, -9, 36, 49, 64, 89 }
        for _, value in ipairs(values) do
            heap:Insert(AsLeaf(value))
        end

        table.sort(values)
        for _, value in ipairs(values) do
            luft.expect(heap:ExtractMin()).to.equal(AsLeaf(value))
        end
        luft.expect(heap:IsEmpty()).to.equal(true)
    end)

    luft.test("Extract sorted with duplicates", function()
        local heap = NavHeap()

        local values = { 25, 16, 9.1, 16, 36, 25, 49, 64, 89, 9.1 }
        for _, value in ipairs(values) do
            heap:Insert(AsLeaf(value))
        end

        table.sort(values)
        for _, value in ipairs(values) do
            luft.expect(heap:ExtractMin()).to.equal(AsLeaf(value))
        end
        luft.expect(heap:IsEmpty()).to.equal(true)
    end)

    luft.test("Clear", function()
        local heap = NavHeap()

        local values = { 25, 16, 9, 36, 49 }
        for _, value in ipairs(values) do
            heap:Insert(AsLeaf(value))
        end

        heap:Clear()
        luft.expect(heap:IsEmpty()).to.equal(true)
        luft.expect(heap:ExtractMin()).to.be_nil()
    end
    )
end)

-- Make sure to call finish so that any errors will fail the CI!
luft.finish()
