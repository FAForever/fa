float4x4 ViewMatrix;
float4x4 InverseViewMatrix;
float4x4 Projection;
float4x4 WorldToProjection;
float4 ParticleSystemPosition;

float time;
float ParticleSystemShape;
float ParticleSpread;
float ParticleSpeed;
float ParticleSystemHeight;
float ParticleSize;

int   DragEnabled = 0;

float4 startColor = float4(1, 1, 0, 1);
float4 endColor = float4(0, 0, 0, 1);

texture BackgroundTexture;
texture ParticleTexture0;
texture ParticleTexture1;

sampler2D BackgroundSampler = sampler_state
{
	Texture		= (BackgroundTexture);
	MipFilter	= LINEAR;
	MinFilter	= LINEAR;
	MagFilter	= LINEAR;
	AddressU	= CLAMP;
	AddressV	= CLAMP;
};

sampler2D ParticleSampler0 = sampler_state
{
	Texture   = (ParticleTexture0);
	MipFilter = LINEAR;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = CLAMP;
};

sampler2D ParticleSampler1 = sampler_state
{
	Texture   = (ParticleTexture1);
	MipFilter = LINEAR;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};


sampler2D ParticleSampler0Wrap = sampler_state
{
	Texture   = (ParticleTexture0);
	MipFilter = LINEAR;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
};




struct WORLD_OUTPUT {
   float4 mPos  : POSITION;
   float2 mTex0 : TEXCOORD0;
   float2 mTex1 : TEXCOORD1;
   float2 mTex2 : TEXCOORD2;
};


WORLD_OUTPUT WorldVS(
	float2 Corner : POSITION0,
    float4 Pos: POSITION1,
    float2 Size: TEXCOORD0,
    float4 Velocity: TEXCOORD1,
    float3 Acceleration: TEXCOORD2,
    float4 inTime : TEXCOORD3,
    float3 inTexOffset : TEXCOORD4,
    float3 dragCoeff : TEXCOORD5,
    uniform bool inAnimTexture,
    uniform bool inFlat
)
{
    WORLD_OUTPUT Out = (WORLD_OUTPUT)0;
    
	// get amount of time elapsed since creation
	float t = time - inTime.x; 				
	float lifetime = inTime.y;
	float framerate = inTime.z;
	float framesize =  inTime.w;

	// get the alpha value
	float alpha = t / lifetime;
    
	// does this thing actually let us early out?
	if( alpha < 1.0f )
	{
	    // initial position
	    float3 pos = float3(0,0,0);
	    if ( 1 == DragEnabled )
            pos = ( dragCoeff.z * Acceleration.xyz - dragCoeff.y * Velocity.xyz ) * ( pow(2.71828183,-dragCoeff.x*t) - 1 ) + dragCoeff.y * Acceleration.xyz * t + Pos.xyz;
        else
    		pos = Pos.xyz + Velocity.xyz * t + (0.5 * Acceleration.xyz * pow(t,2));

		// calculate the sin and cos of our rotation amount
		float rotcos, rotsin;

		// Rotate our initialze -1,1 quad around 0,0
		float2 rotatedquad;
		float rotationRadians = Pos.w + (Velocity.w * t);
		sincos(rotationRadians, rotsin, rotcos);
		
		// rotate the quad
		rotatedquad.x = Corner.x * rotcos - Corner.y * rotsin;
		rotatedquad.y = Corner.x * rotsin + Corner.y * rotcos;	

		// Billboard the quads.
		if( inFlat )
		{
			// our right and up vectors are flat in worldspace
			pos += (rotatedquad.x * float4(1,0,0,0) + rotatedquad.y * float4(0,0,1,0)) * (Size.x + (Size.y * t));
		}																		 
		else
		{
			// The view matrix gives us our right and up vectors.
			pos += (rotatedquad.x * InverseViewMatrix[0] + rotatedquad.y * InverseViewMatrix[1]) * (Size.x + (Size.y * t));
		}

		Out.mPos = mul(float4(pos, 1), WorldToProjection);
		Out.mTex0 = (Corner.xy + 1) * 0.5;
		if( inAnimTexture )
		{ 		
			// calculate current texture frame
			float frame = floor(framerate * t);
			Out.mTex0.x *= framesize;
			Out.mTex0.x += framesize * frame;		
			// y offset of the texture for multiple frame types
			Out.mTex0.y *= inTexOffset.z;
			Out.mTex0.y += inTexOffset.x;
		}
		Out.mTex1.x  = alpha;
		// ramp texture offset for multiple ramps in the same texture.
		Out.mTex1.y = inTexOffset.y;
		
		Out.mTex2 = 0.5 * Out.mPos.xy / Out.mPos.w + 0.5;
		Out.mTex2.y = 1 - Out.mTex2.y; 
	}

   return Out;
}

