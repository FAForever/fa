///////////////////////////////////////////////////////////////////////////////
///
/// File     :  mesh.fx
/// Author(s):  Ivan Rumsey, Gordon Duclos, Greg Kohne
///
/// Summary  :  Effect file for mesh rendering.
///
/// Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////
///
/// Defines
///
///////////////////////////////////////

#define BONE_MAXIMUM            80

#define FIDELITY_LOW            0x00
#define FIDELITY_MEDIUM         0x01
#define FIDELITY_HIGH           0x02

#define STAGE_DEPTH             0x01
#define STAGE_REFLECTION        0x02
#define STAGE_PREEFFECT         0x04
#define STAGE_POSTEFFECT        0x08
#define STAGE_PREWATER          0x10
#define STAGE_POSTWATER         0x20

#define PARAM_UNUSED            0
#define PARAM_FRACTIONCOMPLETE  1
#define PARAM_FRACTIONHEALTH    2
#define PARAM_LIFETIME          3
#define PARAM_AUXILIARY			4

#define SELF_SHADOW

///////////////////////////////////////
///
///	Typedefs
///
///////////////////////////////////////

#ifdef DIRECT3D10
    typedef uint4 anim_t;
#else
    typedef float4 anim_t;
#endif

///////////////////////////////////////
///
/// Shader constants
///
///////////////////////////////////////

float       glowMultiplier  = 2.000;
float       glowMinimum     = 0.010;

float4      terrainScale;
texture		hypsometricTexture;
texture     environmentTexture;
texture     anisotropicTexture;
texture     insectTexture;
float       time;
float4		lodBasis;
float4x4    viewMatrix;
float4x4    projMatrix;
float3      windDirection = float3(0.707, 0.0, 0.707);
float       lightMultiplier;
float3      sunDirection;
float3      sunDiffuse;
float3      sunAmbient;
float3      shadowFill;
int         shadowsEnabled;
float4x4    shadowMatrix;
texture     shadowTexture;
int         shadowBlur;
float       shadowSize;
float       shadowBias;
int         mirrored;
texture     waterRamp;
float1		minimumElevation;
float1		maximumElevation;
float       surfaceElevation;
float       abyssElevation;
texture     dissolveTexture;
texture     albedoTexture;
texture     normalsTexture;
texture     specularTexture;
texture     lookupTexture;
texture     secondaryTexture;
float4      transPalette[BONE_MAXIMUM];
float4      rotPalette[BONE_MAXIMUM];

///	Qualitative constants to tweak phong amount in shaders...
float3 AeonPhongCoeff = float3(0.8,0.85,1.10);
float3 NormalMappedPhongCoeff = float3(0.6,0.80,0.90);


///////////////////////////////////////
///
/// Samplers
///
///////////////////////////////////////

sampler1D hypsometricSampler = sampler_state
{
    Texture   = (hypsometricTexture);
    MipFilter = POINT;
    MinFilter = POINT;
    MagFilter = POINT;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

samplerCUBE environmentSampler = sampler_state
{
    Texture   = (environmentTexture);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
};

sampler2D dissolveSampler = sampler_state
{
    Texture   = (dissolveTexture);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
};

sampler2D shadowSampler = sampler_state
{
    Texture   = (shadowTexture);
    MipFilter = POINT;
    MinFilter = POINT;
    MagFilter = POINT;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

sampler2D shadowPCFSampler = sampler_state
{
    Texture		= (shadowTexture);
    MipFilter	= LINEAR;
    MinFilter	= LINEAR;
    MagFilter	= LINEAR;
    AddressU	= BORDER;
    AddressV	= BORDER;
#ifndef DIRECT3D10
    BorderColor = 0xFFFFFFFF;
#else
    BorderColor = float4(1,1,1,1);
#endif

};

sampler2D albedoSampler = sampler_state
{
    Texture   = (albedoTexture);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
};

sampler2D normalsSampler = sampler_state
{
    Texture   = (normalsTexture);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
};

sampler2D specularSampler = sampler_state
{
    Texture   = (specularTexture);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
};

sampler2D lookupSampler = sampler_state
{
    Texture   = (lookupTexture);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
};

sampler2D secondarySampler = sampler_state
{
    Texture   = (secondaryTexture);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
};

// We use this to store the BRDF response, but we need to keep the name for the engine (I guess)
sampler2D anisotropicSampler = sampler_state
{
    Texture = (anisotropicTexture);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

sampler2D insectSampler = sampler_state
{
    Texture = (insectTexture);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

sampler2D falloffSampler = sampler_state
{
    Texture   = (lookupTexture);
    MipFilter = NONE;
    MinFilter = POINT;
    MagFilter = POINT;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

sampler WaterRampSampler = sampler_state
{
    Texture = (waterRamp);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

///////////////////////////////////////
///
/// Structures
///
///////////////////////////////////////

struct DEPTH_VERTEX
{
    float4 position : POSITION0;
    float4 texcoord0 : TEXCOORD0;
    float depth : TEXCOORD2;
};

struct SILHOUETTE_VERTEX
{
    float4 position : POSITION0;
};

struct CLUTTER_VERTEX
{
    float4 position : POSITION0;
    float3 normal : TEXCOORD3;
    float3 tangent : TEXCOORD4;
    float3 binormal : TEXCOORD5;
    float4 texcoord0 : TEXCOORD0;
    float4 shadow : TEXCOORD2;
    float  dissolve : TEXCOORD7;
};

struct CARTOGRAPHIC_VERTEX
{
    float4 position		: POSITION0;
    float1 elevation	: TEXCOORD0;
    float4 texcoord		: TEXCOORD1;
    float4 color		: COLOR0;
    float3 normal		: TEXCOORD2;
    float3 binormal		: TEXCOORD3;
    float3 tangent		: TEXCOORD4;
};

struct FLAT_VERTEX
{
    float4 position : POSITION0;
    float4 texcoord0 : TEXCOORD0;
    float4 color : COLOR0;
    float4 material : TEXCOORD1;
    float2 depth : TEXCOORD2;
};

struct VERTEXNORMAL_VERTEX
{
    float4 position : POSITION0;
    float3 normal : TEXCOORD3;
    float4 texcoord0 : TEXCOORD0;
    float3 viewDirection : TEXCOORD5;
    float4 shadow : TEXCOORD2;
    float4 color : COLOR0;
    float4 material : TEXCOORD1;
    float  depth : TEXCOORD4;
};

struct NORMALMAPPED_VERTEX
{
    float4 position : POSITION0;
    float3 normal : TEXCOORD3;
    float3 tangent : TEXCOORD4;
    float3 binormal : TEXCOORD5;
    float4 texcoord0 : TEXCOORD0;
    float3 viewDirection : TEXCOORD6;
    float4 shadow : TEXCOORD2;
    float4 color : COLOR0;
    float4 material : TEXCOORD1;	/// various uses
    float2 depth : TEXCOORD7;
};

struct EFFECT_VERTEX
{
    float4 position : POSITION0;
    float3 normal : TEXCOORD3;
    float3 color : COLOR0;
    float4 texcoord0 : TEXCOORD0;
    float4 texcoord1 : TEXCOORD2;
    float4 material : TEXCOORD1;
    float  depth : TEXCOORD4;
};

struct EFFECT_NORMALMAPPED_VERTEX
{
    float4 position : POSITION0;
    float3 normal : TEXCOORD3;
    float3 tangent : TEXCOORD4;
    float3 binormal : TEXCOORD5;
    float4 texcoord0 : TEXCOORD0;
    float4 texcoord1 : TEXCOORD2;
    float3 viewDirection : TEXCOORD6;
    float4 color : COLOR0;
    float4 material : TEXCOORD1;
    float2 depth : TEXCOORD7;
};

struct LOFIEFFECT_VERTEX
{
    float4 position : POSITION0;
    float3 normal : TEXCOORD3;
    float3 color : COLOR0;
    float2 texcoord0 : TEXCOORD0;
    float2 texcoord1 : TEXCOORD2;
    float2 texcoord2 : TEXCOORD5;
    float4 material : TEXCOORD1;
    float  depth : TEXCOORD4;
};

struct SHIELDIMPACT_VERTEX
{
    float4 position : POSITION0;
    float2 texcoord0 : TEXCOORD0;
    float2 texcoord1 : TEXCOORD1;
    float2 texcoord2 : TEXCOORD2;
    float4 material : TEXCOORD3;
    float  depth : TEXCOORD4;
};

///////////////////////////////////////
///
/// Functions
///
///////////////////////////////////////

bool IsExperimentalShader() {
    // lightMultiplier is one of the few variables that is driven by the map,
    // but accessible by the mesh shader.
    return lightMultiplier > 2.1;
}

/// ComputeMatrix
///
/// Compute matrix from scale, translation, and quaternion.
float4x4 ComputeMatrix( float s, float3 T, float4 Q)
{
    float4x4 M;

    float x = Q.x, y = Q.y, z = Q.z, w = Q.w;
    float x2 = 2 * x, y2 = 2 * y, z2 = 2 * z, w2 = 2 * w;
    float xx2 = x * x2, yy2 = y * y2, zz2 = z * z2;
    float xy2 = x * y2, xz2 = x * z2, xw2 = x * w2, yz2 = y * z2, yw2 = y * w2, zw2 = z * w2;

    M._m00 = s * ( 1 - ( yy2 + zz2 ));
    M._m01 = s * ( xy2 + zw2 );
    M._m02 = s * ( xz2 - yw2 );
    M._m03 = 0;

    M._m10 = s * ( xy2 - zw2 );
    M._m11 = s * ( 1 - ( xx2 + zz2 ));
    M._m12 = s * ( yz2 + xw2 );
    M._m13 = 0;

    M._m20 = s * ( xz2 + yw2 );
    M._m21 = s * ( yz2 - xw2 );
    M._m22 = s * ( 1 - ( xx2 + yy2 ));
    M._m23 = 0;

    M._m30 = T.x;
    M._m31 = T.y;
    M._m32 = T.z;
    M._m33 = 1;

    return M;
}

/// ComputePaletteMatrix
///
/// Compute matrix from an index into the bone palette.
float4x4 ComputePaletteMatrix( int index)
{
    float4 translation = transPalette[index];
    return ComputeMatrix( translation.w, translation.xyz, rotPalette[index]);
}

/// ComputeWorldMatrix
///
/// Computes the bone-to-world matrix given the bone index and
/// rows of the model to world matrix.
float4x4 ComputeWorldMatrix( int index, float3 row0, float3 row1, float3 row2, float3 row3)
{
    return mul(ComputePaletteMatrix(index),float4x4(float4(row0,0),float4(row1,0),float4(row2,0),float4(row3,1)));
}

/// ComputeShadowTexcoord
///
/// Computes the shadow texture coordinate of a point given in world space.
float4 ComputeShadowTexcoord( float4 worldPosition)
{
    float4 texcoord = mul( worldPosition, shadowMatrix);
    texcoord.x = ( +texcoord.x + texcoord.w ) * 0.5;
    texcoord.y = ( -texcoord.y + texcoord.w ) * 0.5;
    texcoord.z /= texcoord.w;

    return texcoord;
}

/// ComputeScrolledTexcoord
///
///
float4 ComputeScrolledTexcoord( float4 texcoord, float4 material)
{
    float4 scrolled = texcoord;
    if ( texcoord.y > 0.95 )
    {
        scrolled.x += material.z;
        scrolled.z += material.z;
    }
    else if ( texcoord.y > 0.90 )
    {
        scrolled.x += material.w;
        scrolled.z += material.w;
    }
    return scrolled;
}

/// ComputeShadow
///
/// Computes the "light attenuation factor" for a pixel given its shadow
/// texture coordinate and depth from light.
// *** Standard Shadow Mapping ***
float ComputeShadowStandard( float4 shadowCoords)
{
#ifdef SELF_SHADOW
    shadowCoords.xy /= shadowCoords.w;

    // Standard shadow map comparison
    float shadow = 1.0f;
    if( shadowsEnabled && shadowCoords.z > tex2D( shadowSampler, shadowCoords.xy ).r + shadowBias  )
    {
        shadow = 0.0f;
    }
    return shadow;
#else
    return 1;
#endif
}


// *** Percentage Closer Filtering Shadow Mapping ***
float ComputeShadowPCF( float4 shadowCoords)
{
#ifdef SELF_SHADOW
    shadowCoords.xy /= shadowCoords.w;

    // *** PCF Percentage Closer Filtering ***
    // If we only support 1024x1024 shadow maps we can take out the
    // 'shadowSize' var dependancy. and use a lookup table.
    // Would make this function faster.
    //
    // Altered PCF Kernal:
    //
    //          4
    //
    //      .---1---.
    //      |       |
    //   2  0   X   |  3
    //      |       |
    //      '-------'
    //
    //

    float shadow = 0.0f;
    float texel	 = 1.0f / shadowSize;
    float offset = texel; // make this larger if you want a bigger 'blur'.

    float depthArray[5];
    depthArray[0] = tex2D( shadowPCFSampler, shadowCoords.xy + float2( -(texel * 0.5f),	0.0f ) ).r;
    depthArray[1] = tex2D( shadowPCFSampler, shadowCoords.xy + float2( 0.0f,  -(texel * 0.5f)) ).r;
    depthArray[2] = tex2D( shadowPCFSampler, shadowCoords.xy + float2( -offset,			0.0f ) ).r;
    depthArray[3] = tex2D( shadowPCFSampler, shadowCoords.xy + float2(  offset,			0.0f ) ).r;
    depthArray[4] = tex2D( shadowPCFSampler, shadowCoords.xy + float2( 0.0f,		  offset ) ).r;

    // Sample each of them checking whether the pixel under test is shadowed or not
    for( int i = 0; i < 5; i++ )
    {
        float A = depthArray[i] + shadowBias;
        float B = (shadowCoords.z - 0.001f);
        if( A > B )
        {
            shadow += 1.0f;
        }
    }

    // Get the average
    return shadow * (1.0f / 5.0f);
#else
    return 1;
#endif
}

float ComputeShadow( float4 shadowCoords, uniform bool hiDefFiltering )
{
#ifdef SELF_SHADOW
    // If we are allowed to use hiDefFiltering then allow ShadowPCF
    if( hiDefFiltering )
    {
        return shadowBlur ? (shadowsEnabled ? ComputeShadowPCF( shadowCoords) : 1.0f) : ComputeShadowStandard( shadowCoords);
    }
    else
    {
        return ComputeShadowStandard( shadowCoords);
    }
#else
    return 1;
#endif
}

/// ComputeLight
///
/// Computes the sun's contribution to the pixel's color given the dot product
/// of the light direction and surface normal.  The dot product is precomputed
/// since other portions of the pixel shader might need it (and we need to reuse
/// as many calculations as possible.)
float3 ComputeLight( float dotLightNormal, float attenuation)
{
    /// Typical L.N calculation.
    float3 light = sunDiffuse * saturate( dotLightNormal ) * attenuation + sunAmbient;
    /// The following will "fill in" the shadow color proportional to the absence of light.
    /// This considers the absence of light due to shadows and surface normals pointing away from the light.
    /// This way all dark areas match (very cool.)
    return lightMultiplier * light + ( 1 - light ) * shadowFill;
}
float3 ComputeLight_02( float dotLightNormal, float attenuation)
{
    /// Typical L.N calculation.
    float3 light = sunDiffuse * saturate( dotLightNormal ) * attenuation + sunAmbient;
    /// The following will "fill in" the shadow color proportional to the absence of light.
    /// This considers the absence of light due to shadows and surface normals pointing away from the light.
    /// This way all dark areas match (very cool.)
    //return lightMultiplier * light + ( 1 - light ) * shadowFill;
    //return (saturate(lightMultiplier) * light + ( 0.4 - light * 0.4) * shadowFill) * 1.4;
    return (saturate(lightMultiplier) * light + ( 0.1 - light * 0.1) * (shadowFill + 1)) * 1.2;
}

/// ComputeNormal
///
///
float3 ComputeNormal( sampler2D source, float2 uv, float3x3 rotationMatrix)
{
    float3 normal = 2 * tex2D( source, uv).gaa - 1;
    normal.z = sqrt( 1 - normal.x*normal.x - normal.y*normal.y );
    return normalize( mul( normal, rotationMatrix));
}

float3 ApplyWaterColor(float depth, float3 viewDirection, float3 color, float3 emission = float3(0, 0, 0)) {
    // disable the whole thing on land-only maps
    if (surfaceElevation > 0) {
        // we need this switch to make it consistent with the terrain shader coloration
        if (IsExperimentalShader()) {
            // We need to multiply by 2 to match the terrain shader.
            float scaledDepth = (-depth / (surfaceElevation - abyssElevation)) * 2;
            float3 up = float3(0,1,0);
            // this is the length that the light travels underwater back to the camera
            float oneOverCosV = 1 / max(dot(up, normalize(viewDirection)), 0.0001);
            // Light gets absorbed exponentially.
            // To simplify, we assume that the light enters vertically into the water.
            float waterAbsorption = 1 - saturate(exp(-scaledDepth * (1 + oneOverCosV)));
            // when the mesh emits light, then the path from the surface to the mesh doesn't apply
            float emissionTransmitted = saturate(exp(-scaledDepth * oneOverCosV));
            // darken the color first to simulate the light absorption on the way in and out
            color *= 1 - waterAbsorption;
            // lerp in the watercolor to simulate the scattered light from the dirty water
            float4 waterColor = tex1D(WaterRampSampler, waterAbsorption);
            color = lerp(color, waterColor.rgb, waterAbsorption);
            // similarly tune down the emission light
            color += emission * emissionTransmitted;
        } else {
            float4 waterColor = tex1D(WaterRampSampler, -depth / (surfaceElevation - abyssElevation));
            color = lerp(color, waterColor.rgb, waterColor.w);
            color += emission;
        }
    } else {
        color += emission;
    }
    return color;
}

/////////////////////////////////////////////////
// Physically Based Rendering
/////////////////////////////////////////////////

const float PI = 3.14159265359;

float mapRange(float value, float min1, float max1, float min2, float max2)
{
    // Convert the current value to a percentage
    float perc = (value - min1) / (max1 - min1);
    // Do the same operation backwards with min2 and max2
    return perc * (max2 - min2) + min2;
}

float logisticFn(float x, float x0, float k, float L, float m)
{
    float denom = 1 + pow(2.71828, -k * (m * x - x0));
    return L / denom;
}

float3 FresnelSchlick(float hDotN, float3 F0)
{
    return F0 + (1.0 - F0) * pow(1.0 - hDotN, 5.0);
}

float3 FresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
{
    return F0 + (max(float3(1.0, 1.0, 1.0) - roughness, F0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
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

float3 PBR(
    NORMALMAPPED_VERTEX vertex,
    float3 albedo,
    float metallic,
    float roughness,
    float3 n,
    uniform bool hiDefShadows,
    // Common material specular values:
    // water: .02
    // plastic: .03-.05
    // most materials: .04
    // diamond: .17
    // Not used for metals
    float facingSpecular = .04,
    float ao = 1
) : COLOR0
{
    // See https://blog.selfshadow.com/publications/s2013-shading-course/

    float3 v = normalize(vertex.viewDirection);
    float3 reflection = reflect(-v, n);

    // We can't use texCUBElod so we need to use a workaround
    float lod = roughness * 10;
    float scale = exp2(lod);
    float3 env_reflection = texCUBEgrad(environmentSampler, reflection, float3(scale/256, 0, 0), float3(0, scale/256, 0));
    // This should be convolved into a proper irradiance map, but we will settle for lod 5 for now
    scale = exp2(5);
    float3 env_irradiance = texCUBEgrad(environmentSampler, n, float3(scale/256, 0, 0), float3(0, scale/256, 0));

    float2 envBRDFlookuptexture = tex2D(anisotropicSampler, float2(dot(n, v), 1 - roughness)).rg;
    // We don't have good ao textures to counteract fresnel highlights showing in unplausible places,
    // so we have to tune them down a bit across the board.
    envBRDFlookuptexture.g *= 0.5;

    //////////////////////////////
    // Compute sun light
    //

    // specular reflections of dielectrics mostly disappear underwater
    if (vertex.depth.x < 0) {
        facingSpecular = facingSpecular * 0.05;
    }
    float3 F0 = lerp(float3(facingSpecular, facingSpecular, facingSpecular), albedo, metallic);
    float3 l = sunDirection;
    float3 h = normalize(v + l);
    float nDotL = max(dot(n, l), 0.0);
    // Normal maps can cause an angle > 90° between n and v which would
    // cause artifacts if we don't take some countermeasures
    float nDotV = abs(dot(n, v)) + 0.001;

    float shadow = ComputeShadow(vertex.shadow, hiDefShadows);
    float3 sunLight = sunDiffuse * lightMultiplier * shadow;

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
    kD *= 1.0 - metallic;	

    float3 refracted = kD * albedo;
    float3 irradiance = sunLight * nDotL;
    float3 color = (refracted + reflected) * irradiance;

    //////////////////////////////
    // Compute environment light
    //
    float3 kS = FresnelSchlickRoughness(nDotV, F0, roughness);
    kD = float3(1.0, 1.0, 1.0) - kS;
    kD *= 1.0 - metallic;

    // We need to do this to stay consistent with ComputeLight()
    float3 shadowColor = (1 - (sunDiffuse * shadow * nDotL + sunAmbient)) * shadowFill;
    float3 ambient = sunAmbient * lightMultiplier + shadowColor;

    // As maps were not created with this shader in mind we need to do some tuning to match
    // the shadows of the terrain. This is very non-physical and uses empirical values.
    float shadowCorrection = saturate((ambient.r + ambient.g + ambient.b) / 3);
    shadowCorrection = lerp(shadowCorrection, 1, shadow * nDotL);
    env_irradiance *= shadowCorrection;
    env_reflection *= shadowCorrection;
    env_irradiance += ambient * 0.5;
    env_reflection += ambient * 0.15;

    float3 diffuse = env_irradiance * albedo;
    float3 specular = env_reflection * (kS * envBRDFlookuptexture.r + envBRDFlookuptexture.g);
    color += (kD * diffuse + specular) * ao;

    return color;
}

float4 PBR_UEF(NORMALMAPPED_VERTEX vertex, float teamColorFactor, uniform bool hiDefShadows) : COLOR0
{
    float3x3 rotationMatrix = float3x3(vertex.binormal, vertex.tangent, vertex.normal);
    float3 normal = ComputeNormal(normalsSampler, vertex.texcoord0.zw, rotationMatrix);
    float3 albedo = tex2D(albedoSampler, vertex.texcoord0.xy).rgb;
    float4 specular = tex2D(specularSampler, vertex.texcoord0.xy);

    // try to extract some ambient occlusion information from the albedo
    // unfortunately the albedos have lots of baked in lighting so
    // we have to keep the effect slight
    float ao = .5 + logisticFn(length(albedo) / sqrt(3), .1, 40, .5, 2);

    float teamcolor = min(pow(specular.a * 1.1, 0.6), 1);
    float metallic = max(1 - teamcolor * 2.2, 0);

    albedo = lerp(albedo, albedo * 1.9, metallic);
    albedo = lerp(albedo, vertex.color.rgb * 0.6, teamColorFactor * teamcolor);

    float planeCockpitMask = saturate((specular.r - 0.65) * 3);
    albedo += planeCockpitMask;

    float roughness = specular.g * 0.6 + 0.35 + saturate(pow(specular.a * 3.7, 0.6)) * 0.3;
    roughness += planeCockpitMask - specular.b * 3;
    roughness = saturate(1 - roughness);

    float3 color = PBR(vertex, albedo, metallic, roughness, normal, hiDefShadows, .04, ao);
    float emission = specular.b * 0.8;
    color = ApplyWaterColor(vertex.depth.x, vertex.viewDirection, color, emission * albedo);

    // The glowminimum is required to make the unit behave properly with the water shader.
    // If the alpha channel is 0 somewhere, those parts will show as water refractions even
    // if they are above the water line. See https://github.com/FAForever/fa/issues/4696
    float alphaGlow = mirrored ? 0.5 : emission + glowMinimum;
    return float4(color, alphaGlow);
}

float4 PBR_Aeon(NORMALMAPPED_VERTEX vertex, float teamColorFactor, uniform bool hiDefShadows) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth.x);

    float3x3 rotationMatrix = float3x3(vertex.binormal, vertex.tangent, vertex.normal);
    float3 normal = ComputeNormal(normalsSampler, vertex.texcoord0.zw, rotationMatrix);
    float3 albedo = tex2D( albedoSampler, vertex.texcoord0.xy).rgb;
    float4 specular = tex2D( specularSampler, vertex.texcoord0.xy);
    float fullTeamColor = saturate(specular.a * 2.5);

    float metallic = 0;
    if (specular.r < 0.4)
        metallic = saturate(mapRange(specular.r, 0.2267, 0.3643, 0, 1));
    else
        metallic = min(max(mapRange(specular.r, 0.4129, 0.5384, 1, 0), 0.3), 1);
    metallic = saturate(metallic - fullTeamColor);

    if (specular.g < 0.45)
        specular.g = 0.022 * (exp(6 * specular.g) - 1) + 0.023 + specular.a * 0.2;
    else
        specular.g = 0.762 * specular.g - 0.014;
    float teamcolorBorder = saturate(mapRange(specular.a, 0.54, 0.6, 0, 1));
    float darkAreas = saturate(saturate(mapRange(specular.r, 0.3, 0.44, 1, 0)) - length(albedo));
    float roughness = lerp(specular.g, 0.03, teamcolorBorder);
    roughness = saturate(roughness + darkAreas);

    albedo *= (specular.r + 0.3) * 1.25;
    albedo = pow(albedo, (1 - metallic * 0.95));
    albedo = lerp(albedo, vertex.color.rgb * specular.a * 0.4, teamColorFactor * fullTeamColor);

    float specularAmount = lerp(0.08, 0, darkAreas);
    specularAmount = lerp(specularAmount, 0.04, fullTeamColor);

    float3 color = PBR(vertex, albedo, metallic, roughness, normal, hiDefShadows, specularAmount);
    float3 emission = specular.b + specular.a * vertex.color.rgb * 0.5;
    color = ApplyWaterColor(vertex.depth.x, vertex.viewDirection, color, emission);
     
    float alpha = mirrored ? 0.5 : specular.b + glowMinimum + specular.a * 0.13;

    return float4(color, alpha);
}

float4 PBR_Cybran(NORMALMAPPED_VERTEX vertex, float teamColorFactor, uniform bool hiDefShadows) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth);

    float3x3 rotationMatrix = float3x3(vertex.binormal, vertex.tangent, vertex.normal);
    float3 normal = ComputeNormal(normalsSampler, vertex.texcoord0.zw, rotationMatrix);
    float3 albedo = tex2D( albedoSampler, vertex.texcoord0.xy).rgb;
    float4 specular = tex2D( specularSampler, vertex.texcoord0.xy);

    float metallic = saturate(specular.r + saturate(specular.g - 0.1) * 0.87 - specular.a * 2.2);
    float roughness = lerp(0.8 * (1 - specular.g), lerp(0.5, 0.25, specular.g), metallic);

    albedo += specular.r * 0.1;
    albedo = min(lerp(albedo, albedo * 2.3, pow(metallic, 2.5)), float3(0.9, 0.9, 0.9));
    albedo = lerp(albedo, vertex.color.rgb, teamColorFactor * specular.a);

    float3 color = PBR(vertex, albedo, metallic, roughness, normal, hiDefShadows);
    float emission = pow(max(specular.b - 0.04, 0.0), 0.5);
    color = ApplyWaterColor(vertex.depth.x, vertex.viewDirection, color, emission * albedo);

    float alpha = mirrored ? 0.5 : min(emission + glowMinimum, 0.3);

    return float4(color, alpha);
}


float4 PBR_Seraphim(
    NORMALMAPPED_VERTEX vertex,
    float4 albedo,
    float4 specular,
    float3 normal,
    uniform bool hiDefShadows) : COLOR0
{
    float NdotV = saturate(dot(normalize(vertex.viewDirection), normal));
    NdotV = 2 * pow(NdotV, 6) - 2 * NdotV + 1.5;
    float3 teamColor = NdotV * vertex.color.rgb;
	
    // There are also white highlights in the albedo texture in some models
    float3 whiteness = saturate(albedo.rgb - float3 (0.4,0.4,0.4));

    albedo.rgb = (albedo.bbg + float3(0.4, 0.43, 0.47)) * 0.8;
    albedo.rgb = lerp(albedo.rgb, teamColor, albedo.a);

    float metallic = 1;
    float roughness = saturate((1 - pow(specular.g, 0.5) + 0.3) * 0.7);

    float3 color = PBR(vertex, albedo.rgb, metallic, roughness, normal, hiDefShadows);
    color = lerp(color, teamColor * 0.5, albedo.a - 0.2);
    float3 emission = saturate(specular.b - 0.1) + teamColor * albedo.a + whiteness * 1.5;

    // Substitute all the computations on pure glowing parts with the
    // pure brightness texture to get rid of reflections and shadows
    float mask = saturate(saturate(specular.b * 2) - albedo.a);
    color = lerp(color, specular.b * 2, mask);

    color = ApplyWaterColor(vertex.depth.x, vertex.viewDirection, color, emission * albedo);

    // Bloom is only rendered where alpha > 0
    float teamColorGlow = (vertex.color.r + vertex.color.g + vertex.color.b) / 3;
    teamColorGlow = albedo.a * (1 - teamColorGlow) * 0.06;
    float alpha = mirrored ? 0.5 : saturate(specular.b - 0.1) * 0.4 + teamColorGlow + whiteness.r * 0.1 + glowMinimum;
    
    return float4(color, alpha);
}


///////////////////////////////////////
///
/// Vertex Shaders
///
///////////////////////////////////////

/// DepthVS
///
/// Depth vertex shader
DEPTH_VERTEX DepthVS(
    float3 position : POSITION0,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5
)
{
    DEPTH_VERTEX vertex = (DEPTH_VERTEX)0;

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);

    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));
    vertex.depth = vertex.position.z;

    vertex.texcoord0 = texcoord0;

    return vertex;
}

/// SeraphimBuildDepthVS
///
///
DEPTH_VERTEX SeraphimBuildDepthVS(
    float3 position : POSITION0,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6
)
{
    DEPTH_VERTEX vertex = (DEPTH_VERTEX)0;

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);

    position *= 0.25 + (material.y * 0.75);
    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));
    vertex.depth = vertex.position.z;

    vertex.texcoord0 = texcoord0;

    return vertex;
}

