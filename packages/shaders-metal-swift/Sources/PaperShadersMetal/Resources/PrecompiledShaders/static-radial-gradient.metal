#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// Implementation of the GLSL radians() function
template<typename T>
inline T radians(T d)
{
    return d * T(0.017453292);
}

struct Params
{
    float4 u_colorBack;
    float4 u_colors[10];
    float u_colorsCount;
    float u_radius;
    float u_focalDistance;
    float u_focalAngle;
    float u_falloff;
    float u_mixing;
    float u_distortion;
    float u_distortionShift;
    float u_distortionFreq;
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
    float _84 = hash21(param);
    float a = _84;
    float2 param_1 = i + float2(1.0, 0.0);
    float _90 = hash21(param_1);
    float b = _90;
    float2 param_2 = i + float2(0.0, 1.0);
    float _96 = hash21(param_2);
    float c = _96;
    float2 param_3 = i + float2(1.0);
    float _102 = hash21(param_3);
    float d = _102;
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

fragment main0_out main0(main0_in in [[stage_in]], constant Params& params [[buffer(0)]])
{
    main0_out out = {};
    float2 uv = in.v_objectUV * 2.0;
    float2 grainUV = uv * 1000.0;
    float2 center = float2(0.0);
    float angleRad = -radians(params.u_focalAngle + 90.0);
    float2 focalPoint = float2(cos(angleRad), sin(angleRad)) * params.u_focalDistance;
    float radius = params.u_radius;
    float2 c_to_uv = uv - center;
    float2 f_to_uv = uv - focalPoint;
    float2 f_to_c = center - focalPoint;
    float r = length(c_to_uv);
    float fragAngle = precise::atan2(c_to_uv.y, c_to_uv.x);
    float angleDiff = (fract(((fragAngle - angleRad) + 3.1415927) / 6.2831855) * 6.2831855) - 3.1415927;
    float halfAngle = acos(fast::clamp(radius / fast::max(params.u_focalDistance, 0.0001), 0.0, 1.0));
    float e0 = 1.8849556;
    float e1 = halfAngle;
    float lo = fast::min(e0, e1);
    float hi = fast::max(e0, e1);
    float s = smoothstep(lo, hi, abs(angleDiff));
    float _245;
    if (e1 >= e0)
    {
        _245 = 1.0 - s;
    }
    else
    {
        _245 = s;
    }
    float isInSector = _245;
    float a = dot(f_to_uv, f_to_uv);
    float b = (-2.0) * dot(f_to_uv, f_to_c);
    float c = dot(f_to_c, f_to_c) - (radius * radius);
    float discriminant = (b * b) - ((4.0 * a) * c);
    float t = 1.0;
    if (discriminant >= 0.0)
    {
        float sqrtD = sqrt(discriminant);
        float div = fast::max(0.0001, 2.0 * a);
        float t0 = ((-b) - sqrtD) / div;
        float t1 = ((-b) + sqrtD) / div;
        t = fast::max(t0, t1);
        if (t < 0.0)
        {
            t = 0.0;
        }
    }
    float dist = length(f_to_uv);
    float normalized = dist / fast::max(0.0001, length(f_to_uv * t));
    float shape = fast::clamp(normalized, 0.0, 1.0);
    float falloffMapped = mix(0.2 + (0.8 * fast::max(0.0, params.u_falloff + 1.0)), mix(1.0, 15.0, params.u_falloff * params.u_falloff), step(0.0, params.u_falloff));
    float falloffExp = mix(falloffMapped, 1.0, shape);
    shape = powr(shape, falloffExp);
    shape = 1.0 - fast::clamp(shape, 0.0, 1.0);
    float outerMask = 0.002;
    float outer = 1.0 - smoothstep(radius - outerMask, radius + outerMask, r);
    outer = mix(outer, 1.0, isInSector);
    shape = mix(0.0, shape, outer);
    shape *= (1.0 - smoothstep(radius - 0.01, radius, r));
    float angle = precise::atan2(f_to_uv.y, f_to_uv.x);
    shape -= (((powr(params.u_distortion, 2.0) * shape) * powr(abs(sin(3.1415927 * fast::clamp((length(f_to_uv) - 0.2) + params.u_distortionShift, 0.0, 1.0))), 4.0)) * (sin(params.u_distortionFreq * angle) + cos(floor(0.65 * params.u_distortionFreq) * angle)));
    float2 param = grainUV;
    float2 param_1 = float2(0.0);
    float grain = _noise(param, param_1);
    float mixerGrain = (0.4 * params.u_grainMixer) * (grain - 0.5);
    float mixer = (shape * params.u_colorsCount) + mixerGrain;
    float4 gradient = params.u_colors[0];
    float _461 = gradient.w;
    float4 _463 = gradient;
    float3 _465 = _463.xyz * _461;
    gradient.x = _465.x;
    gradient.y = _465.y;
    gradient.z = _465.z;
    float outerShape = 0.0;
    float _530;
    for (int i = 1; i < 11; i++)
    {
        if (i > int(params.u_colorsCount))
        {
            break;
        }
        float mLinear = fast::clamp(mixer - float(i - 1), 0.0, 1.0);
        float aa = fwidth(mLinear);
        float width = fast::min(params.u_mixing, 0.5);
        float t_1 = fast::clamp((mLinear - ((0.5 - width) - aa)) / ((2.0 * width) + (2.0 * aa)), 0.0, 1.0);
        float p = mix(2.0, 1.0, fast::clamp((params.u_mixing - 0.5) * 2.0, 0.0, 1.0));
        if (t_1 < 0.5)
        {
            _530 = 0.5 * powr(2.0 * t_1, p);
        }
        else
        {
            _530 = 1.0 - (0.5 * powr(2.0 * (1.0 - t_1), p));
        }
        float m = _530;
        float quadBlend = fast::clamp((params.u_mixing - 0.5) * 2.0, 0.0, 1.0);
        m = mix(m, m * m, 0.5 * quadBlend);
        if (i == 1)
        {
            outerShape = m;
        }
        float4 c_1 = params.u_colors[i - 1];
        float _571 = c_1.w;
        float4 _572 = c_1;
        float3 _574 = _572.xyz * _571;
        c_1.x = _574.x;
        c_1.y = _574.y;
        c_1.z = _574.z;
        gradient = mix(gradient, c_1, float4(m));
    }
    float3 color = gradient.xyz * outerShape;
    float opacity = gradient.w * outerShape;
    float3 bgColor = params.u_colorBack.xyz * params.u_colorBack.w;
    color += (bgColor * (1.0 - opacity));
    opacity += (params.u_colorBack.w * (1.0 - opacity));
    float2 param_2 = grainUV;
    float param_3 = 1.0;
    float2 param_4 = rotate(param_2, param_3) + float2(3.0);
    float grainOverlay = valueNoise(param_4);
    float2 param_5 = grainUV;
    float param_6 = 2.0;
    float2 param_7 = rotate(param_5, param_6) + float2(-1.0);
    grainOverlay = mix(grainOverlay, valueNoise(param_7), 0.5);
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

