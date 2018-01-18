Shader "Unlit/Height Map Shader"
{
	Properties
	{
		_Tint ("Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Albedo", 2D) = "White"{}
		[NoScaleOffset]_HeightMap ("Heights", 2D) = "gray"{}
		_Smoothness ("Smoothness", Range(0, 1)) = 0.5
		_SpecularTint ("Specular", Color) = (0.5, 0.5, 0.5)
		//[Gamma]_Metallic ("Matallic", Range(0, 1)) = 0 
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
			float4 _MainTex_ST;
			float4 _Tint;
			float _Smoothness;
			float4 _SpecularTint;
			sampler2D _HeightMap;
			float4 _HeightMap_TexelSize;

			//float _Metallic;


			struct Interpolators
			{
				float4 position : SV_POSITION; // in Fragment Shader
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float3 worldPos : TEXCOORD1;
			};

			struct VertexData
			{
				float4 position : POSITION; // object-space coordinate
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			void InitializeFragmentNormal(inout Interpolators i)
			{
				float2 du = float2(_HeightMap_TexelSize.x*0.5, 0);
				float u1 = tex2D(_HeightMap, i.uv - du);
				float u2 = tex2D(_HeightMap, i.uv + du);
				
				float3 tangent = float3(1, u2 - u1, 0);

				float2 dv = float2(0, _HeightMap_TexelSize.x*0.5);
				float v1 = tex2D(_HeightMap, i.uv - dv);
				float v2 = tex2D(_HeightMap, i.uv + dv);

				float3 bitangent = float3(0, v2 - v1, 1);
				i.normal = cross(bitangent, tangent);
				i.normal = normalize(i.normal);
			}

			Interpolators MyVertexProgram(VertexData v)
			{
				Interpolators i;

				i.position = mul(UNITY_MATRIX_MVP, v.position); // MVP
				i.uv = TRANSFORM_TEX(v.uv, _MainTex);
				i.worldPos = mul(unity_ObjectToWorld, v.position); // object position to world position
				i.normal = UnityObjectToWorldNormal(v.normal); //object normal to world normal
	

				return i;
			}

			float4 MyFragmentProgram(Interpolators i) : SV_TARGET
			{
				//i.normal = normalize(i.normal);
				InitializeFragmentNormal(i);

				float3 lightDir = _WorldSpaceLightPos0.xyz; // Directional lights: (world space direction, 0). Other lights: (world space position, 1).
				float3 lightColor = _LightColor0.rgb;
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
				float3 reflectionDir = reflect(-lightDir, i.normal);
				float3 halfVector = normalize(lightDir + viewDir); // Blinn-Phong require
				float oneMinusReflectivity = 1 - max(_SpecularTint.r, max(_SpecularTint.g, _SpecularTint.b)); // energy between diffuse and specular should be 1
				
				
				
				float3 albedo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb; 
				//albedo *= tex2D(_HeightMap, i.uv);
				albedo *= oneMinusReflectivity; // energy between diffuse and specular should be 1
				//albedo = EnergyConservationBetweenDiffuseAndSpecular(albedo, _SpecularTint.rgb, oneMinusReflectivity); // energy between diffuse and specular should be 1
				//albedo *= oneMinusReflectivity;
				//float3 specularTint;
				//float oneMinusReflectivity;
				float3 ka = (0.15, 0.15, 0.15);
				float3 ambient = ka* albedo;

				//albedo = DiffuseAndSpecularFromMetallic(albedo, _Metallic, specularTint, oneMinusReflectivity); // energy between diffuse and specular should be 1

				

				float3 diffuse = albedo * lightColor * DotClamped(lightDir, i.normal);
				//float3 specular = lightColor *pow(DotClamped(reflectionDir, viewDir), _Smoothness * 100); // Phong shading
				float3 specular = lightColor * pow(DotClamped(halfVector, i.normal), _Smoothness * 100) * _SpecularTint.rgb; // Blinn-Phong
				//float3 specular = lightColor * pow(DotClamped(halfVector, i.normal), _Smoothness * 100) * specularTint; // Blinn-Phong
				
				return float4 (ambient + specular + diffuse, 1);

			}

				ENDCG
		}
	}
}