/// UndulatingDepthVS
///
/// Depth vertex shader
DEPTH_VERTEX UndulatingDepthVS(
    float3 position : POSITION0,
    float3 UnusedNormal : NORMAL,	// tighten up the linkages for D3D10
    float3 UnusedTangent : TANGENT,
    float3 UnusedBinormal : BINORMAL,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5
)
{
    DEPTH_VERTEX vertex = (DEPTH_VERTEX)0;

    float weight = 0.003 * position.y;
    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);

    vertex.position = mul( float4(position,1), worldMatrix);
    float sinSq = sin( 0.05 * time - dot(windDirection,row3.xyz));
    sinSq *= sinSq;

    vertex.position.xyz += weight * sinSq * windDirection;
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));
    vertex.depth = vertex.position.z / vertex.position.w;

    vertex.texcoord0 = texcoord0;

    return vertex;
}

/// SilhouetteVS
///
///
SILHOUETTE_VERTEX SilhouetteVS(
    float3 position : POSITION0,
    float3 UnusedNormal : NORMAL,	// tighten up the linkages for D3D10
    float3 UnusedTangent : TANGENT,
    float3 UnusedBinormal : BINORMAL,
    float4 UnusedTexcoord : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5
)
{
    SILHOUETTE_VERTEX vertex = (SILHOUETTE_VERTEX)0;

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);

    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));

    return vertex;
}

/// ClutterVS
///
///
CLUTTER_VERTEX ClutterVS(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float3 tangent : TANGENT0,
    float3 binormal : BINORMAL0,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6
)
{
    CLUTTER_VERTEX vertex = (CLUTTER_VERTEX)0;

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);

    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.shadow = ComputeShadowTexcoord( vertex.position);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));

    vertex.texcoord0 = texcoord0;
    vertex.normal = normalize( mul( normal, (float3x3)worldMatrix));
    vertex.dissolve = 0.003922 * anim.z;

    float3x3 rotationMatrix = (float3x3)worldMatrix;
    vertex.normal = mul( normal, rotationMatrix);
    vertex.tangent = mul( tangent, rotationMatrix);
    vertex.binormal = mul( binormal, rotationMatrix);

    return vertex;
}

/// UndulatingClutterVS
///
///
CLUTTER_VERTEX UndulatingClutterVS(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float3 tangent : TANGENT0,
    float3 binormal : BINORMAL0,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6
)
{
    CLUTTER_VERTEX vertex = (CLUTTER_VERTEX)0;

    float weight = 0.1 * position.y;
    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);

    vertex.position = mul( float4(position,1), worldMatrix);

    float sinSq = sin( 0.0625 * time - dot( windDirection, row3.xyz));
    sinSq *= sinSq;

    vertex.position.xyz += weight * sinSq * windDirection;
    vertex.shadow = ComputeShadowTexcoord( vertex.position);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));

    vertex.texcoord0 = texcoord0;
    vertex.normal = normalize( mul( normal, (float3x3)worldMatrix));
    vertex.dissolve = 0.003922 * anim.z;

    float3x3 rotationMatrix = (float3x3)worldMatrix;
    vertex.normal = mul( normal, rotationMatrix);
    vertex.tangent = mul( tangent, rotationMatrix);
    vertex.binormal = mul( binormal, rotationMatrix);

    return vertex;
}

/// CartographicVS
///
///
CARTOGRAPHIC_VERTEX CartographicVS(
    float3 position : POSITION0,
    float3 normal : NORMAL,
    float3 tangent : TANGENT,
    float3 binormal : BINORMAL,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 color : COLOR0,
    float4 material : TEXCOORD6
)
{
    CARTOGRAPHIC_VERTEX vertex = (CARTOGRAPHIC_VERTEX)0;
    CompatSwizzle(color);

    float4x4 worldMatrix = ComputeWorldMatrix(anim.y+boneIndex[0],row0,row1,row2,row3);

    vertex.position = mul(float4(position,1),worldMatrix);
    vertex.elevation = vertex.position.y;

    vertex.position = mul(vertex.position,mul(viewMatrix,projMatrix));
    vertex.texcoord = texcoord0;
    vertex.color = color;

    float3x3 R = (float3x3)worldMatrix;
    vertex.normal = mul(normal,R);
    vertex.tangent = mul(tangent,R);
    vertex.binormal = mul(binormal,R);

    return vertex;
}

/// CartographicVS
///
///
CARTOGRAPHIC_VERTEX CartographicFeedbackVS(
    float3 position : POSITION0,
    float3 normal : NORMAL,
    float3 tangent : TANGENT,
    float3 binormal : BINORMAL,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 color : COLOR0,
    float4 material : TEXCOORD6
)
{
    CARTOGRAPHIC_VERTEX vertex = (CARTOGRAPHIC_VERTEX)0;
    CompatSwizzle(color);

    float4x4 worldMatrix = ComputeWorldMatrix(anim.y+boneIndex[0],row0,row1,row2,row3);

    vertex.position = mul(float4(position,1),worldMatrix);
    vertex.elevation = vertex.position.y;

    vertex.position = mul(vertex.position,mul(viewMatrix,projMatrix));
    vertex.texcoord = texcoord0;
    vertex.color = color;

    return vertex;
}

/// FlatVS
///
/// Flat vertex shader (no lighting)
FLAT_VERTEX FlatVS(
    float3 position : POSITION0,
    float3 UnusedNormal : NORMAL,	// tighten up the linkages for D3D10
    float3 UnusedTangent : TANGENT,
    float3 UnusedBinormal : BINORMAL,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 color : COLOR0,
    float4 material : TEXCOORD6
)
{
    FLAT_VERTEX vertex = (FLAT_VERTEX)0;
    CompatSwizzle(color);

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);

    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.depth = vertex.position.y - surfaceElevation;
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));

    vertex.texcoord0 = ( anim.w > 0.5 ) ? ComputeScrolledTexcoord( texcoord0, material) : texcoord0;
    vertex.color = color;
    vertex.material = float4( time - material.x, material.yzw);

    return vertex;
}

/// VertexNormalVS
///
/// Vertex normal lighting only
VERTEXNORMAL_VERTEX VertexNormalVS(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float3 UnusedTangent : TANGENT,   // tighten up the linkages for D3D10
    float3 UnusedBinormal : BINORMAL,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0
)
{
    VERTEXNORMAL_VERTEX vertex = (VERTEXNORMAL_VERTEX)0;
    CompatSwizzle(color);

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);

    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.depth = vertex.position.y - surfaceElevation;
    vertex.shadow = ComputeShadowTexcoord( vertex.position);

    vertex.viewDirection = -mul(viewMatrix, mul( vertex.position, viewMatrix));
    vertex.viewDirection = normalize(vertex.viewDirection);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));

    vertex.texcoord0 = ( anim.w > 0.5 ) ? ComputeScrolledTexcoord( texcoord0, material) : texcoord0;
    vertex.color = color;
    vertex.material = float4( time - material.x, material.yzw);

    vertex.normal = normalize( mul( normal, (float3x3)worldMatrix));

    return vertex;
}

/// NormalMappedVS
///
/// Normal mapped lighting
NORMALMAPPED_VERTEX NormalMappedVS(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float3 tangent : TANGENT0,
    float3 binormal : BINORMAL0,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0,
    float1 colorLookup : TEXCOORD7
)
{
    NORMALMAPPED_VERTEX vertex = (NORMALMAPPED_VERTEX)0;
    CompatSwizzle(color);

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);

    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.depth.xy = float2(vertex.position.y - surfaceElevation,material.x);
    vertex.shadow = ComputeShadowTexcoord( vertex.position);

    // I'm not sure why this is working, should use the camera position for view vector calculation once that is available
    vertex.viewDirection = -mul(viewMatrix, mul( vertex.position, viewMatrix));
    vertex.viewDirection = normalize(vertex.viewDirection);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));
    
    vertex.texcoord0 = ( anim.w > 0.5 ) ? ComputeScrolledTexcoord( texcoord0, material) : texcoord0;
    vertex.color = color;
    vertex.material = float4( time - material.x, material.yzw);

    float3x3 rotationMatrix = (float3x3)worldMatrix;
    vertex.normal = mul( normal, rotationMatrix);
    vertex.tangent = mul( tangent, rotationMatrix);
    vertex.binormal = mul( binormal, rotationMatrix);

    return vertex;
}

/// UnitFalloffVS
///
/// Normal mapped lighting with color lookup instead of material parameters
NORMALMAPPED_VERTEX UnitFalloffVS(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float3 tangent : TANGENT0,
    float3 binormal : BINORMAL0,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0,
    float1 colorLookup : TEXCOORD7
)
{
    NORMALMAPPED_VERTEX vertex = (NORMALMAPPED_VERTEX)0;
    CompatSwizzle(color);

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);

    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.depth.xy = float2(vertex.position.y - surfaceElevation,material.x);
    vertex.shadow = ComputeShadowTexcoord( vertex.position);

    vertex.viewDirection = -mul(viewMatrix, mul( vertex.position, viewMatrix));
    vertex.viewDirection = normalize(vertex.viewDirection);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));

    vertex.texcoord0 = ( anim.w > 0.5 ) ? ComputeScrolledTexcoord( texcoord0, material) : texcoord0;
    vertex.color = color;
    vertex.material.x = colorLookup;

    float3x3 rotationMatrix = (float3x3)worldMatrix;
    vertex.normal = mul( normal, rotationMatrix);
    vertex.tangent = mul( tangent, rotationMatrix);
    vertex.binormal = mul( binormal, rotationMatrix);

    return vertex;
}

/// UndulatingNormalMappedVS
///
/// Normal mapped lighting with
NORMALMAPPED_VERTEX UndulatingNormalMappedVS(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float3 tangent : TANGENT0,
    float3 binormal : BINORMAL0,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0
)
{
    NORMALMAPPED_VERTEX vertex = (NORMALMAPPED_VERTEX)0;
    CompatSwizzle(color);

    float weight = 0.003 * position.y;
    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);

    vertex.position = mul( float4(position,1), worldMatrix);
    float sinSq = sin( 0.05 * time - dot(windDirection, row3.xyz));
    sinSq *= sinSq;

    vertex.position.xyz += weight * sinSq * windDirection;
    vertex.depth.xy = float2(vertex.position.y - surfaceElevation,material.x);
    vertex.shadow = ComputeShadowTexcoord( vertex.position);

    vertex.viewDirection = -mul(viewMatrix, mul( vertex.position, viewMatrix));
    vertex.viewDirection = normalize(vertex.viewDirection);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));

    vertex.texcoord0 = texcoord0;
    vertex.color = color;
    vertex.material = float4( time - material.x, material.yzw);

    float3x3 rotationMatrix = (float3x3)worldMatrix;
    vertex.normal = mul( normal, rotationMatrix);
    vertex.tangent = mul( tangent, rotationMatrix);
    vertex.binormal = mul( binormal, rotationMatrix);

    return vertex;
}

/// BloatingNormalMappedVS
///
///
NORMALMAPPED_VERTEX BloatingNormalMappedVS(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float3 tangent : TANGENT0,
    float3 binormal : BINORMAL0,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0
)
{
    NORMALMAPPED_VERTEX vertex = (NORMALMAPPED_VERTEX)0;
    CompatSwizzle(color);

    float weight = 0.003 * position.y;
    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);

    float3 direction = normalize(position);
    position += 2 * length(direction.xz) * sin( 0.1 * time + length(row3.xz)) * direction;

    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.depth.xy = float2(vertex.position.y - surfaceElevation,material.x);
    vertex.shadow = ComputeShadowTexcoord( vertex.position);

    vertex.viewDirection = -mul(viewMatrix, mul( vertex.position, viewMatrix));
    vertex.viewDirection = normalize(vertex.viewDirection);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));

    vertex.texcoord0 = texcoord0;
    vertex.color = color;
    vertex.material = float4( time - material.x, material.yzw);

    float3x3 rotationMatrix = (float3x3)worldMatrix;
    vertex.normal = mul( normal, rotationMatrix);
    vertex.tangent = mul( tangent, rotationMatrix);
    vertex.binormal = mul( binormal, rotationMatrix);

    return vertex;
}

VERTEXNORMAL_VERTEX BloatingVertexNormalVS(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float3 UnusedTangent : TANGENT,    // tighten up the linkages for D3D10
    float3 UnusedBinormal : BINORMAL,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0
)
{
    VERTEXNORMAL_VERTEX vertex = (VERTEXNORMAL_VERTEX)0;
    CompatSwizzle(color);

    float weight = 0.003 * position.y;
    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);

    float3 direction = normalize(position);
    position += 2 * length(direction.xz) * sin( 0.1 * time + length(row3.xz)) * direction;

    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.depth = vertex.position.y - surfaceElevation;
    vertex.shadow = ComputeShadowTexcoord( vertex.position);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));

    vertex.texcoord0 = ( anim.w > 0.5 ) ? ComputeScrolledTexcoord( texcoord0, material) : texcoord0;
    vertex.color = color;
    vertex.material = float4( time - material.x, material.yzw);

    vertex.normal = normalize( mul( normal, (float3x3)worldMatrix));

    return vertex;
}

/// WreckageVS
///
///
NORMALMAPPED_VERTEX WreckageVS_HighFidelity(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float3 tangent : TANGENT0,
    float3 binormal : BINORMAL0,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0
)
{
    NORMALMAPPED_VERTEX vertex = (NORMALMAPPED_VERTEX)0;
    CompatSwizzle(color);

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);
    vertex.position = mul( float4(position,1), worldMatrix);

    float3 nvert = normalize(vertex.position.xyz);
    float s = nvert * 0.15;
    float r = length(vertex.position.xyz);  // Distance of vert from origin
    float phi = frac( 0.01 * length(row3) );

    vertex.position.x += sin( 14.5 * r * nvert.z + phi) * s;
    vertex.position.y += cos( 10.8 * r * nvert.x + phi) * s;
    vertex.position.z += sin( 20.5 * r * nvert.y + phi) * s;

    // The rest is just the typical normal mapped vertex shader (sans scrolling)
    vertex.depth.xy = float2(vertex.position.y - surfaceElevation,material.x);
    vertex.shadow = ComputeShadowTexcoord( vertex.position);

    vertex.viewDirection = -mul(viewMatrix, mul( vertex.position, viewMatrix));
    vertex.viewDirection = normalize(vertex.viewDirection);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));

    vertex.texcoord0 = texcoord0;
    vertex.color = color;
    vertex.material = float4( time - material.x, material.yzw);

    float3x3 rotationMatrix = (float3x3)worldMatrix;
    vertex.normal = mul( normal, rotationMatrix);
    vertex.tangent = mul( tangent, rotationMatrix);
    vertex.binormal = mul( binormal, rotationMatrix);

    return vertex;
}
/// WreckageVS_LowFidelity
///
///
VERTEXNORMAL_VERTEX WreckageVS_LowFidelity(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float3 tangent : TANGENT0,
    float3 binormal : BINORMAL0,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0
)
{
    VERTEXNORMAL_VERTEX vertex = (VERTEXNORMAL_VERTEX)0;
    CompatSwizzle(color);

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);

    /// Perturb the model space position for broken crunchiness.
    /// The models are all different random sizes in model space, so we have to factor out a uniform scale
    float s = length(row1.xyz);
    float rdmOffset = frac( 0.01 * material.x );
    position += (.05 / s) * ( cos( 15 * rdmOffset * position.x * s) + sin( 20 * rdmOffset * position.z * s));
    position.y *= lerp(0.69, 1, rdmOffset);

    /// the rest is just standard...
    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.depth = vertex.position.y - surfaceElevation,material.x;
    vertex.shadow = ComputeShadowTexcoord( vertex.position);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));

    vertex.texcoord0 = texcoord0;
    vertex.color = color;
    vertex.material = float4( time - material.x, material.yzw);

    vertex.normal = normalize( mul( normal, (float3x3)worldMatrix));

    return vertex;
}

/// EffectVS
///
///
EFFECT_VERTEX EffectVS(
    float3 position : POSITION0,
    float4 texcoord0 : TEXCOORD0,
    float3 UnusedNormal : NORMAL,	// tighten up the linkages for D3D10
    float3 UnusedTangent : TANGENT,
    float3 UnusedBinormal : BINORMAL,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0
)
{
    EFFECT_VERTEX vertex = (EFFECT_VERTEX)0;
    CompatSwizzle(color);

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);

    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));

    vertex.texcoord0.xy = texcoord0.xy;
    vertex.material = float4( time - material.x, material.yzw);
    vertex.color = color;

    return vertex;
}

/// AeonBuildVS
///
/// Aeon build Vertex Shader
NORMALMAPPED_VERTEX AeonBuildVS(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float3 tangent : TANGENT0,
    float3 binormal : BINORMAL0,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0,
    uniform float offset
)
{
    NORMALMAPPED_VERTEX vertex = (NORMALMAPPED_VERTEX)0;
    CompatSwizzle(color);

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);

    // part of build animation: move the mesh up from underground
    float scale = 1 / worldMatrix._m11;
    float buildTime = 1 - min(1.0, (1.25 * material.y));
    position.y = position.y - abs(scale * buildTime);

    // part of build animation: start off small
    position = position * max(0.75, material.y);

    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.depth.xy = float2(vertex.position.y - surfaceElevation,material.x);
    vertex.shadow = ComputeShadowTexcoord( vertex.position);
    // The shadow bugs out at the end of the animation, so we have to disable it
    vertex.shadow.z = 0;

    vertex.viewDirection = -mul(viewMatrix, mul( vertex.position, viewMatrix));
    vertex.viewDirection = normalize(vertex.viewDirection);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));

    vertex.texcoord0 = texcoord0;
    vertex.color = color;
    vertex.material = float4( time - material.x, material.yzw);

    float3x3 rotationMatrix = (float3x3)worldMatrix;
    vertex.normal = mul( normal, rotationMatrix);
    vertex.tangent = mul( tangent, rotationMatrix);
    vertex.binormal = mul( binormal, rotationMatrix);

    // part of build animation: turn mesh slightly inwards to allow the overlay to work properly
    vertex.position = vertex.position + offset * float4(vertex.normal, 0);

    return vertex;
}

/// AeonBuildNoAnimationVS
///
/// Aeon build Vertex Shader
NORMALMAPPED_VERTEX AeonBuildNoAnimationVS(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float3 tangent : TANGENT0,
    float3 binormal : BINORMAL0,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0
)
{
    NORMALMAPPED_VERTEX vertex = (NORMALMAPPED_VERTEX)0;
    CompatSwizzle(color);

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);

    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.depth.xy = float2(vertex.position.y - surfaceElevation,material.x);
    vertex.shadow = ComputeShadowTexcoord( vertex.position);

    vertex.viewDirection = -mul(viewMatrix, mul( vertex.position, viewMatrix));
    vertex.viewDirection = normalize(vertex.viewDirection);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));

    vertex.texcoord0 = texcoord0;
    vertex.color = color;
    vertex.material = float4( time - material.x, material.yzw);

    float3x3 rotationMatrix = (float3x3)worldMatrix;
    vertex.normal = mul( normal, rotationMatrix);
    vertex.tangent = mul( tangent, rotationMatrix);
    vertex.binormal = mul( binormal, rotationMatrix);

    return vertex;
}

VERTEXNORMAL_VERTEX AeonBuildLoFiVS(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float4 texcoord0 : TEXCOORD0,
    float3 UnusedNormal : NORMAL,	// tighten up the linkages for D3D10
    float3 UnusedTangent : TANGENT,
    float3 UnusedBinormal : BINORMAL,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0,
    uniform float texScale0,
    uniform float texScale1,
    uniform float texXshift0,
    uniform float texYshift0,
    uniform float texXshift1,
    uniform float texYshift1
)
{
    VERTEXNORMAL_VERTEX vertex = (VERTEXNORMAL_VERTEX)0;
    CompatSwizzle(color);

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);

    // part of build animation: move the mesh up from underground
    float scale = 1 / worldMatrix._m11;
    float buildTime = 1 - min(1.0, (1.25 * material.y));
    position.y = position.y - abs(scale * buildTime);

    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.depth = vertex.position.y - surfaceElevation;
    vertex.shadow = ComputeShadowTexcoord( vertex.position);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));
    vertex.color = color;

    vertex.texcoord0 = ( anim.w > 0.5 ) ? ComputeScrolledTexcoord( texcoord0, material) : texcoord0;
    vertex.material = float4( time - material.x, material.yzw);

    vertex.normal = normalize( mul( normal, (float3x3)worldMatrix));

    // Texture coordinate modification for PS
    vertex.shadow.xy = vertex.texcoord0.xy;
    vertex.texcoord0.xy *= texScale0;
    vertex.shadow.xy *= texScale1;
    vertex.texcoord0.x += (vertex.material.x * texXshift0);
    vertex.texcoord0.y += (vertex.material.x * texYshift0);
    vertex.shadow.x += (vertex.material.x * texXshift1);
    vertex.shadow.y += (vertex.material.x * texYshift1);

    return vertex;
}

VERTEXNORMAL_VERTEX AeonBuildNoAnimationLoFiVS(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float4 texcoord0 : TEXCOORD0,
    float3 UnusedNormal : NORMAL,	// tighten up the linkages for D3D10
    float3 UnusedTangent : TANGENT,
    float3 UnusedBinormal : BINORMAL,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0,
    uniform float texScale0,
    uniform float texScale1,
    uniform float texXshift0,
    uniform float texYshift0,
    uniform float texXshift1,
    uniform float texYshift1
)
{
    VERTEXNORMAL_VERTEX vertex = (VERTEXNORMAL_VERTEX)0;
    CompatSwizzle(color);

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);

    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.depth = vertex.position.y - surfaceElevation;
    vertex.shadow = ComputeShadowTexcoord( vertex.position);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));
    vertex.color = color;

    vertex.texcoord0 = ( anim.w > 0.5 ) ? ComputeScrolledTexcoord( texcoord0, material) : texcoord0;
    vertex.material = float4( time - material.x, material.yzw);

    vertex.normal = normalize( mul( normal, (float3x3)worldMatrix));

    // Texture coordinate modification for PS
    vertex.shadow.xy = vertex.texcoord0.xy;
    vertex.texcoord0.xy *= texScale0;
    vertex.shadow.xy *= texScale1;
    vertex.texcoord0.x += (vertex.material.x * texXshift0);
    vertex.texcoord0.y += (vertex.material.x * texYshift0);
    vertex.shadow.x += (vertex.material.x * texXshift1);
    vertex.shadow.y += (vertex.material.x * texYshift1);

    return vertex;
}


// SeraphimBuildVS
///
/// Seraphim build Vertex Shader
NORMALMAPPED_VERTEX SeraphimBuildVS(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float3 tangent : TANGENT0,
    float3 binormal : BINORMAL0,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0,
    float1 colorLookup : TEXCOORD7
)
{
    NORMALMAPPED_VERTEX vertex = (NORMALMAPPED_VERTEX)0;
    CompatSwizzle(color);

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);

    position *= 0.25 + (material.y * 0.75);

    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.depth.xy = float2(vertex.position.y - surfaceElevation,colorLookup);
    vertex.shadow = ComputeShadowTexcoord( vertex.position);

    vertex.viewDirection = -mul(viewMatrix, mul( vertex.position, viewMatrix));
    vertex.viewDirection = normalize(vertex.viewDirection);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));

    vertex.texcoord0 = texcoord0;
    vertex.color = color;
    vertex.material = float4( time - material.x, material.yzw);

    float3x3 rotationMatrix = (float3x3)worldMatrix;
    vertex.normal = mul( normal, rotationMatrix);
    vertex.tangent = mul( tangent, rotationMatrix);
    vertex.binormal = mul( binormal, rotationMatrix);

    return vertex;
}


// SeraphimBuildLofiVS
///
/// Seraphim build Vertex Shader
VERTEXNORMAL_VERTEX SeraphimBuildLofiVS(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float3 UnusedTangent : TANGENT,
    float3 UnusedBinormal : BINORMAL,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0
)
{
    VERTEXNORMAL_VERTEX vertex = (VERTEXNORMAL_VERTEX)0;
    CompatSwizzle(color);

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);

    position *= 0.25 + (material.y * 0.75);
    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.depth = vertex.position.y - surfaceElevation;
    vertex.shadow = ComputeShadowTexcoord( vertex.position);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));

    vertex.texcoord0 = ( anim.w > 0.5 ) ? ComputeScrolledTexcoord( texcoord0, material) : texcoord0;
    vertex.color = color;
    vertex.material = float4( time - material.x, material.yzw);

    vertex.normal = normalize( mul( normal, (float3x3)worldMatrix));

    return vertex;
}



/// PositionNormalOffsetVS
///
/// Position Normal Offset VS
VERTEXNORMAL_VERTEX PositionNormalOffsetVS(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float3 UnusedTangent : TANGENT,     // tighten up the linkages for D3D10
    float3 UnusedBinormal : BINORMAL,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0,
    uniform float normalOffset
)
{
    VERTEXNORMAL_VERTEX vertex = (VERTEXNORMAL_VERTEX)0;
    CompatSwizzle(color);

    int bone = anim.y + boneIndex[0];

    float4x4 worldMatrix = ComputeWorldMatrix( bone, row0, row1, row2, row3);
    // Offset the vertex position slightly by its normal
    position += normal * 1 / transPalette[bone].w * normalOffset;

    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.depth = vertex.position.y - surfaceElevation,material.x;
    vertex.shadow = ComputeShadowTexcoord( vertex.position);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));

    vertex.texcoord0 = texcoord0;
    vertex.color = color;
    vertex.material = float4( time - material.x, material.yzw);

    vertex.normal = normalize( mul( normal, (float3x3)worldMatrix));

    return vertex;
}

VERTEXNORMAL_VERTEX EffectVertexNormalHiFiVS(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float3 UnusedTangent : TANGENT,     // tighten up the linkages for D3D10
    float3 UnusedBinormal : BINORMAL,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0,
    uniform float texScale0,
    uniform float texScale1,
    uniform float texXshift0,
    uniform float texYshift0,
    uniform float texXshift1,
    uniform float texYshift1
)
{
    VERTEXNORMAL_VERTEX vertex = (VERTEXNORMAL_VERTEX)0;
    CompatSwizzle(color);

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);

    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.depth = vertex.position.y - surfaceElevation;
    vertex.shadow = ComputeShadowTexcoord( vertex.position);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));

    vertex.texcoord0 = ( anim.w > 0.5 ) ? ComputeScrolledTexcoord( texcoord0, material) : texcoord0;
    vertex.material = float4( time - material.x, material.yzw);

    vertex.normal = normalize( mul( normal, (float3x3)worldMatrix));

    // Texture coordinate modification for PS
    vertex.texcoord0.xy *= texScale0;
    vertex.texcoord0.zw *= texScale1;
    vertex.texcoord0.x += (vertex.material.x * texXshift0);
    vertex.texcoord0.y += (vertex.material.x * texYshift0);
    vertex.texcoord0.zw += (vertex.material.x * texXshift1);
    vertex.texcoord0.zw += (vertex.material.x * texYshift1);

    return vertex;
}


VERTEXNORMAL_VERTEX EffectVertexNormalLoFiVS(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float3 UnusedTangent : TANGENT,     // tighten up the linkages for D3D10
    float3 UnusedBinormal : BINORMAL,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0,
    uniform float texScale0,
    uniform float texScale1,
    uniform float texXshift0,
    uniform float texYshift0,
    uniform float texXshift1,
    uniform float texYshift1
)
{
    VERTEXNORMAL_VERTEX vertex = (VERTEXNORMAL_VERTEX)0;
    CompatSwizzle(color);

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);

    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.depth = vertex.position.y - surfaceElevation;
    vertex.shadow = ComputeShadowTexcoord( vertex.position);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));

    vertex.texcoord0 = ( anim.w > 0.5 ) ? ComputeScrolledTexcoord( texcoord0, material) : texcoord0;
    vertex.material = float4( time - material.x, material.yzw);

    vertex.normal = normalize( mul( normal, (float3x3)worldMatrix));

    // Texture coordinate modification for PS
    vertex.shadow.xy = vertex.texcoord0.xy;
    vertex.texcoord0.xy *= texScale0;
    vertex.shadow.xy *= texScale1;
    vertex.texcoord0.x += (vertex.material.x * texXshift0);
    vertex.texcoord0.y += (vertex.material.x * texYshift0);
    vertex.shadow.x += (vertex.material.x * texXshift1);
    vertex.shadow.y += (vertex.material.x * texYshift1);

    return vertex;
}

