//
//  FilterClient.swift
//  ImageFilter
//
//  Created by 郭 輝平 on 2024/07/10.
//

import Foundation
import MetalKit

enum GrayType: String, CaseIterable, Identifiable {
  case none, averaging, luminance, desaturation
  var id: Self { self }
}

class FilterClient {
  private let device: MTLDevice
  private let filterChain: FilterChain
  private var inputTexture: MTLTexture?
  
  private var averagingFilter: AveragingGrayFilter?
  private var luminanceFilter: LuminanceGrayFilter?
  private var desaturationFilter: DesaturationGrayFilter?
  private var brightnessFilter: BrightnessFilter?
  private var saturationFilter: SaturationFilter?

  init() {
    guard let device = MTLCreateSystemDefaultDevice() else {
      fatalError("Metal is not supported on this device")
    }
    self.device = device
    self.filterChain = FilterChain(device: device)
  }
  
  func loadImage(_ image: NSImage) {
    guard let cgImage = convertToCGImage(image) else {
      print("Failed to convert NSImage to CGImage")
      return
    }
    
    let textureLoader = MTKTextureLoader(device: device)
    inputTexture = try? textureLoader.newTexture(cgImage: cgImage, options: [.textureUsage: MTLTextureUsage.shaderRead.rawValue as NSNumber])
  }
  
  
  func toggleGray(grayType: GrayType) {
    switch grayType {
    case .none:
      toggleAveragingGray(isOn: false)
      toggleLuminanceGray(isOn: false)
      toggleDesaturationGray(isOn: false)
    case .averaging:
      toggleAveragingGray(isOn: true)
      toggleLuminanceGray(isOn: false)
      toggleDesaturationGray(isOn: false)
    case .luminance:
      toggleAveragingGray(isOn: false)
      toggleLuminanceGray(isOn: true)
      toggleDesaturationGray(isOn: false)
    case .desaturation:
      toggleAveragingGray(isOn: false)
      toggleLuminanceGray(isOn: false)
      toggleDesaturationGray(isOn: true)
    }
  }
  
  func adjustBrightness(value: Float) {
    if brightnessFilter == nil {
      brightnessFilter = BrightnessFilter(device: device, brightness: value)
      filterChain.add(filter: brightnessFilter)
    }
    
    brightnessFilter?.brightness = value
  }
  
  func adjustSaturation(value: Float) {
    if saturationFilter == nil {
      saturationFilter = SaturationFilter(device: device, saturation: value)
      filterChain.add(filter: saturationFilter)
    }
    
    saturationFilter?.saturation = value
  }
  
  private func toggleAveragingGray(isOn: Bool) {
    if isOn {
      if averagingFilter == nil {
        averagingFilter = AveragingGrayFilter(device: device)
      }
      filterChain.add(filter: averagingFilter!)
    } else {
      if let averagingFilter {
        filterChain.remove(filter: averagingFilter)
      }
    }
  }
  
  private func toggleLuminanceGray(isOn: Bool) {
    if isOn {
      if luminanceFilter == nil {
        luminanceFilter = LuminanceGrayFilter(device: device)
      }
      filterChain.add(filter: luminanceFilter!)
    } else {
      if let luminanceFilter {
        filterChain.remove(filter: luminanceFilter)
      }
    }
  }
  
  private func toggleDesaturationGray(isOn: Bool) {
    if isOn {
      if desaturationFilter == nil {
        desaturationFilter = DesaturationGrayFilter(device: device)
      }
      filterChain.add(filter: desaturationFilter!)
    } else {
      if let desaturationFilter {
        filterChain.remove(filter: desaturationFilter)
      }
    }
  }
  
  func applyFilters() -> NSImage? {
    guard let inputTexture = inputTexture else {
      print("No input image loaded")
      return nil
    }
    
    guard let outputTexture = filterChain.applyFilters(inputTexture: inputTexture) else {
      print("Failed to apply filters")
      return nil
    }
    
    return convertTextureToNSImage(outputTexture)
  }
  
  private func convertToCGImage(_ nsImage: NSImage) -> CGImage? {
    var imageRect = CGRect(x: 0, y: 0, width: nsImage.size.width, height: nsImage.size.height)
    return nsImage.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
  }
  
  private func convertTextureToNSImage(_ texture: MTLTexture) -> NSImage? {
    convertTextureToUIImage(texture)
  }
}
