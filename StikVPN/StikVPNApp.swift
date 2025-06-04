//
//  StikVPNApp.swift
//  StikVPN
//
//  Created by Stephen on 6/3/25.
//

import SwiftUI

@main
struct StikVPNApp: App {
    @AppStorage("customAccentColor") private var customAccentColorHex: String = ""

    private var accentColor: Color {
        if customAccentColorHex.isEmpty {
            return .blue
        } else {
            return Color(hex: customAccentColorHex) ?? .blue
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear { _ = TunnelManager.shared }
                .accentColor(accentColor)
                .environment(\.accentColor, accentColor)
        }
    }
}
