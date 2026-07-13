#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct Params
{
    float2 u_resolution;
    float u_pixelRatio;
    float u_rotation;
    float4 u_colorBack;
    float4 u_colorShadow;
    float4 u_colorHighlight;
    float u_imageAspectRatio;
    float u_size;
    float u_shadows;
    float u_angle;
    float u_stretch;
    float u_shape;
    float u_distortion;
    float u_highlights;
    float u_distortionShape;
    float u_shift;
    float u_blur;
    float u_edges;
    float u_marginLeft;
    float u_marginRight;
    float u_marginTop;
    float u_marginBottom;
    float u_grainMixer;
    float u_grainOverlay;
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
float2 rotate(thread const float2& uv, thread const float& th)
{
    return float2x2(float2(cos(th), sin(th)), float2(-sin(th), cos(th))) * uv;
}

static inline __attribute__((always_inline))
float2 rotateAspect(thread float2& p, thread const float& a, thread const float& aspect)
{
    p.x *= aspect;
    float2 param = p;
    float param_1 = a;
    p = rotate(param, param_1);
    p.x /= aspect;
    return p;
}

static inline __attribute__((always_inline))
float smoothFract(thread const float& x)
{
    float f = fract(x);
    float w = fwidth(x);
    float edge = abs(f - 0.5) - 0.5;
    float band = smoothstep(-w, w, edge);
    return mix(f, 1.0 - f, band);
}

static inline __attribute__((always_inline))
float hash21(thread float2& p)
{
    p = fract(p * float2(0.3183099, 0.3678794)) + float2(0.1);
    p += float2(dot(p, p + float2(19.19)));
    return fract(p.x * p.y);
}

static inline __attribute__((always_inline))
float valueNoise(thread const float2& st)
{
    float2 i = floor(st);
    float2 f = fract(st);
    float2 param = i;
    float _111 = hash21(param);
    float a = _111;
    float2 param_1 = i + float2(1.0, 0.0);
    float _117 = hash21(param_1);
    float b = _117;
    float2 param_2 = i + float2(0.0, 1.0);
    float _123 = hash21(param_2);
    float c = _123;
    float2 param_3 = i + float2(1.0);
    float _129 = hash21(param_3);
    float d = _129;
    float2 u = (f * f) * (float2(3.0) - (f * 2.0));
    float x1 = mix(a, b, u.x);
    float x2 = mix(c, d, u.x);
    return mix(x1, x2, u.y);
}

static inline __attribute__((always_inline))
float getUvFrame(thread const float2& uv, thread const float& softness)
{
    float aax = 2.0 * fwidth(uv.x);
    float aay = 2.0 * fwidth(uv.y);
    float left = smoothstep(0.0, aax + softness, uv.x);
    float right = 1.0 - smoothstep((1.0 - softness) - aax, 1.0, uv.x);
    float bottom = smoothstep(0.0, aay + softness, uv.y);
    float top = 1.0 - smoothstep((1.0 - softness) - aay, 1.0, uv.y);
    return ((left * right) * bottom) * top;
}

static inline __attribute__((always_inline))
float4 samplePremultiplied(texture2d<float> tex, sampler texSmplr, thread const float2& uv)
{
    float4 c = tex.sample(texSmplr, uv);
    float _218 = c.w;
    float4 _220 = c;
    float3 _222 = _220.xyz * _218;
    c.x = _222.x;
    c.y = _222.y;
    c.z = _222.z;
    return c;
}

static inline __attribute__((always_inline))
float4 getBlur(texture2d<float> tex, sampler texSmplr, thread const float2& uv, thread const float2& texelSize, thread const float2& dir, thread const float& sigma)
{
    if (sigma <= 0.5)
    {
        return tex.sample(texSmplr, uv);
    }
    int radius = int(fast::min(50.0, ceil(3.0 * sigma)));
    float twoSigma2 = (2.0 * sigma) * sigma;
    float gaussianNorm = 1.0 / sqrt((6.2831855 * sigma) * sigma);
    float2 param = uv;
    float4 sum = samplePremultiplied(tex, texSmplr, param) * gaussianNorm;
    float weightSum = gaussianNorm;
    for (int i = 1; i <= 50; i++)
    {
        if (i > radius)
        {
            break;
        }
        float x = float(i);
        float w = exp((-(x * x)) / twoSigma2) * gaussianNorm;
        float2 offset = (dir * texelSize) * x;
        float2 param_1 = uv + offset;
        float4 s1 = samplePremultiplied(tex, texSmplr, param_1);
        float2 param_2 = uv - offset;
        float4 s2 = samplePremultiplied(tex, texSmplr, param_2);
        sum += ((s1 + s2) * w);
        weightSum += (2.0 * w);
    }
    float4 result = sum / float4(weightSum);
    if (result.w > 0.0)
    {
        float _344 = result.w;
        float4 _345 = result;
        float3 _348 = _345.xyz / float3(_344);
        result.x = _348.x;
        result.y = _348.y;
        result.z = _348.z;
    }
    return result;
}

fragment main0_out main0(main0_in in [[stage_in]], constant Params& params [[buffer(0)]], texture2d<float> u_image [[texture(0)]], sampler u_imageSmplr [[sampler(0)]], float4 gl_FragCoord [[position]])
{
    main0_out out = {};
    float patternRotation = ((-params.u_angle) * 3.1415927) / 180.0;
    float patternSize = mix(200.0, 5.0, params.u_size);
    float2 uv = in.v_imageUV;
    float2 uvMask = gl_FragCoord.xy / params.u_resolution;
    float2 sw = float2(0.005);
    float4 margins = float4(params.u_marginLeft, params.u_marginTop, params.u_marginRight, params.u_marginBottom);
    float mask = ((smoothstep(margins.x, margins.x + sw.x, uvMask.x + sw.x) * smoothstep(margins.z, margins.z + sw.x, (1.0 - uvMask.x) + sw.x)) * smoothstep(margins.y, margins.y + sw.y, uvMask.y + sw.y)) * smoothstep(margins.w, margins.w + sw.y, (1.0 - uvMask.y) + sw.y);
    float maskOuter = ((smoothstep(margins.x - sw.x, margins.x, uvMask.x + sw.x) * smoothstep(margins.z - sw.x, margins.z, (1.0 - uvMask.x) + sw.x)) * smoothstep(margins.y - sw.y, margins.y, uvMask.y + sw.y)) * smoothstep(margins.w - sw.y, margins.w, (1.0 - uvMask.y) + sw.y);
    float maskStroke = maskOuter - mask;
    float maskInner = ((smoothstep(margins.x - (2.0 * sw.x), margins.x, uvMask.x) * smoothstep(margins.z - (2.0 * sw.x), margins.z, 1.0 - uvMask.x)) * smoothstep(margins.y - (2.0 * sw.y), margins.y, uvMask.y)) * smoothstep(margins.w - (2.0 * sw.y), margins.w, 1.0 - uvMask.y);
    float maskStrokeInner = maskInner - mask;
    uv -= float2(0.5);
    uv *= patternSize;
    float2 param = uv;
    float param_1 = patternRotation;
    float param_2 = params.u_imageAspectRatio;
    float2 _639 = rotateAspect(param, param_1, param_2);
    uv = _639;
    float curve = 0.0;
    float patternY = uv.y / params.u_imageAspectRatio;
    if (params.u_shape > 4.5)
    {
        curve = 0.5 + ((0.5 * sin(1.5707964 * uv.x)) * cos(1.5707964 * patternY));
    }
    else
    {
        if (params.u_shape > 3.5)
        {
            curve = 10.0 * abs(fract(0.1 * patternY) - 0.5);
        }
        else
        {
            if (params.u_shape > 2.5)
            {
                curve = 4.0 * sin(0.23 * patternY);
            }
            else
            {
                if (params.u_shape > 1.5)
                {
                    curve = 0.5 + ((0.5 * sin(0.5 * uv.x)) * sin(1.7 * uv.x));
                }
            }
        }
    }
    float2 UvToFract = uv + float2(curve);
    float2 fractOrigUV = fract(uv);
    float2 floorOrigUV = floor(uv);
    float param_3 = UvToFract.x;
    float x = smoothFract(param_3);
    float xNonSmooth = fract(UvToFract.x) + 0.0001;
    float highlightsWidth = 2.0 * fast::max(0.001, fwidth(UvToFract.x));
    highlightsWidth += (2.0 * maskStrokeInner);
    float highlights = smoothstep(0.0, highlightsWidth, xNonSmooth);
    highlights *= smoothstep(1.0, 1.0 - highlightsWidth, xNonSmooth);
    highlights = 1.0 - highlights;
    highlights *= params.u_highlights;
    highlights = fast::clamp(highlights, 0.0, 1.0);
    highlights *= mask;
    float shadows = powr(x, 1.3);
    float distortion = 0.0;
    float fadeX = 1.0;
    float frameFade = 0.0;
    float aa = fwidth(xNonSmooth);
    aa = fast::max(aa, fwidth(uv.x));
    aa = fast::max(aa, fwidth(UvToFract.x));
    aa = fast::max(aa, 0.0001);
    if (params.u_distortionShape == 1.0)
    {
        distortion = -powr(1.5 * x, 3.0);
        distortion += (0.5 - params.u_shift);
        frameFade = powr(1.5 * x, 3.0);
        aa = fast::max(0.2, aa);
        aa += mix(0.2, 0.0, params.u_size);
        fadeX = smoothstep(0.0, aa, xNonSmooth) * smoothstep(1.0, 1.0 - aa, xNonSmooth);
        distortion = mix(0.5, distortion, fadeX);
    }
    else
    {
        if (params.u_distortionShape == 2.0)
        {
            distortion = 2.0 * powr(x, 2.0);
            distortion -= (0.5 + params.u_shift);
            frameFade = powr(abs(x - 0.5), 4.0);
            aa = fast::max(0.2, aa);
            aa += mix(0.2, 0.0, params.u_size);
            fadeX = smoothstep(0.0, aa, xNonSmooth) * smoothstep(1.0, 1.0 - aa, xNonSmooth);
            distortion = mix(0.5, distortion, fadeX);
            frameFade = mix(1.0, frameFade, 0.5 * fadeX);
        }
        else
        {
            if (params.u_distortionShape == 3.0)
            {
                distortion = powr(2.0 * (xNonSmooth - 0.5), 6.0);
                distortion -= 0.25;
                distortion -= params.u_shift;
                frameFade = 1.0 - (2.0 * powr(abs(x - 0.4), 2.0));
                aa = 0.15;
                aa += mix(0.1, 0.0, params.u_size);
                fadeX = smoothstep(0.0, aa, xNonSmooth) * smoothstep(1.0, 1.0 - aa, xNonSmooth);
                frameFade = mix(1.0, frameFade, fadeX);
            }
            else
            {
                if (params.u_distortionShape == 4.0)
                {
                    x = xNonSmooth;
                    distortion = sin((x + 0.25) * 6.2831855);
                    shadows = 0.5 + ((0.5 * asin(distortion)) / 1.5707964);
                    distortion *= 0.5;
                    distortion -= params.u_shift;
                    frameFade = 0.5 + (0.5 * sin(x * 6.2831855));
                }
                else
                {
                    if (params.u_distortionShape == 5.0)
                    {
                        distortion -= (powr(abs(x), 0.2) * x);
                        distortion += 0.33;
                        distortion -= (3.0 * params.u_shift);
                        distortion *= 0.33;
                        frameFade = 0.3 * smoothstep(0.0, 1.0, x);
                        shadows = powr(x, 2.5);
                        aa = fast::max(0.1, aa);
                        aa += mix(0.1, 0.0, params.u_size);
                        fadeX = smoothstep(0.0, aa, xNonSmooth) * smoothstep(1.0, 1.0 - aa, xNonSmooth);
                        distortion *= fadeX;
                    }
                }
            }
        }
    }
    float2 dudx = dfdx(in.v_imageUV);
    float2 dudy = dfdy(in.v_imageUV);
    float2 grainUV = in.v_imageUV - float2(0.5);
    grainUV *= (float2(0.8) / float2(length(dudx), length(dudy)));
    grainUV += float2(0.5);
    float2 param_4 = grainUV;
    float grain = valueNoise(param_4);
    grain = smoothstep(0.4, 0.7, grain);
    grain *= params.u_grainMixer;
    distortion = mix(distortion, 0.0, grain);
    shadows = fast::min(shadows, 1.0);
    shadows += maskStrokeInner;
    shadows *= mask;
    shadows = fast::min(shadows, 1.0);
    shadows *= powr(params.u_shadows, 2.0);
    shadows = fast::clamp(shadows, 0.0, 1.0);
    distortion *= (3.0 * params.u_distortion);
    frameFade *= params.u_distortion;
    fractOrigUV.x += distortion;
    float2 param_5 = floorOrigUV;
    float param_6 = -patternRotation;
    float param_7 = params.u_imageAspectRatio;
    float2 _1061 = rotateAspect(param_5, param_6, param_7);
    floorOrigUV = _1061;
    float2 param_8 = fractOrigUV;
    float param_9 = -patternRotation;
    float param_10 = params.u_imageAspectRatio;
    float2 _1070 = rotateAspect(param_8, param_9, param_10);
    fractOrigUV = _1070;
    uv = (floorOrigUV + fractOrigUV) / float2(patternSize);
    uv += float2(powr(maskStroke, 4.0));
    uv += float2(0.5);
    uv = mix(in.v_imageUV, uv, float2(smoothstep(0.0, 0.7, mask)));
    float blur = mix(0.0, 50.0, params.u_blur);
    blur = mix(0.0, blur, smoothstep(0.5, 1.0, mask));
    float edgeDistortion = mix(0.0, 0.04, params.u_edges);
    edgeDistortion += ((0.06 * frameFade) * params.u_edges);
    edgeDistortion *= mask;
    float2 param_11 = uv;
    float param_12 = edgeDistortion;
    float frame = getUvFrame(param_11, param_12);
    float stretch = 1.0 - (smoothstep(0.0, 0.5, xNonSmooth) * smoothstep(1.0, 0.5, xNonSmooth));
    stretch = powr(stretch, 2.0);
    stretch *= mask;
    float2 param_13 = uv;
    float param_14 = 0.1 + ((0.05 * mask) * frameFade);
    stretch *= getUvFrame(param_13, param_14);
    uv.y = mix(uv.y, 0.5, params.u_stretch * stretch);
    float2 param_15 = uv;
    float2 param_16 = (float2(1.0) / params.u_resolution) / float2(params.u_pixelRatio);
    float2 param_17 = float2(0.0, 1.0);
    float param_18 = blur;
    float4 image = getBlur(u_image, u_imageSmplr, param_15, param_16, param_17, param_18);
    float _1174 = image.w;
    float4 _1175 = image;
    float3 _1177 = _1175.xyz * _1174;
    image.x = _1177.x;
    image.y = _1177.y;
    image.z = _1177.z;
    float4 backColor = params.u_colorBack;
    float _1190 = backColor.w;
    float4 _1191 = backColor;
    float3 _1193 = _1191.xyz * _1190;
    backColor.x = _1193.x;
    backColor.y = _1193.y;
    backColor.z = _1193.z;
    float4 highlightColor = params.u_colorHighlight;
    float _1205 = highlightColor.w;
    float4 _1206 = highlightColor;
    float3 _1208 = _1206.xyz * _1205;
    highlightColor.x = _1208.x;
    highlightColor.y = _1208.y;
    highlightColor.z = _1208.z;
    float4 shadowColor = params.u_colorShadow;
    float3 color = highlightColor.xyz * highlights;
    float opacity = highlightColor.w * highlights;
    shadows = mix(shadows * shadowColor.w, 0.0, highlights);
    color = mix(color, shadowColor.xyz * shadowColor.w, float3(0.5 * shadows));
    color += (shadowColor.xyz * (0.5 * powr(shadows, 0.5)));
    opacity += shadows;
    color = fast::clamp(color, float3(0.0), float3(1.0));
    opacity = fast::clamp(opacity, 0.0, 1.0);
    color += ((image.xyz * (1.0 - opacity)) * frame);
    opacity += ((image.w * (1.0 - opacity)) * frame);
    color += (backColor.xyz * (1.0 - opacity));
    opacity += (backColor.w * (1.0 - opacity));
    float2 param_19 = grainUV;
    float param_20 = 1.0;
    float2 param_21 = rotate(param_19, param_20) + float2(3.0);
    float grainOverlay = valueNoise(param_21);
    float2 param_22 = grainUV;
    float param_23 = 2.0;
    float2 param_24 = rotate(param_22, param_23) + float2(-1.0);
    grainOverlay = mix(grainOverlay, valueNoise(param_24), 0.5);
    grainOverlay = powr(grainOverlay, 1.3);
    float grainOverlayV = (grainOverlay * 2.0) - 1.0;
    float3 grainOverlayColor = float3(step(0.0, grainOverlayV));
    float grainOverlayStrength = params.u_grainOverlay * abs(grainOverlayV);
    grainOverlayStrength = powr(grainOverlayStrength, 0.8);
    grainOverlayStrength *= mask;
    color = mix(color, grainOverlayColor, float3(0.35 * grainOverlayStrength));
    opacity += (0.5 * grainOverlayStrength);
    opacity = fast::clamp(opacity, 0.0, 1.0);
    out.fragColor = float4(color, opacity);
    return out;
}

