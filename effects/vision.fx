////////////////////////////////////////////////////////////////////////////////
///
///	File	: vision.fx
///
///	Summary	: Effect file for rendering fog of war.
///	Note	: Similiar to range rendering but requires less data (and overhead.)
///
///	Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
////////////////////////////////////////////////////////////////////////////////

#define CCW_BOUNDARY_BIAS	 0.00001
#define CW_BOUNDARY_BIAS	-0.00001

float4x4 viewMatrix;
float4x4 projMatrix;

float3 boxCenter;
float3 boxExtent;

struct Vertex {
	float4 position : POSITION0;
};
typedef Vertex Pixel;

Vertex boundaryVertexShader( float3 vertex : POSITION0 )
{
	Vertex result = (Vertex)0;

	float3 position = boxExtent * vertex + boxCenter;
	result.position = mul(float4(position,1),mul(viewMatrix,projMatrix));

	return result;
}

Vertex visionVertexShader( float3 vertex : POSITION0, float2 position : POSITION1, float radius : TEXCOORD0 )
{
	Vertex result = (Vertex)0;

	vertex.xz = radius.xx * vertex.xz + position.xy;
	result.position = mul(float4(vertex,1),mul(viewMatrix,projMatrix));

	return result;
}

float4 pixelShader( Pixel pixel) : COLOR0
{
	return float4(0,0,0,0);
}

technique CastVision
{
	pass P0
	{
		CullMode = none;

		AlphaBlendEnable = false;
		AlphaTestEnable = false;

		ColorWriteEnable = 0x00;

		ZWriteEnable = false;
		ZEnable = true;
		ZFunc = less;

		StencilEnable = true;
		StencilWriteMask = 0xFF;
		StencilMask = 0xFF;
		StencilRef = 0x00;

		TwoSidedStencilMode = true;
		StencilFail = keep;
		StencilZFail = incr;
		StencilPass = keep;
		StencilFunc = always;
		CCW_StencilFail = keep;
		CCW_StencilZFail = decr;
		CCW_StencilPass = keep;
		CCW_StencilFunc = always;

		VertexShader = compile vs_2_0 visionVertexShader();
		PixelShader = compile ps_2_0 pixelShader();
	}
}

technique CastBoundaryCCW
{
	pass FrontFace
	{
		CullMode = CCW;

	    ColorWriteEnable = 0x00;
		DepthBias = CCW_BOUNDARY_BIAS;

		ZWriteEnable = false;
		ZEnable = true;
		ZFunc = less;

		StencilEnable = true;
		StencilWriteMask = 0xFF;
		StencilMask = 0xFF;
		StencilRef = 0x00;
		StencilFunc = always;
		StencilFail = keep;
		StencilZFail = incr;
		StencilPass = keep;

		VertexShader = compile vs_2_0 boundaryVertexShader();
		PixelShader = compile ps_2_0 pixelShader();
	}
	pass BackFace
	{
		CullMode = CW;

	    ColorWriteEnable = 0x00;
		DepthBias = CW_BOUNDARY_BIAS;

		ZWriteEnable = false;
		ZEnable = true;
		ZFunc = less;

		StencilEnable = true;
		StencilWriteMask = 0xFF;
		StencilMask = 0xFF;
		StencilRef = 0x00;
		StencilFunc = always;
		StencilFail = keep;
		StencilZFail = decr;
		StencilPass = keep;

		VertexShader = compile vs_2_0 boundaryVertexShader();
		PixelShader = compile ps_2_0 pixelShader();
	}
}

technique CastBoundaryCW
{
	pass FrontFace
	{
		CullMode = CW;

	    ColorWriteEnable = 0x00;
		DepthBias = CW_BOUNDARY_BIAS;

		ZWriteEnable = false;
		ZEnable = true;
		ZFunc = less;

		StencilEnable = true;
		StencilWriteMask = 0xFF;
		StencilMask = 0xFF;
		StencilRef = 0x00;
		StencilFunc = always;
		StencilFail = keep;
		StencilZFail = incr;
		StencilPass = keep;

		VertexShader = compile vs_2_0 boundaryVertexShader();
		PixelShader = compile ps_2_0 pixelShader();
	}
	pass BackFace
	{
		CullMode = CCW;

	    ColorWriteEnable = 0x00;
		DepthBias = CCW_BOUNDARY_BIAS;

		ZWriteEnable = false;
		ZEnable = true;
		ZFunc = less;

		StencilEnable = true;
		StencilWriteMask = 0xFF;
		StencilMask = 0xFF;
		StencilRef = 0x00;
		StencilFunc = always;
		StencilFail = keep;
		StencilZFail = decr;
		StencilPass = keep;

		VertexShader = compile vs_2_0 boundaryVertexShader();
		PixelShader = compile ps_2_0 pixelShader();
	}
}

