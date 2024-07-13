//
//  Help.swift
//  ImageFilter
//
//  Created by 郭 輝平 on 2024/07/07.
//

import Foundation
import MetalKit

func convertTextureToUIImage(_ texture: MTLTexture) -> NSImage? {
  // 1. 获取纹理的宽高和像素格式
  let width = texture.width
  let height = texture.height
  let pixelFormat = texture.pixelFormat
  
  // 2. 检查像素格式是否支持转换
  guard pixelFormat == .bgra8Unorm || pixelFormat == .rgba8Unorm else {
    print("Unsupported pixel format")
    return nil
  }
  
  // 3. 创建一个字节数组来存储纹理数据
  let rowBytes = width * 4
  let length = rowBytes * height
  var rawData = [UInt8](repeating: 0, count: length)
  
  // 4. 从纹理中读取数据
  texture.getBytes(&rawData,
                   bytesPerRow: rowBytes,
                   from: MTLRegionMake2D(0, 0, width, height),
                   mipmapLevel: 0)
  
  // 5. 创建一个指向字节数组的指针
  let rawDataPointer = UnsafeMutablePointer<UInt8>(&rawData)
  
  // 6. 创建一个指向指针的指针
  let dataPointer = UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>.allocate(capacity: 1)
  dataPointer.initialize(to: rawDataPointer)
  
  // 7. 创建 NSBitmapImageRep
  let bitmapRep = NSBitmapImageRep(bitmapDataPlanes: dataPointer,
                                   pixelsWide: width,
                                   pixelsHigh: height,
                                   bitsPerSample: 8,
                                   samplesPerPixel: 4,
                                   hasAlpha: true,
                                   isPlanar: false,
                                   colorSpaceName: .deviceRGB,
                                   bytesPerRow: rowBytes,
                                   bitsPerPixel: 32)
  
  // 8. 创建 NSImage
  if let bitmapRep = bitmapRep {
    let image = NSImage(size: NSSize(width: width, height: height))
    image.addRepresentation(bitmapRep)
    return image
  } else {
    return nil
  }
}
