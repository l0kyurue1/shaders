#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct Params
{
    float u_time;
    float u_scale;
    float4 u_colors[10];
    float u_colorsCount;
    float u_proportion;
    float u_softness;
    float u_shape;
    float u_shapeScale;
    float u_distortion;
    float u_swirl;
    float u_swirlIterations;
};

struct main0_out
{
    float4 fragColor [[color(0)]];
};

struct main0_in
{
    float2 v_patternUV [[user(locn4)]];
};

static inline __attribute__((always_inline))
float randomG(thread const float2& p, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    float2 uv = (floor(p) / float2(100.0)) + float2(0.5);
    return u_noiseTexture.sample(u_noiseTextureSmplr, fract(uv)).y;
}

static inline __attribute__((always_inline))
float valueNoise(thread const float2& st, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    float2 i = floor(st);
    float2 f = fract(st);
    float2 param = i;
    float a = randomG(param, u_noiseTexture, u_noiseTextureSmplr);
    float2 param_1 = i + float2(1.0, 0.0);
    float b = randomG(param_1, u_noiseTexture, u_noiseTextureSmplr);
    float2 param_2 = i + float2(0.0, 1.0);
    float c = randomG(param_2, u_noiseTexture, u_noiseTextureSmplr);
    float2 param_3 = i + float2(1.0);
    float d = randomG(param_3, u_noiseTexture, u_noiseTextureSmplr);
    float2 u = (f * f) * (float2(3.0) - (f * 2.0));
    float x1 = mix(a, b, u.x);
    float x2 = mix(c, d, u.x);
    return mix(x1, x2, u.y);
}

fragment main0_out main0(main0_in in [[stage_in]], constant Params& params [[buffer(0)]], texture2d<float> u_noiseTexture [[texture(0)]], sampler u_noiseTextureSmplr [[sampler(0)]], float4 gl_FragCoord [[position]])
{
    main0_out out = {};
    float2 uv = in.v_patternUV;
    uv *= 0.5;
    float t = 0.0625 * (params.u_time + 118.0);
    float2 param = (uv * 1.0) + float2(t);
    float n1 = valueNoise(param, u_noiseTexture, u_noiseTextureSmplr);
    float2 param_1 = (uv * 2.0) - float2(t);
    float n2 = valueNoise(param_1, u_noiseTexture, u_noiseTextureSmplr);
    float angle = n1 * 6.2831855;
    uv.x += (((4.0 * params.u_distortion) * n2) * cos(angle));
    uv.y += (((4.0 * params.u_distortion) * n2) * sin(angle));
    float swirl = params.u_swirl;
    for (int i = 1; i <= 20; i++)
    {
        if (i >= int(params.u_swirlIterations))
        {
            break;
        }
        float iFloat = float(i);
        uv.x += ((swirl / iFloat) * cos(t + ((iFloat * 1.5) * uv.y)));
        uv.y += ((swirl / iFloat) * cos(t + ((iFloat * 1.0) * uv.x)));
    }
    float proportion = fast::clamp(params.u_proportion, 0.0, 1.0);
    float shape = 0.0;
    if (params.u_shape < 0.5)
    {
        float2 checksShape_uv = uv * (0.5 + (3.5 * params.u_shapeScale));
        shape = 0.5 + ((0.5 * sin(checksShape_uv.x)) * cos(checksShape_uv.y));
        shape += ((0.48 * sign(proportion - 0.5)) * powr(abs(proportion - 0.5), 0.5));
    }
    else
    {
        if (params.u_shape < 1.5)
        {
            float2 stripesShape_uv = uv * (2.0 * params.u_shapeScale);
            float f = fract(stripesShape_uv.y);
            shape = smoothstep(0.0, 0.55, f) * (1.0 - smoothstep(0.45, 1.0, f));
            shape += ((0.48 * sign(proportion - 0.5)) * powr(abs(proportion - 0.5), 0.5));
        }
        else
        {
            float shapeScaling = 5.0 * (1.0 - params.u_shapeScale);
            float e0 = 0.45 - shapeScaling;
            float e1 = 0.55 + shapeScaling;
            shape = smoothstep(fast::min(e0, e1), fast::max(e0, e1), (1.0 - uv.y) + (0.3 * (proportion - 0.5)));
        }
    }
    float mixer = shape * (params.u_colorsCount - 1.0);
    float4 gradient = params.u_colors[0];
    float _351 = gradient.w;
    float4 _353 = gradient;
    float3 _355 = _353.xyz * _351;
    gradient.x = _355.x;
    gradient.y = _355.y;
    gradient.z = _355.z;
    float aa = fwidth(shape);
    for (int i_1 = 1; i_1 < 10; i_1++)
    {
        if (i_1 >= int(params.u_colorsCount))
        {
            break;
        }
        float m = fast::clamp(mixer - float(i_1 - 1), 0.0, 1.0);
        float localMixerStart = floor(m);
        float softness = (0.5 * params.u_softness) + fwidth(m);
        float smoothed = smoothstep(fast::max(0.0, (0.5 - softness) - aa), fast::min(1.0, (0.5 + softness) + aa), m - localMixerStart);
        float stepped = localMixerStart + smoothed;
        m = mix(stepped, m, params.u_softness);
        float4 c = params.u_colors[i_1];
        float _429 = c.w;
        float4 _430 = c;
        float3 _432 = _430.xyz * _429;
        c.x = _432.x;
        c.y = _432.y;
        c.z = _432.z;
        gradient = mix(gradient, c, float4(m));
    }
    float3 color = gradient.xyz;
    float opacity = gradient.w;
    color += float3(0.00390625 * (fract(sin(dot(gl_FragCoord.xy * 0.014, float2(12.9898, 78.233))) * 43758.547) - 0.5));
    out.fragColor = float4(color, opacity);
    return out;
}

