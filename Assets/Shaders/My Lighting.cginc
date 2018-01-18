// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

#if !defined(MY_LIGHTING_INCLUDED)
#define MY_LIGHTING_INCLUDED

#include "AutoLight.cginc"
#include "UnityPBSLighting.cginc"

float4 _Tint;
sampler2D _MainTex, _NormalMap;
float4 _MainTex_ST;

float _Metallic;
float _Smoothness;
float _BumpScale;

struct VertexData {
	float4 position : POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
	float4 tangent : TANGENT;
};

struct Interpolators {
	float4 position : SV_POSITION;
	float2 uv : TEXCOORD0;
	float3 normal : TEXCOORD1;
	float3 worldPos : TEXCOORD2;
	float4 tangent : TEXCOORD4;

	#if defined(VERTEXLIGHT_ON)
		float3 vertexLightColor : TEXCOORD3;
	#endif
};

void ComputeVertexLightColor (inout Interpolators i) 
{
	/*
	#if defined(VERTEXLIGHT_ON)
		i.vertexLightColor = Shade4PointLights(
			unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
			unity_LightColor[0].rgb, unity_LightColor[1].rgb,
			unity_LightColor[2].rgb, unity_LightColor[3].rgb,
			unity_4LightAtten0, i.worldPos, i.normal
		);
	#endif
	*/
}

Interpolators MyVertexProgram (VertexData v) {
	Interpolators i;
	i.position = UnityObjectToClipPos(v.position);
	i.worldPos = mul(unity_ObjectToWorld, v.position);
	i.normal = UnityObjectToWorldNormal(v.normal);
	i.uv = TRANSFORM_TEX(v.uv, _MainTex);
	i.tangent = float4 (UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
	ComputeVertexLightColor(i);
	return i;
}

UnityLight CreateLight (Interpolators i) {
	UnityLight light;

	#if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
		light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
	#else
		light.dir = _WorldSpaceLightPos0.xyz;
	#endif
	
	UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos);
	light.color = _LightColor0.rgb * attenuation;
	light.ndotl = DotClamped(i.normal, light.dir);
	return light;
}

float3 BoxProjection(float3 direction, float3 position, float3 cubemapPosition, float3 boxMin, float3 boxMax)
{
	boxMin -= -position;
	boxMax -= -position;


	float x = (direction.x > 0 ? boxMax.x : boxMin.x) / direction.x;
	float y = (direction.y > 0 ? boxMax.y : boxMin.y) / direction.y;
	float z = (direction.z > 0 ? boxMax.z : boxMin.z) / direction.z;
	float scalar = min(min(x, y), z);

	return direction * scalar + (position - cubemapPosition);

	//return direction;
}

UnityIndirect CreateIndirectLight (Interpolators i, float3 viewDir) {
	UnityIndirect indirectLight;
	indirectLight.diffuse = 0;
	indirectLight.specular = 0;

	#if defined(VERTEXLIGHT_ON)
		indirectLight.diffuse = i.vertexLightColor;
	#endif

	#if defined(FORWARD_BASE_PASS)

		
		

		indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));
		float3 reflectionDir = reflect(-viewDir, i.normal);

		//float roughness = 1 - _Smoothness;
		//roughness *= 1.7 - 0.7 * roughness;

		//float4 envSample = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectionDir, roughness * UNITY_SPECCUBE_LOD_STEPS);
		//indirectLight.specular = DecodeHDR(envSample, unity_SpecCube0_HDR);
		Unity_GlossyEnvironmentData envData;
		envData.roughness = 1 - _Smoothness;
		//envData.reflUVW = reflectionDir;

		envData.reflUVW = BoxProjection(
			reflectionDir, i.worldPos,
			unity_SpecCube0_ProbePosition,
			unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
			);

		indirectLight.specular = Unity_GlossyEnvironment(
			UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData
			);

		//indirectLight.specular = envSample.xyz;

	#endif

	return indirectLight;
}

void InitializeFragmentNormal(inout Interpolators i)
{
	float3 bumpNormal;
	bumpNormal.xy = tex2D(_NormalMap, i.uv).wy * 2 - 1;
	bumpNormal *= _BumpScale;
	bumpNormal.z = max(0, sqrt(1 - (pow(bumpNormal.x, 2) + pow(bumpNormal.y, 2))));


	float3 bitangent = cross(i.tangent.xyz, i.normal) * i.tangent.w;
	//float3 bitangent = cross(i.normal, i.tangent.xyz) * i.tangent.w;
	i.normal = normalize(i.normal);
	bitangent = normalize(bitangent);
	bumpNormal = normalize(bumpNormal);

	i.normal = normalize(bumpNormal.x * i.tangent.xyz + bumpNormal.z * i.normal + bumpNormal.y * bitangent);


}

float4 MyFragmentProgram (Interpolators i) : SV_TARGET {

	InitializeFragmentNormal(i);

	i.normal = normalize(i.normal);

	float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

	float3 albedo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;

	float3 specularTint;
	float oneMinusReflectivity;
	albedo = DiffuseAndSpecularFromMetallic(
		albedo, _Metallic, specularTint, oneMinusReflectivity
	);

	return UNITY_BRDF_PBS(
		albedo, specularTint,
		oneMinusReflectivity, _Smoothness,
		i.normal, viewDir,
		CreateLight(i), CreateIndirectLight(i, viewDir)
	);
}

#endif