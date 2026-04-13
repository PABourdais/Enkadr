import SwiftUI

struct SettingsPanel: View {
    @AppStorage(DefaultsKey.frameMode) var frameModeRaw = DefaultValue.frameMode
    @AppStorage(DefaultsKey.frameColor) var frameColorHex = DefaultValue.frameColor
    @AppStorage(DefaultsKey.ratio) var ratioRaw = DefaultValue.ratio
    @AppStorage(DefaultsKey.outputWidth) var outputWidth = DefaultValue.outputWidth
    @AppStorage(DefaultsKey.outputHeight) var outputHeight = DefaultValue.outputHeight
    @AppStorage(DefaultsKey.margin) var marginPercent = DefaultValue.margin
    @AppStorage(DefaultsKey.borderWidth) var borderWidth = DefaultValue.borderWidth
    @AppStorage(DefaultsKey.borderColor) var borderColorHex = DefaultValue.borderColor
    @AppStorage(DefaultsKey.showMetadata) var showMetadata = DefaultValue.showMetadata
    @AppStorage(DefaultsKey.metadataFont) var metadataFont = DefaultValue.metadataFont
    @AppStorage(DefaultsKey.metadataFontSize) var metadataFontSize = DefaultValue.metadataFontSize
    @AppStorage(DefaultsKey.metadataColor) var metadataColorHex = DefaultValue.metadataColor
    @AppStorage(DefaultsKey.outputFormat) var outputFormatRaw = DefaultValue.outputFormat

    private var selectedRatio: Binding<AspectRatio> {
        Binding(
            get: { AspectRatio(rawValue: ratioRaw) ?? .square },
            set: { ratioRaw = $0.rawValue }
        )
    }

    private var outputFormat: Binding<OutputFormat> {
        Binding(
            get: { OutputFormat(rawValue: outputFormatRaw) ?? .png },
            set: { outputFormatRaw = $0.rawValue }
        )
    }

    private var selectedFrameMode: Binding<FrameMode> {
        Binding(
            get: { FrameMode(rawValue: frameModeRaw) ?? .solidColor },
            set: { frameModeRaw = $0.rawValue }
        )
    }

    private var colorBinding: Binding<Color> {
        Binding(
            get: { Color(nsColor: NSColor.fromHex(frameColorHex) ?? .white) },
            set: { frameColorHex = NSColor($0).toHex() }
        )
    }

    private var borderColorBinding: Binding<Color> {
        Binding(
            get: { Color(nsColor: NSColor.fromHex(borderColorHex) ?? .white) },
            set: { borderColorHex = NSColor($0).toHex() }
        )
    }

    private var metadataColorBinding: Binding<Color> {
        Binding(
            get: { Color(nsColor: NSColor.fromHex(metadataColorHex) ?? .gray) },
            set: { metadataColorHex = NSColor($0).toHex() }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Frame")
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    settingsLabel("Mode")
                    Picker("", selection: selectedFrameMode) {
                        ForEach(FrameMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }
                if selectedFrameMode.wrappedValue == .solidColor {
                    colorPickerRow(label: "Color", hex: $frameColorHex, color: colorBinding)
                }
                if selectedFrameMode.wrappedValue == .blurredImage {
                    GridRow {
                        settingsLabel("Border")
                        HStack(spacing: 4) {
                            Slider(value: $borderWidth, in: 0...20, step: 1)
                                .tint(Theme.accent)
                                .frame(width: 150)
                            Text("\(Int(borderWidth))px")
                                .foregroundStyle(Theme.textSecondary)
                                .frame(width: 35, alignment: .trailing)
                        }
                    }
                    colorPickerRow(label: "Color", hex: $borderColorHex, color: borderColorBinding)
                }
                GridRow {
                    settingsLabel("Margin")
                    HStack(spacing: 4) {
                        Slider(value: $marginPercent, in: 0...30, step: 1)
                            .tint(Theme.accent)
                            .frame(width: 150)
                        Text("\(Int(marginPercent))%")
                            .foregroundStyle(Theme.textSecondary)
                            .frame(width: 35, alignment: .trailing)
                    }
                }
            }

            Divider().overlay(Theme.divider)

            sectionHeader("Output")
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    settingsLabel("Ratio")
                    Picker("", selection: selectedRatio) {
                        ForEach(AspectRatio.allCases) { ratio in
                            Text(ratio.rawValue).tag(ratio)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .onChange(of: ratioRaw) { applyRatioFromWidth() }
                }
                GridRow {
                    settingsLabel("Size")
                    HStack(spacing: 4) {
                        Text("W").font(.caption2).foregroundStyle(Theme.textTertiary)
                        TextField("", text: $outputWidth)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                            .onSubmit { applyRatioFromWidth() }
                        Text("x")
                        Text("H").font(.caption2).foregroundStyle(Theme.textTertiary)
                        TextField("", text: $outputHeight)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                            .onSubmit { applyRatioFromHeight() }
                        Text("px").foregroundStyle(Theme.textSecondary)
                    }
                }
                GridRow {
                    settingsLabel("Format")
                    Picker("", selection: outputFormat) {
                        ForEach(OutputFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }
            }

            Divider().overlay(Theme.divider)

            sectionHeader("Metadata")
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    Text("").frame(width: 60)
                    Toggle("Show EXIF data", isOn: $showMetadata)
                        .toggleStyle(.checkbox)
                }
                if showMetadata {
                    GridRow {
                        settingsLabel("Font")
                        Picker("", selection: $metadataFont) {
                            ForEach(SharedConstants.availableFonts, id: \.self) { font in
                                Text(font).tag(font)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 180)
                    }
                    GridRow {
                        settingsLabel("Size")
                        HStack(spacing: 4) {
                            Slider(value: $metadataFontSize, in: 8...72, step: 1)
                                .tint(Theme.accent)
                                .frame(width: 150)
                            Text("\(Int(metadataFontSize))pt")
                                .foregroundStyle(Theme.textSecondary)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                    colorPickerRow(label: "Color", hex: $metadataColorHex, color: metadataColorBinding)
                }
            }
        }
    }

    // MARK: - Helpers

    private func colorPickerRow(label: String, hex: Binding<String>, color: Binding<Color>) -> some View {
        GridRow {
            settingsLabel(label)
            HStack(spacing: 8) {
                TextField(hex.wrappedValue, text: hex)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                ForEach(SharedConstants.colorPresets, id: \.hex) { preset in
                    Button {
                        hex.wrappedValue = preset.hex
                    } label: {
                        Circle()
                            .fill(Color(nsColor: NSColor.fromHex(preset.hex) ?? .white))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle().stroke(hex.wrappedValue == preset.hex ? Theme.accent : Theme.border, lineWidth: hex.wrappedValue == preset.hex ? 2 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .help(preset.name)
                }
                ColorPicker("", selection: color, supportsOpacity: false)
                    .labelsHidden()
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Theme.accent)
    }

    private func settingsLabel(_ title: String) -> some View {
        Text(title)
            .frame(width: 60, alignment: .trailing)
    }

    private func applyRatioFromWidth() {
        guard let (rw, rh) = (AspectRatio(rawValue: ratioRaw) ?? .square).ratio,
              let width = Int(outputWidth), width > 0 else { return }
        outputHeight = "\(Int(Double(width) * Double(rh) / Double(rw)))"
    }

    private func applyRatioFromHeight() {
        guard let (rw, rh) = (AspectRatio(rawValue: ratioRaw) ?? .square).ratio,
              let height = Int(outputHeight), height > 0 else { return }
        outputWidth = "\(Int(Double(height) * Double(rw) / Double(rh)))"
    }
}
