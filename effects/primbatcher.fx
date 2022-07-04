
// variables global to this effect.

float4x4 CompositeMatrix;
texture Texture1;
float AlphaMultiplier = 1.0;
float time = 0;

sampler LinearSampler = sampler_state
{
    Texture = (Texture1);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = Clamp;
    AddressV  = Clamp;
};

sampler UWrapSampler = sampler_state
{
    Texture = (Texture1);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = Wrap;
    AddressV  = Clamp;
};

sampler PointSampler = sampler_state
{
    Texture = (Texture1);
    MipFilter = POINT;
    MinFilter = POINT;
    MagFilter = POINT;
    AddressU  = Clamp;
    AddressV  = Clamp;
};


struct VS_OUTPUT
{
    float4 Pos  : POSITION;
    float4 Color : COLOR0;
    float2 Tex1  : TEXCOORD0;
};


VS_OUTPUT PrimBatcherVS(
    float3 Pos  : POSITION,
    float4 Color : COLOR0,
    float2 Tex  : TEXCOORD0 )
{
    VS_OUTPUT Out;
    CompatSwizzle(Color);

    Out.Pos = mul(float4(Pos, 1), CompositeMatrix);
    Out.Color = Color;
    Out.Tex1 = Tex;

    return Out;
}


float4 PrimBatcherPS(
    float4 Pos : POSITION,
    float4 Diff : COLOR0,
    float2 Tex1  : TEXCOORD0,
    uniform sampler Samp) : COLOR
{
    float4 color = tex2D(Samp, Tex1) * Diff ;
    color.a *= AlphaMultiplier;
    return color;
}

float4 RangeGlowPS(
    float4 Pos : POSITION,
    float4 Diff : COLOR0,
    float2 Tex1  : TEXCOORD0) : COLOR
{
    return float4(0,0,0,0.2);
}

float4 PrimBatcherPSRed(
    float4 Pos : POSITION,
    float4 Diff : COLOR0,
    float2 Tex1  : TEXCOORD0) : COLOR
{
    return float4(1,0,0,1);
}

float4 PrimBatcherPSYellow(
    float4 Pos : POSITION,
    float4 Diff : COLOR0,
    float2 Tex1  : TEXCOORD0) : COLOR
{
    return float4(1,1,0,1);
}

float4 CommandPS(
    float4 Pos : POSITION,
    float4 Diff : COLOR0,
    float2 Tex1  : TEXCOORD0) : COLOR
{
    float4 color = tex2D(UWrapSampler, Tex1) * Diff;
    color.a *= AlphaMultiplier;
    return color;
}

float4 CommandGlowPS(
    float4 Pos : POSITION,
    float4 Diff : COLOR0,
    float2 Tex1  : TEXCOORD0) : COLOR
{
    float4 textureColor = tex2D(LinearSampler, Tex1);
    if(textureColor.a == 0)
        Diff.a = 0;
    return float4 (0,0,0, Diff.a);
}


float4 StrategicIconPS(
    float4 Pos : POSITION,
    float4 Diff : COLOR0,
    float2 Tex1  : TEXCOORD0) : COLOR
{
    float4 color = tex2D(PointSampler, Tex1);
    float3 d = (color.rgb-float3(0.5,0.5,0.5)) * (color.rgb-float3(0.5,0.5,0.5));
    if( dot(d, float3(1,1,1)) < (0.25) )
        color.rgb = Diff.rgb;
    return color;
}

struct RESOURCE_VERTEX
{
    float4 position  : POSITION;
    float2 texcoord  : TEXCOORD0;
    float1 alpha : TEXCOORD1;
};
typedef RESOURCE_VERTEX RESOURCE_PIXEL;

RESOURCE_VERTEX ResourceVS( float3 position  : POSITION,
                            float4 color : COLOR0,            // color is unused but necessary for the tight linkages between IA and VS in d3d10
                            float2 texcoord0 : TEXCOORD0)
{
    RESOURCE_VERTEX vertex = (RESOURCE_VERTEX)0;
    CompatSwizzle(color);

    float2 r = float2(position.x,position.y);
    float R = 0.00277 * length(r);

    vertex.position = mul(float4(position,1),CompositeMatrix);
    vertex.texcoord = texcoord0;
    vertex.alpha = R;

    return vertex;
}

float4 ResourceIconPS( RESOURCE_PIXEL pixel, uniform bool glow ): COLOR
{
    float4 color = tex2D(PointSampler,pixel.texcoord);
    if ( glow )
    {
        float sine = sin( 1 * time - 10 * pixel.alpha);
        color.a *= 0.6 * sine * sine;
    }
    return color;
}

float4 LifeBarPS(
    float4 Pos : POSITION,
    float4 Diff : COLOR0,
    float2 Tex1  : TEXCOORD0) : COLOR
{
    float4 color = tex2D(PointSampler, Tex1);
    color.rgb = Diff.rgb;
    return color;
}

