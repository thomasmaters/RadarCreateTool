//
// clientshader.fx
//

bool uLighting = true;
bool uEqualColor = false;
float uScreenHeight = 1080.0;
float uScreenWidth = 1920.0;

float uZoom = 2.0;
float uFarClip = 1000.0;
float uNearClip = 0.1;
float uSaturation = 1.0;

float uTextureCompressDistance = 0.1;

#include "mta-helper.fx"
matrix gProjectionMainScene : PROJECTION_MAIN_SCENE;

//---------------------------------------------------------------------
// Sampler for the main texture
//---------------------------------------------------------------------
sampler Sampler0 = sampler_state
{
    Texture = (gTexture0);
};


//---------------------------------------------------------------------
//-- Structure of data sent to the vertex shader
//---------------------------------------------------------------------
struct VSInput
{
  float3 Position : POSITION0;
  float3 Normal : NORMAL0;
  float4 Diffuse : COLOR0;
  float2 TexCoord : TEXCOORD0;
};

//---------------------------------------------------------------------
//-- Structure of data sent to the pixel shader ( from the vertex shader )
//---------------------------------------------------------------------
struct PSInput
{
  float4 Position : POSITION0;
  float4 Diffuse : COLOR0;
  float2 TexCoord : TEXCOORD0;
};

float3 saturation(float3 rgb)
{
    // Algorithm from Chapter 16 of OpenGL Shading Language
    const float3 W = float3(0.2125, 0.7154, 0.0721);
	float dotProduct = dot(rgb, W);
    float3 intensity = float3(dotProduct,dotProduct,dotProduct);
    return lerp(intensity, rgb, uSaturation);
}

float4x4 createProjectionMatrix()
{
    // Create a 4x4 projection matrix from given input
	float4x4 K = {
		float4(0.63281273 / uScreenHeight * uZoom,0,0,0),
		float4(0,2.0 / uScreenWidth * uZoom,0,0),
		float4(0,0,1.0 / (uFarClip - uNearClip), -uNearClip/(uFarClip-uNearClip)),
		float4(0,0,0,1)
	};
	
    return K;
}

PSInput VertexShaderFunction(VSInput VS)
{
    PSInput PS = (PSInput)0;
	
    float4 worldPos = mul(float4(VS.Position, 1), gWorld);
	worldPos.z = worldPos.z * uTextureCompressDistance/200.0;
	
    float4x4 sProjection = createProjectionMatrix();
	float4 posWorldView = mul(worldPos, gView);
    PS.Position = mul(posWorldView, sProjection);

    // Pass through tex coords
    PS.TexCoord = VS.TexCoord;

    // Calc GTA lighting for peds
    PS.Diffuse = VS.Diffuse;
	
    return PS;
}

float4 PixelShaderFunction(PSInput PS) : COLOR0
{
	float4 finalColor;
	
	if(uEqualColor == true){
	    finalColor = tex2D(Sampler0, float2(25,25));
	}else{
		finalColor = tex2D(Sampler0, PS.TexCoord);
	}
	
	if(uLighting == true){
		finalColor *= PS.Diffuse;
	}
	
	finalColor.xyz = saturation(finalColor.xyz);

    return finalColor;
}

technique tec0
{
    pass P0
    {
        VertexShader = compile vs_2_0 VertexShaderFunction();
		PixelShader  = compile ps_2_0 PixelShaderFunction();
    }
}

// Fallback
technique fallback
{
    pass P0
    {
        // Just draw normally
    }
}


