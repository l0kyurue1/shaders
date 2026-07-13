#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct Params
{
    float u_time;
    float2 u_resolution;
    float u_pixelRatio;
    float4 u_colorFront;
    float4 u_colorMid;
    float4 u_colorBack;
    float u_brightness;
    float u_contrast;
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
float2 rotate(thread const float2& uv, thread const float& th)
{
    return float2x2(float2(cos(th), sin(th)), float2(-sin(th), cos(th))) * uv;
}

static inline __attribute__((always_inline))
float neuroShape(thread float2& uv, thread const float& t)
{
    float2 sine_acc = float2(0.0);
    float2 res = float2(0.0);
    float scale = 8.0;
    for (int j = 0; j < 15; j++)
    {
        float2 param = uv;
        float param_1 = 1.0;
        uv = rotate(param, param_1);
        float2 param_2 = sine_acc;
        float param_3 = 1.0;
        sine_acc = rotate(param_2, param_3);
        float2 layer = (((uv * scale) + float2(float(j))) + sine_acc) - float2(t);
        sine_acc += sin(layer);
        res += ((float2(0.5) + (cos(layer) * 0.5)) / float2(scale));
        scale *= 1.2;
    }
    return res.x + res.y;
}

fragment main0_out main0(main0_in in [[stage_in]], constant Params& params [[buffer(0)]], float4 gl_FragCoord [[position]])
{
    main0_out out = {};
    float2 shape_uv = in.v_patternUV;
    shape_uv *= 0.13;
    float t = 0.5 * params.u_time;
    float2 param = shape_uv;
    float param_1 = t;
    float _130 = neuroShape(param, param_1);
    float _noise = _130;
    _noise = ((1.0 + params.u_brightness) * _noise) * _noise;
    _noise = powr(_noise, 0.7 + (6.0 * params.u_contrast));
    _noise = fast::min(1.4, _noise);
    float blend = smoothstep(0.7, 1.4, _noise);
    float4 frontC = params.u_colorFront;
    float _162 = frontC.w;
    float4 _164 = frontC;
    float3 _166 = _164.xyz * _162;
    frontC.x = _166.x;
    frontC.y = _166.y;
    frontC.z = _166.z;
    float4 midC = params.u_colorMid;
    float _179 = midC.w;
    float4 _180 = midC;
    float3 _182 = _180.xyz * _179;
    midC.x = _182.x;
    midC.y = _182.y;
    midC.z = _182.z;
    float4 blendFront = mix(midC, frontC, float4(blend));
    float safeNoise = fast::max(_noise, 0.0);
    float3 color = blendFront.xyz * safeNoise;
    float opacity = fast::clamp(blendFront.w * safeNoise, 0.0, 1.0);
    float3 bgColor = params.u_colorBack.xyz * params.u_colorBack.w;
    color += (bgColor * (1.0 - opacity));
    opacity += (params.u_colorBack.w * (1.0 - opacity));
    color += float3(0.00390625 * (fract(sin(dot(gl_FragCoord.xy * 0.014, float2(12.9898, 78.233))) * 43758.547) - 0.5));
    out.fragColor = float4(color, opacity);
    return out;
}

