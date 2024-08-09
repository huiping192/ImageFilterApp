//
//  DesaturationGrayFilter.swift
//  ImageFilter
//
//  Created by 郭 輝平 on 2024/07/10.
//

import Foundation
import MetalKit

class DesaturationGrayFilter: BaseFilter {
  
  init(device: MTLDevice) {
    super.init(device: device, kernelFunctionName: "makeDesaturationGray")
  }
  
  override func setupCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
  }
}
