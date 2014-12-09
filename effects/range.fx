////////////////////////////////////////////////////////////////////////////////
///
///	File	: range.fx
///
///	Summary	: Effect file for rendering ranges (weapon, intel, etc)
///
///	Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
////////////////////////////////////////////////////////////////////////////////

float4x4 viewMatrix;
float4x4 projMatrix;

struct Vertex {
	float4 position : POSITION0;
};
typedef Vertex Pixel;

Vertex vertexShader( float3 vertex : POSITION0, float2 coeff : TEXCOORD0, float2 position : POSITION1, float2 radius : TEXCOORD1 )
{
	Vertex result = (Vertex)0;
	
	vertex.xz = ( coeff.xx * radius.xx + coeff.yy * radius.yy ) * vertex.xz + position.xy;
	result.position = mul(float4(vertex,1),mul(viewMatrix,projMatrix));
	
	return result;
}

float4 pixelShader( Pixel pixel) : COLOR0
{
	return float4(0,0,0,0);
}

technique Cast
{
	pass FrontFace
	{
		CullMode = CCW;
		
	    ColorWriteEnable = 0x00;

		ZWriteEnable = false;
		ZEnable = true;
		ZFunc = less;
		
		StencilEnable = true;
		StencilWriteMask = 0x7F;
		StencilMask = 0x80;
		StencilRef = 0xFF;
		StencilFunc = notequal;
		StencilFail = zero;
		StencilZFail = incr;
		StencilPass = keep;

		VertexShader = compile vs_2_0 vertexShader();
		PixelShader = compile ps_2_0 pixelShader();
	}
	pass BackFace
	{
		CullMode = CW;
		
	    ColorWriteEnable = 0x00;

		ZWriteEnable = false;
		ZEnable = true;
		ZFunc = less;
	    
		StencilEnable = true;
		StencilWriteMask = 0x7F;
		StencilMask = 0x80;
		StencilRef = 0xFF;
		StencilFunc = notequal;
		StencilFail = zero;
		StencilZFail = decr;
		StencilPass = keep;
		
		VertexShader = compile vs_2_0 vertexShader();
		PixelShader = compile ps_2_0 pixelShader();
	}
}
