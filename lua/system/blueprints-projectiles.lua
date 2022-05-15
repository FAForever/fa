

-- Origin of tables of a projectile blueprint

-- {
--      Audio = { },                    -- default
--      Categories = { },               -- default
--      CategoriesCount = NUMBER,       -- generated
--      CategoriesHash = { }            -- generated
--      Description = STRING,           -- default
--      Display = { },                  -- default
--      Economy = { },                  -- default
--      DoNotCollideList = { },         -- default
--      DoNotCollideListCount = NUMBER, -- generated
--      DoNotCollideListHash = { },     -- generated
--      General = { },                  -- default
--      Interface = { },                -- default
--      Physics = { },                  -- default
-- }

--- Post-processes the provided projectile blueprint
local function PostProcessProjectile(projectile)

    -- create hash tables for quick lookup

    projectile.CategoriesCount = 0
    projectile.CategoriesHash = { }
    if projectile.Categories then 
        projectile.CategoriesCount = table.getn(projectile.Categories)
        for k, category in projectile.Categories do 
            projectile.CategoriesHash[category] = true 
        end
    end

    -- create hash tables for quick lookup

    projectile.DoNotCollideListCount = 0 
    projectile.DoNotCollideListHash = { }
    if projectile.DoNotCollideList then 
        projectile.DoNotCollideListCount = table.getn(projectile.DoNotCollideList)
        for k, category in projectile.DoNotCollideList do 
            projectile.DoNotCollideListHash[category] = true 
        end
    end
end

--- Post-processes all the provided projectile blueprints
function PostProcessProjectiles(projectiles)
    for k, projectile in projectiles do 
        PostProcessProjectile(projectile)
    end
end