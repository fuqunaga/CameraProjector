Shader "RoundCamera/CameraProjector" {
	Properties {
		_ProjectorTex("ProjectorTex", 2D) = "white" {}
		[Toggle] EDGE_FADE("EdgeFade", Float) = 0
		[Toggle(TEX_Y_INVERSE)] TEX_Y_INVERSE("TexYInverse", Float) = 0
		_OverlapUV("OverlapUV", Range(0,0.001)) = 0
	}
	Subshader {
		Tags {"Queue"="Geometry"}
		Pass {
			//ZWrite Off
			//ColorMask RGB
			Blend SrcAlpha OneMinusSrcAlpha
			//ZTest Always


			CGPROGRAM
			#pragma multi_compile _ EDGE_FADE
			#pragma multi_compile _ TEX_Y_INVERSE
			#pragma target 5.0
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			#if defined(EDGE_FADE)
			#define USE_WPOS
			#endif

			struct appdata {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float4 uvShadow : TEXCOORD1;
			#ifdef USE_WPOS
				float4 wPos : TEXCOORD2;
			#endif
			};
			
			float4x4 _ProjectorVPMatrix;
			sampler2D _ProjectorTex;
			float _OverlapUV;

			#ifdef EDGE_FADE
			float4 _EdgeFade; // x:startY y:endY z:gamma
			fixed4 _EdgeFadeColor;
			fixed4 CalcEdgeFadeColor(fixed4 col, v2f i)
			{
				half col_rate = 1- smoothstep(_EdgeFade.x, _EdgeFade.y, i.wPos.y);
				return lerp(_EdgeFadeColor, col, pow(col_rate, _EdgeFade.z));
			}
			#endif

			

			v2f vert (appdata i)
			{
				v2f o;
				o.pos = UnityObjectToClipPos (i.vertex);
				o.uv = i.texcoord;
				float4 wPos = mul(unity_ObjectToWorld, i.vertex);
				o.uvShadow = mul (_ProjectorVPMatrix, wPos);

				#ifdef USE_WPOS
				o.wPos = wPos;
				#endif

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				half2 uvShadow = ((i.uvShadow.xy / i.uvShadow.w) + 1) * 0.5;
				#if TEX_Y_INVERSE
				uvShadow.y = 1 - uvShadow.y;
				#endif

				if (
					(i.uvShadow.z < 0)
					|| any(uvShadow < -_OverlapUV)  // 0だと他のProjectorとの境界部分で微妙にカバーできないことがあるのでほんの少し領域を広げる
					|| any(1 <= uvShadow)
					) discard;

				fixed4 texS = tex2D(_ProjectorTex, uvShadow);
				fixed4 col = texS;

				#ifdef EDGE_FADE
				col = CalcEdgeFadeColor(col, i);
				#endif

				return col;
			}
			ENDCG
		}
	}
}