/// FourUVTexShiftScaleVS
///
/// Vertex normal lighting only
EFFECT_VERTEX FourUVTexShiftScaleVS(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float3 UnusedTangent : TANGENT,     // tighten up the linkages for D3D10
    float3 UnusedBinormal : BINORMAL,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0,
    uniform float texScale0,
    uniform float texScale1,
    uniform float texScale2,
    uniform float texScale3,
    uniform float texXshift0,
    uniform float texYshift0,
    uniform float texXshift1,
    uniform float texYshift1,
    uniform float texXshift2,
    uniform float texYshift2,
    uniform float texXshift3,
    uniform float texYshift3
)
{
    EFFECT_VERTEX vertex = (EFFECT_VERTEX)0;
    CompatSwizzle(color);

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);

    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.depth = vertex.position.y - surfaceElevation;
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));
    vertex.normal = normalize( mul( normal, (float3x3)worldMatrix));

    vertex.texcoord0 = texcoord0;
    vertex.texcoord1 = texcoord0;
    vertex.color = color;
    vertex.material = float4( time - material.x, material.yzw);

    vertex.texcoord0.xy *= texScale0;
    vertex.texcoord0.zw *= texScale1;
    vertex.texcoord1.xy *= texScale2;
    vertex.texcoord1.zw *= texScale3;
    vertex.texcoord0.x += (vertex.material.x * texXshift0);
    vertex.texcoord0.y += (vertex.material.x * texYshift0);
    vertex.texcoord0.z += (vertex.material.x * texXshift1);
    vertex.texcoord0.w += (vertex.material.x * texYshift1);
    vertex.texcoord1.x += (vertex.material.x * texXshift2);
    vertex.texcoord1.y += (vertex.material.x * texYshift2);
    vertex.texcoord1.z += (vertex.material.x * texXshift3);
    vertex.texcoord1.w += (vertex.material.x * texYshift3);

    return vertex;
}

EFFECT_NORMALMAPPED_VERTEX ShieldNormalVS(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float3 tangent : TANGENT0,
    float3 binormal : BINORMAL0,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0,
    uniform float texScale0,
    uniform float texScale1,
    uniform float texScale2,
    uniform float texScale3,
    uniform float texXshift0,
    uniform float texYshift0,
    uniform float texXshift1,
    uniform float texYshift1,
    uniform float texXshift2,
    uniform float texYshift2,
    uniform float texXshift3,
    uniform float texYshift3
)
{
    EFFECT_NORMALMAPPED_VERTEX vertex = (EFFECT_NORMALMAPPED_VERTEX)0;
    CompatSwizzle(color);

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);

    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.depth = float2(vertex.position.y - surfaceElevation,material.x);

    vertex.viewDirection = -mul(viewMatrix, mul( vertex.position, viewMatrix));
    vertex.viewDirection = normalize(vertex.viewDirection);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));

    vertex.texcoord0 = texcoord0;
    vertex.texcoord1 = texcoord0;
    vertex.color = color;
    vertex.material = float4( time - material.x, material.yzw);

    float3x3 rotationMatrix = (float3x3)worldMatrix;
    vertex.normal = mul( normal, rotationMatrix);
    vertex.tangent = mul( tangent, rotationMatrix);
    vertex.binormal = mul( binormal, rotationMatrix);

    vertex.texcoord0.xy *= texScale0;
    vertex.texcoord0.zw *= texScale1;
    vertex.texcoord1.xy *= texScale2;
    vertex.texcoord1.zw *= texScale3;
    vertex.texcoord0.x += (vertex.material.x * texXshift0);
    vertex.texcoord0.y += (vertex.material.x * texYshift0);
    vertex.texcoord0.z += (vertex.material.x * texXshift1);
    vertex.texcoord0.w += (vertex.material.x * texYshift1);
    vertex.texcoord1.x += (vertex.material.x * texXshift2);
    vertex.texcoord1.y += (vertex.material.x * texYshift2);
    vertex.texcoord1.z += (vertex.material.x * texXshift3);
    vertex.texcoord1.w += (vertex.material.x * texYshift3);

    return vertex;
}

EFFECT_VERTEX ShieldPositionNormalOffsetVS(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float3 UnusedTangent : TANGENT,  // tighten up linkages for D3D10
    float3 UnusedBinormal : BINORMAL,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0,
    uniform float normalOffset,
    uniform float texScale0,
    uniform float texScale1,
    uniform float texScale2,
    uniform float texScale3,
    uniform float texXshift0,
    uniform float texYshift0,
    uniform float texXshift1,
    uniform float texYshift1,
    uniform float texXshift2,
    uniform float texYshift2,
    uniform float texXshift3,
    uniform float texYshift3
)
{
    EFFECT_VERTEX vertex = (EFFECT_VERTEX)0;
    CompatSwizzle(color);

    int bone = anim.y + boneIndex[0];

    float4x4 worldMatrix = ComputeWorldMatrix( bone, row0, row1, row2, row3);
    // Offset the vertex position slightly by its normal
    position += normal * 1 / transPalette[bone].w * normalOffset;

    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.depth = vertex.position.y - surfaceElevation,material.x;
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));
    vertex.normal = normalize( mul( normal, (float3x3)worldMatrix));

    vertex.texcoord0 = texcoord0;
    vertex.texcoord1 = texcoord0;
    vertex.color = color;
    vertex.material = float4( time - material.x, material.yzw);

    vertex.texcoord0.xy *= texScale0;
    vertex.texcoord0.zw *= texScale1;
    vertex.texcoord1.xy *= texScale2;
    vertex.texcoord1.zw *= texScale3;
    vertex.texcoord0.x += (vertex.material.x * texXshift0);
    vertex.texcoord0.y += (vertex.material.x * texYshift0);
    vertex.texcoord0.z += (vertex.material.x * texXshift1);
    vertex.texcoord0.w += (vertex.material.x * texYshift1);
    vertex.texcoord1.x += (vertex.material.x * texXshift2);
    vertex.texcoord1.y += (vertex.material.x * texYshift2);
    vertex.texcoord1.z += (vertex.material.x * texXshift3);
    vertex.texcoord1.w += (vertex.material.x * texYshift3);

    return vertex;
}

LOFIEFFECT_VERTEX ThreeUVTexShiftScaleLoFiVS(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float3 UnusedTangent : TANGENT,  // tighten up linkages for D3D10
    float3 UnusedBinormal : BINORMAL,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0,
    uniform float texScale0,
    uniform float texScale1,
    uniform float texScale2,
    uniform float texXshift0,
    uniform float texYshift0,
    uniform float texXshift1,
    uniform float texYshift1,
    uniform float texXshift2,
    uniform float texYshift2
)
{
    LOFIEFFECT_VERTEX vertex = (LOFIEFFECT_VERTEX)0;
    CompatSwizzle(color);

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);

    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.depth = vertex.position.y - surfaceElevation;
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));
    vertex.normal = normalize( mul( normal, (float3x3)worldMatrix));

    vertex.texcoord0 = texcoord0;
    vertex.texcoord1 = texcoord0;
    vertex.texcoord2 = texcoord0;
    vertex.color = color;
    vertex.material = float4( time - material.x, material.yzw);

    vertex.texcoord0.xy *= texScale0;
    vertex.texcoord1.xy *= texScale1;
    vertex.texcoord2.xy *= texScale2;
    vertex.texcoord0.x += (vertex.material.x * texXshift0);
    vertex.texcoord0.y += (vertex.material.x * texYshift0);
    vertex.texcoord1.x += (vertex.material.x * texXshift1);
    vertex.texcoord1.y += (vertex.material.x * texYshift1);
    vertex.texcoord2.x += (vertex.material.x * texXshift2);
    vertex.texcoord2.y += (vertex.material.x * texYshift2);

    return vertex;
}

SHIELDIMPACT_VERTEX ShieldImpactVS(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float3 UnusedTangent : TANGENT,  // tighten up linkages for D3D10
    float3 UnusedBinormal : BINORMAL,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0,
    uniform float texcoord0Xshift,
    uniform float texcoord0Ybshift,
    uniform float texcoord0Yeshift,
    uniform float texcoord0YOffset,
    uniform float texcoord1Scale,
    uniform float texcoord1Xshift,
    uniform float texcoord1Yshift,
    uniform float texcoord2XOffset,
    uniform float fadeTime

)
{
    SHIELDIMPACT_VERTEX vertex = (SHIELDIMPACT_VERTEX)0;
    CompatSwizzle(color);

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);
    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.depth = vertex.position.y - surfaceElevation;
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));

    vertex.material = float4( time - material.x, material.yzw);

    vertex.texcoord0 = texcoord0;
    vertex.texcoord1 = texcoord0;
    vertex.texcoord2 = texcoord0;

    // Texcoord 1, Interpolated uv shifting
    vertex.texcoord0.x += texcoord0Xshift * vertex.material.x;
    vertex.texcoord0.y += texcoord0YOffset + (lerp(texcoord0Ybshift, texcoord0Yeshift, vertex.material.x/fadeTime ) * vertex.material.x);

    // Texcoord 1, shift and scale
    vertex.texcoord1.xy *= texcoord1Scale;
    vertex.texcoord1.x += texcoord1Xshift * vertex.material.x;
    vertex.texcoord1.y += texcoord1Yshift * vertex.material.x;

    // Texcoord 2, Initial x-offset
    vertex.texcoord2.x += frac( texcoord2XOffset * material.x );

    return vertex;
}

/// CommandFeedbackVS
///
/// Vertex normal lighting only
VERTEXNORMAL_VERTEX CommandFeedbackVS(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float3 UnusedTangent : TANGENT,   // tighten up the linkages for D3D10
    float3 UnusedBinormal : BINORMAL,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0,
    uniform float scaleTo
)
{
    VERTEXNORMAL_VERTEX vertex = (VERTEXNORMAL_VERTEX)0;
    CompatSwizzle(color);

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);
    float lodScale = mul(lodBasis,float4(worldMatrix[3].xyz,1));
    position *= lerp( 1, 15, (lodScale - 10.5 ) * 0.001 );
    float age = time - material.x;
    float t = saturate( age / material.y );
    position *= lerp( 1.0, scaleTo, t );

    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.depth = vertex.position.y - surfaceElevation;
    vertex.shadow = ComputeShadowTexcoord( vertex.position);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));

    vertex.texcoord0 = ( anim.w > 0.5 ) ? ComputeScrolledTexcoord( texcoord0, material) : texcoord0;
    vertex.color = color;
    vertex.material = float4( 1 - t, material.yzw);

    vertex.normal = normalize( mul( normal, (float3x3)worldMatrix));

    return vertex;
}




///////////////////////////////////////
///
/// Pixel Shaders
///
///////////////////////////////////////

/// DepthPS
///
/// Depth pixel shader.
float4 DepthPS( DEPTH_VERTEX vertex, uniform bool clipTest) : COLOR0
{
    if ( clipTest )
        clip( tex2D( albedoSampler, vertex.texcoord0.xy).a - 0.5);
    return float4( vertex.depth, 0, 0, 1);
}

/// CartographicPS
///
///
float4 CartographicPS( CARTOGRAPHIC_VERTEX vertex, uniform bool hypsometric) : COLOR0
{
    clip(vertex.elevation-surfaceElevation);

    float3 normal = normalize(vertex.normal);

    float3 color = vertex.color.rgb;
    if ( hypsometric )
    {
        float elevation = ( vertex.elevation - minimumElevation ) / ( maximumElevation - minimumElevation );

        clip(tex2D(albedoSampler,vertex.texcoord.xy).a-0.5);
        color = tex1D(hypsometricSampler,elevation).rgb;

        float tone = dot(normal,normalize(float3(-1,3,-1)));
        float  ca = 0.25;
        float cd0 = ( tone > 0.21 ) ? 0.25 : 0.0;
        float cd1 = ( tone > 0.66 ) ? 0.50 : 0.0;
        float  cs = ( tone > 0.95 ) ? 0.10 : 0.0;
        color = ca * color + cd0 * color + cd1 * color + cs;

        return float4(color,1);
    }

    float edge = clamp(1-saturate(dot(normal,float3(0,1,0))),0.5,1.0);

    return float4(color,edge);
}

/// CartographicFeedbackPS
///
///
float4 CartographicFeedbackPS( CARTOGRAPHIC_VERTEX vertex, uniform bool hypsometric) : COLOR0
{
    clip(vertex.elevation-surfaceElevation);
    float4 color = tex2D(albedoSampler,vertex.texcoord.xy);
    return float4(color.rgb,1);
}

/// CartographicGlowPS
///
///
float4 CartographicGlowPS( CARTOGRAPHIC_VERTEX vertex) : COLOR0
{
    clip(vertex.elevation-surfaceElevation);

    float3 normal = normalize(vertex.normal);
    float edge = 1-saturate(dot(normal,float3(0,1,0)));

    return float4(0,0,0,0.2*edge*edge);
}

/// CartographicPlacePS
///
///
float4 CartographicPlacePS( CARTOGRAPHIC_VERTEX vertex) : COLOR0
{
    clip(vertex.elevation-surfaceElevation);
    float3 color = vertex.color.rgb;
    return float4(color,0.125);
}

/// CartographicBuildPS
///
///
float4 CartographicBuildPS( CARTOGRAPHIC_VERTEX vertex) : COLOR0
{
    clip(vertex.elevation-surfaceElevation);
    float3 color = saturate(vertex.color.rgb + float3(0.1,0.1,0.1));
    return float4(color,0.4);
}

/// CartographicShieldPS
///
///
float4 CartographicShieldPS( CARTOGRAPHIC_VERTEX vertex) : COLOR0
{
    float tone  = saturate(dot(normalize(vertex.normal),normalize(float3(-1,3,-1))));

    tone = pow(tone,80);
    float3 color = lerp(float3(0,0,0),float3(1,1,1),tone);

    return float4(color,0.4*tone);
}

/// FlatPS
///
/// Flat pixel shader (no lighting)
float4 FlatPS( FLAT_VERTEX vertex,
               uniform bool alphaTestEnable,
               uniform int alphaFunc,
               uniform int alphaRef ) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth.x);

    float4 color = vertex.color * tex2D( albedoSampler, vertex.texcoord0.xy);
    float alpha = mirrored ? 0.5 : vertex.material.g * color.a;

#ifdef DIRECT3D10
    if( alphaTestEnable )
        AlphaTestD3D10( alpha, alphaFunc, alphaRef );
#endif
    return float4( color.rgb, alpha);
}

float4 PBR_UEF_PS(NORMALMAPPED_VERTEX vertex,
                uniform bool maskAlbedo,
                uniform bool hiDefShadows,
                uniform bool alphaTestEnable,
                uniform int alphaFunc,
                uniform int alphaRef ) : COLOR0
{
    if (1 == mirrored) clip(vertex.depth.x);

    float teamColorFactor = 1;
    return PBR_UEF(vertex, teamColorFactor, hiDefShadows);
}

float4 PBR_UEFBuildPS( NORMALMAPPED_VERTEX vertex, uniform bool hiDefShadows) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth);

    float4 texcoord = vertex.texcoord0;
    float4 texcoord2 = texcoord * 5;
    texcoord2.y += vertex.material.x * 0.062;
    float4 secondary = tex2D( secondarySampler, texcoord2.xy * 10);

    float teamColorFactor = (vertex.material.y >= 0.90) ? (vertex.material.y - 0.9) * 10 : 0.0;
    float3 color = PBR_UEF(vertex, teamColorFactor, hiDefShadows).rgb;

    float1 t = min(max(frac( 0.02 * time), 0.35), 0.7);
    float3 current = lerp(color+secondary.rgb,float3(0,0,1),t);
    float3 outColor = lerp(current, color, vertex.material.y);

    return float4(outColor, max(vertex.material.y, 0.5));
}

float4 PBR_AeonPS(NORMALMAPPED_VERTEX vertex, uniform bool hiDefShadows) : COLOR0
{
    float teamColorFactor = 1;
    return PBR_Aeon(vertex, teamColorFactor, hiDefShadows);
}

float4 PBR_AeonBuildPS(NORMALMAPPED_VERTEX vertex, uniform bool hiDefShadows) : COLOR0
{
    float teamColorFactor = (vertex.material.y >= 0.90) ? (vertex.material.y - 0.9) * 10 : 0.0;
    return PBR_Aeon(vertex, teamColorFactor, hiDefShadows);
}

float4 PBR_AeonBuildPuddlePS(NORMALMAPPED_VERTEX vertex, uniform bool hiDefShadows) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth.x);

    float2 texcoord = vertex.texcoord0.xy;
    texcoord.x -= vertex.material.x * 0.002;
    texcoord.y += vertex.material.x * 0.0042;

    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal);
    float3 normal = ComputeNormal( normalsSampler, texcoord, rotationMatrix);
    float3 albedo = tex2D( albedoSampler, texcoord ).rgb;
    float4 specular = tex2D( specularSampler, texcoord );

    float metallic = 1;
    float roughness = specular.g;

    float3 color = PBR(vertex, albedo, metallic, roughness, normal, hiDefShadows);

    float alpha = mirrored ? 0.5 : specular.b + glowMinimum;

    return float4(color, alpha);
}

float4 PBR_AeonBuildOverlayPS( NORMALMAPPED_VERTEX vertex) : COLOR0
{
    // Diffuse texture
    float4 texcoord = vertex.texcoord0;
    texcoord.y += vertex.material.x * 0.00162;
    texcoord.x -= vertex.material.x * 0.001;
    float4 mask1 = tex2D( secondarySampler, texcoord * 2);

    float4 texcoord2 = vertex.texcoord0;
    texcoord2.y -= vertex.material.x * 0.00162;
    float4 mask2 = tex2D( secondarySampler, texcoord2 * 2);

    float3 diffuse = mask1.rrr - mask2.ggg + mask1.ggg * mask2.rrr;
    diffuse = lerp( diffuse, float3(0.5,0.5,0.5), 0.75);

    // Custom normal mapping
    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal );
    float3 normal = tex2D( normalsSampler, vertex.texcoord0.zw ).gaa;
    normal = lerp( normal, tex2D( secondarySampler, vertex.texcoord0 * 7 ).baa, 0.5);
    normal = lerp( normal, diffuse, 0.5);
    normal = 2 * normal - 1;
    normal.z = sqrt( 1 - normal.x*normal.x - normal.y*normal.y );
    normal = normalize( mul( normal, rotationMatrix));

    float metallic = 1;
    float roughness = 0.15;
    float3 color = PBR(vertex, diffuse, metallic, roughness, normal, true);

    // Fade out 95% complete
    float percentComplete = vertex.material.y;
    float alpha = (percentComplete >= 0.95) ? (1.0 - ((percentComplete - 0.95) * 20)) * (color.r * 2) : color.r * 2;

    return float4( color, alpha );
}

float4 PBR_AeonCZARPS( NORMALMAPPED_VERTEX vertex, uniform bool hiDefShadows) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth.x);

    float3x3 rotationMatrix = float3x3(vertex.binormal, vertex.tangent, vertex.normal);
    float3 normal = ComputeNormal(normalsSampler, vertex.texcoord0.zw, rotationMatrix);
    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.xy);
    float4 specular = tex2D( specularSampler, vertex.texcoord0.xy);

    float metallic = saturate((specular.r - 0.02) * 4 - specular.a * 5);

    albedo.rgb *= 1 + metallic;
    // We need to make the dark areas darker
    // Should find something that offers more control over the result
    float x = albedo.r;
    albedo.rgb = (pow(x, 3) - 3 * pow(x, 2) + 3 * x) * albedo.rgb;

    albedo.rgb = lerp(albedo.rgb, vertex.color.rgb * 0.8, specular.a);

    if (specular.g < 0.45)
        specular.g = 0.022 * (exp(6 * specular.g) - 1) + 0.023 + specular.a * 0.2;
    else
        specular.g = 0.762 * specular.g - 0.014;
    float teamcolorBorder = saturate(mapRange(specular.a, 0.54, 0.6, 0, 1));
    float darkAreas = 0;
    if (specular.r < 0.18)
        darkAreas = saturate(0.7 - pow(specular.r, 0.6));
    float roughness = lerp(specular.g, 0.03, teamcolorBorder);
    roughness = max(roughness, darkAreas);

    float specularAmount = lerp(0.08, 0, darkAreas);
    specularAmount = lerp(specularAmount, 0.04, saturate(specular.a * 3));

    float3 color = PBR(vertex, albedo.rgb, metallic, roughness, normal, hiDefShadows, specularAmount);
    float3 emission = (specular.b + (pow(specular.a, 2) * 0.13)) * albedo.rgb;

    float2 texcoord = vertex.texcoord0.xy * 60;
    texcoord.x -= vertex.material.x * 0.16;
    texcoord.y -= vertex.material.x * 0.01;
    float2 texcoord2 = vertex.texcoord0.xy * 30;
    texcoord2.x += vertex.material.x * 0.08;
    texcoord2.y -= vertex.material.x * 0.005;
    float3 secondary = tex2D( secondarySampler, texcoord );
    float3 secondary2 = tex2D( secondarySampler, texcoord2 );
    emission += float3(0.2,0.7,1) * (secondary.b + secondary2.g )* (1-albedo.a);
    color = ApplyWaterColor(vertex.depth.x, vertex.viewDirection, color, emission);

    float alpha = mirrored ? 0.5 : specular.b + ((secondary.b + secondary2.g ) * (1-albedo.a)) + glowMinimum;
    return float4(color, alpha);
}

float4 PBR_CybranPS(NORMALMAPPED_VERTEX vertex, uniform bool hiDefShadows) : COLOR0
{
    float teamColorFactor = 1;
    return PBR_Cybran(vertex, teamColorFactor, hiDefShadows);
}

float4 PBR_CybranBuildPS(NORMALMAPPED_VERTEX vertex, uniform bool hiDefShadows) : COLOR0
{
    float teamColorFactor = (vertex.material.y >= 0.90) ? (vertex.material.y - 0.9) * 10 : 0.0;
    float4 color = PBR_Cybran(vertex, teamColorFactor, hiDefShadows);

    // Adjust the transparency of the unit so that it is 40% visible, until the unit is 70% complete
    float alpha = (vertex.material.y >= 0.7) ? 0.4 + (0.6 * ((vertex.material.y - 0.7) * 3.33)) : 0.4;

    return float4(color.rgb, alpha);
}

float4 PBR_SeraphimPS(NORMALMAPPED_VERTEX vertex, uniform bool hiDefShadows) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth.x);

    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal);
    float3 normal = ComputeNormal( normalsSampler, vertex.texcoord0.zw, rotationMatrix);
    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.xy);
    float4 specular = tex2D( specularSampler, vertex.texcoord0.xy);

    return PBR_Seraphim(vertex, albedo, specular, normal, hiDefShadows);
}

float4 PBR_SeraphimBuildPS(NORMALMAPPED_VERTEX vertex, uniform bool hiDefShadows) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth.x);

    float4 texcoord = vertex.texcoord0;
    texcoord.y += vertex.material.x * 0.005;
    float buildFractionMul = (vertex.material.y - 0.9) * 10;
    float4 uvaddress = tex2D( secondarySampler, texcoord * 0.5 ) * 0.03;
    float2 texcoord2 = vertex.texcoord0.xy + lerp( uvaddress.rb, 0, buildFractionMul );

    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal);
    float3 normal = ComputeNormal( normalsSampler, vertex.texcoord0.zw + lerp( uvaddress.rb, 0, buildFractionMul ), rotationMatrix);
    float4 albedo = tex2D( albedoSampler, texcoord2);
    float4 specular = tex2D( specularSampler, texcoord2);

    float3 color = PBR_Seraphim(vertex, albedo, specular, normal, hiDefShadows).rgb;

    return float4(color, max(vertex.material.y, 0.25));
}

/// VertexNormalPS_HighFidelity
///
/// Lighting using vertex normals only.
/// Used by props, mainly some rocks.
/// And the lod1 of many trees apparently. Kinda weird.
float4 VertexNormalPS_HighFidelity( VERTEXNORMAL_VERTEX vertex,
                        		    uniform bool hiDefShadows,
                        		    uniform bool alphaTestEnable,
                        		    uniform int alphaFunc,
                        		    uniform int alphaRef ) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth);

    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.xy);

    float dotLightNormal = dot(sunDirection,vertex.normal);
    float3 light = ComputeLight( dotLightNormal, ComputeShadow( vertex.shadow, hiDefShadows));

    float alpha = mirrored ? 0.5 : vertex.material.g * albedo.a;
    float3 color = vertex.color.rgb * albedo.rgb * light;
    color = ApplyWaterColor(vertex.depth.x, vertex.viewDirection, color);

#ifdef DIRECT3D10
    if( alphaTestEnable )
        AlphaTestD3D10( alpha, alphaFunc, alphaRef );
#endif
    return float4(color.rgb,alpha);
}

/// VertexNormalPS_LowFidelity
///
/// Lighting using vertex normals only.
float4 VertexNormalPS_LowFidelity(VERTEXNORMAL_VERTEX vertex,
                        		  uniform bool alphaTestEnable,
                        		  uniform int alphaFunc,
                        		  uniform int alphaRef ) : COLOR0
{
    float4 albedo = tex2D(albedoSampler,vertex.texcoord0.xy);
    float3 light = ComputeLight(dot(sunDirection,vertex.normal),1);
    float3 color = 2 * light.rgb * light.rgb * albedo.rgb;

    float alpha = albedo.a*vertex.material.g;
#ifdef DIRECT3D10
    if( alphaTestEnable )
        AlphaTestD3D10( alpha, alphaFunc, alphaRef );
#endif
    return float4(color,alpha);
}

///
///
///
float4 ColorMaskPS_LowFidelity(VERTEXNORMAL_VERTEX vertex) : COLOR0
{
    float4 albedo = tex2D(albedoSampler,vertex.texcoord0.xy);
    float4 specular = tex2D(specularSampler,vertex.texcoord0.xy);
    albedo.rgb = lerp(vertex.color.rgb,albedo.rgb,1 - saturate(specular.a));
    float3 light = ComputeLight(dot(sunDirection,vertex.normal),1);
    float3 color = 2 * light.rgb * light.rgb * albedo.rgb;
    return float4(color.rgb,vertex.material.g);
}

/// ClutterPS
///
/// Lighting using vertex normals only with dissolve.
float4 ClutterPS( CLUTTER_VERTEX vertex,
                  uniform bool alphaTestEnable,
                  uniform int alphaFunc,
                  uniform int alphaRef ) : COLOR0
{
    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal);

    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.xy);
    float3 normal = ComputeNormal( normalsSampler, vertex.texcoord0.zw, rotationMatrix);
    float  dissolve = saturate( vertex.dissolve * ( 0.5 * tex2D( dissolveSampler, vertex.texcoord0).a + 0.5));

    float dotLightNormal = dot(sunDirection,normal);
    float3 light = ComputeLight( dotLightNormal, 1.0);

    float alpha = dissolve * albedo.a;
#ifdef DIRECT3D10
    if( alphaTestEnable )
        AlphaTestD3D10( alpha, alphaFunc, alphaRef );
#endif
    return float4( albedo.rgb * light, alpha);
}

/// NormalMappedPS
///
/// Lighting using normal maps.
/// Used by some props, mostly trees
float4 NormalMappedPS( NORMALMAPPED_VERTEX vertex,
                       uniform bool maskAlbedo,
                       uniform bool glow,
                       uniform bool hiDefShadows,
                       uniform bool alphaTestEnable,
                       uniform int alphaFunc,
                       uniform int alphaRef ) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth.x);

    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal);
    float3 normal = ComputeNormal( normalsSampler, vertex.texcoord0.zw, rotationMatrix);
    float dotLightNormal = dot(sunDirection,normal);

    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.xy);
    float4 specular = tex2D( specularSampler, vertex.texcoord0.xy);
    float3 environment = texCUBE( environmentSampler, reflect( -vertex.viewDirection, normal));

    if ( maskAlbedo )
        albedo.rgb = lerp( vertex.color.rgb, albedo.rgb, 1 - specular.a );
    else
        albedo.rgb = albedo.rgb * vertex.color.rgb;

    float phongAmount = saturate( dot( reflect( sunDirection, normal), -vertex.viewDirection));
    float3 phongAdditive = NormalMappedPhongCoeff * pow( phongAmount, 2) * specular.g;
    float3 phongMultiplicative = float3( 2 * environment * specular.r);

    float3 light = ComputeLight( dotLightNormal, ComputeShadow( vertex.shadow, hiDefShadows));

    float emissive = glowMultiplier * specular.b;
    float3 color = albedo.rgb * ( emissive.r + light + phongMultiplicative) + phongAdditive;
    color = ApplyWaterColor(vertex.depth.x, vertex.viewDirection, color);

    float alpha = mirrored ? 0.5 : ( glow ? ( specular.b + glowMinimum ) : ( vertex.material.g * albedo.a ));

#ifdef DIRECT3D10
    if( alphaTestEnable )
        AlphaTestD3D10( alpha, alphaFunc, alphaRef );
#endif
    return float4( color.rgb, alpha );
}

/// MapImagerPS0
///
///
float4 MapImagerPS0( NORMALMAPPED_VERTEX vertex) : COLOR0
{
    float3x3 rotationMatrix = float3x3(vertex.binormal,vertex.tangent,vertex.normal);
    float3 normal = ComputeNormal(normalsSampler,vertex.texcoord0.zw,rotationMatrix);

    float4 albedo = tex2D(albedoSampler,vertex.texcoord0.xy);
    float mask = tex2D(specularSampler,vertex.texcoord0.xy).b;
    float shade = lerp(saturate(dot(sunDirection,normal)),1,mask);
    albedo.rgb = float3(1,1,1) * shade * (albedo.rgb + albedo.aaa) + float3(0.02,0.02,0.02);

    return float4(albedo.rgb,0);
}

/// MapImagerPS1
///
///
float4 MapImagerPS1( NORMALMAPPED_VERTEX vertex) : COLOR0
{
    float4 specular = tex2D(specularSampler,vertex.texcoord0.xy);
    return float4(0,0,0,specular.b+glowMinimum);
}

/// AlbedoPreviewPS
///
/// Used by the unit viewer to preview the albedo map.
float4 AlbedoPreviewPS( NORMALMAPPED_VERTEX vertex) : COLOR0
{
    return tex2D( albedoSampler, vertex.texcoord0.xy);
}

/// NormalsPreviewPS
///
/// Used by the unit viewer to preview the normal map.
float4 NormalsPreviewPS( NORMALMAPPED_VERTEX vertex) : COLOR0
{
    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal);
    float3 normal = ComputeNormal( normalsSampler, vertex.texcoord0.zw, rotationMatrix);
    return float4( normal, 1);
}

