#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct Params
{
    float u_imageAspectRatio;
    float4 u_colorBack;
    float4 u_colorC;
    float4 u_colorM;
    float4 u_colorY;
    float4 u_colorK;
    float u_size;
    float u_minDot;
    float u_contrast;
    float u_grainSize;
    float u_grainMixer;
    float u_grainOverlay;
    float u_gridNoise;
    float u_softness;
    float u_floodC;
    float u_floodM;
    float u_floodY;
    float u_floodK;
    float u_gainC;
    float u_gainM;
    float u_gainY;
    float u_gainK;
    float u_type;
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
float getUvFrame(thread const float2& uv, thread const float2& pad)
{
    float left = smoothstep(-pad.x, 0.0, uv.x);
    float right = smoothstep(1.0 + pad.x, 1.0, uv.x);
    float bottom = smoothstep(-pad.y, 0.0, uv.y);
    float top = smoothstep(1.0 + pad.y, 1.0, uv.y);
    return ((left * right) * bottom) * top;
}

static inline __attribute__((always_inline))
float3 hash23(thread const float2& p)
{
    float3 p3 = fract(p.xyx * float3(0.3183099, 0.3678794, 0.3141592)) + float3(0.1);
    p3 += float3(dot(p3, p3.yzx + float3(19.19)));
    return fract(float3(p3.x * p3.y, p3.y * p3.z, p3.z * p3.x));
}

static inline __attribute__((always_inline))
float3 valueNoise3(thread const float2& st)
{
    float2 i = floor(st);
    float2 f = fract(st);
    float2 param = i;
    float3 a = hash23(param);
    float2 param_1 = i + float2(1.0, 0.0);
    float3 b = hash23(param_1);
    float2 param_2 = i + float2(0.0, 1.0);
    float3 c = hash23(param_2);
    float2 param_3 = i + float2(1.0);
    float3 d = hash23(param_3);
    float2 u = (f * f) * (float2(3.0) - (f * 2.0));
    float3 x1 = mix(a, b, float3(u.x));
    float3 x2 = mix(c, d, float3(u.x));
    return mix(x1, x2, float3(u.y));
}

static inline __attribute__((always_inline))
float sst(thread const float& edge0, thread const float& edge1, thread const float& x)
{
    return smoothstep(edge0, edge1, x);
}

static inline __attribute__((always_inline))
float2 randomRG(thread const float2& p, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    float2 uv = (floor(p) / float2(100.0)) + float2(0.5);
    return u_noiseTexture.sample(u_noiseTextureSmplr, fract(uv)).xy;
}

static inline __attribute__((always_inline))
float2 cellCenterPos(thread const float2& uv, thread const float2& cellOffset, thread const float& channelIdx, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr, constant Params& params)
{
    float2 cellCenter = (floor(uv) + float2(0.5)) + cellOffset;
    float2 param = cellCenter + float2(channelIdx * 50.0);
    return cellCenter + ((randomRG(param, u_noiseTexture, u_noiseTextureSmplr) - float2(0.5)) * params.u_gridNoise);
}

static inline __attribute__((always_inline))
float2 gridToImageUV(thread const float2& cellCenter, thread const float& cosA, thread const float& sinA, thread const float& shift, thread const float2& pad)
{
    float2 uvGrid = float2x2(float2(cosA, -sinA), float2(sinA, cosA)) * (cellCenter - float2(shift));
    return (uvGrid * pad) + float2(0.5);
}

static inline __attribute__((always_inline))
float getCyan(thread const float4& rgba, constant Params& params)
{
    float3 c = fast::clamp(((rgba.xyz - float3(0.5)) * params.u_contrast) + float3(0.5), float3(0.0), float3(1.0));
    float maxRGB = fast::max(fast::max(c.x, c.y), c.z);
    float _348;
    if (maxRGB > 0.00001)
    {
        _348 = (maxRGB - c.x) / maxRGB;
    }
    else
    {
        _348 = 0.0;
    }
    return _348 * rgba.w;
}

static inline __attribute__((always_inline))
void colorMask(thread const float2& pos, thread const float2& cellCenter, thread const float& rad, thread const float& transparency, thread const float& grain, thread const float& channelAddon, thread const float& channelgain, thread const float& generalComp, thread const bool& isJoined, thread float& outMask, constant Params& params)
{
    float dist = length(pos - cellCenter);
    float radius = rad;
    radius *= (1.0 + generalComp);
    radius += (0.15 + (channelgain * radius));
    radius = fast::max(0.0, radius);
    radius = mix(0.0, radius, transparency);
    radius += channelAddon;
    radius *= (1.0 - grain);
    float param = 0.0;
    float param_1 = radius;
    float param_2 = dist;
    float mask = 1.0 - sst(param, param_1, param_2);
    if (isJoined)
    {
        mask = powr(mask, 1.2);
    }
    else
    {
        float param_3 = 0.5 - (0.5 * params.u_softness);
        float param_4 = 0.51 + (0.49 * params.u_softness);
        float param_5 = mask;
        mask = sst(param_3, param_4, param_5);
    }
    mask *= mix(1.0, mix(0.5, 1.0, 1.5 * radius), params.u_softness);
    outMask += mask;
}

static inline __attribute__((always_inline))
float getMagenta(thread const float4& rgba, constant Params& params)
{
    float3 c = fast::clamp(((rgba.xyz - float3(0.5)) * params.u_contrast) + float3(0.5), float3(0.0), float3(1.0));
    float maxRGB = fast::max(fast::max(c.x, c.y), c.z);
    float _388;
    if (maxRGB > 0.00001)
    {
        _388 = (maxRGB - c.y) / maxRGB;
    }
    else
    {
        _388 = 0.0;
    }
    return _388 * rgba.w;
}

static inline __attribute__((always_inline))
float getYellow(thread const float4& rgba, constant Params& params)
{
    float3 c = fast::clamp(((rgba.xyz - float3(0.5)) * params.u_contrast) + float3(0.5), float3(0.0), float3(1.0));
    float maxRGB = fast::max(fast::max(c.x, c.y), c.z);
    float _428;
    if (maxRGB > 0.00001)
    {
        _428 = (maxRGB - c.z) / maxRGB;
    }
    else
    {
        _428 = 0.0;
    }
    return _428 * rgba.w;
}

static inline __attribute__((always_inline))
float getBlack(thread const float4& rgba, constant Params& params)
{
    float3 c = fast::clamp(((rgba.xyz - float3(0.5)) * params.u_contrast) + float3(0.5), float3(0.0), float3(1.0));
    return (1.0 - fast::max(fast::max(c.x, c.y), c.z)) * rgba.w;
}

static inline __attribute__((always_inline))
float3 applyContrast(thread const float3& rgb, constant Params& params)
{
    return fast::clamp(((rgb - float3(0.5)) * params.u_contrast) + float3(0.5), float3(0.0), float3(1.0));
}

static inline __attribute__((always_inline))
float4 RGBAtoCMYK(thread const float4& rgba)
{
    float k = 1.0 - fast::max(fast::max(rgba.x, rgba.y), rgba.z);
    float denom = 1.0 - k;
    float3 cmy = float3(0.0);
    if (denom > 0.00001)
    {
        cmy = ((float3(1.0) - rgba.xyz) - float3(k)) / float3(denom);
    }
    return float4(cmy, k) * rgba.w;
}

static inline __attribute__((always_inline))
float3 applyInk(thread const float3& paper, thread const float3& inkColor, thread const float& cov)
{
    float3 inkEffect = mix(float3(1.0), inkColor, float3(fast::clamp(cov, 0.0, 1.0)));
    return paper * inkEffect;
}

fragment main0_out main0(main0_in in [[stage_in]], constant Params& params [[buffer(0)]], texture2d<float> u_noiseTexture [[texture(0)]], texture2d<float> u_image [[texture(1)]], sampler u_noiseTextureSmplr [[sampler(0)]], sampler u_imageSmplr [[sampler(1)]])
{
    main0_out out = {};
    float2 uv = in.v_imageUV;
    float cellsPerSide = mix(400.0, 7.0, powr(params.u_size, 0.7));
    float cellSizeY = 1.0 / cellsPerSide;
    float2 pad = float2(1.0 / params.u_imageAspectRatio, 1.0) * cellSizeY;
    float2 uvGrid = (uv - float2(0.5)) / pad;
    float2 param = uv;
    float2 param_1 = pad;
    float insideImageBox = getUvFrame(param, param_1);
    float generalComp = ((0.1 * params.u_softness) + (0.1 * params.u_gridNoise)) + ((0.1 * (1.0 - step(0.5, params.u_type))) * (1.5 - params.u_softness));
    float2 uvC = (float2x2(float2(0.9659258, 0.258819), float2(-0.258819, 0.9659258)) * uvGrid) + float2(-0.5);
    float2 uvM = (float2x2(float2(0.258819, 0.9659258), float2(-0.9659258, 0.258819)) * uvGrid) + float2(-0.25);
    float2 uvY = (float2x2(float2(1.0, 0.0), float2(-0.0, 1.0)) * uvGrid) + float2(0.2);
    float2 uvK = (float2x2(float2(0.7071068), float2(-0.7071068, 0.7071068)) * uvGrid) + float2(0.0);
    float2 grainSize = float2(1.0, 1.0 / params.u_imageAspectRatio) * mix(2000.0, 200.0, params.u_grainSize);
    float2 grainUV = ((in.v_imageUV - float2(0.5)) * grainSize) + float2(0.5);
    float2 param_2 = grainUV;
    float3 noiseValues = valueNoise3(param_2);
    float param_3 = 0.55;
    float param_4 = 1.0;
    float param_5 = noiseValues.x;
    float grain = sst(param_3, param_4, param_5);
    grain *= params.u_grainMixer;
    float4 outMask = float4(0.0);
    bool isJoined = params.u_type > 0.5;
    if (params.u_type < 1.5)
    {
        for (int dy = -1; dy <= 1; dy++)
        {
            for (int dx = -1; dx <= 1; dx++)
            {
                float2 cellOffset = float2(float(dx), float(dy));
                float2 param_6 = uvC;
                float2 param_7 = cellOffset;
                float param_8 = 0.0;
                float2 cellCenterC = cellCenterPos(param_6, param_7, param_8, u_noiseTexture, u_noiseTextureSmplr, params);
                float2 param_9 = cellCenterC;
                float param_10 = 0.9659258;
                float param_11 = 0.258819;
                float param_12 = -0.5;
                float2 param_13 = pad;
                float4 texC = u_image.sample(u_imageSmplr, gridToImageUV(param_9, param_10, param_11, param_12, param_13));
                float4 param_14 = texC;
                float2 param_15 = uvC;
                float2 param_16 = cellCenterC;
                float param_17 = getCyan(param_14, params);
                float param_18 = insideImageBox * texC.w;
                float param_19 = grain;
                float param_20 = params.u_floodC;
                float param_21 = params.u_gainC;
                float param_22 = generalComp;
                bool param_23 = isJoined;
                float param_24 = outMask.x;
                colorMask(param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, params);
                outMask.x = param_24;
                float2 param_25 = uvM;
                float2 param_26 = cellOffset;
                float param_27 = 1.0;
                float2 cellCenterM = cellCenterPos(param_25, param_26, param_27, u_noiseTexture, u_noiseTextureSmplr, params);
                float2 param_28 = cellCenterM;
                float param_29 = 0.258819;
                float param_30 = 0.9659258;
                float param_31 = -0.25;
                float2 param_32 = pad;
                float4 texM = u_image.sample(u_imageSmplr, gridToImageUV(param_28, param_29, param_30, param_31, param_32));
                float4 param_33 = texM;
                float2 param_34 = uvM;
                float2 param_35 = cellCenterM;
                float param_36 = getMagenta(param_33, params);
                float param_37 = insideImageBox * texM.w;
                float param_38 = grain;
                float param_39 = params.u_floodM;
                float param_40 = params.u_gainM;
                float param_41 = generalComp;
                bool param_42 = isJoined;
                float param_43 = outMask.y;
                colorMask(param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41, param_42, param_43, params);
                outMask.y = param_43;
                float2 param_44 = uvY;
                float2 param_45 = cellOffset;
                float param_46 = 2.0;
                float2 cellCenterY = cellCenterPos(param_44, param_45, param_46, u_noiseTexture, u_noiseTextureSmplr, params);
                float2 param_47 = cellCenterY;
                float param_48 = 1.0;
                float param_49 = 0.0;
                float param_50 = 0.2;
                float2 param_51 = pad;
                float4 texY = u_image.sample(u_imageSmplr, gridToImageUV(param_47, param_48, param_49, param_50, param_51));
                float4 param_52 = texY;
                float2 param_53 = uvY;
                float2 param_54 = cellCenterY;
                float param_55 = getYellow(param_52, params);
                float param_56 = insideImageBox * texY.w;
                float param_57 = grain;
                float param_58 = params.u_floodY;
                float param_59 = params.u_gainY;
                float param_60 = generalComp;
                bool param_61 = isJoined;
                float param_62 = outMask.z;
                colorMask(param_53, param_54, param_55, param_56, param_57, param_58, param_59, param_60, param_61, param_62, params);
                outMask.z = param_62;
                float2 param_63 = uvK;
                float2 param_64 = cellOffset;
                float param_65 = 3.0;
                float2 cellCenterK = cellCenterPos(param_63, param_64, param_65, u_noiseTexture, u_noiseTextureSmplr, params);
                float2 param_66 = cellCenterK;
                float param_67 = 0.7071068;
                float param_68 = 0.7071068;
                float param_69 = 0.0;
                float2 param_70 = pad;
                float4 texK = u_image.sample(u_imageSmplr, gridToImageUV(param_66, param_67, param_68, param_69, param_70));
                float4 param_71 = texK;
                float2 param_72 = uvK;
                float2 param_73 = cellCenterK;
                float param_74 = getBlack(param_71, params);
                float param_75 = insideImageBox * texK.w;
                float param_76 = grain;
                float param_77 = params.u_floodK;
                float param_78 = params.u_gainK;
                float param_79 = generalComp;
                bool param_80 = isJoined;
                float param_81 = outMask.w;
                colorMask(param_72, param_73, param_74, param_75, param_76, param_77, param_78, param_79, param_80, param_81, params);
                outMask.w = param_81;
            }
        }
    }
    else
    {
        float4 tex = u_image.sample(u_imageSmplr, uv);
        float3 param_82 = tex.xyz;
        float3 _989 = applyContrast(param_82, params);
        tex.x = _989.x;
        tex.y = _989.y;
        tex.z = _989.z;
        insideImageBox *= tex.w;
        float4 param_83 = tex;
        float4 cmykOriginal = RGBAtoCMYK(param_83);
        for (int dy_1 = -1; dy_1 <= 1; dy_1++)
        {
            for (int dx_1 = -1; dx_1 <= 1; dx_1++)
            {
                float2 cellOffset_1 = float2(float(dx_1), float(dy_1));
                float2 param_84 = uvC;
                float2 param_85 = cellOffset_1;
                float param_86 = 0.0;
                float2 param_87 = uvC;
                float2 param_88 = cellCenterPos(param_84, param_85, param_86, u_noiseTexture, u_noiseTextureSmplr, params);
                float param_89 = cmykOriginal.x;
                float param_90 = insideImageBox;
                float param_91 = grain;
                float param_92 = params.u_floodC;
                float param_93 = params.u_gainC;
                float param_94 = generalComp;
                bool param_95 = isJoined;
                float param_96 = outMask.x;
                colorMask(param_87, param_88, param_89, param_90, param_91, param_92, param_93, param_94, param_95, param_96, params);
                outMask.x = param_96;
                float2 param_97 = uvM;
                float2 param_98 = cellOffset_1;
                float param_99 = 1.0;
                float2 param_100 = uvM;
                float2 param_101 = cellCenterPos(param_97, param_98, param_99, u_noiseTexture, u_noiseTextureSmplr, params);
                float param_102 = cmykOriginal.y;
                float param_103 = insideImageBox;
                float param_104 = grain;
                float param_105 = params.u_floodM;
                float param_106 = params.u_gainM;
                float param_107 = generalComp;
                bool param_108 = isJoined;
                float param_109 = outMask.y;
                colorMask(param_100, param_101, param_102, param_103, param_104, param_105, param_106, param_107, param_108, param_109, params);
                outMask.y = param_109;
                float2 param_110 = uvY;
                float2 param_111 = cellOffset_1;
                float param_112 = 2.0;
                float2 param_113 = uvY;
                float2 param_114 = cellCenterPos(param_110, param_111, param_112, u_noiseTexture, u_noiseTextureSmplr, params);
                float param_115 = cmykOriginal.z;
                float param_116 = insideImageBox;
                float param_117 = grain;
                float param_118 = params.u_floodY;
                float param_119 = params.u_gainY;
                float param_120 = generalComp;
                bool param_121 = isJoined;
                float param_122 = outMask.z;
                colorMask(param_113, param_114, param_115, param_116, param_117, param_118, param_119, param_120, param_121, param_122, params);
                outMask.z = param_122;
                float2 param_123 = uvK;
                float2 param_124 = cellOffset_1;
                float param_125 = 3.0;
                float2 param_126 = uvK;
                float2 param_127 = cellCenterPos(param_123, param_124, param_125, u_noiseTexture, u_noiseTextureSmplr, params);
                float param_128 = cmykOriginal.w;
                float param_129 = insideImageBox;
                float param_130 = grain;
                float param_131 = params.u_floodK;
                float param_132 = params.u_gainK;
                float param_133 = generalComp;
                bool param_134 = isJoined;
                float param_135 = outMask.w;
                colorMask(param_126, param_127, param_128, param_129, param_130, param_131, param_132, param_133, param_134, param_135, params);
                outMask.w = param_135;
            }
        }
    }
    float C = outMask.x;
    float M = outMask.y;
    float Y = outMask.z;
    float K = outMask.w;
    if (isJoined)
    {
        float th = 0.5;
        float sLeft = th * params.u_softness;
        float sRight = ((1.0 - th) * params.u_softness) + 0.01;
        C = smoothstep((th - sLeft) - fwidth(C), th + sRight, C);
        M = smoothstep((th - sLeft) - fwidth(M), th + sRight, M);
        Y = smoothstep((th - sLeft) - fwidth(Y), th + sRight, Y);
        K = smoothstep((th - sLeft) - fwidth(K), th + sRight, K);
    }
    C *= params.u_colorC.w;
    M *= params.u_colorM.w;
    Y *= params.u_colorY.w;
    K *= params.u_colorK.w;
    float3 ink = float3(1.0);
    float3 param_136 = ink;
    float3 param_137 = params.u_colorK.xyz;
    float param_138 = K;
    ink = applyInk(param_136, param_137, param_138);
    float3 param_139 = ink;
    float3 param_140 = params.u_colorC.xyz;
    float param_141 = C;
    ink = applyInk(param_139, param_140, param_141);
    float3 param_142 = ink;
    float3 param_143 = params.u_colorM.xyz;
    float param_144 = M;
    ink = applyInk(param_142, param_143, param_144);
    float3 param_145 = ink;
    float3 param_146 = params.u_colorY.xyz;
    float param_147 = Y;
    ink = applyInk(param_145, param_146, param_147);
    float shape = fast::clamp(fast::max(fast::max(C, M), fast::max(Y, K)), 0.0, 1.0);
    float3 color = params.u_colorBack.xyz * params.u_colorBack.w;
    float opacity = params.u_colorBack.w;
    color = mix(color, ink, float3(shape));
    opacity += shape;
    opacity = fast::clamp(opacity, 0.0, 1.0);
    float grainOverlay = mix(noiseValues.y, noiseValues.z, 0.5);
    grainOverlay = powr(grainOverlay, 1.3);
    float grainOverlayV = (grainOverlay * 2.0) - 1.0;
    float3 grainOverlayColor = float3(step(0.0, grainOverlayV));
    float grainOverlayStrength = params.u_grainOverlay * abs(grainOverlayV);
    grainOverlayStrength = powr(grainOverlayStrength, 0.8);
    color = mix(color, grainOverlayColor, float3(0.5 * grainOverlayStrength));
    opacity += (0.5 * grainOverlayStrength);
    opacity = fast::clamp(opacity, 0.0, 1.0);
    out.fragColor = float4(color, opacity);
    return out;
}

