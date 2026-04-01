import AppKit
import CoreGraphics
@preconcurrency import CoreImage
import CoreText
import ImageIO

public struct ExifMetadata {
    public var make: String?
    public var model: String?
    public var focalLength: Double?
    public var aperture: Double?
    public var exposureTime: Double?
    public var iso: Int?

    public init(make: String? = nil, model: String? = nil, focalLength: Double? = nil,
                aperture: Double? = nil, exposureTime: Double? = nil, iso: Int? = nil) {
        self.make = make
        self.model = model
        self.focalLength = focalLength
        self.aperture = aperture
        self.exposureTime = exposureTime
        self.iso = iso
    }

    public var formattedString: String? {
        var parts: [String] = []

        let cameraParts = [make, model].compactMap { $0 }
        if !cameraParts.isEmpty {
            parts.append(cameraParts.joined(separator: " "))
        }

        if let fl = focalLength {
            parts.append(fl == fl.rounded() ? "\(Int(fl))mm" : String(format: "%.1fmm", fl))
        }

        if let ap = aperture {
            parts.append(String(format: "f/%.1f", ap))
        }

        if let et = exposureTime {
            if et >= 1 {
                parts.append(String(format: "%.1fs", et))
            } else {
                parts.append("1/\(Int(round(1.0 / et)))s")
            }
        }

        if let iso {
            parts.append("ISO \(iso)")
        }

        return parts.isEmpty ? nil : parts.joined(separator: "  ")
    }

    public static func read(from url: URL) -> ExifMetadata {
        var meta = ExifMetadata()
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return meta
        }

        if let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any] {
            meta.make = tiff[kCGImagePropertyTIFFMake] as? String
            meta.model = tiff[kCGImagePropertyTIFFModel] as? String
        }

        if let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any] {
            meta.focalLength = exif[kCGImagePropertyExifFocalLength] as? Double
            meta.aperture = exif[kCGImagePropertyExifFNumber] as? Double
            meta.exposureTime = exif[kCGImagePropertyExifExposureTime] as? Double
            if let isoValues = exif[kCGImagePropertyExifISOSpeedRatings] as? [Int], let first = isoValues.first {
                meta.iso = first
            }
        }

        return meta
    }
}

public enum ImageProcessor {

    private static let ciContext = CIContext()

    public struct RGBComponents: Sendable {
        public var red: CGFloat
        public var green: CGFloat
        public var blue: CGFloat

        public init(red: CGFloat, green: CGFloat, blue: CGFloat) {
            self.red = red
            self.green = green
            self.blue = blue
        }

        public init(nsColor: NSColor) {
            let c = nsColor.usingColorSpace(.sRGB) ?? NSColor.white
            self.red = c.redComponent
            self.green = c.greenComponent
            self.blue = c.blueComponent
        }

        public var nsColor: NSColor {
            NSColor(srgbRed: red, green: green, blue: blue, alpha: 1.0)
        }

        public func cgColor(in colorSpace: CGColorSpace) -> CGColor {
            CGColor(colorSpace: colorSpace, components: [red, green, blue, 1.0])
                ?? CGColor(red: red, green: green, blue: blue, alpha: 1.0)
        }
    }

    public struct Settings: Sendable {
        public var outputWidth: Int
        public var outputHeight: Int
        public var margin: Int
        public var frameMode: FrameMode
        public var frameColor: RGBComponents
        public var borderWidth: CGFloat?
        public var borderColor: RGBComponents?
        public var showMetadata: Bool
        public var metadataFontName: String
        public var metadataFontSize: CGFloat
        public var metadataColor: RGBComponents
        public var outputFormat: OutputFormat

        public init(outputWidth: Int, outputHeight: Int, margin: Int,
                    frameMode: FrameMode = .solidColor, frameColor: NSColor,
                    borderWidth: CGFloat? = nil, borderColor: NSColor? = nil,
                    showMetadata: Bool, metadataFontName: String, metadataFontSize: CGFloat,
                    metadataColor: NSColor,
                    outputFormat: OutputFormat) {
            self.outputWidth = outputWidth
            self.outputHeight = outputHeight
            self.margin = margin
            self.frameMode = frameMode
            self.frameColor = RGBComponents(nsColor: frameColor)
            self.borderWidth = borderWidth
            self.borderColor = borderColor.map { RGBComponents(nsColor: $0) }
            self.showMetadata = showMetadata
            self.metadataFontName = metadataFontName
            self.metadataFontSize = metadataFontSize
            self.metadataColor = RGBComponents(nsColor: metadataColor)
            self.outputFormat = outputFormat
        }
    }

    public static func process(imageURL: URL, settings: Settings) throws -> Data {
        guard let cgImage = loadOrientedImage(from: imageURL) else {
            throw ProcessingError.unableToLoadImage
        }

        let outputWidth = settings.outputWidth
        let outputHeight = settings.outputHeight
        let margin = settings.margin

        let metadata = settings.showMetadata ? ExifMetadata.read(from: imageURL) : nil
        let metadataText = metadata?.formattedString

        let metadataHeight = (metadataText != nil) ? max(margin / 3, 30) : 0

        let availableWidth = outputWidth - (margin * 2)
        let availableHeight = outputHeight - (margin * 2) - metadataHeight

        guard availableWidth > 0, availableHeight > 0 else {
            throw ProcessingError.marginTooLarge
        }

        let scale = min(
            Double(availableWidth) / Double(cgImage.width),
            Double(availableHeight) / Double(cgImage.height)
        )
        let scaledWidth = Int(Double(cgImage.width) * scale)
        let scaledHeight = Int(Double(cgImage.height) * scale)

        let offsetX = (outputWidth - scaledWidth) / 2
        let offsetY = margin + (availableHeight - scaledHeight) / 2

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil,
                  width: outputWidth,
                  height: outputHeight,
                  bitsPerComponent: 16,
                  bytesPerRow: 0,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            throw ProcessingError.unableToCreateContext
        }

