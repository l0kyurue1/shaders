#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct Params
{
    float4 u_colorFront;
    float4 u_colorBack;
    float u_shape;
    float u_frequency;
    float u_amplitude;
    float u_spacing;
    float u_proportion;
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

fragment main0_out main0(main0_in in [[stage_in]], constant Params& params [[buffer(0)]])
{
    main0_out out = {};
    float2 shape_uv = in.v_patternUV;
    shape_uv *= 4.0;
    float wave = 0.5 * cos((shape_uv.x * params.u_frequency) * 6.2831855);
    float zigzag = 2.0 * abs(fract(shape_uv.x * params.u_frequency) - 0.5);
    float irregular = sin(((shape_uv.x * 0.25) * params.u_frequency) * 6.2831855) * cos((shape_uv.x * params.u_frequency) * 6.2831855);
    float irregular2 = 0.75 * (sin((shape_uv.x * params.u_frequency) * 6.2831855) + (0.5 * cos(((shape_uv.x * 0.5) * params.u_frequency) * 6.2831855)));
    float offset = mix(zigzag, wave, smoothstep(0.0, 1.0, params.u_shape));
    offset = mix(offset, irregular, smoothstep(1.0, 2.0, params.u_shape));
    offset = mix(offset, irregular2, smoothstep(2.0, 3.0, params.u_shape));
    offset *= (2.0 * params.u_amplitude);
    float spacing = 0.001 + params.u_spacing;
    float shape = 0.5 + (0.5 * sin(((shape_uv.y + offset) * 3.1415927) / spacing));
    float aa = 0.0001 + fwidth(shape);
    float dc = 1.0 - fast::clamp(params.u_proportion, 0.0, 1.0);
    float e0 = (dc - params.u_softness) - aa;
    float e1 = (dc + params.u_softness) + aa;
    float res = smoothstep(fast::min(e0, e1), fast::max(e0, e1), shape);
    float3 fgColor = params.u_colorFront.xyz * params.u_colorFront.w;
    float fgOpacity = params.u_colorFront.w;
    float3 bgColor = params.u_colorBack.xyz * params.u_colorBack.w;
    float bgOpacity = params.u_colorBack.w;
    float3 color = fgColor * res;
    float opacity = fgOpacity * res;
    color += (bgColor * (1.0 - opacity));
    opacity += (bgOpacity * (1.0 - opacity));
    out.fragColor = float4(color, opacity);
    return out;
}

