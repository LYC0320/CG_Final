Shader "Unlit/Normal Map Shader"
{
	Properties
	{
		_Tint ("Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Albedo", 2D) = "White"{}
		_DetailTex ("Detail Texture", 2D) = "gray"{}
		[NoScaleOffset]_NormalMap ("Normals", 2D) = "bump"{}
		[NoScaleOffset]_DetailNormalMap ("Detail Normals", 2D) = "bump"{}
		_Smoothness("Smoothness", Range(0, 1)) = 0.5
		_SpecularTint("Specular", Color) = (0.5, 0.5, 0.5)
		_BumpScale("Bump Scale", Range(0, 3)) = 1
		_DetailBumpScale("Detail Bump Scale", Range(0, 3)) = 0.3

	}

	SubShader
	{
		Pass
		{
		
			Tags
			{
				"LightMode" = "ForwardBase"
			}
			
			CGPROGRAM

			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			#include "UnityStandardBRDF.cginc"
			#include "UnityStandardUtils.cginc"

			sampler2D _MainTex;
			sampler2D _DetailTex;
			float4 _MainTex_ST, _DetailTex_ST;
			float4 _Tint;
			float _Smoothness;
			float4 _SpecularTint;
			sampler2D _NormalMap, _DetailNormalMap;
			float _BumpScale, _DetailBumpScale;
			

	

			struct Interpolators
			{
				float4 position : SV_POSITION; // in Fragment Shader
				float4 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float3 worldPos : TEXCOORD1;
				float4 tangent : TEXCOORD2;
			};

			struct VertexData
			{
				float4 position : POSITION; // object-space coordinate
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			void InitializeFragmentNormal(inout Interpolators i)
			{
				float3 detailNormal;
				detailNormal.xy = tex2D(_DetailNormalMap, i.uv.zw).wy * 2 - 1;
				detailNormal *= _DetailBumpScale;
				detailNormal.z = max(0, sqrt(1 - (pow(detailNormal.x, 2) + pow(detailNormal.y, 2))));


				float3 mainNormal;
				mainNormal.xy = tex2D(_NormalMap, i.uv.xy).wy * 2 - 1; // because they are stored as n+1/2 and x->g y->alpha.
				mainNormal *= _BumpScale; // z will decrease so it looks darker
				mainNormal.z = max(0, sqrt(1 - (pow(mainNormal.x, 2) + pow(mainNormal.y, 2)))); // z can be computed because it have been normalized.


				float3 tangentSpaceNormal;
				tangentSpaceNormal = float3(mainNormal.xy + detailNormal.xy, mainNormal.z * detailNormal.z); // blending normal
				tangentSpaceNormal = tangentSpaceNormal.xzy; // unity's up is y axis
				

				

				float3 bitangent = cross(i.tangent.xyz, i.normal) * i.tangent.w;
				
				// normalize vector
				i.normal = normalize(i.normal);
				bitangent = normalize(bitangent);
				tangentSpaceNormal = normalize(tangentSpaceNormal);

				i.normal = normalize(tangentSpaceNormal.x * i.tangent.xyz + tangentSpaceNormal.z * bitangent + tangentSpaceNormal.y * i.normal); // normal is composed of three vector in tangentspace.
				i.normal = normalize(i.normal);
			}

			Interpolators MyVertexProgram(VertexData v)
			{
				Interpolators i;

				i.position = mul(UNITY_MATRIX_MVP, v.position); // MVP
				i.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				i.uv.zw = TRANSFORM_TEX(v.uv, _DetailTex);
				i.worldPos = mul(unity_ObjectToWorld, v.position); // object position to world position
				i.normal = UnityObjectToWorldNormal(v.normal); //object normal to world normal
				i.tangent = float4 (UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
	

				return i;
			}

			float4 MyFragmentProgram(Interpolators i) : SV_TARGET
			{
			
				InitializeFragmentNormal(i);

				float3 lightDir = _WorldSpaceLightPos0.xyz; // Directional lights: (world space direction, 0). Other lights: (world space position, 1).
				float3 lightColor = _LightColor0.rgb;
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
				float3 reflectionDir = reflect(-lightDir, i.normal);
				float3 halfVector = normalize(lightDir + viewDir); // Blinn-Phong require
				float oneMinusReflectivity = 1 - max(_SpecularTint.r, max(_SpecularTint.g, _SpecularTint.b)); // energy between diffuse and specular should be 1
				
				
				
				float3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Tint.rgb * tex2D(_DetailTex, i.uv.zw) * unity_ColorSpaceDouble;
				
				albedo *= oneMinusReflectivity; // energy between diffuse and specular should be 1
				
				float3 ka = (0.15, 0.15, 0.15);
				float3 ambient = ka* albedo;

				
				float3 diffuse = albedo * lightColor * DotClamped(lightDir, i.normal);
			
				float3 specular = lightColor * pow(DotClamped(halfVector, i.normal), _Smoothness * 100) * _SpecularTint.rgb; // Blinn-Phong
			
				
				return float4 (ambient + specular + diffuse, 1);

			}

				ENDCG
		}
	}
}