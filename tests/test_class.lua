-- -- Test framework
-- local luft = require "luft"

-- table.empty = function(t)
--     return next(t) == nil
-- end

-- -- Functions are imported to the global scope...
-- require "../lua/system/class.lua"

-- -- Test data
-- local entity_methods = {
--     GetPosition = function() end;
--     GetBlueprint = function() end;
--     GetOrientation = function() end;
--     Destroy = function() end;
--     SetMesh = function() end;
--     GetArmy = function() end;
-- }

-- local unit_methods = {
--     RevertElevation = function() end;
--     ShowBone = function() end;
--     HideBone = function() end;
--     GetCurrentLayer = function() end;
-- }

-- local Exclusions = {
--     __index = true,
--     n = true,
-- }

-- -- convert the 'c class', we boldy assume this works :)
-- ConvertCClassToLuaSimplifiedClass(entity_methods)
-- ConvertCClassToLuaSimplifiedClass(unit_methods)

-- luft.describe("Class system", function()
--     luft.test("Inheritance", function()
--         local Specs = {
--             OnCreate = function() end;
--             OnDestroy = function() end;
--         }

--         -- create an entity class
--         local Entity = Class (entity_methods) (Specs)

--         -- make an instance
--         local instance = Entity()

--         -- confirm the functions are inherited properly from the specifications
--         for k in pairs(Specs) do
--             if not Exclusions[k] then
--                 luft.expect(tostring(instance[k])).to.equal(tostring(Entity[k]))
--             end
--         end

--         -- confirm the functions are inherited properly from the entity methods
--         for k in pairs(entity_methods) do
--             if not Exclusions[k] then
--                 luft.expect(tostring(instance[k])).to.equal(tostring(entity_methods[k]))
--             end
--         end

--         -- check the meta table
--         luft.expect(tostring(getmetatable(instance))).to.equal(tostring(Entity))
--     end)

--     luft.test("Dual inheritance", function()
--         local Specs = {
--             OnCreate = function() end;
--             OnDestroy = function() end;
--         }

--         -- create an entity class
--         local Entity = Class(entity_methods, unit_methods)(Specs)

--         -- make an instance
--         local instance = Entity()

--         -- confirm the functions are inherited properly from the specifications
--         for k in pairs(Specs) do
--             if not Exclusions[k] then
--                 luft.expect(tostring(instance[k])).to.equal(tostring(Entity[k]))
--             end
--         end

--         -- confirm the functions are inherited properly from the entity methods
--         for k in pairs(entity_methods) do
--             if not Exclusions[k] then
--                 luft.expect(tostring(instance[k])).to.equal(tostring(entity_methods[k]))
--             end
--         end

--         -- confirm the functions are inherited properly from the entity methods
--         for k in pairs(unit_methods) do
--             if not Exclusions[k] then
--                 luft.expect(tostring(instance[k])).to.equal(tostring(unit_methods[k]))
--             end
--         end

--         -- check the meta table
--         luft.expect(tostring(getmetatable(instance))).to.equal(tostring(Entity))
--     end)

--     luft.test("Overriding", function()
--         local Specs = {
--             GetPosition = function() end;
--             OnCreate = function() end;
--             OnDestroy = function() end;
--         }

--         -- create an entity class
--         local Entity = Class(entity_methods)(Specs)

--         -- make an instance
--         local instance = Entity()

--         -- confirm the specifications are inherited properly
--         for k in pairs(Specs) do
--             if not Exclusions[k] then
--                 luft.expect(tostring(instance[k])).to.equal(tostring(Entity[k]))
--             end
--         end

--         -- confirm that one function is overridden by the specificiation
--         luft.expect(tostring(instance.GetPosition)).to_not.equal(tostring(entity_methods.GetPosition))
--     end)

--     luft.test("Self value", function()
--         local Specs = {
--             OnCreate = function() end;
--             OnDestroy = function() end;
--         }

--         -- create an entity class
--         local Entity = Class(entity_methods)(Specs)

--         -- make two instances with their own data set
--         local instanceA = Entity()
--         instanceA.Bob = true
--         instanceA.Charlie = true
--         instanceA.Delta = true

--         local instanceB = Entity()
--         instanceB.Bob = false
--         instanceB.Charlie = false
--         instanceB.Delta = false

--         -- confirm the changes of each instance are local
--         for k in pairs(instanceA) do
--             luft.expect(instanceA[k]).to_not.equal(instanceB[k])
--         end
--     end)
-- end)

-- -- Make sure to call finish so that any errors will fail the CI!
-- luft.finish()
