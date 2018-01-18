Shader "Unlit/Transparent"
{
	Properties
	{
		_Color("Main Tint",Color) = (1,1,1,1)
		_MainTex("Main Tex",2D) = "white"{}
		_Cutoff("Alpha Cutoff", Range(0,1)) = 0.5
		_AlphaScale("Alpha Scale",Range(0,1)) = 1

	}
		SubShader
		{
			Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}

			/*Pass
			{
				ZWrite On
				ColorMask 0
		
			}*/	


			Pass
			{
				Tags{"LightMode" = "ForwardBase"}

				
				Cull Front
				Blend SrcAlpha OneMinusSrcAlpha
				ZWrite Off

				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "Lighting.cginc"

				float4 _Color;
				sampler2D _MainTex;
				float _Cutoff;
				float4 _MainTex_ST;
				float _AlphaScale;

				struct Interpolators
				{
					float4 position : SV_POSITION;
					float2 uv : TEXCOORD0;
					float3 normal : TEXCOORD1;
					float3 worldPos : TEXCOORD2;
				};

				struct VertexData
				{
					float4 position : POSITION;
					float4 normal : NORMAL;
					float2 uv : TEXCOORD0;
				};

				Interpolators vert(VertexData v)
				{
					Interpolators i;
					i.position = mul(UNITY_MATRIX_MVP, v.position);
					i.uv = TRANSFORM_TEX(v.uv, _MainTex);
					i.normal = UnityObjectToWorldNormal(v.normal);
					i.worldPos = i.worldPos = mul(unity_ObjectToWorld, v.position);

					return i;
				}

				float4 frag(Interpolators i) : SV_TARGET
				{
					float3 worldNormal = normalize(i.normal);
					float3 worldLightDir = _WorldSpaceLightPos0.xyz;
					float4 texColor = tex2D(_MainTex, i.uv);

					//clip(texColor.a - _Cutoff);

					float3 albedo = texColor.rgb*_Color.rgb;
					float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
					float3 diffuse = _LightColor0.rgb * albedo * DotClamped(worldLightDir, worldNormal);
				
					return float4(ambient + diffuse, texColor.a * _AlphaScale);

					//return float4(ambient + diffuse, 1);
				}
				ENDCG
			}

			Pass
				{
					Tags{ "LightMode" = "ForwardBase" }

					
					Cull Back
					Blend SrcAlpha OneMinusSrcAlpha
					ZWrite Off

					CGPROGRAM
					#pragma vertex vert
					#pragma fragment frag

					#include "Lighting.cginc"

					float4 _Color;
					sampler2D _MainTex;
					float _Cutoff;
					float4 _MainTex_ST;
					float _AlphaScale;

				struct Interpolators
				{
					float4 position : SV_POSITION;
					float2 uv : TEXCOORD0;
					float3 normal : TEXCOORD1;
					float3 worldPos : TEXCOORD2;
				};

				struct VertexData
				{
					float4 position : POSITION;
					float4 normal : NORMAL;
					float2 uv : TEXCOORD0;
				};

				Interpolators vert(VertexData v)
				{
					Interpolators i;
					i.position = mul(UNITY_MATRIX_MVP, v.position);
					i.uv = TRANSFORM_TEX(v.uv, _MainTex);
					i.normal = UnityObjectToWorldNormal(v.normal);
					i.worldPos = i.worldPos = mul(unity_ObjectToWorld, v.position);

					return i;
				}

				float4 frag(Interpolators i) : SV_TARGET
				{
					float3 worldNormal = normalize(i.normal);
					float3 worldLightDir = _WorldSpaceLightPos0.xyz;
					float4 texColor = tex2D(_MainTex, i.uv);

					//clip(texColor.a - _Cutoff);

					float3 albedo = texColor.rgb*_Color.rgb;
					float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
					float3 diffuse = _LightColor0.rgb * albedo * DotClamped(worldLightDir, worldNormal);

					return float4(ambient + diffuse, texColor.a * _AlphaScale);

					return float4(ambient + diffuse, 1);
				}
					ENDCG
				}

			
		}

			FallBack "Transparent/VertexLit"
}