/// LightingPreviewPS
///
/// Used by the unit viewer to preview a unit's lighting.
float4 LightingPreviewPS( NORMALMAPPED_VERTEX vertex) : COLOR0
{
    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal);
    float3 normal = ComputeNormal( normalsSampler, vertex.texcoord0.zw, rotationMatrix);
    float dotLightNormal = dot(sunDirection,normal);
    return float4( dotLightNormal.xxx, 1);
}

/// BlackenedNormalMappedPS
///
float4 BlackenedNormalMappedPS( NORMALMAPPED_VERTEX vertex,
                        		uniform bool maskAlbedo,
                        		uniform bool glow,
                        		uniform bool hiDefShadows,
                        		uniform bool alphaTestEnable,
                        		uniform int alphaFunc,
                        		uniform int alphaRef ) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth.x);

    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal);
    float3 normal = ComputeNormal( normalsSampler, vertex.texcoord0.zw, rotationMatrix);
    float dotLightNormal = dot(sunDirection,normal);

    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.xy);

    // blacken the albedo
    albedo.rgb = dot(albedo.rgb, float3(.1,.1,.1));

    float4 specular = tex2D( specularSampler, vertex.texcoord0.xy);
    float3 environment = texCUBE( environmentSampler, reflect( -vertex.viewDirection, normal));

    if ( maskAlbedo )
        albedo.rgb = lerp( vertex.color.rgb, albedo.rgb, 1 - specular.a );
    else
        albedo.rgb = albedo.rgb * vertex.color.rgb;

    float phongAmount = saturate( dot( reflect( sunDirection, normal), -vertex.viewDirection));
    float3 phongAdditive = pow( phongAmount, 8) * specular.g;
    float3 phongMultiplicative = float3( 2 * environment * specular.r);

    float3 light = ComputeLight( dotLightNormal, ComputeShadow( vertex.shadow, hiDefShadows));

    float emissive = glowMultiplier * specular.b;
    float3 color = albedo.rgb * ( emissive.r + light + phongMultiplicative) + phongAdditive;

    float alpha = mirrored ? 0.5 : ( glow ? ( specular.b + glowMinimum ) : ( vertex.material.g * albedo.a ));

#ifdef DIRECT3D10
    if( alphaTestEnable )
        AlphaTestD3D10( alpha, alphaFunc, alphaRef );
#endif
    return float4( color, alpha);
}

float4 BlackenedLoFiPS( VERTEXNORMAL_VERTEX vertex,
                        uniform bool alphaTestEnable,
                        uniform int alphaFunc,
                        uniform int alphaRef ) : COLOR0
{
    float4 color = tex2D( albedoSampler, vertex.texcoord0.xy);
    color.rgb = dot(color.rgb, float3(.1,.1,.1));
    float3 light = ComputeLight( dot(sunDirection,vertex.normal), 1);

    color.rgb *= light;
    color.a = vertex.material.g * color.a;

#ifdef DIRECT3D10
    if( alphaTestEnable )
        AlphaTestD3D10( color.a, alphaFunc, alphaRef );
#endif
    return color;
}

/// WreckagePS
///
/// Wreckage that applies noise over the albedo and normal maps
float4 WreckagePS( NORMALMAPPED_VERTEX vertex) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth.x);

    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal);
    float3 normal = ComputeNormal( normalsSampler, vertex.texcoord0.zw, rotationMatrix);
    float dotLightNormal = dot(sunDirection,normal);

    float2 texcoord = vertex.texcoord0.xy;
    float4 albedo = tex2D( albedoSampler, texcoord);
    texcoord.y -= frac( 0.01 * vertex.depth.y );
    texcoord.x += frac( 0.01 * vertex.depth.y );
    float4 specular = tex2D( specularSampler, texcoord * 5.15);

    /// Wreckage should not receive shadows (the "random" crunchiness makes for bad artifacts.)
    float3 color = albedo * ComputeLight( dotLightNormal, 1);

    if( specular.g < 0.22 )
        color *= (albedo + specular.r + specular.a) * specular.b * 2.5;
    else
        color *= specular.b * 2;

    color = ApplyWaterColor(vertex.depth.x, vertex.viewDirection, color);

    return float4( color, glowMinimum );
}

float4 WreckagePS_LowFidelity(VERTEXNORMAL_VERTEX vertex) : COLOR0
{
    float4 albedo = tex2D(albedoSampler,vertex.texcoord0.xy);
    float4 specular = tex2D(specularSampler,vertex.texcoord0.xy * 10 );
    float3 color = albedo.rgb * ComputeLight(dot(sunDirection,vertex.normal),1);
    color *= (albedo + specular.r + specular.a) * specular.b * 5.5;
    return float4(color.rgb,vertex.material.g);
}

/// NormalMappedTerrainPS
///
/// Used by some props, mostly rocks and ice floes
float4 NormalMappedTerrainPS( NORMALMAPPED_VERTEX vertex ) : COLOR
{
    if ( 1 == mirrored ) clip( vertex.depth.x);

    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal);
    float3 normal = ComputeNormal( normalsSampler, vertex.texcoord0.zw, rotationMatrix);
    float dotLightNormal = dot(sunDirection,normal);

    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.xy);
    albedo.rgb = albedo.rgb * vertex.color.rgb;
    float3 light = ComputeLight( dotLightNormal, ComputeShadow(vertex.shadow, true));
    float alpha = mirrored ? 0.5 : glowMinimum;

    float3 color = light * albedo.rgb;
    color = ApplyWaterColor(vertex.depth.x, vertex.viewDirection, color);

    return float4(color,alpha);
}

/// AlphaFadePS
///
///
float4 AlphaFadePS( VERTEXNORMAL_VERTEX vertex,
                    uniform float timeFade,
                    uniform float fadeMultiplier,
                    uniform bool hiDefShadows,
                    uniform bool alphaTestEnable,
                    uniform int alphaFunc,
                    uniform int alphaRef ) : COLOR0
{
    float4 color = tex2D( albedoSampler, vertex.texcoord0.xy);

    float dotLightNormal = dot(sunDirection,vertex.normal);
    float3 light = ComputeLight( dotLightNormal, ComputeShadow( vertex.shadow, hiDefShadows));

    color = float4( color.rgb * light, color.a * vertex.material.y );
    color.a *= saturate( 1.0f - ( vertex.material.x - timeFade) * fadeMultiplier);

#ifdef DIRECT3D10
    if( alphaTestEnable )
        AlphaTestD3D10( color.a, alphaFunc, alphaRef );
#endif
    return color;
}

float4 AlphaFadeLoFiPS( VERTEXNORMAL_VERTEX vertex,
                        uniform float timeFade,
                        uniform float fadeMultiplier,
                        uniform bool alphaTestEnable,
                        uniform int alphaFunc,
                        uniform int alphaRef ) : COLOR0
{
    float4 color = tex2D( albedoSampler, vertex.texcoord0.xy);
    float3 light = ComputeLight( dot(sunDirection,vertex.normal), 1);

    color = float4( color.rgb * light, color.a * vertex.material.y );
    color.a *= saturate( 1.0f - ( vertex.material.x - timeFade) * fadeMultiplier);

#ifdef DIRECT3D10
    if( alphaTestEnable )
        AlphaTestD3D10( color.a, alphaFunc, alphaRef );
#endif
    return color;
}

float4 CommandFeedbackPS0( VERTEXNORMAL_VERTEX vertex, uniform bool fade ) : COLOR0
{
    float4 color = tex2D( albedoSampler, vertex.texcoord0.xy);
    return float4(color.rgb, fade ? saturate(color.a * vertex.material.x) : color.a );
}

float4 FakeRingsPS( VERTEXNORMAL_VERTEX vertex, uniform float alpha) : COLOR0
{
    float4 color = tex2D( albedoSampler, vertex.texcoord0.xy);
    return float4(color.rgb, vertex.material.y );
}

float4 CommandFeedbackPS1( VERTEXNORMAL_VERTEX vertex, uniform float glow) : COLOR0
{
    return float4(0,0,0,glow);
}

/// AlphaFadeTexShiftScalePS
///
///
float4 AlphaFadeTexShiftScalePS( EFFECT_VERTEX vertex, uniform float texScale, uniform float timeCoeff, uniform float timeFade, uniform float fadeMultiplier ) : COLOR
{
    float2 texcoord = texScale * vertex.texcoord0;
    texcoord.y += vertex.material.x * timeCoeff;

    float4 color = tex2D( albedoSampler, texcoord);
    color.a *= tex2D( normalsSampler, vertex.texcoord0).g;//specularSampler
    color.a *= saturate( 1.0f - ( vertex.material.x - timeFade) * fadeMultiplier);

    return color;
}

/// NukeHeadPS
///
///
float4 NukeHeadPS( EFFECT_VERTEX vertex,
                   uniform float texScale,
                   uniform float timeCoeff,
                   uniform float timeFade,
                   uniform float fadeMultiplier,
                   uniform bool alphaTestEnable,
                   uniform int alphaFunc,
                   uniform int alphaRef ) : COLOR
{
    float2 texcoord = vertex.texcoord0;
    float cTime = vertex.material.x;
    //texcoord.y += vertex.material.x * timeCoeff * 0.25;

    float2 texcoord2 = 6 * vertex.texcoord0;
    texcoord2.y += cTime * timeCoeff * 1.25;

    float2 texcoord3 = 4 * vertex.texcoord0;
    texcoord3.y += cTime * timeCoeff * 1.25;

    float2 texcoord4 = 0.25 * vertex.texcoord0;
    texcoord4.y += cTime * timeCoeff * 0.1;

    float4 color = tex2D( albedoSampler, texcoord);
    float4 color2 = tex2D( normalsSampler, texcoord2);
    float4 color3 = tex2D( normalsSampler, texcoord3);
    float4 color4 = tex2D( normalsSampler, texcoord4);
    float4 outColor = color;
    outColor.rgb = (color3.g + color2.b) * 0.5;
    outColor.rgb = (outColor.r + color4.b) * 0.5;
    outColor.rgb += (color4.r * 0.5);
    outColor.rgb = lerp( outColor, color, 0.5);
    outColor.rgb += (color2.b * 0.3);
    outColor.rgb *= color3.g;
    outColor.rgb += color2.b;
    //color.rgb += lerp( color.rgb, color3.r, 0.5 );
    //color.rgb += color2.b;// - color3.r) * color3.a) + (color2.a * 0.2);
    outColor.a *= saturate( 1.0f - ( cTime - timeFade) * fadeMultiplier);

    float fade = cTime - 20;
    // Dissolve textue based on current alpha value and the noise in NormalSampler texture
    if( fade >= 0 )
    {
        if( (color2.a * color3.b * color2.g) >= color.a )
            outColor.a = 0;
    }

    outColor.a *= color2.g;

#ifdef DIRECT3D10
    if( alphaTestEnable )
        AlphaTestD3D10( outColor.a, alphaFunc, alphaRef );
#endif
    return outColor;
}

/// UnitPlacePS
///
///
float4 UnitPlacePS( VERTEXNORMAL_VERTEX vertex) : COLOR0
{
    float4 color = vertex.color ;
    float dotLightNormal = dot(sunDirection,vertex.normal);
    float3 light = ComputeLight( dotLightNormal, 1);
    color = float4( color.rgb * light, 0.2 );
    return color;
}

/// NormalMappedMetalPS
///
///
float4 NormalMappedMetalPS( NORMALMAPPED_VERTEX vertex, uniform bool hiDefShadows) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth.x);

    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal);
    float3 normal = ComputeNormal( normalsSampler, vertex.texcoord0.zw, rotationMatrix);
    float dotLightNormal = dot(sunDirection,normal);

    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.xy);
    float4 specular = tex2D( specularSampler, vertex.texcoord0.xy);
    float3 environment = texCUBE( environmentSampler, reflect( -vertex.viewDirection, normal));

    float2 anisoLookup = float2( dot( reflect( sunDirection, normal), -vertex.viewDirection), dotLightNormal);
    float4 anisoAmount = tex2D( anisotropicSampler, anisoLookup);

    albedo.rgb = lerp( vertex.color.rgb, albedo.rgb, 1 - specular.a );

    float4 phongAdditive = anisoAmount * specular.g + float4( 0.5 * specular.r * environment, 0);

    float shadow = ComputeShadow( vertex.shadow, hiDefShadows);
    float3 light = ComputeLight( dotLightNormal, shadow);

    float emissive = glowMultiplier * specular.b;
    float3 color = albedo.rgb * ( emissive.r + light ) + phongAdditive.rgb;

    float alpha = mirrored ? 0.5 : specular.b + glowMinimum;

    return float4( color, alpha );
}

/// AeonPS
///
///
float4 AeonPS( NORMALMAPPED_VERTEX vertex, uniform bool hiDefShadows) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth.x);

    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal);
    float3 normal = ComputeNormal( normalsSampler, vertex.texcoord0.zw, rotationMatrix);
    float dotLightNormal = dot(sunDirection,normal);

    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.xy);
    float4 specular = tex2D( specularSampler, vertex.texcoord0.xy);
    float3 environment = texCUBE( environmentSampler, reflect( -vertex.viewDirection, normal));

    albedo.rgb = lerp( vertex.color.rgb, albedo.rgb, 1 - specular.a );

    float3 reflection = reflect( sunDirection, normal);
    float phongAmount = saturate( dot( reflection, -vertex.viewDirection));

    float3 phongAdditive = AeonPhongCoeff * pow( phongAmount, 3) * specular.g;
    float3 phongMultiplicative = specular.r * environment;

    float shadow = ComputeShadow( vertex.shadow, hiDefShadows);
    float3 light = sunDiffuse * saturate( dotLightNormal ) * shadow + sunAmbient;
    light = 0.6 * lightMultiplier * light + ( 1 - light ) * shadowFill;

    float emissive = glowMultiplier * specular.b;
    float3 color = albedo.rgb * ( emissive.r + light + phongMultiplicative ) + phongAdditive.rgb;

    float alpha = mirrored ? 0.5 : specular.b + glowMinimum;

    return float4( color, alpha );
}

/// AeonCZARPS
///
///
float4 AeonCZARPS( NORMALMAPPED_VERTEX vertex, uniform bool hiDefShadows) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth.x);

    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal);
    float3 normal = ComputeNormal( normalsSampler, vertex.texcoord0.zw, rotationMatrix);
    float dotLightNormal = dot(sunDirection,normal);

    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.xy);
    float4 specular = tex2D( specularSampler, vertex.texcoord0.xy);
    float3 environment = texCUBE( environmentSampler, reflect( -vertex.viewDirection, normal));

    albedo.rgb = lerp( vertex.color.rgb, albedo.rgb, 1 - specular.a );

    float3 reflection = reflect( sunDirection, normal);
    float phongAmount = saturate( dot( reflection, -vertex.viewDirection));

    float3 phongAdditive = pow( phongAmount, 8) * specular.g;
    float3 phongMultiplicative = specular.r * environment;

    float shadow = ComputeShadow( vertex.shadow, hiDefShadows);
    float3 light = sunDiffuse * saturate( dotLightNormal ) * shadow + sunAmbient;
    light = 0.6 * lightMultiplier * light + ( 1 - light ) * shadowFill;

    float emissive = glowMultiplier * specular.b;
    float3 color = albedo.rgb * ( emissive.r + light + phongMultiplicative ) + phongAdditive.rgb;

    float2 texcoord = vertex.texcoord0.xy * 60;
    texcoord.x -= vertex.material.x * 0.16;
    texcoord.y -= vertex.material.x * 0.01;
    float2 texcoord2 = vertex.texcoord0.xy * 30;
    texcoord2.x += vertex.material.x * 0.08;
    texcoord2.y -= vertex.material.x * 0.005;
    float3 secondary = tex2D( secondarySampler, texcoord );
    float3 secondary2 = tex2D( secondarySampler, texcoord2 );
    color += float3(0.2,0.7,1) * (secondary.b + secondary2.g )* (1-albedo.a);

    float alpha = mirrored ? 0.5 : specular.b + ((secondary.b + secondary2.g )* (1-albedo.a))+ glowMinimum;
    return float4( color, alpha );
}

/// UnitFalloffPS
///
/// - Similar to unit shader, with the exception that it uses the diffuse texture alpha
///   channel to mask area's in which the view dependant lookup texture is sampled.
///   Only works in Medium and High fidelity.
///   Used for Seraphim units
///
float4 UnitFalloffPS( NORMALMAPPED_VERTEX vertex, uniform bool hiDefShadows) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth.x);

    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal);
    float3 normal = ComputeNormal( normalsSampler, vertex.texcoord0.zw, rotationMatrix);
    float dotLightNormal = dot(sunDirection,normal);

    float4 diffuse = tex2D( albedoSampler, vertex.texcoord0.xy);
    float4 specular = tex2D( specularSampler, vertex.texcoord0.xy);
    float3 environment = texCUBE( environmentSampler, reflect( -vertex.viewDirection, normal));

    // Calculate lookup into falloff ramp
    float NdotV = pow(1 - saturate(dot( normalize(vertex.viewDirection), normal )), 0.6);
    float4 fallOff = tex2D( falloffSampler, float2(NdotV,vertex.material.x));

    // Calculate specular highlights based on current sun direction
    float3 reflection = reflect( sunDirection, normal);
    float specularAmount = saturate( dot( reflection, -vertex.viewDirection));
    float3 phongAdditive = float3 (0.5,0.6,0.7) * pow( specularAmount, 9) * specular.g;

    // Calculate environment map reflection
    environment *= specular.r * fallOff.a;

    // Calculate lighting and shadows
    float shadow = 0; // ComputeShadow( vertex.shadow, hiDefShadows);

    float3 light = sunDiffuse * saturate( dotLightNormal ) * shadow + sunAmbient;
    light = light + ( 1 - light ) * shadowFill;

    // This gives almost the same result as the ramp in fallOff.rgb, but we will use this,
    // because it produces consistent results with different player colors
    NdotV = 2 * pow(NdotV, 6) - 2 * NdotV + 1.5;
    float3 teamColor = NdotV * vertex.color.rgb;

    // Determine our final output color
    float3 color = diffuse.rgb * light;
    color += environment + phongAdditive;
    color += (teamColor.rgb * diffuse.a);

    float alpha = mirrored ? 0.5 : specular.b + glowMinimum;
    return float4( color, alpha );
}

float4 LowFiUnitFalloffPS( NORMALMAPPED_VERTEX vertex) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth.x);

    float4 diffuse = tex2D(albedoSampler,vertex.texcoord0.xy);
    float4 specular = tex2D(specularSampler,vertex.texcoord0.xy);

    diffuse.rgb = specular.ggg * specular.rrr * ( 1 - diffuse.rgb );
    diffuse.rgb = lerp(vertex.color,diffuse.rgb,specular.g);

    float3 normal = normalize(vertex.normal);

    float3 reflected = reflect(-normalize(vertex.viewDirection),normal);
    float highlight = pow(saturate(dot(reflected,sunDirection)),5);

    float dotLightNormal = dot(sunDirection,normal);
    float3 light = ComputeLight(dotLightNormal, 1);
    float3 color = diffuse.rgb * light + highlight.rrr;

    return float4(color.rgb,0);
}

// directx 9
// ps_2.0 -> limited set of 64 instructions
// ps_2.0_a -> limited set of 256 instructions

/// AeonBuildPS
///
///
float4 AeonBuildPS( NORMALMAPPED_VERTEX vertex, uniform bool hiDefShadows) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth.x);

    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal);
    float3 normal = ComputeNormal( normalsSampler, vertex.texcoord0.zw, rotationMatrix);
    float dotLightNormal = dot(sunDirection,normal);

    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.xy);
    float4 specular = tex2D( specularSampler, vertex.texcoord0.xy);
    float3 environment = texCUBE( environmentSampler, reflect( -vertex.viewDirection, normal));

    // Calculate lighting and shadows
    float3 light = ComputeLight_02( dotLightNormal, ComputeShadow( vertex.shadow, hiDefShadows));

    light = (light * 0.5) * pow((1 - specular.a), 8);

    // Calculate Specular and Reflection
    float3 reflection = reflect( sunDirection, normal);
    float phongAmount = saturate( dot( reflection, -vertex.viewDirection));
    float3 phongAdditive = AeonPhongCoeff * pow( phongAmount, 5) * light *  specular.g * pow((1 - (specular.a * 0.5) ), 8) * 2;
    float3 phongMultiplicative = specular.r * light * environment * (1 - specular.a) * 1.2;
    float phongMultiplicativeGlow = (phongMultiplicative.r + phongMultiplicative.g + phongMultiplicative.b)/3;
    float phongAdditiveGlow = (phongAdditive.r + phongAdditive.g + phongAdditive.b)/3;

    // Does the rest of the stuff
    float emissive = glowMultiplier * specular.b;
    float3 color = (albedo.rgb * 0.125) + (emissive + (light * albedo.rgb)) + phongAdditive + phongMultiplicative;

    float teamColorFactor = (vertex.material.y >= 0.90) ? (vertex.material.y - 0.9) * 10 : 0.0;
    color += teamColorFactor * (vertex.color.rgb * specular.a);
    float teamColGlowCompensation = teamColorFactor * ((vertex.color.r + vertex.color.g + vertex.color.b) / 3);
    float alpha = mirrored ? 0.5 : specular.b + glowMinimum + (pow(specular.a * 1.5, 2) * 0.07 * (1.4 - teamColGlowCompensation)) + ((phongMultiplicativeGlow + phongAdditiveGlow) * 0.05);

    return float4( color, alpha );
}

float4 AeonBuildOverlayPS( NORMALMAPPED_VERTEX vertex) : COLOR0
{
    // Diffuse texture
    float4 texcoord = vertex.texcoord0;
    texcoord.y += vertex.material.x * 0.00162;
    texcoord.x -= vertex.material.x * 0.001;
    float4 mask1 = tex2D( secondarySampler, texcoord * 2);

    float4 texcoord2 = vertex.texcoord0;
    texcoord2.y -= vertex.material.x * 0.00162;
    float4 mask2 = tex2D( secondarySampler, texcoord2 * 2);

    float3 diffuse = mask1.rrr - mask2.ggg + mask1.ggg * mask2.rrr;
    diffuse = lerp( diffuse, float3(0.5,0.5,0.5), 0.75);

    // Custom normal mapping
    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal );
    float3 normal = tex2D( normalsSampler, vertex.texcoord0.zw ).gaa;
    normal = lerp( normal, tex2D( secondarySampler, vertex.texcoord0 * 7 ).baa, 0.5);
    normal = lerp( normal, diffuse, 0.5);
    normal = 2 * normal - 1;
    normal.z = sqrt( 1 - normal.x*normal.x - normal.y*normal.y );
    normal = normalize( mul( normal, rotationMatrix));

    // Specular highlights
    float4 dotLightNormal = saturate(dot(sunDirection,normal));
    float3 reflection = normalize( 2 * dotLightNormal * normal - normalize(sunDirection));
    float4 specular = pow( saturate( dot(reflection, vertex.viewDirection )), 8);

    float3 color = diffuse * dotLightNormal + specular;

    // Fade out 95% complete
    float percentComplete = vertex.material.y;
    float alpha = (percentComplete >= 0.95) ? (1.0 - ((percentComplete - 0.95) * 20)) * (color.r * 2) : color.r * 2;

    return float4( color, alpha );
}

/// AeonBuildPuddlePS
///
///
float4 AeonBuildPuddlePS( NORMALMAPPED_VERTEX vertex, uniform bool hiDefShadows) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth.x);

    float2 texcoord = vertex.texcoord0.xy;
    texcoord.x -= vertex.material.x * 0.002;
    texcoord.y += vertex.material.x * 0.0042;

    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal);
    float3 normal = ComputeNormal( normalsSampler, texcoord, rotationMatrix);
    float dotLightNormal = dot(sunDirection,normal);

    float4 albedo = tex2D( albedoSampler, texcoord );

    float4 specular = tex2D( specularSampler, texcoord );
    float3 environment = texCUBE( environmentSampler, reflect( -vertex.viewDirection, normal));

    float3 reflection = reflect( sunDirection, normal);
    float phongAmount = saturate( dot( reflection, -vertex.viewDirection));

    float3 phongAdditive = pow( phongAmount, 8) * specular.g;
    float3 phongMultiplicative = specular.r * environment;

    float shadow = ComputeShadow( vertex.shadow, hiDefShadows);
    float3 light = sunDiffuse * saturate( dotLightNormal ) * shadow + sunAmbient;
    light = 0.4 * lightMultiplier * light + ( 1 - light ) * shadowFill;

    float emissive = glowMultiplier * specular.b;
    float3 color = albedo.rgb * ( emissive.r + light + phongMultiplicative ) + phongAdditive.rgb;

    float alpha = mirrored ? 0.5 : specular.b + glowMinimum;

    return float4( color, alpha );
}

float4 AeonBuildPuddleLoFiPS( VERTEXNORMAL_VERTEX vertex) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth.x);

    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.xy );
    //return albedo;
    float3 environment = texCUBE( environmentSampler, reflect( -sunDirection, vertex.normal) );
    return float4( albedo.rgb + (environment * 0.15), 1);
}

/// CybranBuildPS
///
///
float4 CybranBuildPS( NORMALMAPPED_VERTEX vertex, uniform bool hiDefShadows) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth);
    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal);

    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.xy);
    float3 normal = ComputeNormal( normalsSampler, vertex.texcoord0.zw, rotationMatrix);
    float4 specular = tex2D( specularSampler, vertex.texcoord0.xy);
    float3 environment = texCUBE( environmentSampler, reflect( -vertex.viewDirection, normal));

    float dotLightNormal = dot(sunDirection,normal);
    float2 anisoLookup = float2( dot( reflect( sunDirection, normal), -vertex.viewDirection), dotLightNormal);
    float4 anisoAmount = tex2D( insectSampler, anisoLookup);
    float4 phongAdditive = anisoAmount * specular.g + float4( 0.5 * specular.r * environment, 0);
    phongAdditive *= ( 1 - specular.a);

    float shadow = ComputeShadow( vertex.shadow, hiDefShadows);
    float3 light = 2 * sunDiffuse * saturate( dotLightNormal ) * shadow + sunAmbient;
    light = lightMultiplier * light + ( 1 - light ) * shadowFill;

    float emissive = glowMultiplier * specular.b;
    float3 teamColor = vertex.color.rgb;
    teamColor *= (vertex.material.y >= 0.90) ? (vertex.material.y - 0.9) * 10 : 0.0;
    albedo.rgb = lerp( teamColor, albedo.rgb, 1 - specular.a );

    float3 color = albedo.rgb * ( emissive.r + light ) + phongAdditive.rgb;

    // Adjust the transparency of the unit so that it is 40% visible, until the unit is 70% complete
    float alpha = (vertex.material.y >= 0.7) ? 0.4 + (0.6 * ((vertex.material.y - 0.7) * 3.33)) : 0.4;

    return float4( color, alpha );
}

float4 CybranBuildLoFiPS( VERTEXNORMAL_VERTEX vertex) : COLOR0
{
    float4 albedo = tex2D(albedoSampler,vertex.texcoord0.xy);
    float4 specular = tex2D(specularSampler,vertex.texcoord0.xy);
    albedo.rgb = lerp( vertex.color.rgb * vertex.material.y * 0.5,albedo.rgb,1 - saturate(specular.a));
    float3 light = ComputeLight(dot(sunDirection,vertex.normal),1);
    float alpha = (vertex.material.y >= 0.7) ? 0.4 + (0.6 * ((vertex.material.y - 0.7) * 3.33)) : 0.4;
    return float4( 2 * light.rgb * light.rgb * albedo.rgb, alpha);
}

/// CybranBuildOverlayPS
///
///
float4 CybranBuildOverlayPS( VERTEXNORMAL_VERTEX vertex) : COLOR0
{
    float4 secondary = tex2D(secondarySampler, vertex.texcoord0.xy );
    float4 alphamask1 = tex2D(secondarySampler, vertex.shadow.xy );
    float4 color = float4( secondary.a * 0.75, 0, 0, alphamask1.r * secondary.a );
    color.a *= (vertex.material.y >= 0.95) ? 1.0 - ((vertex.material.y - 0.95) * 20) : 1.0;
    return color;
}

/// SeraphimBuildPS
///
///
float4 SeraphimBuildPS( NORMALMAPPED_VERTEX vertex, uniform bool hiDefShadows) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth.x);

    float4 texcoord = vertex.texcoord0;
    texcoord.y += vertex.material.x * 0.005;
    float buildFractionMul = (vertex.material.y - 0.9) * 10;

    float4 uvaddress = tex2D( secondarySampler, texcoord * 0.5 ) * 0.03;
    float2 texcoord2 = vertex.texcoord0.xy + lerp( uvaddress.rb, 0, buildFractionMul );

    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal);
    float3 normal = ComputeNormal( normalsSampler, vertex.texcoord0.zw + lerp( uvaddress.rb, 0, buildFractionMul ), rotationMatrix);
    float dotLightNormal = dot(sunDirection,normal);

    // Calculate lookup texture for falloff ramp
    float NdotV = saturate(dot( normalize(vertex.viewDirection), normal ));
    float4 fallOff = tex2D( falloffSampler, float2(pow(1 - NdotV, 0.6),vertex.material.x));
    
    // Calculate lighting and shadows
    float shadow = ComputeShadow( vertex.shadow, hiDefShadows);
    float3 light = sunDiffuse * saturate( dotLightNormal ) * shadow + sunAmbient;
    float correction = sunDiffuse.g + sunAmbient.g; 
    light = light / correction + ( 1 - light / correction ) * shadowFill * 0.5;

    float4 diffuse = tex2D( albedoSampler, texcoord2);
    float4 specular = tex2D( specularSampler, texcoord2);
    float3 environment = texCUBE( environmentSampler, reflect( -vertex.viewDirection, normal));
    environment *= specular.r * fallOff.a * light;
    
    // Calculate specular highlights of the sun
    float3 reflection = reflect( sunDirection, normal);
    float specularAmount = saturate( dot( reflection, -vertex.viewDirection));
    float3 phongAdditive = pow( specularAmount, 9) * specular.g * shadow * sunDiffuse * 0.7;

    // Determine our final output color
    float3 color = (diffuse.rgb + float3 (0.25,0.35,0.45)) * light * (1 - diffuse.a) * 0.65;
    color += environment + phongAdditive + (NdotV * vertex.color.rgb * diffuse.a);

    return float4( color, max(vertex.material.y, 0.25) );
}

