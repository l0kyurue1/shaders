#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()
template<typename Tx, typename Ty>
inline Tx mod(Tx x, Ty y)
{
    return x - y * floor(x / y);
}

struct Params
{
    float u_time;
    float4 u_colorBack;
    float4 u_colorFront;
    float u_density;
    float u_distortion;
    float u_strokeWidth;
    float u_strokeCap;
    float u_strokeTaper;
    float u_noise;
    float u_noiseFrequency;
    float u_softness;
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
float3 permute(thread const float3& x)
{
    return mod(((x * 34.0) + float3(1.0)) * x, float3(289.0));
}

static inline __attribute__((always_inline))
float snoise(thread const float2& v)
{
    float2 i = floor(v + float2(dot(v, float2(0.36602542))));
    float2 x0 = (v - i) + float2(dot(i, float2(0.21132487)));
    float2 i1 = select(float2(0.0, 1.0), float2(1.0, 0.0), bool2(x0.x > x0.y));
    float4 x12 = x0.xyxy + float4(0.21132487, 0.21132487, -0.57735026, -0.57735026);
    float4 _77 = x12;
    float2 _79 = _77.xy - i1;
    x12.x = _79.x;
    x12.y = _79.y;
    i = mod(i, float2(289.0));
    float3 param = float3(i.y) + float3(0.0, i1.y, 1.0);
    float3 param_1 = (permute(param) + float3(i.x)) + float3(0.0, i1.x, 1.0);
    float3 p = permute(param_1);
    float3 m = fast::max(float3(0.5) - float3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), float3(0.0));
    m *= m;
    m *= m;
    float3 x = (fract(p * float3(0.024390243)) * 2.0) - float3(1.0);
    float3 h = abs(x) - float3(0.5);
    float3 ox = floor(x + float3(0.5));
    float3 a0 = x - ox;
    m *= (float3(1.7928429) - (((a0 * a0) + (h * h)) * 0.85373473));
    float3 g;
    g.x = (a0.x * x0.x) + (h.x * x0.y);
    float2 _194 = (a0.yz * x12.xz) + (h.yz * x12.yw);
    g.y = _194.x;
    g.z = _194.y;
    return 130.0 * dot(m, g);
}

fragment main0_out main0(main0_in in [[stage_in]], constant Params& params [[buffer(0)]], float4 gl_FragCoord [[position]])
{
    main0_out out = {};
    float2 uv = in.v_patternUV * 2.0;
    float t = params.u_time;
    float l = length(uv);
    float density = fast::clamp(params.u_density, 0.0, 1.0);
    l = powr(fast::max(l, 0.000001), density);
    float angle = precise::atan2(uv.y, uv.x) - t;
    float angleNormalised = angle / 6.2831855;
    float2 param = uv * (16.0 * powr(params.u_noiseFrequency, 3.0));
    angleNormalised += ((0.125 * params.u_noise) * snoise(param));
    float offset = l + angleNormalised;
    offset -= (params.u_distortion * (sin((4.0 * l) - (0.5 * t)) * cos((3.1415927 + l) + (0.5 * t))));
    float stripe = fract(offset);
    float shape = 2.0 * abs(stripe - 0.5);
    float width = 1.0 - fast::clamp(params.u_strokeWidth, 0.005 * params.u_strokeTaper, 1.0);
    float wCap = mix(width, (1.0 - stripe) * (1.0 - step(0.5, stripe)), 1.0 - fast::clamp(l, 0.0, 1.0));
    width = mix(width, wCap, params.u_strokeCap);
    width *= (1.0 - (fast::clamp(params.u_strokeTaper, 0.0, 1.0) * l));
    float fw = fwidth(offset);
    float fwMult = 4.0 - (3.0 * (smoothstep(0.05, 0.4, 2.0 * params.u_strokeWidth) * smoothstep(0.05, 0.4, 2.0 * (1.0 - params.u_strokeWidth))));
    float pixelSize = mix(fwMult * fw, fwidth(shape), fast::clamp(fw, 0.0, 1.0));
    pixelSize = mix(pixelSize, 0.002, params.u_strokeCap * (1.0 - fast::clamp(l, 0.0, 1.0)));
    float res = smoothstep((width - pixelSize) - params.u_softness, (width + pixelSize) + params.u_softness, shape);
    float3 fgColor = params.u_colorFront.xyz * params.u_colorFront.w;
    float fgOpacity = params.u_colorFront.w;
    float3 bgColor = params.u_colorBack.xyz * params.u_colorBack.w;
    float bgOpacity = params.u_colorBack.w;
    float3 color = fgColor * res;
    float opacity = fgOpacity * res;
    color += (bgColor * (1.0 - opacity));
    opacity += (bgOpacity * (1.0 - opacity));
    color += float3(0.00390625 * (fract(sin(dot(gl_FragCoord.xy * 0.014, float2(12.9898, 78.233))) * 43758.547) - 0.5));
    out.fragColor = float4(color, opacity);
    return out;
}

