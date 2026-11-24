import AppKit
import ApplicationServices
import CoreGraphics

/// Global Option+V listener backed by a CGEventTap.
///
/// A session-level tap requires Accessibility permission; the first launch
/// triggers the system prompt. If the tap is disabled by the OS it is
/// re-enabled automatically, and installation is retried until it succeeds.
@MainActor
final class HotKeyMonitor {
    private static let optionVKeyCode: Int64 = 9 // kVK_ANSI_V

    private let onTrigger: () -> Void
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var retryTimer: Timer?

    init(onTrigger: @escaping () -> Void) {
        self.onTrigger = onTrigger
    }

    func start() {
        requestAccessibilityIfNeeded()
        installTap()

        retryTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self else {
                    timer.invalidate()
                    return
                }
                if self.eventTap != nil {
                    timer.invalidate()
                } else {
                    self.installTap()
                }
            }
        }
        RunLoop.main.add(retryTimer!, forMode: .common)
    }

    private func reenable() {
        guard let eventTap else { return }
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    private func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        // Literal value of kAXTrustedCheckOptionPrompt; the imported global
        // variable is not concurrency-safe in Swift 6.
        let options: CFDictionary = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    private func installTap() {
        guard AXIsProcessTrusted(), eventTap == nil else { return }

        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)

        let callback: CGEventTapCallBack = { _, type, event, refcon in
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let refcon {
                    let monitor = Unmanaged<HotKeyMonitor>.fromOpaque(refcon).takeUnretainedValue()
                    monitor.reenable()
                }
                return Unmanaged.passUnretained(event)
            }
            guard type == .keyDown, let refcon else {
                return Unmanaged.passUnretained(event)
            }

            // Let our own synthetic Cmd+V pass through untouched.
            if event.getIntegerValueField(.eventSourceUserData) == PasteSimulator.userDataTag {
                return Unmanaged.passUnretained(event)
            }

            let flags = event.flags
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let isOptionV = keyCode == HotKeyMonitor.optionVKeyCode
                && flags.contains(.maskAlternate)
                && !flags.contains(.maskCommand)
                && !flags.contains(.maskControl)

            guard isOptionV else { return Unmanaged.passUnretained(event) }

            let monitor = Unmanaged<HotKeyMonitor>.fromOpaque(refcon).takeUnretainedValue()
            DispatchQueue.main.async { monitor.onTrigger() }
            return nil // consume Option+V so it does not type into the target app
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(RunLoop.main.getCFRunLoop(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        eventTap = tap
        runLoopSource = source
    }

    deinit {
        retryTimer?.invalidate()
        if let source = runLoopSource {
            CFRunLoopRemoveSource(RunLoop.main.getCFRunLoop(), source, .commonModes)
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
    }
}
