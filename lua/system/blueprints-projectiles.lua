---@declare-global

-- Origin of tables of a projectile blueprint

-- {
--      Audio = { },                    -- default
--      Categories = { },               -- default
--      CategoriesCount = NUMBER,       -- generated
--      CategoriesHash = { }            -- generated
--      Description = STRING,           -- default
--      Display = { },                  -- default
--      Economy = { },                  -- default
--      General = { },                  -- default
--      Interface = { },                -- default
--      Physics = { },                  -- default
-- }

--- Post-processes the provided projectile blueprint
---@param projectile ProjectileBlueprint
local function PostProcessProjectile(projectile)
    -- create hash tables for quick lookup
    projectile.CategoriesCount = 0
    projectile.CategoriesHash = {}
    if projectile.Categories then
        projectile.CategoriesCount = table.getn(projectile.Categories)
        for _, category in projectile.Categories do
            projectile.CategoriesHash[category] = true
        end
    end

    projectile.CategoriesHash[projectile.BlueprintId] = true

    -- fix desired shooter cap for missiles
    if (projectile.CategoriesHash['MISSILE'] and (not projectile.CategoriesHash['STRATEGIC'])) or projectile.CategoriesHash["TORPEDO"] then
        if not projectile.DesiredShooterCap then
            projectile.DesiredShooterCap = projectile.Defense.Health or 1
        else
            if projectile.DesiredShooterCap != (projectile.Defense.Health or 1) then
                WARN(string.format("Inconsistent shooter cap defined for projectile %s, it should match its health", projectile.BlueprintId))
            end
        end
    end
end

--- Post-processes all the provided projectile blueprints
---@param projectiles ProjectileBlueprint[]
function PostProcessProjectiles(projectiles)
    for _, projectile in projectiles do
        PostProcessProjectile(projectile)
    end
end