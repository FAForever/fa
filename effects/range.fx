////////////////////////////////////////////////////////////////////////////////
///
///  File  : range.fx
///
///  Summary  : Effect file for rendering ranges (weapon, intel, etc)
///
///  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
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

  vertex.xz = dot(coeff, radius) * vertex.xz + position.xy;
  result.position = mul(float4(vertex,1),mul(viewMatrix,projMatrix));
  return result;
}

technique Cast
{
  pass P0
  {
    CullMode = none;

    ColorWriteEnable = 0x00;

    ZWriteEnable = false;
    ZEnable = true;
    ZFunc = less;

    StencilEnable = true;
    StencilWriteMask = 0x7F;
    StencilRef = 0xFF;
    StencilMask = 0x80;

    TwoSidedStencilMode = true;
    StencilFail = zero;
    StencilZFail = incr;
    StencilPass = keep;
    StencilFunc = notequal;
    CCW_StencilFail = keep;
    CCW_StencilZFail = decr;
    CCW_StencilPass = keep;
    CCW_StencilFunc = notequal;

    VertexShader = compile vs_2_0 vertexShader();
  }
}
