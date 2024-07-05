//
//  ImageRGB.swift
//  ImageFilter
//
//  Created by 郭 輝平 on 2024/07/06.
//

import Foundation
import MetalKit
import CoreGraphics

class ImagePixelReader {
  private let device: MTLDevice
  private let commandQueue: MTLCommandQueue
  private let pipelineState: MTLComputePipelineState
  private var texture: MTLTexture?
  
  init?() {
    guard let device = MTLCreateSystemDefaultDevice(),
          let commandQueue = device.makeCommandQueue() else {
      return nil
    }
    
    self.device = device
    self.commandQueue = commandQueue
    
    let kernelSource = """
    kernel void getPixelColor(texture2d<float, access::read> inTexture [[texture(0)]],
                              device float4 *outColor [[buffer(0)]],
                              constant uint2 *position [[buffer(1)]])
    {
        *outColor = inTexture.read(*position);
    }
    """
    
    let library = try! device.makeLibrary(source: kernelSource, options: nil)
    let kernelFunction = library.makeFunction(name: "getPixelColor")!
    
    do {
      pipelineState = try device.makeComputePipelineState(function: kernelFunction)
    } catch {
      print("Unable to create pipeline state: \(error)")
      return nil
    }
  }
  
  func loadImage(_ image: CGImage) {
    let textureLoader = MTKTextureLoader(device: device)
    texture = try? textureLoader.newTexture(cgImage: image, options: [.textureUsage: MTLTextureUsage.shaderRead.rawValue as NSNumber])
  }
  
  func getPixelColor(at point: CGPoint) -> (red: Float, green: Float, blue: Float)? {
    guard let texture = texture else { return nil }
    
    let x = Int(point.x)
    let y = Int(point.y)
    
    if x < 0 || x >= texture.width || y < 0 || y >= texture.height {
      return nil
    }
    
    let colorBuffer = device.makeBuffer(length: MemoryLayout<SIMD4<Float>>.size, options: .storageModeShared)!
    
    let commandBuffer = commandQueue.makeCommandBuffer()!
    let commandEncoder = commandBuffer.makeComputeCommandEncoder()!
    
    commandEncoder.setComputePipelineState(pipelineState)
    commandEncoder.setTexture(texture, index: 0)
    commandEncoder.setBuffer(colorBuffer, offset: 0, index: 0)
    
    // 使用 x 和 y 坐标
    var position = SIMD2<UInt32>(UInt32(x), UInt32(y))
    commandEncoder.setBytes(&position, length: MemoryLayout<SIMD2<UInt32>>.size, index: 1)
    
    let threadgroupSize = MTLSizeMake(1, 1, 1)
    let threadgroupCount = MTLSizeMake(1, 1, 1)
    
    commandEncoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadgroupSize)
    commandEncoder.endEncoding()
    
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    
    let color = colorBuffer.contents().load(as: SIMD4<Float>.self)
    
    return (red: color.x, green: color.y, blue: color.z)
  }
}
