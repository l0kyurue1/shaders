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
    float u_stepsPerColor;
    float u_size;
    float u_sizeRange;
    float u_spreading;
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
float2 randomGB(thread const float2& p, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    float2 uv = (floor(p) / float2(100.0)) + float2(0.5);
    return u_noiseTexture.sample(u_noiseTextureSmplr, fract(uv)).yz;
}

static inline __attribute__((always_inline))
float randomR(thread const float2& p, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    float2 uv = (floor(p) / float2(100.0)) + float2(0.5);
    return u_noiseTexture.sample(u_noiseTextureSmplr, fract(uv)).x;
}

static inline __attribute__((always_inline))
float2 rotate(thread const float2& uv, thread const float& th)
{
    return float2x2(float2(cos(th), sin(th)), float2(-sin(th), cos(th))) * uv;
}

static inline __attribute__((always_inline))
float3 voronoiShape(thread const float2& uv, thread const float& time, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr, constant Params& params)
{
    float2 i_uv = floor(uv);
    float2 f_uv = fract(uv);
    float spreading = 0.25 * fast::clamp(params.u_spreading, 0.0, 1.0);
    float minDist = 1.0;
    float2 randomizer = float2(0.0);
    for (int y = -1; y <= 1; y++)
    {
        for (int x = -1; x <= 1; x++)
        {
            float2 tileOffset = float2(float(x), float(y));
            float2 param = i_uv + tileOffset;
            float2 rand = randomGB(param, u_noiseTexture, u_noiseTextureSmplr);
            float2 cellCenter = float2(0.5001);
            cellCenter += (cos(float2(time) + (rand * 6.2831855)) * spreading);
            cellCenter -= float2(0.5);
            float2 param_1 = float2(rand.x, rand.y);
            float2 param_2 = cellCenter;
            float param_3 = randomR(param_1, u_noiseTexture, u_noiseTextureSmplr) + (0.1 * time);
            cellCenter = rotate(param_2, param_3);
            cellCenter += float2(0.5);
            float dist = length((tileOffset + cellCenter) - f_uv);
            if (dist < minDist)
            {
                minDist = dist;
                randomizer = rand;
            }
        }
    }
    return float3(minDist, randomizer);
}

fragment main0_out main0(main0_in in [[stage_in]], constant Params& params [[buffer(0)]], texture2d<float> u_noiseTexture [[texture(0)]], sampler u_noiseTextureSmplr [[sampler(0)]])
{
    main0_out out = {};
    float2 shape_uv = in.v_patternUV;
    shape_uv *= 1.5;
    float t = params.u_time + (-10.0);
    float2 param = shape_uv;
    float param_1 = t;
    float3 voronoi = voronoiShape(param, param_1, u_noiseTexture, u_noiseTextureSmplr, params) + float3(0.0001);
    float radius = (0.25 * fast::clamp(params.u_size, 0.0, 1.0)) - ((0.5 * fast::clamp(params.u_sizeRange, 0.0, 1.0)) * voronoi.z);
    float dist = voronoi.x;
    float edgeWidth = fwidth(dist);
    float dots = 1.0 - smoothstep(radius - edgeWidth, radius + edgeWidth, dist);
    float shape = voronoi.y;
    float mixer = shape * (params.u_colorsCount - 1.0);
    mixer = (shape - (0.5 / params.u_colorsCount)) * params.u_colorsCount;
    float steps = fast::max(1.0, params.u_stepsPerColor);
    float4 gradient = params.u_colors[0];
    float _287 = gradient.w;
    float4 _288 = gradient;
    float3 _290 = _288.xyz * _287;
    gradient.x = _290.x;
    gradient.y = _290.y;
    gradient.z = _290.z;
    for (int i = 1; i < 10; i++)
    {
        if (i >= int(params.u_colorsCount))
        {
            break;
        }
        float localT = fast::clamp(mixer - float(i - 1), 0.0, 1.0);
        localT = round(localT * steps) / steps;
        float4 c = params.u_colors[i];
        float _332 = c.w;
        float4 _333 = c;
        float3 _335 = _333.xyz * _332;
        c.x = _335.x;
        c.y = _335.y;
        c.z = _335.z;
        gradient = mix(gradient, c, float4(localT));
    }
    bool _350 = mixer < 0.0;
    bool _359;
    if (!_350)
    {
        _359 = mixer > (params.u_colorsCount - 1.0);
    }
    else
    {
        _359 = _350;
    }
    if (_359)
    {
        float localT_1 = mixer + 1.0;
        if (mixer > (params.u_colorsCount - 1.0))
        {
            localT_1 = mixer - (params.u_colorsCount - 1.0);
        }
        localT_1 = round(localT_1 * steps) / steps;
        float4 cFst = params.u_colors[0];
        float _387 = cFst.w;
        float4 _388 = cFst;
        float3 _390 = _388.xyz * _387;
        cFst.x = _390.x;
        cFst.y = _390.y;
        cFst.z = _390.z;
        float4 cLast = params.u_colors[int(params.u_colorsCount - 1.0)];
        float _405 = cLast.w;
        float4 _406 = cLast;
        float3 _408 = _406.xyz * _405;
        cLast.x = _408.x;
        cLast.y = _408.y;
        cLast.z = _408.z;
        gradient = mix(cLast, cFst, float4(localT_1));
    }
    float3 color = gradient.xyz * dots;
    float opacity = gradient.w * dots;
    float3 bgColor = params.u_colorBack.xyz * params.u_colorBack.w;
    color += (bgColor * (1.0 - opacity));
    opacity += (params.u_colorBack.w * (1.0 - opacity));
    out.fragColor = float4(color, opacity);
    return out;
}

