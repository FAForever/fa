#define FIDELITY_LOW            0x00
#define FIDELITY_MEDIUM         0x01
#define FIDELITY_HIGH           0x02

#ifdef DIRECT3D10
    typedef uint4 position_t;
#else
    typedef float4 position_t;
#endif

// defined by the engine
float4x4 ViewMatrix;
float4x4 ProjMatrix;
float3 HalfAngle;
float3 CameraPosition;
float3 CameraDirection;
float4x4 ShadowMatrix;
texture ShadowTexture;

// defined by game settings or console commands
int ShadowsEnabled;
float ShadowSize;

// defined in the editor
float3 ShadowFillColor = float3(0,0,0);
float Time;
float LightingMultiplier;
float3 SunDirection;
float3 SunAmbience;
float3 SunColor;
float4 SpecularColor;
texture WaterRamp;
float WaterElevation;
float WaterElevationDeep;
float WaterElevationAbyss;

// masks of stratum layers 1 - 4
texture        UtilityTextureA;

// masks of stratum layers 5 - 8
texture        UtilityTextureB;

// red: wave normal strength
// green: water depth
// blue: ???
// alpha: foam reduction
texture        UtilityTextureC;

// appear to be unused
texture NoiseTexture; 
texture OverlayTexture;

// defined by the engine
float4 NormalMapScale;
float4 NormalMapOffset;
float4 SampleOffset;
float2 ViewportScale;
float2 ViewportOffset;

#define DECLARE_STRATUM(n)                     \
    float4 n##Tile;                            \
    texture n##Texture;                        \
    sampler2D n##Sampler = sampler_state       \
    {                                          \
        Texture   = <n##Texture>;              \
        MipFilter = LINEAR;                    \
        MinFilter = LINEAR;                    \
        MagFilter = LINEAR;                    \
        AddressU  = WRAP;                      \
        AddressV  = WRAP;                      \
    };

DECLARE_STRATUM(LowerAlbedo)
DECLARE_STRATUM(Stratum0Albedo)
DECLARE_STRATUM(Stratum1Albedo)
DECLARE_STRATUM(Stratum2Albedo)
DECLARE_STRATUM(Stratum3Albedo)
DECLARE_STRATUM(Stratum4Albedo)
DECLARE_STRATUM(Stratum5Albedo)
DECLARE_STRATUM(Stratum6Albedo)
DECLARE_STRATUM(Stratum7Albedo)
DECLARE_STRATUM(UpperAlbedo)
DECLARE_STRATUM(LowerNormal)
DECLARE_STRATUM(Stratum0Normal)
DECLARE_STRATUM(Stratum1Normal)
DECLARE_STRATUM(Stratum2Normal)
DECLARE_STRATUM(Stratum3Normal)
DECLARE_STRATUM(Stratum4Normal)
DECLARE_STRATUM(Stratum5Normal)
DECLARE_STRATUM(Stratum6Normal)
DECLARE_STRATUM(Stratum7Normal)
texture     SkirtTexture;
// bicubic 1-d lookup texture
texture BiCubicLookup;
// size of texture we are bicubic sampling
float2 e_x;
float2 e_y;
float2 size_source;
// we want to scale the z-amount by a little bit
// because as we get further from the camera we
// want the terrain to drop down a little so that it doesn't
// intersect with the water plane and cause z-artifacts.
// this is a very empirical value right now
float   TerrainErrorScale = 1.0005;

// defined by the engine
texture NormalTexture;

// defined by the engine, depending on what decal we're rendering
float4x4 DecalMatrix;
float4x4 TangentMatrix;
texture DecalAlbedoTexture;
texture DecalNormalTexture;
texture DecalSpecTexture;
texture DecalMaskTexture;
float DecalAlpha;

// defined by the engine, used to generate texture coordinates
// this is basically 1/mapresolution
float4 TerrainScale; 

// scale of Y coordinate as it's 16-bit
float HeightScale;

struct VS_OUTPUT
{
    float4 mPos                    : POSITION0;
    float4 mTexWT                : TEXCOORD1;
    float4 mTexSS                : TEXCOORD2;
    float4 mShadow              : TEXCOORD3;
    float3 mViewDirection        : TEXCOORD4;
    float4 mTexDecal            : TEXCOORD5;
    // We store some texture scales here to be able to save some memory registers
    // in the pixel shader as the stratumTiles only have one float of actual data,
    // but use four and we are pretty tight on register slots in the new shaders.
    float4 nearScales           : TEXCOORD6;
    float4 farScales            : TEXCOORD7;
};

struct TERRAIN_DEPTH
{
    float4 mPos         : POSITION0;
    float4 mDepth       : TEXCOORD0;
};

samplerCUBE environmentSampler = sampler_state
{
    Texture   = (Stratum7NormalTexture);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
};

#ifdef DIRECT3D10
    sampler2D BiCubicLookupSampler = sampler_state
#else
    sampler1D BiCubicLookupSampler = sampler_state
#endif
{
    Texture = (BiCubicLookup);
    MipFilter = POINT;
    MinFilter = POINT;
    MagFilter = POINT;
    AddressU  = WRAP;
};

sampler2D OverlaySampler = sampler_state
{
    Texture   = (OverlayTexture);
    MipFilter = POINT;
    MinFilter = POINT;
    MagFilter = POINT;
    AddressU  = WRAP;
    AddressV  = WRAP;
};

sampler2D NoiseSampler = sampler_state
{
    Texture   = (NoiseTexture);
    MipFilter = POINT;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
};

sampler2D SkirtSampler = sampler_state
{
    Texture   = (SkirtTexture);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
};

sampler2D ShadowHorizontalBlurSampler = sampler_state
{
    Texture   = (ShadowTexture);
    MipFilter = POINT;
    MinFilter = POINT;
    MagFilter = POINT;
};

