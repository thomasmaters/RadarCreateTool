//
// clientshader.fx
//

float uNearClipPlane = 1.0;
float2  uPerspToOrtho = float2( 0,0 );

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

// Make everything all flashy!
float4 GetColor()
{
    return float4( cos(gTime*10), cos(gTime*7), cos(gTime*4), 1 );
}

float4x4 createProjectionMatrix(float left, float right, float top, float bottom, float n, float f)
{
    // Create a 4x4 projection matrix from given input

    float4x4 projectionMatrix = {
        float4(2 / (right - left), 	0,              	0,-((right + left) / (right - left))),
        float4(0,  2 / (top - bottom), 					0,-((top + bottom) / (top - bottom))),
        float4(0,       			0,		-2 / (f - n),-((f + n) / (f - n))),
        float4(0,              		0,             		0,  			1)
    };    
    return projectionMatrix;
}

PSInput VertexShaderFunction(VSInput VS)
{
    PSInput PS = (PSInput)0;
	
    float4 worldPos = mul(float4(VS.Position, 1), gWorld);

    // Create projection matrix
    float sFarClip = gProjectionMainScene[3][2] / (1 - gProjectionMainScene[2][2]);
    float sNearClip = gProjectionMainScene[3][2] / - gProjectionMainScene[2][2];
	float3 camDirection = gCameraDirection;
	
	
	float3 up = float3(0,1,0);
	float3 r = cross(camDirection,up);
	float3 l = -r;
	float3 t = cross(camDirection, r);
	float3 b = -t;
	
    float4x4 sProjection = createProjectionMatrix(l.x, r.x, t.y, b.y, 0.1, 1000);
	//float4x4 sProjection = createProjectionMatrix(-1280, 1280, -770, 770, 0.1, 100);
	float4 posWorldView = mul(worldPos, gView);
    PS.Position = mul(posWorldView, sProjection);;
    //PS.Position.z *= 0.00625 * 2;

    // Calculate screen pos of vertex
    //PS.Position = MTACalcScreenPosition ( VS.Position );

    // Pass through tex coords
    PS.TexCoord = VS.TexCoord;

    // Calc GTA lighting for peds
    PS.Diffuse = VS.Diffuse;

    return PS;
}

float4 PixelShaderFunction(PSInput PS) : COLOR0
{
    //-- Modify the texture coord to make the image look all wobbly
    //PS.TexCoord.y += sin(PS.TexCoord.y * 100 + gTime * 10) * 0.03;

    //-- Grab the pixel from the texture
    float4 finalColor = tex2D(Sampler0, PS.TexCoord);

    //-- Apply color tint
    //finalColor *= GetColor();

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


