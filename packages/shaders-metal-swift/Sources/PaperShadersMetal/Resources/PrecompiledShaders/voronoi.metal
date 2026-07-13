#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct Params
{
    float u_time;
    float u_scale;
    float4 u_colors[5];
    float u_colorsCount;
    float u_stepsPerColor;
    float4 u_colorGlow;
    float4 u_colorGap;
    float u_distortion;
    float u_gap;
    float u_glow;
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
float4 voronoi(thread const float2& x, thread const float& t, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr, constant Params& params)
{
    float2 ip = floor(x);
    float2 fp = fract(x);
    float md = 8.0;
    float rand = 0.0;
    float2 mr;
    float2 mg;
    for (int j = -1; j <= 1; j++)
    {
        for (int i = -1; i <= 1; i++)
        {
            float2 g = float2(float(i), float(j));
            float2 param = ip + g;
            float2 o = randomGB(param, u_noiseTexture, u_noiseTextureSmplr);
            float raw_hash = o.x;
            o = float2(0.5) + (sin(float2(t) + (o * 6.2831855)) * params.u_distortion);
            float2 r = (g + o) - fp;
            float d = dot(r, r);
            if (d < md)
            {
                md = d;
                mr = r;
                mg = g;
                rand = raw_hash;
            }
        }
    }
    md = 8.0;
    for (int j_1 = -2; j_1 <= 2; j_1++)
    {
        for (int i_1 = -2; i_1 <= 2; i_1++)
        {
            float2 g_1 = mg + float2(float(i_1), float(j_1));
            float2 param_1 = ip + g_1;
            float2 o_1 = randomGB(param_1, u_noiseTexture, u_noiseTextureSmplr);
            o_1 = float2(0.5) + (sin(float2(t) + (o_1 * 6.2831855)) * params.u_distortion);
            float2 r_1 = (g_1 + o_1) - fp;
            if (dot(mr - r_1, mr - r_1) > 0.00001)
            {
                md = fast::min(md, dot((mr + r_1) * 0.5, fast::normalize(r_1 - mr)));
            }
        }
    }
    return float4(md, mr, rand);
}

fragment main0_out main0(main0_in in [[stage_in]], constant Params& params [[buffer(0)]], texture2d<float> u_noiseTexture [[texture(0)]], sampler u_noiseTextureSmplr [[sampler(0)]])
{
    main0_out out = {};
    float2 shape_uv = in.v_patternUV;
    shape_uv *= 1.25;
    float t = params.u_time;
    float2 param = shape_uv;
    float param_1 = t;
    float4 voronoiRes = voronoi(param, param_1, u_noiseTexture, u_noiseTextureSmplr, params);
    float shape = fast::clamp(voronoiRes.w, 0.0, 1.0);
    float mixer = shape * (params.u_colorsCount - 1.0);
    mixer = (shape - (0.5 / params.u_colorsCount)) * params.u_colorsCount;
    float steps = fast::max(1.0, params.u_stepsPerColor);
    float4 gradient = params.u_colors[0];
    float _264 = gradient.w;
    float4 _266 = gradient;
    float3 _268 = _266.xyz * _264;
    gradient.x = _268.x;
    gradient.y = _268.y;
    gradient.z = _268.z;
    for (int i = 1; i < 5; i++)
    {
        if (i >= int(params.u_colorsCount))
        {
            break;
        }
        float localT = fast::clamp(mixer - float(i - 1), 0.0, 1.0);
        localT = round(localT * steps) / steps;
        float4 c = params.u_colors[i];
        float _312 = c.w;
        float4 _313 = c;
        float3 _315 = _313.xyz * _312;
        c.x = _315.x;
        c.y = _315.y;
        c.z = _315.z;
        gradient = mix(gradient, c, float4(localT));
    }
    bool _330 = mixer < 0.0;
    bool _339;
    if (!_330)
    {
        _339 = mixer > (params.u_colorsCount - 1.0);
    }
    else
    {
        _339 = _330;
    }
    if (_339)
    {
        float localT_1 = mixer + 1.0;
        if (mixer > (params.u_colorsCount - 1.0))
        {
            localT_1 = mixer - (params.u_colorsCount - 1.0);
        }
        localT_1 = round(localT_1 * steps) / steps;
        float4 cFst = params.u_colors[0];
        float _367 = cFst.w;
        float4 _368 = cFst;
        float3 _370 = _368.xyz * _367;
        cFst.x = _370.x;
        cFst.y = _370.y;
        cFst.z = _370.z;
        float4 cLast = params.u_colors[int(params.u_colorsCount - 1.0)];
        float _385 = cLast.w;
        float4 _386 = cLast;
        float3 _388 = _386.xyz * _385;
        cLast.x = _388.x;
        cLast.y = _388.y;
        cLast.z = _388.z;
        gradient = mix(cLast, cFst, float4(localT_1));
    }
    float3 cellColor = gradient.xyz;
    float cellOpacity = gradient.w;
    float glows = length(voronoiRes.yz * params.u_glow);
    glows = powr(glows, 1.5);
    float3 color = mix(cellColor, params.u_colorGlow.xyz * params.u_colorGlow.w, float3(params.u_colorGlow.w * glows));
    float opacity = cellOpacity + (params.u_colorGlow.w * glows);
    float edge = voronoiRes.x;
    float smoothEdge = (0.02 / (2.0 * params.u_scale)) * (1.0 + (0.5 * params.u_gap));
    edge = smoothstep(params.u_gap - smoothEdge, params.u_gap + smoothEdge, edge);
    color = mix(params.u_colorGap.xyz * params.u_colorGap.w, color, float3(edge));
    opacity = mix(params.u_colorGap.w, opacity, edge);
    out.fragColor = float4(color, opacity);
    return out;
}

