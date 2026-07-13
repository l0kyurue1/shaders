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
    float4 u_colors[10];
    float u_colorsCount;
    float u_bandCount;
    float u_twist;
    float u_center;
    float u_proportion;
    float u_softness;
    float u_noise;
    float u_noiseFrequency;
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
    float2 shape_uv = in.v_objectUV;
    float l = length(shape_uv);
    l = fast::max(0.0001, l);
    float t = params.u_time;
    float angle = (ceil(params.u_bandCount) * precise::atan2(shape_uv.y, shape_uv.x)) + t;
    float angle_norm = angle / 6.2831855;
    float twist = 3.0 * fast::clamp(params.u_twist, 0.0, 1.0);
    float offset = powr(l, -twist) + angle_norm;
    float shape = fract(offset);
    shape = 1.0 - abs((2.0 * shape) - 1.0);
    float2 param = shape_uv * (15.0 * powr(params.u_noiseFrequency, 2.0));
    shape += (params.u_noise * snoise(param));
    float mid = smoothstep(0.2, 0.2 + (0.8 * params.u_center), powr(l, twist));
    shape = mix(0.0, shape, mid);
    float proportion = fast::clamp(params.u_proportion, 0.0, 1.0);
    float exponent = mix(0.25, 1.0, proportion * 2.0);
    exponent = mix(exponent, 10.0, fast::max(0.0, (proportion * 2.0) - 1.0));
    shape = powr(shape, exponent);
    float mixer = shape * params.u_colorsCount;
    float4 gradient = params.u_colors[0];
    float _331 = gradient.w;
    float4 _332 = gradient;
    float3 _334 = _332.xyz * _331;
    gradient.x = _334.x;
    gradient.y = _334.y;
    gradient.z = _334.z;
    float outerShape = 0.0;
    for (int i = 1; i < 11; i++)
    {
        if (i > int(params.u_colorsCount))
        {
            break;
        }
        float m = fast::clamp(mixer - float(i - 1), 0.0, 1.0);
        float aa = fwidth(m);
        m = smoothstep((0.5 - (0.5 * params.u_softness)) - aa, (0.5 + (0.5 * params.u_softness)) + aa, m);
        if (i == 1)
        {
            outerShape = m;
        }
        float4 c = params.u_colors[i - 1];
        float _397 = c.w;
        float4 _398 = c;
        float3 _400 = _398.xyz * _397;
        c.x = _400.x;
        c.y = _400.y;
        c.z = _400.z;
        gradient = mix(gradient, c, float4(m));
    }
    float midAA = 0.1 * fwidth(powr(l, -twist));
    float outerMid = smoothstep(0.2, 0.2 + midAA, powr(l, twist));
    outerShape = mix(0.0, outerShape, outerMid);
    float3 color = gradient.xyz * outerShape;
    float opacity = gradient.w * outerShape;
    float3 bgColor = params.u_colorBack.xyz * params.u_colorBack.w;
    color += (bgColor * (1.0 - opacity));
    opacity += (params.u_colorBack.w * (1.0 - opacity));
    color += float3(0.00390625 * (fract(sin(dot(gl_FragCoord.xy * 0.014, float2(12.9898, 78.233))) * 43758.547) - 0.5));
    out.fragColor = float4(color, opacity);
    return out;
}

