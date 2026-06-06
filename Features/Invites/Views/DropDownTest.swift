//
//  DropDownTest.swift
//  Scoop Test
//
//  Created by Art Ostin on 06/06/2026.
//

import SwiftUI

struct DropDownTest: View {
    @State private var showPicker = false
    @State private var selectedType: Event.EventType?


    var body: some View {
        VStack(spacing: 24) {
//            menuVersion
            popoverButton
                .popover(isPresented: $showPicker, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                    Text("Hello World")
                        .presentationCompactAdaptation(.popover)
                }
        }
        .padding(.bottom, 96)
    }
    
    private var menuVersion: some View {
        Menu {
            Picker("Type", selection: $selectedType) {
                ForEach(Event.EventType.allCases, id: \.self) { eventType in
                    Text("\(eventType.emoji)     \(eventType.longTitle)")
                        .tag(Optional(eventType))
                }
            }
        } label: {
            HStack {
                Text(selectedType?.longTitle ?? "Options")
                Image(systemName: "chevron.down")
            }
            .fontWeight(.bold)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
    
    private var popoverButton: some View {
        Button {
            withAnimation(.snappy(duration: 0.2)) { showPicker.toggle() }
        } label: {
            HStack(spacing: 6) {
                Text("JUN 2026")
                Image(systemName: "chevron.down")
                    .rotationEffect(.degrees(showPicker ? 180 : 0))
            }
        }
    }
    
    private var popoverPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(0..<5, id: \.self) { index in
                Text("Hello World")
                if index < 4 {
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .frame(width: 240)
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
    }
}