/// UEFBuildPS
///
///
float4 UEFBuildHiFiPS( NORMALMAPPED_VERTEX vertex, uniform bool hiDefShadows) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth);

    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal);

    float4 texcoord = vertex.texcoord0;
    float4 texcoord2 = texcoord * 5;
    texcoord2.y += vertex.material.x * 0.062;

    float4 albedo = tex2D( albedoSampler, texcoord.xy);
    float3 normal = ComputeNormal( normalsSampler, vertex.texcoord0.zw, rotationMatrix);
    float4 specular = tex2D( specularSampler, texcoord.xy);
    float3 environment = texCUBE( environmentSampler, reflect( -vertex.viewDirection, normal));
    float4 secondary = tex2D( secondarySampler, texcoord2.xy * 10);

    float3 teamColor = vertex.color.rgb;
    teamColor *= (vertex.material.y >= 0.90) ? (vertex.material.y - 0.9) * 10 : 0.0;
    albedo.rgb = lerp( teamColor, albedo.rgb, 1 - specular.a );
    float phongAmount = saturate( dot( reflect( sunDirection, normal), -vertex.viewDirection));
    float3 phongAdditive = pow( phongAmount, 8) * specular.g;
    float3 phongMultiplicative = float3( 2 * environment * specular.r);

    float3 light = ComputeLight( dot(sunDirection,normal), ComputeShadow( vertex.shadow, hiDefShadows));

    float emissive = glowMultiplier * specular.b;
    float3 color = albedo.rgb * ( emissive.r + light + phongMultiplicative) + phongAdditive;

    float1 t = min(max(frac( 0.02 * time), 0.35), 0.7);
    float3 current = lerp(color+secondary.rgb,float3(0,0,1),t);
    float3 outColor =  lerp( current, color, vertex.material.y);

    return float4( outColor, max(vertex.material.y, 0.5));
}

float4 UEFBuildLoFiPS( VERTEXNORMAL_VERTEX vertex) : COLOR0
{
    float4 albedo = tex2D( albedoSampler, vertex.texcoord0);
    float4 specular = tex2D( specularSampler, vertex.texcoord0);
    albedo.rgb = lerp( vertex.color.rgb * vertex.material.y * 0.25, albedo.rgb, saturate(1 - specular.a) );
    float3 light = ComputeLight( dot(sunDirection,vertex.normal), 1);
    float4 color = ( saturate( 2 * light.rgb * light.rgb * albedo.rgb ) + ((1 - vertex.material.y) * float3( 0, 0, 1 )), max(vertex.material.y, 0.5));
    return color;
}

/// UEFBuildOverlayPS
///
///
float4 UEFBuildOverlayHiFiPS( VERTEXNORMAL_VERTEX vertex) : COLOR0
{
    float4 xshift = tex2D( secondarySampler, vertex.texcoord0.xy );
    float4 yshift = tex2D( secondarySampler, vertex.texcoord0.zw );

    // Fade the overlay mask alpha to 0 in the last 5% of building
    float alpha = max((xshift.a + yshift.a) * (1.0 - vertex.material.y), 0.25);
    alpha *= (vertex.material.y >= 0.95) ? 1.0 - ((vertex.material.y - 0.95) * 20) : 1.0;

    return float4(xshift.rgb + yshift.rgb, alpha);
}

float4 UEFBuildOverlayLoFiPS( VERTEXNORMAL_VERTEX vertex) : COLOR0
{
    float4 xshift = tex2D( secondarySampler, vertex.texcoord0.xy );
    float4 yshift = tex2D( secondarySampler, vertex.shadow.xy );

    // Fade the overlay mask alpha to 0 in the last 5% of building
    float alpha = (xshift.a + yshift.a) * saturate(1.0 - vertex.material.y);
    alpha = max(alpha, 0.25);

    return float4(xshift.rgb + yshift.rgb, alpha);
}

/// UEFBuildCubePS
///
///
float4 UEFBuildCubePS( NORMALMAPPED_VERTEX vertex) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth);

    float4 texcoord = vertex.texcoord0;
    texcoord.x += vertex.material.x * 0.012;
    texcoord.y += vertex.material.x * 0.062;
    float4 texcoord2 = texcoord;
    texcoord2.y += vertex.material.x * 0.062;

    float4 albedo = tex2D( albedoSampler, texcoord.xy * 0.025);
    float4 secondary = tex2D( secondarySampler, texcoord2.xy * 50);

    float3 color = albedo.rgb;
    float percentComplete = vertex.material.y;
    float3 outColor = color;

    float3 colorMod1 = float3( 0, 0, 1.0 );
    float3 current = lerp( color + secondary, colorMod1, max(frac( 0.05 * time), 0.35));
    outColor =  lerp( current, color, percentComplete);

    return float4( outColor, max(percentComplete, 0.5) * albedo.a);
}

float4 UEFBuildCubeLoFiPS( VERTEXNORMAL_VERTEX vertex) : COLOR0
{
    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.xy );
    float4 secondary = tex2D( secondarySampler, vertex.shadow.xy );

    float3 current = lerp( albedo.rgb + secondary, float3( 0, 0, 1.0 ), 0.65 );
    float3 outColor = lerp( current, albedo.rgb, saturate(vertex.material.y));

    return float4( outColor, max(vertex.material.y, 0.5) * albedo.a);
}

/// NormalMappedInsectPS
///
///
float4 NormalMappedInsectPS( NORMALMAPPED_VERTEX vertex, uniform bool hiDefShadows) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth);

    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal);
    float3 normal = ComputeNormal( normalsSampler, vertex.texcoord0.zw, rotationMatrix);
    float dotLightNormal = dot(sunDirection,normal);

    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.xy);
    float4 specular = tex2D( specularSampler, vertex.texcoord0.xy);
    float3 environment = texCUBE( environmentSampler, reflect( -vertex.viewDirection, normal));

    float2 anisoLookup = float2( dot( reflect( sunDirection, normal), -vertex.viewDirection), dotLightNormal);
    float4 anisoAmount = tex2D( insectSampler, anisoLookup);

    albedo.rgb = lerp( vertex.color.rgb, albedo.rgb, 1 - specular.a );

    float4 phongAdditive = anisoAmount * specular.g + float4( 0.05 * specular.r * environment, 0);
  phongAdditive *= ( 1 - specular.a);

    float shadow = ComputeShadow( vertex.shadow, hiDefShadows);
    float3 light = 2 * sunDiffuse * saturate( dotLightNormal ) * shadow + sunAmbient;
    light = lightMultiplier * light + ( 1 - light ) * shadowFill;

    float emissive = glowMultiplier * specular.b;
    float3 color = albedo.rgb * ( emissive.r + light ) + phongAdditive.rgb;

    float alpha = mirrored ? 0.5 : specular.b + glowMinimum;

    return float4( color, alpha);
}

float shieldWaterAbsorption(float depth) {
    float factor = 1.0;
    if (surfaceElevation > 0) {
        if (depth < 0) factor = 0.6;
        factor *= 1 - tex1D(WaterRampSampler, (-depth / (surfaceElevation - abyssElevation))).w;
    }
    return factor;
}

/// ShieldPS
///
///
float4 ShieldPS( EFFECT_VERTEX vertex ) : COLOR
{
    if ( 1 == mirrored ) clip(vertex.depth);

    float4 colorMask = tex2D( albedoSampler, vertex.texcoord0.xy);
    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.zw);
    float3 normal = tex2D( secondarySampler, vertex.texcoord1.xy ).gaa * 2 - 1;
    normal.z = sqrt( 1 - normal.x*normal.x - normal.y*normal.y );
    float3 specular = tex2D( specularSampler, vertex.texcoord1.zw );

    // Combine albedo and normal sampler for a final color
    float4 color = float4( mul( albedo.rgr, normal.rgb ) + float3( 0, 0, 0.25), 1.0);

    // Using the specular sampler, with 3 layers of noise in color chanels modulate the
    // alpha channel for the current pixel
    if( specular.g <= albedo.r )
    {
        if( specular.b >= albedo.g )
            color.a = ( color.b >= normal.b ) ? 0.12 : lerp( 0.05, 0, sin(frac( 0.01 * time) * 3.14) );
        else
            color.a = ( normal.b >= albedo.r ) ? 0.2 : lerp( 0.01, 0.1, sin(frac( 0.01 * time) * 3.14) );
    }
    else
    {
        if( specular.r >= albedo.r )
            color.a = ( specular.b >= albedo.r ) ? 0.025 : 0.1;
        else
            color.a = ( specular.g >= albedo.g ) ? 0.02 : lerp( 0.37, 0.46, sin(frac( 0.01 * time) * 3.14) );
    }

    color.rgb += float3( 0, 0, 0.15 );

    // Adjust color of shield based on its health percentage
    float4 colorMod1 = lerp(float4( 0.5, 0.0, 0.0, 0.05 ), color, 0.5);
    colorMod1 = lerp( color, colorMod1 + color, sin(frac( 0.06 * time) * 3.14) );
    color = lerp( colorMod1, color, vertex.material.y );
    color += (colorMask.b * 0.95);

    // Add in our alpha channel to mask UV pinching at the top of the sphere
    color.a *= colorMask.a;// * 0.75;
    color.a *= shieldWaterAbsorption(vertex.depth.x);

    return color;
}

float4 ShieldLoFiPS( LOFIEFFECT_VERTEX vertex ) : COLOR
{
    float3 color = float3( 0.0, 0.0, 0.3);
    float4 colormask = tex2D( albedoSampler, vertex.texcoord0.xy);
    float4 albedo = tex2D( albedoSampler, vertex.texcoord1.xy );
    float4 secondary = tex2D( secondarySampler, vertex.texcoord2.xy);
    float4 specular = tex2D( specularSampler, vertex.texcoord2.xy);

    color.rgb += albedo.r + secondary.b;
    float alpha = colormask.b * 0.7;

    if( specular.g <= albedo.g )
        alpha += 0.2;
    else
        alpha += 0.1;

    color.rgb += float3( 0, 0, 0.15 ) + colormask.bbb;

    alpha *= colormask.a;
    return float4(color,alpha);
}

/// ShieldCybranPS
///
///
float4 ShieldCybranPS( EFFECT_VERTEX vertex, uniform float alpha ) : COLOR
{
    if ( 1 == mirrored ) clip(vertex.depth);

    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.xy );
    float4 albedo2 = tex2D( albedoSampler, vertex.texcoord0.zw );
    float3 specular = tex2D( specularSampler, vertex.texcoord1.xy );
    float3 specular2 = tex2D( specularSampler, vertex.texcoord1.zw );

    // Color wackiness
    float3 color2 = (albedo2.b * specular2.g * 3 );
    float3 color3 = specular2.g * albedo.a;
    float3 color4 = ((albedo2.g - specular2.b ) * specular.b) * albedo.a;
    float3 finalColor = float3( 0.05, 0.0, 0.3 ) + color4 - color2 * color3;

    // Adjust color of shield based on its health percentage
    float3 colorMod1 = lerp(float3( 0.2, 0, 0.0 ), finalColor, 0.5);
    colorMod1 = lerp( finalColor, (colorMod1 - finalColor) + (color4 + colorMod1), sin(frac( 0.06 * vertex.material.x) * 3.14) );
    finalColor = lerp( colorMod1, finalColor, vertex.material.y);

    finalColor += (albedo.r + albedo2.r) * 0.1;
    finalColor -= (1 - albedo.a);

    float clradd = (finalColor.r + finalColor.g + finalColor.b);

    if (clradd < 0.1)
    {
        finalColor = float3( 0.15, 0.15, 0.3 );
    }
    else
    {
        if (clradd > 0.1)
        {
            if (clradd < 0.2)
                finalColor = specular.b;
        }
    }

    finalColor += ((albedo.r + albedo2.r) * float3( 0.0, 0.0, 0.3 ));

    // Alpha
    alpha += (albedo.r + albedo2.r) * 0.2;
    alpha *= shieldWaterAbsorption(vertex.depth.x);

    return float4(finalColor, alpha);
}

float4 ShieldCybranLoFiPS( LOFIEFFECT_VERTEX vertex, uniform float alpha ) : COLOR
{
    if ( 1 == mirrored ) clip(vertex.depth);

    // Texture samplers
    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.xy );
    float4 albedo2 = tex2D( albedoSampler, vertex.texcoord1.xy );
    float3 specular = tex2D( specularSampler, vertex.texcoord2.xy );

    // Color wackiness
    float3 color = float3( 0.2, 0.0, 0.5 ) * specular.b;
    alpha += (albedo.r + albedo2.r) * 0.8;
    return float4(color, alpha );
}


/// ShieldAeonPS
///
///
float4 ShieldAeonPS( EFFECT_NORMALMAPPED_VERTEX vertex ) : COLOR
{
    if ( 1 == mirrored ) clip(vertex.depth);

    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal);

    // Texture samplers
    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.xy );
    float3 specular = tex2D( specularSampler, vertex.texcoord0.zw );
    float3 specular2 = tex2D( specularSampler, vertex.texcoord1.xy );
    float3 normal = ComputeNormal( normalsSampler, vertex.texcoord1.zw * 4, rotationMatrix);

    float dotLightNormal = dot(sunDirection,normal);
    float phongAmount = saturate( dot( reflect( -vertex.viewDirection, normal), vertex.viewDirection)) * 0.6;
    float3 environment = texCUBE( environmentSampler, reflect( -vertex.viewDirection, normal));

    // Magic
    float3 terrainBand = albedo.b * 0.5;
    float3 color1 = phongAmount + environment - albedo.ggg;
    float3 color2 = (specular.rrr) * lerp( 0.6, 1.3, sin(frac( 0.015 * time) * 3.14));
    float3 color3 = (specular2.rrr) * lerp( 2.0, 2.2, sin(frac( 0.0045 * time) * 3.14));

    float3 finalColor = (color1 * color2) * color3;
    float3 color4 = (finalColor * normal.rgb) * 0.65 + finalColor;
    finalColor = color4 * environment * albedo.a;

    // Adjust color of shield based on its health percentage
    float3 colorMod1 = lerp(float3( 0.7, 0.3, 0.3 ), finalColor, 0.9 );
    float3 colorMod2 = lerp( finalColor, colorMod1, sin(frac( 0.05 * vertex.material.x) * 3.14) );
    finalColor = lerp( colorMod1, finalColor, vertex.material.y);

    float alpha = 0.707 * ((environment.r + environment.g + environment.b) * 0.25) + terrainBand.r;
    alpha *= shieldWaterAbsorption(vertex.depth.x);

    return float4( lerp( colorMod1, finalColor, vertex.material.y), alpha);
}

float4 ShieldAeonLoFiPS( LOFIEFFECT_VERTEX vertex, uniform float alpha ) : COLOR
{
    // Texture samplers
    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.xy );
    float4 specular = tex2D( specularSampler, vertex.texcoord1.xy );
    float3 specular2 = tex2D( specularSampler, vertex.texcoord2.xy );

    float3 finalColor = (dot(albedo.rgb * alpha, float3(.6,.6,.6)) + (albedo.rgb * alpha)) * ((specular.rrr * 1.45) + (specular2.rrr * 2.2));

    return float4( finalColor, 0.33 * alpha * albedo.a );
}

/// ShieldSeraphimPS
///
///
float4 ShieldSeraphimPS( EFFECT_NORMALMAPPED_VERTEX vertex ) : COLOR
{
    if ( 1 == mirrored )
        clip(vertex.depth);

    float4 normal_pixel = tex2D( normalsSampler, vertex.texcoord1.zw );
    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal );
    float3 normal = ComputeNormal( normalsSampler, vertex.texcoord1.zw, rotationMatrix );
    float4 uvaddress = tex2D( normalsSampler, vertex.texcoord1.xy );
    float2 texcoord = vertex.texcoord0.xy + (uvaddress.rb * 0.1);
    float4 specular = tex2D( specularSampler, texcoord );

    float m = abs( normal_pixel.g - 0.5 );
    const float max_brightness = 0.453;
    float dp = abs( cos(dot( float4(0,1,0,0), normal )) );
    float channel_color = max_brightness - clamp((1.0 - dp), 0, max_brightness );
    float t = abs(dot(float4(0,1,0,0), normalize(vertex.normal)));
    float time_cutoff = 0.753;
    float dp2 = abs(dot(vertex.viewDirection,normal));

    ///If we are not close enough to the top of the shield dome...
    if( t < time_cutoff )
    {
        m = 1.0;	/// This alpha multiple won't change alpha (So we are not fading to near transparency yet).
    }
    else
    {
        // NOTE: From right to left in the equation.
        // Get a percentage multiple of how close we are to the top of the dome from the
        // point where we want to start an alpha gradient to (close to) transparency. Using that
        // we mutliply by 0.7 in order to get a percentage of a percentage multiple that is less than one.
        // Then that is all subtracted from one, the closer we are to the top of the dome, the more we
        // are subtracting 0.7 from 1.0 and the closer our final percentage multiple is to 0.4, where the
        // final percentage multiple ('m') starts out at one. 0.7 is used to ensure that we do not go to complete
        // transparency and retain some feeling of a sphere around the top area of the dome.
        m = 1.0 - 0.7 * (t - time_cutoff) / (1.0 - time_cutoff);
    }

    ///Compute the final translucency value.
    float alpha = m *( dp2 * 0.3 + channel_color )*1.75;
    alpha *= shieldWaterAbsorption(vertex.depth.x);

    // Multiples(0.425,0.76274,1.0) are to give a blue tint. The dot product of the normal and the world up vector is squared
    // so that the blue and whitish color fade off in an exponential gradient.
    return  float4( 0.425 * dp * dp * specular.r, 0.76274 * dp * dp * specular.g, 1.0 * dp * dp * specular.b, alpha );
}

/// ShieldFillPS()
///
///
float4 ShieldFillPS( FLAT_VERTEX vertex ) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth.x);
    return float4(0,0,0,0);
}

float4 ShieldImpactPS( SHIELDIMPACT_VERTEX vertex, uniform float fadeTime, uniform float fadeMul  ) : COLOR
{
    if ( 1 == mirrored ) clip(vertex.depth);

    float alphaFade = saturate( 1.0f - ( vertex.material.x - fadeTime) * fadeMul);

    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.xy );
    float4 normal = tex2D( specularSampler, vertex.texcoord1.xy );
    float alphaMask = tex2D( specularSampler, vertex.texcoord2.xy ).a;

    float3 color =  float3( 0, 0, 0.5) + normal.r;
    float alpha = alphaMask * albedo.g * (normal.r + normal.g) * alphaFade;

    return float4( color, alpha );
}

float4 CybranShieldImpactPS( SHIELDIMPACT_VERTEX vertex, uniform float fadeTime, uniform float fadeMul, uniform float alphaIntensity ) : COLOR
{
    if ( 1 == mirrored ) clip(vertex.depth.x);

    float alphaFade = saturate( 1.0f - ( vertex.material.x - fadeTime) * fadeMul);

    // Read textures and modify texture coords, so that they slow down as it fades
    float4 color0 = tex2D( specularSampler, vertex.texcoord0.xy );
    float4 color1 = tex2D( specularSampler, vertex.texcoord1.xy );
    float4 color2 = tex2D( specularSampler, vertex.texcoord2.xy );

    float3 finalcolor = color1.rrr + color0.g;
    float alpha = color1.b * color2.r * alphaIntensity * alphaFade * color0.a;

    return float4( finalcolor, alpha );
}

float4 PhaseShieldPS( VERTEXNORMAL_VERTEX vertex ) : COLOR
{
    float2 tc1 = vertex.texcoord0.xy * 0.5;
    tc1.x += 0.005 * vertex.material.x;
    tc1.y += 0.02 * vertex.material.x;
    float4 lookup = tex2D( lookupSampler, tc1);

    float2 tc2 = vertex.texcoord0.xy * 4;
    tc2.y += 0.008 * vertex.material.x;
    tc2.x -= 0.008 * vertex.material.x;
    float4 lookup2 = tex2D( lookupSampler, tc2);

    float2 tc3 = vertex.texcoord0.xy * 0.01;
    tc3.x -= 0.0018 * vertex.material.x;
    float4 lookup3 = tex2D( lookupSampler, tc3);

    float electricity =  lookup.r * lookup2.b;
    float4 baseshellcolor = float4( 0.5, 0.5, 1, 1);
    float4 glowpulse = float4(lookup3.ggg, min(lookup3.g, 0.65) + electricity );

    return (baseshellcolor  + electricity) * glowpulse;
}

float4 AeonPhaseShieldPS( VERTEXNORMAL_VERTEX vertex ) : COLOR
{
    float2 tc1 = vertex.texcoord0.xy * 2;
    tc1.x += 0.005 * vertex.material.x;
    tc1.y += 0.02 * vertex.material.x;
    float4 lookup = tex2D( lookupSampler, tc1);

    float2 tc2 = vertex.texcoord0.xy * 8;
    tc2.y += 0.02 * vertex.material.x;
    tc2.x -= 0.02 * vertex.material.x;
    float4 lookup2 = tex2D( lookupSampler, tc2);

    float2 tc3 = vertex.texcoord0.xy * 0.03 ;
    tc3.x -= 0.001 * vertex.material.x;
    float4 lookup3 = tex2D( lookupSampler, tc3);

    float electricity = lookup.r * lookup2.b * 0.75;
    float4 baseshellcolor = float4( 0.4, 1, 0.6, 0.8);
    float4 glowpulse = float4(lookup3.ggg, min(lookup3.g, 0.65) + electricity );

    return (baseshellcolor + electricity) * glowpulse;
}

float4 CybranPhaseShieldPS( VERTEXNORMAL_VERTEX vertex ) : COLOR
{
    float2 tc1 = vertex.texcoord0.xy * 2;
    tc1.x += 0.1 * vertex.material.x;
    tc1.y += 0.5 * vertex.material.x;
    float4 lookup = tex2D( lookupSampler, tc1);

    float2 tc2 = vertex.texcoord0.xy * 8;
    tc2.y += 0.5 * vertex.material.x;
    tc2.x -= 0.5 * vertex.material.x;
    float4 lookup2 = tex2D( lookupSampler, tc2);

    float2 tc3 = vertex.texcoord0.xy * 0.001 ;
    tc3.x -= 0.001 * vertex.material.x;
    tc3.y  = 4;
    float4 lookup3 = tex2D( lookupSampler, tc3);

    float electricity =  lookup.r * lookup2.b * 2;
    float4 baseshellcolor = float4( 1, 0.1, 0.2, 0.9);
    float4 glowpulse = float4(lookup3.ggg, min(lookup3.g, 0.8) + electricity );

    return (baseshellcolor + electricity) * glowpulse;
}


float4 SeraphimPhaseShieldPS( VERTEXNORMAL_VERTEX vertex ) : COLOR
{
    float2 tc1 = vertex.texcoord0.xy * 0.5;
    tc1.x += 0.005 * vertex.material.x;
    tc1.y += 0.02 * vertex.material.x;
    float4 lookup = tex2D( secondarySampler, tc1);

    float2 tc2 = vertex.texcoord0.xy * 4;
    tc2.y += 0.008 * vertex.material.x;
    tc2.x -= 0.008 * vertex.material.x;
    float4 lookup2 = tex2D( secondarySampler, tc2);

    float2 tc3 = vertex.texcoord0.xy * 0.01;
    tc3.x -= 0.0018 * vertex.material.x;
    float4 lookup3 = tex2D( secondarySampler, tc3);

    float electricity =  lookup.r * lookup2.b;
    float4 baseshellcolor = float4( 0.5, 0.5, 1, 1);
    float4 glowpulse = float4(lookup3.ggg, min(lookup3.g, 0.65) + electricity );

    return (baseshellcolor  + electricity) * glowpulse;
}

float4 StunnedUnit( VERTEXNORMAL_VERTEX vertex ) : COLOR
{
    return float4( 0, 0, 0, 0.66 );
}

/// EffectPS
///
///
float4 EffectPS( EFFECT_VERTEX vertex ) : COLOR
{
    float2 texcoord = vertex.texcoord0;
    texcoord.y += vertex.material.x * 0.0008;
    texcoord.y *= 3;

    float4 color = tex2D( albedoSampler, texcoord);
    float alpha = 1.0 - tex2D( albedoSampler, vertex.texcoord0 ).a;

    alpha *= saturate( 1.0f - ( vertex.material.x - 180) * 0.025);

    return float4( color.xyz, alpha);
}

/// EffectFadePS
///
///
float4 EffectFadePS( EFFECT_VERTEX vertex, uniform float timeFade, uniform float fadeMultiplier, uniform bool hiDefShadows ) : COLOR0
{
    float4 color = tex2D( albedoSampler, vertex.texcoord0.xy);

    float dotLightNormal = dot(sunDirection,vertex.normal);
    float3 light = ComputeLight( dotLightNormal, 1);

    color = float4( color.rgb * light, color.a * vertex.material.y );
    color.a *= saturate( 1.0f - ( vertex.material.x - timeFade) * fadeMultiplier);

    return color;
}

/// ExplosionPS()
///
///
float expinitialfadeoutTime =  0.375;
float expfadeinTime         =  8.500;
float expalphafadeoutTime   = 10.000;
float expfadeMul            =  0.035;
float expfadeMul2           =  0.120;

float4 ExplosionPS( EFFECT_VERTEX vertex,
                    uniform bool alphaTestEnable,
                    uniform int alphaFunc,
                    uniform int alphaRef ) : COLOR0
{
    // Get our texture cood, precalc fadetime
    float2 t = vertex.texcoord0;
    float fade = vertex.material.x - expalphafadeoutTime;

    // Sample the AlbedoSampler texture and shift in different directions
    t.y += vertex.material.x * 0.0036;      // Modify our texture cood by scalar
    float4 c = tex2D( albedoSampler, t );   // Sample our current pixel at texture cood

    t.y += vertex.material.x * 0.018;
    float4 d = tex2D( specularSampler, t );

    // Add our sampled colors together and save off
    c = lerp(c, d, d.a);

    // Fade out these initial textures
    c.xyz *= saturate( 1.0f - (vertex.material.x - expinitialfadeoutTime) * expfadeMul);

    // Fade in 2nd Texture
    float4 e = tex2D( normalsSampler, t );
    e.xyz *= saturate( fade * expfadeMul);

    // Combine initial and 2nd texture, re-use d
    d = c + e;

    // Alpha out our texture overtime
    float alpha = saturate( 1.0f - fade * expfadeMul2);

    // Dissolve textue based on current alpha value and the noise in NormalSampler texture
    if( fade >= 0 )
    {
        if( e.a <= alpha )
            alpha += e.a;
        else
            alpha = 0;
    }

#ifdef DIRECT3D10
    if( alphaTestEnable )
        AlphaTestD3D10( alpha, alphaFunc, alphaRef );
#endif
    return float4( d.xyz, alpha );
}

float4 TwoTexShiftScalePS( VERTEXNORMAL_VERTEX vertex, uniform float colorMul, uniform float alpha ) : COLOR
{
    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.xy);
    float4 normal = tex2D( normalsSampler, vertex.shadow.xy);

    return float4( (albedo.rgb + normal.rgb) * colorMul * albedo.a, alpha);
}

float4 TexSubAlphaMaskStaticLoFiPS( LOFIEFFECT_VERTEX vertex, uniform float colorMul, uniform float alphaMul ) : COLOR
{
    float4 albedo = tex2D( albedoSampler, vertex.texcoord0);
    float4 normal = tex2D( normalsSampler, vertex.texcoord1);
    float alphaMask = tex2D( albedoSampler, vertex.texcoord2).a;

    return float4( (albedo.rgb - normal.rgb) * colorMul, alphaMul * alphaMask);
}



/// EditorMarkerPS
///
float4 EditorMarkerPS( VERTEXNORMAL_VERTEX vertex) : COLOR0
{
    float dotLightNormal = dot(sunDirection,vertex.normal);
    float3 light = ComputeLight( dotLightNormal, 1);

    return float4( vertex.color.rgb * light, 1);
}

float4 GlassAlphaPS( NORMALMAPPED_VERTEX vertex, uniform bool hiDefShadows ) : COLOR
{
    if ( 1 == mirrored ) clip(vertex.depth);

    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal);
    float3 normal = ComputeNormal( normalsSampler, vertex.texcoord0.zw, rotationMatrix);
    float dotLightNormal = dot(sunDirection,normal);

    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.xy);
    float4 specular = tex2D( specularSampler, vertex.texcoord0.xy);
    float3 environment = texCUBE( environmentSampler, reflect( -vertex.viewDirection, normal));
    //return float4( environment, 0.5);

    float2 anisoLookup = float2( dot( reflect( sunDirection, normal), -vertex.viewDirection), dotLightNormal);

    albedo.rgb = lerp( vertex.color.rgb, albedo.rgb, 1 - specular.a );

    float4 phongAdditive = specular.g + float4( 0.5 * specular.r * environment, 0);
    phongAdditive *= ( 1 - specular.a);

    float shadow = ComputeShadow( vertex.shadow, hiDefShadows);
    float3 light = 2 * sunDiffuse * saturate( dotLightNormal ) * shadow + sunAmbient;
    light = lightMultiplier * light + ( 1 - light ) * shadowFill;
    //return float4( light, 0.2);

    float emissive = glowMultiplier * specular.b;
    float3 color = albedo.rgb * ( emissive.r + light ) + phongAdditive.rgb;

    float alpha = mirrored ? albedo.a: albedo.a + specular.b + phongAdditive.a;

    return float4(color, alpha);
}

