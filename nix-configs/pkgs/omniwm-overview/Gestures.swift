// Independent client of Apple's private MultitouchSupport ABI. Record size and
// offsets checked against OmniWM MultitouchGestureFrame.swift (GPL-2.0-only);
// implementation below is written independently, without copying its code.
import AppKit
import Foundation
import IOKit

private typealias Device = OpaquePointer
private typealias FrameCallback = @convention(c) (
    Device, UnsafeMutableRawPointer?, Int32, Double, Int32, UnsafeMutableRawPointer?
) -> Int32

private final class MultitouchAPI {
    typealias List = @convention(c) () -> Unmanaged<CFArray>?
    typealias Start = @convention(c) (Device, Int32) -> Int32
    typealias Stop = @convention(c) (Device) -> Int32
    typealias Running = @convention(c) (Device) -> Bool
    typealias Service = @convention(c) (Device) -> io_service_t
    typealias Register = @convention(c) (Device, FrameCallback, UnsafeMutableRawPointer?) -> Int32
    typealias Unregister = @convention(c) (Device, FrameCallback) -> Int32
    let list: List
    let start: Start
    let stop: Stop
    let running: Running
    let service: Service
    let register: Register
    let unregister: Unregister

    init?() {
        guard let library = dlopen(
            "/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport", RTLD_LAZY
        ) else { return nil }
        func resolve<T>(_ name: String, _: T.Type) -> T? {
            guard let address = dlsym(library, name) else { return nil }
            return unsafeBitCast(address, to: T.self)
        }
        guard let list = resolve("MTDeviceCreateList", List.self),
              let start = resolve("MTDeviceStart", Start.self),
              let stop = resolve("MTDeviceStop", Stop.self),
              let running = resolve("MTDeviceIsRunning", Running.self),
              let service = resolve("MTDeviceGetService", Service.self),
              let register = resolve("MTRegisterContactFrameCallbackWithRefcon", Register.self),
              let unregister = resolve("MTUnregisterContactFrameCallback", Unregister.self)
        else { return nil }
        self.list = list; self.start = start; self.stop = stop
        self.running = running; self.service = service
        self.register = register; self.unregister = unregister
        // Keep the library loaded for every function-pointer/callback lifetime.
    }

    func enumerate() -> (CFArray?, [UInt64: Device]) {
        guard let list = list()?.takeRetainedValue() else { return (nil, [:]) }
        var devices: [UInt64: Device] = [:]
        for index in 0..<CFArrayGetCount(list) {
            guard let pointer = CFArrayGetValueAtIndex(list, index) else { continue }
            let device = Device(pointer)
            let entry = service(device)
            var id: UInt64 = 0
            if entry != 0, IORegistryEntryGetRegistryEntryID(entry, &id) == KERN_SUCCESS {
                devices[id] = device
            }
        }
        return (list, devices)
    }
}

private struct Stroke {
    var origin: CGPoint?
    var fired = false
}

private struct Registration {
    let device: Device
    var needsStop = true
    var needsUnregister = true
}

// Only stroke state crosses callback threads; lifecycle/AppKit/Process use main.
private final class GestureHelper: @unchecked Sendable {
    let api: MultitouchAPI
    let appPath: String
    let lock = NSLock()
    var strokes: [UInt: Stroke] = [:]
    var generation: UInt = 0
    var accepting = false
    var list: CFArray?
    var devices: [UInt64: Registration] = [:]
    var cleanupPending = false
    var timer: DispatchSourceTimer?
    var retry: DispatchWorkItem?
    var retryDelay: Double = 1
    var observers: [NSObjectProtocol] = []
    var unlockObserver: NSObjectProtocol?
    var signals: [DispatchSourceSignal] = []
    var notificationPort: IONotificationPortRef?
    var iterators: [io_iterator_t] = []
    var terminating = false

    init(api: MultitouchAPI, appPath: String) {
        self.api = api; self.appPath = appPath
    }

