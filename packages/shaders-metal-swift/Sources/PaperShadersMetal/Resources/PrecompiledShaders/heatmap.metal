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
    float u_imageAspectRatio;
    float4 u_colorBack;
    float4 u_colors[10];
    float u_colorsCount;
    float u_angle;
    float u_noise;
    float u_innerGlow;
    float u_outerGlow;
    float u_contour;
};

struct main0_out
{
    float4 fragColor [[color(0)]];
};

struct main0_in
{
    float2 v_imageUV [[user(locn6)]];
    float2 v_objectUV [[user(locn0)]];
};

static inline __attribute__((always_inline))
float getImgFrame(thread const float2& uv, thread const float& th)
{
    float frame = 1.0;
    frame *= smoothstep(0.0, th, uv.y);
    frame *= (1.0 - smoothstep(1.0 - th, 1.0, uv.y));
    frame *= smoothstep(0.0, th, uv.x);
    frame *= (1.0 - smoothstep(1.0 - th, 1.0, uv.x));
    return frame;
}

static inline __attribute__((always_inline))
float blurEdge3x3(texture2d<float> tex, sampler texSmplr, thread const float2& uv, thread const float2& dudx, thread const float2& dudy, thread const float& radius, thread const float& centerSample)
{
    float2 texel = float2(1.0) / float2(int2(tex.get_width(), tex.get_height()));
    float2 r = texel * radius;
    float w1 = 1.0;
    float w2 = 2.0;
    float w4 = 4.0;
    float norm = 16.0;
    float sum = w4 * centerSample;
    sum += (w2 * tex.sample(texSmplr, (uv + float2(0.0, -r.y)), gradient2d(dudx, dudy)).y);
    sum += (w2 * tex.sample(texSmplr, (uv + float2(0.0, r.y)), gradient2d(dudx, dudy)).y);
    sum += (w2 * tex.sample(texSmplr, (uv + float2(-r.x, 0.0)), gradient2d(dudx, dudy)).y);
    sum += (w2 * tex.sample(texSmplr, (uv + float2(r.x, 0.0)), gradient2d(dudx, dudy)).y);
    sum += (w1 * tex.sample(texSmplr, (uv + float2(-r.x, -r.y)), gradient2d(dudx, dudy)).y);
    sum += (w1 * tex.sample(texSmplr, (uv + float2(r.x, -r.y)), gradient2d(dudx, dudy)).y);
    sum += (w1 * tex.sample(texSmplr, (uv + float2(-r.x, r.y)), gradient2d(dudx, dudy)).y);
    sum += (w1 * tex.sample(texSmplr, (uv + float2(r.x, r.y)), gradient2d(dudx, dudy)).y);
    return sum / norm;
}

static inline __attribute__((always_inline))
float sst(thread const float& edge0, thread const float& edge1, thread const float& x)
{
    return smoothstep(edge0, edge1, x);
}

static inline __attribute__((always_inline))
float lst(thread const float& edge0, thread const float& edge1, thread const float& x)
{
    return fast::clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
}

static inline __attribute__((always_inline))
float circle(thread const float2& uv, thread const float2& c, thread const float2& r)
{
    return 1.0 - smoothstep(r.x, r.y, length(uv - c));
}

