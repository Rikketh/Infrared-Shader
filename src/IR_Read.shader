Shader "Custom/Alareis/Infrared/Read"
{
	Properties
	{
		[IntRange] _StencilRef ("Stencil Reference Value", Range(0,255)) = 0
	}
	SubShader
	{
		LOD 100
		ColorMask 0 // kills Fragment execution

		Tags{ "RenderType"="Transparent" "Queue"="Geometry-1"}
		ZTest LEqual
		ZWrite Off
		Cull Off

		Stencil{
			Ref [_StencilRef]
			Comp Always
			Pass Replace
		}

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag // ideally shouldn't run, but will use state switch regardlesss

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;

				UNITY_VERTEX_INPUT_INSTANCE_ID // SPSI
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;

				UNITY_VERTEX_OUTPUT_STEREO // SPSI
			};

			v2f vert (appdata v)
			{
				v2f o;

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i); // SPSI
				return fixed4(0,0,0,0);
			}
			ENDCG
		}
	}
}
