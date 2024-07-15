//
//  ContrastFilter.swift
//  ImageFilter
//
//  Created by 郭 輝平 on 2024/07/15.
//

import Foundation
import MetalKit

class ContrastFilter: Filter {
  let device: MTLDevice
  let pipelineState: MTLComputePipelineState
  var contrast: Float
  
  init(device: MTLDevice, contrast: Float) {
    self.device = device
    self.contrast = contrast
    
    let library = device.makeDefaultLibrary()!
    let kernelFunction = library.makeFunction(name: "adjustContrast")!
    self.pipelineState = try! device.makeComputePipelineState(function: kernelFunction)
  }
  
  func encode(commandEncoder: MTLComputeCommandEncoder, inputTexture: MTLTexture, outputTexture: MTLTexture) {
    commandEncoder.setComputePipelineState(pipelineState)
    commandEncoder.setTexture(inputTexture, index: 0)
    commandEncoder.setTexture(outputTexture, index: 1)
    commandEncoder.setBytes(&contrast, length: MemoryLayout<Float>.size, index: 0)
    
    let threadgroupSize = MTLSizeMake(16, 16, 1)
    let threadgroupCount = MTLSizeMake(
      (inputTexture.width + threadgroupSize.width - 1) / threadgroupSize.width,
      (inputTexture.height + threadgroupSize.height - 1) / threadgroupSize.height,
      1)
    
    commandEncoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadgroupSize)
  }
}