sampler2D ShadowVerticalBlurSampler = sampler_state
{
    Texture   = (ShadowTexture);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

sampler2D ShadowSampler = sampler_state
{
    Texture        = (ShadowTexture);
    MipFilter    = LINEAR;
    MinFilter    = LINEAR;
    MagFilter    = LINEAR;
    AddressU    = BORDER;
    AddressV    = BORDER;
#ifndef DIRECT3D10
    BorderColor = 0xFFFFFFFF;
#else
    BorderColor = float4(1,1,1,1);
#endif
};

sampler2D UtilitySamplerA = sampler_state
{
    Texture   = (UtilityTextureA);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

sampler2D UtilitySamplerB = sampler_state
{
    Texture   = (UtilityTextureB);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};
sampler2D UtilitySamplerC = sampler_state
{
    Texture   = (UtilityTextureC);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

sampler WaterRampSampler = sampler_state
{
    Texture = (WaterRamp);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

sampler NormalSampler = sampler_state
{
    Texture   = <NormalTexture>;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

sampler DecalAlbedoSampler = sampler_state
{
    Texture   = <DecalAlbedoTexture>;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

sampler DecalSpecSampler = sampler_state
{
    Texture   = <DecalSpecTexture>;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

sampler DecalNormalSampler = sampler_state
{
    Texture   = <DecalNormalTexture>;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

sampler DecalMaskSampler = sampler_state
{
    Texture   = <DecalMaskTexture>;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

struct VS_IN
{
    float4 Pos   : POSITION;
    float2 Tex1  : TEXCOORD0;
};

struct VS_OUT
{
    float4 Pos   : POSITION;
    float2 Tex1  : TEXCOORD0;
    float2 Tex2  : TEXCOORD1;
};

VS_OUT FixedFuncVS( VS_IN In )
{
    VS_OUT Out = (VS_OUT)0;

    float posX = (In.Pos.x+0.5); // adjust for d3d9 pixel center (centers are not shifted 0.5 for 10)
    float posY = (In.Pos.y+0.5); // ditto
    Out.Pos = float4( 2.0*(posX/ShadowSize)-1.0, 2.0*(posY/ShadowSize)-1, In.Pos.z, In.Pos.w );

    // copy through tex coords
    Out.Tex1 = In.Tex1;
    Out.Tex2 = In.Tex1;

    return Out;
}

bool IsExperimentalShader() {
    // The tile value basically says how often the texture gets repeated on the map.
    // A value less than one doesn't make sense under normal conditions, so it is
    // relatively save to use it as our switch.

    // in order to trigger this you can set the albedo scale to be bigger than the map 
    // size. Use the value 10000 to be safe for any map
    return UpperAlbedoTile.x < 1.0;
}

// sample a texture that is another buffer the same size as the one
// we are rendering into and with the viewport setup the same way.
float4 SampleScreen(sampler inSampler, float4 inTex)
{
    inTex.xy *=  ViewportScale;
    inTex.xy += (ViewportOffset * inTex.w);
    return tex2Dproj( inSampler, inTex );
}

// return the inPos in homogenous space
float4 calculateHomogenousCoordinate(float4 inPos)
{
    // get the vertex into viewspace
    float4 viewSpace = mul(inPos, ViewMatrix);

    // now we want to scale the z-amount by a little bit
    // because as we get further from the camera we
    // want the terrain to drop down a little so that it doesn't
    // intersect with the water plane
    viewSpace.xyz *= TerrainErrorScale;

    // calculate position
    return mul( viewSpace, ProjMatrix  );
}

//--------------------------------------------------------------------------------------
// Compute the attenuation due to shadowing using the variance shadow map
//--------------------------------------------------------------------------------------
float ComputeShadow( float4 vShadowCoord )
{
    vShadowCoord.xy /= vShadowCoord.w;
    return tex2D( ShadowSampler, vShadowCoord ).g;
}

// apply the water color
float3 ApplyWaterColor(float terrainHeight, float depth, float3 inColor)
{
    if (depth > 0) {
        // With this extra check we get rid of unwanted coloration on steep cliffs when zoomed in,
        // but we prevent that terrain tesselation swallows too much of the water when zoomed out
        float opacity = saturate(smoothstep(10, 200, CameraPosition.y - WaterElevation) + step(terrainHeight, WaterElevation));
        float4 wcolor = tex1D(WaterRampSampler, depth);
        inColor = lerp(inColor.xyz, wcolor.xyz, wcolor.w * opacity);
    }
    return inColor;
}

float3 ApplyWaterColorExponentially(float3 viewDirection, float terrainHeight, float waterDepth, float3 color)
{
    if (waterDepth > 0) {
        float opacity = saturate(smoothstep(10, 200, CameraPosition.y - WaterElevation) + step(terrainHeight, WaterElevation));
        float3 up = float3(0,1,0);
        // this is the length that the light travels underwater back to the camera
        float oneOverCosV = 1 / max(dot(up, normalize(viewDirection)), 0.0001);
        // Light gets absorbed exponentially,
        // to simplify, we assume that the light enters vertically into the water.
        // We need to multiply by 2 to reach 98% absorption as the waterDepth can't go over 1.
        float waterAbsorption = 1 - saturate(exp(-waterDepth * 2 * (1 + oneOverCosV)));
        // darken the color first to simulate the light absorption on the way in and out
        color *= 1 - waterAbsorption * opacity;
        // lerp in the watercolor to simulate the scattered light from the dirty water
        float4 waterColor = tex1D(WaterRampSampler, waterAbsorption);
        color = lerp(color, waterColor.rgb, waterAbsorption * opacity);
    }
    return color;
}

// calculate the lit pixels
float4 CalculateLighting( float3 inNormal, float3 inViewPosition, float3 inAlbedo, float specAmount, float waterDepth, float4 inShadow, uniform bool inShadows)
{
    float4 color = float4( 0, 0, 0, 0 );

    float shadow = ( inShadows && ( 1 == ShadowsEnabled ) ) ? ComputeShadow( inShadow ) : 1;
    if (IsExperimentalShader()) {
        float3 position = TerrainScale * inViewPosition;
        float mapShadow = tex2D(UpperAlbedoSampler, position.xy).w;
        shadow = shadow * mapShadow;
    }

    // calculate some specular
    float3 viewDirection = normalize(inViewPosition.xzy-CameraPosition);

    float SunDotNormal = dot( SunDirection, inNormal);
    float3 R = SunDirection - 2.0f * SunDotNormal * inNormal;
    float specular = pow( saturate( dot(R, viewDirection) ), 80) * SpecularColor.x * specAmount;

    float3 light = SunColor * saturate( SunDotNormal) * shadow + SunAmbience + specular;
    light = LightingMultiplier * light + ShadowFillColor * ( 1 - light );
    color.rgb = light * inAlbedo;

    if (IsExperimentalShader()) {
        color.rgb = ApplyWaterColorExponentially(-viewDirection, inViewPosition.z, waterDepth, color);
    } else {
        color.rgb = ApplyWaterColor(inViewPosition.z, waterDepth, color);
    }

    color.a = 0.01f + (specular*SpecularColor.w);
    return color;
}

const float PI = 3.14159265359;

float3 FresnelSchlick(float hDotN, float3 F0)
{
    return F0 + (1.0 - F0) * pow(1.0 - hDotN, 5.0);
}

float NormalDistribution(float3 n, float3 h, float roughness)
{
    float a2 = roughness*roughness;
    float nDotH = max(dot(n, h), 0.0);
    float nDotH2 = nDotH*nDotH;

    float num = a2;
    float denom = nDotH2 * (a2 - 1.0) + 1.0;
    denom = PI * denom * denom;

    return num / denom;
}

float GeometrySchlick(float nDotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;

    float num = nDotV;
    float denom = nDotV * (1.0 - k) + k;

    return num / denom;
}

float GeometrySmith(float3 n, float nDotV, float3 l, float roughness)
{
    float nDotL = max(dot(n, l), 0.0);
    float gs2 = GeometrySchlick(nDotV, roughness);
    float gs1 = GeometrySchlick(nDotL, roughness);

    return gs1 * gs2;
}

float3 PBR(VS_OUTPUT inV, float4 position, float3 albedo, float3 n, float roughness, float waterDepth) {
    // See https://blog.selfshadow.com/publications/s2013-shading-course/

    float shadow = 1;
    if (ShadowsEnabled == 1) {
        float mapShadow = tex2D(UpperAlbedoSampler, position.xy).w; // 1 where sun is, 0 where shadow is
        shadow = tex2D(ShadowSampler, inV.mShadow.xy).g; // 1 where sun is, 0 where shadow is
        shadow *= mapShadow;
    }

    float facingSpecular = 0.04;
    // using only the texture looks bad when zoomed in, using only the mesh 
    // looks bad when zoomed out, so we interpolate between both
    float underwater = lerp(step(inV.mTexWT.z, WaterElevation), saturate(waterDepth * 20), smoothstep(10, 200, CameraPosition.y - WaterElevation));
    facingSpecular *= 1 - 0.9 * underwater;

    float3 v = normalize(-inV.mViewDirection);
    float3 F0 = float3(facingSpecular, facingSpecular, facingSpecular);
    float3 l = SunDirection;
    float3 h = normalize(v + l);
    float nDotL = max(dot(n, l), 0.0);
    // Normal maps can cause an angle > 90° betweeen n and v which would 
    // cause artifacts if we don't take some countermeasures
    float nDotV = abs(dot(n, v)) + 0.001;
    float3 sunLight = SunColor * LightingMultiplier * shadow;

    // Cook-Torrance BRDF
    float3 F = FresnelSchlick(max(dot(h, v), 0.0), F0);
    float NDF = NormalDistribution(n, h, roughness);
    float G = GeometrySmith(n, nDotV, l, roughness);

    // For point lights we need to multiply with Pi
    float3 numerator = PI * NDF * G * F;
    // add 0.0001 to avoid division by zero
    float denominator = 4.0 * nDotV * nDotL + 0.0001;
    float3 reflected = numerator / denominator;
    
    float3 kD = float3(1.0, 1.0, 1.0) - F;	
    float3 refracted = kD * albedo;
    float3 irradiance = sunLight * nDotL;
    float3 color = (refracted + reflected) * irradiance;

    float3 shadowColor = (1 - (SunColor * shadow * nDotL + SunAmbience)) * ShadowFillColor;
    float3 ambient = SunAmbience * LightingMultiplier + shadowColor;

    // we simplify here for the ambient lighting
    color += albedo * ambient;

    // While it would be nice to be more sophisticated here by sampling the
    // environment map and making correct specular calculations with the
    // BRDF lookup texture, there are several problems:
    // We can't access that lookup texture and we run into the shader limit
    // of 16 different texture samplers per shader.
    // Luckily, ground is generally pretty rough, so specular reflections of
    // the environment are not that noticeable and we still have the specular
    // reflections of the sun, which does most of the visual work.
    // It's a bit sad that we can't use the env map to truely match the lighting
    // of the mesh shader, but the alternative would be to sacrifice one albedo
    // slot or to sacrifice water rendering.
    // In the future we could write another shader that does exactly this, so
    // mappers can choose to use that if they want to make a shiny map.

    // used textures:
    // lowerAlbedo
    // Albedo stratum 0-7
    // upperAlbedo
    // NormalTexture
    // ShadowTexture
    // UtilityTextureA
    // UtilityTextureB
    // UtilityTextureC
    // WaterRamp

    return color;
}

TERRAIN_DEPTH TerrainDepthVS( position_t p : POSITION0)
{
    TERRAIN_DEPTH result;

    float4 position = HeightScale * float4(p);
    position.y *= HeightScale;

    result.mPos = mul(position,mul(ViewMatrix,ProjMatrix));
    result.mDepth = result.mPos;

    return result;
}

float4 TerrainDepthPS( TERRAIN_DEPTH inDepth) : COLOR0
{
    return float4(inDepth.mDepth.z,1,0,1); // D24S8
}

//--------------------------------------------------------------------------------------
// Copy depth to variance and perform the horizontal portion of a two-pass
// separable 5x5 Gaussian blur
//--------------------------------------------------------------------------------------
float4 HorizontalBlurDepthToVariancePS( float4 Pos : POSITION,
                                        float2 uv  : TEXCOORD0 ) : COLOR0
{
    // Fetch a row of 5 pixels from the D24S8 depth map
    float4 Depth0123;
    float  Depth4;

    float texel = 1.0f / ShadowSize;
    Depth0123.x = tex2D( ShadowHorizontalBlurSampler, float2( uv.x - (2.0f*texel), uv.y) ).g;
    Depth0123.y = tex2D( ShadowHorizontalBlurSampler, float2( uv.x - (1.0f*texel), uv.y) ).g;
    Depth0123.z = tex2D( ShadowHorizontalBlurSampler, uv ).g;
    Depth0123.w = tex2D( ShadowHorizontalBlurSampler, float2( uv.x + (1.0f*texel), uv.y) ).g;
    Depth4      = tex2D( ShadowHorizontalBlurSampler, float2( uv.x + (2.0f*texel), uv.y) ).g;

    // Do the Guassian blur (using a 5-tap filter kernel of [ 1 4 6 4 1 ] )
    float z = dot( Depth0123.xyzw,  float4( 1.0/16, 4.0/16, 6.0/16, 4.0/16 ) ) + Depth4 * ( 1.0 / 16 );
    return float4( z, z, 0, 0 );
}


//--------------------------------------------------------------------------------------
// Vertical portion of a two-pass separable 5x5 Gaussian blur for variance shadow maps
//--------------------------------------------------------------------------------------
float4 VerticalBlurDepthToVariancePS( float4 Pos : POSITION,
                                      float2 uv  : TEXCOORD0 ) : COLOR0
{
    // Note that this second pass of the separable filter can use filtered fetches
    // Fetch 4 samples which filter across a column of 5 pixels from the VSM
    float4 t0, t1;

    float texel = 1.0f / ShadowSize;
    t0.xy = tex2D( ShadowVerticalBlurSampler, float2( uv.x, uv.y + (1.5f*texel)) ).g;
    t0.zw = tex2D( ShadowVerticalBlurSampler, float2( uv.x, uv.y + (0.5f*texel)) ).g;
    t1.xy = tex2D( ShadowVerticalBlurSampler, float2( uv.x, uv.y - (0.5f*texel)) ).g;
    t1.zw = tex2D( ShadowVerticalBlurSampler, float2( uv.x, uv.y - (1.5f*texel)) ).g;

    // Sum results with Gaussian weights
    float z  = dot( float4( t0.x, t0.z, t1.x, t1.z ), float4( 2.0/16, 6.0/16, 6.0/16, 2.0/16 ) );
    return float4( z, z, 0, 0 );
}

VS_OUTPUT TerrainVS( position_t p : POSITION0, uniform bool shadowed)
{
    VS_OUTPUT result;

    result.nearScales = float4(Stratum0AlbedoTile.x, Stratum1AlbedoTile.x, Stratum2AlbedoTile.x, Stratum3AlbedoTile.x);
    result.farScales =  float4(Stratum0NormalTile.x, Stratum1NormalTile.x, Stratum2NormalTile.x, Stratum3NormalTile.x);

    float4 position = float4(p);
    position.y *= HeightScale;

    // calculate output position
    result.mPos = calculateHomogenousCoordinate(position);

    // calculate 0..1 uv based on size of map
    result.mTexWT = position.xzyw;
    // caluclate screen space coordinate for sample a frame buffer of this size
    result.mTexSS = result.mPos;
    result.mTexDecal = float4(0,0,0,0);

    result.mViewDirection = normalize(position.xyz-CameraPosition.xyz);

    // if we have shadows enabled fill in the tex coordinate for the shadow projection
    if ( shadowed && ( 1 == ShadowsEnabled ))
    {
        result.mShadow = mul(position,ShadowMatrix);
        result.mShadow.x = ( +result.mShadow.x + result.mShadow.w ) * 0.5;
        result.mShadow.y = ( -result.mShadow.y + result.mShadow.w ) * 0.5;
        result.mShadow.z -= 0.01f; // put epsilon in vs to save ps instruction
    }
    else
    {
        result.mShadow = float4( 0, 0, 0, 1);
    }

    return result;
}

VS_OUTPUT TerrainGlowVS( position_t p : POSITION0, uniform bool shadowed)
{
    VS_OUTPUT result;

    result.nearScales = float4(Stratum0AlbedoTile.x, Stratum1AlbedoTile.x, Stratum2AlbedoTile.x, Stratum3AlbedoTile.x);
    result.farScales =  float4(Stratum0NormalTile.x, Stratum1NormalTile.x, Stratum2NormalTile.x, Stratum3NormalTile.x);

    float4 position = float4(p);
    position.y *= HeightScale;

    // calculate output position
    result.mPos = calculateHomogenousCoordinate(position);

    // calculate 0..1 uv based on size of map
    result.mTexWT = position.xzyw;
    // caluclate screen space coordinate for sample a frame buffer of this size
    result.mTexSS = result.mPos;

    result.mViewDirection = normalize(position.xyz-CameraPosition.xyz);

    //    setup some animated texture coordinates
    float4 offset = float4(0,0,0,0);
    sincos(Time * 0.125, offset.x, offset.y);
    offset *= 0.01;
    result.mTexDecal = offset;

    // if we have shadows enabled fill in the tex coordinate for the shadow projection
    if ( shadowed && ( 1 == ShadowsEnabled ))
    {
        result.mShadow = mul(position,ShadowMatrix);
        result.mShadow.x = ( +result.mShadow.x + result.mShadow.w ) * 0.5;
        result.mShadow.y = ( -result.mShadow.y + result.mShadow.w ) * 0.5;
        result.mShadow.z -= 0.01f; // put epsilon in vs to save ps instruction
    }
    else
    {
        result.mShadow = float4( 0, 0, 0, 1);
    }

    return result;
}



VS_OUTPUT TerrainSkirtVS( position_t p : POSITION0)
{
    VS_OUTPUT result;

    result.nearScales = float4(Stratum0AlbedoTile.x, Stratum1AlbedoTile.x, Stratum2AlbedoTile.x, Stratum3AlbedoTile.x);
    result.farScales =  float4(Stratum0NormalTile.x, Stratum1NormalTile.x, Stratum2NormalTile.x, Stratum3NormalTile.x);

    float4 position = float4(p);
    position.y *= HeightScale;

    // calculate output position
    result.mPos = calculateHomogenousCoordinate(position);

    // calculate 0..1 uv based on size of map
    result.mTexWT = position.xzyw;
    // caluclate screen space coordinate for sample a frame buffer of this size
    result.mTexSS = float4(0,0,0,0);
    result.mTexDecal = position.xzyw * TerrainScale;
    result.mShadow = float4( 0, 0, 0, 0);
    result.mViewDirection = normalize(position.xyz-CameraPosition.xyz);

    return result;
}

VS_OUTPUT TerrainFogVS( position_t p : POSITION0)
{

    VS_OUTPUT result;

    result.nearScales = float4(Stratum0AlbedoTile.x, Stratum1AlbedoTile.x, Stratum2AlbedoTile.x, Stratum3AlbedoTile.x);
    result.farScales =  float4(Stratum0NormalTile.x, Stratum1NormalTile.x, Stratum2NormalTile.x, Stratum3NormalTile.x);

    float4 position = float4(p);
    position.y *= HeightScale;

#if 1
    if( position.y < WaterElevation )
        position.y = WaterElevation + 0.0001;
#endif

    // calculate output position
    result.mPos = calculateHomogenousCoordinate(position) - float4(0,0,0.0001,0);

    // calculate 0..1 uv based on size of map
    result.mTexWT = position.xzyw;
    // caluclate screen space coordinate for sample a frame buffer of this size
    result.mTexSS = float4(0,0,0,0);
    result.mTexDecal = position.xzyw * TerrainScale;
    result.mShadow = float4( 0, 0, 0, 0);
    result.mViewDirection = normalize(position.xyz-CameraPosition.xyz);

    return result;
}



float4 TerrainSkirtPS( VS_OUTPUT inV ) : COLOR
{
    return float4(0.1,0.1,0.1,0);
}



float4 TerrainNormalsPS( VS_OUTPUT inV ) : COLOR
{
    // sample all the textures we'll need
    float4 mask = saturate(tex2D( UtilitySamplerA, inV.mTexWT * TerrainScale));

    float4 lowerNormal = normalize(tex2D( LowerNormalSampler, inV.mTexWT  * TerrainScale * LowerNormalTile ) * 2 - 1);
    float4 stratum0Normal = normalize(tex2D( Stratum0NormalSampler, inV.mTexWT  * TerrainScale * Stratum0NormalTile ) * 2 - 1);
    float4 stratum1Normal = normalize(tex2D( Stratum1NormalSampler, inV.mTexWT  * TerrainScale * Stratum1NormalTile ) * 2 - 1);
    float4 stratum2Normal = normalize(tex2D( Stratum2NormalSampler, inV.mTexWT  * TerrainScale * Stratum2NormalTile ) * 2 - 1);
    float4 stratum3Normal = normalize(tex2D( Stratum3NormalSampler, inV.mTexWT  * TerrainScale * Stratum3NormalTile ) * 2 - 1);

    // blend all normals together
    float4 normal = lowerNormal;
    normal = lerp( normal, stratum0Normal, mask.x );
    normal = lerp( normal, stratum1Normal, mask.y );
    normal = lerp( normal, stratum2Normal, mask.z );
    normal = lerp( normal, stratum3Normal, mask.w );
    normal.xyz = normalize( normal.xyz );

    return float4( (normal.xyz * 0.5 + 0.5) , normal.w);
}

float4 TerrainNormalsXP( VS_OUTPUT pixel ) : COLOR
{
    float4 mask0 = saturate(tex2D(UtilitySamplerA,pixel.mTexWT*TerrainScale));
    float4 mask1 = saturate(tex2D(UtilitySamplerB,pixel.mTexWT*TerrainScale));

    float4 lowerNormal = normalize(tex2D(LowerNormalSampler,pixel.mTexWT*TerrainScale*LowerNormalTile)*2-1);
    float4 stratum0Normal = normalize(tex2D(Stratum0NormalSampler,pixel.mTexWT*TerrainScale*Stratum0NormalTile)*2-1);
    float4 stratum1Normal = normalize(tex2D(Stratum1NormalSampler,pixel.mTexWT*TerrainScale*Stratum1NormalTile)*2-1);
    float4 stratum2Normal = normalize(tex2D(Stratum2NormalSampler,pixel.mTexWT*TerrainScale*Stratum2NormalTile)*2-1);
    float4 stratum3Normal = normalize(tex2D(Stratum3NormalSampler,pixel.mTexWT*TerrainScale*Stratum3NormalTile)*2-1);
    float4 stratum4Normal = normalize(tex2D(Stratum4NormalSampler,pixel.mTexWT*TerrainScale*Stratum4NormalTile)*2-1);
    float4 stratum5Normal = normalize(tex2D(Stratum5NormalSampler,pixel.mTexWT*TerrainScale*Stratum5NormalTile)*2-1);
    float4 stratum6Normal = normalize(tex2D(Stratum6NormalSampler,pixel.mTexWT*TerrainScale*Stratum6NormalTile)*2-1);
    float4 stratum7Normal = normalize(tex2D(Stratum7NormalSampler,pixel.mTexWT*TerrainScale*Stratum7NormalTile)*2-1);

    float4 normal = lowerNormal;
    normal = lerp(normal,stratum0Normal,mask0.x);
    normal = lerp(normal,stratum1Normal,mask0.y);
    normal = lerp(normal,stratum2Normal,mask0.z);
    normal = lerp(normal,stratum3Normal,mask0.w);
    normal = lerp(normal,stratum4Normal,mask1.x);
    normal = lerp(normal,stratum5Normal,mask1.y);
    normal = lerp(normal,stratum6Normal,mask1.z);
    normal = lerp(normal,stratum7Normal,mask1.w);
    normal.xyz = normalize( normal.xyz );

    return float4( (normal.xyz * 0.5 + 0.5) , normal.w);
}

// render the basis out to the blue, alpha channels
float4 TerrainBasisPS( VS_OUTPUT inV ) : COLOR
{
    return tex2Dproj( UtilitySamplerA, inV.mTexWT * TerrainScale * NormalMapScale + NormalMapOffset ).xxwy;
}

// render the basis out to the buffer but sample it using a bi-cubic filter
// special thanks to Sigg and Hadwiger GPU Gems 2 pg 313
float4 TerrainBasisPSBiCubic( VS_OUTPUT inV ) : COLOR
{
    float4 result;
    if (IsExperimentalShader()) {
        float4 position = TerrainScale * inV.mTexWT;
        result = (float4(1, 1, tex2D(UpperAlbedoSampler, position.xy).xy));
    } else {
        float2 coord_source = (inV.mTexWT * TerrainScale * NormalMapScale + NormalMapOffset).xy;
        float2 coord_hg = coord_source * size_source - float2(0.5, 0.5);

        // fetch offsets and weights from filter texture
    #ifdef DIRECT3D10
        // force to a 2d lookup for d3d10 since d3d10 is much stricter when enforcing
        // 1d lookups from 2d textures
        float3 hg_x = tex2D(BiCubicLookupSampler, float2(coord_hg.x,0)).xyz;
        float3 hg_y = tex2D(BiCubicLookupSampler, float2(coord_hg.y,0)).xyz;
    #else
        float3 hg_x = tex1D(BiCubicLookupSampler, coord_hg.x).xyz;
        float3 hg_y = tex1D(BiCubicLookupSampler, coord_hg.y).xyz;
    #endif

        // determine linear sampling coordinates
        float2 coord_source10 = coord_source + hg_x.x * e_x;
        float2 coord_source00 = coord_source - hg_x.y * e_x;
        float2 coord_source11 = coord_source10 + hg_y.x * e_y;
        float2 coord_source01 = coord_source00 + hg_y.x * e_y;
        coord_source10 = coord_source10 - hg_y.y * e_y;
        coord_source00 = coord_source00 - hg_y.y * e_y;

        // fetch the samples from the appropriate spot on the texture
        float4 tex_source00 = tex2D( UtilitySamplerA, coord_source00 );
        float4 tex_source10 = tex2D( UtilitySamplerA, coord_source10 );
        float4 tex_source01 = tex2D( UtilitySamplerA, coord_source01 );
        float4 tex_source11 = tex2D( UtilitySamplerA, coord_source11 );

        // weight along y direction
        tex_source00 = lerp(tex_source00, tex_source01, hg_y.z );
        tex_source10 = lerp(tex_source10, tex_source11, hg_y.z );

        // weight along x direction
        tex_source00 = lerp(tex_source00, tex_source10, hg_x.z );

        // remember we are only writing into the blue and alpha channels.
        // we can probably optimize our lerps above by taking advantage of the fact that
        // we only have 2 channels.
        result = tex_source00.xxwy;
    }
    return result;
}


float4 TerrainPS( VS_OUTPUT inV, uniform bool inShadows ) : COLOR
{
    // sample all the textures we'll need
    float4 mask = saturate(tex2Dproj( UtilitySamplerA, inV.mTexWT  * TerrainScale)* 2 - 1 );
    float4 upperAlbedo = tex2Dproj( UpperAlbedoSampler, inV.mTexWT  * TerrainScale* UpperAlbedoTile );
    float4 lowerAlbedo = tex2Dproj( LowerAlbedoSampler, inV.mTexWT  * TerrainScale* LowerAlbedoTile );
    float4 stratum0Albedo = tex2Dproj( Stratum0AlbedoSampler, inV.mTexWT  * TerrainScale* Stratum0AlbedoTile );
    float4 stratum1Albedo = tex2Dproj( Stratum1AlbedoSampler, inV.mTexWT  * TerrainScale* Stratum1AlbedoTile );
    float4 stratum2Albedo = tex2Dproj( Stratum2AlbedoSampler, inV.mTexWT  * TerrainScale* Stratum2AlbedoTile );
    float4 stratum3Albedo = tex2Dproj( Stratum3AlbedoSampler, inV.mTexWT  * TerrainScale* Stratum3AlbedoTile );

    float3 normal = SampleScreen(NormalSampler, inV.mTexSS).xyz*2-1;

    // blend all albedos together
    float4 albedo = lowerAlbedo;
    albedo = lerp( albedo, stratum0Albedo, mask.x );
    albedo = lerp( albedo, stratum1Albedo, mask.y );
    albedo = lerp( albedo, stratum2Albedo, mask.z );
    albedo = lerp( albedo, stratum3Albedo, mask.w );
    albedo.xyz = lerp( albedo.xyz, upperAlbedo.xyz, upperAlbedo.w );

    // get the water depth
    float waterDepth = tex2Dproj( UtilitySamplerC, inV.mTexWT * TerrainScale).g;

    // calculate the lit pixel
    float4 outColor = CalculateLighting( normal, inV.mTexWT.xyz, albedo.xyz, 1-albedo.w, waterDepth, inV.mShadow, inShadows);

    return outColor;
}

float4 TerrainAlbedoXP( VS_OUTPUT pixel) : COLOR
{
    float4 position = TerrainScale*pixel.mTexWT;

    float4 mask0 = saturate(tex2Dproj(UtilitySamplerA,position)*2-1);
    float4 mask1 = saturate(tex2Dproj(UtilitySamplerB,position)*2-1);

    float4 lowerAlbedo = tex2Dproj(LowerAlbedoSampler,position*LowerAlbedoTile);
    float4 stratum0Albedo = tex2Dproj(Stratum0AlbedoSampler,position*Stratum0AlbedoTile);
    float4 stratum1Albedo = tex2Dproj(Stratum1AlbedoSampler,position*Stratum1AlbedoTile);
    float4 stratum2Albedo = tex2Dproj(Stratum2AlbedoSampler,position*Stratum2AlbedoTile);
    float4 stratum3Albedo = tex2Dproj(Stratum3AlbedoSampler,position*Stratum3AlbedoTile);
    float4 stratum4Albedo = tex2Dproj(Stratum4AlbedoSampler,position*Stratum4AlbedoTile);
    float4 stratum5Albedo = tex2Dproj(Stratum5AlbedoSampler,position*Stratum5AlbedoTile);
    float4 stratum6Albedo = tex2Dproj(Stratum6AlbedoSampler,position*Stratum6AlbedoTile);
    float4 stratum7Albedo = tex2Dproj(Stratum7AlbedoSampler,position*Stratum7AlbedoTile);
    float4 upperAlbedo = tex2Dproj(UpperAlbedoSampler,position*UpperAlbedoTile);

    float4 albedo = lowerAlbedo;
    albedo = lerp(albedo,stratum0Albedo,mask0.x);
    albedo = lerp(albedo,stratum1Albedo,mask0.y);
    albedo = lerp(albedo,stratum2Albedo,mask0.z);
    albedo = lerp(albedo,stratum3Albedo,mask0.w);
    albedo = lerp(albedo,stratum4Albedo,mask1.x);
    albedo = lerp(albedo,stratum5Albedo,mask1.y);
    albedo = lerp(albedo,stratum6Albedo,mask1.z);
    albedo = lerp(albedo,stratum7Albedo,mask1.w);
    albedo.rgb = lerp(albedo.xyz,upperAlbedo.xyz,upperAlbedo.w);

    float3 normal = normalize(2*SampleScreen(NormalSampler,pixel.mTexSS).xyz-1);
    
    float3 r = reflect(normalize(pixel.mViewDirection),normal);
    float3 specular = pow(saturate(dot(r,SunDirection)),80)*albedo.aaa*SpecularColor.a*SpecularColor.rgb;

    float dotSunNormal = dot(SunDirection,normal);

    float shadow = tex2D(ShadowSampler,pixel.mShadow.xy).g;
    float3 light = SunColor*saturate(dotSunNormal)*shadow + SunAmbience;
    light = LightingMultiplier*light + ShadowFillColor*(1-light);
    albedo.rgb = light * ( albedo.rgb + specular.rgb );

    float waterDepth = tex2Dproj(UtilitySamplerC,pixel.mTexWT*TerrainScale).g;
    albedo.rgb = ApplyWaterColor(pixel.mTexWT.z, waterDepth, albedo.rgb);

    return float4(albedo.rgb, 0.01f);
}

float4 TerrainGlowPS( VS_OUTPUT inV, uniform bool inShadows ) : COLOR
{
    // sample all the textures we'll need
    float4 mask = saturate(tex2Dproj( UtilitySamplerA, inV.mTexWT  * TerrainScale)* 2 - 1 );
    float4 upperAlbedo = tex2Dproj( UpperAlbedoSampler, inV.mTexWT  * TerrainScale* UpperAlbedoTile );
    float4 lowerAlbedo = tex2Dproj( LowerAlbedoSampler, inV.mTexWT  * TerrainScale* LowerAlbedoTile );
    float4 stratum0Albedo = tex2Dproj( Stratum0AlbedoSampler, inV.mTexWT  * TerrainScale* Stratum0AlbedoTile );
    // grab our animated texture coordinates
    float4 offset = inV.mTexDecal;
    float4 stratum1Albedo = tex2Dproj( Stratum1AlbedoSampler, (inV.mTexWT  * TerrainScale* Stratum1AlbedoTile)+offset);
    float glow = tex2Dproj( Stratum1AlbedoSampler, (inV.mTexWT  * TerrainScale* Stratum1AlbedoTile)+offset.yxzw ).a;
    stratum1Albedo.a = 0;
    float4 stratum2Albedo = tex2Dproj( Stratum2AlbedoSampler, inV.mTexWT  * TerrainScale* Stratum2AlbedoTile );
    float4 stratum3Albedo = tex2Dproj( Stratum3AlbedoSampler, inV.mTexWT  * TerrainScale* Stratum3AlbedoTile );

    float3 normal = SampleScreen(NormalSampler, inV.mTexSS).xyz*2-1;

    // blend all albedos together
    float4 albedo = lowerAlbedo;
    albedo = lerp( albedo, stratum0Albedo, mask.x );
    albedo = lerp( albedo, stratum1Albedo, mask.y );
    albedo = lerp( albedo, stratum2Albedo, mask.z );
    albedo = lerp( albedo, stratum3Albedo, mask.w );
    albedo.xyz = lerp( albedo.xyz, upperAlbedo.xyz, upperAlbedo.w );

    // get the water depth
    float waterDepth = tex2Dproj( UtilitySamplerC, inV.mTexWT * TerrainScale).g;

    // calculate the lit pixel
    float4 outColor = CalculateLighting( normal, inV.mTexWT.xyz, albedo.xyz, 1-albedo.w, waterDepth, inV.mShadow, inShadows);

    // output the glow amount
    outColor.a = glow * mask.y + 0.01;

    return outColor;
}


float4 TerrainOverlayPS( VS_OUTPUT inV ) : COLOR
{
    // sample all the textures we'll need
    float4 overlayColor = tex2Dproj( OverlaySampler, inV.mTexWT * TerrainScale);
    return overlayColor;
}

technique TTerrainDepth
{
    pass P0
    {
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 TerrainDepthVS();
        PixelShader = compile ps_2_0 TerrainDepthPS();
    }
}

technique THorizontalBlurDepthToVariance
{
    pass P0
    {
        DepthState( Depth_Disable_Write_None )
        RasterizerState( Rasterizer_Cull_None )

        VertexShader = FIXED_FUNC_VS;
        PixelShader = compile ps_2_0 HorizontalBlurDepthToVariancePS();
    }
}

technique TVerticalBlurDepthToVariance
{
    pass P0
    {
        DepthState( Depth_Disable_Write_None )
        RasterizerState( Rasterizer_Cull_None )

        VertexShader = FIXED_FUNC_VS;
        PixelShader = compile ps_2_0 VerticalBlurDepthToVariancePS();
    }
}

technique TTerrain <
    string usage = "composite";
    string normals = "TTerrainNormals";
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 TerrainVS( true );
        PixelShader = compile ps_2_a TerrainPS( true);
    }
}

technique TTerrainXP <
    string usage = "composite";
    string normals = "TTerrainNormalsXP";
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 TerrainVS(true);
        PixelShader = compile ps_2_a TerrainAlbedoXP();
    }
}

// Terrain where the the 1st strata texture's alpha
// is animated and used as a glow channel
technique TTerrainGlow <
    string usage = "composite";
    string normals = "TTerrainNormals";
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 TerrainGlowVS( true );
        PixelShader = compile ps_2_a TerrainGlowPS( true);
    }
}



technique TTerrainNormals
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RG )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 TerrainVS( false );
        PixelShader = compile ps_2_0 TerrainNormalsPS();
    }
}