WORLD_OUTPUT WorldVSAlign(
	float2 Corner : POSITION0,
    float4 Pos: POSITION1,
    float2 Size: TEXCOORD0,
    float4 Velocity: TEXCOORD1,
    float3 Acceleration: TEXCOORD2,
    float4 inTime : TEXCOORD3,
    float3 inTexOffset : TEXCOORD4,
    float3 dragCoeff : TEXCOORD5,
    uniform bool inAnimTexture,
    uniform bool nomovement
)
{
    WORLD_OUTPUT Out = (WORLD_OUTPUT)0;

	// get amount of time elapsed since creation
	float t = time - inTime.x; 				
	float lifetime = inTime.y;
	float framerate = inTime.z;
	float framesize =  inTime.w;

	// get the alpha value
	float alpha = t / lifetime;

	// does this thing actually let us early out?
	//if(  alpha < 1.0f )
	{
		// initial position
		float3 pos = Pos.xyz;
     
        float EXP = 0;
        if ( 1 == DragEnabled )
            EXP = pow(2.71828183,-dragCoeff.x*t);
            
        if( !nomovement )
        {
	        if ( 1 == DragEnabled )
                pos += ( dragCoeff.z * Acceleration.xyz - dragCoeff.y * Velocity.xyz ) * ( EXP - 1 ) + dragCoeff.y * Acceleration.xyz * t;
            else
    		    pos += Velocity.xyz * t + (0.5 * Acceleration.xyz * pow(t,2));
        }


		// move position into view space
		pos = mul( float4(pos, 1), ViewMatrix );

		// get the direction into view space that we are heading
		float3 v = float3(0,0,0);
		if ( 1 == DragEnabled )
		    v = ( -dragCoeff.y * Acceleration.xyz + Velocity.xyz ) * EXP + dragCoeff.y * Acceleration.xyz;
        else
    		v = normalize(Velocity.xyz + (Acceleration.xyz * t));
        		
		float3 viewspacedirection = mul(v, ViewMatrix);

		viewspacedirection = normalize(viewspacedirection);
		
		// calculate the cross product of the direction of the beam and the direction of the camera
		// to get our x offset in view space
		float3 xoffset = cross(float3(0,0,1), viewspacedirection);
		xoffset = normalize(xoffset) * Corner.x * (Size.x + (Size.y * t));
		
		// and our y offset in view space is just the actual direction we are going
		float3 zoffset = viewspacedirection * Corner.y * (Size.x + (Size.y * t));
	
		// get the position into view space
		pos += xoffset;		
		pos += zoffset;

		// get us into regular projection space
		Out.mPos = mul(float4(pos, 1), Projection);
		Out.mTex0.xy = (Corner.xy + 1) * 0.5;
		if( inAnimTexture )
		{ 		
			// calculate current texture frame
			float frame = floor(framerate * t);
			Out.mTex0.x *= framesize;
			Out.mTex0.x += framesize * frame;		
			// y offset of the texture for multiple frame types
			Out.mTex0.y *= inTexOffset.z;
			Out.mTex0.y += inTexOffset.x;
		}
		Out.mTex1.x  = alpha;
		// ramp texture offset for multiple ramps in the same texture.
		Out.mTex1.y = inTexOffset.y;
	}
		
    return Out;
}

struct PS_OUTPUT {
   float4 color : COLOR0;
};

PS_OUTPUT WorldPS(WORLD_OUTPUT inData)
{
	PS_OUTPUT o = (PS_OUTPUT)0;
	o.color = tex2D(ParticleSampler0,inData.mTex0) * tex2D(ParticleSampler1,inData.mTex1);
	return o;
}

