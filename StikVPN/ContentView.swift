//
//  ContentView.swift
//  StikVPN
//
//  Created by Stephen on 6/3/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var manager = TunnelManager.shared
    @AppStorage("customAccentColor") private var customAccentColorHex: String = ""
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
            Color(colorScheme == .dark ? .black : .white)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 25) {
                Spacer()
                Text("VPN Status: \(manager.status.rawValue.capitalized)")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                HStack(spacing: 20) {
                    Button(action: {
                        HapticFeedbackHelper.trigger()
                        manager.startVPN()
                    }) {
                        Text("Start")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(accentColor)
                            .foregroundColor(accentColor.contrastText())
                            .cornerRadius(16)
                            .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    Button(action: {
                        HapticFeedbackHelper.trigger()
                        manager.stopVPN()
                    }) {
                        Text("Stop")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(accentColor)
                            .foregroundColor(accentColor.contrastText())
                            .cornerRadius(16)
                            .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal, 20)
                Spacer()
            }
        }
        .accentColor(accentColor)
    }
}

#Preview {
    ContentView()
}
