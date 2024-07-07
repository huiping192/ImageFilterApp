//
//  GrayscaleFilter.swift
//  ImageFilter
//
//  Created by 郭 輝平 on 2024/07/07.
//

import Foundation
import MetalKit

enum GrayType: String, CaseIterable, Identifiable {
    case none, standard, luminance, desaturation
    var id: Self { self }
}

class GrayscaleFilter {
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
    let kernelFunction = library.makeFunction(name: "makeGray")!
    
    do {
      pipelineState = try device.makeComputePipelineState(function: kernelFunction)
    } catch {
      fatalError("Unable to create pipeline state: \(error)")
    }
  }
  
  func loadImage(_ image: CGImage) {
    let textureLoader = MTKTextureLoader(device: device)
    texture = try? textureLoader.newTexture(cgImage: image, options: [.textureUsage: MTLTextureUsage.shaderRead.rawValue as NSNumber])
  }
  
  func loadImage(_ image: NSImage) {
    loadImage(convertToCGImage(image)!)
  }
  
  private func convertToCGImage(_ nsImage: NSImage) -> CGImage? {
    var imageRect = CGRect(x: 0, y: 0, width: nsImage.size.width, height: nsImage.size.height)
    return nsImage.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
  }
  
  func makeStandardGrayImage () -> NSImage? {
    guard let outputTexture = makeGray() else {
      return nil
    }
    
    return convertTextureToUIImage(outputTexture)
  }
  
  func makeLuminanceGrayImage () -> NSImage? {
    guard let outputTexture = makeGray() else {
      return nil
    }
    
    return convertTextureToUIImage(outputTexture)
  }
  
  func makeDesaturationGrayImage () -> NSImage? {
    guard let outputTexture = makeGray() else {
      return nil
    }
    
    return convertTextureToUIImage(outputTexture)
  }
  
  private func makeGray() -> MTLTexture? {
    guard let texture else { return nil }
    guard let outputTexture = makeOutputTexture(matchingInput: texture) else {
      return nil
    }
    
    guard let commandBuffer = commandQueue.makeCommandBuffer(),
          let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
      return nil
    }
    
    computeEncoder.setComputePipelineState(pipelineState)
    computeEncoder.setTexture(texture, index: 0)
    computeEncoder.setTexture(outputTexture, index: 1)
    
    let threadgroupSize = MTLSizeMake(16, 16, 1)
    let threadgroupCount = MTLSizeMake(
      (texture.width + threadgroupSize.width - 1) / threadgroupSize.width,
      (texture.height + threadgroupSize.height - 1) / threadgroupSize.height,
      1)
    
    computeEncoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadgroupSize)
    computeEncoder.endEncoding()
    
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    
    return outputTexture
  }
  
  private func makeOutputTexture(matchingInput texture: MTLTexture) -> MTLTexture? {
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: .rgba8Unorm,
      width: texture.width,
      height: texture.height,
      mipmapped: false)
    descriptor.usage = [.shaderWrite, .shaderRead]
    return device.makeTexture(descriptor: descriptor)
  }
  
}