PS_OUTPUT WorldRefractPS( WORLD_OUTPUT inData)
{
	PS_OUTPUT o = (PS_OUTPUT)0;

	float4 texel0 = tex2D(ParticleSampler0,inData.mTex0);
	float2 offset = 0.005 * ( 2 * texel0.rg - 1 );
	
	float3 color = tex2D(BackgroundSampler,inData.mTex2+offset).rgb;
	float  alpha = texel0.a * tex2D(ParticleSampler1,inData.mTex1).a;
	
	o.color = float4(color,alpha);

	return o;
}

float4 LightPS(WORLD_OUTPUT inData) : COLOR 
{
	return tex2D(ParticleSampler0, inData.mTex0) * tex2D(ParticleSampler1,inData.mTex1);	
}



struct BEAM_OUTPUT {
   float4 mPos: POSITION;
   float4 mColor: COLOR0;
   float2 mUv0: TEXCOORD0;
   float2 mUv1: TEXCOORD1;
};


/*

For each vertex in the beam we want the direction along the bream either + or -
to be transformed into view space.

then the offset = cross( view space camera direction,  view space beam direction )

normalize this and add it to the position.


*/


BEAM_OUTPUT BeamVS(float3 Pos: POSITION, float4 Size: TEXCOORD0, float4 Color: TEXCOORD1, float4 Scaling: TEXCOORD2)
{
   BEAM_OUTPUT Out;

	// initial position
	float3 pos = mul( float4(Pos,1), ViewMatrix);

	// get the direction into view space.
	float3 viewspacedirection = mul( Size.xyz, ViewMatrix);
	
	// calculate the cross product of the direction of the beam and the direction of the camera
	float3 offset = cross(float3(0,0,1), viewspacedirection);

	// normalize the offset
	offset = normalize(offset) * Size.w;
	
	// get the position into view space
	pos += offset;		

	Out.mPos = mul(float4(pos, 1), Projection);

	Out.mColor = Color;
	Out.mUv0.x = Scaling.x + (Scaling.z * time);
	Out.mUv0.y = Scaling.y + (Scaling.w * time);	
	Out.mUv1 = Scaling.xy;
	
	return Out;
}


float4 BeamPS(BEAM_OUTPUT inData, uniform int textureCount) : COLOR 
{
	float4 color;
	if( textureCount == 1 )
	{
		color =  tex2D(ParticleSampler0Wrap, inData.mUv0) * inData.mColor; 
	}
	if( textureCount == 2 )
	{
		color = tex2D(ParticleSampler0Wrap, inData.mUv0) * tex2D(ParticleSampler1, inData.mUv1) * inData.mColor;
	}
	
	return color;
	
}



struct TRAIL_OUTPUT {
   float4 mPos: POSITION;
   float2 mUv0: TEXCOORD0;
   float2 mUv1: TEXCOORD1;
};


TRAIL_OUTPUT TrailVS(float3 Pos: POSITION, float3 Direction: TEXCOORD0, float3 Lifetime: TEXCOORD1, float4 Width: TEXCOORD2)
{
   TRAIL_OUTPUT Out;

	// time this strip started
	float originTime = Width.w;
	float startTime = Lifetime.x;
	float lifetime = Lifetime.y;
	float repeatRate = Lifetime.z;

	// get amount of time elapsed since creation
	float t = (time - startTime) / lifetime; 	
	// get amount of time lapsed since beginning of strip
	float vee = (startTime - originTime) / lifetime;
	float repeatvee = vee * repeatRate; //frac(vee);

	// initial position
	float3 pos = mul( float4(Pos,1), ViewMatrix);

	// get the direction into view space.
	float3 viewspacedirection = mul( Direction.xyz, ViewMatrix);
	
	// calculate the cross product of the direction of the beam and the direction of the camera
	float3 offset = cross(float3(0,0,1), viewspacedirection);
	
	// normalize the offset
	offset = normalize(offset) * Width.x;
	
	// get the position into view space
	pos += offset;		

	// get the position into projection space
	Out.mPos = mul(float4(pos, 1), Projection);

	// output some useful uv's	
	Out.mUv0 = float2(Width.z, repeatRate);
	Out.mUv1 = float2(t, Width.z);
	return Out;
}

float4 TrailPS(TRAIL_OUTPUT inData) : COLOR 
{
    if( inData.mUv1.x > 0.0 && inData.mUv1.x < 1.0 )
        return tex2D(ParticleSampler1, inData.mUv1) * tex2D(ParticleSampler0Wrap, inData.mUv0);
    else
        return float4(0, 0, 0, 0);
}


