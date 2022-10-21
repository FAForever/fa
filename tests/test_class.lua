-- Test framework
local lust = require "lust"

table.empty = function(t)
  return next(t) == nil 
end

-- Functions are imported to the global scope...
require "../lua/system/class.lua"

-- Test data
local entity_methods = {
  GetPosition = function() end,
  GetBlueprint = function() end,
  GetOrientation = function() end,
  Destroy = function() end,
  SetMesh = function() end,
  GetArmy = function() end,
}

local unit_methods = {
  RevertElevation = function() end,
  ShowBone = function() end,
  HideBone = function() end,
  GetCurrentLayer = function() end,
}

local Exclusions = { 
  __index = true,
  n = true,
}

-- convert the 'c class', we boldy assume this works :)
ConvertCClassToLuaSimplifiedClass(entity_methods)
ConvertCClassToLuaSimplifiedClass(unit_methods)

lust.describe(
  "Test class system", 
  function()

    lust.describe(
      "Basic class tests", 
      function()

        lust.it(
          "Basic inheritance", 
          function()

            local Specs = {
              OnCreate = function() end,
              OnDestroy = function() end,
            }

            -- create an entity class
            local Entity = Class (entity_methods) (Specs)

            -- make an instance
            local instance = Entity()

            -- confirm the functions are inherited properly from the specifications
            for k, v in Specs do 
              if not Exclusions[k] then 
                lust.expect(tostring(instance[k])).to.equal(tostring(Entity[k]))
              end
            end

            -- confirm the functions are inherited properly from the entity methods
            for k, v in entity_methods do 
              if not Exclusions[k] then 
                lust.expect(tostring(instance[k])).to.equal(tostring(entity_methods[k]))
              end
            end

            -- check the meta table
            lust.expect(tostring(getmetatable(instance))).to.equal(tostring(Entity))
          end
        )

        lust.it(
          "Basic dual inheritance", 
          function()

            local Specs = {
              OnCreate = function() end,
              OnDestroy = function() end,
            }

            -- create an entity class
            local Entity = Class (entity_methods, unit_methods) (Specs)

            -- make an instance
            local instance = Entity()

            -- confirm the functions are inherited properly from the specifications
            for k, v in Specs do 
              if not Exclusions[k] then 
                lust.expect(tostring(instance[k])).to.equal(tostring(Entity[k]))
              end
            end

            -- confirm the functions are inherited properly from the entity methods
            for k, v in entity_methods do 
              if not Exclusions[k] then 
                lust.expect(tostring(instance[k])).to.equal(tostring(entity_methods[k]))
              end
            end

            -- confirm the functions are inherited properly from the entity methods
            for k, v in unit_methods do 
              if not Exclusions[k] then 
                lust.expect(tostring(instance[k])).to.equal(tostring(unit_methods[k]))
              end
            end

            -- check the meta table
            lust.expect(tostring(getmetatable(instance))).to.equal(tostring(Entity))

            lust.expect(true).to.equal(false)
          end
        )

        lust.it(
          "Basic override", 
          function()

            local Specs = {
              GetPosition = function() end,
              OnCreate = function() end,
              OnDestroy = function() end,
            }

            -- create an entity class
            local Entity = Class (entity_methods) (Specs)

            -- make an instance
            local instance = Entity()

            -- confirm the specifications are inherited properly
            for k, v in Specs do 
              if not Exclusions[k] then 
                lust.expect(tostring(instance[k])).to.equal(tostring(Entity[k]))
              end
            end

            -- confirm that one function is overridden by the specificiation
            lust.expect(tostring(instance.GetPosition)).to_not.equal(tostring(entity_methods.GetPosition))
          end
        )

        lust.it(
          "Basic self value", 
          function()

            local Specs = {
              OnCreate = function() end,
              OnDestroy = function() end,
            }

            -- create an entity class
            local Entity = Class (entity_methods) (Specs)

            -- make two instances with their own data set
            local instanceA = Entity()
            instanceA.Bob = true 
            instanceA.Charlie = true 
            instanceA.Delta = true 

            local instanceB = Entity()
            instanceB.Bob = false 
            instanceB.Charlie = false 
            instanceB.Delta = false 

            -- confirm the changes of each instance are local
            for k, v in instanceA do 
                lust.expect(instanceA[k]).to_not.equal(instanceB[k])
            end
          end
        )
      end
    )
  end
)

-- Make sure to call finish so that any errors will fail the CI!
lust.finish()