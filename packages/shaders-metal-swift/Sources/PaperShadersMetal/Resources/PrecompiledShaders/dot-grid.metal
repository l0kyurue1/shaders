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
    float4 u_colorBack;
    float4 u_colorFill;
    float4 u_colorStroke;
    float u_dotSize;
    float u_gapX;
    float u_gapY;
    float u_strokeWidth;
    float u_sizeRange;
    float u_opacityRange;
    float u_shape;
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
    float4 _83 = x12;
    float2 _85 = _83.xy - i1;
    x12.x = _85.x;
    x12.y = _85.y;
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
    float2 _200 = (a0.yz * x12.xz) + (h.yz * x12.yw);
    g.y = _200.x;
    g.z = _200.y;
    return 130.0 * dot(m, g);
}

static inline __attribute__((always_inline))
float polygon(thread const float2& p, thread const float& N, thread const float& rot)
{
    float a = precise::atan2(p.x, p.y) + rot;
    float r = 6.2831855 / N;
    return cos((floor(0.5 + (a / r)) * r) - a) * length(p);
}

fragment main0_out main0(main0_in in [[stage_in]], constant Params& params [[buffer(0)]])
{
    main0_out out = {};
    float2 shape_uv = in.v_patternUV * 100.0;
    float2 gap = fast::max(abs(float2(params.u_gapX, params.u_gapY)), float2(0.000001));
    float2 grid = fract(shape_uv / gap) + float2(0.0001);
    float2 grid_idx = floor(shape_uv / gap);
    float2 param = float2(grid_idx.x * 100.0, grid_idx.y) * 2.0;
    float sizeRandomizer = 0.5 + (0.8 * snoise(param));
    float2 param_1 = float2(grid_idx.y, grid_idx.x) * 2.0;
    float opacity_randomizer = 0.5 + (0.7 * snoise(param_1));
    float2 center = float2(0.499);
    float2 p = (grid - center) * float2(params.u_gapX, params.u_gapY);
    float baseSize = params.u_dotSize * (1.0 - (sizeRandomizer * params.u_sizeRange));
    float strokeWidth = params.u_strokeWidth * (1.0 - (sizeRandomizer * params.u_sizeRange));
    float dist;
    if (params.u_shape < 0.5)
    {
        dist = length(p);
    }
    else
    {
        if (params.u_shape < 1.5)
        {
            strokeWidth *= 1.5;
            float2 param_2 = p * 1.5;
            float param_3 = 4.0;
            float param_4 = 0.7853982;
            dist = polygon(param_2, param_3, param_4);
        }
        else
        {
            if (params.u_shape < 2.5)
            {
                float2 param_5 = p * 1.03;
                float param_6 = 4.0;
                float param_7 = 0.001;
                dist = polygon(param_5, param_6, param_7);
            }
            else
            {
                strokeWidth *= 1.5;
                p = (p * 2.0) - float2(1.0);
                p *= 0.9;
                p.y = 1.0 - p.y;
                p.y -= (0.75 * baseSize);
                float2 param_8 = p;
                float param_9 = 3.0;
                float param_10 = 0.001;
                dist = polygon(param_8, param_9, param_10);
            }
        }
    }
    float edgeWidth = fwidth(dist);
    float shapeOuter = 1.0 - smoothstep(baseSize - edgeWidth, baseSize + edgeWidth, dist - strokeWidth);
    float shapeInner = 1.0 - smoothstep(baseSize - edgeWidth, baseSize + edgeWidth, dist);
    float stroke = shapeOuter - shapeInner;
    float dotOpacity = fast::max(0.0, 1.0 - (opacity_randomizer * params.u_opacityRange));
    stroke *= dotOpacity;
    shapeInner *= dotOpacity;
    stroke *= params.u_colorStroke.w;
    shapeInner *= params.u_colorFill.w;
    float3 color = float3(0.0);
    color += (params.u_colorStroke.xyz * stroke);
    color += (params.u_colorFill.xyz * shapeInner);
    color += ((params.u_colorBack.xyz * ((1.0 - shapeInner) - stroke)) * params.u_colorBack.w);
    float opacity = 0.0;
    opacity += stroke;
    opacity += shapeInner;
    opacity += ((1.0 - opacity) * params.u_colorBack.w);
    out.fragColor = float4(color, opacity);
    return out;
}