// ********************************************************************************
// *** TRamp 
// ********************************************************************************
technique TRamp_MODULATEINVERSE
{
	pass P0
	{
		AlphaState( AlphaBlend_Zero_InvSrcColor )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(false,false);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRamp_MODULATE2XINVERSE
{
	pass P0
	{
		AlphaState( AlphaBlend_InvDestColor_InvSrcColor )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(false,false);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRamp_ADD
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_One )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(false,false);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRamp_ALPHABLEND
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(false,false);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRamp_PREMODALPHA
{
	pass P0
	{
		AlphaState( AlphaBlend_One_InvSrcAlpha_Write_RGB )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(false,false);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRamp_REFRACT
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(false,false);
		PixelShader = compile ps_2_0 WorldRefractPS();
	}
}

// ********************************************************************************
// *** TRampAnimate 
// ********************************************************************************
technique TRampAnimate_MODULATEINVERSE
{
	pass P0
	{
		AlphaState( AlphaBlend_Zero_InvSrcColor )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(true, false);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAnimate_MODULATE2XINVERSE
{
	pass P0
	{
		AlphaState( AlphaBlend_InvDestColor_InvSrcColor )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(true, false);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAnimate_ADD
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_One )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(true, false);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAnimate_ALPHABLEND
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(true, false);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAnimate_PREMODALPHA
{
	pass P0
	{
		AlphaState( AlphaBlend_One_InvSrcAlpha_Write_RGB )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(true, false);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAnimate_REFRACT
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(true, false);
		PixelShader = compile ps_2_0 WorldRefractPS();
	}
}

// ********************************************************************************
// *** TRampAlign 
// ********************************************************************************
technique TRampAlign_MODULATEINVERSE
{
	pass P0
	{
		AlphaState( AlphaBlend_Zero_InvSrcColor )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVSAlign(false, false);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAlign_MODULATE2XINVERSE
{
	pass P0
	{
		AlphaState( AlphaBlend_InvDestColor_InvSrcColor )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVSAlign(false, false);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAlign_ADD
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_One_Write_RGB )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )
		//ColorWriteEnable = 0x7;

		VertexShader = compile vs_1_1 WorldVSAlign(false, false);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAlign_ALPHABLEND
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )
		//ColorWriteEnable = 0x7;

		VertexShader = compile vs_1_1 WorldVSAlign(false, false);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAlign_PREMODALPHA
{
	pass P0
	{
		AlphaState( AlphaBlend_One_InvSrcAlpha_Write_RGB )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )
		//ColorWriteEnable = 0x7;

		VertexShader = compile vs_1_1 WorldVSAlign(false, false);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAlign_REFRACT
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVSAlign(false, false);
		PixelShader = compile ps_2_0 WorldRefractPS();
	}
}

// ********************************************************************************
// *** TRampAnimateAlign 
// ********************************************************************************
technique TRampAnimateAlign_MODULATEINVERSE
{
	pass P0
	{
		AlphaState( AlphaBlend_Zero_InvSrcColor )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVSAlign(true, false);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAnimateAlign_MODULATE2XINVERSE
{
	pass P0
	{
		AlphaState( AlphaBlend_InvDestColor_InvSrcColor )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVSAlign(true, false);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAnimateAlign_ADD
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_One )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVSAlign(true, false);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAnimateAlign_ALPHABLEND
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVSAlign(true, false);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAnimateAlign_PREMODALPHA
{
	pass P0
	{
		AlphaState( AlphaBlend_One_InvSrcAlpha_Write_RGB )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )
		//ColorWriteEnable = 0x7;

		VertexShader = compile vs_1_1 WorldVSAlign(true, false);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAnimateAlign_REFRACT
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVSAlign(true, false);
		PixelShader = compile ps_2_0 WorldRefractPS();
	}
}

// ********************************************************************************
// *** TRampAnimateAlignToBone 
// ********************************************************************************
technique TRampAnimateAlignToBone_MODULATEINVERSE
{
	pass P0
	{
		AlphaState( AlphaBlend_Zero_InvSrcColor )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVSAlign(true, true);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAnimateAlignToBone_MODULATE2XINVERSE
{
	pass P0
	{
		AlphaState( AlphaBlend_InvDestColor_InvSrcColor )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVSAlign(true, true);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAnimateAlignToBone_ADD
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_One )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVSAlign(true, true);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAnimateAlignToBone_ALPHABLEND
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVSAlign(true, true);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAnimateAlignToBone_PREMODALPHA
{
	pass P0
	{
		AlphaState( AlphaBlend_One_InvSrcAlpha_Write_RGB )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )
		//ColorWriteEnable = 0x7;

		VertexShader = compile vs_1_1 WorldVSAlign(true, true);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAnimateAlignToBone_REFRACT
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVSAlign(true, true);
		PixelShader = compile ps_2_0 WorldRefractPS();
	}
}

// ********************************************************************************
// *** TRampAlignToBone
// ********************************************************************************
technique TRampAlignToBone_MODULATEINVERSE
{
	pass P0
	{
		AlphaState( AlphaBlend_Zero_InvSrcColor )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVSAlign(false, true);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAlignToBone_MODULATE2XINVERSE
{
	pass P0
	{
		AlphaState( AlphaBlend_InvDestColor_InvSrcColor )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVSAlign(false, true);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAlignToBone_ADD
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_One )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVSAlign(false, true);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAlignToBone_ALPHABLEND
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVSAlign(false, true);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAlignToBone_PREMODALPHA
{
	pass P0
	{
		AlphaState( AlphaBlend_One_InvSrcAlpha_Write_RGB )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )
		//ColorWriteEnable = 0x7;

		VertexShader = compile vs_1_1 WorldVSAlign(false, true);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAlignToBone_REFRACT
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVSAlign(false, true);
		PixelShader = compile ps_2_0 WorldRefractPS();
	}
}

// ********************************************************************************
// *** TRampFlat
// ********************************************************************************
technique TRampFlat_MODULATEINVERSE
{
	pass P0
	{
		AlphaState( AlphaBlend_Zero_InvSrcColor )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(false,true);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampFlat_MODULATE2XINVERSE
{
	pass P0
	{
		AlphaState( AlphaBlend_InvDestColor_InvSrcColor )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(false,true);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampFlat_ADD
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_One )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(false,true);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampFlat_ALPHABLEND
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(false,true);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampFlat_PREMODALPHA
{
	pass P0
	{
		AlphaState( AlphaBlend_One_InvSrcAlpha_Write_RGB )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )
		//ColorWriteEnable = 0x7;

		VertexShader = compile vs_1_1 WorldVS(false,true);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampFlat_REFRACT
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(false,true);
		PixelShader = compile ps_2_0 WorldRefractPS();
	}
}

// ********************************************************************************
// *** TRampAnimateFlat
// ********************************************************************************
technique TRampAnimateFlat_MODULATEINVERSE
{
	pass P0
	{
		AlphaState( AlphaBlend_Zero_InvSrcColor )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(true,true);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAnimateFlat_MODULATE2XINVERSE
{
	pass P0
	{
		AlphaState( AlphaBlend_InvDestColor_InvSrcColor )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(true,true);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAnimateFlat_ADD
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_One )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(true,true);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAnimateFlat_ALPHABLEND
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(true,true);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAnimateFlat_PREMODALPHA
{
	pass P0
	{
		AlphaState( AlphaBlend_One_InvSrcAlpha_Write_RGB )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )
		//ColorWriteEnable = 0x7;

		VertexShader = compile vs_1_1 WorldVS(true,true);
		PixelShader = compile ps_2_0 WorldPS();
	}
}

technique TRampAnimateFlat_REFRACT
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(true,true);
		PixelShader = compile ps_2_0 WorldRefractPS();
	}
}

// ********************************************************************************
// *** TLight
// ********************************************************************************
technique TLight_MODULATEINVERSE
{
	pass P0
	{
		AlphaState( AlphaBlend_Zero_InvSrcColor_Write_RGBA )
		DepthState( Depth_Disable_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(false,true);
		PixelShader = compile ps_2_0 LightPS();
	}
}

technique TLight_MODULATE2XINVERSE
{
	pass P0
	{
		AlphaState( AlphaBlend_InvDestColor_InvSrcColor_Write_RGBA )
		DepthState( Depth_Disable_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(false,true);
		PixelShader = compile ps_2_0 LightPS();
	}
}

technique TLight_ADD
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_One_Write_RGBA )
		DepthState( Depth_Disable_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(false,true);
		PixelShader = compile ps_2_0 LightPS();
	}
}

technique TLight_ALPHABLEND
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )		
		DepthState( Depth_Disable_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(false,true);
		PixelShader = compile ps_2_0 LightPS();
	}
}

technique TLight_PREMODALPHA
{
	pass P0
	{
		AlphaState( AlphaBlend_One_InvSrcAlpha_Write_RGBA )
		DepthState( Depth_Disable_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 WorldVS(false,true);
		PixelShader = compile ps_2_0 LightPS();
	}
}

// ********************************************************************************
// *** TBeam_OneTexture
// ********************************************************************************
technique TBeam_OneTexture_MODULATEINVERSE
{
	pass P0
	{
		AlphaState( AlphaBlend_Zero_InvSrcColor )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 BeamVS();
		PixelShader = compile ps_2_0 BeamPS(1);
	}
}

technique TBeam_OneTexture_MODULATE2XINVERSE
{
	pass P0
	{
		AlphaState( AlphaBlend_InvDestColor_InvSrcColor )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 BeamVS();
		PixelShader = compile ps_2_0 BeamPS(1);
	}
}

technique TBeam_OneTexture_ADD
{
	pass P0
	{
		AlphaState( AlphaBlend_One_One_Write_RGBA )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 BeamVS();
		PixelShader = compile ps_2_0 BeamPS(1);
	}
}

technique TBeam_OneTexture_ALPHABLEND
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 BeamVS();
		PixelShader = compile ps_2_0 BeamPS(1);
	}
}

technique TBeam_OneTexture_PREMODALPHA
{
	pass P0
	{
		AlphaState( AlphaBlend_One_InvSrcAlpha_Write_RGBA )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 BeamVS();
		PixelShader = compile ps_2_0 BeamPS(1);
	}
}


// ********************************************************************************
// *** TBeam_TwoTexture
// ********************************************************************************
technique TBeam_TwoTexture_MODULATEINVERSE
{
	pass P0
	{
		AlphaState( AlphaBlend_Zero_InvSrcColor )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 BeamVS();
		PixelShader = compile ps_2_0 BeamPS(2);
	}
}

technique TBeam_TwoTexture_MODULATE2XINVERSE
{
	pass P0
	{
		AlphaState( AlphaBlend_InvDestColor_InvSrcColor )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 BeamVS();
		PixelShader = compile ps_2_0 BeamPS(2);
	}
}

technique TBeam_TwoTexture_ADD
{
	pass P0
	{
		AlphaState( AlphaBlend_One_One_Write_RGBA )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 BeamVS();
		PixelShader = compile ps_2_0 BeamPS(2);
	}
}

technique TBeam_TwoTexture_ALPHABLEND
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGBA )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 BeamVS();
		PixelShader = compile ps_2_0 BeamPS(2);
	}
}

technique TBeam_TwoTexture_PREMODALPHA
{
	pass P0
	{
		AlphaState( AlphaBlend_One_InvSrcAlpha_Write_RGBA )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 BeamVS();
		PixelShader = compile ps_2_0 BeamPS(2);
	}
}


// ********************************************************************************
// *** TPolyTrail
// ********************************************************************************
technique TPolyTrail_MODULATEINVERSE
{
	pass P0
	{
		AlphaState( AlphaBlend_Zero_InvSrcColor )
		DepthState( Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 TrailVS();
		PixelShader = compile ps_2_0 TrailPS();
	}
}

technique TPolyTrail_MODULATE2XINVERSE
{
	pass P0
	{
		AlphaState( AlphaBlend_InvDestColor_InvSrcColor )
		DepthState(	Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 TrailVS();
		PixelShader = compile ps_2_0 TrailPS();
	}
}

technique TPolyTrail_ADD
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_One )
		DepthState(	Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 TrailVS();
		PixelShader = compile ps_2_0 TrailPS();
	}
}

technique TPolyTrail_ALPHABLEND
{
	pass P0
	{
		AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
		DepthState(	Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 TrailVS();
		PixelShader = compile ps_2_0 TrailPS();
	}
}

technique TPolyTrail_PREMODALPHA
{
	pass P0
	{
		AlphaState( AlphaBlend_One_InvSrcAlpha_Write_RGB )
		DepthState(	Depth_Enable_Less_Write_None )
		RasterizerState( Rasterizer_Cull_None )

		VertexShader = compile vs_1_1 TrailVS();
		PixelShader = compile ps_2_0 TrailPS();
	}
}