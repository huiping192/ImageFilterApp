//
//  FilterChain.swift
//  ImageFilter
//
//  Created by 郭 輝平 on 2024/07/10.
//

import Foundation
import MetalKit

class FilterChain {
  let device: MTLDevice
  let commandQueue: MTLCommandQueue
  var filters: [Filter]
  
  init(device: MTLDevice) {
    self.device = device
    self.commandQueue = device.makeCommandQueue()!
    self.filters = []
  }
  
  func add(filter: Filter?) {
    guard let filter else { return }
    filters.append(filter)
  }
  
  func remove(filter: Filter?) {
    guard let filter else { return }
    filters.removeAll { $0 === filter }
  }
  
  func applyFilters(inputTexture: MTLTexture) -> MTLTexture? {
    guard !filters.isEmpty else { return inputTexture }
    
    var currentTexture = inputTexture
    let outputTexture = makeOutputTexture(matchingInput: currentTexture)

    let commandBuffer = commandQueue.makeCommandBuffer()!
    
    for filter in filters {
      guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return nil }
      filter.encode(commandEncoder: computeEncoder, inputTexture: currentTexture, outputTexture: outputTexture)
      computeEncoder.endEncoding()
      
      currentTexture = outputTexture
    }
    
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    
    return outputTexture
  }
  
  private func makeOutputTexture(matchingInput texture: MTLTexture) -> MTLTexture {
    let textureDescriptor = MTLTextureDescriptor()
    
    textureDescriptor.textureType = texture.textureType
    textureDescriptor.pixelFormat = texture.pixelFormat
    textureDescriptor.width = texture.width
    textureDescriptor.height = texture.height
    textureDescriptor.depth = texture.depth
    textureDescriptor.mipmapLevelCount = texture.mipmapLevelCount
    textureDescriptor.sampleCount = texture.sampleCount
    textureDescriptor.arrayLength = texture.arrayLength
    
    textureDescriptor.usage = [.shaderWrite, .shaderRead]
    
    return device.makeTexture(descriptor: textureDescriptor)!
  }
}
