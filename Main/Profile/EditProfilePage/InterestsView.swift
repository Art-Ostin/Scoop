//
//  InterestsTest.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/07/2025.
//

import SwiftUI

struct InterestsHolder<Content: View, Destination: View>: View {
    
    let title: String
    let destination: Destination
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content, @ViewBuilder destination: () -> Destination) {
        self.title = title
        self.content = content()
        self.destination = destination()
    }
    
    var body: some View {
        NavigationLink {
            destination
        } label : {
            VStack(spacing: 8) {
                HStack {
                    Text("Interests & Character")
                        .font(.body(12, .bold))
                        .foregroundStyle(Color.grayText)
                    Spacer()
                    Image("EditGray")
                        .offset(x: -8)
                        .offset(y: -4)
                }
                .padding(.horizontal, 16)
                content
            }
        }
//        .padding()
    }
}


struct InterestsLayout: View {
    
    var passions: [String]
    
    let forProfile: Bool
    
    
    private var rows: [[String]] {
        stride(from: 0, to: passions.count, by: 2).map {
            Array(passions[$0..<min($0+2, passions.count)])
        }
    }
    
    var body: some View {
        VStack(spacing: forProfile ? 12 : 16) {
            ForEach(rows.indices, id: \.self) { index in
                let row = rows[index]
                HStack {
                    Text(row[safe: 0] ?? "")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                        .frame(height: 20)
                    
                    Text(row.count > 1 ? row[1] : "")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                if index < rows.count - 1 {
                    Divider()
                }
            }
        }
        .padding()
        .font(.body())
        .foregroundStyle(passions.count < 1 ? Color.accent : Color.black)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill( Color.white)
                .shadow(color: .black.opacity(0.02), radius: 8, x: 0, y: 0.05)
        )
//        .overlay(RoundedRectangle(cornerRadius: 12).stroke(passions.count < 1 ? Color.accent : Color(red: 0.85, green: 0.85, blue: 0.85), lineWidth: 0.5))
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}


struct InterestsView: View {
    @Bindable var vm: EditProfileViewModel
    
    @State var interests: [String]?
    
    var body: some View {
        InterestsHolder(title: "Interests") {
            InterestsLayout(passions: interests ?? [], forProfile: false)
        } destination: {
            EditInterests(vm: vm)
        }
        .onAppear {
            interests = vm.user.interests
        }
    }
}
