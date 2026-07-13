#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// Implementation of signed integer mod accurate to SPIR-V specification
template<typename Tx, typename Ty>
inline Tx spvSMod(Tx x, Ty y)
{
    Tx remainder = x - y * (x / y);
    return select(Tx(remainder + y), remainder, remainder == 0 || (x >= 0) == (y >= 0));
}

struct Params
{
    float u_time;
    float4 u_colorFront;
    float4 u_colorBack;
    float u_proportion;
    float u_softness;
    float u_octaveCount;
    float u_persistence;
    float u_lacunarity;
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
float hash31(thread float3& p)
{
    p = fract(p * 0.3183099) + float3(0.1);
    p += float3(dot(p, p.yzx + float3(19.19)));
    return fract(p.x * (p.y + p.z));
}

static inline __attribute__((always_inline))
float3 gradientPredefined(thread const float& hash)
{
    int idx = spvSMod(int(hash * 12.0), 12);
    if (idx == 0)
    {
        return float3(1.0, 1.0, 0.0);
    }
    if (idx == 1)
    {
        return float3(-1.0, 1.0, 0.0);
    }
    if (idx == 2)
    {
        return float3(1.0, -1.0, 0.0);
    }
    if (idx == 3)
    {
        return float3(-1.0, -1.0, 0.0);
    }
    if (idx == 4)
    {
        return float3(1.0, 0.0, 1.0);
    }
    if (idx == 5)
    {
        return float3(-1.0, 0.0, 1.0);
    }
    if (idx == 6)
    {
        return float3(1.0, 0.0, -1.0);
    }
    if (idx == 7)
    {
        return float3(-1.0, 0.0, -1.0);
    }
    if (idx == 8)
    {
        return float3(0.0, 1.0, 1.0);
    }
    if (idx == 9)
    {
        return float3(0.0, -1.0, 1.0);
    }
    if (idx == 10)
    {
        return float3(0.0, 1.0, -1.0);
    }
    return float3(0.0, -1.0, -1.0);
}

static inline __attribute__((always_inline))
float3 fade(thread const float3& t)
{
    return ((t * t) * t) * ((t * ((t * 6.0) - float3(15.0))) + float3(10.0));
}

static inline __attribute__((always_inline))
float interpolateSafe(thread const float& v000, thread const float& v001, thread const float& v010, thread const float& v011, thread const float& v100, thread const float& v101, thread const float& v110, thread const float& v111, thread float3& t)
{
    t = fast::clamp(t, float3(0.0), float3(1.0));
    float v00 = mix(v000, v100, t.x);
    float v01 = mix(v001, v101, t.x);
    float v10 = mix(v010, v110, t.x);
    float v11 = mix(v011, v111, t.x);
    float v0 = mix(v00, v10, t.y);
    float v1 = mix(v01, v11, t.y);
    return mix(v0, v1, t.z);
}

static inline __attribute__((always_inline))
float perlinNoise(thread float3& position, thread const float& seed)
{
    position += float3(seed * 127.1, seed * 311.7, seed * 74.7);
    float3 i = floor(position);
    float3 f = fract(position);
    float3 param = i;
    float _263 = hash31(param);
    float h000 = _263;
    float3 param_1 = i + float3(0.0, 0.0, 1.0);
    float _269 = hash31(param_1);
    float h001 = _269;
    float3 param_2 = i + float3(0.0, 1.0, 0.0);
    float _275 = hash31(param_2);
    float h010 = _275;
    float3 param_3 = i + float3(0.0, 1.0, 1.0);
    float _280 = hash31(param_3);
    float h011 = _280;
    float3 param_4 = i + float3(1.0, 0.0, 0.0);
    float _286 = hash31(param_4);
    float h100 = _286;
    float3 param_5 = i + float3(1.0, 0.0, 1.0);
    float _291 = hash31(param_5);
    float h101 = _291;
    float3 param_6 = i + float3(1.0, 1.0, 0.0);
    float _296 = hash31(param_6);
    float h110 = _296;
    float3 param_7 = i + float3(1.0);
    float _302 = hash31(param_7);
    float h111 = _302;
    float param_8 = h000;
    float3 g000 = gradientPredefined(param_8);
    float param_9 = h001;
    float3 g001 = gradientPredefined(param_9);
    float param_10 = h010;
    float3 g010 = gradientPredefined(param_10);
    float param_11 = h011;
    float3 g011 = gradientPredefined(param_11);
    float param_12 = h100;
    float3 g100 = gradientPredefined(param_12);
    float param_13 = h101;
    float3 g101 = gradientPredefined(param_13);
    float param_14 = h110;
    float3 g110 = gradientPredefined(param_14);
    float param_15 = h111;
    float3 g111 = gradientPredefined(param_15);
    float v000 = dot(g000, f - float3(0.0));
    float v001 = dot(g001, f - float3(0.0, 0.0, 1.0));
    float v010 = dot(g010, f - float3(0.0, 1.0, 0.0));
    float v011 = dot(g011, f - float3(0.0, 1.0, 1.0));
    float v100 = dot(g100, f - float3(1.0, 0.0, 0.0));
    float v101 = dot(g101, f - float3(1.0, 0.0, 1.0));
    float v110 = dot(g110, f - float3(1.0, 1.0, 0.0));
    float v111 = dot(g111, f - float3(1.0));
    float3 param_16 = f;
    float3 u = fade(param_16);
    float param_17 = v000;
    float param_18 = v001;
    float param_19 = v010;
    float param_20 = v011;
    float param_21 = v100;
    float param_22 = v101;
    float param_23 = v110;
    float param_24 = v111;
    float3 param_25 = u;
    float _398 = interpolateSafe(param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25);
    return _398;
}

static inline __attribute__((always_inline))
float p_noise(thread const float3& position, thread int& octaveCount, thread const float& persistence, thread const float& lacunarity)
{
    float value = 0.0;
    float amplitude = 1.0;
    float frequency = 10.0;
    float maxValue = 0.0;
    octaveCount = clamp(octaveCount, 1, 8);
    for (int i = 0; i < octaveCount; i++)
    {
        float seed = float(i) * 0.7319;
        float3 param = position * frequency;
        float param_1 = seed;
        float _427 = perlinNoise(param, param_1);
        value += (_427 * amplitude);
        maxValue += amplitude;
        amplitude *= persistence;
        frequency *= lacunarity;
    }
    return value;
}

static inline __attribute__((always_inline))
float get_max_amp(thread float& persistence, thread float& octaveCount)
{
    persistence = fast::clamp(persistence * 0.999, 0.0, 0.999);
    octaveCount = fast::clamp(octaveCount, 1.0, 8.0);
    if (abs(persistence - 1.0) < 0.001)
    {
        return octaveCount;
    }
    return (1.0 - powr(persistence, octaveCount)) / fast::max(0.0001, 1.0 - persistence);
}

fragment main0_out main0(main0_in in [[stage_in]], constant Params& params [[buffer(0)]], float4 gl_FragCoord [[position]])
{
    main0_out out = {};
    float2 uv = in.v_patternUV;
    uv *= 0.5;
    float t = 0.2 * params.u_time;
    float3 p = float3(uv, t);
    float octCount = floor(params.u_octaveCount);
    float3 param = p;
    int param_1 = int(octCount);
    float param_2 = params.u_persistence;
    float param_3 = params.u_lacunarity;
    float _514 = p_noise(param, param_1, param_2, param_3);
    float _noise = _514;
    float param_4 = params.u_persistence;
    float param_5 = octCount;
    float _521 = get_max_amp(param_4, param_5);
    float max_amp = _521;
    float noise_normalized = fast::clamp(((_noise + max_amp) / fast::max(0.0001, 2.0 * max_amp)) + (params.u_proportion - 0.5), 0.0, 1.0);
    float sharpness = fast::clamp(params.u_softness, 0.0, 1.0);
    float smooth_w = 0.5 * fast::max(fwidth(noise_normalized), 0.001);
    float res = smoothstep((0.5 - (0.5 * sharpness)) - smooth_w, (0.5 + (0.5 * sharpness)) + smooth_w, noise_normalized);
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

