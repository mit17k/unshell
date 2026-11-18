#if DEBUG
import AppKit

/// `UNSHELL_SNAPSHOT=<dev view id> UNSHELL_SNAPSHOT_OUT=<file.png>` renders one
/// dev view offscreen at 2x, writes a PNG and exits. For checking views from
/// scripts without driving the UI. Debug builds only.
enum DevSnapshot {
    static func runIfRequested() -> Bool {
        let env = ProcessInfo.processInfo.environment
        guard let id = env["UNSHELL_SNAPSHOT"], let out = env["UNSHELL_SNAPSHOT_OUT"] else { return false }
        guard let view = DevViews.make(id) else {
            FileHandle.standardError.write("unknown dev view \(id)\n".data(using: .utf8)!)
            exit(2)
        }
        let width = CGFloat(Double(env["UNSHELL_SNAPSHOT_WIDTH"] ?? "") ?? 1200)
        let container = DevContainer(content: view)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: width, height: 800),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: .darkAqua)
        window.contentView = container
        container.layoutSubtreeIfNeeded()
        let height = env["UNSHELL_SNAPSHOT_HEIGHT"].flatMap { Double($0) }.map { CGFloat($0) }
            ?? container.fittingHeight(width: width)
        window.setContentSize(NSSize(width: width, height: height))
        container.layoutSubtreeIfNeeded()
        // Let one run-loop turn pass so asynchronous work (highlighting) lands.
        let settle = Double(env["UNSHELL_SNAPSHOT_SETTLE"] ?? "") ?? 0.3
        RunLoop.main.run(until: Date().addingTimeInterval(settle))
        container.displayIfNeeded()

        let scale: CGFloat = 2
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(width * scale), pixelsHigh: Int(height * scale),
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                   colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        rep.size = NSSize(width: width, height: height)
        container.cacheDisplay(in: container.bounds, to: rep)
        do {
            try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
        } catch {
            FileHandle.standardError.write("snapshot write failed: \(error)\n".data(using: .utf8)!)
            exit(1)
        }
        exit(0)
    }
}
#endif
