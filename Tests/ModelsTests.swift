import AppKit
import Testing
import UniformTypeIdentifiers
@testable import EnkadrKit

@Suite("Models")
struct ModelsTests {

    // MARK: - AspectRatio

    @Test("AspectRatio square returns (1, 1)")
    func squareRatio() {
        let ratio = AspectRatio.square.ratio
        #expect(ratio?.0 == 1 && ratio?.1 == 1)
    }

    @Test("AspectRatio custom returns nil")
    func customRatio() {
        #expect(AspectRatio.custom.ratio == nil)
    }

    @Test("All non-custom ratios have values")
    func allRatiosHaveValues() {
        for ratio in AspectRatio.allCases where ratio != .custom {
            #expect(ratio.ratio != nil)
        }
    }

    // MARK: - OutputFormat

    @Test("PNG is lossless")
    func pngLossless() {
        #expect(OutputFormat.png.supportsLossless == true)
    }

    @Test("JPEG is lossy")
    func jpegLossy() {
        #expect(OutputFormat.jpeg.supportsLossless == false)
    }

    @Test("File extensions are correct")
    func fileExtensions() {
        #expect(OutputFormat.png.fileExtension == "png")
        #expect(OutputFormat.jpeg.fileExtension == "jpg")
        #expect(OutputFormat.tiff.fileExtension == "tiff")
        #expect(OutputFormat.heic.fileExtension == "heic")
        #expect(OutputFormat.webp.fileExtension == "webp")
    }

    @Test("UTTypes are valid")
    func utTypes() {
        #expect(OutputFormat.png.utType == .png)
        #expect(OutputFormat.jpeg.utType == .jpeg)
        #expect(OutputFormat.tiff.utType == .tiff)
        #expect(OutputFormat.heic.utType == .heic)
    }

    // MARK: - NSColor Hex

    @Test("fromHex with # prefix")
    func fromHexWithHash() {
        let color = NSColor.fromHex("#FF0000")
        #expect(color != nil)
        let c = color!.usingColorSpace(.sRGB)!
        #expect(c.redComponent > 0.99)
        #expect(c.greenComponent < 0.01)
        #expect(c.blueComponent < 0.01)
    }

    @Test("fromHex without # prefix")
    func fromHexWithoutHash() {
        let color = NSColor.fromHex("00FF00")
        #expect(color != nil)
        let c = color!.usingColorSpace(.sRGB)!
        #expect(c.greenComponent > 0.99)
    }

    @Test("fromHex invalid string returns nil")
    func fromHexInvalid() {
        #expect(NSColor.fromHex("xyz") == nil)
        #expect(NSColor.fromHex("#12") == nil)
        #expect(NSColor.fromHex("") == nil)
    }

    @Test("toHex roundtrip")
    func toHexRoundtrip() {
        let hex = "#3A7BFF"
        let color = NSColor.fromHex(hex)!
        #expect(color.toHex() == hex)
    }

    // MARK: - SharedConstants

    @Test("Supported extensions contain common formats")
    func supportedExtensions() {
        #expect(SharedConstants.supportedExtensions.contains("jpg"))
        #expect(SharedConstants.supportedExtensions.contains("png"))
        #expect(SharedConstants.supportedExtensions.contains("heic"))
        #expect(!SharedConstants.supportedExtensions.contains("gif"))
    }
}
