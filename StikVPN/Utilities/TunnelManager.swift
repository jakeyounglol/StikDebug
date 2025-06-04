import SwiftUI
import NetworkExtension

class VPNLogger: ObservableObject {
    @Published var logs: [String] = []
    static let shared = VPNLogger()
    private init() {}

    func log(_ message: Any, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("[\(fileName):\(line)] \(function): \(message)")
        #endif
        logs.append("\(message)")
    }
}

enum TunnelStatus: String {
    case disconnected = "Disconnected"
    case connecting = "Connecting"
    case connected = "Connected"
    case disconnecting = "Disconnecting"
    case error = "Error"
}

class TunnelManager: ObservableObject {
    @Published var tunnelStatus: TunnelStatus = .disconnected
    static let shared = TunnelManager()

    private let sharedDefaults = UserDefaults(suiteName: "group.com.stik.sj")
    private let vpnStatusKey = "vpnStatus"

    private var vpnManager: NETunnelProviderManager?
    private var tunnelDeviceIp: String {
        sharedDefaults?.string(forKey: "TunnelDeviceIP") ?? "10.7.0.0"
    }
    private var tunnelFakeIp: String {
        sharedDefaults?.string(forKey: "TunnelFakeIP") ?? "10.7.0.1"
    }
    private var tunnelSubnetMask: String {
        sharedDefaults?.string(forKey: "TunnelSubnetMask") ?? "255.255.255.0"
    }
    private var tunnelBundleId: String {
        Bundle.main.bundleIdentifier!.appending(".TunnelProv")
    }

    private init() {
        if let saved = sharedDefaults?.string(forKey: vpnStatusKey),
           let status = TunnelStatus(rawValue: saved) {
            tunnelStatus = status
        }
        loadTunnelPreferences()
        NotificationCenter.default.addObserver(self, selector: #selector(statusDidChange(_:)), name: .NEVPNStatusDidChange, object: nil)
    }

    private func loadTunnelPreferences() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let error = error {
                    VPNLogger.shared.log("Error loading preferences: \(error.localizedDescription)")
                    self.tunnelStatus = .error
                    return
                }
                if let managers = managers, !managers.isEmpty {
                    for manager in managers {
                        if let proto = manager.protocolConfiguration as? NETunnelProviderProtocol,
                           proto.providerBundleIdentifier == self.tunnelBundleId {
                            self.vpnManager = manager
                            self.updateTunnelStatus(from: manager.connection.status)
                            VPNLogger.shared.log("Loaded existing tunnel configuration")
                            break
                        }
                    }
                    if self.vpnManager == nil, let firstManager = managers.first {
                        self.vpnManager = firstManager
                        self.updateTunnelStatus(from: firstManager.connection.status)
                        VPNLogger.shared.log("Using existing tunnel configuration")
                    }
                } else {
                    VPNLogger.shared.log("No existing tunnel configuration found")
                }
            }
        }
    }

    @objc private func statusDidChange(_ notification: Notification) {
        if let connection = notification.object as? NEVPNConnection {
            updateTunnelStatus(from: connection.status)
        }
    }

    private func updateTunnelStatus(from connectionStatus: NEVPNStatus) {
        DispatchQueue.main.async {
            switch connectionStatus {
            case .invalid, .disconnected:
                self.tunnelStatus = .disconnected
            case .connecting:
                self.tunnelStatus = .connecting
            case .connected:
                self.tunnelStatus = .connected
            case .disconnecting:
                self.tunnelStatus = .disconnecting
            case .reasserting:
                self.tunnelStatus = .connecting
            @unknown default:
                self.tunnelStatus = .error
            }
            self.sharedDefaults?.set(self.tunnelStatus.rawValue, forKey: self.vpnStatusKey)
            VPNLogger.shared.log("VPN status updated: \(self.tunnelStatus.rawValue)")
        }
    }

    private func createOrUpdateTunnelConfiguration(completion: @escaping (Bool) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            guard let self = self else { return completion(false) }
            if let error = error {
                VPNLogger.shared.log("Error loading preferences: \(error.localizedDescription)")
                return completion(false)
            }

            let manager: NETunnelProviderManager
            if let existingManagers = managers, !existingManagers.isEmpty {
                if let matchingManager = existingManagers.first(where: {
                    ($0.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == self.tunnelBundleId
                }) {
                    manager = matchingManager
                    VPNLogger.shared.log("Updating existing tunnel configuration")
                } else {
                    manager = existingManagers[0]
                    VPNLogger.shared.log("Using first available tunnel configuration")
                }
            } else {
                manager = NETunnelProviderManager()
                VPNLogger.shared.log("Creating new tunnel configuration")
            }

            manager.localizedDescription = "StikVPN"
            let proto = NETunnelProviderProtocol()
            proto.providerBundleIdentifier = self.tunnelBundleId
            proto.serverAddress = "StikVPN Local Tunnel"
            manager.protocolConfiguration = proto
            manager.isOnDemandEnabled = true
            manager.isEnabled = true

            manager.saveToPreferences { [weak self] error in
                guard let self = self else { return completion(false) }
                DispatchQueue.main.async {
                    if let error = error {
                        VPNLogger.shared.log("Error saving tunnel configuration: \(error.localizedDescription)")
                        completion(false)
                        return
                    }
                    self.vpnManager = manager
                    VPNLogger.shared.log("Tunnel configuration saved successfully")
                    completion(true)
                }
            }
        }
    }

    func startVPN() {
        if let manager = vpnManager {
            startExistingVPN(manager: manager)
        } else {
            createOrUpdateTunnelConfiguration { [weak self] success in
                guard let self = self, success else { return }
                self.loadTunnelPreferences()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let manager = self.vpnManager {
                        self.startExistingVPN(manager: manager)
                    }
                }
            }
        }
    }

    private func startExistingVPN(manager: NETunnelProviderManager) {
        guard tunnelStatus != .connected else {
            VPNLogger.shared.log("Network tunnel is already connected")
            return
        }
        tunnelStatus = .connecting
        sharedDefaults?.set(tunnelStatus.rawValue, forKey: vpnStatusKey)
        let options: [String: NSObject] = [
            "TunnelDeviceIP": tunnelDeviceIp as NSObject,
            "TunnelFakeIP": tunnelFakeIp as NSObject,
            "TunnelSubnetMask": tunnelSubnetMask as NSObject
        ]
        do {
            try manager.connection.startVPNTunnel(options: options)
            VPNLogger.shared.log("Network tunnel start initiated")
        } catch {
            tunnelStatus = .error
            sharedDefaults?.set(tunnelStatus.rawValue, forKey: vpnStatusKey)
            VPNLogger.shared.log("Failed to start tunnel: \(error.localizedDescription)")
        }
    }

    func stopVPN() {
        guard let manager = vpnManager else { return }
        tunnelStatus = .disconnecting
        sharedDefaults?.set(tunnelStatus.rawValue, forKey: vpnStatusKey)
        manager.connection.stopVPNTunnel()
        VPNLogger.shared.log("Network tunnel stop initiated")
    }
}