technique TTerrainNormalsXP
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RG )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 TerrainVS( false );
        PixelShader = compile ps_2_0 TerrainNormalsXP();
    }
}

// output the normals we need for the basis
technique TTerrainBasis
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_BA )
        DepthState( Depth_Enable )
    
        VertexShader = compile vs_1_1 TerrainVS( false);
        PixelShader = compile ps_2_0 TerrainBasisPS();
    }
}

// output the normals we need for the basis
technique TTerrainBasisBiCubic
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_BA )
        DepthState( Depth_Enable )
    
        VertexShader = compile vs_1_1 TerrainVS( false);
        PixelShader = compile ps_2_0 TerrainBasisPSBiCubic();
    }
}

technique TTerrainOverlay
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 TerrainVS(false);
        PixelShader = compile ps_2_0 TerrainOverlayPS();
    }
}


technique TTerrainSkirt
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        DepthState( Depth_Enable )
        RasterizerState( Rasterizer_Cull_None )

        VertexShader = compile vs_1_1 TerrainSkirtVS();
        PixelShader = compile ps_2_0 TerrainSkirtPS();
    }
}





//****************************
//****************************
//****************************
//****************************

// empirical offset for the decal height to make them not z-fuckup
float decalHeightOffset = 0;

VS_OUTPUT DecalsVS( position_t p : POSITION0, uniform bool shadowed)
{
    VS_OUTPUT result;

    result.nearScales = float4(Stratum0AlbedoTile.x, Stratum1AlbedoTile.x, Stratum2AlbedoTile.x, Stratum3AlbedoTile.x);
    result.farScales =  float4(Stratum0NormalTile.x, Stratum1NormalTile.x, Stratum2NormalTile.x, Stratum3NormalTile.x);

    float4 position = float4(p);
    position.y += decalHeightOffset;
    position.y *= HeightScale;

    // clamp height to water
#if 0
    if( position.y < WaterElevation )
        position.y = WaterElevation;
#endif

    // calculate output position
    result.mPos = calculateHomogenousCoordinate(position);

    // calculate 0..1 uv based on size of map
    result.mTexWT = position.xzyw;

    // calculate the decal local texcoords
    result.mTexDecal = mul( position, DecalMatrix ).xzyw;

    // caluclate screen space coordinate for sample a frame buffer of this size
    result.mTexSS = result.mPos;

    result.mViewDirection = normalize(position.xyz-CameraPosition.xyz);

    // if we have shadows enabled fill in the tex coordinate for the shadow projection
    if ( shadowed && ( 1 == ShadowsEnabled ))
    {
        result.mShadow = mul(position,ShadowMatrix);
        result.mShadow.x = ( +result.mShadow.x + result.mShadow.w ) * 0.5;
        result.mShadow.y = ( -result.mShadow.y + result.mShadow.w ) * 0.5;
        result.mShadow.z -= 0.01f; // put epsilon in vs to save ps instruction
    }
    else
    {
        result.mShadow = float4( 0, 0, 0, 1);
    }

    return result;
}


