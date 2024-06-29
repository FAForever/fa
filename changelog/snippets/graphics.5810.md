- (#5810) Rotate every other texture layer in the Terrain301 shader

    By rotating every other texture layer by 30° we can make it harder to spot texture repetition. At the moment the Terrain301 shader is only used by the Sunset biome of the map generator. Hand-made maps don't use it yet, because there is no support in the map editor.
