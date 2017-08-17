////////////////////////////////////////////////////////////////////////////////
///
///	File	: sky.fx
///
///	Summary	: Effect file for sky dome rendering
///
///	Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
////////////////////////////////////////////////////////////////////////////////

#define CIRRUS_LAYER_COUNT	4
#define TWO_PI				6.283185
#define INV_TWO_PI			0.159155

int tick;
float interpolant;

float3 lightDirection = float3(0.577,0.577,0.577);
float3 lightDiffuse = float3(1,1,1);

float3 viewRight;
float3 viewUp;

float3 viewPosition;
float4x4 viewProjMatrix;

float1 horizonBegin;
float1 horizonEnd;
float3 horizonColor;
float3 skyColor;

float1 decalGlowMultiplier = 0.1;

texture horizonLookup;
sampler2D horizonLookupSampler = sampler_state
{
    Texture   = (horizonLookup);
    MipFilter = NONE;
    MinFilter = POINT;
    MagFilter = POINT;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

texture decalAlbedoTexture;
sampler2D decalAlbedoSampler = sampler_state
{
    Texture   = (decalAlbedoTexture);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

texture decalGlowTexture;
sampler2D decalGlowSampler = sampler_state
{
    Texture   = (decalGlowTexture);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

texture cumulusLightRamp;
sampler1D cumulusLightRampSampler = sampler_state
{
    Texture   = (cumulusLightRamp);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

texture cumulusDispersionRamp;
sampler1D cumulusDispersionRampSampler = sampler_state
{
    Texture   = (cumulusDispersionRamp);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

texture cumulusTexture;
sampler2D cumulusSampler = sampler_state
{
    Texture   = (cumulusTexture);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
};

struct Cirrus {
    float2 frequency;
    float1 speed;
    float2 direction;
};

float1 cirrusMultiplier;
float3 cirrusColor;
Cirrus aCirrus[CIRRUS_LAYER_COUNT];

texture cirrusTexture;
sampler2D cirrusSampler = sampler_state
{
    Texture   = (cirrusTexture);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
};

struct DomeVertex
{
    float4 position		: POSITION0;
    float1 elevation	: TEXCOORD0;
    float1 theta		: TEXCOORD1;
    float4 texcoord0	: TEXCOORD2;
    float4 texcoord1	: TEXCOORD3;
};
typedef DomeVertex DomePixel;

struct DecalVertex
{
    float4 position	: POSITION0;
    float2 texcoord : TEXCOORD0;
};
typedef DecalVertex DecalPixel;

struct CumulusVertex
{
    float4 position	: POSITION0;
    float3 normal	: TEXCOORD0;
    float3 elev		: TEXCOORD1;
    float2 texcoord : TEXCOORD2;
};
typedef CumulusVertex CumulusPixel;

float2 computeCirrusCoord( float time, float2 position, Cirrus cirrus)
{
    float2 direction = normalize(cirrus.direction);

    float2x2 R = float2x2(float2(direction.x,direction.y),float2(direction.y,-direction.x));
    position = mul(position,R);

    return cirrus.frequency * ( position - time * cirrus.speed * direction );
}

DomeVertex DomeVS( float3 position : POSITION0, float theta : TEXCOORD0 )
{
    DomeVertex vertex = (DomeVertex)0;

    float time = (float) tick + interpolant;

    vertex.texcoord0.xy = computeCirrusCoord(time,position.xz,aCirrus[0]);
    vertex.texcoord0.zw = computeCirrusCoord(time,position.xz,aCirrus[1]);
    vertex.texcoord1.xy = computeCirrusCoord(time,position.xz,aCirrus[2]);
    vertex.texcoord1.zw = computeCirrusCoord(time,position.xz,aCirrus[3]);

    vertex.elevation = position.y;
    vertex.theta = theta;

    vertex.position = mul(float4(position,1),viewProjMatrix);

    return vertex;
}

DecalVertex DecalVS(
    float2 corner	: POSITION0,
    float4 position	: POSITION1,
    float2 size		: TEXCOORD0,
    float4 texcoord	: TEXCOORD1
)
{
    DecalVertex vertex = (DecalVertex)0;

    float sine = sin(position.w);
    float cosine = cos(position.w);

    vertex.texcoord = texcoord.xy + 0.5*texcoord.zw*(corner+float2(1,1));
    vertex.texcoord.y = 1 - vertex.texcoord.y;

    corner = size * corner;
    float2 r = float2(corner.x * cosine - corner.y * sine,corner.x * sine + corner.y * cosine);

    position.xyz = position.xyz + r.xxx * viewRight + r.yyy * viewUp;
    vertex.position = mul(float4(position.xyz,1),viewProjMatrix);

    return vertex;
}

CumulusVertex CumulusVS(
    float2 corner			: POSITION0,
    float4 position			: POSITION1,
    float3 groupPosition	: TEXCOORD0,
    float2 groupExtent		: TEXCOORD1,
    float2 size				: TEXCOORD2,
    float4 texcoord			: TEXCOORD3
)
{
    CumulusVertex vertex = (CumulusVertex)0;

    float sine = sin(position.w);
    float cosine = cos(position.w);

    vertex.texcoord = texcoord.xy + 0.5*texcoord.zw*(corner+float2(1,1));
    vertex.texcoord.y = 1 - vertex.texcoord.y;

    corner = size * corner;
    float2 r = float2(corner.x * cosine - corner.y * sine,corner.x * sine + corner.y * cosine);

    position.xyz = position.xyz + r.xxx * viewRight + r.yyy * viewUp;

    vertex.normal = normalize(position.xyz - groupPosition);
    vertex.elev = float3(position.y,groupExtent.x,groupExtent.y);

    vertex.position = mul(float4(position.xyz,1),viewProjMatrix);

    return vertex;
}

float4 AtmospherePS( DomePixel pixel) : COLOR0
{
    float th = INV_TWO_PI*clamp(pixel.theta,0,TWO_PI);
    float tv = clamp(( pixel.elevation - horizonBegin ) / ( horizonEnd - horizonBegin ),0.0,1.0);
    float t = tex2D(horizonLookupSampler,float2(th,0.25)).a * tex2D(horizonLookupSampler,float2(tv,0.75)).a;

    return float4(lerp(horizonColor,skyColor,1-t.rrr).rgb,0);
}

float4 DecalAlbedoPS( DecalPixel pixel) : COLOR0
{
    return tex2D(decalAlbedoSampler,pixel.texcoord);
}

float4 DecalGlowPS( DecalPixel pixel) : COLOR0
{
    float4 texel = tex2D(decalGlowSampler,pixel.texcoord);
    return float4(0,0,0,decalGlowMultiplier*texel.a);
}

float4 CumulusPS( CumulusPixel pixel) : COLOR0
{
    float2 texel = tex2D(cumulusSampler,pixel.texcoord).ra;

    float1 t = saturate(dot(normalize(pixel.normal),normalize(lightDirection)));
    float1 h = ( clamp(pixel.elev.x,pixel.elev.y,pixel.elev.z) - pixel.elev.y ) / (pixel.elev.z - pixel.elev.y);

    float4 dispersion = tex1D(cumulusDispersionRampSampler,h);

    float3 light = lightDiffuse * tex1D(cumulusLightRampSampler,t) * dispersion.rgb;
    float3 color = light * texel.rrr;

    return float4(color,dispersion.a*texel.g);
}

float4 CirrusPS( DomePixel pixel) : COLOR0
{
    float c0 = tex2D(cirrusSampler,pixel.texcoord0.xy).r;
    float c1 = tex2D(cirrusSampler,pixel.texcoord0.zw).g;
    float c2 = tex2D(cirrusSampler,pixel.texcoord1.xy).b;
    float c3 = tex2D(cirrusSampler,pixel.texcoord1.zw).a;
    float alpha = cirrusMultiplier * c0 * c1 * c2 * c3;
    return float4(cirrusColor,alpha);
}

technique Atmosphere
{
    pass P0
    {
        CullMode = CW;

        AlphaState( AlphaBlend_Disable_Write_RGB )

        ZWriteEnable = false;
        ZEnable = false;
        ZFunc = less;

        VertexShader = compile vs_1_1 DomeVS();
        PixelShader = compile ps_2_0 AtmospherePS();
    }
}

technique Decal
{
    pass P0
    {
        CullMode = CW;

        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )

        ZWriteEnable = false;
        ZEnable = false;
        ZFunc = less;

        VertexShader = compile vs_1_1 DecalVS();
        PixelShader = compile ps_2_0 DecalAlbedoPS();
    }
    pass P1
    {
        CullMode = CW;

        AlphaState( AlphaBlend_Disable_Write_A )

        ZWriteEnable = false;
        ZEnable = false;
        ZFunc = less;

        VertexShader = compile vs_1_1 DecalVS();
        PixelShader = compile ps_2_0 DecalGlowPS();
    }
}

technique Cumulus
{
    pass P0
    {
        CullMode = CW;

        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )

        ZWriteEnable = false;
        ZEnable = false;
        ZFunc = less;

        VertexShader = compile vs_1_1 CumulusVS();
        PixelShader = compile ps_2_0 CumulusPS();
    }
}

technique Cirrus
{
    pass P0
    {
        CullMode = CW;

        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )

        ZWriteEnable = false;
        ZEnable = false;
        ZFunc = less;

        VertexShader = compile vs_1_1 DomeVS();
        PixelShader = compile ps_2_0 CirrusPS();
    }
}
