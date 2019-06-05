//
// radar_mask.fx
//

texture uCustomRadarTexturePart;

float uScreenHeight = 0;
float uScreenWidth = 0;

//Set these parameters with lua.
float uUVRotation = 0;
float2 uUVPosition = float2(0,0);

#include "mta-helper.fx"

// Returns 1 if point is inside ellipse, 0 otherwise.
float InsideEllipse(float center_x, float center_y, float el_width, float el_height, float x, float y){
    return floor((pow((x - center_x),2) / pow(el_width,2)) + (pow((y - center_y),2) / pow(el_height,2)));
}

//---------------------------------------------------------------------
// Sampler for the main texture
//---------------------------------------------------------------------
sampler Sampler0 = sampler_state
{
    Texture = (gTexture0);
	MinFilter = Linear;
    MagFilter = Linear;
    AddressU = Clamp; //Clamp so no tiling.
    AddressV = Clamp;
};

//---------------------------------------------------------------------
// Sampler for mask texture
//---------------------------------------------------------------------
sampler Sampler1 = sampler_state
{
    Texture = (uCustomRadarTexturePart);
	MinFilter = Linear;
    MagFilter = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
};


//---------------------------------------------------------------------
//-- Structure of data sent to the vertex shader
//---------------------------------------------------------------------
struct VSInput
{
  float3 Position : POSITION0;
  float4 Diffuse : COLOR0;
};

//---------------------------------------------------------------------
//-- Structure of data sent to the pixel shader ( from the vertex shader )
//---------------------------------------------------------------------
struct PSInput
{
  float4 Position : POSITION0;
  float4 Diffuse : COLOR0;
  float2 TexCoord : TEXCOORD0;
  float2 ScreenPosition : SV_POSITION;
};

PSInput VertexShaderFunction(VSInput VS)
{
    PSInput PS = (PSInput)0;
	
    PS.Position = MTACalcScreenPosition(VS.Position);

    PS.Diffuse = VS.Diffuse;
	
    return PS;
}

float4 PixelShaderFunction(PSInput PS) : COLOR0
{
	//Check if we are in the mask area.
    float inEllipse = InsideEllipse(0.5,0.5,0.85,0.85, PS.TexCoord.x - 0.5, PS.TexCoord.y - 0.5);
	
	//Normalize based on screen size.
    PS.ScreenPosition.x /= uScreenWidth;
    PS.ScreenPosition.y /= uScreenHeight;
	
	//Apply transforms.
    PS.ScreenPosition = rotate(PS.ScreenPosition,rot);
    PS.ScreenPosition += uvOffset;
    
	//Sample default texture at normal texture coordinates.
    float4 finalColor = tex2D(Sampler0, PS.TexCoord);
	
	//Sample based on screen position.
    float4 maskColor = tex2D(Sampler0, PS.ScreenPosition);
    
	//Combine texture colors.
    return finalColor * (inEllipse ? 1:0) + maskColor * (inEllipse ? 0:1);
}

technique tec0
{
    pass P1
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


