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


kernel void gaussianBlur(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         constant float &radius [[buffer(0)]],
                         uint2 gid [[thread_position_in_grid]])
{
  
  // 检查是否超出纹理边界
  if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
    return;
  }
  
  // 如果 radius 为 0，直接输出原始像素
  if (radius <= 0.0) {
    float4 originalColor = inTexture.read(gid);
    outTexture.write(originalColor, gid);
    return;
  }
  
  // 定义模糊内核的大小，这决定了采样范围
  const int KERNEL_SIZE = 15;
  // 根据输入的radius计算高斯分布的标准差
  const float sigma = radius * 0.3;
  const float pi = 3.14159265359;
  
  
  // 初始化累积颜色和权重和
  float4 accumColor = float4(0);
  float weightSum = 0.0;
  
  // 遍历模糊内核
  for (int offsetY = -KERNEL_SIZE / 2; offsetY <= KERNEL_SIZE / 2; offsetY++) {
    for (int offsetX = -KERNEL_SIZE / 2; offsetX <= KERNEL_SIZE / 2; offsetX++) {
      // 计算采样位置
      uint2 samplePos = uint2(gid.x + offsetX, gid.y + offsetY);
      // 确保采样位置不超出纹理边界
      samplePos = clamp(samplePos, uint2(0, 0), uint2(inTexture.get_width() - 1, inTexture.get_height() - 1));
      
      // 读取采样位置的颜色
      float4 color = inTexture.read(samplePos);
      
      // 计算当前采样点到中心的距离
      float distance = length(float2(offsetX, offsetY));
      // 计算高斯权重
      float weight = (1.0 / sqrt(2.0 * pi * sigma * sigma)) * exp(-(distance * distance) / (2.0 * sigma * sigma));
      
      // 累加加权颜色和权重
      accumColor += color * weight;
      weightSum += weight;
    }
  }
  
  // 计算最终颜色
  float4 finalColor = accumColor / weightSum;
  // 写入结果到输出纹理
  outTexture.write(finalColor, gid);
}



kernel void sharpen(texture2d<float, access::read> inTexture [[texture(0)]],
                    texture2d<float, access::write> outTexture [[texture(1)]],
                    constant float &strength [[buffer(0)]],
                    uint2 gid [[thread_position_in_grid]])
{
  
  
  // 检查是否超出纹理边界
  if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
    return;
  }
  
  float4 sum = float4(0.0);
  // 定义卷积核的常量值
  float CENTER_WEIGHT = 5.0;
  float ADJACENT_WEIGHT = -1.0;
  float DIAGONAL_WEIGHT = 0.0;
  
  // 应用3x3卷积核
  for (int offsetY = -1; offsetY <= 1; offsetY++) {
    for (int offsetX = -1; offsetX <= 1; offsetX++) {
      uint2 samplePos = uint2(gid.x + offsetX, gid.y + offsetY);
      
      // 确保采样位置在纹理范围内
      samplePos = clamp(samplePos, uint2(0, 0), uint2(inTexture.get_width() - 1, inTexture.get_height() - 1));
      
      // 读取像素颜色
      float4 color = inTexture.read(samplePos);
      
      // 应用卷积核权重
      float weight;
      if (offsetX == 0 && offsetY == 0) {
        weight = CENTER_WEIGHT;
      } else if (abs(offsetX) + abs(offsetY) == 1) {
        weight = ADJACENT_WEIGHT;
      } else {
        weight = DIAGONAL_WEIGHT;
      }
      sum += color * weight;
    }
  }
  
  // 读取原始中心像素颜色
  float4 originalColor = inTexture.read(gid);
  
  // 根据强度参数混合原始颜色和锐化后的颜色
  float4 sharpened = mix(originalColor, sum, strength);
  
  // 确保颜色分量在 [0, 1] 范围内
  sharpened = clamp(sharpened, 0.0, 1.0);
  
  // 写入结果到输出纹理
  outTexture.write(sharpened, gid);
}