static inline __attribute__((always_inline))
float shadowShape(thread const float2& uv, thread const float& t, thread const float& contour)
{
    float2 scaledUV = uv;
    float posY = mix(-1.0, 2.0, t);
    scaledUV.y -= 0.5;
    float param = 0.0;
    float param_1 = 0.8;
    float param_2 = posY;
    float param_3 = 1.4;
    float param_4 = 0.9;
    float param_5 = posY;
    float mainCircleScale = sst(param, param_1, param_2) * lst(param_3, param_4, param_5);
    scaledUV *= float2(1.0, 1.0 + (1.5 * mainCircleScale));
    scaledUV.y += 0.5;
    float innerR = 0.4;
    float param_6 = 0.1;
    float param_7 = 0.2;
    float param_8 = t;
    float param_9 = 0.2;
    float param_10 = 0.5;
    float param_11 = t;
    float outerR = 1.0 - (0.3 * (sst(param_6, param_7, param_8) * (1.0 - sst(param_9, param_10, param_11))));
    float2 param_12 = scaledUV;
    float2 param_13 = float2(0.5, posY - 0.2);
    float2 param_14 = float2(innerR, outerR);
    float s = circle(param_12, param_13, param_14);
    float param_15 = 0.2;
    float param_16 = 0.3;
    float param_17 = t;
    float param_18 = 0.6;
    float param_19 = 0.3;
    float param_20 = t;
    float shapeSizing = sst(param_15, param_16, param_17) * sst(param_18, param_19, param_20);
    s = powr(s, 1.4);
    s *= 1.2;
    float topFlattener = 0.0;
    float pos = posY - uv.y;
    float edge = 1.2;
    float param_21 = -0.4;
    float param_22 = 0.0;
    float param_23 = pos;
    float param_24 = 0.0;
    float param_25 = edge;
    float param_26 = pos;
    topFlattener = lst(param_21, param_22, param_23) * (1.0 - sst(param_24, param_25, param_26));
    topFlattener = powr(topFlattener, 3.0);
    float param_27 = 0.0;
    float param_28 = 0.3;
    float param_29 = pos;
    float topFlattenerMixer = 1.0 - sst(param_27, param_28, param_29);
    s = mix(topFlattener, s, topFlattenerMixer);
    float param_30 = 0.6;
    float param_31 = 0.7;
    float param_32 = t;
    float param_33 = 0.8;
    float param_34 = 0.9;
    float param_35 = t;
    float visibility = sst(param_30, param_31, param_32) * (1.0 - sst(param_33, param_34, param_35));
    float angle = (-2.0) - (t * 6.2831855);
    float2 param_36 = uv;
    float2 param_37 = float2(0.95 - (0.2 * cos(angle)), 0.4 - (0.1 * sin(angle)));
    float2 param_38 = float2(0.15, 0.3);
    float rightCircle = circle(param_36, param_37, param_38);
    rightCircle *= visibility;
    s = mix(s, 0.0, rightCircle);
    float2 param_39 = uv;
    float2 param_40 = float2(0.5, 0.19);
    float2 param_41 = float2(0.05, 0.25);
    float topCircle = circle(param_39, param_40, param_41);
    float2 param_42 = uv;
    float2 param_43 = float2(0.5, 0.19);
    float2 param_44 = float2(0.2, 0.5);
    topCircle += ((2.0 * contour) * circle(param_42, param_43, param_44));
    float param_45 = 0.2;
    float param_46 = 0.3;
    float param_47 = t;
    float param_48 = 0.3;
    float param_49 = 0.45;
    float param_50 = t;
    float visibility_1 = (0.55 * sst(param_45, param_46, param_47)) * (1.0 - sst(param_48, param_49, param_50));
    topCircle *= visibility_1;
    s = mix(s, 0.0, topCircle);
    float2 param_51 = uv;
    float2 param_52 = float2(0.53, 0.13);
    float2 param_53 = float2(0.08, 0.19);
    float leafMask = circle(param_51, param_52, param_53);
    float param_54 = 0.4;
    float param_55 = 0.54;
    float param_56 = uv.x;
    leafMask = mix(leafMask, 0.0, 1.0 - sst(param_54, param_55, param_56));
    float param_57 = 0.0;
    float param_58 = 0.2;
    float param_59 = uv.y;
    leafMask = mix(0.0, leafMask, sst(param_57, param_58, param_59));
    float param_60 = 0.5;
    float param_61 = 1.1;
    float param_62 = posY;
    float param_63 = 1.5;
    float param_64 = 1.3;
    float param_65 = posY;
    leafMask *= (sst(param_60, param_61, param_62) * sst(param_63, param_64, param_65));
    s += leafMask;
    float param_66 = 0.0;
    float param_67 = 0.4;
    float param_68 = t;
    float param_69 = 0.6;
    float param_70 = 0.8;
    float param_71 = t;
    float visibility_2 = sst(param_66, param_67, param_68) * (1.0 - sst(param_69, param_70, param_71));
    float2 param_72 = uv;
    float2 param_73 = float2(0.52, 0.92);
    float2 param_74 = float2(0.09, 0.25);
    s = mix(s, 0.0, visibility_2 * circle(param_72, param_73, param_74));
    float param_75 = 0.0;
    float param_76 = 0.6;
    float param_77 = t;
    float param_78 = 0.6;
    float param_79 = 1.0;
    float param_80 = t;
    float pos_1 = sst(param_75, param_76, param_77) * (1.0 - sst(param_78, param_79, param_80));
    float2 param_81 = uv;
    float2 param_82 = float2(0.0, 1.2 - (0.5 * pos_1));
    float2 param_83 = float2(0.1, 0.3);
    s = mix(s, 0.5, circle(param_81, param_82, param_83));
    float2 param_84 = uv;
    float2 param_85 = float2(1.0, 0.5 + (0.5 * pos_1));
    float2 param_86 = float2(0.1, 0.3);
    s = mix(s, 0.0, circle(param_84, param_85, param_86));
    float param_87 = 0.3;
    float param_88 = 0.4;
    float param_89 = t;
    float param_90 = 0.7;
    float param_91 = 0.5;
    float param_92 = t;
    float2 param_93 = uv;
    float2 param_94 = float2(0.95, 0.2 + ((0.2 * sst(param_87, param_88, param_89)) * sst(param_90, param_91, param_92)));
    float2 param_95 = float2(0.07, 0.22);
    s = mix(s, 1.0, circle(param_93, param_94, param_95));
    float param_96 = 0.3;
    float param_97 = 0.4;
    float param_98 = t;
    float param_99 = 0.5;
    float param_100 = 0.7;
    float param_101 = t;
    float2 param_102 = uv;
    float2 param_103 = float2(0.95, 0.2 + ((0.2 * sst(param_96, param_97, param_98)) * (1.0 - sst(param_99, param_100, param_101))));
    float2 param_104 = float2(0.07, 0.22);
    s = mix(s, 1.0, circle(param_102, param_103, param_104));
    float param_105 = 1.0;
    float param_106 = 0.85;
    float param_107 = uv.y;
    s /= fast::max(0.0001, sst(param_105, param_106, param_107));
    s = fast::clamp(0.0, 1.0, s);
    return s;
}

