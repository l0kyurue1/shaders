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
    float4 u_colorHighlight;
    float u_imageAspectRatio;
    float u_size;
    float u_highlights;
    float u_layering;
    float u_edges;
    float u_caustic;
    float u_waves;
};

struct main0_out
{
    float4 fragColor [[color(0)]];
};

struct main0_in
{
    float2 v_imageUV [[user(locn6)]];
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
    float4 _91 = x12;
    float2 _93 = _91.xy - i1;
    x12.x = _93.x;
    x12.y = _93.y;
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
    float2 _208 = (a0.yz * x12.xz) + (h.yz * x12.yw);
    g.y = _208.x;
    g.z = _208.y;
    return 130.0 * dot(m, g);
}

static inline __attribute__((always_inline))
float2x2 rotate2D(thread const float& r)
{
    return float2x2(float2(cos(r), sin(r)), float2(-sin(r), cos(r)));
}

static inline __attribute__((always_inline))
float getCausticNoise(thread float2& uv, thread const float& t, thread float& scale)
{
    float2 n = float2(0.1);
    float2 N = float2(0.1);
    float param = 0.5;
    float2x2 m = rotate2D(param);
    for (int j = 0; j < 6; j++)
    {
        uv *= m;
        n *= m;
        float2 q = (((uv * scale) + float2(float(j))) + n) + float2(((0.5 + (0.5 * float(j))) * (mod(float(j), 2.0) - 1.0)) * t);
        n += sin(q);
        N += (cos(q) / float2(scale));
        scale *= 1.1;
    }
    return (N.x + N.y) + 1.0;
}

static inline __attribute__((always_inline))
float getUvFrame(thread const float2& uv)
{
    float aax = 2.0 * fwidth(uv.x);
    float aay = 2.0 * fwidth(uv.y);
    float left = smoothstep(0.0, aax, uv.x);
    float right = 1.0 - smoothstep(1.0 - aax, 1.0, uv.x);
    float bottom = smoothstep(0.0, aay, uv.y);
    float top = 1.0 - smoothstep(1.0 - aay, 1.0, uv.y);
    return ((left * right) * bottom) * top;
}

fragment main0_out main0(main0_in in [[stage_in]], constant Params& params [[buffer(0)]], texture2d<float> u_image [[texture(0)]], sampler u_imageSmplr [[sampler(0)]])
{
    main0_out out = {};
    float2 imageUV = in.v_imageUV;
    float2 patternUV = in.v_imageUV - float2(0.5);
    patternUV *= float2(params.u_imageAspectRatio, 1.0);
    patternUV /= float2(0.01 + (0.09 * params.u_size));
    float t = params.u_time;
    float2 param = (patternUV * ((0.3 + (0.1 * sin(t))) * 0.1)) + float2(0.0, 0.4 * t);
    float wavesNoise = snoise(param);
    float2 param_1 = patternUV + ((float2(1.0, -1.0) * params.u_waves) * wavesNoise);
    float param_2 = 2.0 * t;
    float param_3 = 1.5;
    float _416 = getCausticNoise(param_1, param_2, param_3);
    float causticNoise = _416;
    float2 param_4 = patternUV + ((float2(1.0, -1.0) * (2.0 * params.u_waves)) * wavesNoise);
    float param_5 = 1.5 * t;
    float param_6 = 2.0;
    float _432 = getCausticNoise(param_4, param_5, param_6);
    causticNoise += (params.u_layering * _432);
    causticNoise *= causticNoise;
    float edgesDistortion = smoothstep(0.0, 0.1, imageUV.x);
    edgesDistortion *= smoothstep(0.0, 0.1, imageUV.y);
    edgesDistortion *= (smoothstep(1.0, 1.1, imageUV.x) + (1.0 - smoothstep(0.8, 0.95, imageUV.x)));
    edgesDistortion *= (1.0 - smoothstep(0.9, 1.0, imageUV.y));
    edgesDistortion = mix(edgesDistortion, 1.0, params.u_edges);
    float causticNoiseDistortion = (0.02 * causticNoise) * edgesDistortion;
    float wavesDistortion = (0.1 * params.u_waves) * wavesNoise;
    imageUV += float2(wavesDistortion, -wavesDistortion);
    imageUV += float2(params.u_caustic * causticNoiseDistortion);
    float2 param_7 = imageUV;
    float frame = getUvFrame(param_7);
    float4 image = u_image.sample(u_imageSmplr, imageUV);
    float4 backColor = params.u_colorBack;
    float _516 = backColor.w;
    float4 _517 = backColor;
    float3 _519 = _517.xyz * _516;
    backColor.x = _519.x;
    backColor.y = _519.y;
    backColor.z = _519.z;
    float3 color = mix(backColor.xyz, image.xyz, float3(image.w * frame));
    float opacity = backColor.w + (image.w * frame);
    causticNoise = fast::max(-0.2, causticNoise);
    float hightlight = (0.025 * params.u_highlights) * causticNoise;
    hightlight *= params.u_colorHighlight.w;
    color = mix(color, params.u_colorHighlight.xyz, float3((0.05 * params.u_highlights) * causticNoise));
    opacity += hightlight;
    color += float3(hightlight * (0.5 + (0.5 * wavesNoise)));
    opacity += (hightlight * (0.5 + (0.5 * wavesNoise)));
    opacity = fast::clamp(opacity, 0.0, 1.0);
    out.fragColor = float4(color, opacity);
    return out;
}

