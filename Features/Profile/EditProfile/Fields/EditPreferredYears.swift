//
//  EditPreferredYears.swift
//  Scoop
//
//  Created by Art Ostin on 19/01/2026.

import SwiftUI

struct EditPreferredYears: View {
    @Bindable var vm: EditProfileViewModel
    
    var selection: Binding<[String]> {
        Binding {vm.draft[keyPath: \.preferredYears]} set: {vm.set(.preferredYears, \.preferredYears, to: $0)}
    }
    let grid = [GridItem(.flexible()), GridItem(.flexible())]
    let options = ["U0", "U1", "U2", "U3", "U4"]

    var body: some View {
        VStack(alignment: .leading, spacing: 84) {
            Text("Preferred Years")
                .font(.title(32))
                .padding(.horizontal, 24)
            LazyVGrid(columns: grid, spacing: Spacing.xxl) {
                ForEach(options, id: \.self) { option in
                    YearPill(title: option, selection: selection)
                }
            }
        }
        .padding(.bottom, Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appCanvas)
    }
}

private struct YearPill: View {
    let title: String
    @Binding var selection: [String]

    @State private var shake = false
    @State private var showMessage = false

    private var isSelected: Bool { selection.contains(title) }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text(title)
                .frame(width: 148, height: 44)
                .font(.body(16, .bold))
                .foregroundStyle(isSelected ? Color.textAccent : Color.textTertiary)
                .capsuleStroke(lineWidth: 1, color: isSelected ? Color.textPrimary : Color.border)
                .contentShape(Rectangle())
                .overlay {
                    if !isSelected {
                        Cross()
                            .stroke(style: .init(lineWidth: 1, lineCap: .round))
                            .foregroundStyle(Color.textPlaceholder)
                            .padding(6)
                    }
                }
                .showShakeAnimation(bool: shake)

            Group {
                if showMessage {
                    Text("Can only deselect 2 years")
                        .font(.body(12, .bold))
                        .foregroundStyle(.accent)
                        .transition(.opacity)
                } else {
                    Text(" ")
                        .font(.body(12, .bold))
                }
            }
            .animation(.easeInOut(duration: 0.5), value: showMessage)
        }
        .onTapGesture {
            var current = selection

            if let idx = current.firstIndex(of: title) {
                if current.count < 4 {
                    shake.toggle()
                    showMessage = true
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(2))
                        showMessage = false
                    }
                    return
                }
                current.remove(at: idx)
            } else {
                current.append(title)
            }
            selection = current
        }
    }
}

private struct Cross: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return p
    }
}