    func frame(device: Device, contacts: UnsafeMutableRawPointer?, count: Int32) {
        guard count >= 0, count <= 32 else { return }
        var x: Float = 0, y: Float = 0, active = 0
        if let contacts {
            for index in 0..<Int(count) {
                let base = index * 96
                guard contacts.load(fromByteOffset: base + 20, as: Int32.self) == 4 else { continue }
                let px = contacts.load(fromByteOffset: base + 32, as: Float.self)
                let py = contacts.load(fromByteOffset: base + 36, as: Float.self)
                guard px.isFinite, py.isFinite else { return }
                x += px; y += py; active += 1
            }
        }
        let key = UInt(bitPattern: device)
        lock.lock()
        guard accepting, strokes[key] != nil else { lock.unlock(); return }
        var stroke = strokes[key]!
        var action: String?
        if active == 0 {
            stroke = Stroke()
        } else if active == 4, !stroke.fired {
            let point = CGPoint(x: Double(x / 4), y: Double(y / 4))
            if let origin = stroke.origin {
                let dy = point.y - origin.y, dx = point.x - origin.x
                // 12% of trackpad height, with clear vertical intent.
                if abs(dy) >= 0.12, abs(dy) > abs(dx) * 1.4 {
                    stroke.fired = true
                    action = dy > 0 ? "open" : "close"
                }
            } else { stroke.origin = point }
        } else {
            // Changing finger counts must not preserve a stale centroid baseline.
            stroke.origin = nil
        }
        strokes[key] = stroke
        let epoch = generation
        lock.unlock()
        if let action {
            DispatchQueue.main.async { [self] in
                lock.lock(); let valid = accepting && epoch == generation; lock.unlock()
                if valid { send(action) }
            }
        }
    }

    func send(_ action: String) {
        if action == "close", NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.t4ko.omniwm-overview"
        ).isEmpty { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-g", "-a", appPath, "omniwm-overview://\(action)"]
        do { try process.run() }
        catch { log("open failed: \(error.localizedDescription)") }
    }

    @discardableResult
    func cleanup() -> Bool {
        lock.lock(); accepting = false; generation &+= 1; strokes.removeAll(); lock.unlock()
        cleanupPending = true
        for id in Array(devices.keys) {
            guard var registration = devices[id] else { continue }
            if registration.needsStop {
                let status = api.stop(registration.device)
                if status == KERN_SUCCESS || !api.running(registration.device) {
                    registration.needsStop = false
                }
            }
            if !registration.needsStop, registration.needsUnregister,
               api.unregister(registration.device, receiveFrame) != 0 {
                registration.needsUnregister = false
            }
            if registration.needsStop || registration.needsUnregister {
                // Keep both the device and its owning CFArray alive until cleanup
                // succeeds. A false unregister result is conservatively retried.
                devices[id] = registration
            } else { devices.removeValue(forKey: id) }
        }
        if devices.isEmpty { list = nil; cleanupPending = false }
        return !cleanupPending
    }

