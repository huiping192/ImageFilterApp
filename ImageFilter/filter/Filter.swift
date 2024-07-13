//
//  Filter.swift
//  ImageFilter
//
//  Created by 郭 輝平 on 2024/07/08.
//

import Foundation
import MetalKit

protocol Filter: AnyObject {
  var device: MTLDevice { get }
  var pipelineState: MTLComputePipelineState { get }
  
  func encode(commandEncoder: MTLComputeCommandEncoder, inputTexture: MTLTexture, outputTexture: MTLTexture)
}