float4 GlassAlphaLoFiPS( VERTEXNORMAL_VERTEX vertex ) : COLOR
{
    float4 albedo = tex2D(albedoSampler,vertex.texcoord0.xy);
    float4 specular = tex2D(specularSampler,vertex.texcoord0.xy);
    albedo.rgb = lerp(vertex.color.rgb,albedo.rgb,1 - saturate(specular.a));
    float3 light = ComputeLight(dot(sunDirection,vertex.normal),1);
    float3 color = 2 * light.rgb * light.rgb * albedo.rgb;
    float alpha = mirrored ? albedo.a: albedo.a + specular.b;
    return float4(color.rgb,alpha);
}

///////////////////////////////////////
///
/// Techniques
///
///////////////////////////////////////



/// AlbedoPreview
///
///
technique AlbedoPreview
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_0 AlbedoPreviewPS();
    }
}


/// NormalsPreview
///
///
technique NormalsPreview
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_0 NormalsPreviewPS();
    }
}

/// LightingPreview
///
///
technique LightingPreview
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_0 LightingPreviewPS();
    }
}

/// Depth
///
///
technique Depth
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = false;
#endif

        VertexShader = compile vs_1_1 DepthVS();
        PixelShader = compile ps_2_0 DepthPS(false);
    }
}

/// SeraphimBuildDepth
///
///
technique SeraphimBuildDepth
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = false;
#endif

        VertexShader = compile vs_1_1 SeraphimBuildDepthVS();
        PixelShader = compile ps_2_0 DepthPS(false);
    }
}

/// DepthClip
///
///
technique DepthClip
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = false;
#endif

        VertexShader = compile vs_1_1 DepthVS();
        PixelShader = compile ps_2_0 DepthPS(true);
    }
}

/// UndulatingDepthClip
///
///
technique UndulatingDepthClip
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = false;
#endif

        VertexShader = compile vs_1_1 UndulatingDepthVS();
        PixelShader = compile ps_2_0 DepthPS(true);
    }
}

/// Occlude
///
/// Technique for updating the stencil buffer with occluding data.  In other words,
/// set bit 0 for all pixels which can act as an occluder.
/// See: Silhouette below and TSilhouette in frame.fx
technique Occlude
{
    /// Set bit 0 everywhere in the stencil buffer there is
    /// an "occluding" pixel.
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_None )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Occlude )

        VertexShader = compile vs_1_1 SilhouetteVS();
        PixelShader = null;
    }
}

/// Silhouette
///
/// Technique for updating the stencil buffer with occluded data.
/// See: Occlude above and TSilhouette in frame.fx
technique Silhouette
{
    /// First pass
    ///
    /// Set bit 1 everywhere there is an "occluded" pixel.  Bit 0 is set for all occluders.  Therefore,
    /// the value 0x03 will exist in the stencil buffer for all occluder and occluded
    /// overlaps.
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_None )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_SilhouetteP0 )

        VertexShader = compile vs_1_1 SilhouetteVS();
        PixelShader = null;
    }

    /// Second pass
    ///
    /// Clear the stencil buffer everywhere bits 0 and 1 are set (0x03) and
    /// the depth test passes.  If the stencil test passes but the depth test fails,
    /// keep the value 0x03 which will serve as the acutal silhouette in the stencil buffer.
    pass P1
    {
        DepthState( Depth_SilhouetteP1 )

        VertexShader = compile vs_1_1 SilhouetteVS();
        PixelShader = null;
    }
}

/// CartographicFeedback
///
///
technique CartographicFeedback
<
    int renderStage = 0;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x7F;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 CartographicFeedbackVS();
        PixelShader = compile ps_2_0 CartographicFeedbackPS(true);
    }
}

/// CartographicFeature
///
///
technique CartographicFeature
<
    int renderStage = 0;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x7F;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 CartographicVS();
        PixelShader = compile ps_2_0 CartographicPS(true);
    }
}

/// CartographicUnit
///
///
technique CartographicUnit
<
    int renderStage = 0;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 CartographicVS();
        PixelShader = compile ps_2_0 CartographicPS(false);
    }
    pass P1
    {
        AlphaState( AlphaBlend_Disable_Write_A )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Disable )

        VertexShader = compile vs_1_1 CartographicVS();
        PixelShader = compile ps_2_0 CartographicGlowPS();
    }
}

/// CartographicPlace
///
///
technique CartographicPlace
<
    int renderStage = 0;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 CartographicVS();
        PixelShader = compile ps_2_0 CartographicPlacePS();
    }
}

/// CartographicBuild
///
///
technique CartographicBuild
<
    int renderStage = 0;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 CartographicVS();
        PixelShader = compile ps_2_0 CartographicBuildPS();
    }
}

/// CartographicShield
///
///
technique CartographicShield
<
    int renderStage = 0;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        ColorWriteEnable = 0x07;

        AlphaBlendEnable = true;
        SrcBlend = SrcAlpha;
        DestBlend = InvSrcAlpha;

        ZEnable = true;
        ZWriteEnable = false;

        VertexShader = compile vs_1_1 CartographicVS();
        PixelShader = compile ps_2_0 CartographicShieldPS();
    }
}

/// Flat
///
///
technique Flat
<
    string depthTechnique = "DepthClip";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x7F;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 FlatVS();
        PixelShader = compile ps_2_0 FlatPS( true, d3d_Greater, 0x7F );
    }
}

/// VertexNormal
///
///
technique VertexNormal_HighFidelity
<
    int fidelity = FIDELITY_HIGH;

    string abstractTechnique = "VertexNormal";
    string cartographicTechnique = "CartographicFeature";
    string depthTechnique = "DepthClip";

    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaFunc = Greater;
        AlphaRef = 0x23;
#endif

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_a VertexNormalPS_HighFidelity(true, true, d3d_Greater, 0x23 );
    }
}

technique VertexNormal_MedFidelity
<
    int fidelity = FIDELITY_MEDIUM;

    string abstractTechnique = "VertexNormal";
    string cartographicTechnique = "CartographicFeature";
    string depthTechnique = "DepthClip";

    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaFunc = Greater;
        AlphaRef = 0x23;
#endif

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 VertexNormalPS_HighFidelity(false, true, d3d_Greater, 0x23 );
    }
}

technique VertexNormal_LowFidelity
<
    int fidelity = FIDELITY_LOW;

    string abstractTechnique = "VertexNormal";
    string cartographicTechnique = "CartographicFeature";
    string depthTechnique = "DepthClip";

    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x23;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 VertexNormalPS_LowFidelity( true, d3d_Greater, 0x23 );
    }
}

/// NormalMappedAlpha
///
///
technique NormalMappedAlpha_HighFidelity
<
    int fidelity = FIDELITY_HIGH;

    string abstractTechnique = "NormalMappedAlpha";
    string cartographicTechnique = "CartographicFeature";
    string depthTechnique = "DepthClip";

    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x80;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NormalMappedPS(false,false,true,  true, d3d_Greater, 0x80 );
    }
}

technique NormalMappedAlpha_MedFidelity
<
    int fidelity = FIDELITY_MEDIUM;

    string abstractTechnique = "NormalMappedAlpha";
    string cartographicTechnique = "CartographicFeature";
    string depthTechnique = "DepthClip";

    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x80;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NormalMappedPS(false,false,false,  true, d3d_Greater, 0x80 );
    }
}

technique NormalMappedAlpha_LowFidelity
<
    int fidelity = FIDELITY_LOW;

    string abstractTechnique = "NormalMappedAlpha";
    string cartographicTechnique = "CartographicFeature";
    string depthTechnique = "DepthClip";

    int renderStage = STAGE_DEPTH + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x80;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 VertexNormalPS_LowFidelity( true, d3d_Greater, 0x80 );
    }
}

/// NormalMappedAlphaNoShadow
///
///
technique NormalMappedAlphaNoShadow_HighFidelity
<
    int fidelity = FIDELITY_HIGH;

    string abstractTechnique = "NormalMappedAlphaNoShadow";
    string cartographicTechnique = "CartographicFeature";
    string depthTechnique = "DepthClip";

    int renderStage = STAGE_REFLECTION + STAGE_POSTWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x80;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NormalMappedPS(false,false,true,  true, d3d_Greater, 0x80 );
    }
}

technique NormalMappedAlphaNoShadow_MedFidelity
<
    int fidelity = FIDELITY_MEDIUM;

    string abstractTechnique = "NormalMappedAlphaNoShadow";
    string cartographicTechnique = "CartographicFeature";
    string depthTechnique = "DepthClip";

    int renderStage = STAGE_REFLECTION + STAGE_POSTWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x80;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NormalMappedPS(false,false,false,  true, d3d_Greater, 0x80 );
    }
}

technique NormalMappedAlphaNoShadow_LowFidelity
<
    int fidelity = FIDELITY_LOW;

    string abstractTechnique = "NormalMappedAlphaNoShadow";
    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "DepthClip";

    int renderStage = STAGE_POSTWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x80;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 VertexNormalPS_LowFidelity( true, d3d_Greater, 0x80 );
    }
}


/// UndulatingNormalMappedAlpha
///
/// Normal mapped with alpha test.  No color mask or glow.
technique UndulatingNormalMappedAlpha_HighFidelity
<
    int fidelity = FIDELITY_HIGH;

    string abstractTechnique = "UndulatingNormalMappedAlpha";
    string cartographicTechnique = "CartographicFeature";
    string depthTechnique = "UndulatingDepthClip";

    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x80;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 UndulatingNormalMappedVS();
        PixelShader = compile ps_2_a NormalMappedPS(false,false,true,  true, d3d_Greater, 0x80 );
    }
}

technique UndulatingNormalMappedAlpha_MedFidelity
<
    int fidelity = FIDELITY_MEDIUM;

    string abstractTechnique = "UndulatingNormalMappedAlpha";
    string cartographicTechnique = "CartographicFeature";
    string depthTechnique = "UndulatingDepthClip";

    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x80;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 UndulatingNormalMappedVS();
        PixelShader = compile ps_2_a NormalMappedPS(false,false,false,  true, d3d_Greater, 0x80 );
    }
}

technique UndulatingNormalMappedAlpha_LowFidelity
<
    int fidelity = FIDELITY_LOW;

    string abstractTechnique = "UndulatingNormalMappedAlpha";
    string cartographicTechnique = "CartographicFeature";
    string depthTechnique = "UndulatingDepthClip";

    int renderStage = STAGE_DEPTH + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x80;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 VertexNormalPS_LowFidelity( true, d3d_Greater, 0x80 );
    }
}

/// BloatingNormalMappedAlpha
///
///
technique BloatingNormalMappedAlpha_HighFidelity
<
    int fidelity = FIDELITY_HIGH;

    string abstractTechnique = "BloatingNormalMappedAlpha";
    string cartographicTechnique = "CartographicFeature";
    string depthTechnique = "UndulatingDepthClip";

    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_POSTWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x80;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 BloatingNormalMappedVS();
        PixelShader = compile ps_2_a NormalMappedPS(false,false,true,  true, d3d_Greater, 0x80 );
    }
}

technique BloatingNormalMappedAlpha_MedFidelity
<
    int fidelity = FIDELITY_MEDIUM;

    string abstractTechnique = "BloatingNormalMappedAlpha";
    string cartographicTechnique = "CartographicFeature";
    string depthTechnique = "UndulatingDepthClip";

    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_POSTWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x80;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 BloatingNormalMappedVS();
        PixelShader = compile ps_2_a NormalMappedPS(false,false,false,  true, d3d_Greater, 0x80 );
    }
}

technique BloatingNormalMappedAlpha_LowFidelity
<
    int fidelity = FIDELITY_LOW;

    string abstractTechnique = "BloatingNormalMappedAlpha";
    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "UndulatingDepthClip";

    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_POSTWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x80;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 BloatingVertexNormalVS();
        PixelShader = compile ps_2_0 VertexNormalPS_LowFidelity( true, d3d_Greater, 0x80 );
    }
}

/// BlackenedNormalMappedAlpha
///
/// Blackened normal mapped with alpha test.  No color mask or glow.
technique BlackenedNormalMappedAlpha_HighFidelity
<
    int fidelity = FIDELITY_HIGH;

    string abstractTechnique = "BlackenedNormalMappedAlpha";
    string cartographicTechnique = "CartographicFeature";
    string depthTechnique = "DepthClip";

    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_POSTWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x80;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a BlackenedNormalMappedPS(false,false,true,  true, d3d_Greater, 0x80 );
    }
}

technique BlackenedNormalMappedAlpha_MedFidelity
<
    int fidelity = FIDELITY_MEDIUM;

    string abstractTechnique = "BlackenedNormalMappedAlpha";
    string cartographicTechnique = "CartographicFeature";
    string depthTechnique = "DepthClip";

    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_POSTWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x80;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_0 BlackenedNormalMappedPS(false,false,false,  true, d3d_Greater, 0x80 );
    }
}

technique BlackenedNormalMappedAlpha_LowFidelity
<
    int fidelity = FIDELITY_LOW;

    string abstractTechnique = "BlackenedNormalMappedAlpha";
    string cartographicTechnique = "CartographicFeature";
    string depthTechnique = "DepthClip";

    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_POSTWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x80;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 BlackenedLoFiPS( true, d3d_Greater, 0x80 );
    }
}

/// NormalMappedGlow
///
/// Normal mapped with glow.  No color mask or alpha.
technique NormalMappedGlow_HighFidelity
<
    int fidelity = FIDELITY_HIGH;

    string abstractTechnique = "NormalMappedGlow";
    string cartographicTechnique = "CartographicFeature";
    string depthTechnique = "Depth";

    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = false;
#endif

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NormalMappedPS(false,true,true, false,0,0 );
    }
}

/// MapImager
///
///
technique MapImager_LowFi
<
    string abstractTechnique = "MapImager";
    int fidelity = FIDELITY_LOW;

    int renderStage = STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_0 MapImagerPS0();
    }
    pass P1
    {
        AlphaState( AlphaBlend_Disable_Write_A )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_0 MapImagerPS1();
    }
}

technique NormalMappedGlow_MedFidelity
<
    string abstractTechnique = "NormalMappedGlow";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicFeature";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = false;
#endif

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NormalMappedPS(false,true,false, false,0,0 );
    }
}

technique NormalMappedGlow_LowFidelity
<
    string abstractTechnique = "NormalMappedGlow";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicFeature";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = false;
#endif

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 VertexNormalPS_LowFidelity(false,0,0);
    }
}

/// Clutter
///
///
technique Clutter
<
    int renderStage = STAGE_POSTWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable_Less )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x70;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 ClutterVS();
        PixelShader = compile ps_2_0 ClutterPS( true, d3d_Greater, 0x03 );
    }
}

/// Clutter
///
///
technique UnderwaterClutter
<
    int renderStage = STAGE_PREWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable_Less )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x70;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 ClutterVS();
        PixelShader = compile ps_2_0 ClutterPS( true, d3d_Greater, 0x70 );
    }
}

/// UndulatingClutter
///
///
technique UndulatingClutter
<
    int renderStage = STAGE_POSTWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable_Less )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x70;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 UndulatingClutterVS();
        PixelShader = compile ps_2_0 ClutterPS( true, d3d_Greater, 0x70 );
    }
}

/// UnderwaterUndulatingClutter
///
///
technique UnderwaterUndulatingClutter
<
    int renderStage = STAGE_PREWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable_Less )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x70;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 UndulatingClutterVS();
        PixelShader = compile ps_2_0 ClutterPS( true, d3d_Greater, 0x70 );
    }
}

/// NormalMappedTerrain
///
///
technique NormalMappedTerrain
<
    string depthTechnique = "Depth";
    string cartographicTechnique = "CartographicFeature";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable_Less )

#ifndef DIRECT3D10
        AlphaTestEnable = false;
#endif

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NormalMappedTerrainPS();
    }
}

/// Unit
///
/// Basic unit techniques.
technique Unit_HighFidelity
<
    string abstractTechnique = "Unit";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a PBR_UEF_PS(true,true,false,0,0 );
    }
}

technique Unit_MedFidelity
<
    string abstractTechnique = "Unit";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NormalMappedPS(true,true,true, false,0,0 );
    }
}

technique Unit_LowFidelity
<
    string abstractTechnique = "Unit";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 ColorMaskPS_LowFidelity();
    }
}

/// AlphaFade
///
///
technique AlphaFade_HighFidelity
<
    string abstractTechnique = "AlphaFade";
    int fidelity = FIDELITY_HIGH;

    int renderStage = STAGE_POSTWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable_Less )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x23;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_a AlphaFadePS( 2.0, 0.145, true,  true, d3d_Greater, 0x23 );
    }
}

technique AlphaFade_MedFidelity
<
    string abstractTechnique = "AlphaFade";
    int fidelity = FIDELITY_MEDIUM;

    int renderStage = STAGE_POSTWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable_Less )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x23;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 AlphaFadePS( 2.0, 0.145, false,  true, d3d_Greater, 0x23 );
    }
}

technique AlphaFade_LowFidelity
<
    string abstractTechnique = "AlphaFade";
    int fidelity = FIDELITY_LOW;

    int renderStage = STAGE_POSTWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable_Less )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x23;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 AlphaFadeLoFiPS( 2.0, 0.145,  true, d3d_Greater, 0x23 );
    }
}

technique CommandFeedback
<
    string cartographicTechnique = "CartographicFeedback";

    int renderStage = STAGE_POSTWATER + STAGE_PREEFFECT;
    int parameter = PARAM_LIFETIME;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )    // if RGBA is written, then you get glow, just RGB is no glow
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Disable )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x23;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 CommandFeedbackVS(0.7);
        PixelShader = compile ps_2_0 CommandFeedbackPS0(true);
    }
}

technique RallyPoint
<
    string cartographicTechnique = "CartographicFeedback";

    int renderStage = STAGE_POSTWATER + STAGE_PREEFFECT;
    int parameter = PARAM_LIFETIME;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )    // if RGBA is written, then you get glow, just RGB is no glow
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Disable )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x23;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 CommandFeedbackVS(0.7);
        PixelShader = compile ps_2_0 CommandFeedbackPS0(false);
    }
}

technique FakeRingsNoDepth
<
    string cartographicTechnique = "CartographicFeedback";

    int renderStage = STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )    // if RGBA is written, then you get glow, just RGB is no glow
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Disable )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x23;
        AlphaFunc = Greater;
        ZEnable = false;
#endif

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_0 FakeRingsPS(false);
    }
}

technique FakeRings
<
    string cartographicTechnique = "CartographicFeedback";

    int renderStage = STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )    // if RGBA is written, then you get glow, just RGB is no glow
        RasterizerState( Rasterizer_Cull_CW )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x23;
#endif

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_0 FakeRingsPS(false);
    }
}

technique CommandFeedback2
<
    string cartographicTechnique = "CartographicFeedback";

    int renderStage = STAGE_POSTWATER + STAGE_PREEFFECT;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )    // if RGBA is written, then you get glow, just RGB is no glow
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Disable )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x23;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 CommandFeedbackVS(1.1);
        PixelShader = compile ps_2_0 CommandFeedbackPS0(true);
    }
}

technique CommandFeedback3
<
    string cartographicTechnique = "CartographicFeedback";

    int renderStage = STAGE_POSTWATER + STAGE_PREEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Disable )

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 CommandFeedbackPS0(false);
    }
}

technique CommandFeedback4
<
    string cartographicTechnique = "CartographicFeedback";

    int renderStage = STAGE_POSTWATER + STAGE_PREEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable_LessEqual_Write_None )

        DepthBias = -0.0001;

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 CommandFeedbackPS0(false);
    }
}

/// UnitPlace
///
///
technique UnitPlace_LowFidelity
<
    int fidelity = FIDELITY_LOW;

    string abstractTechnique = "UnitPlace";
    string cartographicTechnique = "CartographicPlace";
    int renderStage = STAGE_POSTWATER + STAGE_POSTEFFECT;

    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable_Less )

        VertexShader = compile vs_1_1 PositionNormalOffsetVS(0.05);
        PixelShader = compile ps_2_0 UnitPlacePS();
    }

}

/// UnitFormationPreview
///
///
technique UnitFormationPreview_LowFidelity
<
    string abstractTechnique = "UnitFormationPreview";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicPlace";
    int renderStage = STAGE_POSTWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable_Less )

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 UnitPlacePS(); // Just use UnitPlace for now
    }
}

/// Metal
///
///
technique Metal_HighFidelity
<
    string abstractTechnique = "Metal";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NormalMappedMetalPS(true);
    }
}

technique Metal_MedFidelity
<
    string abstractTechnique = "Metal";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_0 NormalMappedMetalPS(false);
    }
}

technique Metal_LowFidelity
<
    string abstractTechnique = "Metal";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 ColorMaskPS_LowFidelity();
    }
}

/// Insect
///
///
technique Insect_HighFidelity
<
    string abstractTechnique = "Insect";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a PBR_CybranPS(true);
    }
}

technique Insect_MedFidelity
<
    string abstractTechnique = "Insect";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        //PixelShader = compile ps_2_0 NormalMappedInsectPS(false);
        PixelShader = compile ps_2_a NormalMappedInsectPS(true);
    }
}

technique Insect_LowFidelity
<
    string abstractTechnique = "Insect";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 ColorMaskPS_LowFidelity();
    }
}

/// Aeon
///
///
technique Aeon_HighFidelity
<
    string abstractTechnique = "Aeon";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a PBR_AeonPS(true);
    }
}

technique Aeon_MedFidelity
<
    string abstractTechnique = "Aeon";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a AeonPS(true);
    }
}

technique Aeon_LowFidelity
<
    string abstractTechnique = "Aeon";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 ColorMaskPS_LowFidelity();
    }
}

/// Seraphim
///
///
technique Seraphim_HighFidelity
<
    string abstractTechnique = "Seraphim";
    int fidelity = FIDELITY_HIGH;


    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";

    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 UnitFalloffVS();
        PixelShader = compile ps_2_a PBR_SeraphimPS(true);
    }
}

technique Seraphim_MedFidelity
<
    string abstractTechnique = "Seraphim";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";

    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;

    string environment = "<seraphim>";
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 UnitFalloffVS();
        PixelShader = compile ps_2_0 UnitFalloffPS(false);
    }
}

technique Seraphim_LowFidelity
<
    string abstractTechnique = "Seraphim";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";

    string environment = "<seraphim>";

    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_0 LowFiUnitFalloffPS();
    }
}


/// AeonCZAR
///
///
technique AeonCZAR_HighFidelity
<
    string abstractTechnique = "AeonCZAR";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a PBR_AeonCZARPS(true);
    }
}

technique AeonCZAR_MedFidelity
<
    string abstractTechnique = "AeonCZAR";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_0 AeonPS(false);
    }
}

technique AeonCZAR_LowFidelity
<
    string abstractTechnique = "AeonCZAR";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 ColorMaskPS_LowFidelity();
    }
}


// The navy variants are supposed to use a mirrored environment
// texture to emulate the water surface reflecting the sky.
technique UEFNavy_HighFidelity
<
    string abstractTechnique = "UEFNavy";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;

    string environment = "<water>";
>
{
    pass P0
    {
        RasterizerState(Rasterizer_Cull_CW)

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a PBR_UEF_PS(true, true, false, 0, 0);
    }
}

technique UEFNavy_MedFidelity
<
    string abstractTechnique = "UEFNavy";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
    
    string environment = "<water>";
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NormalMappedPS(true,true,true, false,0,0 );
    }
}

technique UEFNavy_LowFidelity
<
    string abstractTechnique = "UEFNavy";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
    
    string environment = "<water>";
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 ColorMaskPS_LowFidelity();
    }
}

technique CybranNavy_HighFidelity
<
    string abstractTechnique = "CybranNavy";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;

    string environment = "<water>";
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a PBR_CybranPS(true);
    }
}

technique CybranNavy_MedFidelity
<
    string abstractTechnique = "CybranNavy";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;

    string environment = "<water>";
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NormalMappedInsectPS(true);
    }
}

technique CybranNavy_LowFidelity
<
    string abstractTechnique = "CybranNavy";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;

    string environment = "<water>";
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 ColorMaskPS_LowFidelity();
    }
}

technique AeonNavy_HighFidelity
<
    string abstractTechnique = "AeonNavy";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
        
    string environment = "<water>";
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a PBR_AeonPS(true);
    }
}

technique AeonNavy_MedFidelity
<
    string abstractTechnique = "AeonNavy";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
            
    string environment = "<water>";
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a AeonPS(true);
    }
}

technique AeonNavy_LowFidelity
<
    string abstractTechnique = "AeonNavy";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
            
    string environment = "<water>";
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 ColorMaskPS_LowFidelity();
    }
}

technique SeraphimNavy_HighFidelity
<
    string abstractTechnique = "SeraphimNavy";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";

    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
            
    string environment = "<water>";
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 UnitFalloffVS();
        PixelShader = compile ps_2_a PBR_SeraphimPS(true);
    }
}

technique SeraphimNavy_MedFidelity
<
    string abstractTechnique = "SeraphimNavy";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";

    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;

    string environment = "<water>";
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 UnitFalloffVS();
        PixelShader = compile ps_2_0 UnitFalloffPS(false);
    }
}

technique SeraphimNavy_LowFidelity
<
    string abstractTechnique = "SeraphimNavy";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";

    string environment = "<water>";

    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_0 LowFiUnitFalloffPS();
    }
}

/// AeonBuild
///
///
technique AeonBuild_HighFidelity
<
    string abstractTechnique = "AeonBuild";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicBuild";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )
        AlphaState( AlphaBlend_Disable_Write_RGB )

        VertexShader = compile vs_1_1 AeonBuildVS(0.0);
        PixelShader = compile ps_2_a PBR_AeonBuildPS(true);
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 AeonBuildVS(0);
        PixelShader = compile ps_2_a PBR_AeonBuildOverlayPS();
    }
}

technique AeonBuild_MedFidelity
<
    string abstractTechnique = "AeonBuild";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicBuild";
    int renderStage = STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )
        AlphaState( AlphaBlend_Disable_Write_RGB )

        VertexShader = compile vs_1_1 AeonBuildVS(0.0);
        PixelShader = compile ps_2_a AeonBuildPS(false);
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 AeonBuildVS(0);
        PixelShader = compile ps_2_0 AeonBuildOverlayPS();
    }
}

technique AeonBuild_LowFidelity
<
    string abstractTechnique = "AeonBuild";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicBuild";
    int renderStage = STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 AeonBuildLoFiVS(1,1,0,0,0,0);
        PixelShader = compile ps_2_0 ColorMaskPS_LowFidelity();
    }
}


/// AeonBuildNoAnimation
///
///
technique AeonBuildNoAnimation_HighFidelity
<
    string abstractTechnique = "AeonBuildNoAnimation";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicBuild";
    int renderStage = STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )
        AlphaState( AlphaBlend_Disable_Write_RGB )

        VertexShader = compile vs_1_1 AeonBuildNoAnimationVS();
        PixelShader = compile ps_2_a AeonBuildPS(true);
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 AeonBuildNoAnimationVS();
        PixelShader = compile ps_2_0 AeonBuildOverlayPS();
    }
}

technique AeonBuildNoAnimation_MedFidelity
<
    string abstractTechnique = "AeonBuildNoAnimation";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicBuild";
    int renderStage = STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )
        AlphaState( AlphaBlend_Disable_Write_RGB )

        VertexShader = compile vs_1_1 AeonBuildNoAnimationVS();
        PixelShader = compile ps_2_a AeonBuildPS(false);
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 AeonBuildNoAnimationVS();
        PixelShader = compile ps_2_0 AeonBuildOverlayPS();
    }
}

technique AeonBuildNoAnimation_LowFidelity
<
    string abstractTechnique = "AeonBuildNoAnimation";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicBuild";
    int renderStage = STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 AeonBuildNoAnimationLoFiVS(1,1,0,0,0,0);
        PixelShader = compile ps_2_0 ColorMaskPS_LowFidelity();
    }
}

/// AeonBuildPuddle
///
///
technique AeonBuildPuddle_HighFidelity
<
    string abstractTechnique = "AeonBuildPuddle";
    int fidelity = FIDELITY_HIGH;

    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a PBR_AeonBuildPuddlePS(true);
    }
}

technique AeonBuildPuddle_MedFidelity
<
    string abstractTechnique = "AeonBuildPuddle";
    int fidelity = FIDELITY_MEDIUM;

    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_0 AeonBuildPuddlePS(false);
    }
}

technique AeonBuildPuddle_LowFidelity
<
    string abstractTechnique = "AeonBuildPuddle";
    int fidelity = FIDELITY_LOW;

    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 EffectVertexNormalLoFiVS( 1, 1, -0.002, 0.0042, 0, 0 );
        PixelShader = compile ps_2_0 AeonBuildPuddleLoFiPS();
    }
}

/// CybranBuild
///
///
technique CybranBuild_HighFidelity
<
    string abstractTechnique = "CybranBuild";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicBuild";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a PBR_CybranBuildPS(true);
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 EffectVertexNormalLoFiVS( 14, 4, 0, 0, -0.008, 0.008 );
        PixelShader = compile ps_2_0 CybranBuildOverlayPS();
    }
}

technique CybranBuild_MedFidelity
<
    string abstractTechnique = "CybranBuild";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicBuild";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_0 CybranBuildPS(false);
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 EffectVertexNormalLoFiVS( 14, 4, 0, 0, -0.008, 0.008 );
        PixelShader = compile ps_2_0 CybranBuildOverlayPS();
    }
}

technique CybranBuild_LowFidelity
<
    string abstractTechnique = "CybranBuild";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicBuild";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 CybranBuildLoFiPS();
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )

        VertexShader = compile vs_1_1 EffectVertexNormalLoFiVS( 14, 4, 0, 0, -0.008, 0.008 );
        PixelShader = compile ps_2_0 CybranBuildOverlayPS();
    }
}

