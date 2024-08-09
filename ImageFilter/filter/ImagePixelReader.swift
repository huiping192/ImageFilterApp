//
//  ImageRGB.swift
//  ImageFilter
//
//  Created by 郭 輝平 on 2024/07/06.
//

import Foundation
import MetalKit
import CoreGraphics

protocol ImagePixelReadable {
  func loadImage(_ image: CGImage)
  func getPixelColor(at point: CGPoint) -> (red: Float, green: Float, blue: Float)?
}


class ImagePixelReader {
  
  private let cpuImagePixelReader = CPUImagePixelReader()
  private let gpuImagePixelReader = GPUImagePixelReader()
  
  
  func loadImage(_ image: NSImage) {
    guard let cgImage = convertToCGImage(image) else { return }
    cpuImagePixelReader.loadImage(cgImage)
    gpuImagePixelReader.loadImage(cgImage)
  }
  
  func getPixelColor(at point: CGPoint, useGPU: Bool = true) -> (red: Float, green: Float, blue: Float)? {
    if useGPU {
      return gpuImagePixelReader.getPixelColor(at: point)
    } else {
      return cpuImagePixelReader.getPixelColor(at: point)
    }
  }
}

private func convertToCGImage(_ nsImage: NSImage) -> CGImage? {
  var imageRect = CGRect(x: 0, y: 0, width: nsImage.size.width, height: nsImage.size.height)
  return nsImage.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
}



private class CPUImagePixelReader: ImagePixelReadable {
  private var image: CGImage?
  
  func loadImage(_ image: CGImage) {
    self.image = image
  }
  
  func getPixelColor(at point: CGPoint) -> (red: Float, green: Float, blue: Float)? {
    guard let image = image else { return nil }
    guard let dataProvider = image.dataProvider,
          let data = dataProvider.data,
          let pointer = CFDataGetBytePtr(data) else {
      return nil
    }
    
//    let width = image.width
//    let height = image.height
    let bytesPerPixel = image.bitsPerPixel / 8
    let bytesPerRow = image.bytesPerRow
    let pixelInfo = Int(point.y) * bytesPerRow + Int(point.x) * bytesPerPixel
    
    let red = Float(pointer[pixelInfo]) / 255.0
    let green = Float(pointer[pixelInfo + 1]) / 255.0
    let blue = Float(pointer[pixelInfo + 2]) / 255.0
    
    return (red: red, green: green, blue: blue)
  }
}

private class GPUImagePixelReader {
  private let device: MTLDevice
  private let commandQueue: MTLCommandQueue
  private let pipelineState: MTLComputePipelineState
  private var texture: MTLTexture?
  
  init() {
    guard let device = MTLCreateSystemDefaultDevice(),
          let commandQueue = device.makeCommandQueue() else {
      fatalError("can not use metal!")
    }
    
    self.device = device
    self.commandQueue = commandQueue
    
    
    let library = device.makeDefaultLibrary()!
    let kernelFunction = library.makeFunction(name: "getPixelColor")!
    
    do {
      pipelineState = try device.makeComputePipelineState(function: kernelFunction)
    } catch {
      print("Unable to create pipeline state: \(error)")
      fatalError("can not use metal!")
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
