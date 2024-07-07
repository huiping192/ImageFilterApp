//
//  ContentView.swift
//  ImageFilter
//
//  Created by 郭 輝平 on 2024/07/05.
//

import SwiftUI


class MouseTrackingView: NSView {
  var mouseMovedCallback: ((NSPoint) -> Void)?
  
  override func mouseMoved(with event: NSEvent) {
    super.mouseMoved(with: event)
    let location = convert(event.locationInWindow, from: nil)
    mouseMovedCallback?(location)
  }
  
  override func updateTrackingAreas() {
    super.updateTrackingAreas()
    
    for area in trackingAreas {
      removeTrackingArea(area)
    }
    
    let trackingArea = NSTrackingArea(rect: bounds, options: [.mouseMoved, .activeInKeyWindow], owner: self, userInfo: nil)
    addTrackingArea(trackingArea)
  }
}

struct MouseTrackingNSView: NSViewRepresentable {
  @Binding var position: NSPoint
  
  func makeNSView(context: Context) -> MouseTrackingView {
    let view = MouseTrackingView()
    view.mouseMovedCallback = { point in
      DispatchQueue.main.async {
        self.position = point
      }
    }
    return view
  }
  
  func updateNSView(_ nsView: MouseTrackingView, context: Context) {}
}

struct ContentView: View {
  @State private var image: NSImage?
  @State private var brightness: Double = 0
  @State private var isGrayscale: Bool = false
  @State private var rgbValues: String = "RGB: N/A"
  @State private var position: NSPoint = .zero
  
  private let imagePixelReader: ImagePixelReader = ImagePixelReader()
  
  var body: some View {
    NavigationView {
      // 左侧控制面板
      List {
        Button("Load") {
          openImage()
        }
        
        Button("Save") {
          saveImage()
        }
        
        Section(header: Text("adjust")) {
          Slider(value: $brightness, in: -1...1, step: 0.0) {
            Text("Brightness")
          }
          
          Toggle("Gray", isOn: $isGrayscale)
        }
      }
      .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
      .navigationTitle("Control")
      
      // 右侧图片显示
      VStack {
        if let image = image {
          GeometryReader { geometry in
            ZStack {
              Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .brightness(brightness)
                .grayscale(isGrayscale ? 1 : 0)
              
              MouseTrackingNSView(position: $position)
                .background(Color.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }.onChange(of: position) { newPosition in
              let convertedPosition = convertMousePosition(newPosition, in: geometry.size, for: image)
              
              if let pixelColor = imagePixelReader.getPixelColor(at: convertedPosition) {
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
  
  func openImage() {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.allowedFileTypes = ["png", "jpg", "jpeg", "tiff"]
    
    if panel.runModal() == .OK {
      if let url = panel.url {
        image = NSImage(contentsOf: url)
        if let image {
          imagePixelReader.loadImage(image)
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
