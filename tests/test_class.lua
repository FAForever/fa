-- Test framework
local lust = require "lust"

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

local Unit = Class(entity_methods, unit_methods)

lust.describe(
  "Test class system", 
  function()
    lust.describe(
      "Basic class tests", 
      function()
        lust.it(
          "Basic inheritance", 
          function()

            local Entity = Class(entity_methods) {
              OnCreate = function() end,
              OnDestroy = function() end,
            }

            local instance = Entity()

            for k, v in Entity do 
              lust.expect(instance[k]).to.equal(Entity[k])
            end

            for k, v in entity_methods do 
              lust.expect(instance[k]).to.equal(entity_methods[k])
            end
          end
        )
      end
    )
  end
)

-- Make sure to call finish so that any errors will fail the CI!
lust.finish()