VS_OUTPUT DecalsVSWaterAlbedo( position_t p : POSITION0, uniform bool shadowed)
{
    VS_OUTPUT result;

    result.nearScales = float4(Stratum0AlbedoTile.x, Stratum1AlbedoTile.x, Stratum2AlbedoTile.x, Stratum3AlbedoTile.x);
    result.farScales =  float4(Stratum0NormalTile.x, Stratum1NormalTile.x, Stratum2NormalTile.x, Stratum3NormalTile.x);

    float4 position = float4(p);
    position.y += decalHeightOffset;
    position.y *= HeightScale;

    // clamp height to water
    if( position.y < WaterElevation )
        position.y = WaterElevation + 0.01;

    // calculate output position
    result.mPos = calculateHomogenousCoordinate(position);

    // calculate 0..1 uv based on size of map
    result.mTexWT = position.xzyw;

    // calculate the decal local texcoords
    result.mTexDecal = mul( position, DecalMatrix ).xzyw;

    // caluclate screen space coordinate for sample a frame buffer of this size
    result.mTexSS = result.mPos;

    result.mViewDirection = normalize(position.xyz-CameraPosition.xyz);

    // if we have shadows enabled fill in the tex coordinate for the shadow projection
    if ( shadowed && ( 1 == ShadowsEnabled ))
    {
        result.mShadow = mul(position,ShadowMatrix);
        result.mShadow.x = ( +result.mShadow.x + result.mShadow.w ) * 0.5;
        result.mShadow.y = ( -result.mShadow.y + result.mShadow.w ) * 0.5;
        result.mShadow.z -= 0.01f; // put epsilon in vs to save ps instruction
    }
    else
    {
        result.mShadow = float4( 0, 0, 0, 1);
    }

    return result;
}


float4 DecalsPSWaterAlbedo( VS_OUTPUT inV, uniform bool inShadows) : COLOR
{

    // sample all the textures we'll need
    float4 decalAlbedo = tex2Dproj( DecalAlbedoSampler, inV.mTexDecal );
    float4 decalMask = tex2Dproj( DecalMaskSampler, inV.mTexDecal ).xxxx;

    float3 color =  LightingMultiplier * decalAlbedo.xyz;

    if ( inShadows && ( 1 == ShadowsEnabled ))
    {
//        float4 sid = tex2Dproj( ShadowSampler, inV.mTexShadow );
//        if ( dot( sid, float4(1,1,1,1) ) != 0 )
//            color *= ShadowFillColor;
    }

    return float4( color, decalAlbedo.w * decalMask.w * DecalAlpha );

}

float4 DecalsPSGlow( VS_OUTPUT inV) : COLOR
{
    // sample all the textures we'll need
    float glow = tex2Dproj( DecalAlbedoSampler, inV.mTexDecal ).a;
    float decalMask = tex2Dproj( DecalMaskSampler, inV.mTexDecal ).x * 0.25;

    return glow * decalMask * DecalAlpha; // + 0.01;
}



float4 DecalsNormalsPS( VS_OUTPUT inV, uniform bool alphablend ) : COLOR
{
    // read textures
    float4 decalMask = tex2Dproj( DecalMaskSampler, inV.mTexDecal );
    float4 decalRaw = tex2Dproj( DecalNormalSampler, inV.mTexDecal );
    float3 decalNormal;
    decalNormal.xz = decalRaw.ag * 2 - 1;
    decalNormal.y = sqrt(1 - dot(decalNormal.xz,decalNormal.xz));

    // rotate the decalnormal by the decal matrix to get the decal into world space
    // from tangent space
    decalNormal = mul( TangentMatrix, decalNormal);
    decalNormal = normalize(decalNormal);

    // our blend mask is stored in the r channel of the decal
    float blendFactor = decalRaw.r;

    // get decal normal back into 0..1 range and output
    decalNormal = (decalNormal * 0.5) + 0.5;
    return float4( decalNormal.xzy,  blendFactor * decalMask.w * DecalAlpha);
}


float4 DecalsPS( VS_OUTPUT inV, uniform bool inShadows) : COLOR
{
    // sample all the textures we'll need
    float4 decalAlbedo = tex2Dproj(DecalAlbedoSampler, inV.mTexDecal);
    float4 decalSpec = tex2Dproj(DecalSpecSampler, inV.mTexDecal);
    float4 decalMask = tex2Dproj(DecalMaskSampler, inV.mTexDecal).xxxx;
    float3 normal = SampleScreen(NormalSampler, inV.mTexSS).xyz * 2 -1;

    float waterDepth = tex2Dproj(UtilitySamplerC, inV.mTexWT * TerrainScale).g;

    float3 color = CalculateLighting(normal, inV.mTexWT.xyz, decalAlbedo.xyz, decalSpec.r, waterDepth, inV.mShadow, inShadows).xyz;

    return float4(color.rgb, decalAlbedo.w * decalMask.w * DecalAlpha);
}

float4 DecalAlbedoXP( VS_OUTPUT inV, uniform bool inShadows) : COLOR
{
    float4 albedo = tex2Dproj(DecalAlbedoSampler,inV.mTexDecal);
    float  specularAmount = tex2Dproj(DecalSpecSampler,inV.mTexDecal).a;
    float  mask = tex2Dproj(DecalMaskSampler,inV.mTexDecal).a;
    float3 normal = normalize(2*SampleScreen(NormalSampler,inV.mTexSS).xyz-1);

    float3 r = reflect(normalize(inV.mViewDirection),normal);
    float3 specular = pow(saturate(dot(r,SunDirection)),80)*specularAmount*SpecularColor.a*SpecularColor.rgb;

    float dotSunNormal = dot(SunDirection,normal);

    float  shadow = tex2D(ShadowSampler,inV.mShadow.xy).g;
    float3 light = SunColor*saturate(dotSunNormal)*shadow + SunAmbience;
    light = LightingMultiplier*light + ShadowFillColor*(1-light);
    albedo.rgb = light * ( albedo.rgb + specular.rgb );

    float waterDepth = tex2Dproj(UtilitySamplerC,inV.mTexWT*TerrainScale).g;
    float4 water = tex1D(WaterRampSampler,waterDepth);
    albedo.rgb = lerp(albedo.rgb,water.rgb,water.a);

    return float4(albedo.rgb,DecalAlpha*albedo.a*mask);
}

float4 DecalsGlowMaskPS( VS_OUTPUT inV, uniform bool inShadows) : COLOR
{

    // sample all the textures we'll need
    float4 decalAlbedo = tex2Dproj( DecalAlbedoSampler, inV.mTexDecal );
    float4 decalSpec = tex2Dproj( DecalSpecSampler, inV.mTexDecal );
    float4 decalMask = tex2Dproj( DecalMaskSampler, inV.mTexDecal ).xxxx;
    float3 normal = SampleScreen(NormalSampler, inV.mTexSS).xyz * 2 -1;


    float waterDepth = tex2Dproj( UtilitySamplerC, inV.mTexWT * TerrainScale).g;
    // calculate the lit pixel
    float3 color = CalculateLighting( normal, inV.mTexWT.xyz, decalAlbedo.xyz, decalSpec.r, waterDepth, inV.mShadow, inShadows).xyz;
    float a = saturate(decalAlbedo.w * decalMask.w * DecalAlpha);
    clip(a-0.90);
    return float4( color, 0.01);
}





float4 DecalsOverDrawPS( VS_OUTPUT inV) : COLOR
{

    // sample all the textures we'll need
    float decalMask = tex2Dproj( DecalMaskSampler, inV.mTexDecal ).x;
    float4 outC = float4(0.1, 0, 0, 0);
    if( decalMask > 0.05 )
    {
        outC = float4(0, 0, 0.1, 0);
    }
    return outC;
}




float4 DecalsPSWaterMask( VS_OUTPUT inV,
                          uniform bool alphaTestEnable,
                          uniform int alphaFunc,
                          uniform int alphaRef ) : COLOR
{
    // return the mask value
    float decalMask = 1- tex2Dproj( DecalMaskSampler, inV.mTexDecal ).x;

    float mask = tex2Dproj( DecalAlbedoSampler, inV.mTexDecal ).r * 0.01;

    float output = mask + decalMask;

#ifdef DIRECT3D10
    if( alphaTestEnable )
        AlphaTestD3D10( output, alphaFunc, alphaRef );
#endif

    return output; //
}


#define decalDepthOffset (-0.00001)


technique TDecalOverDraw
{
    pass P0
    {
        AlphaState( AlphaBlend_One_One_Write_RGB )
        DepthState( Depth_Enable_LessEqual_Write_None )
        RasterizerState( Rasterizer_Bias_Decal )

        VertexShader = compile vs_2_0 DecalsVS( true );
        PixelShader = compile ps_2_0 DecalsOverDrawPS();
    }

}

technique TDecals
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        DepthState( Depth_Enable_LessEqual_Write_None )
        RasterizerState( Rasterizer_Bias_Decal )

        VertexShader = compile vs_2_0 DecalsVS( true );
        PixelShader = compile ps_2_a DecalsPS( true);
    }
}

technique TDecalsXP
{
    pass P0
    {
        AlphaState(AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB)
        DepthState(Depth_Enable_LessEqual_Write_None)
        RasterizerState(Rasterizer_Bias_Decal)

        VertexShader = compile vs_2_0 DecalsVS(true);
        PixelShader = compile ps_2_0 DecalAlbedoXP(true);
    }
}

technique TDecalGlowMask
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        DepthState( Depth_Enable_LessEqual_Write_None )
        RasterizerState( Rasterizer_Bias_Decal )

        VertexShader = compile vs_2_0 DecalsVS(false);
        PixelShader = compile ps_2_0 DecalsGlowMaskPS(false);
    }
}



technique TDecalsGlow
{
    pass P0
    {
        AlphaState( AlphaBlend_One_One_Write_A )
        DepthState( Depth_Enable_LessEqual_Write_None )
        RasterizerState( Rasterizer_Bias_Decal )

        VertexShader = compile vs_2_0 DecalsVS( true );
        PixelShader = compile ps_2_0 DecalsPSGlow();
    }
}

technique TDecalsWaterAlbedo
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        DepthState( Depth_Enable_LessEqual_Write_None )
        RasterizerState( Rasterizer_Bias_Decal )
    
#ifndef DIRECT3D10
        alphatestenable = false;
#endif

        VertexShader = compile vs_2_0 DecalsVSWaterAlbedo(true);
        PixelShader = compile ps_2_0 DecalsPSWaterAlbedo(true);
    }
}

technique TDecalsWaterMask
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_A )
        DepthState( Depth_Enable_LessEqual_Write_None )
        RasterizerState( Rasterizer_Bias_Decal )

#ifndef DIRECT3D10
        alphatestenable = true;
        alphafunc = lessequal;
        alpharef = 3;
#endif

        VertexShader = compile vs_2_0 DecalsVS( true );
        PixelShader = compile ps_2_0 DecalsPSWaterMask( true, d3d_LessEqual, 3 );
    }
}

technique TDecalsNormals
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RG )
        DepthState( Depth_Enable_LessEqual_Write_None )
        RasterizerState( Rasterizer_Bias_Decal )

        VertexShader = compile vs_1_1 DecalsVS( false);
        PixelShader = compile ps_2_0 DecalsNormalsPS(false);
    }
}

technique TDecalsNormalsAlpha
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RG )
        DepthState( Depth_Enable_LessEqual_Write_None )
        RasterizerState( Rasterizer_Bias_Decal )

        VertexShader = compile vs_1_1 DecalsVS( false);
        PixelShader = compile ps_2_0 DecalsNormalsPS(true);
    }
}


struct SPLAT_OUTPUT
{
    float4 mPos                    : POSITION0;
    float4 mTexWT                : TEXCOORD0;
    float4 mTexSS                : TEXCOORD1;
    float4 mShadow              : TEXCOORD2;
    float4 mTexDecal            : TEXCOORD3;
    float1 mAlpha               : TEXCOORD4;
};

SPLAT_OUTPUT SplatsVS(
    float4 p : POSITION0,
    float2 t : TEXCOORD0,
    float2 a : TEXCOORD1,
    uniform bool inShadows )
{
    SPLAT_OUTPUT result;

    float4 pos = p;

    // calculate output position
    result.mPos = calculateHomogenousCoordinate(p);

    // calculate 0..1 uv based on size of map
    result.mTexWT = pos.xzyw;

    // calculate the decal local texcoords
    result.mTexDecal = float4(t, 0, 1);

    // caluclate screen space coordinate for sample a frame buffer of this size
    result.mTexSS = result.mPos;

    // the alpha is passed in the last spot in the verts
    result.mAlpha = a.x;

    // if we have shadows enabled fill in the tex coordinate for the shadow projection
    if ( inShadows && ( 1 == ShadowsEnabled ))
    {
        result.mShadow = mul(p,ShadowMatrix);
        result.mShadow.x = ( +result.mShadow.x + result.mShadow.w ) * 0.5;
        result.mShadow.y = ( -result.mShadow.y + result.mShadow.w ) * 0.5;
        result.mShadow.z -= 0.01f; // put epsilon in vs to save ps instruction
    }
    else
    {
        result.mShadow = float4( 0, 0, 0, 1);
    }

    return result;
}

float4 SplatsPS( SPLAT_OUTPUT inV, uniform bool inShadows, uniform bool lowFidelity ) : COLOR
{
    // sample all the textures we'll need
    float4 decalAlbedo = tex2Dproj( DecalAlbedoSampler, inV.mTexDecal );

    // calculate the normal for lighting
    float3 normal =  SampleScreen(NormalSampler, inV.mTexSS).xyz * 2 - 1;

    // calculate the lit pixel
    float waterDepth = tex2Dproj( UtilitySamplerC, inV.mTexWT * TerrainScale).g;

    float3 color;
    if ( lowFidelity )
        color = decalAlbedo;
    else
        color = CalculateLighting( normal, inV.mTexWT.xyz, decalAlbedo, 0, waterDepth, inV.mShadow, inShadows).xyz;

    return float4( color, decalAlbedo.w * inV.mAlpha.x);
}

technique TSplats
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        DepthState( Depth_Enable_LessEqual_Write_None )
        RasterizerState( Rasterizer_Cull_None_Bias_Neg001 )
    
        VertexShader = compile vs_1_1 SplatsVS(true);
        PixelShader = compile ps_2_0 SplatsPS(true,false);
    }
}

technique LowFidelitySplat
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        DepthState( Depth_Enable_LessEqual_Write_None )
        RasterizerState( Rasterizer_Cull_CCW_Bias_Neg02 )

        VertexShader = compile vs_1_1 SplatsVS(true);
        PixelShader = compile ps_2_0 SplatsPS(true,true);
    }
}

///
///
///

struct LOWFIDELITY_VERTEX
{
    float4 position     : POSITION0;
    float4 texcoord0    : TEXCOORD0;
    float4 shadow       : TEXCOORD1;
};

LOWFIDELITY_VERTEX LowFidelityTerrainVS( position_t p : POSITION0)
{
    LOWFIDELITY_VERTEX vertex = (LOWFIDELITY_VERTEX)0;

    float4 position = float4(p);
    position.y *= HeightScale;

    vertex.position = calculateHomogenousCoordinate(position);
    vertex.texcoord0 = position.xzyw;

    return vertex;
}

float4 LowFidelityTerrainPS( LOWFIDELITY_VERTEX vertex ) : COLOR0
{
    float4 texcoord = TerrainScale * vertex.texcoord0;

    float4 mask = saturate( 2 * tex2Dproj(UtilitySamplerA,texcoord) - 1 );

    float3 albedo0 = tex2Dproj(Stratum0AlbedoSampler,Stratum0AlbedoTile * texcoord).rgb;
    float3 albedo1 = tex2Dproj(Stratum1AlbedoSampler,Stratum1AlbedoTile * texcoord).rgb;
    float3 albedo2 = tex2Dproj(Stratum2AlbedoSampler,Stratum2AlbedoTile * texcoord).rgb;
    float3 albedo3 = tex2Dproj(Stratum3AlbedoSampler,Stratum3AlbedoTile * texcoord).rgb;

    float3 albedo = tex2Dproj(LowerAlbedoSampler,LowerAlbedoTile * texcoord).rgb;
    albedo = lerp(albedo,albedo0,mask.x);
    albedo = lerp(albedo,albedo1,mask.y);
    albedo = lerp(albedo,albedo2,mask.z);
    albedo = lerp(albedo,albedo3,mask.w);

    return float4(albedo,0.1);
}

