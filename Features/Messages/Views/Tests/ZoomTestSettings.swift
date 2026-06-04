//
//  ZoomTestSettings.swift
//  Scoop Test
//
//  Created by Art Ostin on 04/06/2026.
//

import SwiftUI


struct ToolbarZoomExample: View {
    @Namespace private var namespace
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            VStack {
                ForEach(0..<20) { i in
                    Text("Hello World \(i)")
                }
            }
            .navigationTitle("Inbox")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .matchedTransitionSource(id: "settings", in: namespace)
                }
            }
            .fullScreenCover(isPresented: $showSettings) { //KeyPut it
                SettingsViewTest()
                    // 👇 destination zooms out of that toolbar button
                    .navigationTransition(.zoom(sourceID: "settings", in: namespace))
            }
        }
    }
}

private struct SettingsViewTest: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Text("Settings content")
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