    func scheduleRetry() {
        let work = DispatchWorkItem { [self] in refresh(force: true) }
        retry = work
        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay, execute: work)
        retryDelay = min(30, retryDelay * 2)
    }

    func refresh(force: Bool = false) {
        guard !terminating else { return }
        let (newList, candidates) = api.enumerate()
        if !force, !cleanupPending, !devices.isEmpty, Set(candidates.keys) == Set(devices.keys),
           devices.values.allSatisfy({ api.running($0.device) }) { return }
        retry?.cancel(); retry = nil
        guard cleanup() else { scheduleRetry(); return }
        list = newList
        for (id, device) in candidates {
            lock.lock(); strokes[UInt(bitPattern: device)] = Stroke(); lock.unlock()
            let registered = api.register(device, receiveFrame, Unmanaged.passUnretained(self).toOpaque()) != 0
            if registered {
                // Track ownership before start, including a partially failed start.
                devices[id] = Registration(device: device)
            }
            guard registered, api.start(device, 0) == KERN_SUCCESS, api.running(device) else {
                cleanup(); scheduleRetry(); return
            }
        }
        lock.lock(); accepting = !devices.isEmpty; lock.unlock()
        if devices.count != candidates.count || devices.isEmpty {
            scheduleRetry()
        } else { retryDelay = 1 }
    }

    func run() {
        let center = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.didWakeNotification, NSWorkspace.sessionDidBecomeActiveNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [self] _ in
                retryDelay = 1; refresh(force: true)
            })
        }
        unlockObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil, queue: .main
        ) { [self] _ in retryDelay = 1; refresh(force: true) }
        // Prompt hotplug notifications plus a slow poll for private-class changes
        // and devices arriving later than the wake/unlock notification.
        if let port = IONotificationPortCreate(kIOMainPortDefault) {
            notificationPort = port
            IONotificationPortSetDispatchQueue(port, .main)
            for kind in [kIOFirstMatchNotification, kIOTerminatedNotification] {
                var iterator: io_iterator_t = 0
                let status = IOServiceAddMatchingNotification(
                    port, kind, IOServiceMatching("AppleMultitouchDevice"), topologyChanged,
                    Unmanaged.passUnretained(self).toOpaque(), &iterator
                )
                if status == KERN_SUCCESS { iterators.append(iterator); drain(iterator) }
            }
        }
        let poll = DispatchSource.makeTimerSource(queue: .main)
        poll.schedule(deadline: .now() + 15, repeating: 15, leeway: .seconds(3))
        poll.setEventHandler { [self] in refresh() }
        poll.resume(); timer = poll
        for number in [SIGTERM, SIGINT] {
            signal(number, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: number, queue: .main)
            source.setEventHandler { [self] in shutdown(); exit(0) }
            source.resume(); signals.append(source)
        }
        refresh()
        RunLoop.main.run()
    }

    func topologyDidChange() { retryDelay = 1; refresh(force: true) }

    func shutdown() {
        terminating = true; retry?.cancel(); timer?.cancel()
        for observer in observers { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
        if let observer = unlockObserver { DistributedNotificationCenter.default().removeObserver(observer) }
        for iterator in iterators { IOObjectRelease(iterator) }
        if let port = notificationPort { IONotificationPortDestroy(port) }
        // The signal handler exits immediately afterward; unsuccessful cleanup
        // retains ownership and the helper remains alive until process exit.
        cleanup()
    }
}

private func drain(_ iterator: io_iterator_t) {
    while case let entry = IOIteratorNext(iterator), entry != 0 { IOObjectRelease(entry) }
}

private let topologyChanged: IOServiceMatchingCallback = { context, iterator in
    drain(iterator)
    guard let context else { return }
    Unmanaged<GestureHelper>.fromOpaque(context).takeUnretainedValue().topologyDidChange()
}

private let receiveFrame: FrameCallback = { device, contacts, count, _, _, context in
    if let context {
        Unmanaged<GestureHelper>.fromOpaque(context).takeUnretainedValue()
            .frame(device: device, contacts: contacts, count: count)
    }
    return 0
}

private func log(_ message: String) {
    FileHandle.standardError.write(Data("omniwm-overview-gestures: \(message)\n".utf8))
}

@main
private enum Main {
    static func main() {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let api = MultitouchAPI() else { log("MultitouchSupport API unavailable"); exit(1) }
        if arguments == ["--diagnose"] {
            let (list, devices) = api.enumerate()
            print("MultitouchSupport API: available")
            print("Raw devices: \(list.map(CFArrayGetCount) ?? 0); usable devices: \(devices.count)")
            return
        }
        guard arguments.count == 2, arguments[0] == "--app-path", arguments[1].hasPrefix("/") else {
            log("usage: omniwm-overview-gestures --app-path /absolute/Overview.app | --diagnose")
            exit(64)
        }
        let helper = GestureHelper(api: api, appPath: arguments[1])
        helper.run()
        withExtendedLifetime(helper) {}
    }
}
