Shader "Custom/Alareis/Infrared/Write"{
	Properties{
		_Color ("Tint", Color) = (1,1,1,1)
		// R = glow power
		// G = strobe XY pattern
		// B = strobe mask
		// A = opacity mask
		// ! all values are linear
		_IRMask("IR Mask", 2D) = "white" {}
		_GlowFactor("Glow Factor", Range(0, 53)) = 1.0
		_ScanSpeed("Scan speed", Float) = (1.0, 1.0, 0, 0)
		_Alpha("Opacity factor", Range(0, 1)) = 1.0
		[IntRange] _StencilRef ("Stencil Reference Value", Range(0,255)) = 0
		[ToggleUI] _StrobeComposition_Multiplicative("Multiplicative Strobe Composition", Int) = 0
	}

	SubShader{
		Tags
		{ 
			"RenderType"="Transparent"
			"Queue"="Transparent+2"
			"IgnoreProjector"="True"
			// "PreviewType"="Plane"
		}
		ZTest On
		// ZWrite Off
		Lighting Off
		// Blend One OneMinusSrcAlpha // premultiplied alpha
		Blend SrcAlpha OneMinusSrcAlpha // straight alpha
		Offset -1, -1 // force any possible depth geometry conflicts by moving it closer since geometry shares position

		Stencil{
			Ref [_StencilRef]
			Comp Equal
			Pass Keep
			Fail Keep
		}

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float4 vcol : COLOR;
				float2 uv : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID // SPSI
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float4 vcolor : COLOR;

				UNITY_VERTEX_OUTPUT_STEREO // SPSI
			};

			Texture2D _IRMask;
			SamplerState sampler_IRMask;
			float4 _IRMask_ST;

			uniform float4 _Color, _ScanSpeed;
			uniform float _GlowFactor, _Alpha;

			uniform bool _StrobeComposition_Multiplicative;

			v2f vert (appdata v)
			{
				v2f o;

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);


				o.vertex = UnityObjectToClipPos(v.vertex);
				o.vcolor = v.vcol;
				o.uv = TRANSFORM_TEX(v.uv, _IRMask);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i); // SPSI

				float4 input = _IRMask.Sample(sampler_IRMask, i.uv);
				float glowPower = input.r * _GlowFactor; // "reflectance" level (IRD.r)
				float strobeMask = input.b;
				float packedOpacity = input.a;

				float4 flickerUVs = float4(
					frac(_Time.y * _ScanSpeed.x), // move uv.x left/right at this Hz
					frac(_Time.y * _ScanSpeed.y), // same, but uv.y up/down
					_IRMask_ST.x, // copies tiling
					_IRMask_ST.y  // again
				);
				float flicker = _IRMask.Sample(sampler_IRMask, flickerUVs).g;

				// ? UNITY_BRANCH // phased out by GCN lmao
				// ? on UNITY_BRANCH: https://forum.unity.com/threads/correct-use-of-unity_branch.476804/#post-3108460
				// this controls how the strobe effect will apply itself to the surface
				if (_StrobeComposition_Multiplicative) {
					// this will take straight value of IRD.g and multiply it with your base colour
					flicker *= glowPower;
				} else {
					// otherwise you'll add more into HDR space
					flicker += glowPower;
				}

				// and only use strobe-corrected colour over areas masked by the strobe mask (IRD.b)
				float strobe = lerp(glowPower, flicker, strobeMask);

				fixed4 col = fixed4(0,0,0,0);
				// strobe is monochromatic, render it as uniform, mix _Color and vertex colour for component compat
				col.rgb = strobe.xxx * _Color.rgb * i.vcolor.rgb;
				// mix alpha with _Color's alpha, vertex alpha, and scalar alpha factor
				col.a = packedOpacity * _Color.a * i.vcolor.a * _Alpha; // animate opacity in a clip with _Alpha

				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}