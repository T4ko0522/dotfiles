import AppKit
import ScreenCaptureKit

struct Workspace: Decodable, Sendable {
    let id: String
    let displayName: String
    let number: Int
    let isCurrent: Bool
}
struct WindowInfo: Decodable, Sendable {
    struct App: Decodable, Sendable { let name: String; let bundleId: String? }
    struct Space: Decodable, Sendable { let id: String; let number: Int }
    let id: String // Opaque navigation identifier; never decoded.
    let windowId: UInt32 // Native ID provided independently by OmniWM.
    let title: String
    let app: App
    let workspace: Space
    let isFocused: Bool
}
struct Snapshot: Sendable { let windows: [WindowInfo]; let workspaces: [Workspace] }
enum CLI {
    static let executable = "/Applications/OmniWM.app/Contents/MacOS/omniwmctl"
    static func run(_ arguments: [String]) throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        try process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "OmniWM", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "omniwmctl failed (\(process.terminationStatus)). Is OmniWM running?"])
        }
        return data
    }
    static func query<T: Decodable>(_ kind: String, as: T.Type) throws -> T {
        let data = try run(["query", kind])
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any], object["ok"] as? Bool == true,
              let result = object["result"] as? [String: Any], let payload = result["payload"] as? [String: Any], let value = payload[kind] else {
            throw NSError(domain: "OmniWM", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unexpected OmniWM query response: \(kind)"])
        }
        return try JSONDecoder().decode(T.self, from: JSONSerialization.data(withJSONObject: value))
    }
    static func snapshot() async throws -> Snapshot {
        try await Task.detached(priority: .userInitiated) {
            let windows = try query("windows", as: [WindowInfo].self)
            let spaces = try query("workspaces", as: [Workspace].self)
            _ = try run(["query", "displays"])
            return Snapshot(windows: windows, workspaces: spaces.sorted { $0.number < $1.number })
        }.value
    }
}

