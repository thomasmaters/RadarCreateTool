//
// radar_mask.fx
//

float2 uUVPrePosition = float2( 0, 0 );
float2 uUVScale = float( 1 );                     // UV scale
float2 uUVScaleCenter = float2( 0.5, 0.5 );
float  uUVRotAngle = float( 0 );                   // UV Rotation
float2 uUVRotCenter = float2( 0.5, 0.5 );
float2 uUVPosition = float2( 0, 0 );              // UV position

texture uCustomRadarTexturePart;
float uScreenHeight = 0;
float uScreenWidth = 0;

#include "mta-helper.fx"

//-------------------------------------------
// Returns a translation matrix
//-------------------------------------------
float3x3 makeTranslationMatrix ( float2 pos )
{
    return float3x3(
                    1, 0, 0,
                    0, 1, 0,
                    pos.x, pos.y, 1
                    );
}


//-------------------------------------------
// Returns a rotation matrix
//-------------------------------------------
float3x3 makeRotationMatrix ( float angle )
{
    float s = sin(angle);
    float c = cos(angle);
    return float3x3(
                    c, s, 0,
                    -s, c, 0,
                    0, 0, 1
                    );
}


//-------------------------------------------
// Returns a scale matrix
//-------------------------------------------
float3x3 makeScaleMatrix ( float2 scale )
{
    return float3x3(
                    scale.x, 0, 0,
                    0, scale.y, 0,
                    0, 0, 1
                    );
}


//-------------------------------------------
// Returns a combined matrix of doom
//-------------------------------------------
float3x3 makeTextureTransform ( float2 prePosition, float2 scale, float2 scaleCenter, float rotAngle, float2 rotCenter, float2 postPosition )
{
    float3x3 matPrePosition = makeTranslationMatrix( prePosition );
    float3x3 matToScaleCen = makeTranslationMatrix( -scaleCenter );
    float3x3 matScale = makeScaleMatrix( scale );
    float3x3 matFromScaleCen = makeTranslationMatrix( scaleCenter );
    float3x3 matToRotCen = makeTranslationMatrix( -rotCenter );
    float3x3 matRot = makeRotationMatrix( rotAngle );
    float3x3 matFromRotCen = makeTranslationMatrix( rotCenter );
    float3x3 matPostPosition = makeTranslationMatrix( postPosition );

    float3x3 result =
                    mul(
                    mul(
                    mul(
                    mul(
                    mul(
                    mul(
                    mul(
                        matPrePosition
                        ,matToScaleCen)
                        ,matScale)
                        ,matFromScaleCen)
                        ,matToRotCen)
                        ,matRot)
                        ,matFromRotCen)
                        ,matPostPosition)
                    ;
    return result;
}

float InsideEllipse(float center_x, float center_y, float el_width, float el_height, float x, float y){
	float result = (pow((x - center_x),2) / pow(el_width,2)) + (pow((y - center_y),2) / pow(el_height,2));
	return result;
}

//---------------------------------------------------------------------
// Sampler for the main texture
//---------------------------------------------------------------------
sampler Sampler0 = sampler_state
{
    Texture = (gTexture0);
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

PSInput VertexShaderFunction(VSInput VS)
{
    PSInput PS = (PSInput)0;
	
    PS.Position = MTACalcScreenPosition(VS.Position);

    PS.TexCoord = VS.TexCoord;

    PS.Diffuse = VS.Diffuse;
	
    return PS;
}

float4 PixelShaderFunction(PSInput PS) : COLOR0
{
	float4 finalColor = tex2D(Sampler0, PS.TexCoord.xy);
	
	if (InsideEllipse(0.5,0.5,1 - 0.15,1 - 0.15, PS.TexCoord.x - 0.5, PS.TexCoord.y - 0.5) <= 1.1){
		finalColor = tex2D(Sampler1, PS.TexCoord);
	}
    return finalColor;
}

//-------------------------------------------
// Returns UV anim transform
//-------------------------------------------
float3x3 getTextureTransform ()
{
    float posU = -fmod( gTime/8 ,1 );    // Scroll Right
    float posV = 0;

    return float3x3(
                    1, 0, 0,
                    0, 1, 0,
                    posU, posV, 1
                    );
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