technique LowFidelityTerrain
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 LowFidelityTerrainVS();
        PixelShader = compile ps_2_0 LowFidelityTerrainPS();
    }
}

LOWFIDELITY_VERTEX LowFidelityLightingVS( position_t p : POSITION0)
{
    LOWFIDELITY_VERTEX vertex = (LOWFIDELITY_VERTEX)0;

    float4 position = float4(p);
    position.y *= HeightScale;

    vertex.position = calculateHomogenousCoordinate(position);
    vertex.texcoord0 = position.xzyw;

    if( 1 == ShadowsEnabled )
    {
        vertex.shadow = mul(position,ShadowMatrix);
        vertex.shadow.x = ( +vertex.shadow.x + vertex.shadow.w ) * 0.5;
        vertex.shadow.y = ( -vertex.shadow.y + vertex.shadow.w ) * 0.5;
        vertex.shadow.z -= 0.01f;
    }
    else
    {
        vertex.shadow = float4(0,0,0,1);
    }

    return vertex;
}

float4 LowFidelityLightingPS( LOWFIDELITY_VERTEX vertex) : COLOR0
{
    float shadow = 1;
    if ( 1 == ShadowsEnabled )
    {
        shadow = ComputeShadow( vertex.shadow );
    }

    float3 normal = 2 * tex2Dproj(UtilitySamplerA,vertex.texcoord0 * TerrainScale * NormalMapScale + NormalMapOffset).aag - 1;
    normal.g = sqrt( 1 - normal.r * normal.r - normal.b * normal.b );

    float3 light = ( SunColor * saturate(dot(SunDirection,normal)) * shadow + SunAmbience );
    light = LightingMultiplier * light + ShadowFillColor * ( 1 - light );

    return float4(light.rgb,0.1);
}

technique LowFidelityLighting
{
    pass P0
    {
        AlphaState( AlphaBlend_Zero_SrcColor_Write_RGB )
        DepthState( Depth_Enable_LessEqual_Write_None )

        VertexShader = compile vs_1_1 LowFidelityLightingVS();
        PixelShader = compile ps_2_0 LowFidelityLightingPS();
    }
}

/* # Blending techniques # */

float splatLerp(float t1, float t2, float t2height, float opacity, uniform float blurriness) {
    float height1 = 1;
    float height2 = t2height * (1 - 2 * blurriness) + blurriness + opacity;
    float ma = max(height1, height2) - blurriness;
    float factor1 = max(height1 - ma, 0);
    float factor2 = max(height2 - ma, 0);
    return (t1 * factor1 + t2 * factor2) / (factor1 + factor2);
}

float4 splatLerp(float4 t1, float4 t2, float t2height, float opacity, uniform float blurriness = 0.06) {
    float height1 = 1;
    float height2 = t2height * (1 - 2 * blurriness) + blurriness + opacity;
    float ma = max(height1, height2) - blurriness;
    float factor1 = max(height1 - ma, 0);
    float factor2 = max(height2 - ma, 0);
    return (t1 * factor1 + t2 * factor2) / (factor1 + factor2);
}

float3 splatBlendNormal(float3 n1, float3 n2, float t2height, float opacity, uniform float blurriness = 0.06) {
    float height1 = 1;
    float height2 = t2height * (1 - 2 * blurriness) + blurriness + opacity;
    float ma = max(height1, height2) - blurriness;
    float factor1 = max(height1 - ma, 0);
    float factor2 = max(height2 - ma, 0);
    // These factors are to make low opacity normal maps more visible,
    // as we notice small changes to the albedo maps more easily.
    // The value of 0.5 is just eyeballed.
    float factor1modified = pow(factor1 / (factor1 + factor2), 0.6);
    float factor2modified = pow(factor2 / (factor1 + factor2), 0.6);
    // UDN blending
    return normalize(float3((n1.xy * factor1modified + n2.xy * factor2modified), n1.z));
}

/* # Sample a 2D 2x2 texture atlas # */
/* To prevent bleeding from the neighboring tiles, we need to work with padding */
float4 atlas2D(sampler2D s, float2 uv, uniform float2 offset) {
    // We need to manually provide the derivatives to prevent seams.
    // See https://forum.unity.com/threads/tiling-textures-within-an-atlas-by-wrapping-uvs-within-frag-shader-getting-artifacts.535793/
    float2 uv_ddx = ddx(uv) / 4;
    float2 uv_ddy = ddy(uv) / 4;
    uv.x = frac(uv.x) / 4 + offset.x + 0.125;
    uv.y = frac(uv.y) / 4 + offset.y + 0.125;
    return tex2Dgrad(s, uv, uv_ddx, uv_ddy);
}

float3 sampleNormal(sampler2D s, float2 position, uniform float2 scale, float mask) {
    // 30° rotation
    float2x2 rotationMatrix = float2x2(float2(0.866, -0.5), float2(0.5, 0.866));
    float3 normal = tex2D(s, position * scale).rgb;
    float3 normalRotated = tex2D(s, mul(position, rotationMatrix) * scale).rgb;
    return splatBlendNormal(normalize(2 * normal - 1), normalize(2 * normalRotated - 1), 0.5, mask, 0.03);
}

float4 sampleAlbedo(sampler2D s, float2 position, uniform float2 scale, uniform float2 offset, uniform bool firstBatch, float mask) {
    // 30° rotation
    float2x2 rotationMatrix = float2x2(float2(0.866, -0.5), float2(0.5, 0.866));
    float4 albedo = tex2D(s, position * scale);
    float4 albedoRotated = tex2D(s, mul(position, rotationMatrix) * scale);
    // store roughness in albedo alpha so we get the roughness splatting for free
    if (firstBatch) {
        albedo.a = atlas2D(Stratum7NormalSampler, position * scale, offset).y;
        albedoRotated.a = atlas2D(Stratum7NormalSampler, mul(position, rotationMatrix) * scale, offset).y;
    } else {
        albedo.a = atlas2D(Stratum7NormalSampler, position * scale, offset).w;
        albedoRotated.a = atlas2D(Stratum7NormalSampler, mul(position, rotationMatrix) * scale, offset).w;
    }
    return splatLerp(albedo, albedoRotated, 0.5, mask, 0.03);
}

float4 sampleAlbedo(sampler2D s, float2 position, uniform float2 scale, uniform float2 offset, uniform bool firstBatch) {
    float4 albedo = tex2D(s, position * scale);
    // store roughness in albedo alpha so we get the roughness splatting for free
    if (firstBatch) {
        albedo.a = atlas2D(Stratum7NormalSampler, position * scale, offset).y;
    } else {
        albedo.a = atlas2D(Stratum7NormalSampler, position * scale, offset).w;
    }
    return albedo;
}

float sampleHeight(float2 position, uniform float2 nearScale, uniform float2 farScale, uniform float2 offset, uniform bool firstBatch, float mask) {
    float2x2 rotationMatrix = float2x2(float2(0.866, -0.5), float2(0.5, 0.866));
    float2 heightNear = atlas2D(Stratum7NormalSampler, position * nearScale, offset).xz;
    float2 heightNearRotated = atlas2D(Stratum7NormalSampler, mul(position, rotationMatrix) * nearScale, offset).xz;
    float heightFar;
    if (firstBatch) {
        heightNear.x = splatLerp(heightNear.x, heightNearRotated.x, 0.5, mask, 0.03);
        heightFar = atlas2D(Stratum7NormalSampler, position * farScale, offset).x;
    } else {
        heightNear.x = splatLerp(heightNear.y, heightNearRotated.y, 0.5, mask, 0.03);
        heightFar = atlas2D(Stratum7NormalSampler, position * farScale, offset).z;
    }
    return (heightNear.x + heightFar) / 2;
}

float sampleHeight(float2 position, uniform float2 nearScale, uniform float2 farScale, uniform float2 offset, uniform bool firstBatch) {
    float heightNear;
    float heightFar;
    if (firstBatch) {
        heightNear = atlas2D(Stratum7NormalSampler, position * nearScale, offset).x;
        heightFar = atlas2D(Stratum7NormalSampler, position * farScale, offset).x;
    } else {
        heightNear = atlas2D(Stratum7NormalSampler, position * nearScale, offset).z;
        heightFar = atlas2D(Stratum7NormalSampler, position * farScale, offset).z;
    }
    return (heightNear + heightFar) / 2;
}

float blendHeight(float4 position, float2 blendWeights, uniform float2 nearscale, uniform float2 farscale, uniform float2 offset, uniform bool firstBatch) {
    float heightNearXZ;
    float heightFarXZ;
    float heightNearYZ;
    float heightFarYZ;
    if (firstBatch) {
        heightNearXZ = atlas2D(Stratum7NormalSampler, position.xz * nearscale, offset).x;
        heightFarXZ = atlas2D(Stratum7NormalSampler, position.xz * farscale, offset).x;
        heightNearYZ = atlas2D(Stratum7NormalSampler, position.yz * nearscale, offset).x;
        heightFarYZ = atlas2D(Stratum7NormalSampler, position.yz * farscale, offset).x;
    } else {
        heightNearXZ = atlas2D(Stratum7NormalSampler, position.xz * nearscale, offset).z;
        heightFarXZ = atlas2D(Stratum7NormalSampler, position.xz * farscale, offset).z;
        heightNearYZ = atlas2D(Stratum7NormalSampler, position.yz * nearscale, offset).z;
        heightFarYZ = atlas2D(Stratum7NormalSampler, position.yz * farscale, offset).z;
    }
    return (heightNearYZ + heightFarYZ) / 2 * blendWeights.x + (heightNearXZ + heightFarXZ) / 2 * blendWeights.y;
}

/* # TerrainPBR # */
/* a worksite to test new things and an agglomeration of all kinds of stuff you can do to improve the visuals */
/* similar to Terrain301 but additionally uses rotated sampling of all textures to break up repetition patterns */
/* and uses vertical texture sampling for cliff textures in stratum3 */
// Layer| Albedo stratum                                               | Normal stratum
//      | R           | G             | B            | A               | R             | G             | B             | A            |
//  ----            ---             ---             ---              ---             ---             ---             ---            ---
// | L  | R             G               B              unused          | X               Y               Z               unused       |
//  ----            ---             ---             ---              ---             ---             ---             ---            ---
// | S0 | R             G               B              unused          | X               Y               Z               unused       |
// | S1 | R             G               B              unused          | X               Y               Z               unused       |
// | S2 | R             G               B              unused          | X               Y               Z               unused       |
// | S3 | R             G               B              unused          | X               Y               Z               unused       |
//  ----            ---             ---            ---               ---             ---             ---             ---            ---
// | S4 | R             G               B              unused          | X               Y               Z               unused       |
// | S5 | R             G               B              unused          | X               Y               Z               unused       |
// | S6 | R             G               B          sampling direction  | X               Y               Z               unused       |
// | S7 | albedo.r      albedo.g        albedo.b       transparency    | height L-S2   roughness L-S2  height S3-S6   roughness S3-S6 |
//  ----            ---             ---             ---              ---             ---             ---             ---            ---
// | U  | normal.x      normal.z        waterDepth     shadow          | 
//  ----
// The normal map scales are controlled by the albedo scales to ensure that they use the same values.
// The layer mask of S7 acts as a roughness multiplier with 0.5 as the neutral value.
// Height processing happens at two scales, the albedo scales control the near scale and the normal scales control the far scale.
// SpecularColor.r is used to control the blurriness of the texture splatting
// SpecularColor.g is used for the scaling of the sampling direction texture

float4 TerrainPBRNormalsPS ( VS_OUTPUT inV ) : COLOR
{
    // z coordinate of Terrainscale is 0
    float4 position;
    position.xyw = TerrainScale.xyw * inV.mTexWT.xyw;
    position.z = TerrainScale.x * inV.mTexWT.z;

    float4 mask0 = tex2D(UtilitySamplerA, position.xy);
    float4 mask1 = tex2D(UtilitySamplerB, position.xy);
    float rotationMask = tex2D(Stratum6AlbedoSampler, position.xy / (SpecularColor.g + 0.01)).w;

    float3 lowerNormal    = sampleNormal(LowerNormalSampler,    position.xy, LowerAlbedoTile.xy,    rotationMask);
    float3 stratum0Normal = sampleNormal(Stratum0NormalSampler, position.xy, Stratum0AlbedoTile.xy, rotationMask);
    float3 stratum1Normal = sampleNormal(Stratum1NormalSampler, position.xy, Stratum1AlbedoTile.xy, rotationMask);
    float3 stratum2Normal = sampleNormal(Stratum2NormalSampler, position.xy, Stratum2AlbedoTile.xy, rotationMask);
    float3 stratum4Normal = sampleNormal(Stratum4NormalSampler, position.xy, Stratum4AlbedoTile.xy, rotationMask);
    float3 stratum5Normal = sampleNormal(Stratum5NormalSampler, position.xy, Stratum5AlbedoTile.xy, rotationMask);
    float3 stratum6Normal = sampleNormal(Stratum6NormalSampler, position.xy, Stratum6AlbedoTile.xy, rotationMask);

    float stratum0Height = sampleHeight(position.xy, Stratum0AlbedoTile.xy, Stratum0NormalTile.xy, float2(0.5, 0.0), true,  rotationMask);
    float stratum1Height = sampleHeight(position.xy, Stratum1AlbedoTile.xy, Stratum1NormalTile.xy, float2(0.0, 0.5), true,  rotationMask);
    float stratum2Height = sampleHeight(position.xy, Stratum2AlbedoTile.xy, Stratum2NormalTile.xy, float2(0.5, 0.5), true,  rotationMask);
    float stratum4Height = sampleHeight(position.xy, Stratum4AlbedoTile.xy, Stratum4NormalTile.xy, float2(0.5, 0.0), false, rotationMask);
    float stratum5Height = sampleHeight(position.xy, Stratum5AlbedoTile.xy, Stratum5NormalTile.xy, float2(0.0, 0.5), false, rotationMask);
    float stratum6Height = sampleHeight(position.xy, Stratum6AlbedoTile.xy, Stratum6NormalTile.xy, float2(0.5, 0.5), false, rotationMask);

    float3 stratum3NormalXZ = normalize(tex2D(Stratum3NormalSampler, position.xz * Stratum3AlbedoTile.xy).rgb * 2 - 1);
    float3 stratum3NormalYZ = normalize(tex2D(Stratum3NormalSampler, position.yz * Stratum3AlbedoTile.xy).rgb * 2 - 1);
    float2 blendWeights = pow(abs(lowerNormal.xy), 3);
    blendWeights = blendWeights / (blendWeights.x + blendWeights.y);
    float3 stratum3Normal = stratum3NormalYZ * blendWeights.x + stratum3NormalXZ * blendWeights.y;
    float stratum3Height =  blendHeight(position, blendWeights, inV.nearScales.ww, inV.farScales.ww, float2(0.0, 0.0), false);

    float3 normal = lowerNormal;
    normal = splatBlendNormal(normal, stratum0Normal, stratum0Height, mask0.x, SpecularColor.r);
    normal = splatBlendNormal(normal, stratum1Normal, stratum1Height, mask0.y, SpecularColor.r);
    normal = splatBlendNormal(normal, stratum2Normal, stratum2Height, mask0.z, SpecularColor.r);
    normal = splatBlendNormal(normal, stratum3Normal, stratum3Height, mask0.w, SpecularColor.r);
    normal = splatBlendNormal(normal, stratum4Normal, stratum4Height, mask1.x, SpecularColor.r);
    normal = splatBlendNormal(normal, stratum5Normal, stratum5Height, mask1.y, SpecularColor.r);
    normal = splatBlendNormal(normal, stratum6Normal, stratum6Height, mask1.z, SpecularColor.r);

    return float4( 0.5 + 0.5 * normal.rgb, 1);
}