/// Seraphim Build
///
///
technique SeraphimBuild_HighFidelity
<
    string abstractTechnique = "SeraphimBuild";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicBuild";
    string depthTechnique = "SeraphimBuildDepth";

    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 SeraphimBuildVS();
        PixelShader = compile ps_2_a PBR_SeraphimBuildPS(true);
    }
}

technique SeraphimBuild_MedFidelity
<
    string abstractTechnique = "SeraphimBuild";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicBuild";
    string depthTechnique = "SeraphimBuildDepth";

    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 SeraphimBuildVS();
        PixelShader = compile ps_2_a SeraphimBuildPS(true);
    }
}

technique SeraphimBuild_LowFidelity
<
    string abstractTechnique = "SeraphimBuild";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicBuild";
    string depthTechnique = "SeraphimBuildDepth";

    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 SeraphimBuildLofiVS();
        PixelShader = compile ps_2_0 CybranBuildLoFiPS();
    }
}

/// UEFBuild
///
///
technique UEFBuild_HighFidelity
<
    string abstractTechnique = "UEFBuild";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicBuild";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a PBR_UEFBuildPS(true);
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 EffectVertexNormalHiFiVS( 16.0, 8.0, 0.0192, 0.0176, -0.0122, -0.0122 );
        PixelShader = compile ps_2_0 UEFBuildOverlayHiFiPS();
    }
}

technique UEFBuild_MedFidelity
<
    string abstractTechnique = "UEFBuild";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicBuild";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_0 UEFBuildHiFiPS(false);
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 EffectVertexNormalHiFiVS( 16.0, 8.0, 0.0192, 0.0176, -0.0122, -0.0122 );
        PixelShader = compile ps_2_0 UEFBuildOverlayHiFiPS();
    }
}

technique UEFBuild_LowFidelity
<
    string abstractTechnique = "UEFBuild";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicBuild";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 UEFBuildLoFiPS();
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 EffectVertexNormalLoFiVS( 16, 8, 0.0192, 0.0176, -0.05, -0.05 );
        PixelShader = compile ps_2_0 UEFBuildOverlayLoFiPS();
    }
}



/// UEFBuildCube
///
///
technique UEFBuildCube_MedFidelity
<
    string abstractTechnique = "UEFBuildCube";
    int fidelity = FIDELITY_MEDIUM;

    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable_LessEqual_Write_None )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_0 UEFBuildCubePS();
    }
}

technique UEFBuildCube_LowFidelity
<
    string abstractTechnique = "UEFBuildCube";
    int fidelity = FIDELITY_LOW;

    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 EffectVertexNormalLoFiVS( 0.025, 50, 0.0012, 0.0062, -0.25, -0.0062);
        PixelShader = compile ps_2_0 UEFBuildCubeLoFiPS();
    }
}

/// Wreckage
///
///
technique Wreckage_MedFidelity
<
    string abstractTechnique = "Wreckage";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicFeature";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_2_0 WreckageVS_HighFidelity();
        PixelShader = compile ps_2_0 WreckagePS();
    }
};

technique Wreckage_LowFidelity
<
    string abstractTechnique = "Wreckage";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicFeature";
    int renderStage = STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 WreckageVS_LowFidelity();
        PixelShader = compile ps_2_0 WreckagePS_LowFidelity();
    }
};

technique UnitStunned_HighFidelity
<
    string abstractTechnique = "UnitStunned";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a PBR_UEF_PS(true,true, false,0,0 );
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a StunnedUnit();
    }
}

technique UnitStunned_MedFidelity
<
    string abstractTechnique = "UnitStunned";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NormalMappedPS(true,true,false, false,0,0 );
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a StunnedUnit();
    }
}

technique UnitStunned_LowFidelity
<
    string abstractTechnique = "UnitStunned";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 ColorMaskPS_LowFidelity();
    }
}

technique InsectStunned_HighFidelity
<
    string abstractTechnique = "InsectStunned";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a PBR_CybranPS(true);
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a StunnedUnit();
    }
}

technique InsectStunned_MedFidelity
<
    string abstractTechnique = "InsectStunned";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_0 NormalMappedInsectPS(false);
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a StunnedUnit();
    }
}

technique InsectStunned_LowFidelity
<
    string abstractTechnique = "InsectStunned";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 ColorMaskPS_LowFidelity();
    }
}

technique AeonStunned_HighFidelity
<
    string abstractTechnique = "AeonStunned";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a PBR_AeonPS(true);
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a StunnedUnit();
    }
}

technique AeonStunned_MedFidelity
<
    string abstractTechnique = "AeonStunned";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_0 AeonPS(false);
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a StunnedUnit();
    }
}

technique AeonStunned_LowFidelity
<
    string abstractTechnique = "AeonStunned";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 ColorMaskPS_LowFidelity();
    }
}

/// Seraphim
///
///
technique SeraphimStunned_HighFidelity
<
    string abstractTechnique = "SeraphimStunned";
    int fidelity = FIDELITY_HIGH;


    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";

    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 UnitFalloffVS();
        PixelShader = compile ps_2_a PBR_SeraphimPS(true);
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a StunnedUnit();
    }
}

technique SeraphimStunned_MedFidelity
<
    string abstractTechnique = "SeraphimStunned";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";

    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;

    string environment = "<seraphim>";
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 UnitFalloffVS();
        PixelShader = compile ps_2_0 UnitFalloffPS(false);
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a StunnedUnit();
    }
}

technique SeraphimStunned_LowFidelity
<
    string abstractTechnique = "SeraphimStunned";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";

    string environment = "<seraphim>";

    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_0 LowFiUnitFalloffPS();
    }
}

/// Personal Shields
///
///
technique PhaseShield_HighFidelity
<
    string abstractTechnique = "PhaseShield";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicShield";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a PBR_UEF_PS(true, true, false, 0, 0);
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 PositionNormalOffsetVS(0.02);
        PixelShader = compile ps_2_0 PhaseShieldPS();
    }
}

technique AeonPhaseShield_HighFidelity
<
    string abstractTechnique = "AeonPhaseShield";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicShield";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a PBR_AeonPS(true);
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 PositionNormalOffsetVS(0.02);
        PixelShader = compile ps_2_0 AeonPhaseShieldPS();
    }
}

technique CybranPhaseShield_HighFidelity
<
    string abstractTechnique = "CybranPhaseShield";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicShield";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a PBR_CybranPS(true);
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 PositionNormalOffsetVS(0.02);
        PixelShader = compile ps_2_0 CybranPhaseShieldPS();
    }
}

technique SeraphimPersonalShield_HighFidelity
<
    string abstractTechnique = "SeraphimPersonalShield";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;

    int parameter = PARAM_LIFETIME;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 UnitFalloffVS();
        PixelShader = compile ps_2_a PBR_SeraphimPS(true);
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 PositionNormalOffsetVS(0.02);
        PixelShader = compile ps_2_0 SeraphimPhaseShieldPS();
    }
}

technique SeraphimPersonalShield_MedFidelity
<
    string abstractTechnique = "SeraphimPersonalShield";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;

    int parameter = PARAM_LIFETIME;

    string environment = "<seraphim>";
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 UnitFalloffVS();
        PixelShader = compile ps_2_a UnitFalloffPS(true);
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 PositionNormalOffsetVS(0.05);
        PixelShader = compile ps_2_0 SeraphimPhaseShieldPS();
    }
}

technique SeraphimPersonalShield_LowFidelity
<
    string abstractTechnique = "SeraphimPersonalShield";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;

    int parameter = PARAM_LIFETIME;

    string environment = "<seraphim>";
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_0 LowFiUnitFalloffPS();
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 PositionNormalOffsetVS(0.05);
        PixelShader = compile ps_2_0 PhaseShieldPS();
    }
}

technique PhaseShield_MedFidelity
<
    string abstractTechnique = "PhaseShield";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicShield";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NormalMappedPS(true,true,false, false,0,0 );
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 PositionNormalOffsetVS(0.05);
        PixelShader = compile ps_2_0 PhaseShieldPS();
    }
}

technique PhaseShield_LowFidelity
<
    string abstractTechnique = "PhaseShield";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicShield";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 ColorMaskPS_LowFidelity();
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 PositionNormalOffsetVS(0.05);
        PixelShader = compile ps_2_0 PhaseShieldPS();
    }
}

/// UEF Shield
///
///
technique ShieldUEF_MedFidelity
<
    string abstractTechnique = "ShieldUEF";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicShield";
    int renderStage = STAGE_POSTWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_FRACTIONHEALTH;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_None )
        DepthState( Depth_Enable_LessEqual_Write_None )

        VertexShader = compile vs_1_1 FourUVTexShiftScaleVS( 1, 3, 32, 6, 0, 0, 0.0003, 0.005, -0.001, -0.005, -0.0003, -0.0008 );
        PixelShader = compile ps_2_0 ShieldPS();
    }
}

technique ShieldUEF_LowFidelity
<
    string abstractTechnique = "ShieldUEF";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicShield";
    int renderStage = STAGE_POSTWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_FRACTIONHEALTH;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_None )
        DepthState( Depth_Enable_LessEqual_Write_None )

        VertexShader = compile vs_1_1 ThreeUVTexShiftScaleLoFiVS( 1, 3, 32, 0, 0, 0.0003, 0.005, -0.001, -0.005 );
        PixelShader = compile ps_2_0 ShieldLoFiPS();
    }
}

/// Cybran Shield
///
///
technique ShieldCybran_MedFidelity
<
    string abstractTechnique = "ShieldCybran";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicShield";
    int renderStage = STAGE_POSTWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_FRACTIONHEALTH;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_None )
        DepthState( Depth_Enable_LessEqual_Write_None )

        VertexShader = compile vs_1_1 FourUVTexShiftScaleVS( 1,1,2,1, -0.01,0, -0.002,0, 0,0.0012, 0.001,-0.0015 );
        PixelShader = compile ps_2_0 ShieldCybranPS(0.17);
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        DepthState( Depth_Enable_LessEqual_Write_None )
        RasterizerState( Rasterizer_Cull_None )

        VertexShader = compile vs_1_1 ShieldPositionNormalOffsetVS( 0.01, 1,1,4,1, 0.01,0, -0.002,0, 0,0.0012, 0.001,-0.003 );
        PixelShader = compile ps_2_0 ShieldCybranPS(0.17);
    }
}

technique ShieldCybran_LowFidelity
<
    string abstractTechnique = "ShieldCybran";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicShield";
    int renderStage = STAGE_POSTWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_FRACTIONHEALTH;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_None )
        DepthState( Depth_Enable_LessEqual_Write_None )

        VertexShader = compile vs_1_1 ThreeUVTexShiftScaleLoFiVS( 1,2,1, 0,0, 0,0.002, 0.001,-0.003 );
        PixelShader = compile ps_2_0 ShieldCybranLoFiPS(0.24);
    }
}
/// Aeon Shield
///
///
technique ShieldAeon_MedFidelity
<
    string abstractTechnique = "ShieldAeon";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicShield";
    int renderStage = STAGE_REFLECTION + STAGE_POSTWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_FRACTIONHEALTH;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_None )
        DepthState( Depth_Enable_LessEqual_Write_None )

        VertexShader = compile vs_1_1 ShieldNormalVS( 1,12,8,3, 0,0, 0,0.032, 0.012,-0.032, 0,0.0012 );
        PixelShader = compile ps_2_0 ShieldAeonPS();
    }
}

technique ShieldAeon_LowFidelity
<
    string abstractTechnique = "ShieldAeon";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicShield";
    int renderStage = STAGE_REFLECTION + STAGE_POSTWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_FRACTIONHEALTH;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_None )
        DepthState( Depth_Enable_LessEqual_Write_None )

        VertexShader = compile vs_1_1 ThreeUVTexShiftScaleLoFiVS( 1,12,8, 0,0, 0,0.032, 0.012,-0.032 );
        PixelShader = compile ps_2_0 ShieldAeonLoFiPS( 0.5 );
    }
}

/// Seraphim Shield
///
///
technique ShieldSeraphim_MedFidelity
<
    string abstractTechnique = "ShieldSeraphim";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicShield";
    int renderStage = STAGE_REFLECTION + STAGE_POSTWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_FRACTIONHEALTH;

    string environment = "<seraphim>";
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_One_Write_RGB )

        RasterizerState( Rasterizer_Cull_None )
        DepthState( Depth_Enable_LessEqual_Write_None )

        VertexShader = compile vs_1_1 ShieldNormalVS(5,1,1,11, -0.00153,-0.0159, 0,0, 0.003,-0.0045, -0.005,-0.045 );
        PixelShader = compile ps_2_0 ShieldSeraphimPS();
    }
}

technique ShieldSeraphim_LowFidelity
<
    string abstractTechnique = "ShieldSeraphim";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicShield";
    int renderStage = STAGE_REFLECTION + STAGE_POSTWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_FRACTIONHEALTH;

    string environment = "<seraphim>";
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_One_Write_RGB )

        RasterizerState( Rasterizer_Cull_None )
        DepthState( Depth_Enable_LessEqual_Write_None )

        VertexShader = compile vs_1_1 ThreeUVTexShiftScaleLoFiVS( 1,12,8, 0,0, 0,0.032, 0.012,-0.032 );
        PixelShader = compile ps_2_0 ShieldAeonLoFiPS( 0.5 );
    }
}


/// ShieldDepthFill
///
///
technique ShieldFill
<
    int renderStage = STAGE_POSTWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_FRACTIONHEALTH;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_None )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )

#ifndef DIRECT3D10
        AlphaTestEnable = false;
#endif

        VertexShader = compile vs_1_1 FlatVS();
        PixelShader = compile ps_2_0 ShieldFillPS();
    }
}

technique ShieldImpact
<
    int renderStage = STAGE_POSTWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_One_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable_LessEqual_Write_None )

        VertexShader = compile vs_1_1 ShieldImpactVS( -0.003, -0.1, -0.085 , -0.15 , 0.25, 0, 0, 0.0, 2.0 );
        PixelShader = compile ps_2_0 ShieldImpactPS( 2.0, 0.2 );
    }
}

technique CybranShieldImpact
<
    int renderStage = STAGE_POSTWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_None )
        DepthState( Depth_Enable_LessEqual_Write_None )

        VertexShader = compile vs_1_1 ShieldImpactVS( 0, 0, 0, 0, 1, -0.003, -0.06, -0.01, 1 );
        PixelShader = compile ps_2_0 CybranShieldImpactPS( 6.0, 0.15, 4.5 );
    }
}


///  Effect
///
///
technique Effect
<
    string depthTechnique = "DepthClip";
    int renderStage = STAGE_POSTWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 EffectVS();
        PixelShader = compile ps_2_0 EffectPS();
    }
}


/// Explosion
///
///
technique Explosion
<
    int renderStage = STAGE_POSTWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable_Less )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x40;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 EffectVS();
        PixelShader = compile ps_2_0 ExplosionPS( true, d3d_Greater, 0x40 );
    }
}

/// Cloud
///
///
technique Cloud_HighFidelity
<
    string abstractTechnique = "Cloud";
    int fidelity = FIDELITY_HIGH;

    int renderStage = STAGE_POSTWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        DepthState( Depth_Enable )
        RasterizerState( Rasterizer_Cull_CW )

#ifndef DIRECT3D10
        AlphaTestEnable = false;
#endif

        VertexShader = compile vs_1_1 EffectVS();
        PixelShader = compile ps_2_a EffectFadePS( 180.0, 0.025, true);
    }
}

technique Cloud_MedFidelity
<
    string abstractTechnique = "Cloud";
    int fidelity = FIDELITY_MEDIUM;

    int renderStage = STAGE_POSTWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        DepthState( Depth_Enable )
        RasterizerState( Rasterizer_Cull_CW )

#ifndef DIRECT3D10
        AlphaTestEnable = false;
#endif

        VertexShader = compile vs_1_1 EffectVS();
        PixelShader = compile ps_2_0 EffectFadePS( 180.0, 0.025, false);
    }
}

technique Cloud_LowFidelity
<
    string abstractTechnique = "Cloud";
    int fidelity = FIDELITY_LOW;

    int renderStage = STAGE_POSTWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        DepthState( Depth_Enable )
        RasterizerState( Rasterizer_Cull_CW )

#ifndef DIRECT3D10
        AlphaTestEnable = false;
#endif

        VertexShader = compile vs_1_1 EffectVS();
        PixelShader = compile ps_2_0 EffectFadePS( 180.0, 0.025, false);
    }
}

/// OuterCloud
///
///
technique OuterCloud
<
    int renderStage = STAGE_POSTWATER + STAGE_PREEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        DepthState( Depth_Enable_Less_Write_None )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 EffectVS();
        PixelShader = compile ps_2_0 AlphaFadeTexShiftScalePS( 1.0, -0.008, 180.0, 0.025);
    }
}

/// NukeUEF
///
///
technique NukeUEF
<
  //  string depthTechnique = "Depth";
    int renderStage =  STAGE_POSTWATER + STAGE_PREEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        DepthState( Depth_Enable )
        RasterizerState( Rasterizer_Cull_CW )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0x0F;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 EffectVS();
        PixelShader = compile ps_2_0 NukeHeadPS( 1.0, 0.018, 50.0, 0.015,  true, d3d_Greater, 0x0F );
    }
}

/// NukeEMP
///
///
technique NukeEMP
<
    int renderStage = STAGE_POSTWATER + STAGE_PREEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        DepthState( Depth_Enable_Less_Write_None )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 EffectVS();
        PixelShader = compile ps_2_0 AlphaFadeTexShiftScalePS( 1.0, -0.008, 180.0, 0.025);
    }
}

/// NukeQuantum
///
///
technique NukeQuantum
<
    int renderStage = STAGE_POSTWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RBA )
        DepthState( Depth_Enable_Less_Write_None )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 EffectVS();
        PixelShader = compile ps_2_0 AlphaFadeTexShiftScalePS( 0.5, -0.006, 150.0, 0.025);
    }
}

technique PhalanxEffect
<
    int renderStage = STAGE_POSTWATER + STAGE_PREEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_One_InvSrcAlpha_Write_RGBA )
        DepthState( Depth_Enable_Less_Write_None )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 EffectVertexNormalLoFiVS( 1, 1, -0.05, 0, -0.05, -0.025 );
        PixelShader = compile ps_2_0 TwoTexShiftScalePS( 0.2, 0.2 );
    }
}

technique UEFQuantumGate
<
    int renderStage = STAGE_POSTWATER + STAGE_PREEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        DepthState( Depth_Enable_Less_Write_None )
        RasterizerState( Rasterizer_Cull_None )

        VertexShader = compile vs_1_1 ThreeUVTexShiftScaleLoFiVS( 1, 4, 1, 0, 0.025, 0.025, 0.025, 0, 0 );
        PixelShader = compile ps_2_0 TexSubAlphaMaskStaticLoFiPS( 1, 0.4 );
    }
}

/// EditorMarker
///
///
technique EditorMarker
<
    int renderStage = STAGE_POSTWATER + STAGE_PREEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        DepthState( Depth_Enable )
        RasterizerState( Rasterizer_Cull_CW )

#ifndef DIRECT3D10
        AlphaTestEnable = false;
#endif

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 EditorMarkerPS();
    }
}

/// Glass shader
///
///
technique GlassAlpha_MedFidelity
<
    string abstractTechnique = "GlassAlpha";
    int fidelity = FIDELITY_MEDIUM;

    int renderStage = STAGE_POSTWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_FRACTIONHEALTH;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        DepthState( Depth_Enable_LessEqual_Write_None )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_0 GlassAlphaPS(false);
    }
}

technique GlassAlpha_LowFidelity
<
    string abstractTechnique = "GlassAlpha";
    int fidelity = FIDELITY_LOW;

    int renderStage = STAGE_POSTWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_FRACTIONHEALTH;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        DepthState( Depth_Enable_LessEqual_Write_None )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 GlassAlphaLoFiPS();
    }
}


//--------------------------------------------------------------------------------------
/////////////////////////     BEGIN CUSTOM FACTION SHADERS     /////////////////////////
//--------------------------------------------------------------------------------------


///////////////////////////////////////
///
/// Nomads
///
///////////////////////////////////////


// STRUCTS

struct NOMADSBUILD_VERTEX
{
    float4 position : POSITION0;
    float3 normal : TEXCOORD3;
    float3 tangent : TEXCOORD4;
    float3 binormal : TEXCOORD5;
    float4 texcoord0 : TEXCOORD0;
    float3 viewDirection : TEXCOORD6;
    float4 shadow : TEXCOORD2;
    float4 color : COLOR0;
    float4 material : TEXCOORD1;    /// various uses
    float3 screenPos : TEXCOORD7;
};

struct NOMADSBUILDMESH_VERTEX
{
    float4 position : POSITION0;
    float3 normal : TEXCOORD3;
    float3 tangent : TEXCOORD4;
    float3 binormal : TEXCOORD5;
    float4 texcoord0 : TEXCOORD0;
    float3 viewDirection : TEXCOORD6;
    float4 shadow : TEXCOORD2;
    float4 color : COLOR0;
    float4 material : TEXCOORD1;    /// various uses
    float3 relativePos : TEXCOORD7;
};

// VERTEX SHADERS ---------------------------------------------------------------------------------------------

NOMADSBUILD_VERTEX NOMADSBuildVS(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float3 tangent : TANGENT0,
    float3 binormal : BINORMAL0,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0,
    float1 colorLookup : TEXCOORD7
)
{
    NOMADSBUILD_VERTEX vertex = (NOMADSBUILD_VERTEX)0;
    CompatSwizzle(color);

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);
    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.shadow = ComputeShadowTexcoord( vertex.position);

    vertex.viewDirection = -mul(viewMatrix, mul( vertex.position, viewMatrix));
    vertex.viewDirection = normalize(vertex.viewDirection);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));

    vertex.texcoord0 = ( anim.w > 0.5 ) ? ComputeScrolledTexcoord( texcoord0, material) : texcoord0;
    vertex.color = color;
    vertex.material = float4( time - material.x, material.yzw);

    float3x3 rotationMatrix = (float3x3)worldMatrix;
    vertex.normal = mul( normal, rotationMatrix);
    vertex.tangent = mul( tangent, rotationMatrix);
    vertex.binormal = mul( binormal, rotationMatrix);

    // An extra step to pass the screen position to the pixel shader
    vertex.screenPos = vertex.position.xyz / vertex.position.w;

    return vertex;
}

//like the above, but it passes a a mesh relative position instead of a screen position.
NOMADSBUILDMESH_VERTEX NOMADSBuildMeshVS(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float3 tangent : TANGENT0,
    float3 binormal : BINORMAL0,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0,
    float1 colorLookup : TEXCOORD7
)
{
    NOMADSBUILDMESH_VERTEX vertex = (NOMADSBUILDMESH_VERTEX)0;
    CompatSwizzle(color);

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);
    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.shadow = ComputeShadowTexcoord( vertex.position);

    vertex.viewDirection = -mul(viewMatrix, mul( vertex.position, viewMatrix));
    vertex.viewDirection = normalize(vertex.viewDirection);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));

    vertex.texcoord0 = ( anim.w > 0.5 ) ? ComputeScrolledTexcoord( texcoord0, material) : texcoord0;
    vertex.color = color;
    vertex.material = float4( time - material.x, material.yzw);

    float3x3 rotationMatrix = (float3x3)worldMatrix;
    vertex.normal = mul( normal, rotationMatrix);
    vertex.tangent = mul( tangent, rotationMatrix);
    vertex.binormal = mul( binormal, rotationMatrix);

    // We pass the vertex coordinates to the pixel shader, and have to normalize them to ensure that different size structures all work.
    vertex.relativePos = normalize( position.xyz);

    return vertex;
}

// SAMPLERS --------------------------------------------------------------------------------------------------

// This sampler is for sampling the nomads noise cube texture
sampler3D NoiseCubeSampler = sampler_state
{
    texture = (lookupTexture);
    AddressU = wrap;
    AddressV = wrap;
    AddressW = wrap;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

// PIXEL SHADERS ---------------------------------------------------------------------------------------------

// The factory build rect
float4 NomadsFactoryBuildHologramPS( NOMADSBUILD_VERTEX vertex ) : COLOR0
{
    // The holographic colour
    float3 holo = float3(1.0, 0.5, 0.0);
    float alpha = 0.22;

    return float4(holo, alpha);
}

//TODO: merge the two nomads build shaders together by using a bool.

// creates a build-band hologram that reveals the unit
float4 NomadsBuildHologramPS( NOMADSBUILDMESH_VERTEX vertex,
                    uniform bool FadeAlmostDone ) : COLOR0
{
    // The holographic colour
    float3 holo = float3(1.0, 0.5, 0.0);
    float alpha = 0.25;
    
    //Alpha channel creates a scanning band as the unit is being built.
    float height = 0.1 + vertex.material.y - vertex.relativePos.y;
    float band = 0.1 -(height * height * 30);  
    if (vertex.material.y < 0.9)
    {
        alpha = clamp(4 * band, 0, 1) + min(20 * height, 0.1) ; 
    }
    else if (FadeAlmostDone && vertex.material.y > 0.9)
    {
        alpha = alpha * (10 * (1 - vertex.material.y));
    }
    

    return float4(holo, alpha);
}

// creates a build-band hologram that reveals the unit. this one is for factories, where the banding is horizontal.
float4 NomadsBuildHologramUnitPS( NOMADSBUILDMESH_VERTEX vertex,
                    uniform bool FadeAlmostDone ) : COLOR0
{
    // The holographic colour
    float3 holo = float3(1.0, 0.5, 0.0);
    float alpha = 0.25;

    //Alpha channel creates a scanning band as the unit is being built.
    float height = 0.1 + 2*vertex.material.y - (1 - vertex.relativePos.z);
    float band = 0.1 -(height * height * 30);  
    if (vertex.material.y < 0.9)
    {
        alpha = clamp(4 * band, 0, 1) + min(20 * height, 0.1) ; 
    }
    else if (FadeAlmostDone && vertex.material.y > 0.9)
    {
        alpha = alpha * (10 * (1 - vertex.material.y));
    }
    

    return float4(holo, alpha);
}

// creates the noise effect
float4 NomadsBuildNoisePS( NOMADSBUILD_VERTEX vertex,
                    uniform bool FadeAlmostDone ) : COLOR0
{
    // The holographic colour
    float3 holo = float3(1.0f, 0.5f, 0.0f);

    // 3d noise
    float4 noisy = 1.0f;
    float noiselayer = ((vertex.material.x/4.0f) % 4.0f);
    float3 noisecoord = float3(vertex.screenPos.x*2.0f, vertex.screenPos.y*2.0f, noiselayer);
    noisy *= tex3D(NoiseCubeSampler, noisecoord);

    //Alpha channel
    float alpha = 0.5f;
    if (vertex.material.y < 0.9)
    {
        alpha = alpha * (vertex.material.y / 0.5);
    }
    else if (FadeAlmostDone && vertex.material.y > 0.9)
    {
        alpha = alpha * (10 * (1 - vertex.material.y));
    }
    
    return float4(holo, alpha) * noisy;
}


// This applies texture fade in
float4 NomadsBuildPS( NORMALMAPPED_VERTEX vertex,
                     uniform bool hiDefShadows ) : COLOR0
{
    clip(vertex.material.y - 0.9f);
    // Calc normals
    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal);
    float3 normal = ComputeNormal( normalsSampler, vertex.texcoord0.zw, rotationMatrix);
    float dotLightNormal = dot(sunDirection,normal);

    // retrieve sampler values
    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.xy);
    float4 specular = tex2D( specularSampler, vertex.texcoord0.xy);
    float3 environment = texCUBE( environmentSampler, reflect( -vertex.viewDirection, normal));

    // teamcolour mask on the albedo
    albedo.rgb = lerp( vertex.color.rgb, albedo.rgb, 1 - specular.a );

    // Phong spec, reflection
    float phongAmount = saturate( dot( reflect( sunDirection, normal), -vertex.viewDirection));
    float3 phongAdditive = NormalMappedPhongCoeff * pow( phongAmount, 2) * specular.g;
    float3 phongMultiplicative = float3( 2 * environment * specular.r);

    // lighting
    float3 light = ComputeLight( dotLightNormal, ComputeShadow( vertex.shadow, hiDefShadows));

    // Combine albedo, lighting, phong
    float3 textured = albedo.rgb * ( light + phongMultiplicative) + phongAdditive;

    // The holographic colour with lighting
    float4 holo = float4(float3(1.0f, 0.5f, 0.0f) * light, 0.0f);

    //interpolate between holographic and normal textured unit

    // Start at 90% completion
    float interpolate = 0.0f;
    if (vertex.material.y > 0.9) {
        interpolate = 10*(vertex.material.y - 0.9);
    }

    float4 color = lerp(holo, float4(textured, 1.0f), interpolate);

    return color;
}

float4 NomadsNormalMappedPS( NORMALMAPPED_VERTEX vertex,
                       uniform bool maskAlbedo,
                       uniform bool glow,
                       uniform bool hiDefShadows,
                       uniform bool alphaTestEnable,
                       uniform int alphaFunc,
                       uniform int alphaRef ) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth.x);

    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal);
    float3 normal = ComputeNormal( normalsSampler, vertex.texcoord0.zw, rotationMatrix);
    float dotLightNormal = dot(sunDirection,normal);

    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.xy);
    float4 specular = tex2D( specularSampler, vertex.texcoord0.xy);
    float3 environment = texCUBE( environmentSampler, reflect( -vertex.viewDirection, normal));

    if ( maskAlbedo )
        albedo.rgb = lerp( vertex.color.rgb, albedo.rgb, 1 - specular.a );
    else
        albedo.rgb = albedo.rgb * vertex.color.rgb;

    float phongAmount = saturate( dot( reflect( sunDirection, normal), -vertex.viewDirection));
    float3 phongAdditive = NormalMappedPhongCoeff * pow( phongAmount, 2) * specular.g;
    float3 phongMultiplicative = float3( 2 * environment * specular.r);

    float3 light = ComputeLight( dotLightNormal, ComputeShadow( vertex.shadow, hiDefShadows));

    float emissive = glowMultiplier * specular.b;
    float3 color = albedo.rgb * ( emissive.r + light + phongMultiplicative) + phongAdditive;

    float alpha = mirrored ? 0.5 : ( glow ? ( specular.b + glowMinimum ) : ( vertex.material.g * albedo.a ));

