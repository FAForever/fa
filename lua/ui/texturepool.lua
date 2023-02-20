-- An object pool for Bitmap objects.
-- Should you need a largeish number of identical bitmaps for some reason, you may encounter poor
-- performance characteristics if you are forever destroying and creating new ones (the particular
-- situation that inspired the creation of this class was that it would take 300ms to spawn the
-- bitmaps required to show resources in map previews).
-- Instead, initilise a TexturePool with the URL to the target texture, and it'll do object pooling
-- for them in the obvious way.
---@class TexturePool
TexturePool = ClassSimple {
    __init = function(self, textureURL, textureParent, width, height)
        local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

        self.textureURL = textureURL

        -- The object store for this pool.
        local _objects = {}

        -- Get a Bitmap from the pool (creating a new one if required).
        self.Get = function(self)
            -- Try and recycle a Bitmap from the pool...
            local bmp = table.remove(_objects)

            -- ... Make a fresh one if they're all checked out.
            if not bmp then
                -- The caller shall return this Bitmap to us via Dispose, so it actually gets pooled...
                bmp = Bitmap(textureParent, textureURL)
                bmp.Width:Set(width)
                bmp.Height:Set(height)
            end

            bmp.OnHide = nil
            bmp:Show()
            return bmp
        end

        -- Return the given bitmap to the pool.
        self.Dispose = function(self, bmp)
            bmp:Hide()

            -- This effectively "locks" the visibility of this Bitmap so it can't be shown, even if
            -- the parent is shown (stopping the pool contents from appearing if the parent Group
            -- is shown).
            bmp.OnHide = function(self, hidden)
                return true
            end

            table.insert(_objects, bmp)
        end

        -- Dispose of the Bitmap resources held by this object.
        self.Destroy = function(self)
            for i = 1, table.getn(_objects) do
                _objects[i]:Destroy()
            end
        end
    end
}
