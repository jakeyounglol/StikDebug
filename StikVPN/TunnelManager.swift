import Foundation
import NetworkExtension

class TunnelManager: ObservableObject {
    static let shared = TunnelManager()

    enum TunnelStatus: String {
        case disconnected, connecting, connected, disconnecting, error
    }

    @Published var status: TunnelStatus = .disconnected {
        didSet { sharedDefaults.set(status.rawValue, forKey: "vpnStatus") }
    }

    private let sharedDefaults = UserDefaults(suiteName: "group.com.stik.sj")!
    private var manager: NETunnelProviderManager?

    private init() {
        loadPreferences()
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: sharedDefaults, queue: .main) { [weak self] _ in
            self?.status = self?.currentStatusFromDefaults() ?? .disconnected
        }
    }

    private func loadPreferences() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] mgrs, error in
            guard let self = self else { return }
            if let error = error {
                print("Failed to load configurations: \(error.localizedDescription)")
                self.manager = nil
                self.status = .error
                return
            }
            self.manager = mgrs?.first
            self.status = self.manager?.connection.status.vpnStatus ?? self.currentStatusFromDefaults()
        }
    }

    private func currentStatusFromDefaults() -> TunnelStatus {
        if let raw = sharedDefaults.string(forKey: "vpnStatus"), let st = TunnelStatus(rawValue: raw) {
            return st
        }
        return .disconnected
    }

    func startVPN() {
        loadPreferences()
        guard let manager = manager else { return }
        status = .connecting
        do {
            try manager.connection.startVPNTunnel()
        } catch {
            status = .error
        }
    }

    func stopVPN() {
        status = .disconnecting
        manager?.connection.stopVPNTunnel()
    }
}

private extension NEVPNStatus {
    var vpnStatus: TunnelManager.TunnelStatus {
        switch self {
        case .invalid, .disconnected: return .disconnected
        case .connecting, .reasserting: return .connecting
        case .connected: return .connected
        case .disconnecting: return .disconnecting
        @unknown default: return .error
        }
    }
}