#ifdef DIRECT3D10
    if( alphaTestEnable )
        AlphaTestD3D10( alpha, alphaFunc, alphaRef );
#endif

    //increasing the alpha creates more glow
    alpha = alpha * 1.5;

    //subtracting the alpha from the color cancels out the oversaturation created when the glowy parts of the frame are blurred and added to the frame
    color.rgb = color.rgb - (float3(alpha, alpha, alpha) * 0.4);

    return float4( color.rgb, alpha );
}

/// Nomads powered armor
///
float4 NomadsPowerArmorPS( VERTEXNORMAL_VERTEX vertex ) : COLOR
{
//    float4 color = float4( 1, 0.4, 0.18, 0.5);
    float4 color = float4( 0.4, 0.6, 0.18, 0.5);

    float2 tc = vertex.texcoord0.xy * 0.1; // duration, speed and size?
    tc.x -= 0.0015 * vertex.material.x * (2 - vertex.material.y); // speed
    tc.y = tc.y * 8;  // shape of the effects, squares -> lines

    float4 lookup = tex2D( lookupSampler, tc);
    float4 glowpulse = float4(lookup.ggg, min(lookup.g, 0.65) );

    // Adjust color of armor effect based on its health percentage, going to white-ish with low alpha channel
//    float4 colorMod1 = float4( color.r * 0.8, color.g * 2, color.b * 2.7, color.a * 0.4 );
    float4 colorMod1 = float4( color.r * 2, color.g * 1.333, color.b * 2.7, color.a * 0.4 );
    color = lerp( colorMod1, color, vertex.material.y );

    return color * glowpulse;
}

/// Nomads personal shield
///
float4 NomadsPhaseShieldPS( VERTEXNORMAL_VERTEX vertex ) : COLOR
{
    float4 baseshellcolor = float4( 0.9, 0.5, 0.1, 0.6);

    float2 tc1 = vertex.texcoord0.xy * 0.5;
    tc1.x += 0.005 * vertex.material.x;
    tc1.y += 0.02 * vertex.material.x;
    float4 lookup = tex2D( lookupSampler, tc1);

    float2 tc2 = vertex.texcoord0.xy * 2;
    tc2.y += 0.008 * vertex.material.x;
    tc2.x -= 0.008 * vertex.material.x;
    float4 lookup2 = tex2D( lookupSampler, tc2);

    float2 tc3 = vertex.texcoord0.xy * 0.001;
    tc3.x -= 0.0015 * vertex.material.x;
    float4 lookup3 = tex2D( lookupSampler, tc3);

    float electricity =  lookup.r * lookup2.b * 5;
    float4 glowpulse = float4(lookup3.ggg, min(lookup3.g, 0.65) + electricity );

    return (baseshellcolor  + electricity) * glowpulse;
}

/// Bubble shield
///
float4 ShieldNomadsPS( EFFECT_VERTEX vertex ) : COLOR
{
    if ( 1 == mirrored ) clip(vertex.depth);

    float4 colorMask = tex2D( albedoSampler, vertex.texcoord0.xy);
    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.zw);
    float3 normal = tex2D( secondarySampler, vertex.texcoord1.xy ).gaa;
    normal.z = sqrt( 1 - normal.x*normal.x - normal.y*normal.y );
    float3 specular = tex2D( specularSampler, vertex.texcoord1.zw );

    // the alpha value (0 -> 1) controls how transparent the shield is.
    float alpha = 0.28;
    float4 color = float4( mul( albedo.r , normal.r), mul( albedo.g , normal.g), mul( albedo.b , normal.b), alpha);

    // using the specular (noise map) to create noise on the shield by manipulating the alpha value
    float noiseFactor = 0.2;
    color.a = color.a * ((1 - noiseFactor) * (specular.r + specular.g + specular.b));

    // Adjust color of shield based on its health percentage
    float4 colorMod1 = float4( color.r * 0.5, color.g * 0.9, color.b * 0.9, color.a * 0.8 );
    color = lerp( colorMod1, color, vertex.material.y );

    return color;
}

float4 ShieldNomadsLoFiPS( LOFIEFFECT_VERTEX vertex ) : COLOR
{
    float3 color = float3( 1, 0.53, 0.24);
    float4 colormask = tex2D( albedoSampler, vertex.texcoord0.xy);
    float4 albedo = tex2D( albedoSampler, vertex.texcoord1.xy );
    float4 secondary = tex2D( secondarySampler, vertex.texcoord2.xy);
    float4 specular = tex2D( specularSampler, vertex.texcoord2.xy);

    color.rgb += albedo.r + secondary.b;
    float alpha = colormask.b * 0.7;

    if( specular.g <= albedo.g )
        alpha += 0.2;
    else
        alpha += 0.1;

    color.rgb += float3( 1, 0.53, 0.24 ) + colormask.bbb;

    alpha *= colormask.a;
    return float4(color,alpha);
}

// TECHNIQUES ------------------------------------------------------------------------------------------

technique NOMADSBuildUnit_MediumFidelity
<
    string abstractTechnique = "NomadsBuildUnit";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";

    // A note: Without STAGE_DEPTH, shadow and lighting info is not passed
    int renderStage = STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    // Glow first as it does not use depth
    // A pass afterwards must write the depth buffer
    pass P0
    {
        RasterizerState( Rasterizer_Cull_None )
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        ZEnable = true;
        ZWriteEnable = false;

        VertexShader = compile vs_1_1 NOMADSBuildMeshVS();
        PixelShader = compile ps_2_a NomadsBuildHologramUnitPS(true);
    }
    pass P1
    {
        RasterizerState( Rasterizer_Cull_CW )
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        ZEnable = true;
        ZWriteEnable = true;

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NomadsBuildPS(true);
    }
    pass P2
    {
        RasterizerState( Rasterizer_Cull_CW )
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        ZEnable = true;
        ZWriteEnable = true;

        VertexShader = compile vs_1_1 NOMADSBuildVS();
        PixelShader = compile ps_2_a NomadsBuildNoisePS(true);
    }
}

technique NOMADSBuildUnit_LowFidelity
<
    string abstractTechnique = "NomadsBuildUnit";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";

    // A note: Without STAGE_DEPTH, shadow and lighting info is not passed
    int renderStage = STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    // Glow first as it does not use depth
    // A pass afterwards must write the depth buffer
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        ZEnable = true;
        ZWriteEnable = true;

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NomadsBuildPS(true);
    }
    pass P1
    {
        RasterizerState( Rasterizer_Cull_CW )
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        ZEnable = true;
        ZWriteEnable = true;

        VertexShader = compile vs_1_1 NOMADSBuildVS();
        PixelShader = compile ps_2_a NomadsBuildNoisePS(true);
    }
}

technique NOMADSBuild_MediumFidelity
<
    string abstractTechnique = "NomadsBuild";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";

    // A note: Without STAGE_DEPTH, shadow and lighting info is not passed
    int renderStage = STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    // Glow first as it does not use depth
    // A pass afterwards must write the depth buffer
    pass P0
    {
        RasterizerState( Rasterizer_Cull_None )
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        ZEnable = true;
        ZWriteEnable = false;

        VertexShader = compile vs_1_1 NOMADSBuildMeshVS();
        PixelShader = compile ps_2_a NomadsBuildHologramPS(true);
    }
    pass P1
    {
        RasterizerState( Rasterizer_Cull_CW )
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        ZEnable = true;
        ZWriteEnable = true;

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NomadsBuildPS(true);
    }
    pass P2
    {
        RasterizerState( Rasterizer_Cull_CW )
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        ZEnable = true;
        ZWriteEnable = true;

        VertexShader = compile vs_1_1 NOMADSBuildVS();
        PixelShader = compile ps_2_a NomadsBuildNoisePS(true);
    }
}

technique NOMADSBuild_LowFidelity
<
    string abstractTechnique = "NomadsBuild";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";

    // A note: Without STAGE_DEPTH, shadow and lighting info is not passed
    int renderStage = STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    // Glow first as it does not use depth
    // A pass afterwards must write the depth buffer
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        ZEnable = true;
        ZWriteEnable = true;

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NomadsBuildPS(true);
    }
    pass P1
    {
        RasterizerState( Rasterizer_Cull_CW )
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        ZEnable = true;
        ZWriteEnable = true;

        VertexShader = compile vs_1_1 NOMADSBuildVS();
        PixelShader = compile ps_2_a NomadsBuildNoisePS(true);
    }
}

// Is this used?
// Orange holographic style
// Like NOMADSBuild but without fade to texture
technique OrangeHolo_HighFidelity
<
    string abstractTechnique = "NomadsBuild2";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";

    // A note: Without STAGE_DEPTH, shadow and lighting info is not passed
    int renderStage = STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    // Glow first as it does not use depth
    // A pass afterwards must write the depth buffer
    pass P0
    {
        RasterizerState( Rasterizer_Cull_None )
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        ZEnable = true;
        ZWriteEnable = false;

        VertexShader = compile vs_1_1 NOMADSBuildMeshVS();
        PixelShader = compile ps_2_a NomadsBuildHologramPS(false);
    }
    pass P1
    {
        RasterizerState( Rasterizer_Cull_CW )
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        ZEnable = true;
        ZWriteEnable = true;

        VertexShader = compile vs_1_1 NOMADSBuildVS();
        PixelShader = compile ps_2_a NomadsBuildNoisePS(false);
    }
}

// Orange holographic style
// Factory build rect
technique NomadsFactoryBuildRect_HighFidelity
<
    string abstractTechnique = "NomadsFactoryBuildRect";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";

    // A note: Without STAGE_DEPTH, shadow and lighting info is not passed
    int renderStage = STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    // Glow first as it does not use depth
    // A pass afterwards must write the depth buffer
    pass P0
    {
        RasterizerState( Rasterizer_Cull_None )
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        ZEnable = true;
        ZWriteEnable = true;

        VertexShader = compile vs_1_1 NOMADSBuildVS();
        PixelShader = compile ps_2_a NomadsFactoryBuildHologramPS();
    }
}

// NOMADS UNIT
// Don't forget to also update the personal shield techniques!
technique NomadsUnit_HighFidelity
<
    string abstractTechnique = "NomadsUnit";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NomadsNormalMappedPS(
            true,  // mask albedo
            true,  // glow
            true,  // hi def shadows
            false, // alpha test enable
            0, // alpha func
            0 // alpha ref
        );
    }
}

technique NomadsUnit_MedFidelity
<
    string abstractTechnique = "NomadsUnit";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NormalMappedPS(true,true,false, false,0,0 );
    }
}

technique NomadsUnit_LowFidelity
<
    string abstractTechnique = "NomadsUnit";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 ColorMaskPS_LowFidelity();
    }
}

technique NomadsUnitStunned_HighFidelity
<
    string abstractTechnique = "NomadsUnitStunned";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NomadsNormalMappedPS(
            true,  // mask albedo
            true,  // glow
            true,  // hi def shadows
            false, // alpha test enable
            0, // alpha func
            0 // alpha ref
        );
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a StunnedUnit();
    }
}

technique NomadsUnitStunned_MedFidelity
<
    string abstractTechnique = "NomadsUnitStunned";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NormalMappedPS(true,true,false, false,0,0 );
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a StunnedUnit();
    }
}

technique NomadsUnitStunned_LowFidelity
<
    string abstractTechnique = "NomadsUnitStunned";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 ColorMaskPS_LowFidelity();
    }
}

/// Nomads powered armor
/// Don't forget to also update the unit shader techniques (if the P0 pass is changed)!
technique NomadsPowerArmor_HighFidelity
<
    string abstractTechnique = "NomadsPowerArmor";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicShield";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONHEALTH;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NomadsNormalMappedPS(true,true,true, false,0,0 );
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 PositionNormalOffsetVS(0.01);
        PixelShader = compile ps_2_0 NomadsPowerArmorPS();
    }
}

technique NomadsPowerArmor_MedFidelity
<
    string abstractTechnique = "NomadsPowerArmor";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicShield";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONHEALTH;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NormalMappedPS(true,true,false, false,0,0 );
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 PositionNormalOffsetVS(0.01);
        PixelShader = compile ps_2_0 NomadsPowerArmorPS();
    }
}

technique NomadsPowerArmor_LowFidelity
<
    string abstractTechnique = "NomadsPowerArmor";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicShield";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONHEALTH;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 ColorMaskPS_LowFidelity();
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 PositionNormalOffsetVS(0.01);
        PixelShader = compile ps_2_0 NomadsPowerArmorPS();
    }
}

/// Nomad personal shield
///
technique NomadsPhaseShield_HighFidelity
<
    string abstractTechnique = "NomadsPhaseShield";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicShield";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONHEALTH;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NomadsNormalMappedPS(true,true,true, false,0,0 );
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 PositionNormalOffsetVS(0.01);
        PixelShader = compile ps_2_0 NomadsPhaseShieldPS();
    }
}

technique NomadsPhaseShield_MedFidelity
<
    string abstractTechnique = "NomadsPhaseShield";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicShield";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONHEALTH;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NormalMappedPS(true,true,false, false,0,0 );
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 PositionNormalOffsetVS(0.01);
        PixelShader = compile ps_2_0 NomadsPhaseShieldPS();
    }
}

technique NomadsPhaseShield_LowFidelity
<
    string abstractTechnique = "NomadsPhaseShield";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicShield";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONHEALTH;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 ColorMaskPS_LowFidelity();
    }
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )

        VertexShader = compile vs_1_1 PositionNormalOffsetVS(0.01);
        PixelShader = compile ps_2_0 NomadsPhaseShieldPS();
    }
}

/// Nomad Shield
///
technique ShieldNomads_MedFidelity
<
    string abstractTechnique = "ShieldNomads";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicShield";
    int renderStage = STAGE_POSTWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_FRACTIONHEALTH;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_None )
        DepthState( Depth_Enable_LessEqual_Write_None )

        VertexShader = compile vs_1_1 FourUVTexShiftScaleVS(
            1,  // ?
            1,  // size and number of albedo's simultaniously
            32,  // ?
            6,  // ?
            0,  // ?
            0,  // ?
            0.001,  // albedo rotation
            0.008,  // albedo speed top to bottom
            0,  // rotation Y axis of secondary texture
            0,  // speed of secondary texture (top to bottom)
            0,  // rotating (Y axis)
            0.004   // speed of specular texture (top to bottom)
        );
        PixelShader = compile ps_2_0 ShieldNomadsPS();
    }
}

technique ShieldNomads_LowFidelity
<
    string abstractTechnique = "ShieldNomads";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicShield";
    int renderStage = STAGE_POSTWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_FRACTIONHEALTH;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_None )
        DepthState( Depth_Enable_LessEqual_Write_None )

        VertexShader = compile vs_1_1 ThreeUVTexShiftScaleLoFiVS(
            1,  // ?
            1,  // size and number of albedo's simultaniously
            32,  // ?
            6,  // ?
            0,  // ?
            0,  // ?
            0.001,  // albedo rotation
            0.008,  // albedo speed top to bottom
            0  // rotation Y axis of secondary texture
        );
        PixelShader = compile ps_2_0 ShieldNomadsLoFiPS();
    }
}

technique ShieldNomadsStealth_MedFidelity
<
    string abstractTechnique = "StealthShieldNomads";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicShield";
    int renderStage = STAGE_POSTWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_FRACTIONHEALTH;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_None )
        DepthState( Depth_Enable_LessEqual_Write_None )

        VertexShader = compile vs_1_1 FourUVTexShiftScaleVS(
            1,  // ?
            3,  // size and number of albedo's simultaniously
            32,  // ?
            6,  // ?
            0,  // ?
            0,  // ?
            0.005,  // albedo rotation
            0.04,  // albedo speed top to bottom
            0,  // rotation Y axis of secondary texture
            0,  // speed of secondary texture (top to bottom)
            0,  // rotating (Y axis)
            0.006   // speed of specular texture (top to bottom)
        );
        PixelShader = compile ps_2_0 ShieldNomadsPS();
    }
}

technique ShieldNomadsStealth_LowFidelity
<
    string abstractTechnique = "StealthShieldNomads";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicShield";
    int renderStage = STAGE_POSTWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_FRACTIONHEALTH;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        RasterizerState( Rasterizer_Cull_None )
        DepthState( Depth_Enable_LessEqual_Write_None )

        VertexShader = compile vs_1_1 ThreeUVTexShiftScaleLoFiVS(
            1,  // ?
            3,  // size and number of albedo's simultaniously
            32,  // ?
            6,  // ?
            0,  // ?
            0,  // ?
            0.005,  // albedo rotation
            0.04,  // albedo speed top to bottom
            0  // rotation Y axis of secondary texture
        );
        PixelShader = compile ps_2_0 ShieldNomadsLoFiPS();
    }
}


///////////////////////////////////////
///
/// Total Annihilation
///
///////////////////////////////////////

// Original Shader by Armoured Fish, version 1.2 (10th Feb 2008)
// Ported to Forged Alliance by Raevn


//////////////////
//STRUCTS
//////////////////


struct TABUILD_VERTEX
{
    float4 position : POSITION0;
    float4 material : TEXCOORD0;
    float4 positionLocal : TEXCOORD1;
    float4 depth : TEXCOORD2;
};


/////////////////////
//TA VERTEX SHADER //
/////////////////////


TABUILD_VERTEX TABuildVS(
    float3 position : POSITION0,
    float3 normal : NORMAL0,
    float3 tangent : TANGENT0,
    float3 binormal : BINORMAL0,
    float4 texcoord0 : TEXCOORD0,
    int boneIndex[4] : BLENDINDICES,
    float3 row0 : TEXCOORD1,
    float3 row1 : TEXCOORD2,
    float3 row2 : TEXCOORD3,
    float3 row3 : TEXCOORD4,
    anim_t anim : TEXCOORD5,
    float4 material : TEXCOORD6,
    float4 color : COLOR0
)
{
    TABUILD_VERTEX vertex = (TABUILD_VERTEX)0;
    CompatSwizzle(color);

    vertex.positionLocal = mul(transPalette[anim.y + boneIndex[0]].w, float4(position,1));

    float4x4 worldMatrix = ComputeWorldMatrix( anim.y + boneIndex[0], row0, row1, row2, row3);
    vertex.position = mul( float4(position,1), worldMatrix);
    vertex.position = mul( vertex.position, mul( viewMatrix, projMatrix));
    vertex.depth.xy = float2(vertex.position.y - terrainScale.y * surfaceElevation,material.x);


    vertex.material = float4( time - material.x, material.yzw);
    return vertex;
}


////////////////////
//TA PIXEL SHADER //
////////////////////

float4 TABuildPS( TABUILD_VERTEX vertex ) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth);
    float posY = vertex.positionLocal.y;

    float percentComplete = vertex.material.y;
		
	//The following is a list of variables for tweaking the effect.
	//startpercent is the % complete the unit will be before effect starts.
	//speed is the fraction of the build time it would take to move from y=0 to y=1
	//thickness is simply the width of the band or leading edge band in the y direction
	//NOTE: the start and end percent vars don't seem terribly exact
	//      remember, bands have an END or FINISH percent, not a start
	//      it's only like that cause it's easiest to make something reach or leave 0 at a certain time
	//      than the unit height which is I can't actually read through the pixel shader
    	#define band1endpercent 0.05
    	#define band1speed 45.0
    	#define band1thickness 0.2

    	#define band2endpercent 0.15
    	#define band2speed 45.0
    	#define band2thickness 0.2

    	#define mainfillstartpercent 0.2
    	#define mainfillspeed 45.0
    	#define mainfillleadthickness 0.2

   	 #define texturefillstartpercent 0.7
   	 #define texturefillspeed 45.0
   	 #define texturefillleadthickness 0.2

   	 #define band3endpercent 0.95
   	 #define band3speed 45.0
   	 #define band3thickness 0.2

	
    //0 = transparent, 1 = sine green, 2 = cosine green, 3 = ignore (texture pass fills this in)
    int shadingmethod = 0;
    //This is where we determine what shading method to use on this pixel
    //Order of overlays here is in highest to lowest priority

    //third band pass
    if (1 - (percentComplete - band3endpercent)*band3speed >= posY &&
        posY + band3thickness >= (1 - (percentComplete - band3endpercent)*band3speed))
            shadingmethod = 2;

    //second band pass
    else if (1 - (percentComplete - band2endpercent)*band2speed >= posY &&
        posY + band2thickness >= (1 - (percentComplete - band2endpercent)*band2speed))
            shadingmethod = 2;

    //first band pass
    else if (1 - (percentComplete - band1endpercent)*band1speed >= posY &&
        posY + band1thickness >= (1 - (percentComplete - band1endpercent)*band1speed))
            shadingmethod = 2;

    //texture overlay
    else if ((percentComplete - texturefillstartpercent)*texturefillspeed >= posY) {
        //lead band
        if (posY + texturefillleadthickness >= (percentComplete - texturefillstartpercent)*texturefillspeed)
            shadingmethod = 2;
        //rest of fill
        else
            shadingmethod = 3;
    }

    //main color overlay
    else if ((percentComplete - mainfillstartpercent)*mainfillspeed >= posY) {
        //lead band
        if (posY + mainfillleadthickness >= (percentComplete - mainfillstartpercent)*mainfillspeed)
            shadingmethod = 2;
        //rest of fill
        else
            shadingmethod = 1;
    }


    //Now we actually compute pixel color
    float4 color = float4(0,0,0,1);

    //Shading methods very simple right now, however can be expanded upon
    //for more complex effects at high fidelity.
    //I tried to emulate the TA color movement but my attempts looked bad.
    //Just pure green ended up looking better.

    //0 = transparent, 1 = sine green, 2 = cosine green, 3 = ignore (texture pass fills this in)

    if (shadingmethod == 3) {
        discard;
    }
    else if (shadingmethod == 0)
        color.a = 0;
    else if (shadingmethod == 1) {
        color.g = (0.5*sin(time))+0.5;
    }
    else if (shadingmethod == 2) {
        color.g = (0.5*cos(time))+0.5;
    }

   return color;
}
float4 TABuildWiresPS( FLAT_VERTEX vertex) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth);
    //Same as shading method 2 in the solid shader.
    return float4(0,(0.5*cos(time))+0.5,0,0);
}



// TABuild technique High Fidelity
technique TABuild_HighFidelity
<
    string abstractTechnique = "TABuild";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicBuild";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_POSTWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    //NOTE: This all WOULD be just 2 passes, but 8 tex coords are already required for
    //the unit shader and adding the 1 more that I require is beyond shader limits.
    //This is a pain in the ass as combining them would fix a few things

    //occlusion pass for hidden line style render
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_None )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Occlude )

        VertexShader = compile vs_1_1 SilhouetteVS();
        PixelShader = null;
    }

    //render the main shading
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )
        FillMode = Solid;
        DepthBias = -0.00001f;

        VertexShader = compile vs_1_1 TABuildVS();
        PixelShader = compile ps_2_a TABuildPS(); //Right now this is the only version
    }
    //render the flashing wireframe
    pass P2
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        FillMode = WireFrame;  //This pass cannot be last else nothing will set this back to solid
        DepthBias = -0.00002f;

        VertexShader = compile vs_1_1 FlatVS();
        PixelShader = compile ps_2_a TABuildWiresPS(); //Right now this is the only version
    }
    //render the texture
    pass P3
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )
        FillMode = Solid;
        DepthBias = 0.0f;

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NormalMappedPS(true,true,true, false,0,0 );
    }

}

// TABuild technique Medium Fidelity
technique TABuild_MedFidelity
<
    string abstractTechnique = "TABuild";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicBuild";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_POSTWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    //NOTE: This all WOULD be just 2 passes, but 8 tex coords are already required for
    //the unit shader and adding the 1 more that I require is beyond shader limits.
    //This is a pain in the ass as combining them would fix a few things

    //occlusion pass for hidden line style render
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Occlude )

        VertexShader = compile vs_1_1 SilhouetteVS();
        PixelShader = null;
    }

    //render the main shading
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )
        FillMode = Solid;
        DepthBias = -0.00001f;

        VertexShader = compile vs_1_1 TABuildVS();
        PixelShader = compile ps_2_0 TABuildPS(); //Right now this is the only version
    }
    //render the flashing wireframe
    pass P2
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        FillMode = WireFrame;  //This pass cannot be last else nothing will set this back to solid
        DepthBias = -0.00002f;

        VertexShader = compile vs_1_1 FlatVS();
        PixelShader = compile ps_2_0 TABuildWiresPS(); //Right now this is the only version
    }
    //render the texture
    pass P3
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )
        FillMode = Solid;
        DepthBias = 0.0f;

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a NormalMappedPS(true,true,false, false,0,0 );
    }

}


// TABuild technique Low Fidelity
technique TABuild_LowFidelity
<
    string abstractTechnique = "TABuild";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicBuild";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_POSTWATER + STAGE_PREEFFECT;
    int parameter = PARAM_FRACTIONCOMPLETE;
>
{
    //NOTE: This all WOULD be just 2 passes, but 8 tex coords are already required for
    //the unit shader and adding the 1 more that I require is beyond shader limits.
    //This is a pain in the ass as combining them would fix a few things

    //occlusion pass for hidden line style render
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Occlude )

        VertexShader = compile vs_1_1 SilhouetteVS();
        PixelShader = null;
    }

    //render the main shading
    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable )
        FillMode = Solid;
        DepthBias = -0.00001f;

        VertexShader = compile vs_1_1 TABuildVS();
        PixelShader = compile ps_2_0 TABuildPS(); //Right now this is the only version
    }
    //render the flashing wireframe
    pass P2
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        FillMode = WireFrame;  //This pass cannot be last else nothing will set this back to solid
        DepthBias = -0.00002f;

        VertexShader = compile vs_1_1 FlatVS();
        PixelShader = compile ps_2_0 TABuildWiresPS(); //Right now this is the only version
    }
    //render the texture
    pass P3
    {
        AlphaState( AlphaBlend_Disable_Write_RGBA )
        RasterizerState( Rasterizer_Cull_CW )
        FillMode = Solid;
        DepthBias = 0.0f;

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 ColorMaskPS_LowFidelity();
    }

}

/////////////////////
// TA Cloak Shader //
/////////////////////

// Based off NormalMappedPS Shader with half alpha
//
// Original Shader by Armoured Fish
// Adapted for FA by Raevn

float4 TACloakPS( NORMALMAPPED_VERTEX vertex, 
					   uniform bool maskAlbedo, 
					   uniform bool glow, 
					   uniform bool hiDefShadows,
					   uniform bool alphaTestEnable, 
					   uniform int alphaFunc, 
					   uniform int alphaRef ) : COLOR0
{
    if ( 1 == mirrored ) clip(vertex.depth.x);
		
    float3x3 rotationMatrix = float3x3( vertex.binormal, vertex.tangent, vertex.normal);
    float3 normal = ComputeNormal( normalsSampler, vertex.texcoord0.zw, rotationMatrix);
    float dotLightNormal = dot(sunDirection,normal);

    float4 albedo = tex2D( albedoSampler, vertex.texcoord0.xy);
    float4 specular = tex2D( specularSampler, vertex.texcoord0.xy);
	float3 environment = texCUBE( environmentSampler, reflect( -vertex.viewDirection, normal));
    
    if ( maskAlbedo )
    	albedo.rgb = lerp( vertex.color.rgb, albedo.rgb, 1 - specular.a );
    else
        albedo.rgb = albedo.rgb * vertex.color.rgb;

	float phongAmount = saturate( dot( reflect( sunDirection, normal), -vertex.viewDirection));
	float3 phongAdditive = NormalMappedPhongCoeff * pow( phongAmount, 2) * specular.g;
	float3 phongMultiplicative = float3( 2 * environment * specular.r);

	float3 light = ComputeLight( dotLightNormal, ComputeShadow( vertex.shadow, hiDefShadows));

	float emissive = glowMultiplier * specular.b;
	float3 color = albedo.rgb * ( emissive.r + light + phongMultiplicative) + phongAdditive;

//	float alpha = mirrored ? 0.5 : ( glow ? ( specular.b + glowMinimum ) : ( vertex.material.g * albedo.a ));

//#ifdef DIRECT3D10
//	if( alphaTestEnable )
//		AlphaTestD3D10( alpha, alphaFunc, alphaRef );
//#endif
	return float4( color.rgb, 0.5 );
}


technique TACloak_HighFidelity
<
    string abstractTechnique = "TACloak";
    int fidelity = FIDELITY_HIGH;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_POSTEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable_Less )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_a TACloakPS(true,false,true, false,0,0 );
    }
}
technique TACloak_MedFidelity
<
    string abstractTechnique = "TACloak";
    int fidelity = FIDELITY_MEDIUM;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_REFLECTION + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable_Less )

        VertexShader = compile vs_1_1 NormalMappedVS();
        PixelShader = compile ps_2_0 TACloakPS(true,false,false, false,0,0 );
    }
}
technique TACloak_LowFidelity
<
    string abstractTechnique = "TACloak";
    int fidelity = FIDELITY_LOW;

    string cartographicTechnique = "CartographicUnit";
    string depthTechnique = "Depth";
    int renderStage = STAGE_DEPTH + STAGE_PREWATER + STAGE_PREEFFECT;
    int parameter = PARAM_UNUSED;
>
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_CW )
        DepthState( Depth_Enable_Less )

        VertexShader = compile vs_1_1 VertexNormalVS();
        PixelShader = compile ps_2_0 TACloakPS(true,false,false, false,0,0 );
    }
}
