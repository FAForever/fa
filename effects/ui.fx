
// variables global to this effect.
float4x4	ObjectToWorld;
float4x4	WorldToView;
float4x4	Projection;
texture     Texture1;
texture     Texture2;
float		UiGlow;

//============================================================================
//
//    Ui Canvas shaders
//
//============================================================================

sampler2D Sampler1 = sampler_state
{
    Texture = (Texture1);
	MipFilter = NONE;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU  = Clamp;
	AddressV  = Clamp;
};

sampler2D WrapSampler = sampler_state
{
    Texture = (Texture1);
	MipFilter = NONE;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU  = Wrap;
	AddressV  = Wrap;
};

sampler2D WrapSampler2 = sampler_state
{
	Texture   = (Texture2);
	MipFilter = NONE;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU  = Wrap;
	AddressV  = Wrap;
};

sampler2D MipSampler = sampler_state
{
    Texture = (Texture1);
	MipFilter = LINEAR;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU  = Clamp;
	AddressV  = Clamp;
};

struct VS_OUTPUT
{
    float4 Pos  : POSITION;
    float4 Color : COLOR0;
    float2 Tex1  : TEXCOORD0;    
};


VS_OUTPUT FixedVS(
    float3 Pos  : POSITION, 
    float4 Color : COLOR0, 
    float2 Tex  : TEXCOORD0)
{
    VS_OUTPUT Out = (VS_OUTPUT)0;

    float4x4 WorldView = mul(ObjectToWorld, WorldToView);

    float3 P = mul(float4(Pos, 1), (float4x3)WorldView);  // position (view space)
    Out.Pos  = mul(float4(P, 1), Projection);             // position (projected)
    
    // copy through color and tex coords
    Out.Color = Color;
    Out.Tex1 = Tex;
    return Out;
}

float4 UiSelectPS(
    float4 Diff : COLOR0,
    float2 Tex1  : TEXCOORD0,    
    uniform sampler2D sampler1, 
    uniform bool alphaTestEnable, 
	uniform int alphaFunc, 
	uniform int alphaRef ) : COLOR
{
	float4 texColor;
	if ( Diff.g == 1.0f )
		texColor = tex2D(sampler1, Tex1);
	else
		texColor = tex2D(WrapSampler2, Tex1);
		
#ifdef DIRECT3D10
	if( alphaTestEnable )
		AlphaTestD3D10( texColor.a, alphaFunc, alphaRef );
#endif
	return texColor;    
}

float4 UiPS(
    float4 Diff : COLOR0,
    float2 Tex1  : TEXCOORD0,    
    uniform sampler2D sampler1) : COLOR
{    
	float4 texColor = tex2D(sampler1, Tex1) * Diff;	
	return texColor;    
}

float4 SelectGlowPS(
    float4 Diff : COLOR0,
    float2 Tex1  : TEXCOORD0) : COLOR
{	
	return float4( Diff + 0.01 );
}

float4 UiGlowPS(
    float4 Diff : COLOR0,
    float2 Tex1  : TEXCOORD0) : COLOR
{	
	return float4( UiGlow, UiGlow, UiGlow, UiGlow );
}

technique TPath
{
    pass P0
    {
		AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
		DepthState( Depth_Enable_Less )
       
        VertexShader = compile vs_1_1 FixedVS();
        PixelShader = compile ps_2_0 UiPS(MipSampler);
    }
}

technique TSelect
{
    pass P0
    {		
		AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
		DepthState( Depth_Always )
		
#ifndef DIRECT3D10
		AlphaTestEnable = true;
		AlphaFunc = Greater;
		AlphaRef = 0;
#endif
    
        VertexShader = compile vs_1_1 FixedVS();
        PixelShader = compile ps_2_0 UiSelectPS(WrapSampler, true, d3d_Greater, 0 );        
    }
}

technique TSelectGlow
{
    pass P0
    {
		AlphaState( AlphaBlend_Disable )
		DepthState( Depth_Enable_Always_Write_None )
      
        VertexShader = compile vs_1_1 FixedVS();
        PixelShader = compile ps_2_0 SelectGlowPS();
    }
}

technique TPathGlow
{
    pass P0
    {
		AlphaState( AlphaBlend_Disable )
		DepthState( Depth_Enable_Always_Write_None )
		  
        VertexShader = compile vs_1_1 FixedVS();
        PixelShader = compile ps_2_0 UiGlowPS();
    }
}

technique TPathNoMip
{
	pass P0
    {				
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
        DepthState( Depth_Always )
        
        VertexShader = compile vs_1_1 FixedVS();
        PixelShader = compile ps_2_0 UiPS(Sampler1);        
    }
}

technique TPathNoZClip
{
	pass P0
    {				
		AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
		DepthState( Depth_Always )
      
        VertexShader = compile vs_1_1 FixedVS();
        PixelShader = compile ps_2_0 UiPS(MipSampler);        
    }
}




