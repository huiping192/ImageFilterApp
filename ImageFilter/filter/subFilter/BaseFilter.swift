//
//  BaseFilter.swift
//  ImageFilter
//
//  Created by Huiping Guo on 2024/08/10.
//

import Foundation
import MetalKit

class BaseFilter: Filter {
  let device: MTLDevice
  let pipelineState: MTLComputePipelineState
  
  init(device: MTLDevice, kernelFunctionName: String) {
    self.device = device
    
    let library = device.makeDefaultLibrary()!
    let kernelFunction = library.makeFunction(name: kernelFunctionName)!
    self.pipelineState = try! device.makeComputePipelineState(function: kernelFunction)
  }
  
  func encode(commandEncoder: MTLComputeCommandEncoder, inputTexture: MTLTexture, outputTexture: MTLTexture) {
    commandEncoder.setComputePipelineState(pipelineState)
    commandEncoder.setTexture(inputTexture, index: 0)
    commandEncoder.setTexture(outputTexture, index: 1)
    
    setupCommandEncoder(commandEncoder: commandEncoder)
    
    let threadgroupSize = MTLSizeMake(16, 16, 1)
    let threadgroupCount = MTLSizeMake(
      (inputTexture.width + threadgroupSize.width - 1) / threadgroupSize.width,
      (inputTexture.height + threadgroupSize.height - 1) / threadgroupSize.height,
      1)
    
    commandEncoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadgroupSize)
  }
  
  func setupCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
    fatalError("Subclasses must implement setupCommandEncoder(commandEncoder:)")
  }
}
