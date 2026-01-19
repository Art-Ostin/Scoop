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
    
    @State var showCustomSex: Bool = false
    
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
            .onTapGesture  {
                var current = selection.wrappedValue
                if let idx = current.firstIndex(of: title) {
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

