#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct Params
{
    float u_time;
    float4 u_colors[10];
    float u_colorsCount;
    float u_distortion;
    float u_swirl;
    float u_grainMixer;
    float u_grainOverlay;
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
float hash21(thread float2& p)
{
    p = fract(p * float2(0.3183099, 0.3678794)) + float2(0.1);
    p += float2(dot(p, p + float2(19.19)));
    return fract(p.x * p.y);
}

static inline __attribute__((always_inline))
float valueNoise(thread const float2& st)
{
    float2 i = floor(st);
    float2 f = fract(st);
    float2 param = i;
    float _91 = hash21(param);
    float a = _91;
    float2 param_1 = i + float2(1.0, 0.0);
    float _97 = hash21(param_1);
    float b = _97;
    float2 param_2 = i + float2(0.0, 1.0);
    float _103 = hash21(param_2);
    float c = _103;
    float2 param_3 = i + float2(1.0);
    float _109 = hash21(param_3);
    float d = _109;
    float2 u = (f * f) * (float2(3.0) - (f * 2.0));
    float x1 = mix(a, b, u.x);
    float x2 = mix(c, d, u.x);
    return mix(x1, x2, u.y);
}

static inline __attribute__((always_inline))
float _noise(thread const float2& n, thread const float2& seedOffset)
{
    float2 param = n + seedOffset;
    return valueNoise(param);
}

static inline __attribute__((always_inline))
float2 rotate(thread const float2& uv, thread const float& th)
{
    return float2x2(float2(cos(th), sin(th)), float2(-sin(th), cos(th))) * uv;
}

static inline __attribute__((always_inline))
float2 getPosition(thread const int& i, thread const float& t)
{
    float a = float(i) * 0.37;
    float b = 0.6 + (fract(float(i) / 3.0) * 0.9);
    float c = 0.8 + fract(float(i + 1) / 4.0);
    float x = sin((t * b) + a);
    float y = cos((t * c) + (a * 1.5));
    return float2(0.5) + (float2(x, y) * 0.5);
}

fragment main0_out main0(main0_in in [[stage_in]], constant Params& params [[buffer(0)]])
{
    main0_out out = {};
    float2 uv = in.v_objectUV;
    uv += float2(0.5);
    float2 grainUV = uv * 1000.0;
    float2 param = grainUV;
    float2 param_1 = float2(0.0);
    float grain = _noise(param, param_1);
    float mixerGrain = (0.4 * params.u_grainMixer) * (grain - 0.5);
    float t = 0.5 * (params.u_time + 41.5);
    float radius = smoothstep(0.0, 1.0, length(uv - float2(0.5)));
    float center = 1.0 - radius;
    for (float i = 1.0; i <= 2.0; i += 1.0)
    {
        uv.x += ((((params.u_distortion * center) / i) * sin(t + ((i * 0.4) * smoothstep(0.0, 1.0, uv.y)))) * cos((0.2 * t) + ((i * 2.4) * smoothstep(0.0, 1.0, uv.y))));
        uv.y += (((params.u_distortion * center) / i) * cos(t + ((i * 2.0) * smoothstep(0.0, 1.0, uv.x))));
    }
    float2 uvRotated = uv;
    uvRotated -= float2(0.5);
    float angle = (3.0 * params.u_swirl) * radius;
    float2 param_2 = uvRotated;
    float param_3 = -angle;
    uvRotated = rotate(param_2, param_3);
    uvRotated += float2(0.5);
    float3 color = float3(0.0);
    float opacity = 0.0;
    float totalWeight = 0.0;
    for (int i_1 = 0; i_1 < 10; i_1++)
    {
        if (i_1 >= int(params.u_colorsCount))
        {
            break;
        }
        int param_4 = i_1;
        float param_5 = t;
        float2 pos = getPosition(param_4, param_5) + float2(mixerGrain);
        float3 colorFraction = params.u_colors[i_1].xyz * params.u_colors[i_1].w;
        float opacityFraction = params.u_colors[i_1].w;
        float dist = length(uvRotated - pos);
        dist = powr(dist, 3.5);
        float weight = 1.0 / (dist + 0.001);
        color += (colorFraction * weight);
        opacity += (opacityFraction * weight);
        totalWeight += weight;
    }
    color /= float3(fast::max(0.0001, totalWeight));
    opacity /= fast::max(0.0001, totalWeight);
    float2 param_6 = grainUV;
    float param_7 = 1.0;
    float2 param_8 = rotate(param_6, param_7) + float2(3.0);
    float grainOverlay = valueNoise(param_8);
    float2 param_9 = grainUV;
    float param_10 = 2.0;
    float2 param_11 = rotate(param_9, param_10) + float2(-1.0);
    grainOverlay = mix(grainOverlay, valueNoise(param_11), 0.5);
    grainOverlay = powr(grainOverlay, 1.3);
    float grainOverlayV = (grainOverlay * 2.0) - 1.0;
    float3 grainOverlayColor = float3(step(0.0, grainOverlayV));
    float grainOverlayStrength = params.u_grainOverlay * abs(grainOverlayV);
    grainOverlayStrength = powr(grainOverlayStrength, 0.8);
    color = mix(color, grainOverlayColor, float3(0.35 * grainOverlayStrength));
    opacity += (0.5 * grainOverlayStrength);
    opacity = fast::clamp(opacity, 0.0, 1.0);
    out.fragColor = float4(color, opacity);
    return out;
}

