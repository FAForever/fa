////////////////////////////////////////////////////////////////////////////////
///
///	File	: cartographic.fx
///
///	Summary	: Effect file for NPR cartographic view of world.
///
///	Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
////////////////////////////////////////////////////////////////////////////////

#ifdef DIRECT3D10
    typedef uint4 position_t;
#else
    typedef float4 position_t;
#endif

float4x4 viewMatrix;
float4x4 projMatrix;

float4 gridSizeCoeff;
float4 terrainSizeCoeff;
float1 terrainHeightScale;
float1 elevMaximum;
float1 elevMinimum;

float1 frameWidth;
float1 frameHeight;

texture elevTexture;
sampler2D elevSampler = sampler_state {
    Texture   = (elevTexture);
    MipFilter = NONE;
    MinFilter = POINT;
    MagFilter = POINT;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

texture hypsometricTexture;
sampler1D hypsometricSampler = sampler_state {
    Texture   = (hypsometricTexture);
    MipFilter = POINT;
    MinFilter = POINT;
    MagFilter = POINT;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

texture topographicTexture;
sampler1D topographicSampler = sampler_state {
    Texture   = (topographicTexture);
    MipFilter = POINT;
    MinFilter = POINT;
    MagFilter = POINT;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

texture frameTexture;
sampler2D frameSampler = sampler_state {
    Texture   = (frameTexture);
    MipFilter = POINT;
    MinFilter = POINT;
    MagFilter = POINT;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

texture decalTexture;
sampler2D decalSampler = sampler_state
{
    Texture   = (decalTexture);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

struct TerrainVertex
{
    float4 position : POSITION0;
    float3 world : TEXCOORD0;
};
typedef TerrainVertex TerrainPixel;

struct FrameVertex
{
    float4 position : POSITION0;
    float2 texcoord : TEXCOORD0;
};
typedef FrameVertex FramePixel;

struct DecalVertex
{
    float4 position	: POSITION0;
    float2 texcoord : TEXCOORD0;
};
typedef DecalVertex DecalPixel;

TerrainVertex TerrainVS( position_t p : POSITION0)
{
    TerrainVertex result = (TerrainVertex)0;

    result.position = float4(p);
    result.position.y *= terrainHeightScale;
    result.world = result.position.xyz;
    result.position = mul(result.position,mul(viewMatrix,projMatrix));

    return result;
}

DecalVertex DecalVS(
    float2 corner	: POSITION0,
    float3 position	: POSITION1,
    float2 size		: TEXCOORD0,
    float4 texcoord	: TEXCOORD1
)
{
    DecalVertex vertex = (DecalVertex)0;

    float sine = sin(position.z);
    float cosine = cos(position.z);

    vertex.texcoord = texcoord.xy + 0.5*texcoord.zw*(corner+float2(1,1));
    vertex.texcoord.y = 1 - vertex.texcoord.y;

    corner = size * corner;
    float2 r = float2(corner.x * cosine - corner.y * sine,corner.x * sine + corner.y * cosine);

    float2 p = position.xy + float2(r.x,0) + float2(0,-r.y);
    vertex.position = mul(float4(p.x,0,p.y,1),mul(viewMatrix,projMatrix));

    return vertex;
}

float4 TerrainPS0( TerrainPixel pixel) : COLOR0
{
    float2 v0 = terrainSizeCoeff * pixel.world.xz;
    float2 v1 = v0 + float2(1,0);
    float2 v2 = v0 + float2(0,1);
    float2 v3 = v0 + float2(1,1);

    float2 t = v0 - floor(v0);

    float2 h0 = tex2D(elevSampler,gridSizeCoeff*v0).rg;
    float2 h1 = tex2D(elevSampler,gridSizeCoeff*v1).rg;
    float2 h2 = tex2D(elevSampler,gridSizeCoeff*v2).rg;
    float2 h3 = tex2D(elevSampler,gridSizeCoeff*v3).rg;
    float2 h  = clamp(lerp(lerp(h0,h1,t.x),lerp(h2,h3,t.x),t.y) - 0.0001,0,1);

    float3 hypsometric = tex1D(hypsometricSampler,h.x).rgb;
    float1 topographic = tex1D(topographicSampler,h.x).a;

    // if the map doesnt contain color info for contour map already, lets magic some info up
    if (hypsometric[0] == 0 && hypsometric[1] == 0 && hypsometric[2] == 0)
    {
        float chunkiness = 10;
        float3 dark = float3(0.45, 0.38, 0.41);
        float3 light = float3(0.80, 0.80, 0.68);

        // background color is halfway between dark and light
        hypsometric = lerp(dark, light, h.x);

        // the "alpha" we return will be between 0 and 1, and used to determine if we should draw a contour line or not
        // we could just return hyposometric but its too detailed. this logic chunks it up, which ends up drawing nicer lines
        topographic = int((h.x * 100) / chunkiness) * chunkiness / 100;
    }

    return float4(hypsometric,topographic);
}

float4 TerrainPS1( FramePixel pixel) : COLOR0
{
    static const half dx = 1.0 / frameWidth;
    static const half dy = 1.0 / frameHeight;

    float4 color = tex2D(frameSampler,pixel.texcoord);
    half4 c  = color.a;

    ///	The following edge detection filter was adapted from
    /// and example provided by Mark J. Harris and GPGPU.org
    half4 bl = tex2D(frameSampler,pixel.texcoord+half2(-dx,-dy)).a;
    half4 l  = tex2D(frameSampler,pixel.texcoord+half2(-dx,  0)).a;
    half4 tl = tex2D(frameSampler,pixel.texcoord+half2(-dx, dy)).a;
    half4 t  = tex2D(frameSampler,pixel.texcoord+half2(  0, dy)).a;
    half4 ur = tex2D(frameSampler,pixel.texcoord+half2( dx, dy)).a;
    half4 r  = tex2D(frameSampler,pixel.texcoord+half2( dx,  0)).a;
    half4 br = tex2D(frameSampler,pixel.texcoord+half2( dx,-dy)).a;
    half4 b  = tex2D(frameSampler,pixel.texcoord+half2(  0,-dy)).a;
    float topo = saturate( 16.0 * ( c - 0.125 * (bl + l + tl + t + ur + r + br + b )));

    return float4(color.rgb - topo.rrr,0);
}

float4 DecalPS( DecalPixel pixel) : COLOR0
{
    return tex2D(decalSampler,pixel.texcoord);
}

technique Terrain_Stage0
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )

        ZEnable = true;
        ZWriteEnable = true;
        ZFunc = always;

        VertexShader = compile vs_1_1 TerrainVS();
        PixelShader = compile ps_2_0 TerrainPS0();
    }
}

technique Terrain_Stage1
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        DepthState( Depth_Disable )

        VertexShader = FIXED_FUNC_VS;
        PixelShader = compile ps_2_0 TerrainPS1();
    }
}

technique Decal
{
    pass P0
    {
        CullMode = None;

        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        DepthState( Depth_Disable )

        VertexShader = compile vs_1_1 DecalVS();
        PixelShader = compile ps_2_0 DecalPS();
    }
}

technique DecalGlow
{
    pass P0
    {
        CullMode = None;

        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_A )
        DepthState( Depth_Disable )

        VertexShader = compile vs_1_1 DecalVS();
        PixelShader = compile ps_2_0 DecalPS();
    }
}