@MainActor final class OverviewView: NSView {
    weak var owner: OverviewController?
    var cards: [(WindowInfo, NSRect)] = []
    var headings: [(String, NSRect, Bool)] = []
    var message = "Loading windows…"
    var permissionRequired = false
    var settingsRect = NSRect.zero
    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }
    func text(_ string: String, in rect: NSRect, size: CGFloat = 14, color: NSColor = .white, weight: NSFont.Weight = .regular) {
        let paragraph = NSMutableParagraphStyle(); paragraph.lineBreakMode = .byTruncatingTail
        (string as NSString).draw(in: rect, withAttributes: [.font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: color, .paragraphStyle: paragraph])
    }
    override func draw(_ dirtyRect: NSRect) {
        NSColor(calibratedWhite: 0.055, alpha: 0.98).setFill(); bounds.fill()
        text("Overview", in: NSRect(x: 32, y: 20, width: 200, height: 36), size: 26, weight: .semibold)
        text("Arrows / Tab: Select    Space: Preview    Enter: Open    1–9: Workspace    Esc: Back", in: NSRect(x: 250, y: 30, width: bounds.width - 280, height: 22), color: .secondaryLabelColor)
        if let owner, owner.preview, let window = owner.visibleWindows.first(where: { $0.id == owner.selectedID }) {
            text(window.title.isEmpty ? window.app.name : window.title, in: NSRect(x: 32, y: 64, width: bounds.width - 64, height: 26), size: 18)
            let area = NSRect(x: 32, y: 104, width: bounds.width - 64, height: bounds.height - 136)
            if let image = owner.images[window.id] {
                let scale = min(area.width / image.size.width, area.height / image.size.height)
                let rect = NSRect(x: area.midX - image.size.width * scale / 2, y: area.midY - image.size.height * scale / 2, width: image.size.width * scale, height: image.size.height * scale)
                NSGraphicsContext.current?.imageInterpolation = .high
                image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
            } else { text(owner.captureErrors[window.id] ?? "Capturing…", in: area, size: 18) }
            return
        }
        if let owner, !owner.search.isEmpty { text("Search: \(owner.search)", in: NSRect(x: 32, y: 60, width: bounds.width - 64, height: 24), color: .systemTeal) }
        for (name, rect, current) in headings { text(name + (current ? "   • Current" : ""), in: rect, size: 16, color: current ? .systemTeal : .white, weight: .semibold) }
        for (window, rect) in cards {
            let selected = owner?.selectedID == window.id
            NSColor(calibratedWhite: selected ? 0.22 : 0.12, alpha: 1).setFill()
            let path = NSBezierPath(roundedRect: rect, xRadius: 10, yRadius: 10); path.fill()
            if selected { NSColor.systemTeal.setStroke(); path.lineWidth = 3; path.stroke() }
            let preview = NSRect(x: rect.minX + 8, y: rect.minY + 8, width: rect.width - 16, height: max(1, rect.height - 46))
            if let image = owner?.images[window.id] {
                let scale = min(preview.width / image.size.width, preview.height / image.size.height)
                let fitted = NSRect(x: preview.midX - image.size.width * scale / 2, y: preview.midY - image.size.height * scale / 2, width: image.size.width * scale, height: image.size.height * scale)
                NSGraphicsContext.current?.imageInterpolation = .high
                image.draw(in: fitted, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
            } else { text(owner?.captureErrors[window.id] ?? "Capturing…", in: preview.insetBy(dx: 12, dy: preview.height / 2 - 10), size: 12, color: .secondaryLabelColor) }
            let labelY = rect.maxY - 29
            if let icon = owner?.icons[window.app.bundleId ?? window.app.name] { icon.draw(in: NSRect(x: rect.minX + 10, y: labelY, width: 20, height: 20), from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil) }
            text(window.title.isEmpty ? window.app.name : window.title, in: NSRect(x: rect.minX + 36, y: labelY + 1, width: rect.width - 46, height: 22), size: 13)
        }
        if !message.isEmpty { text(message, in: NSRect(x: 48, y: 110, width: bounds.width - 96, height: 100), size: 18) }
        if permissionRequired {
            settingsRect = NSRect(x: 48, y: 220, width: 310, height: 42)
            NSColor.systemTeal.setFill(); NSBezierPath(roundedRect: settingsRect, xRadius: 8, yRadius: 8).fill()
            text("Open Screen Recording Settings", in: settingsRect.insetBy(dx: 15, dy: 10), color: .black, weight: .semibold)
        }
    }
    override func mouseDown(with event: NSEvent) {
        if owner?.preview == true { owner?.preview = false; needsDisplay = true; return }
        let point = convert(event.locationInWindow, from: nil)
        if permissionRequired && settingsRect.contains(point) { owner?.openSettings(); return }
        if let card = cards.first(where: { $0.1.contains(point) }) { owner?.navigate(card.0); return }
        owner?.dismiss()
    }
    override func keyDown(with event: NSEvent) { owner?.key(event) }
    override func setFrameSize(_ newSize: NSSize) { super.setFrameSize(newSize); owner?.layout() }
}
final class OverviewPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor final class OverviewController: NSObject, NSApplicationDelegate {
    var panel: OverviewPanel?
    var canvas: OverviewView?
    var snapshot: Snapshot?
    var images: [String: NSImage] = [:]
    var icons: [String: NSImage] = [:]
    var captureErrors: [String: String] = [:]
    var selectedID: String?
    var search = ""
    var preview = false
    var previousApp: NSRunningApplication?
    var loadTask: Task<Void, Never>?
    var reopenTask: Task<Void, Never>?
    var generation = UUID()
    var shown: Bool { panel?.isVisible == true }
    var visibleWindows: [WindowInfo] {
        guard let snapshot else { return [] }
        return snapshot.workspaces.flatMap { space in snapshot.windows.filter { $0.workspace.id == space.id && (search.isEmpty || ($0.title + " " + $0.app.name).localizedCaseInsensitiveContains(search)) } }
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        if CommandLine.arguments.contains("--show") { show() }
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Launch Services can send both reopen and URL events for open -a APP URL.
        // Give the explicit URL precedence so toggle never happens twice.
        reopenTask?.cancel()
        reopenTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard !Task.isCancelled else { return }
            self?.toggle()
        }
        return false
    }
    func application(_ application: NSApplication, open urls: [URL]) {
        reopenTask?.cancel(); reopenTask = nil
        for url in urls where url.scheme == "omniwm-overview" {
            switch url.host { case "open", "show": show(); case "close", "hide": dismiss(); default: toggle() }
        }
    }
    func toggle() { shown ? dismiss() : show() }
    func show() {
        guard !shown else { return }
        previousApp = NSWorkspace.shared.frontmostApplication
        generation = UUID(); let token = generation
        search = ""; preview = false; snapshot = nil; selectedID = nil; images.removeAll(); captureErrors.removeAll(); icons.removeAll()
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main!
        let panel = OverviewPanel(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false; panel.backgroundColor = .clear
        let view = OverviewView(frame: NSRect(origin: .zero, size: screen.frame.size)); view.owner = self
        panel.contentView = view; self.panel = panel; canvas = view
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil); panel.makeFirstResponder(view)
        writeStatus()
        guard CGPreflightScreenCaptureAccess() else {
            view.permissionRequired = true
            view.message = "Screen Recording permission is required for window previews.\nEnable OmniWM Overview in System Settings, then quit and reopen this app."
            view.needsDisplay = true
            _ = CGRequestScreenCaptureAccess()
            return
        }
        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let data = try await CLI.snapshot()
                guard !Task.isCancelled, self.generation == token, self.shown else { return }
                self.snapshot = data
                self.selectedID = data.windows.first(where: { $0.isFocused })?.id ?? self.visibleWindows.first?.id
                for window in data.windows {
                    let key = window.app.bundleId ?? window.app.name
                    if let bundle = window.app.bundleId, let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundle) { self.icons[key] = NSWorkspace.shared.icon(forFile: url.path) }
                }
                self.canvas?.message = data.windows.isEmpty ? "No OmniWM windows found." : ""
                self.layout()
                let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: false)
                guard !Task.isCancelled, self.generation == token else { return }
                let native = Dictionary(content.windows.map { ($0.windowID, $0) }, uniquingKeysWith: { first, _ in first })
                // Four captures at a time; no polling or capture work while idle.
                for offset in stride(from: 0, to: data.windows.count, by: 4) {
                    guard !Task.isCancelled, self.generation == token, self.shown else { return }
                    let batch = Array(data.windows[offset..<min(offset + 4, data.windows.count)])
                    await withTaskGroup(of: Void.self) { group in
                        for window in batch {
                            guard let target = native[window.windowId] else { self.captureErrors[window.id] = "Preview unavailable"; continue }
                            group.addTask { @MainActor [weak self] in
                                guard let self, !Task.isCancelled, self.generation == token else { return }
                                do {
                                    let filter = SCContentFilter(desktopIndependentWindow: target)
                                    let config = SCStreamConfiguration()
                                    let scale = CGFloat(filter.pointPixelScale)
                                    config.width = max(1, Int(ceil(filter.contentRect.width * scale)))
                                    config.height = max(1, Int(ceil(filter.contentRect.height * scale)))
                                    config.showsCursor = false; config.ignoreShadowsSingleWindow = true
                                    config.captureResolution = .best
                                    let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
                                    guard !Task.isCancelled, self.generation == token, self.shown else { return }
                                    self.images[window.id] = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                                } catch {
                                    guard self.generation == token, self.shown else { return }
                                    self.captureErrors[window.id] = "Preview unavailable"
                                }
                                self.canvas?.needsDisplay = true
                                self.writeStatus()
                            }
                        }
                    }
                    self.canvas?.needsDisplay = true
                    self.writeStatus()
                }
            } catch {
                guard self.generation == token, self.shown else { return }
                self.canvas?.message = error.localizedDescription; self.canvas?.needsDisplay = true
                self.writeStatus()
            }
        }
    }
    func layout() {
        guard let canvas, let snapshot else { return }
        canvas.cards = []; canvas.headings = []
        let windows = visibleWindows
        let groups = snapshot.workspaces.compactMap { space -> (Workspace, [WindowInfo])? in
            let items = windows.filter { $0.workspace.id == space.id }; return items.isEmpty ? nil : (space, items)
        }
        let availableWidth = max(1, canvas.bounds.width - 64), availableHeight = max(1, canvas.bounds.height - 112)
        var width: CGFloat = min(350, availableWidth)
        func metrics(_ width: CGFloat) -> (Int, CGFloat, CGFloat) {
            let columns = max(1, Int((availableWidth + 16) / (width + 16))), height = width * 0.61 + 38
            let total = groups.reduce(CGFloat(0)) { $0 + 32 + CGFloat(Int(ceil(Double($1.1.count) / Double(columns)))) * (height + 14) }
            return (columns, height, total)
        }
        while metrics(width).2 > availableHeight && width > 80 { width -= 4 }
        let (columns, height, _) = metrics(width)
        var y: CGFloat = 96
        for (space, items) in groups {
            canvas.headings.append(("Workspace \(space.displayName)", NSRect(x: 32, y: y, width: availableWidth, height: 24), space.isCurrent)); y += 30
            for (index, item) in items.enumerated() { canvas.cards.append((item, NSRect(x: 32 + CGFloat(index % columns) * (width + 16), y: y + CGFloat(index / columns) * (height + 14), width: width, height: height))) }
            y += CGFloat(Int(ceil(Double(items.count) / Double(columns)))) * (height + 14) + 2
        }
        if !windows.contains(where: { $0.id == selectedID }) { selectedID = windows.first?.id }
        canvas.needsDisplay = true
    }
    func key(_ event: NSEvent) {
        if event.keyCode == 53 { if preview { preview = false; canvas?.needsDisplay = true } else { dismiss() }; return }
        if event.keyCode == 49, selectedID != nil { preview.toggle(); canvas?.needsDisplay = true; return }
        let windows = visibleWindows
        if event.keyCode == 36 || event.keyCode == 76 { if let window = windows.first(where: { $0.id == selectedID }) { navigate(window) }; return }
        if [123, 124, 125, 126, 48].contains(event.keyCode), !windows.isEmpty {
            let index = windows.firstIndex(where: { $0.id == selectedID }) ?? 0
            let backwards = event.keyCode == 123 || event.keyCode == 126 || (event.keyCode == 48 && event.modifierFlags.contains(.shift))
            if [125, 126].contains(event.keyCode), let current = canvas?.cards.first(where: { $0.0.id == selectedID }) {
                let candidates = (canvas?.cards ?? []).filter { backwards ? $0.1.midY < current.1.midY - 1 : $0.1.midY > current.1.midY + 1 }
                if let nearest = candidates.min(by: { abs($0.1.midY - current.1.midY) * 4 + abs($0.1.midX - current.1.midX) < abs($1.1.midY - current.1.midY) * 4 + abs($1.1.midX - current.1.midX) }) { selectedID = nearest.0.id }
            } else { selectedID = windows[(index + (backwards ? -1 : 1) + windows.count) % windows.count].id }
            canvas?.needsDisplay = true; return
        }
        if let characters = event.charactersIgnoringModifiers, let number = Int(characters), (1...9).contains(number), search.isEmpty {
            selectedID = windows.first(where: { $0.workspace.number == number })?.id ?? selectedID; canvas?.needsDisplay = true; return
        }
        if event.keyCode == 51 { if !search.isEmpty { search.removeLast() }; layout(); return }
        if !event.modifierFlags.intersection([.command, .control, .option]).isEmpty { return }
        if let characters = event.characters, !characters.isEmpty, characters.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) }) { search += characters; layout() }
    }
    func navigate(_ window: WindowInfo) {
        dismiss(restore: false)
        Task {
            do { _ = try await Task.detached(priority: .userInitiated) { try CLI.run(["window", "navigate", window.id]) }.value }
            catch { let alert = NSAlert(); alert.messageText = "Unable to select window"; alert.informativeText = error.localizedDescription; alert.runModal() }
        }
    }
    func dismiss(restore: Bool = true) {
        guard shown else { return }
        generation = UUID(); loadTask?.cancel(); loadTask = nil
        panel?.orderOut(nil); panel = nil; canvas = nil; images.removeAll(); icons.removeAll(); snapshot = nil
        if restore { previousApp?.activate(options: []) }; previousApp = nil
        writeStatus()
    }
    func writeStatus() {
        // Opt-in diagnostics contain IDs and pixel dimensions, never titles or pixels.
        guard let index = CommandLine.arguments.firstIndex(of: "--status-file"), CommandLine.arguments.indices.contains(index + 1) else { return }
        let sizes = images.mapValues { ["width": Int($0.size.width), "height": Int($0.size.height)] }
        let object: [String: Any] = ["visible": shown, "screenRecordingAllowed": CGPreflightScreenCaptureAccess(), "captures": sizes, "failedCaptures": Array(captureErrors.keys)]
        if let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: URL(fileURLWithPath: CommandLine.arguments[index + 1]), options: .atomic)
        }
    }
    func openSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
        dismiss(restore: false)
    }
}

if CommandLine.arguments.contains("--diagnose") {
    // Read-only: no activation, capture request, or UI launch.
    do {
        let windows = try CLI.query("windows", as: [WindowInfo].self), spaces = try CLI.query("workspaces", as: [Workspace].self)
        let object: [String: Any] = ["screenRecordingAllowed": CGPreflightScreenCaptureAccess(), "windowCount": windows.count, "workspaceCount": spaces.count, "nativeWindowIDs": windows.map(\.windowId), "bundleIdentifier": Bundle.main.bundleIdentifier ?? "unbundled"]
        FileHandle.standardOutput.write(try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])); print("")
    } catch { fputs("\(error.localizedDescription)\n", stderr); exit(1) }
} else {
    MainActor.assumeIsolated {
        let application = NSApplication.shared
        let delegate = OverviewController()
        application.delegate = delegate
        application.run()
    }
}
