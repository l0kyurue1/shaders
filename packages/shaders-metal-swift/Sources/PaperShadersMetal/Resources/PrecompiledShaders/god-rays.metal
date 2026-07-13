#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct Params
{
    float u_time;
    float4 u_colorBack;
    float4 u_colorBloom;
    float4 u_colors[5];
    float u_colorsCount;
    float u_density;
    float u_spotty;
    float u_midSize;
    float u_midIntensity;
    float u_intensity;
    float u_bloom;
};

struct main0_out
{
    float4 fragColor [[color(0)]];
};

struct main0_in
{
    float2 v_objectUV [[user(locn0)]];
};

static inline __attribute__((always_inline))
float2 rotate(thread const float2& uv, thread const float& th)
{
    return float2x2(float2(cos(th), sin(th)), float2(-sin(th), cos(th))) * uv;
}

static inline __attribute__((always_inline))
float hash11(thread float& p)
{
    p = fract(p * 0.3183099) + 0.1;
    p *= (p + 19.19);
    return fract(p * p);
}

static inline __attribute__((always_inline))
float randomR(thread const float2& p, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    float2 uv = (floor(p) / float2(100.0)) + float2(0.5);
    return u_noiseTexture.sample(u_noiseTextureSmplr, fract(uv)).x;
}

static inline __attribute__((always_inline))
float valueNoise(thread const float2& st, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    float2 i = floor(st);
    float2 f = fract(st);
    float2 param = i;
    float a = randomR(param, u_noiseTexture, u_noiseTextureSmplr);
    float2 param_1 = i + float2(1.0, 0.0);
    float b = randomR(param_1, u_noiseTexture, u_noiseTextureSmplr);
    float2 param_2 = i + float2(0.0, 1.0);
    float c = randomR(param_2, u_noiseTexture, u_noiseTextureSmplr);
    float2 param_3 = i + float2(1.0);
    float d = randomR(param_3, u_noiseTexture, u_noiseTextureSmplr);
    float2 u = (f * f) * (float2(3.0) - (f * 2.0));
    float x1 = mix(a, b, u.x);
    float x2 = mix(c, d, u.x);
    return mix(x1, x2, u.y);
}

static inline __attribute__((always_inline))
float raysShape(thread const float2& uv, thread const float& r, thread const float& freq, thread const float& intensity, thread const float& radius, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    float a = precise::atan2(uv.y, uv.x);
    float2 left = float2(a * freq, r);
    float2 right = float2((fract(a / 6.2831855) * 6.2831855) * freq, r);
    float2 param = left;
    float n_left = powr(valueNoise(param, u_noiseTexture, u_noiseTextureSmplr), intensity);
    float2 param_1 = right;
    float n_right = powr(valueNoise(param_1, u_noiseTexture, u_noiseTextureSmplr), intensity);
    float shape = mix(n_right, n_left, smoothstep(-0.15, 0.15, uv.x));
    return shape;
}

fragment main0_out main0(main0_in in [[stage_in]], constant Params& params [[buffer(0)]], texture2d<float> u_noiseTexture [[texture(0)]], sampler u_noiseTextureSmplr [[sampler(0)]], float4 gl_FragCoord [[position]])
{
    main0_out out = {};
    float2 shape_uv = in.v_objectUV;
    float t = 0.2 * params.u_time;
    float radius = length(shape_uv);
    float spots = 6.5 * abs(params.u_spotty);
    float intensity = 4.0 - (3.0 * fast::clamp(params.u_intensity, 0.0, 1.0));
    float delta = 1.0 - smoothstep(0.0, 1.0, radius);
    float midSize = 10.0 * abs(params.u_midSize);
    float ms_lo = 0.02 * midSize;
    float ms_hi = fast::max(midSize, 0.000001);
    float middleShape = powr(params.u_midIntensity, 0.3) * (1.0 - smoothstep(ms_lo, ms_hi, 3.0 * radius));
    middleShape = powr(middleShape, 5.0);
    float3 accumColor = float3(0.0);
    float accumAlpha = 0.0;
    for (int i = 0; i < 5; i++)
    {
        if (i >= int(params.u_colorsCount))
        {
            break;
        }
        float2 param = shape_uv;
        float param_1 = float(i) + 1.0;
        float2 rotatedUV = rotate(param, param_1);
        float r1 = (radius * (1.0 + (0.4 * float(i)))) - (3.0 * t);
        float r2 = ((0.5 * radius) * (1.0 + spots)) - (2.0 * t);
        float density = (6.0 * params.u_density) + (step(0.5, params.u_density) * powr(4.5 * (params.u_density - 0.5), 4.0));
        float param_2 = float(i) * 15.0;
        float _347 = hash11(param_2);
        float f = mix(1.0, 3.0 + (0.5 * float(i)), _347) * density;
        float2 param_3 = rotatedUV;
        float param_4 = r1;
        float param_5 = 5.0 * f;
        float param_6 = intensity;
        float param_7 = radius;
        float ray = raysShape(param_3, param_4, param_5, param_6, param_7, u_noiseTexture, u_noiseTextureSmplr);
        float2 param_8 = rotatedUV;
        float param_9 = r2;
        float param_10 = 4.0 * f;
        float param_11 = intensity;
        float param_12 = radius;
        ray *= raysShape(param_8, param_9, param_10, param_11, param_12, u_noiseTexture, u_noiseTextureSmplr);
        ray += ((1.0 + (4.0 * ray)) * middleShape);
        ray = fast::clamp(ray, 0.0, 1.0);
        float srcAlpha = params.u_colors[i].w * ray;
        float3 srcColor = params.u_colors[i].xyz * srcAlpha;
        float3 alphaBlendColor = accumColor + (srcColor * (1.0 - accumAlpha));
        float alphaBlendAlpha = accumAlpha + ((1.0 - accumAlpha) * srcAlpha);
        float3 addBlendColor = accumColor + srcColor;
        float addBlendAlpha = accumAlpha + srcAlpha;
        accumColor = mix(alphaBlendColor, addBlendColor, float3(params.u_bloom));
        accumAlpha = mix(alphaBlendAlpha, addBlendAlpha, params.u_bloom);
    }
    float overlayAlpha = params.u_colorBloom.w;
    float3 overlayColor = params.u_colorBloom.xyz * overlayAlpha;
    float3 colorWithOverlay = accumColor + (overlayColor * accumAlpha);
    accumColor = mix(accumColor, colorWithOverlay, float3(params.u_bloom));
    float3 bgColor = params.u_colorBack.xyz * params.u_colorBack.w;
    float3 color = accumColor + (bgColor * (1.0 - accumAlpha));
    float opacity = accumAlpha + ((1.0 - accumAlpha) * params.u_colorBack.w);
    color = fast::clamp(color, float3(0.0), float3(1.0));
    opacity = fast::clamp(opacity, 0.0, 1.0);
    color += float3(0.00390625 * (fract(sin(dot(gl_FragCoord.xy * 0.014, float2(12.9898, 78.233))) * 43758.547) - 0.5));
    out.fragColor = float4(color, opacity);
    return out;
}

