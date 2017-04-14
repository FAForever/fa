#define FIDELITY_LOW            0x00
#define FIDELITY_MEDIUM         0x01
#define FIDELITY_HIGH           0x02

#ifdef DIRECT3D10
    typedef uint4 position_t;
#else
    typedef float4 position_t;
#endif

float4x4    ViewMatrix;
float4x4    ProjMatrix;

float        LightingMultiplier;

float3        SunDirection;
float3        SunAmbience;
float3        SunColor;
float3        HalfAngle;
float3      CameraPosition;
float3      CameraDirection;
float4      SpecularColor;

int         ShadowsEnabled;
float       ShadowSize;
float4x4    ShadowMatrix;
texture        ShadowTexture;
float3        ShadowFillColor = float3(0,0,0);

texture     WaterRamp;
float        WaterElevation;
float        WaterElevationDeep;
float        WaterElevationAbyss;

float        Time;

texture        NoiseTexture;        // the fog noise texture
texture     OverlayTexture;     // debug terrain overlay

texture        UtilityTextureA;
texture        UtilityTextureB;
texture        UtilityTextureC;

float4      NormalMapScale;
float4      NormalMapOffset;
float4      SampleOffset;
float2      ViewportScale;
float2      ViewportOffset;

#define DECLARE_STRATUM(n)                        \
    float4 n##Tile;                                \
    texture n##Texture;                            \
    sampler2D n##Sampler = sampler_state        \
    {                                            \
        Texture   = <n##Texture>;                \
        MipFilter = LINEAR;                        \
        MinFilter = LINEAR;                        \
        MagFilter = LINEAR;                        \
        AddressU  = WRAP;                        \
        AddressV  = WRAP;                        \
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

texture        NormalTexture;

float4x4    DecalMatrix;
float4x4    TangentMatrix;
texture        DecalAlbedoTexture;
texture        DecalNormalTexture;
texture     DecalSpecTexture;
texture        DecalMaskTexture;
float       DecalAlpha;

float4 TerrainScale; // scale of the terrain for generating texture coordinates

// scale of Y coordinate as it's 16-bit
float  HeightScale;

struct VS_OUTPUT
{
    float4 mPos                    : POSITION0;
    float4 mTexWT                : TEXCOORD1;
    float4 mTexSS                : TEXCOORD2;
    float4 mShadow              : TEXCOORD3;
    float3 mViewDirection        : TEXCOORD4;
    float4 mTexDecal            : TEXCOORD5;
};

struct TERRAIN_DEPTH
{
    float4 mPos         : POSITION0;
    float4 mDepth       : TEXCOORD0;
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
    MipFilter = POINT;
    MinFilter = POINT;
    MagFilter = POINT;
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
float3 ApplyWaterColor( float depth, float3  inColor)
{
#ifdef DIRECT3D10
    float4 wcolor = tex2D(WaterRampSampler, float2(depth,0));
#else
    float4 wcolor = tex1D(WaterRampSampler, depth);
#endif
    return lerp( inColor.xyz, wcolor.xyz, wcolor.w );
}

// calculate the lit pixels
float4 CalculateLighting( float3 inNormal, float3 inViewPosition, float3 inAlbedo, float specAmount, float waterDepth, float4 inShadow, uniform bool inShadows)
{
    float4 color = float4( 0, 0, 0, 0 );
    float shadow = ( inShadows && ( 1 == ShadowsEnabled ) ) ? ComputeShadow( inShadow ) : 1;

    // calculate some specular
    float3 viewDirection = normalize(inViewPosition.xzy-CameraPosition);

    float SunDotNormal = dot( SunDirection, inNormal);
    float3 R = SunDirection - 2.0f * SunDotNormal * inNormal;
    float specular = pow( saturate( dot(R, viewDirection) ), 80) * SpecularColor.x * specAmount;

    float3 light = SunColor * saturate( SunDotNormal) * shadow + SunAmbience + specular;
    light = LightingMultiplier * light + ShadowFillColor * ( 1 - light );
    color.rgb = light * inAlbedo;

    // instead of calculating the fog based
    // on the absolute depth, calculate it based
    // on the length from that depth at this map
    // coordinate
    color.rgb = ApplyWaterColor( waterDepth, color );

    color.a = 0.01f + (specular*SpecularColor.w);
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
    float4 mask = tex2D( UtilitySamplerA, inV.mTexWT * TerrainScale);
    float4 lowerNormal = tex2D( LowerNormalSampler, inV.mTexWT  * TerrainScale * LowerNormalTile ) * 2 - 1;
    float4 stratum0Normal = tex2D( Stratum0NormalSampler, inV.mTexWT  * TerrainScale * Stratum0NormalTile ) * 2 - 1;
    float4 stratum1Normal = tex2D( Stratum1NormalSampler, inV.mTexWT  * TerrainScale * Stratum1NormalTile ) * 2 - 1;
    float4 stratum2Normal = tex2D( Stratum2NormalSampler, inV.mTexWT  * TerrainScale * Stratum2NormalTile ) * 2 - 1;
    float4 stratum3Normal = tex2D( Stratum3NormalSampler, inV.mTexWT  * TerrainScale * Stratum3NormalTile ) * 2 - 1;

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
    float4 mask0 = tex2D(UtilitySamplerA,pixel.mTexWT*TerrainScale);
    float4 mask1 = tex2D(UtilitySamplerB,pixel.mTexWT*TerrainScale);

    float4 lowerNormal = tex2D(LowerNormalSampler,pixel.mTexWT*TerrainScale*LowerNormalTile)*2-1;
    float4 stratum0Normal = tex2D(Stratum0NormalSampler,pixel.mTexWT*TerrainScale*Stratum0NormalTile)*2-1;
    float4 stratum1Normal = tex2D(Stratum1NormalSampler,pixel.mTexWT*TerrainScale*Stratum1NormalTile)*2-1;
    float4 stratum2Normal = tex2D(Stratum2NormalSampler,pixel.mTexWT*TerrainScale*Stratum2NormalTile)*2-1;
    float4 stratum3Normal = tex2D(Stratum3NormalSampler,pixel.mTexWT*TerrainScale*Stratum3NormalTile)*2-1;
    float4 stratum4Normal = tex2D(Stratum4NormalSampler,pixel.mTexWT*TerrainScale*Stratum4NormalTile)*2-1;
    float4 stratum5Normal = tex2D(Stratum5NormalSampler,pixel.mTexWT*TerrainScale*Stratum5NormalTile)*2-1;
    float4 stratum6Normal = tex2D(Stratum6NormalSampler,pixel.mTexWT*TerrainScale*Stratum6NormalTile)*2-1;
    float4 stratum7Normal = tex2D(Stratum7NormalSampler,pixel.mTexWT*TerrainScale*Stratum7NormalTile)*2-1;

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
    return tex_source00.xxwy;
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
    float4 water = tex1D(WaterRampSampler,waterDepth);
    albedo.rgb = lerp(albedo.rgb,water.rgb,water.a);

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
        PixelShader = compile ps_2_0 TerrainPS( true);
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
        PixelShader = compile ps_2_0 TerrainAlbedoXP();
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
        PixelShader = compile ps_2_0 TerrainGlowPS( true);
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
    float4 decalAlbedo = tex2Dproj( DecalAlbedoSampler, inV.mTexDecal );
    float4 decalSpec = tex2Dproj( DecalSpecSampler, inV.mTexDecal );
    float4 decalMask = tex2Dproj( DecalMaskSampler, inV.mTexDecal ).xxxx;
    float3 normal = SampleScreen(NormalSampler, inV.mTexSS).xyz * 2 -1;

    float waterDepth = tex2Dproj( UtilitySamplerC, inV.mTexWT * TerrainScale).g;
    // calculate the lit pixel
    float3 color = CalculateLighting( normal, inV.mTexWT.xyz, decalAlbedo.xyz, decalSpec.r, waterDepth, inV.mShadow, inShadows).xyz;
    return float4( color.rgb, decalAlbedo.w * decalMask.w * DecalAlpha);
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
        PixelShader = compile ps_2_0 DecalsPS( true);
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
