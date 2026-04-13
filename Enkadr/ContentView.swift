import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var imageURLs: [URL] = []
    @State private var isTargeted = false
    @State private var isProcessing = false
    @State private var statusMessage: String?
    @State private var showError = false
    @State private var errorMessage = ""

    // Read current settings for processing
    @AppStorage(DefaultsKey.frameMode) private var frameModeRaw = DefaultValue.frameMode
    @AppStorage(DefaultsKey.frameColor) private var frameColorHex = DefaultValue.frameColor
    @AppStorage(DefaultsKey.outputWidth) private var outputWidth = DefaultValue.outputWidth
    @AppStorage(DefaultsKey.outputHeight) private var outputHeight = DefaultValue.outputHeight
    @AppStorage(DefaultsKey.margin) private var marginPercent = DefaultValue.margin
    @AppStorage(DefaultsKey.borderWidth) private var borderWidth = DefaultValue.borderWidth
    @AppStorage(DefaultsKey.borderColor) private var borderColorHex = DefaultValue.borderColor
    @AppStorage(DefaultsKey.showMetadata) private var showMetadata = DefaultValue.showMetadata
    @AppStorage(DefaultsKey.metadataFont) private var metadataFont = DefaultValue.metadataFont
    @AppStorage(DefaultsKey.metadataFontSize) private var metadataFontSize = DefaultValue.metadataFontSize
    @AppStorage(DefaultsKey.metadataColor) private var metadataColorHex = DefaultValue.metadataColor
    @AppStorage(DefaultsKey.outputFormat) private var outputFormatRaw = DefaultValue.outputFormat

    var body: some View {
        VStack(spacing: 28) {
            dropZone
                .frame(height: 220)
                .overlay(alignment: .bottomLeading) {
                    if !imageURLs.isEmpty {
                        overlayButton(icon: "arrow.down.doc", color: Theme.accent) {
                            openFilePicker()
                        }
                        .offset(x: -8, y: 8)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if !imageURLs.isEmpty {
                        overlayButton(icon: "trash", color: .red.opacity(0.8)) {
                            imageURLs.removeAll()
                        }
                        .offset(x: 8, y: 8)
                    }
                }

            SettingsPanel()

            Button { Task { await processImages() } } label: {
                if isProcessing {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                        .frame(width: 160, height: 36)
                } else {
                    Text(imageURLs.isEmpty ? "Export" : "Export \(imageURLs.count) image\(imageURLs.count > 1 ? "s" : "")")
                        .fontWeight(.medium)
                        .frame(width: 160, height: 36)
                }
            }
            .buttonStyle(AccentButtonStyle())
            .disabled(imageURLs.isEmpty || isProcessing)

            if let statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(24)
        .frame(width: 480)
        .background(Theme.bg)
        .foregroundStyle(Theme.textPrimary)
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Components

    private func overlayButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(color)
                .padding(6)
                .background(Theme.bgTertiary, in: Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Drop Zone

    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundStyle(isTargeted ? Theme.accent : Theme.border)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isTargeted ? Theme.accent.opacity(0.08) : Theme.bgSecondary)
                )

            if imageURLs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 36))
                        .foregroundStyle(Theme.textSecondary)
                    Text("Drop or click to add images")
                        .foregroundStyle(Theme.textSecondary)
                    Text(SharedConstants.supportedExtensions.sorted().map { $0.uppercased() }.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundStyle(Theme.textTertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture { openFilePicker() }
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVGrid(columns: [GridItem](repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(imageURLs, id: \.self) { url in
                            imageThumb(url: url)
                        }
                    }
                    .padding(12)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            let validProviders = providers.filter { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }
            guard !validProviders.isEmpty else { return false }
            handleDrop(providers: validProviders)
            return true
        }
    }

    @ViewBuilder
    private func imageThumb(url: URL) -> some View {
        if let nsImage = NSImage(contentsOf: url) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .allowsHitTesting(false)
                .overlay(alignment: .topTrailing) {
                    Button {
                        imageURLs.removeAll { $0 == url }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white, Theme.accent)
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
        }
    }

    // MARK: - File Picker

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = SharedConstants.supportedExtensions.compactMap { UTType(filenameExtension: $0) }

        guard panel.runModal() == .OK else { return }
        for url in panel.urls where !imageURLs.contains(url) {
            imageURLs.append(url)
        }
    }

    // MARK: - Drop Handling

    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil),
                      SharedConstants.supportedExtensions.contains(url.pathExtension.lowercased()) else {
                    return
                }
                DispatchQueue.main.async {
                    if !imageURLs.contains(url) {
                        imageURLs.append(url)
                    }
                }
            }
        }
    }

    // MARK: - Processing

    @MainActor
    private func processImages() async {
        guard let width = Int(outputWidth), let height = Int(outputHeight),
              width > 0, height > 0 else {
            errorMessage = "Please enter valid numeric values."
            showError = true
            return
        }

        let maxDimension = 20000
        guard width <= maxDimension, height <= maxDimension else {
            errorMessage = "Maximum output size is \(maxDimension)x\(maxDimension) pixels."
            showError = true
            return
        }

        let marginPx = Int(Double(min(width, height)) * marginPercent / 100.0)
        let format = OutputFormat(rawValue: outputFormatRaw) ?? .png

        let mode = FrameMode(rawValue: frameModeRaw) ?? .solidColor
        let settings = ImageProcessor.Settings(
            outputWidth: width,
            outputHeight: height,
            margin: marginPx,
            frameMode: mode,
            frameColor: NSColor.fromHex(frameColorHex) ?? .white,
            borderWidth: mode == .blurredImage ? CGFloat(borderWidth) : nil,
            borderColor: mode == .blurredImage ? NSColor.fromHex(borderColorHex) ?? .white : nil,
            showMetadata: showMetadata,
            metadataFontName: metadataFont,
            metadataFontSize: CGFloat(metadataFontSize),
            metadataColor: NSColor.fromHex(metadataColorHex) ?? .darkGray,
            outputFormat: format
        )

        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = "Choose output folder"

        guard panel.runModal() == .OK, let outputDir = panel.url else { return }

        isProcessing = true
        statusMessage = nil

        let urls = imageURLs

        let (successCount, errors) = await Task.detached {
            var successCount = 0
            var errors: [String] = []

            for url in urls {
                do {
                    let data = try ImageProcessor.process(imageURL: url, settings: settings)
                    let outputURL = outputDir
                        .appendingPathComponent(url.deletingPathExtension().lastPathComponent)
                        .appendingPathExtension(settings.outputFormat.fileExtension)
                    try data.write(to: outputURL)
                    successCount += 1
                } catch {
                    errors.append("\(url.lastPathComponent): \(error.localizedDescription)")
                }
            }

            return (successCount, errors)
        }.value

        isProcessing = false
        if errors.isEmpty {
            statusMessage = "\(successCount) image(s) exported successfully."
        } else {
            errorMessage = errors.joined(separator: "\n")
            showError = true
            statusMessage = "\(successCount) exported, \(errors.count) error(s)."
        }
    }
}