float4 TerrainPBRAlbedoPS ( VS_OUTPUT inV) : COLOR
{
    // z coordinate of Terrainscale is 0
    float4 position;
    position.xyw = TerrainScale.xyw * inV.mTexWT.xyw;
    position.z = TerrainScale.x * inV.mTexWT.z;

    // do arithmetics to get range from (0, 1) to (-1, 1) as normal maps store their values as (0, 1)
    float3 normal = normalize(2 * SampleScreen(NormalSampler,inV.mTexSS).xyz - 1);

    float4 mask0 = tex2D(UtilitySamplerA, position.xy);
    float4 mask1 = tex2D(UtilitySamplerB, position.xy);
    float rotationMask = tex2D(Stratum6AlbedoSampler, position.xy / (SpecularColor.g + 0.01)).w;

    // This shader wouldn't compile because it would have to store too many variables if we didn't use this trick in the vertex shader
    float4 lowerAlbedo =    sampleAlbedo(LowerAlbedoSampler,    position.xy, LowerAlbedoTile.xy,    float2(0.0, 0.0), true,  rotationMask);
    float4 stratum0Albedo = sampleAlbedo(Stratum0AlbedoSampler, position.xy, inV.nearScales.xx,     float2(0.5, 0.0), true,  rotationMask);
    float4 stratum1Albedo = sampleAlbedo(Stratum1AlbedoSampler, position.xy, inV.nearScales.yy,     float2(0.0, 0.5), true,  rotationMask);
    float4 stratum2Albedo = sampleAlbedo(Stratum2AlbedoSampler, position.xy, inV.nearScales.zz,     float2(0.5, 0.5), true,  rotationMask);
    float4 stratum4Albedo = sampleAlbedo(Stratum4AlbedoSampler, position.xy, Stratum4AlbedoTile.xy, float2(0.5, 0.0), false, rotationMask);
    float4 stratum5Albedo = sampleAlbedo(Stratum5AlbedoSampler, position.xy, Stratum5AlbedoTile.xy, float2(0.0, 0.5), false, rotationMask);
    float4 stratum6Albedo = sampleAlbedo(Stratum6AlbedoSampler, position.xy, Stratum6AlbedoTile.xy, float2(0.5, 0.5), false, rotationMask);

    float stratum0Height = sampleHeight(position.xy, inV.nearScales.xx,     inV.farScales.xx,      float2(0.5, 0.0), true,  rotationMask);
    float stratum1Height = sampleHeight(position.xy, inV.nearScales.yy,     inV.farScales.yy,      float2(0.0, 0.5), true,  rotationMask);
    float stratum2Height = sampleHeight(position.xy, inV.nearScales.zz,     inV.farScales.zz,      float2(0.5, 0.5), true,  rotationMask);
    float stratum4Height = sampleHeight(position.xy, Stratum4AlbedoTile.xy, Stratum4NormalTile.xy, float2(0.5, 0.0), false, rotationMask);
    float stratum5Height = sampleHeight(position.xy, Stratum5AlbedoTile.xy, Stratum5NormalTile.xy, float2(0.0, 0.5), false, rotationMask);
    float stratum6Height = sampleHeight(position.xy, Stratum6AlbedoTile.xy, Stratum6NormalTile.xy, float2(0.5, 0.5), false, rotationMask);

    float4 stratum3albedoXZ = sampleAlbedo(Stratum3AlbedoSampler, position.xz, inV.nearScales.ww, float2(0.0, 0.0), false);
    float4 stratum3albedoYZ = sampleAlbedo(Stratum3AlbedoSampler, position.yz, inV.nearScales.ww, float2(0.0, 0.0), false);
    float2 blendWeights = pow(abs(normal.xy), 3);
    blendWeights = blendWeights / (blendWeights.x + blendWeights.y);
    float4 stratum3albedo = stratum3albedoYZ * blendWeights.x + stratum3albedoXZ * blendWeights.y;
    float stratum3Height = blendHeight(position, blendWeights, inV.nearScales.ww, inV.farScales.ww, float2(0.0, 0.0), false);

    float4 albedo = lowerAlbedo;
    albedo = splatLerp(albedo, stratum0Albedo, stratum0Height, mask0.x, SpecularColor.r);
    albedo = splatLerp(albedo, stratum1Albedo, stratum1Height, mask0.y, SpecularColor.r);
    albedo = splatLerp(albedo, stratum2Albedo, stratum2Height, mask0.z, SpecularColor.r);
    albedo = splatLerp(albedo, stratum3albedo, stratum3Height, mask0.w, SpecularColor.r);
    albedo = splatLerp(albedo, stratum4Albedo, stratum4Height, mask1.x, SpecularColor.r);
    albedo = splatLerp(albedo, stratum5Albedo, stratum5Height, mask1.y, SpecularColor.r);
    albedo = splatLerp(albedo, stratum6Albedo, stratum6Height, mask1.z, SpecularColor.r);
    float4 mapwide = tex2D(Stratum7AlbedoSampler, position.xy);
    albedo.rgb = lerp(albedo.rgb, mapwide.rgb, mapwide.a);

    // We need to add 0.01 as the reflection disappears at 0
    float roughness = saturate(albedo.a * mask1.w * 2 + 0.01);

    float waterDepth = tex2D(UpperAlbedoSampler, position.xy).b;
    float3 color = PBR(inV, position, albedo, normal, roughness, waterDepth);
    color = ApplyWaterColorExponentially(-1 * inV.mViewDirection, inV.mTexWT.z, waterDepth, color);

    return float4(color, 0.01f);
    // SpecularColor.ba, LowerNormalTile, Stratum7AlbedoTile and Stratum7NormalTile are unused now
    // Candidates for configurable values are the rotation matrix values
}

//technique TerrainPBRNormals
//{
//    pass P0
//    {
//        AlphaState( AlphaBlend_Disable_Write_RG )
//        DepthState( Depth_Enable )
//
//        VertexShader = compile vs_1_1 TerrainVS(false);
//        PixelShader = compile ps_2_a TerrainPBRNormalsPS();
//    }
//}
//
//technique TerrainPBR <
//    string usage = "composite";
//    string normals = "TerrainPBRNormals";
//>
//{
//    pass P0
//    {
//        AlphaState( AlphaBlend_Disable_Write_RGBA )
//        DepthState( Depth_Enable )
//
//        VertexShader = compile vs_1_1 TerrainVS(true);
//        // If we use ps_3_0 we lose the distance fog
//        PixelShader = compile ps_2_a TerrainPBRAlbedoPS();
//    }
//}

// Terrain0XX for shaders that are pretty regular
// Terrain1XX for shaders using roughness maps
// Terrain2XX for shaders using advanced splatting
// Terrain3XX for shaders using roughness and advanced splatting

// TerrainX0X to TerrainX4X for shaders with half mask range
// TerrainX5X to TerrainX9X for shaders using the full mask range

// TerrainX1X and TerrainX6X for shaders using biplanar mapping?
// TerrainX2X and TerrainX7X for shaders using additional rotated sampling?
// TerrainX3X and TerrainX8X for shaders using biplanar mapping and additional rotated sampling?

// ----------------------------------------------------------------------------
//#region Terrain001, Terrain002 and Terrain052

// Layer| Albedo stratum                                               | Normal stratum
//      | R           | G             | B            | A               | R             | G             | B             | A            |
//  ----            ---             ---             ---              ---             ---             ---             ---            ---
// | L  | R             G               B              unused          | X               Y               Z               unused       |
//  ----            ---             ---             ---              ---             ---             ---             ---            ---
// | S0 | R             G               B              unused          | X               Y               Z               unused       |
// | S1 | R             G               B              unused          | X               Y               Z               unused       |
// | S2 | R             G               B              unused          | X               Y               Z               unused       |
// | S3 | R             G               B              unused          | X               Y               Z               unused       |
//  ----            ---             ---            ---               ---             ---             ---             ---            ---
// | S4 | R             G               B              unused          | X               Y               Z               unused       |
// | S5 | R             G               B              unused          | X               Y               Z               unused       |
// | S6 | R             G               B              unused          | X               Y               Z               unused       |
// | S7 | R             G               B              unused          | X               Y               Z               unused       |
//  ----            ---             ---             ---              ---             ---             ---             ---            ---
// | U  | normal.x      normal.z        unused         shadow  | 

// Terrain001 and Terrain002 are similar to the usual TTerrainXP shader. They
// are designed as a drop-in replacement that solely introduce the map-wide
// normals and map-wide shadows

// Terrain002 fixes the normals interpreting the masks different than albedo,
// for this shader the normals also start reading at a value of 128 (0%) up to
// 255 (100%). We choose to keep it instead of fixing the range as all editors
// assume the values to range from 128 to 255

// Terrain052 uses the full mask range

float4 Terrain002NormalsPS( VS_OUTPUT pixel, uniform bool halfRange ) : COLOR
{
    float2 coordinates = pixel.mTexWT * TerrainScale;

    // - x = stratum layer 0
    // - y = stratum layer 1
    // - z = stratum layer 2
    // - w = stratum layer 3
    float4 mask0 = tex2D(UtilitySamplerA, coordinates);

    // - x = stratum layer 4
    // - y = stratum layer 5
    // - z = stratum layer 6
    // - w = stratum layer 7
    float4 mask1 = tex2D(UtilitySamplerB, coordinates);

    if (halfRange) {
        mask0 = saturate(mask0 * 2 - 1);
        mask1 = saturate(mask1 * 2 - 1);
    }

    // these normals are pre-baked on top of the terrain
    float4 lowerNormal    = normalize(tex2D(LowerNormalSampler,    coordinates * LowerNormalTile.xx)    * 2 - 1);
    float4 stratum0Normal = normalize(tex2D(Stratum0NormalSampler, coordinates * Stratum0NormalTile.xx) * 2 - 1);
    float4 stratum1Normal = normalize(tex2D(Stratum1NormalSampler, coordinates * Stratum1NormalTile.xx) * 2 - 1);
    float4 stratum2Normal = normalize(tex2D(Stratum2NormalSampler, coordinates * Stratum2NormalTile.xx) * 2 - 1);
    float4 stratum3Normal = normalize(tex2D(Stratum3NormalSampler, coordinates * Stratum3NormalTile.xx) * 2 - 1);
    float4 stratum4Normal = normalize(tex2D(Stratum4NormalSampler, coordinates * Stratum4NormalTile.xx) * 2 - 1);
    float4 stratum5Normal = normalize(tex2D(Stratum5NormalSampler, coordinates * Stratum5NormalTile.xx) * 2 - 1);
    float4 stratum6Normal = normalize(tex2D(Stratum6NormalSampler, coordinates * Stratum6NormalTile.xx) * 2 - 1);
    float4 stratum7Normal = normalize(tex2D(Stratum7NormalSampler, coordinates * Stratum7NormalTile.xx) * 2 - 1);

    // blend the normals
    float4 normal = lowerNormal;
    normal = normalize(lerp(normal,stratum0Normal,mask0.x));
    normal = normalize(lerp(normal,stratum1Normal,mask0.y));
    normal = normalize(lerp(normal,stratum2Normal,mask0.z));
    normal = normalize(lerp(normal,stratum3Normal,mask0.w));
    normal = normalize(lerp(normal,stratum4Normal,mask1.x));
    normal = normalize(lerp(normal,stratum5Normal,mask1.y));
    normal = normalize(lerp(normal,stratum6Normal,mask1.z));
    normal = normalize(lerp(normal,stratum7Normal,mask1.w));

    return float4( (normal.xyz * 0.5 + 0.5) , normal.w);
}

float4 Terrain001AlbedoPS ( VS_OUTPUT inV, uniform bool halfRange ) : COLOR
{
    float4 coordinates = TerrainScale * inV.mTexWT;

    // - x = stratum layer 0
    // - y = stratum layer 1
    // - z = stratum layer 2
    // - w = stratum layer 3
    float4 mask0 = tex2D(UtilitySamplerA, coordinates.xy);

    // - x = stratum layer 4
    // - y = stratum layer 5
    // - z = stratum layer 6
    // - w = stratum layer 7
    float4 mask1 = tex2D(UtilitySamplerB, coordinates.xy);

    if (halfRange) {
        mask0 = saturate(mask0 * 2 - 1);
        mask1 = saturate(mask1 * 2 - 1);
    }

    // x = normals-x
    // y = normals-z
    // z = unused
    // w = shadows
    float4 utility = tex2D(UpperAlbedoSampler, coordinates.xy);
    float mapShadow = utility.w;

    // disable shadows when game settings tell us to
    if (0 == ShadowsEnabled) {
        mapShadow = 1.0f;
    }

    // sample the albedo's
    float4 lowerAlbedo    = tex2Dproj(LowerAlbedoSampler,    coordinates * LowerAlbedoTile);
    float4 stratum0Albedo = tex2Dproj(Stratum0AlbedoSampler, coordinates * Stratum0AlbedoTile);
    float4 stratum1Albedo = tex2Dproj(Stratum1AlbedoSampler, coordinates * Stratum1AlbedoTile);
    float4 stratum2Albedo = tex2Dproj(Stratum2AlbedoSampler, coordinates * Stratum2AlbedoTile);
    float4 stratum3Albedo = tex2Dproj(Stratum3AlbedoSampler, coordinates * Stratum3AlbedoTile);
    float4 stratum4Albedo = tex2Dproj(Stratum4AlbedoSampler, coordinates * Stratum4AlbedoTile);
    float4 stratum5Albedo = tex2Dproj(Stratum5AlbedoSampler, coordinates * Stratum5AlbedoTile);
    float4 stratum6Albedo = tex2Dproj(Stratum6AlbedoSampler, coordinates * Stratum6AlbedoTile);
    float4 stratum7Albedo = tex2Dproj(Stratum7AlbedoSampler, coordinates * Stratum7AlbedoTile);

    // blend the albedo
    float4 albedo = lowerAlbedo;
    albedo = lerp(albedo,stratum0Albedo,mask0.x);
    albedo = lerp(albedo,stratum1Albedo,mask0.y);
    albedo = lerp(albedo,stratum2Albedo,mask0.z);
    albedo = lerp(albedo,stratum3Albedo,mask0.w);
    albedo = lerp(albedo,stratum4Albedo,mask1.x);
    albedo = lerp(albedo,stratum5Albedo,mask1.y);
    albedo = lerp(albedo,stratum6Albedo,mask1.z);
    albedo = lerp(albedo,stratum7Albedo,mask1.w);

    // compute the shadows, combining the baked and dynamic shadows
    float shadow = tex2D(ShadowSampler, inV.mShadow.xy).g; // 1 where sun is, 0 where shadow is
    shadow = shadow * mapShadow;

    // normalize the pre-computed normal
    float3 normal = normalize(2 * SampleScreen(NormalSampler,inV.mTexSS).xyz - 1);

    // compute specular
    float3 r = reflect(normalize(inV.mViewDirection), normal);
    float3 specular = pow(saturate(dot(r, SunDirection)),80) * albedo.aaa * SpecularColor.a * SpecularColor.rgb;

    // compute lighting
    float dotSunNormal = max(0, dot(SunDirection, normal));

    // combine everything
    float3 light = SunColor * saturate(dotSunNormal) * shadow + SunAmbience;
    light = LightingMultiplier * light + ShadowFillColor * (1 - light);
    albedo.rgb = light * (albedo.rgb + specular.rgb);

    // compute water ramp intensity
    float waterDepth = tex2Dproj(UtilitySamplerC, coordinates).g;
    albedo.rgb = ApplyWaterColorExponentially(-1 * inV.mViewDirection, inV.mTexWT.z, waterDepth, albedo.rgb);

    return float4(albedo.rgb, 0.01f);
}

