import Foundation

enum DefaultsKey {
    static let frameMode = "defaultFrameMode"
    static let frameColor = "defaultFrameColor"
    static let ratio = "defaultRatio"
    static let outputWidth = "defaultOutputWidth"
    static let outputHeight = "defaultOutputHeight"
    static let margin = "defaultMargin"
    static let borderWidth = "defaultBorderWidth"
    static let borderColor = "defaultBorderColor"
    static let showMetadata = "defaultShowMetadata"
    static let metadataFont = "defaultMetadataFont"
    static let metadataFontSize = "defaultMetadataFontSize"
    static let metadataColor = "defaultMetadataColor"
    static let outputFormat = "defaultOutputFormat"
}

enum DefaultValue {
    static let frameMode = "Color"
    static let frameColor = "#FFFFFF"
    static let ratio = "1:1"
    static let outputWidth = "3000"
    static let outputHeight = "3000"
    static let margin = 5.0
    static let borderWidth = 2.0
    static let borderColor = "#FFFFFF"
    static let showMetadata = false
    static let metadataFont = "Helvetica Neue"
    static let metadataFontSize = 14.0
    static let metadataColor = "#333333"
    static let outputFormat = "PNG"
}

enum Defaults {
    static func register() {
        UserDefaults.standard.register(defaults: [
            DefaultsKey.frameMode: DefaultValue.frameMode,
            DefaultsKey.frameColor: DefaultValue.frameColor,
            DefaultsKey.ratio: DefaultValue.ratio,
            DefaultsKey.outputWidth: DefaultValue.outputWidth,
            DefaultsKey.outputHeight: DefaultValue.outputHeight,
            DefaultsKey.margin: DefaultValue.margin,
            DefaultsKey.borderWidth: DefaultValue.borderWidth,
            DefaultsKey.borderColor: DefaultValue.borderColor,
            DefaultsKey.showMetadata: DefaultValue.showMetadata,
            DefaultsKey.metadataFont: DefaultValue.metadataFont,
            DefaultsKey.metadataFontSize: DefaultValue.metadataFontSize,
            DefaultsKey.metadataColor: DefaultValue.metadataColor,
            DefaultsKey.outputFormat: DefaultValue.outputFormat,
        ])
    }
}