        // CoreGraphics uses bottom-left origin
        let flippedY = outputHeight - offsetY - scaledHeight
        let imageRect = CGRect(x: offsetX, y: flippedY, width: scaledWidth, height: scaledHeight)

        // Fill background based on frame mode
        switch settings.frameMode {
        case .solidColor:
            context.setFillColor(settings.frameColor.cgColor(in: colorSpace))
            context.fill(CGRect(x: 0, y: 0, width: outputWidth, height: outputHeight))

        case .blurredImage:
            drawBlurredBackground(cgImage, in: context, outputWidth: outputWidth, outputHeight: outputHeight)
            if let bw = settings.borderWidth, bw > 0 {
                let borderRect = imageRect.insetBy(dx: -bw / 2, dy: -bw / 2)
                let borderComponents = settings.borderColor ?? RGBComponents(red: 1, green: 1, blue: 1)
                context.setStrokeColor(borderComponents.cgColor(in: colorSpace))
                context.setLineWidth(bw)
                context.stroke(borderRect)
            }
        }

        // Draw image
        context.interpolationQuality = .high
        context.draw(cgImage, in: imageRect)

        // Draw metadata centered between bottom of image and bottom of output
        if let text = metadataText {
            drawMetadataText(
                text,
                in: context,
                outputWidth: outputWidth,
                textCenterY: flippedY / 2,
                color: settings.metadataColor.cgColor(in: colorSpace),
                fontName: settings.metadataFontName,
                fontSize: settings.metadataFontSize
            )
        }

        guard let outputImage = context.makeImage() else {
            throw ProcessingError.unableToCreateOutput
        }

        return try encodeImage(outputImage, format: settings.outputFormat)
    }

    // MARK: - Private

    private static func loadOrientedImage(from url: URL) -> CGImage? {
        guard let nsImage = NSImage(contentsOf: url) else { return nil }

        // Use pixel dimensions from the best representation, not point-based size
        guard let bestRep = nsImage.representations.first else { return nil }
        let pixelWidth = bestRep.pixelsWide
        let pixelHeight = bestRep.pixelsHigh
        guard pixelWidth > 0, pixelHeight > 0 else { return nil }

        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelWidth,
            pixelsHigh: pixelHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        nsImage.draw(in: NSRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight),
                     from: .zero, operation: .sourceOver, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()

        return rep.cgImage
    }

    private static func drawBlurredBackground(
        _ image: CGImage,
        in context: CGContext,
        outputWidth: Int,
        outputHeight: Int
    ) {
        let ciImage = CIImage(cgImage: image)
        let blurRadius = Double(max(outputWidth, outputHeight)) * 0.03

        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else { return }
        blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter.setValue(blurRadius, forKey: kCIInputRadiusKey)

        guard let blurred = blurFilter.outputImage else { return }

        // Crop to original extent (blur expands the image)
        let cropped = blurred.cropped(to: ciImage.extent)

        guard let blurredCG = ciContext.createCGImage(cropped, from: cropped.extent) else { return }

        // Scale blurred image to fill the entire output (cover mode)
        let scaleX = CGFloat(outputWidth) / CGFloat(blurredCG.width)
        let scaleY = CGFloat(outputHeight) / CGFloat(blurredCG.height)
        let fillScale = max(scaleX, scaleY)
        let fillW = CGFloat(blurredCG.width) * fillScale
        let fillH = CGFloat(blurredCG.height) * fillScale
        let fillX = (CGFloat(outputWidth) - fillW) / 2.0
        let fillY = (CGFloat(outputHeight) - fillH) / 2.0

        context.interpolationQuality = .high
        context.draw(blurredCG, in: CGRect(x: fillX, y: fillY, width: fillW, height: fillH))
    }

    private static func encodeImage(_ image: CGImage, format: OutputFormat) throws -> Data {
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData as CFMutableData,
            format.utType.identifier as CFString,
            1,
            nil
        ) else {
            throw ProcessingError.unableToCreateOutput
        }

        let properties: [CFString: Any] = format.supportsLossless
            ? [:]
            : [kCGImageDestinationLossyCompressionQuality: 1.0]
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw ProcessingError.unableToCreateOutput
        }

        return mutableData as Data
    }

    private static func drawMetadataText(
        _ text: String,
        in context: CGContext,
        outputWidth: Int,
        textCenterY: Int,
        color: CGColor,
        fontName: String,
        fontSize: CGFloat
    ) {
        let textColor = color
        let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
        let textBounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)

        let textX = (CGFloat(outputWidth) - textBounds.width) / 2.0
        let textY = CGFloat(textCenterY) - textBounds.height / 2.0

        context.saveGState()
        context.textPosition = CGPoint(x: textX, y: textY)
        CTLineDraw(line, context)
        context.restoreGState()
    }

    public enum ProcessingError: LocalizedError {
        case unableToLoadImage
        case marginTooLarge
        case unableToCreateContext
        case unableToCreateOutput

        public var errorDescription: String? {
            switch self {
            case .unableToLoadImage:    return "Unable to load image."
            case .marginTooLarge:       return "Margin is too large for the output size."
            case .unableToCreateContext: return "Internal rendering error."
            case .unableToCreateOutput: return "Unable to create output image."
            }
        }
    }
}
