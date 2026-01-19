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
    
    @State private var shakeTicks: [String: Int] = [:]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 84) {
            Text("Preferred Years")
                .font(.title(32))
                .padding(.horizontal, 24)
            LazyVGrid(columns: grid, spacing: 48) {
                ForEach(options, id: \.self) { option in
                    optionPill(option)
                }
            }
        }
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background)
    }
}

extension EditPreferredYears {
    @ViewBuilder
    private func optionPill(_ title: String) -> some View {
        let isSelected = selection.wrappedValue.contains(title)
        let shakeValue = shakeTicks[title, default: 0]
        
        return VStack(spacing: 8) {
            Text(title)
                .frame(width: 148, height: 44)
                .font(.body(16, .bold))
                .foregroundStyle(isSelected ? Color.accent : Color.grayText)
                .stroke(20, lineWidth: 1, color: isSelected ? Color.black : Color.grayPlaceholder)
                .contentShape(Rectangle())
                .overlay {
                    if !isSelected {
                        Cross()
                            .stroke(style: .init(lineWidth: 1, lineCap: .round))
                            .foregroundStyle(Color.grayPlaceholder) // or .black / .accent / etc.
                            .padding(6) // keeps the X inside the rounded corners
                    }
                }
                .modifier(Shake(animatableData: shakeValue == 0 ? 0 : CGFloat(shakeValue)))
                .animation(shakeValue > 0 ? .easeInOut(duration: 0.5) : .none, value: shakeValue)
            
            if shakeValue > 0 {
                Text("min 3")
                    .font(.body(12, .bold))
                    .foregroundStyle(.accent)
            } else {
                Text(" ")
                    .font(.body(12, .bold))
            }
        }
        .onChange(of: shakeTicks[title, default: 0]) { _, newValue in
            guard newValue > 0 else { return }
            
            Task {
                try? await Task.sleep(for: .seconds(1))
                if shakeTicks[title, default: 0] == newValue {
                    withAnimation { shakeTicks[title] = 0 }
                }
            }
            
        }
        .onTapGesture  {
            var current = selection.wrappedValue
            if let idx = current.firstIndex(of: title) {
                if current.count <= 3 {
                    shakeTicks[title, default: 0] += 1
                    return
                }
                current.remove(at: idx)
            } else {
                current.append(title)
            }
            selection.wrappedValue = current
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


/*
 .font(.body(16, .bold))
 .overlay ( RoundedRectangle(cornerRadius: 20).stroke(isSelected ? Color.black : Color.grayBackground, lineWidth: 1))
 .foregroundStyle(isSelected ? Color.accent : Color.grayText
 )            .onTapGesture {

     isSelected.toggle()
 }

 */




//
//#Preview {
//    EditPreferredYears()
//}