struct SKYBOX_OUTPUT
{
    float4 Pos  : POSITION;
    float3 Tex  : TEXCOORD0;
};


SKYBOX_OUTPUT SkyBoxVS(
    float3 Pos  : POSITION,
    float4 Color : COLOR0,
    float2 Tex  : TEXCOORD0 )
{
    SKYBOX_OUTPUT Out;
       CompatSwizzle(Color);

    Out.Pos = mul(float4(Pos, 1), CompositeMatrix);
    // output the position as a vector
    Out.Tex = normalize(Pos).xyz;
    return Out;
}

float4 SkyBoxPS( SKYBOX_OUTPUT input ) : COLOR
{
    float4 color = texCUBE(LinearSampler, input.Tex);
    return color;
}


technique TSkyBox
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        DepthState( Depth_Disable_Write_None )
        RasterizerState( Rasterizer_Cull_None )

#ifndef DIRECT3D10
        AlphaTestEnable = false;
#endif
        VertexShader = compile vs_1_1 SkyBoxVS();
        PixelShader = compile ps_2_0 SkyBoxPS();
    }
}


technique TRed
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        DepthState( Depth_Disable )
        RasterizerState( Rasterizer_Cull_None )

#ifndef DIRECT3D10
        AlphaTestEnable = false;
#endif
        VertexShader = compile vs_1_1 PrimBatcherVS();
        PixelShader = compile ps_2_0 PrimBatcherPSRed();
    }
}

technique TYellow
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_RGB )
        DepthState( Depth_Disable )
        RasterizerState( Rasterizer_Cull_None )

#ifndef DIRECT3D10
        AlphaTestEnable = false;
#endif
        VertexShader = compile vs_1_1 PrimBatcherVS();
        PixelShader = compile ps_2_0 PrimBatcherPSYellow();
    }
}

technique TAlphaBlendLinearSample
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_None )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = Greater;
#endif
        VertexShader = compile vs_1_1 PrimBatcherVS();
        PixelShader = compile ps_2_0 PrimBatcherPS(LinearSampler);
    }
}

technique TAlphaBlendPointSample
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        RasterizerState( Rasterizer_Cull_None )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = Greater;
#endif
        VertexShader = compile vs_1_1 PrimBatcherVS();
        PixelShader = compile ps_2_0 PrimBatcherPS(PointSampler);
    }
}

technique TAlphaBlendLinearSampleNoDepth
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        DepthState( Depth_Disable )
        RasterizerState( Rasterizer_Cull_None )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 PrimBatcherVS();
        PixelShader = compile ps_2_0 PrimBatcherPS(LinearSampler);
    }
}

technique TRange
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        DepthState( Depth_Disable )
        RasterizerState( Rasterizer_Cull_None )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 PrimBatcherVS();
        PixelShader = compile ps_2_0 PrimBatcherPS(LinearSampler);
    }
}

technique TCommand
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        DepthState( Depth_TCommand )
        RasterizerState( Rasterizer_Cull_None )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 PrimBatcherVS();
        PixelShader = compile ps_2_0 CommandPS();
    }
}

technique TCommandGlow
{
    pass P0
    {
        AlphaState( AlphaBlend_Disable_Write_A )
        DepthState( Depth_Disable )
        RasterizerState( Rasterizer_Cull_None )

        VertexShader = compile vs_1_1 PrimBatcherVS();
        PixelShader = compile ps_2_0 CommandGlowPS();
    }
}

technique TCommandOther
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        DepthState( Depth_TCommandOther )
        RasterizerState( Rasterizer_Cull_None )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 PrimBatcherVS();
        PixelShader = compile ps_2_0 CommandPS();
    }
}



technique TStrategicIcon
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        DepthState( Depth_Disable )
        RasterizerState( Rasterizer_Cull_None )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 PrimBatcherVS();
        PixelShader = compile ps_2_0 StrategicIconPS();
    }
}

technique TStrategicFormationIcon
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        DepthState( Depth_Disable )
        RasterizerState( Rasterizer_Cull_None )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 PrimBatcherVS();
        PixelShader = compile ps_2_0 StrategicIconPS();
    }
}

technique TResourceIcon
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        DepthState( Depth_Disable )
        RasterizerState( Rasterizer_Cull_None )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 ResourceVS();
        PixelShader = compile ps_2_0 ResourceIconPS(false);
    }

    pass P1
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_A )
        DepthState( Depth_Disable )
        RasterizerState( Rasterizer_Cull_None )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 ResourceVS();
        PixelShader = compile ps_2_0 ResourceIconPS(true);
    }
}

technique TLifeBar
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        DepthState( Depth_Disable )
        RasterizerState( Rasterizer_Cull_None )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 PrimBatcherVS();
        PixelShader = compile ps_2_0 LifeBarPS();
    }
}
