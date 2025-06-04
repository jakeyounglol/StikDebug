import SwiftUI
import NetworkExtension

struct StikVPNManagementView: View {
    @ObservedObject private var tunnelManager = TunnelManager.shared
    @AppStorage("customAccentColor") private var customAccentColorHex: String = ""
    @AppStorage("autoStartVPN") private var autoStartVPN = true
    @AppStorage("TunnelDeviceIP") private var deviceIP: String = "10.7.0.0"
    @AppStorage("TunnelFakeIP") private var fakeIP: String = "10.7.0.1"
    @Environment(\.colorScheme) private var colorScheme

    private var accentColor: Color {
        if customAccentColorHex.isEmpty {
            return .blue
        } else {
            return Color(hex: customAccentColorHex) ?? .blue
        }
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 8) {
                    Text("StikVPN Status")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(tunnelManager.tunnelStatus.rawValue)
                        .font(.title)
                        .fontWeight(.bold)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Device IP")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    HStack {
                        TextField("10.7.0.0", text: $deviceIP)
                            .keyboardType(.numbersAndPunctuation)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.vertical, 8)

                        if !deviceIP.isEmpty {
                            Button(action: { deviceIP = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color(UIColor.tertiaryLabel))
                                    .font(.system(size: 16))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .background(Color(UIColor.tertiarySystemFill))
                    .cornerRadius(8)

                    Text("Fake IP")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    HStack {
                        TextField("10.7.0.1", text: $fakeIP)
                            .keyboardType(.numbersAndPunctuation)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.vertical, 8)

                        if !fakeIP.isEmpty {
                            Button(action: { fakeIP = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color(UIColor.tertiaryLabel))
                                    .font(.system(size: 16))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .background(Color(UIColor.tertiarySystemFill))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 40)

                Button(action: toggleVPN) {
                    HStack {
                        Image(systemName: tunnelManager.tunnelStatus == .connected ? "xmark" : "checkmark")
                            .font(.system(size: 20))
                        Text(tunnelManager.tunnelStatus == .connected ? "Disable StikVPN" : "Enable StikVPN")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(accentColor)
                    .foregroundColor(accentColor.contrastText())
                    .cornerRadius(16)
                    .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 40)

                Toggle("Start StikVPN Automatically", isOn: $autoStartVPN)
                    .padding(.horizontal, 40)
                
                Spacer()
            }
        }
    }

    private func toggleVPN() {
        switch tunnelManager.tunnelStatus {
        case .connected, .connecting:
            tunnelManager.stopVPN()
        case .disconnected, .error, .disconnecting:
            tunnelManager.startVPN()
            // Ensure the debugging heartbeat resumes when the VPN is enabled
            startHeartbeatInBackground()
        }
    }
}

#Preview {
    StikVPNManagementView()
}
