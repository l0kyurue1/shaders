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
    float u_scale;
    float4 u_colors[10];
    float u_colorsCount;
    float u_stepsPerColor;
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
    float4 _88 = x12;
    float2 _90 = _88.xy - i1;
    x12.x = _90.x;
    x12.y = _90.y;
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
    float2 _205 = (a0.yz * x12.xz) + (h.yz * x12.yw);
    g.y = _205.x;
    g.z = _205.y;
    return 130.0 * dot(m, g);
}

static inline __attribute__((always_inline))
float getNoise(thread const float2& uv, thread const float& t)
{
    float2 param = uv - float2(0.0, 0.3 * t);
    float _noise = 0.5 * snoise(param);
    float2 param_1 = (uv * 2.0) + float2(0.0, 0.32 * t);
    _noise += (0.5 * snoise(param_1));
    return _noise;
}

static inline __attribute__((always_inline))
float steppedSmooth(thread const float& m, thread const float& steps, thread const float& softness)
{
    float stepT = floor(m * steps) / steps;
    float f = (m * steps) - floor(m * steps);
    float fw = steps * fwidth(m);
    float smoothed = smoothstep(0.5 - softness, fast::min(1.0, (0.5 + softness) + fw), f);
    return stepT + (smoothed / steps);
}

fragment main0_out main0(main0_in in [[stage_in]], constant Params& params [[buffer(0)]], float4 gl_FragCoord [[position]])
{
    main0_out out = {};
    float2 shape_uv = in.v_patternUV;
    shape_uv *= 0.1;
    float t = 0.2 * params.u_time;
    float2 param = shape_uv;
    float param_1 = t;
    float shape = 0.5 + (0.5 * getNoise(param, param_1));
    bool u_extraSides = true;
    float mixer = shape * (params.u_colorsCount - 1.0);
    if (u_extraSides == true)
    {
        mixer = (shape - (0.5 / params.u_colorsCount)) * params.u_colorsCount;
    }
    float steps = fast::max(1.0, params.u_stepsPerColor);
    float4 gradient = params.u_colors[0];
    float _343 = gradient.w;
    float4 _344 = gradient;
    float3 _346 = _344.xyz * _343;
    gradient.x = _346.x;
    gradient.y = _346.y;
    gradient.z = _346.z;
    for (int i = 1; i < 10; i++)
    {
        if (i >= int(params.u_colorsCount))
        {
            break;
        }
        float localM = fast::clamp(mixer - float(i - 1), 0.0, 1.0);
        float param_2 = localM;
        float param_3 = steps;
        float param_4 = 0.5 * params.u_softness;
        localM = steppedSmooth(param_2, param_3, param_4);
        float4 c = params.u_colors[i];
        float _394 = c.w;
        float4 _395 = c;
        float3 _397 = _395.xyz * _394;
        c.x = _397.x;
        c.y = _397.y;
        c.z = _397.z;
        gradient = mix(gradient, c, float4(localM));
    }
    if (u_extraSides == true)
    {
        bool _416 = mixer < 0.0;
        bool _425;
        if (!_416)
        {
            _425 = mixer > (params.u_colorsCount - 1.0);
        }
        else
        {
            _425 = _416;
        }
        if (_425)
        {
            float localM_1 = mixer + 1.0;
            if (mixer > (params.u_colorsCount - 1.0))
            {
                localM_1 = mixer - (params.u_colorsCount - 1.0);
            }
            float param_5 = localM_1;
            float param_6 = steps;
            float param_7 = 0.5 * params.u_softness;
            localM_1 = steppedSmooth(param_5, param_6, param_7);
            float4 cFst = params.u_colors[0];
            float _456 = cFst.w;
            float4 _457 = cFst;
            float3 _459 = _457.xyz * _456;
            cFst.x = _459.x;
            cFst.y = _459.y;
            cFst.z = _459.z;
            float4 cLast = params.u_colors[int(params.u_colorsCount - 1.0)];
            float _474 = cLast.w;
            float4 _475 = cLast;
            float3 _477 = _475.xyz * _474;
            cLast.x = _477.x;
            cLast.y = _477.y;
            cLast.z = _477.z;
            gradient = mix(cLast, cFst, float4(localM_1));
        }
    }
    float3 color = gradient.xyz;
    float opacity = gradient.w;
    color += float3(0.00390625 * (fract(sin(dot(gl_FragCoord.xy * 0.014, float2(12.9898, 78.233))) * 43758.547) - 0.5));
    out.fragColor = float4(color, opacity);
    return out;
}

