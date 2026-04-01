import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Aspect Ratio

public enum AspectRatio: String, CaseIterable, Identifiable {
    case square = "1:1"
    case portrait4x5 = "4:5"
    case landscape16x9 = "16:9"
    case portrait9x16 = "9:16"
    case landscape3x2 = "3:2"
    case portrait2x3 = "2:3"
    case portrait3x4 = "3:4"
    case landscape4x3 = "4:3"
    case custom = "Custom"

    public var id: String { rawValue }

    public var ratio: (Int, Int)? {
        switch self {
        case .square:        return (1, 1)
        case .portrait4x5:   return (4, 5)
        case .landscape16x9: return (16, 9)
        case .portrait9x16:  return (9, 16)
        case .landscape3x2:  return (3, 2)
        case .portrait2x3:   return (2, 3)
        case .portrait3x4:   return (3, 4)
        case .landscape4x3:  return (4, 3)
        case .custom:        return nil
        }
    }
}

// MARK: - Frame Mode

public enum FrameMode: String, CaseIterable, Identifiable, Sendable {
    case solidColor = "Color"
    case blurredImage = "Blur"

    public var id: String { rawValue }
}

// MARK: - Output Format

public enum OutputFormat: String, CaseIterable, Identifiable, Sendable {
    case png = "PNG"
    case jpeg = "JPEG"
    case tiff = "TIFF"
    case heic = "HEIC"
    case webp = "WebP"

    public var id: String { rawValue }

    public var utType: UTType {
        switch self {
        case .png:  return .png
        case .jpeg: return .jpeg
        case .tiff: return .tiff
        case .heic: return .heic
        case .webp: return UTType("public.webp") ?? .png
        }
    }

    public var fileExtension: String {
        switch self {
        case .png:  return "png"
        case .jpeg: return "jpg"
        case .tiff: return "tiff"
        case .heic: return "heic"
        case .webp: return "webp"
        }
    }

    public var supportsLossless: Bool {
        switch self {
        case .png, .tiff: return true
        case .jpeg, .heic, .webp: return false
        }
    }
}

// MARK: - Shared Constants

public enum SharedConstants {
    public static let supportedExtensions = Set(["jpg", "jpeg", "png", "tiff", "tif", "heic", "bmp", "webp"])

    public static let colorPresets: [(name: String, hex: String)] = [
        ("White", "#FFFFFF"),
        ("Light Gray", "#D3D3D3"),
        ("Gray", "#808080"),
        ("Dark Gray", "#404040"),
        ("Black", "#000000"),
        ("Beige", "#F5F0E8"),
    ]

    public static var availableFonts: [String] {
        let preferred = [
            "Helvetica Neue", "Helvetica", "Arial", "Avenir", "Avenir Next",
            "Futura", "Gill Sans", "SF Pro", "SF Mono", "Menlo", "Monaco",
            "Courier New", "Georgia", "Times New Roman", "Baskerville", "Didot", "Palatino",
        ]
        let available = Set(NSFontManager.shared.availableFontFamilies)
        return preferred.filter { available.contains($0) }
    }
}

// MARK: - NSColor Hex Helpers

extension NSColor {
    public static func fromHex(_ hex: String) -> NSColor? {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6, let value = UInt64(h, radix: 16) else { return nil }
        let r = CGFloat((value >> 16) & 0xFF) / 255.0
        let g = CGFloat((value >> 8) & 0xFF) / 255.0
        let b = CGFloat(value & 0xFF) / 255.0
        return NSColor(srgbRed: r, green: g, blue: b, alpha: 1.0)
    }

    public func toHex() -> String {
        guard let c = usingColorSpace(.sRGB) else { return "#FFFFFF" }
        let r = Int(round(c.redComponent * 255))
        let g = Int(round(c.greenComponent * 255))
        let b = Int(round(c.blueComponent * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
