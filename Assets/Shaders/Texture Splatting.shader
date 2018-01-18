Shader "Unlit/Texture Splatting"
{
	Properties
	{
		_MainTex("Splat Map", 2D) = "White"{}
		[NoScaleOffset] _Texture1("Texture 1", 2D) = "White"{}
		[NoScaleOffset] _Texture2("Texture 2", 2D) = "White"{}
		[NoScaleOffset] _Texture3("Texture 3", 2D) = "White"{}
		[NoScaleOffset] _Texture4("Texture 4", 2D) = "White"{}
	}

		SubShader
	{
		Pass
		{
			CGPROGRAM

#pragma vertex MyVertexShader
#pragma fragment MyFragmentShader

#include "UnityCG.cginc"

			sampler2D _MainTex;
			sampler2D _Texture1, _Texture2, _Texture3, _Texture4;
			float4 _MainTex_ST;

			struct Interpolators
			{
				float4 position : SV_POSITION;
				float2 uv : TEXCOORD0;
				float2 uvSplat : TEXCOORD1;
			};

			struct VertexData
			{
				float4 position : POSITION;
				float2 uv : TEXCOORD0;
			};

			Interpolators MyVertexShader(VertexData v)
			{
				Interpolators i;
				i.position = UnityObjectToClipPos(v.position);
				i.uv = TRANSFORM_TEX(v.uv, _MainTex);
				i.uvSplat = v.uv;

				return i;
			}

			float4 MyFragmentShader(Interpolators i) : SV_TARGET
			{
				float4 splat = tex2D(_MainTex, i.uvSplat); // rgb-map

				return
				tex2D(_Texture1, i.uv) * splat.r +
				tex2D(_Texture2, i.uv) * splat.g +
				tex2D(_Texture3, i.uv) * splat.b +
				tex2D(_Texture4, i.uv) * (1 - splat.r - splat.g - splat.b);
			}

				ENDCG
		}
	}
}
