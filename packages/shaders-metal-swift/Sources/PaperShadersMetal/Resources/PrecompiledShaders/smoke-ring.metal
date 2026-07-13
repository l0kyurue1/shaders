#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct Params
{
    float u_time;
    float4 u_colorBack;
    float4 u_colors[10];
    float u_colorsCount;
    float u_thickness;
    float u_radius;
    float u_innerShape;
    float u_noiseScale;
    float u_noiseIterations;
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
float2 fbm(thread float2& n0, thread float2& n1, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr, constant Params& params)
{
    float2 total = float2(0.0);
    float amplitude = 0.4;
    for (int i = 0; i < 8; i++)
    {
        if (i >= int(params.u_noiseIterations))
        {
            break;
        }
        float2 param = n0;
        total.x += (valueNoise(param, u_noiseTexture, u_noiseTextureSmplr) * amplitude);
        float2 param_1 = n1;
        total.y += (valueNoise(param_1, u_noiseTexture, u_noiseTextureSmplr) * amplitude);
        n0 *= 1.99;
        n1 *= 1.99;
        amplitude *= 0.65;
    }
    return total;
}

static inline __attribute__((always_inline))
float getNoise(thread const float2& uv, thread const float2& pUv, thread const float& t, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr, constant Params& params)
{
    float2 pUvLeft = pUv + float2(0.03 * t);
    float period = fast::max(abs(params.u_noiseScale * 6.2831855), 0.000001);
    float2 pUvRight = float2(fract(pUv.x / period) * period, pUv.y) + float2(0.03 * t);
    float2 param = pUvLeft;
    float2 param_1 = pUvRight;
    float2 _214 = fbm(param, param_1, u_noiseTexture, u_noiseTextureSmplr, params);
    float2 _noise = _214;
    return mix(_noise.y, _noise.x, smoothstep(-0.25, 0.25, uv.x));
}

static inline __attribute__((always_inline))
float getRingShape(thread const float2& uv, constant Params& params)
{
    float radius = params.u_radius;
    float thickness = params.u_thickness;
    float _distance = length(uv);
    float ringValue = 1.0 - smoothstep(radius, radius + thickness, _distance);
    ringValue *= smoothstep(radius - (powr(params.u_innerShape, 3.0) * thickness), radius, _distance);
    return ringValue;
}

fragment main0_out main0(main0_in in [[stage_in]], constant Params& params [[buffer(0)]], texture2d<float> u_noiseTexture [[texture(0)]], sampler u_noiseTextureSmplr [[sampler(0)]], float4 gl_FragCoord [[position]])
{
    main0_out out = {};
    float2 shape_uv = in.v_objectUV;
    float t = params.u_time;
    float cycleDuration = 3.0;
    float period2 = 2.0 * cycleDuration;
    float localTime1 = fract(((0.1 * t) + cycleDuration) / period2) * period2;
    float localTime2 = fract((0.1 * t) / period2) * period2;
    float timeBlend = 0.5 + (0.5 * sin((((0.1 * t) * 3.1415927) / cycleDuration) - 1.5707964));
    float atg = precise::atan2(shape_uv.y, shape_uv.x) + 0.001;
    float l = length(shape_uv);
    float radialOffset = (0.5 * l) - rsqrt(fast::max(0.0001, l));
    float2 polar_uv1 = float2(atg, localTime1 - radialOffset) * params.u_noiseScale;
    float2 polar_uv2 = float2(atg, localTime2 - radialOffset) * params.u_noiseScale;
    float2 param = shape_uv;
    float2 param_1 = polar_uv1;
    float param_2 = t;
    float _noise1 = getNoise(param, param_1, param_2, u_noiseTexture, u_noiseTextureSmplr, params);
    float2 param_3 = shape_uv;
    float2 param_4 = polar_uv2;
    float param_5 = t;
    float _noise2 = getNoise(param_3, param_4, param_5, u_noiseTexture, u_noiseTextureSmplr, params);
    float _noise = mix(_noise1, _noise2, timeBlend);
    shape_uv *= (0.8 + (1.2 * _noise));
    float2 param_6 = shape_uv;
    float ringShape = getRingShape(param_6, params);
    float mixer = (ringShape * ringShape) * (params.u_colorsCount - 1.0);
    int idxLast = int(params.u_colorsCount) - 1;
    float4 gradient = params.u_colors[idxLast];
    float _396 = gradient.w;
    float4 _398 = gradient;
    float3 _400 = _398.xyz * _396;
    gradient.x = _400.x;
    gradient.y = _400.y;
    gradient.z = _400.z;
    for (int i = 8; i >= 0; i--)
    {
        float localT = fast::clamp(mixer - float((idxLast - i) - 1), 0.0, 1.0);
        float4 c = params.u_colors[i];
        float _430 = c.w;
        float4 _431 = c;
        float3 _433 = _431.xyz * _430;
        c.x = _433.x;
        c.y = _433.y;
        c.z = _433.z;
        gradient = mix(gradient, c, float4(localT));
    }
    float3 color = gradient.xyz * ringShape;
    float opacity = gradient.w * ringShape;
    float3 bgColor = params.u_colorBack.xyz * params.u_colorBack.w;
    color += (bgColor * (1.0 - opacity));
    opacity += (params.u_colorBack.w * (1.0 - opacity));
    color += float3(0.00390625 * (fract(sin(dot(gl_FragCoord.xy * 0.014, float2(12.9898, 78.233))) * 43758.547) - 0.5));
    out.fragColor = float4(color, opacity);
    return out;
}