/* # Similar to TTerrainXP, but upperAlbedo is used for map-wide #
   # textures and we use better water color calculations.        #
   # It is designed to be a drop-in replacement for TTerrainXP.  # */
technique Terrain001 <
    string usage = "composite";
    string normals = "TTerrainNormalsXP";
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 TerrainVS(true);
        PixelShader = compile ps_2_a Terrain001AlbedoPS(true);
    }
}

technique Terrain002Normals
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RG )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 TerrainVS(false);
        PixelShader = compile ps_2_a Terrain002NormalsPS(true);
    }
}

/* # Very similar to Terrain001, but makes the used value ranges #
   # in the texture masks consistent between normal and albedo.  # */
technique Terrain002 <
    string usage = "composite";
    string normals = "Terrain002Normals";
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 TerrainVS(true);
        PixelShader = compile ps_2_a Terrain001AlbedoPS(true);
    }
}

technique Terrain052Normals
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RG )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 TerrainVS(false);
        PixelShader = compile ps_2_a Terrain002NormalsPS(false);
    }
}

technique Terrain052 <
    string usage = "composite";
    string normals = "Terrain052Normals";
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 TerrainVS(true);
        PixelShader = compile ps_2_a Terrain001AlbedoPS(false);
    }
}

//#endregion

// ----------------------------------------------------------------------------
//#region Terrain003 and Terrain053

// Layer| Albedo stratum                                               | Normal stratum
//      | R           | G             | B            | A               | R             | G             | B             | A            |
//  ----            ---             ---             ---              ---             ---             ---             ---            ---
// | L  | R             G               B              unused          | X               Y               Z               unused       |
//  ----            ---             ---             ---              ---             ---             ---             ---            ---
// | S0 | R             G               B              unused          | X               Y               Z               unused       |
// | S1 | R             G               B              unused          | X               Y               Z               unused       |
// | S2 | R             G               B              unused          | X               Y               Z               unused       |
// | S3 | R             G               B              unused          | X               Y               Z               unused       |
//  ----            ---             ---            ---               ---             ---             ---             ---            ---
// | S4 | R             G               B              unused          | X               Y               Z               unused       |
// | S5 | R             G               B              unused          | X               Y               Z               unused       |
// | S6 | R             G               B              unused          | X               Y               Z               unused       |
// | S7 | albedo.r      albedo.g        albedo.b       transparency    | specular        unused          unused          unused       |
//  ----            ---             ---             ---              ---             ---             ---             ---            ---
// | U  | normal.x      normal.z        unused         shadow  | 

float4 UDNBlending(float4 n1, float4 n2, float factor) {
    n2.xy *= factor;
    return normalize(float4(n1.xy + n2.xy, n1.z, 0));
}

float4 Terrain003NormalsPS( VS_OUTPUT pixel, uniform bool halfRange ) : COLOR
{
    float2 coordinates = pixel.mTexWT * TerrainScale;

    // - x = stratum layer 0
    // - y = stratum layer 1
    // - z = stratum layer 2
    // - w = stratum layer 3
    float4 mask0 = tex2D(UtilitySamplerA, coordinates);

    // - x = stratum layer 4
    // - y = stratum layer 5
    // - z = stratum layer 6
    // - w = unused
    float4 mask1 = tex2D(UtilitySamplerB, coordinates);

    if (halfRange) {
        mask0 = saturate(mask0 * 2 - 1);
        mask1 = saturate(mask1 * 2 - 1);
    }

    // these normals are pre-baked on top of the terrain
    float4 base =           normalize(tex2D(LowerNormalSampler,    coordinates * LowerNormalTile.xx   ) * 2 - 1);
    float4 stratum0Normal = normalize(tex2D(Stratum0NormalSampler, coordinates * Stratum0NormalTile.xx) * 2 - 1);
    float4 stratum1Normal = normalize(tex2D(Stratum1NormalSampler, coordinates * Stratum1NormalTile.xx) * 2 - 1);
    float4 stratum2Normal = normalize(tex2D(Stratum2NormalSampler, coordinates * Stratum2NormalTile.xx) * 2 - 1);
    float4 stratum3Normal = normalize(tex2D(Stratum3NormalSampler, coordinates * Stratum3NormalTile.xx) * 2 - 1);
    float4 stratum4Normal = normalize(tex2D(Stratum4NormalSampler, coordinates * Stratum4NormalTile.xx) * 2 - 1);
    float4 stratum5Normal = normalize(tex2D(Stratum5NormalSampler, coordinates * Stratum5NormalTile.xx) * 2 - 1);
    float4 stratum6Normal = normalize(tex2D(Stratum6NormalSampler, coordinates * Stratum6NormalTile.xx) * 2 - 1);

    // blend the normals
    float4 normal = base;
    normal = UDNBlending(normal,stratum0Normal,mask0.x);
    normal = UDNBlending(normal,stratum1Normal,mask0.y);
    normal = UDNBlending(normal,stratum2Normal,mask0.z);
    normal = UDNBlending(normal,stratum3Normal,mask0.w);
    normal = UDNBlending(normal,stratum4Normal,mask1.x);
    normal = UDNBlending(normal,stratum5Normal,mask1.y);
    normal = UDNBlending(normal,stratum6Normal,mask1.z);

    return float4( (normal.xyz * 0.5 + 0.5) , normal.w);
}

float4 Terrain003AlbedoPS ( VS_OUTPUT inV, uniform bool halfRange ) : COLOR
{
    float2 coordinates = TerrainScale * inV.mTexWT;

    // x = stratum layer 0
    // y = stratum layer 1
    // z = stratum layer 2
    // w = stratum layer 3
    float4 mask0 = tex2D(UtilitySamplerA, coordinates);

    // x = stratum layer 4
    // y = stratum layer 5
    // z = stratum layer 6
    // w = ??
    float4 mask1 = tex2D(UtilitySamplerB, coordinates);

    if (halfRange) {
        mask0 = saturate(mask0 * 2 - 1);
        mask1 = saturate(mask1 * 2 - 1);
    }

    // x = normals-x
    // y = normals-z
    // z = unused
    // w = shadows
    float4 utility01 = tex2D(UpperAlbedoSampler, coordinates.xy);
    float mapShadow = utility01.w;

    // disable shadows when game settings tell us to
    if (0 == ShadowsEnabled) {
        mapShadow = 1.0f;
    }

    // x = specular
    // y = unused
    // z = unused
    // w = unused
    float4 utility03 = tex2D(Stratum7NormalSampler, coordinates.xy);
    float mapSpecular = utility03.r;

    // sample the albedo's
    float4 lowerAlbedo =    tex2D(LowerAlbedoSampler,    coordinates * LowerAlbedoTile.xx);
    float4 stratum0Albedo = tex2D(Stratum0AlbedoSampler, coordinates * Stratum0AlbedoTile.xx);
    float4 stratum1Albedo = tex2D(Stratum1AlbedoSampler, coordinates * Stratum1AlbedoTile.xx);
    float4 stratum2Albedo = tex2D(Stratum2AlbedoSampler, coordinates * Stratum2AlbedoTile.xx);
    float4 stratum3Albedo = tex2D(Stratum3AlbedoSampler, coordinates * Stratum3AlbedoTile.xx);
    float4 stratum4Albedo = tex2D(Stratum4AlbedoSampler, coordinates * Stratum4AlbedoTile.xx);
    float4 stratum5Albedo = tex2D(Stratum5AlbedoSampler, coordinates * Stratum5AlbedoTile.xx);
    float4 stratum6Albedo = tex2D(Stratum6AlbedoSampler, coordinates * Stratum6AlbedoTile.xx);
    float4 stratum7Albedo = tex2D(Stratum7AlbedoSampler, coordinates);

    // blend the albedo
    float4 albedo = lowerAlbedo;
    albedo = lerp(albedo, stratum0Albedo, mask0.x);
    albedo = lerp(albedo, stratum1Albedo, mask0.y);
    albedo = lerp(albedo, stratum2Albedo, mask0.z);
    albedo = lerp(albedo, stratum3Albedo, mask0.w);
    albedo = lerp(albedo, stratum4Albedo, mask1.x);
    albedo = lerp(albedo, stratum5Albedo, mask1.y);

    // blend map-wide albedo
    albedo = lerp(albedo, stratum7Albedo, stratum7Albedo.w);

    // compute the shadows, combining the baked and dynamic shadows
    float shadow = tex2D(ShadowSampler, inV.mShadow.xy).g; 
    shadow = shadow * mapShadow;

    // normalize the pre-computed normal
    float3 normal = normalize(2 * SampleScreen(NormalSampler,inV.mTexSS).xyz - 1);

    // compute specular
    float3 r = reflect(normalize(inV.mViewDirection), normal);
    float3 specular = pow(saturate(dot(r, SunDirection)), 20) * mapSpecular * stratum7Albedo.w * shadow * SunColor;

    // compute lighting
    float dotSunNormal = max(0, dot(SunDirection, normal));

    // combine everything
    float3 light = SunColor * saturate(dotSunNormal) * shadow + SunAmbience;
    light = LightingMultiplier * light + ShadowFillColor * (1 - light);
    albedo.rgb = light * (albedo.rgb + specular.rgb);

    // compute water ramp intensity
    float waterDepth = tex2D(UtilitySamplerC, coordinates).g;
    albedo.rgb = ApplyWaterColorExponentially(-1 * inV.mViewDirection, inV.mTexWT.z, waterDepth, albedo.rgb);

    return float4(albedo.rgb, 0.01f);
}

technique Terrain003Normals
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RG )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 TerrainVS(false);
        PixelShader = compile ps_2_a Terrain003NormalsPS(true);
    }
}

technique Terrain003 <
    string usage = "composite";
    string normals = "Terrain003Normals"; 
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 TerrainVS(true);
        PixelShader = compile ps_2_a Terrain003AlbedoPS(true);
    }
}

technique Terrain053Normals
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RG )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 TerrainVS(false);
        PixelShader = compile ps_2_a Terrain003NormalsPS(false);
    }
}

technique Terrain053 <
    string usage = "composite";
    string normals = "Terrain053Normals"; 
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 TerrainVS(true);
        PixelShader = compile ps_2_a Terrain003AlbedoPS(false);
    }
}

//#endregion
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
//#region Terrain100
// These use roughness maps for PBR rendering

// Layer| Albedo stratum                                               | Normal stratum
//      | R           | G             | B            | A               | R             | G             | B             | A            |
//  ----            ---             ---             ---              ---             ---             ---             ---            ---
// | L  | R             G               B              unused          | X               Y               Z               unused       |
//  ----            ---             ---             ---              ---             ---             ---             ---            ---
// | S0 | R             G               B              unused          | X               Y               Z               unused       |
// | S1 | R             G               B              unused          | X               Y               Z               unused       |
// | S2 | R             G               B              unused          | X               Y               Z               unused       |
// | S3 | R             G               B              unused          | X               Y               Z               unused       |
//  ----            ---             ---            ---               ---             ---             ---             ---            ---
// | S4 | R             G               B              unused          | X               Y               Z               unused       |
// | S5 | R             G               B              unused          | X               Y               Z               unused       |
// | S6 | R             G               B              unused          | X               Y               Z               unused       |
// | S7 | albedo.r      albedo.g        albedo.b       transparency    | height L-S2   roughness L-S2  height S3-S6   roughness S3-S6 |
//  ----            ---             ---             ---              ---             ---             ---             ---            ---
// | U  | normal.x      normal.z        waterDepth     shadow          | 
//  ----
// The normal map scales are controlled by the albedo scales to ensure that they use the same values.
// The layer mask of S7 acts as a roughness multiplier with 0.5 as the neutral value.

float4 Terrain101NormalsPS ( VS_OUTPUT inV, uniform bool halfRange ) : COLOR
{
    float4 position = TerrainScale * inV.mTexWT;

    float4 mask0 = tex2D(UtilitySamplerA, position.xy);
    float4 mask1 = tex2D(UtilitySamplerB, position.xy);

    if (halfRange) {
        mask0 = saturate(mask0 * 2 - 1);
        mask1 = saturate(mask1 * 2 - 1);
    }

    float3 lowerNormal    = normalize(tex2D(LowerNormalSampler,    position.xy * LowerAlbedoTile.xy   ).rgb * 2 - 1);
    float3 stratum0Normal = normalize(tex2D(Stratum0NormalSampler, position.xy * Stratum0AlbedoTile.xy).rgb * 2 - 1);
    float3 stratum1Normal = normalize(tex2D(Stratum1NormalSampler, position.xy * Stratum1AlbedoTile.xy).rgb * 2 - 1);
    float3 stratum2Normal = normalize(tex2D(Stratum2NormalSampler, position.xy * Stratum2AlbedoTile.xy).rgb * 2 - 1);
    float3 stratum3Normal = normalize(tex2D(Stratum3NormalSampler, position.xy * Stratum3AlbedoTile.xy).rgb * 2 - 1);
    float3 stratum4Normal = normalize(tex2D(Stratum4NormalSampler, position.xy * Stratum4AlbedoTile.xy).rgb * 2 - 1);
    float3 stratum5Normal = normalize(tex2D(Stratum5NormalSampler, position.xy * Stratum5AlbedoTile.xy).rgb * 2 - 1);
    float3 stratum6Normal = normalize(tex2D(Stratum6NormalSampler, position.xy * Stratum6AlbedoTile.xy).rgb * 2 - 1);

    float3 normal = lowerNormal;
    normal = normalize(lerp(normal,stratum0Normal,mask0.x));
    normal = normalize(lerp(normal,stratum1Normal,mask0.y));
    normal = normalize(lerp(normal,stratum2Normal,mask0.z));
    normal = normalize(lerp(normal,stratum3Normal,mask0.w));
    normal = normalize(lerp(normal,stratum4Normal,mask1.x));
    normal = normalize(lerp(normal,stratum5Normal,mask1.y));
    normal = normalize(lerp(normal,stratum6Normal,mask1.z));

    return float4( 0.5 + 0.5 * normal.rgb, 1);
}

