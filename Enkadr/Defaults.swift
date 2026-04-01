import Foundation

enum DefaultsKey {
    static let frameColor = "defaultFrameColor"
    static let ratio = "defaultRatio"
    static let outputWidth = "defaultOutputWidth"
    static let outputHeight = "defaultOutputHeight"
    static let margin = "defaultMargin"
    static let showMetadata = "defaultShowMetadata"
    static let metadataFont = "defaultMetadataFont"
    static let metadataFontSize = "defaultMetadataFontSize"
    static let outputFormat = "defaultOutputFormat"
}

enum DefaultValue {
    static let frameColor = "#FFFFFF"
    static let ratio = "1:1"
    static let outputWidth = "3000"
    static let outputHeight = "3000"
    static let margin = 5.0
    static let showMetadata = false
    static let metadataFont = "Helvetica Neue"
    static let metadataFontSize = 14.0
    static let outputFormat = "PNG"
}

enum Defaults {
    static func register() {
        UserDefaults.standard.register(defaults: [
            DefaultsKey.frameColor: DefaultValue.frameColor,
            DefaultsKey.ratio: DefaultValue.ratio,
            DefaultsKey.outputWidth: DefaultValue.outputWidth,
            DefaultsKey.outputHeight: DefaultValue.outputHeight,
            DefaultsKey.margin: DefaultValue.margin,
            DefaultsKey.showMetadata: DefaultValue.showMetadata,
            DefaultsKey.metadataFont: DefaultValue.metadataFont,
            DefaultsKey.metadataFontSize: DefaultValue.metadataFontSize,
            DefaultsKey.outputFormat: DefaultValue.outputFormat,
        ])
    }
}
