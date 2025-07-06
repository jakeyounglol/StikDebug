//
//  ScriptEditorView.swift
//  StikDebug
//
//  Created by s s on 2025/7/4.
//

import SwiftUI

/// Custom code editor with line numbers styled like Xcode.

struct ScriptEditorView: View {
    let scriptURL: URL
    @State private var scriptContent: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            CodeEditor(text: $scriptContent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray))
                .navigationTitle(scriptURL.lastPathComponent)
                .navigationBarTitleDisplayMode(.inline)
                .font(.system(.footnote, design: .monospaced))

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Save") {
                    saveScript()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .onAppear(perform: loadScript)
    }

    private func loadScript() {
        scriptContent = (try? String(contentsOf: scriptURL)) ?? ""
    }

    private func saveScript() {
        try? scriptContent.write(to: scriptURL, atomically: true, encoding: .utf8)
    }
}
