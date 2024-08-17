//
//  Shaders.metal
//  ImageFilter
//
//  Created by 郭 輝平 on 2024/07/07.
//

#include <metal_stdlib>
using namespace metal;

// get image pixel color
kernel void getPixelColor(texture2d<float, access::read> inTexture [[texture(0)]],
                          device float4 *outColor [[buffer(0)]],
                          constant uint2 *position [[buffer(1)]])
{
  *outColor = inTexture.read(*position);
}


// make color image to gray image
kernel void makeAveragingGray(texture2d<float, access::read> inTexture [[texture(0)]],
                              texture2d<float, access::write> outTexture [[texture(1)]],
                              uint2 gid [[thread_position_in_grid]]) {
  if (gid.x >= inTexture.get_width() || gid.y >= inTexture.get_height()) {
    return;
  }
  
  float4 color = inTexture.read(gid);
  float gray = (color.r + color.g + color.b) / 3.0;
  outTexture.write(float4(gray, gray, gray, color.a), gid);
}

kernel void makeLuminanceGray(texture2d<float, access::read> inTexture [[texture(0)]],
                              texture2d<float, access::write> outTexture [[texture(1)]],
                              uint2 gid [[thread_position_in_grid]]) {
  if (gid.x >= inTexture.get_width() || gid.y >= inTexture.get_height()) {
    return;
  }
  
  float4 color = inTexture.read(gid);
  float luminance = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));
  outTexture.write(float4(luminance, luminance, luminance, color.a), gid);
}

kernel void makeDesaturationGray(texture2d<float, access::read> inTexture [[texture(0)]],
                                 texture2d<float, access::write> outTexture [[texture(1)]],
                                 uint2 gid [[thread_position_in_grid]]) {
  if (gid.x >= inTexture.get_width() || gid.y >= inTexture.get_height()) {
    return;
  }
  
  float4 color = inTexture.read(gid);
  
  float maxValue = max(max(color.r, color.g), color.b);
  float minValue = min(min(color.r, color.g), color.b);
  
  float gray = (maxValue + minValue) / 2.0;
  
  outTexture.write(float4(gray, gray, gray, color.a), gid);
}


kernel void adjustBrightness(texture2d<float, access::read> inTexture [[texture(0)]],
                              texture2d<float, access::write> outTexture [[texture(1)]],
                              constant float &brightness [[ buffer(0) ]],
                              uint2 gid [[thread_position_in_grid]]) {
  if (gid.x >= inTexture.get_width() || gid.y >= inTexture.get_height()) {
    return;
  }
  
  float4 color = inTexture.read(gid);
  // alpha channel is not changed
  color.rgb += brightness;
  outTexture.write(color, gid);
}



kernel void adjustSaturationRGB(texture2d<float, access::read> inTexture [[texture(0)]],
                                texture2d<float, access::write> outTexture [[texture(1)]],
                                constant float &saturationFactor [[buffer(0)]],
                                uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    float4 inColor = inTexture.read(gid);

    // 计算灰度值 (使用 Rec. 601 标准)
    float luminance = dot(inColor.rgb, float3(0.299, 0.587, 0.114));

    // 调整饱和度
    float3 adjustedColor = mix(float3(luminance), inColor.rgb, saturationFactor);

    outTexture.write(float4(adjustedColor, inColor.a), gid);
}


kernel void adjustContrast(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           constant float &contrast [[buffer(0)]],
                           uint2 gid [[thread_position_in_grid]])
{
    // 确保我们没有超出纹理边界
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    
    // 读取输入颜色
    float4 color = inTexture.read(gid);
    
    float mappedContrast = contrast * 255.0;

    // 计算对比度因子
    float factor = (259.0 * (mappedContrast + 255.0)) / (255.0 * (259.0 - mappedContrast));
    
    // 应用对比度调整
    float3 adjustedColor = float3(
        clamp(factor * (color.r - 0.5) + 0.5, 0.0, 1.0),
        clamp(factor * (color.g - 0.5) + 0.5, 0.0, 1.0),
        clamp(factor * (color.b - 0.5) + 0.5, 0.0, 1.0)
    );
    
    // 写入调整后的颜色，保持原始的 alpha 值
    outTexture.write(float4(adjustedColor, color.a), gid);
}


kernel void invertColors(texture2d<float, access::read> inTexture [[texture(0)]],
                              texture2d<float, access::write> outTexture [[texture(1)]],
                              uint2 gid [[thread_position_in_grid]]) {
  if (gid.x >= inTexture.get_width() || gid.y >= inTexture.get_height()) {
    return;
  }
  
  float4 color = inTexture.read(gid);
  color.r = 1.0 - color.r;
  color.g = 1.0 - color.g;
  color.b = 1.0 - color.b;
  outTexture.write(color, gid);
}


kernel void threshold(texture2d<float, access::read> inTexture [[texture(0)]],
                      texture2d<float, access::write> outTexture [[texture(1)]],
                      constant float &threshold [[buffer(0)]],
                      uint2 gid [[thread_position_in_grid]])
{
  if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
    return;
  }
  
  float4 color = inTexture.read(gid);
  
  float intensity = dot(color.rgb, float3(0.299, 0.587, 0.114));
  float3 result = step(threshold, intensity);
  color = float4(result, color.a);
  outTexture.write(color, gid);
}
