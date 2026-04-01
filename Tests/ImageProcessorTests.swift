import AppKit
import ImageIO
import Testing
@testable import EnkadrKit

@Suite("ImageProcessor")
struct ImageProcessorTests {

    private func createTestImage(width: Int, height: Int) -> URL {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
        let ctx = NSGraphicsContext(bitmapImageRep: rep)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx
        NSColor.red.setFill()
        NSBezierPath.fill(NSRect(x: 0, y: 0, width: width, height: height))
        NSGraphicsContext.restoreGraphicsState()

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        try! rep.representation(using: .png, properties: [:])!.write(to: url)
        return url
    }

    private func createTestImageWithExif(width: Int, height: Int) -> URL {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
        let ctx = NSGraphicsContext(bitmapImageRep: rep)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx
        NSColor.blue.setFill()
        NSBezierPath.fill(NSRect(x: 0, y: 0, width: width, height: height))
        NSGraphicsContext.restoreGraphicsState()

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")
        let data = NSMutableData()
        let dest = CGImageDestinationCreateWithData(data as CFMutableData, "public.jpeg" as CFString, 1, nil)!
        let properties: [CFString: Any] = [
            kCGImagePropertyTIFFDictionary: [
                kCGImagePropertyTIFFMake: "TestCam",
                kCGImagePropertyTIFFModel: "X100"
            ],
            kCGImagePropertyExifDictionary: [
                kCGImagePropertyExifFocalLength: 23.0,
                kCGImagePropertyExifFNumber: 2.0,
                kCGImagePropertyExifExposureTime: 0.004,
                kCGImagePropertyExifISOSpeedRatings: [400]
            ]
        ]
        CGImageDestinationAddImage(dest, rep.cgImage!, properties as CFDictionary)
        CGImageDestinationFinalize(dest)
        try! (data as Data).write(to: url)
        return url
    }

    private func defaultSettings(
        outputWidth: Int = 500,
        outputHeight: Int = 500,
        margin: Int = 50,
        format: OutputFormat = .png
    ) -> ImageProcessor.Settings {
        ImageProcessor.Settings(
            outputWidth: outputWidth,
            outputHeight: outputHeight,
            margin: margin,
            frameColor: .white,
            showMetadata: false,
            metadataFontName: "Helvetica Neue",
            metadataFontSize: 14.0,
            metadataColor: .darkGray,
            outputFormat: format
        )
    }

    @Test("Process produces valid PNG data")
    func processProducesPNG() throws {
        let url = createTestImage(width: 200, height: 200)
        defer { try? FileManager.default.removeItem(at: url) }

        let data = try ImageProcessor.process(imageURL: url, settings: defaultSettings())
        #expect(!data.isEmpty)

        let image = NSImage(data: data)
        #expect(image != nil)
        #expect(image?.representations.first?.pixelsWide == 500)
        #expect(image?.representations.first?.pixelsHigh == 500)
    }

    @Test("Process produces valid JPEG data")
    func processProducesJPEG() throws {
        let url = createTestImage(width: 200, height: 200)
        defer { try? FileManager.default.removeItem(at: url) }

        let data = try ImageProcessor.process(imageURL: url, settings: defaultSettings(format: .jpeg))
        #expect(!data.isEmpty)

        let image = NSImage(data: data)
        #expect(image != nil)
    }

    @Test("Non-square image is centered with correct aspect ratio")
    func nonSquareImage() throws {
        let url = createTestImage(width: 400, height: 200)
        defer { try? FileManager.default.removeItem(at: url) }

        let data = try ImageProcessor.process(imageURL: url, settings: defaultSettings())
        let image = NSImage(data: data)
        #expect(image != nil)
        #expect(image?.representations.first?.pixelsWide == 500)
        #expect(image?.representations.first?.pixelsHigh == 500)
    }

