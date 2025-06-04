import SwiftUI
import NetworkExtension

private let vpnStatusKey = "vpnStatus"
private let appGroupID = "group.com.stik.sj"

enum TunnelStatus: String {
    case disconnected = "Disconnected"
    case connecting = "Connecting"
    case connected = "Connected"
    case disconnecting = "Disconnecting"
    case error = "Error"
}

struct VPNMainView: View {
    @AppStorage("customAccentColor") private var customAccentColorHex: String = ""
    @State private var status: TunnelStatus = .disconnected
    private let sharedDefaults = UserDefaults(suiteName: appGroupID)

    @AppStorage("TunnelDeviceIP", store: UserDefaults(suiteName: appGroupID)) private var deviceIP: String = "10.7.0.0"
    @AppStorage("TunnelFakeIP", store: UserDefaults(suiteName: appGroupID)) private var fakeIP: String = "10.7.0.1"
    @AppStorage("TunnelSubnetMask", store: UserDefaults(suiteName: appGroupID)) private var subnetMask: String = "255.255.255.0"

    private var accentColor: Color {
        if customAccentColorHex.isEmpty {
            return .blue
        } else {
            return Color(hex: customAccentColorHex) ?? .blue
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("StikVPN")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
            Text("Status: \(status.rawValue)")
                .font(.system(.title3, design: .rounded))
                .foregroundColor(.secondary)

            HStack(spacing: 20) {
                Button(action: startVPN) {
                    Label("Connect", systemImage: "link")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(accentColor)
                        .foregroundColor(accentColor.contrastText())
                        .cornerRadius(12)
                }
                Button(action: stopVPN) {
                    Label("Disconnect", systemImage: "link.badge.minus")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(accentColor)
                        .foregroundColor(accentColor.contrastText())
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                TextField("Device IP", text: $deviceIP)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Fake IP", text: $fakeIP)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Subnet Mask", text: $subnetMask)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button(action: saveIPs) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(accentColor)
                        .foregroundColor(accentColor.contrastText())
                        .cornerRadius(12)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .onAppear(perform: loadStatus)
    }

    private func loadStatus() {
        if let saved = sharedDefaults?.string(forKey: vpnStatusKey),
           let s = TunnelStatus(rawValue: saved) {
            status = s
        }
    }

    private func startVPN() {
        sharedDefaults?.set(TunnelStatus.connecting.rawValue, forKey: vpnStatusKey)
        status = .connecting
        // Actual connection handled by network extension target
    }

    private func stopVPN() {
        sharedDefaults?.set(TunnelStatus.disconnecting.rawValue, forKey: vpnStatusKey)
        status = .disconnecting
        // Actual disconnection handled by network extension target
    }

    private func saveIPs() {
        let defaults = UserDefaults(suiteName: appGroupID)
        defaults?.set(deviceIP, forKey: "TunnelDeviceIP")
        defaults?.set(fakeIP, forKey: "TunnelFakeIP")
        defaults?.set(subnetMask, forKey: "TunnelSubnetMask")
    }
}

struct VPNMainView_Previews: PreviewProvider {
    static var previews: some View {
        VPNMainView()
    }
}