float4 Terrain101AlbedoPS ( VS_OUTPUT inV, uniform bool halfRange ) : COLOR
{
    // height is now in the z coordinate
    float4 position = TerrainScale * inV.mTexWT;

    // do arithmetics to get range from (0, 1) to (-1, 1) as normal maps store their values as (0, 1)
    float3 normal = normalize(2 * SampleScreen(NormalSampler,inV.mTexSS).xyz - 1);

    float4 mask0 = tex2D(UtilitySamplerA, position.xy);
    float4 mask1 = tex2D(UtilitySamplerB, position.xy);

    if (halfRange) {
        mask0 = saturate(mask0 * 2 - 1);
        mask1 = saturate(mask1 * 2 - 1);
    }

    float4 lowerAlbedo =    sampleAlbedo(LowerAlbedoSampler,    position.xy, LowerAlbedoTile.xy,    float2(0.0, 0.0), true);
    float4 stratum0Albedo = sampleAlbedo(Stratum0AlbedoSampler, position.xy, Stratum0AlbedoTile.xy, float2(0.5, 0.0), true);
    float4 stratum1Albedo = sampleAlbedo(Stratum1AlbedoSampler, position.xy, Stratum1AlbedoTile.xy, float2(0.0, 0.5), true);
    float4 stratum2Albedo = sampleAlbedo(Stratum2AlbedoSampler, position.xy, Stratum2AlbedoTile.xy, float2(0.5, 0.5), true);
    float4 stratum3Albedo = sampleAlbedo(Stratum3AlbedoSampler, position.xy, Stratum3AlbedoTile.xy, float2(0.0, 0.0), false);
    float4 stratum4Albedo = sampleAlbedo(Stratum4AlbedoSampler, position.xy, Stratum4AlbedoTile.xy, float2(0.5, 0.0), false);
    float4 stratum5Albedo = sampleAlbedo(Stratum5AlbedoSampler, position.xy, Stratum5AlbedoTile.xy, float2(0.0, 0.5), false);
    float4 stratum6Albedo = sampleAlbedo(Stratum6AlbedoSampler, position.xy, Stratum6AlbedoTile.xy, float2(0.5, 0.5), false);

    float4 albedo = lowerAlbedo;
    albedo = lerp(albedo,stratum0Albedo,mask0.x);
    albedo = lerp(albedo,stratum1Albedo,mask0.y);
    albedo = lerp(albedo,stratum2Albedo,mask0.z);
    albedo = lerp(albedo,stratum3Albedo,mask0.w);
    albedo = lerp(albedo,stratum4Albedo,mask1.x);
    albedo = lerp(albedo,stratum5Albedo,mask1.y);
    albedo = lerp(albedo,stratum6Albedo,mask1.z);
    float4 mapwide = tex2D(Stratum7AlbedoSampler, position.xy);
    albedo.rgb = lerp(albedo.rgb, mapwide.rgb, mapwide.a);

    // We need to add 0.01 as the reflection disappears at 0
    float roughness = saturate(albedo.a * mask1.w * 2 + 0.01);

    float waterDepth = tex2D(UpperAlbedoSampler, position.xy).b;
    float3 color = PBR(inV, position, albedo, normal, roughness, waterDepth);
    color = ApplyWaterColorExponentially(-1 * inV.mViewDirection, inV.mTexWT.z, waterDepth, color);

    return float4(color, 0.01f);
}

technique Terrain101Normals
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RG )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 TerrainVS(false);
        PixelShader = compile ps_2_a Terrain101NormalsPS(true);
    }
}

technique Terrain101 <
    string usage = "composite";
    string normals = "Terrain101Normals";
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 TerrainVS(true);
        PixelShader = compile ps_2_a Terrain101AlbedoPS(true);
    }
}

technique Terrain151Normals
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RG )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 TerrainVS(false);
        PixelShader = compile ps_2_a Terrain101NormalsPS(false);
    }
}

technique Terrain151 <
    string usage = "composite";
    string normals = "Terrain151Normals";
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 TerrainVS(true);
        PixelShader = compile ps_2_a Terrain101AlbedoPS(false);
    }
}

//#endregion
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
//#region Terrain300
// These use roughness maps for PBR rendering and height maps for texture splatting

// Layer| Albedo stratum                                               | Normal stratum
//      | R           | G             | B            | A               | R             | G             | B             | A            |
//  ----            ---             ---             ---              ---             ---             ---             ---            ---
// | L  | R             G               B              unused          | X               Y               Z               unused       |
//  ----            ---             ---             ---              ---             ---             ---             ---            ---
// | S0 | R             G               B              unused          | X               Y               Z               unused       |
// | S1 | R             G               B              unused          | X               Y               Z               unused       |
// | S2 | R             G               B              unused          | X               Y               Z               unused       |
// | S3 | R             G               B              unused          | X               Y               Z               unused       |
//  ----            ---             ---            ---               ---             ---             ---             ---            ---
// | S4 | R             G               B              unused          | X               Y               Z               unused       |
// | S5 | R             G               B              unused          | X               Y               Z               unused       |
// | S6 | R             G               B              unused          | X               Y               Z               unused       |
// | S7 | albedo.r      albedo.g        albedo.b       transparency    | height L-S2   roughness L-S2  height S3-S6   roughness S3-S6 |
//  ----            ---             ---             ---              ---             ---             ---             ---            ---
// | U  | normal.x      normal.z        waterDepth     shadow          | 
//  ----
// The normal map scales are controlled by the albedo scales to ensure that they use the same values.
// The layer mask of S7 acts as a roughness multiplier with 0.5 as the neutral value.
// Height processing happens at two scales, the albedo scales control the near scale and the normal scales control the far scale.
// SpecularColor.r is used to control the blurriness of the texture splatting

float4 Terrain301NormalsPS ( VS_OUTPUT inV, uniform bool halfRange ) : COLOR
{
    float4 position = TerrainScale * inV.mTexWT;
    // 30° rotation
    float2x2 rotationMatrix = float2x2(float2(0.866, -0.5), float2(0.5, 0.866));
    position.zw = mul(position.xy, rotationMatrix);

    float4 mask0 = tex2D(UtilitySamplerA, position.xy);
    float4 mask1 = tex2D(UtilitySamplerB, position.xy);

    if (halfRange) {
        mask0 = saturate(mask0 * 2 - 1);
        mask1 = saturate(mask1 * 2 - 1);
    }

    float3 lowerNormal    = normalize(tex2D(LowerNormalSampler,    position.xy * LowerAlbedoTile.xy   ).rgb * 2 - 1);
    float3 stratum0Normal = normalize(tex2D(Stratum0NormalSampler, position.zw * Stratum0AlbedoTile.xy).rgb * 2 - 1);
    float3 stratum1Normal = normalize(tex2D(Stratum1NormalSampler, position.xy * Stratum1AlbedoTile.xy).rgb * 2 - 1);
    float3 stratum2Normal = normalize(tex2D(Stratum2NormalSampler, position.zw * Stratum2AlbedoTile.xy).rgb * 2 - 1);
    float3 stratum3Normal = normalize(tex2D(Stratum3NormalSampler, position.xy * Stratum3AlbedoTile.xy).rgb * 2 - 1);
    float3 stratum4Normal = normalize(tex2D(Stratum4NormalSampler, position.zw * Stratum4AlbedoTile.xy).rgb * 2 - 1);
    float3 stratum5Normal = normalize(tex2D(Stratum5NormalSampler, position.xy * Stratum5AlbedoTile.xy).rgb * 2 - 1);
    float3 stratum6Normal = normalize(tex2D(Stratum6NormalSampler, position.zw * Stratum6AlbedoTile.xy).rgb * 2 - 1);

    float stratum0Height = sampleHeight(position.zw, Stratum0AlbedoTile.xy, Stratum0NormalTile.xy, float2(0.5, 0.0), true);
    float stratum1Height = sampleHeight(position.xy, Stratum1AlbedoTile.xy, Stratum1NormalTile.xy, float2(0.0, 0.5), true);
    float stratum2Height = sampleHeight(position.zw, Stratum2AlbedoTile.xy, Stratum2NormalTile.xy, float2(0.5, 0.5), true);
    float stratum3Height = sampleHeight(position.xy, Stratum3AlbedoTile.xy, Stratum3NormalTile.xy, float2(0.0, 0.0), false);
    float stratum4Height = sampleHeight(position.zw, Stratum4AlbedoTile.xy, Stratum4NormalTile.xy, float2(0.5, 0.0), false);
    float stratum5Height = sampleHeight(position.xy, Stratum5AlbedoTile.xy, Stratum5NormalTile.xy, float2(0.0, 0.5), false);
    float stratum6Height = sampleHeight(position.zw, Stratum6AlbedoTile.xy, Stratum6NormalTile.xy, float2(0.5, 0.5), false);

    float3 normal = lowerNormal;
    normal = splatBlendNormal(normal, stratum0Normal, stratum0Height, mask0.x, SpecularColor.r);
    normal = splatBlendNormal(normal, stratum1Normal, stratum1Height, mask0.y, SpecularColor.r);
    normal = splatBlendNormal(normal, stratum2Normal, stratum2Height, mask0.z, SpecularColor.r);
    normal = splatBlendNormal(normal, stratum3Normal, stratum3Height, mask0.w, SpecularColor.r);
    normal = splatBlendNormal(normal, stratum4Normal, stratum4Height, mask1.x, SpecularColor.r);
    normal = splatBlendNormal(normal, stratum5Normal, stratum5Height, mask1.y, SpecularColor.r);
    normal = splatBlendNormal(normal, stratum6Normal, stratum6Height, mask1.z, SpecularColor.r);

    return float4( 0.5 + 0.5 * normal.rgb, 1);
}

float4 Terrain301AlbedoPS ( VS_OUTPUT inV, uniform bool halfRange ) : COLOR
{
    // height is now in the z coordinate
    float4 position = TerrainScale * inV.mTexWT;
    // 30° rotation
    float2x2 rotationMatrix = float2x2(float2(0.866, -0.5), float2(0.5, 0.866));
    position.zw = mul(position.xy, rotationMatrix);

    // do arithmetics to get range from (0, 1) to (-1, 1) as normal maps store their values as (0, 1)
    float3 normal = normalize(2 * SampleScreen(NormalSampler,inV.mTexSS).xyz - 1);

    float4 mask0 = tex2D(UtilitySamplerA, position.xy);
    float4 mask1 = tex2D(UtilitySamplerB, position.xy);

    if (halfRange) {
        mask0 = saturate(mask0 * 2 - 1);
        mask1 = saturate(mask1 * 2 - 1);
    }

    // This shader wouldn't compile because it would have to store too many variables if we didn't use this trick in the vertex shader
    float4 lowerAlbedo =    sampleAlbedo(LowerAlbedoSampler,    position.xy, LowerAlbedoTile.xy,    float2(0.0, 0.0), true);
    float4 stratum0Albedo = sampleAlbedo(Stratum0AlbedoSampler, position.zw, inV.nearScales.xx,     float2(0.5, 0.0), true);
    float4 stratum1Albedo = sampleAlbedo(Stratum1AlbedoSampler, position.xy, inV.nearScales.yy,     float2(0.0, 0.5), true);
    float4 stratum2Albedo = sampleAlbedo(Stratum2AlbedoSampler, position.zw, inV.nearScales.zz,     float2(0.5, 0.5), true);
    float4 stratum3Albedo = sampleAlbedo(Stratum3AlbedoSampler, position.xy, inV.nearScales.ww,     float2(0.0, 0.0), false);
    float4 stratum4Albedo = sampleAlbedo(Stratum4AlbedoSampler, position.zw, Stratum4AlbedoTile.xy, float2(0.5, 0.0), false);
    float4 stratum5Albedo = sampleAlbedo(Stratum5AlbedoSampler, position.xy, Stratum5AlbedoTile.xy, float2(0.0, 0.5), false);
    float4 stratum6Albedo = sampleAlbedo(Stratum6AlbedoSampler, position.zw, Stratum6AlbedoTile.xy, float2(0.5, 0.5), false);

    float stratum0Height = sampleHeight(position.zw, inV.nearScales.xx,     inV.farScales.xx,      float2(0.5, 0.0), true);
    float stratum1Height = sampleHeight(position.xy, inV.nearScales.yy,     inV.farScales.yy,      float2(0.0, 0.5), true);
    float stratum2Height = sampleHeight(position.zw, inV.nearScales.zz,     inV.farScales.zz,      float2(0.5, 0.5), true);
    float stratum3Height = sampleHeight(position.xy, inV.nearScales.ww,     inV.farScales.ww,      float2(0.0, 0.0), false);
    float stratum4Height = sampleHeight(position.zw, Stratum4AlbedoTile.xy, Stratum4NormalTile.xy, float2(0.5, 0.0), false);
    float stratum5Height = sampleHeight(position.xy, Stratum5AlbedoTile.xy, Stratum5NormalTile.xy, float2(0.0, 0.5), false);
    float stratum6Height = sampleHeight(position.zw, Stratum6AlbedoTile.xy, Stratum6NormalTile.xy, float2(0.5, 0.5), false);

    float4 albedo = lowerAlbedo;
    albedo = splatLerp(albedo, stratum0Albedo, stratum0Height, mask0.x, SpecularColor.r);
    albedo = splatLerp(albedo, stratum1Albedo, stratum1Height, mask0.y, SpecularColor.r);
    albedo = splatLerp(albedo, stratum2Albedo, stratum2Height, mask0.z, SpecularColor.r);
    albedo = splatLerp(albedo, stratum3Albedo, stratum3Height, mask0.w, SpecularColor.r);
    albedo = splatLerp(albedo, stratum4Albedo, stratum4Height, mask1.x, SpecularColor.r);
    albedo = splatLerp(albedo, stratum5Albedo, stratum5Height, mask1.y, SpecularColor.r);
    albedo = splatLerp(albedo, stratum6Albedo, stratum6Height, mask1.z, SpecularColor.r);
    float4 mapwide = tex2D(Stratum7AlbedoSampler, position.xy);
    albedo.rgb = lerp(albedo.rgb, mapwide.rgb, mapwide.a);

    // We need to add 0.01 as the reflection disappears at 0
    float roughness = saturate(albedo.a * mask1.w * 2 + 0.01);
    
    float waterDepth = tex2D(UpperAlbedoSampler, position.xy).b;
    float3 color = PBR(inV, position, albedo, normal, roughness, waterDepth);
    color = ApplyWaterColorExponentially(-1 * inV.mViewDirection, inV.mTexWT.z, waterDepth, color);

    return float4(color, 0.01f);
}

technique Terrain301Normals
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RG )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 TerrainVS(false);
        PixelShader = compile ps_2_a Terrain301NormalsPS(true);
    }
}

technique Terrain301 <
    string usage = "composite";
    string normals = "Terrain301Normals";
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 TerrainVS(true);
        PixelShader = compile ps_2_a Terrain301AlbedoPS(true);
    }
}

technique Terrain351Normals
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RG )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 TerrainVS(false);
        PixelShader = compile ps_2_a Terrain301NormalsPS(false);
    }
}

technique Terrain351 <
    string usage = "composite";
    string normals = "Terrain351Normals";
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 TerrainVS(true);
        PixelShader = compile ps_2_a Terrain301AlbedoPS(false);
    }
}

//#endregion
// ----------------------------------------------------------------------------