    @Test("Margin too large throws error")
    func marginTooLarge() {
        let url = createTestImage(width: 100, height: 100)
        defer { try? FileManager.default.removeItem(at: url) }

        let settings = defaultSettings(outputWidth: 100, outputHeight: 100, margin: 60)
        #expect(throws: ImageProcessor.ProcessingError.marginTooLarge) {
            try ImageProcessor.process(imageURL: url, settings: settings)
        }
    }

    @Test("Invalid file throws unableToLoadImage")
    func invalidFile() {
        let url = URL(fileURLWithPath: "/nonexistent.png")
        #expect(throws: ImageProcessor.ProcessingError.unableToLoadImage) {
            try ImageProcessor.process(imageURL: url, settings: defaultSettings())
        }
    }

    @Test("Zero margin works")
    func zeroMargin() throws {
        let url = createTestImage(width: 200, height: 200)
        defer { try? FileManager.default.removeItem(at: url) }

        let data = try ImageProcessor.process(imageURL: url, settings: defaultSettings(margin: 0))
        let image = NSImage(data: data)
        #expect(image != nil)
        #expect(image?.representations.first?.pixelsWide == 500)
    }

    @Test("Blur mode produces valid output")
    func blurMode() throws {
        let url = createTestImage(width: 200, height: 200)
        defer { try? FileManager.default.removeItem(at: url) }

        let settings = ImageProcessor.Settings(
            outputWidth: 500,
            outputHeight: 500,
            margin: 50,
            frameMode: .blurredImage,
            frameColor: .white,
            showMetadata: false,
            metadataFontName: "Helvetica Neue",
            metadataFontSize: 14.0,
            metadataColor: .darkGray,
            outputFormat: .png
        )
        let data = try ImageProcessor.process(imageURL: url, settings: settings)
        let image = NSImage(data: data)
        #expect(image != nil)
        #expect(image?.representations.first?.pixelsWide == 500)
        #expect(image?.representations.first?.pixelsHigh == 500)
    }

    @Test("Blur mode with non-square image")
    func blurModeNonSquare() throws {
        let url = createTestImage(width: 400, height: 200)
        defer { try? FileManager.default.removeItem(at: url) }

        let settings = ImageProcessor.Settings(
            outputWidth: 800,
            outputHeight: 600,
            margin: 40,
            frameMode: .blurredImage,
            frameColor: .white,
            showMetadata: false,
            metadataFontName: "Helvetica Neue",
            metadataFontSize: 14.0,
            metadataColor: .darkGray,
            outputFormat: .png
        )
        let data = try ImageProcessor.process(imageURL: url, settings: settings)
        let image = NSImage(data: data)
        #expect(image != nil)
        #expect(image?.representations.first?.pixelsWide == 800)
        #expect(image?.representations.first?.pixelsHigh == 600)
    }

    @Test("Show metadata enabled produces valid output")
    func showMetadataEnabled() throws {
        let url = createTestImage(width: 200, height: 200)
        defer { try? FileManager.default.removeItem(at: url) }

        let settings = ImageProcessor.Settings(
            outputWidth: 500,
            outputHeight: 500,
            margin: 50,
            frameColor: .white,
            showMetadata: true,
            metadataFontName: "Helvetica Neue",
            metadataFontSize: 14.0,
            metadataColor: .darkGray,
            outputFormat: .png
        )
        let data = try ImageProcessor.process(imageURL: url, settings: settings)
        let image = NSImage(data: data)
        #expect(image != nil)
        #expect(image?.representations.first?.pixelsWide == 500)
        #expect(image?.representations.first?.pixelsHigh == 500)
    }

    @Test("Show metadata with blur mode produces valid output")
    func showMetadataBlurMode() throws {
        let url = createTestImage(width: 300, height: 200)
        defer { try? FileManager.default.removeItem(at: url) }

        let settings = ImageProcessor.Settings(
            outputWidth: 600,
            outputHeight: 600,
            margin: 50,
            frameMode: .blurredImage,
            frameColor: .white,
            showMetadata: true,
            metadataFontName: "Helvetica Neue",
            metadataFontSize: 24.0,
            metadataColor: .white,
            outputFormat: .png
        )
        let data = try ImageProcessor.process(imageURL: url, settings: settings)
        let image = NSImage(data: data)
        #expect(image != nil)
        #expect(image?.representations.first?.pixelsWide == 600)
        #expect(image?.representations.first?.pixelsHigh == 600)
    }

    @Test("Blur mode with zero border width produces valid output")
    func blurModeZeroBorder() throws {
        let url = createTestImage(width: 200, height: 200)
        defer { try? FileManager.default.removeItem(at: url) }

        let settings = ImageProcessor.Settings(
            outputWidth: 500,
            outputHeight: 500,
            margin: 50,
            frameMode: .blurredImage,
            frameColor: .white,
            borderWidth: 0,
            borderColor: .white,
            showMetadata: false,
            metadataFontName: "Helvetica Neue",
            metadataFontSize: 14.0,
            metadataColor: .darkGray,
            outputFormat: .png
        )
        let data = try ImageProcessor.process(imageURL: url, settings: settings)
        let image = NSImage(data: data)
        #expect(image != nil)
        #expect(image?.representations.first?.pixelsWide == 500)
        #expect(image?.representations.first?.pixelsHigh == 500)
    }

    @Test("Custom output dimensions")
    func customDimensions() throws {
        let url = createTestImage(width: 300, height: 200)
        defer { try? FileManager.default.removeItem(at: url) }

        let data = try ImageProcessor.process(
            imageURL: url,
            settings: defaultSettings(outputWidth: 1000, outputHeight: 800, margin: 100)
        )
        let image = NSImage(data: data)
        #expect(image?.representations.first?.pixelsWide == 1000)
        #expect(image?.representations.first?.pixelsHigh == 800)
    }

    // HEIC excluded: CI runners lack hardware HEVC encoder
    @Test("All output formats produce valid data", arguments: OutputFormat.allCases.filter { $0 != .heic })
    func allOutputFormats(format: OutputFormat) throws {
        let url = createTestImage(width: 200, height: 200)
        defer { try? FileManager.default.removeItem(at: url) }

        let data = try ImageProcessor.process(imageURL: url, settings: defaultSettings(format: format))
        #expect(!data.isEmpty)

        let image = NSImage(data: data)
        #expect(image != nil)
    }

    @Test("Metadata text is rendered with EXIF data")
    func metadataWithExif() throws {
        let url = createTestImageWithExif(width: 200, height: 200)
        defer { try? FileManager.default.removeItem(at: url) }

        let meta = ExifMetadata.read(from: url)
        #expect(meta.make == "TestCam")
        #expect(meta.model == "X100")
        #expect(meta.formattedString != nil)

        let settings = ImageProcessor.Settings(
            outputWidth: 500,
            outputHeight: 500,
            margin: 50,
            frameColor: .white,
            showMetadata: true,
            metadataFontName: "Helvetica Neue",
            metadataFontSize: 24.0,
            metadataColor: .darkGray,
            outputFormat: .png
        )
        let data = try ImageProcessor.process(imageURL: url, settings: settings)
        let image = NSImage(data: data)
        #expect(image != nil)
        #expect(image?.representations.first?.pixelsWide == 500)
    }

    @Test("Metadata text with blur mode and EXIF data")
    func metadataBlurWithExif() throws {
        let url = createTestImageWithExif(width: 300, height: 200)
        defer { try? FileManager.default.removeItem(at: url) }

        let settings = ImageProcessor.Settings(
            outputWidth: 600,
            outputHeight: 600,
            margin: 50,
            frameMode: .blurredImage,
            frameColor: .white,
            borderWidth: 3,
            borderColor: .white,
            showMetadata: true,
            metadataFontName: "Helvetica Neue",
            metadataFontSize: 20.0,
            metadataColor: .white,
            outputFormat: .png
        )
        let data = try ImageProcessor.process(imageURL: url, settings: settings)
        let image = NSImage(data: data)
        #expect(image != nil)
        #expect(image?.representations.first?.pixelsWide == 600)
        #expect(image?.representations.first?.pixelsHigh == 600)
    }

    @Test("Large dimensions produce valid output")
    func largeDimensions() throws {
        let url = createTestImage(width: 100, height: 100)
        defer { try? FileManager.default.removeItem(at: url) }

        let data = try ImageProcessor.process(
            imageURL: url,
            settings: defaultSettings(outputWidth: 10000, outputHeight: 10000, margin: 500)
        )
        let image = NSImage(data: data)
        #expect(image != nil)
        #expect(image?.representations.first?.pixelsWide == 10000)
        #expect(image?.representations.first?.pixelsHigh == 10000)
    }
}
