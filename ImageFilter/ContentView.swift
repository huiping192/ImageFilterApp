//
//  ContentView.swift
//  ImageFilter
//
//  Created by 郭 輝平 on 2024/07/05.
//

import SwiftUI

struct ContentView: View {
  @State private var image: NSImage?
  @State private var originImage: NSImage?
  @State private var brightness: Float = 0
  @State private var saturation: Float = 1
  @State private var contrast: Float = 0
  @State private var rgbValues: String = "RGB: N/A"
  @State private var position: NSPoint = .zero
  @State private var selectedGrayType: GrayType = .none
  @State private var invertColor: Bool = false
  @State private var threshold: Float = 0.5
  @State private var thresholdEnable: Bool = false
  @State private var gaussianBlur: Float = 0
  @State private var sharpen: Float = 0

  private let imagePixelReader: ImagePixelReader = ImagePixelReader()
  private let filterClient = FilterClient()

  var body: some View {
    NavigationView {
      // 左侧控制面板
      List {
        Section(header: Text("Image Actions")) {
          Button("Load Image", action: openImage)
          Button("Save Image", action: saveImage)
        }
        
        Section(header: Text("Adjustments")) {
          VStack(alignment: .leading) {
            Text("Brightness: \(brightness, specifier: "%.2f")")
            Slider(value: $brightness, in: -1...1, step: 0.01)
              .onChange(of: brightness) {
                updateImage()
              }
          }
          
          VStack(alignment: .leading) {
            Text("Saturation: \(saturation, specifier: "%.2f")")
            Slider(value: $saturation, in: 0...2, step: 0.01)
              .onChange(of: saturation) {
                updateImage()
              }
          }
          
          VStack(alignment: .leading) {
            Text("Contrast: \(contrast, specifier: "%.2f")")
            Slider(value: $contrast, in: -1...1, step: 0.01)
              .onChange(of: contrast) {
                updateImage()
              }
          }
          
          VStack(alignment: .leading) {
            Text("Grayscale Type")
            Picker("", selection: $selectedGrayType) {
              ForEach(GrayType.allCases) { grayType in
                Text(grayType.rawValue.capitalized).tag(grayType)
              }
            }
            .pickerStyle(RadioGroupPickerStyle())
            .onChange(of: selectedGrayType) {
              updateImage()
            }
          }
          
          HStack {
            Text("InvertColor")
            Toggle("", isOn: $invertColor)
              .labelsHidden()
          }
          .onChange(of: invertColor) {
            updateImage()
          }
          
          VStack(alignment: .leading) {
            HStack {
              Text("Threshold: \(threshold, specifier: "%.2f")")
              Toggle("", isOn: $thresholdEnable)
                .labelsHidden()
                .onChange(of: thresholdEnable) {
                  updateImage()
                }
            }
            Slider(value: $threshold, in: 0...1, step: 0.01)
              .onChange(of: threshold) {
                updateImage()
              }
          }
          
          VStack(alignment: .leading) {
            Text("GaussianBlur: \(gaussianBlur, specifier: "%.2f")")
            Slider(value: $gaussianBlur, in: 0...25, step: 1)
              .onChange(of: gaussianBlur) {
                updateImage()
              }
          }
          
          VStack(alignment: .leading) {
            Text("Sharpen: \(sharpen, specifier: "%.2f")")
            Slider(value: $sharpen, in: 0...1, step: 0.01)
              .onChange(of: sharpen) {
                updateImage()
              }
          }
        }
      }
      .listStyle(SidebarListStyle())
      .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
      .navigationTitle("Image Editor")
      
      // 右侧图片显示
      VStack {
        if let image = image {
          GeometryReader { geometry in
            ZStack {
              Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
              
              MouseTrackingNSView(position: $position)
                .background(Color.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }.onChange(of: position) { _, newPosition in
              let convertedPosition = convertMousePosition(newPosition, in: geometry.size, for: image)
              
              if let pixelColor = imagePixelReader.getPixelColor(at: convertedPosition, useGPU: false) {
                rgbValues = String(format: "RGB: (%d, %d, %d)", Int(pixelColor.red * 255), Int(pixelColor.green * 255), Int(pixelColor.blue * 255))
              } else {
                rgbValues = "RGB: N/A"
              }
            }
          }
        } else {
          Text("Load image to show here.")
        }
        
        Text(rgbValues).padding()
      }
      .frame(minWidth: 300, idealWidth: 500)
      .navigationTitle("Image Preview")
    }
  }
  
  func updateImage() {
    filterClient.toggleGray(grayType: selectedGrayType)
    filterClient.adjustBrightness(value: brightness)
    filterClient.adjustSaturation(value: saturation)
    filterClient.adjustContrast(value: contrast)
    filterClient.toggleInvertColor(isOn: invertColor)
    filterClient.adjustThreshold(value: threshold, thresholdEnable: thresholdEnable)
    filterClient.adjustGaussianBlur(value: gaussianBlur)
    filterClient.adjustSharpen(value: sharpen)

    if let newImage = filterClient.applyFilters() {
      image = newImage
    } else {
      image = originImage
    }
    
    imagePixelReader.loadImage(image!)
  }
  
  func openImage() {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.allowedContentTypes = [.png, .jpeg, .tiff]
    if panel.runModal() == .OK {
      if let url = panel.url {
        image = NSImage(contentsOf: url)
        originImage = image
        if let image {
          imagePixelReader.loadImage(image)
          filterClient.loadImage(image)
        }
      }
    }
  }
  
  func saveImage() {
    guard let image = image else { return }
    
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.png]
    panel.canCreateDirectories = true
    panel.isExtensionHidden = false
    panel.title = "Save Image"
    panel.message = "Choose a folder and a name to store the image."
    panel.nameFieldLabel = "Image file name:"
    
    if panel.runModal() == .OK {
      if let url = panel.url {
        if let tiffData = image.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapImage.representation(using: .png, properties: [:]) {
          try? pngData.write(to: url)
        }
      }
    }
  }
}

func convertMousePosition(_ mousePosition: NSPoint, in viewSize: CGSize, for image: NSImage) -> NSPoint {
  let imageAspectRatio = image.size.width / image.size.height
  let viewAspectRatio = viewSize.width / viewSize.height
  
  var scaledImageSize: CGSize
  if imageAspectRatio > viewAspectRatio {
    scaledImageSize = CGSize(width: viewSize.width, height: viewSize.width / imageAspectRatio)
  } else {
    scaledImageSize = CGSize(width: viewSize.height * imageAspectRatio, height: viewSize.height)
  }
  
  let xOffset = (viewSize.width - scaledImageSize.width) / 2
  let yOffset = (viewSize.height - scaledImageSize.height) / 2
  
  let imageX = (mousePosition.x - xOffset) * (image.size.width / scaledImageSize.width)
  let imageY = (mousePosition.y - yOffset) * (image.size.height / scaledImageSize.height)
  
  return NSPoint(x: imageX, y: image.size.height - imageY)
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

#Preview {
  ContentView()
}
