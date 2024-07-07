//
//  Shaders.metal
//  ImageFilter
//
//  Created by 郭 輝平 on 2024/07/07.
//

#include <metal_stdlib>
using namespace metal;

kernel void getPixelColor(texture2d<float, access::read> inTexture [[texture(0)]],
                          device float4 *outColor [[buffer(0)]],
                          constant uint2 *position [[buffer(1)]])
{
    *outColor = inTexture.read(*position);
}