fragment main0_out main0(main0_in in [[stage_in]], constant Params& params [[buffer(0)]], texture2d<float> u_image [[texture(0)]], sampler u_imageSmplr [[sampler(0)]])
{
    main0_out out = {};
    float2 uv = in.v_objectUV + float2(0.5);
    uv.y = 1.0 - uv.y;
    float2 imgUV = in.v_imageUV;
    imgUV -= float2(0.5);
    imgUV *= 0.5714286;
    imgUV += float2(0.5);
    float2 param = imgUV;
    float param_1 = 0.03;
    float imgSoftFrame = getImgFrame(param, param_1);
    float4 img = u_image.sample(u_imageSmplr, imgUV);
    float2 dudx = dfdx(imgUV);
    float2 dudy = dfdy(imgUV);
    if (img.w == 0.0)
    {
        out.fragColor = params.u_colorBack;
        return out;
    }
    float t = 0.1 * params.u_time;
    t -= 0.3;
    float tCopy = t + 0.33333334;
    float tCopy2 = t + 0.6666667;
    t = mod(t, 1.0);
    tCopy = mod(tCopy, 1.0);
    tCopy2 = mod(tCopy2, 1.0);
    float2 animationUV = imgUV - float2(0.5);
    float angle = ((-params.u_angle) * 3.1415927) / 180.0;
    float cosA = cos(angle);
    float sinA = sin(angle);
    animationUV = float2((animationUV.x * cosA) - (animationUV.y * sinA), (animationUV.x * sinA) + (animationUV.y * cosA)) + float2(0.5);
    float shape = img.x;
    float2 param_2 = imgUV;
    float2 param_3 = dudx;
    float2 param_4 = dudy;
    float param_5 = 8.0;
    float param_6 = img.y;
    img.y = blurEdge3x3(u_image, u_imageSmplr, param_2, param_3, param_4, param_5, param_6);
    float outerBlur = 1.0 - mix(1.0, img.y, shape);
    float innerBlur = mix(img.y, 0.0, shape);
    float contour = mix(img.z, 0.0, shape);
    outerBlur *= imgSoftFrame;
    float2 param_7 = animationUV;
    float param_8 = t;
    float param_9 = innerBlur;
    float shadow = shadowShape(param_7, param_8, param_9);
    float2 param_10 = animationUV;
    float param_11 = tCopy;
    float param_12 = innerBlur;
    float shadowCopy = shadowShape(param_10, param_11, param_12);
    float2 param_13 = animationUV;
    float param_14 = tCopy2;
    float param_15 = innerBlur;
    float shadowCopy2 = shadowShape(param_13, param_14, param_15);
    float inner = 0.8 + (0.8 * innerBlur);
    inner = mix(inner, 0.0, shadow);
    inner = mix(inner, 0.0, shadowCopy);
    inner = mix(inner, 0.0, shadowCopy2);
    inner *= mix(0.0, 2.0, params.u_innerGlow);
    inner += ((params.u_contour * 2.0) * contour);
    inner = fast::min(1.0, inner);
    inner *= (1.0 - shape);
    float outer = 0.0;
    t *= 3.0;
    t = mod(t - 0.1, 1.0);
    outer = 0.9 * powr(outerBlur, 0.8);
    float y = mod(animationUV.y - t, 1.0);
    float param_16 = 0.3;
    float param_17 = 0.65;
    float param_18 = y;
    float param_19 = 0.65;
    float param_20 = 1.0;
    float param_21 = y;
    float animatedMask = sst(param_16, param_17, param_18) * (1.0 - sst(param_19, param_20, param_21));
    animatedMask = 0.5 + animatedMask;
    outer *= animatedMask;
    outer *= mix(0.0, 5.0, powr(params.u_outerGlow, 2.0));
    outer *= imgSoftFrame;
    inner = powr(inner, 1.2);
    float heat = fast::clamp(inner + outer, 0.0, 1.0);
    heat += ((0.005 + (0.35 * params.u_noise)) * (fract(sin(dot(uv, float2(12.9898, 78.233))) * 43758.547) - 0.5));
    float mixer = heat * params.u_colorsCount;
    float4 gradient = params.u_colors[0];
    float _949 = gradient.w;
    float4 _951 = gradient;
    float3 _953 = _951.xyz * _949;
    gradient.x = _953.x;
    gradient.y = _953.y;
    gradient.z = _953.z;
    float outerShape = 0.0;
    for (int i = 1; i < 11; i++)
    {
        if (i > int(params.u_colorsCount))
        {
            break;
        }
        float m = fast::clamp(mixer - float(i - 1), 0.0, 1.0);
        if (i == 1)
        {
            outerShape = m;
        }
        float4 c = params.u_colors[i - 1];
        float _998 = c.w;
        float4 _999 = c;
        float3 _1001 = _999.xyz * _998;
        c.x = _1001.x;
        c.y = _1001.y;
        c.z = _1001.z;
        gradient = mix(gradient, c, float4(m));
    }
    float3 color = gradient.xyz * outerShape;
    float opacity = gradient.w * outerShape;
    float3 bgColor = params.u_colorBack.xyz * params.u_colorBack.w;
    color += (bgColor * (1.0 - opacity));
    opacity += (params.u_colorBack.w * (1.0 - opacity));
    color += float3(0.02 * (fract(sin(dot(uv + float2(1.0), float2(12.9898, 78.233))) * 43758.547) - 0.5));
    out.fragColor = float4(color, opacity);
    return out;
}

