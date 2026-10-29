import Network

/// Watches for an expensive (hotspot) connection and reports its interface name.
///
/// macOS marks both Wi-Fi Personal Hotspot and iPhone USB tethering as
/// expensive, so this needs no SSID lookup or location permission. One
/// monitor per interface type keeps a VPN tunnel from hiding the real link.
final class HotspotMonitor: Sendable {
    private let monitors = [
        NWPathMonitor(requiredInterfaceType: .wiredEthernet),
        NWPathMonitor(requiredInterfaceType: .wifi),
    ]
    private let queue = DispatchQueue(label: "HotspotMonitor")

    /// Calls `onChange` on the main actor with the hotspot interface name, or nil when none.
    func start(onChange: @escaping @MainActor @Sendable (String?) -> Void) {
        let state = HotspotState()
        for (index, monitor) in monitors.enumerated() {
            monitor.pathUpdateHandler = { path in
                let name = path.status == .satisfied && path.isExpensive
                    ? path.availableInterfaces.first?.name
                    : nil
                let current = state.update(slot: index, name: name)
                Task { @MainActor in onChange(current) }
            }
            monitor.start(queue: queue)
        }
    }

    func stop() {
        monitors.forEach { $0.cancel() }
    }
}

/// Per-monitor results, only touched from the monitor queue.
private final class HotspotState: @unchecked Sendable {
    private var names: [Int: String] = [:]

    func update(slot: Int, name: String?) -> String? {
        names[slot] = name
        return names.sorted { $0.key < $1.key }.first?.value
    }
}
