import Foundation
import Testing
@testable import EnkadrKit

@Suite("ExifMetadata")
struct ExifMetadataTests {

    @Test("Empty metadata returns nil")
    func emptyMetadata() {
        let meta = ExifMetadata()
        #expect(meta.formattedString == nil)
    }

    @Test("Camera make and model")
    func cameraOnly() {
        let meta = ExifMetadata(make: "Canon", model: "EOS R5")
        #expect(meta.formattedString == "Canon EOS R5")
    }

    @Test("Make only, no model")
    func makeOnly() {
        let meta = ExifMetadata(make: "Sony")
        #expect(meta.formattedString == "Sony")
    }

    @Test("Integer focal length omits decimal")
    func integerFocalLength() {
        let meta = ExifMetadata(focalLength: 50.0)
        #expect(meta.formattedString == "50mm")
    }

    @Test("Fractional focal length shows one decimal")
    func fractionalFocalLength() {
        let meta = ExifMetadata(focalLength: 35.5)
        #expect(meta.formattedString == "35.5mm")
    }

    @Test("Aperture formatting")
    func aperture() {
        let meta = ExifMetadata(aperture: 2.8)
        #expect(meta.formattedString == "f/2.8")
    }

    @Test("Exposure time >= 1s")
    func longExposure() {
        let meta = ExifMetadata(exposureTime: 2.5)
        #expect(meta.formattedString == "2.5s")
    }

    @Test("Exposure time < 1s uses fraction")
    func shortExposure() {
        let meta = ExifMetadata(exposureTime: 1.0 / 250.0)
        #expect(meta.formattedString == "1/250s")
    }

    @Test("ISO formatting")
    func iso() {
        let meta = ExifMetadata(iso: 800)
        #expect(meta.formattedString == "ISO 800")
    }

    @Test("Full metadata string")
    func fullMetadata() {
        let meta = ExifMetadata(
            make: "Nikon",
            model: "Z6",
            focalLength: 85.0,
            aperture: 1.4,
            exposureTime: 1.0 / 500.0,
            iso: 400
        )
        #expect(meta.formattedString == "Nikon Z6  85mm  f/1.4  1/500s  ISO 400")
    }

    @Test("Read from non-existent file returns empty metadata")
    func readNonExistent() {
        let meta = ExifMetadata.read(from: URL(fileURLWithPath: "/nonexistent.jpg"))
        #expect(meta.make == nil)
        #expect(meta.model == nil)
        #expect(meta.focalLength == nil)
        #expect(meta.aperture == nil)
        #expect(meta.exposureTime == nil)
        #expect(meta.iso == nil)
    }
}
