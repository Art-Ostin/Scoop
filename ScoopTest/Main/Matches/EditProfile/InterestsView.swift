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
        
        CustomList {
            NavigationLink {
                destination
            } label : {
                VStack(spacing: 8) {
                    HStack {
                        Text(title)
                            .font(.body(12, .bold))
                            .foregroundStyle(Color.grayText)
                        Spacer()
                        Image("EditGray")
                    }
                    .padding(.horizontal, 8)
                    content
                }
            }
            .padding()
        }
        .padding(.horizontal, 32)
    }
}


struct InterestsLayout: View {
    
    @Bindable var vm: EditProfileViewModel
    
    var passions: [String] {
        vm.draftUser.interests ?? []
    }
    
    
    private var rows: [[String]] {
        stride(from: 0, to: passions.count, by: 2).map {
            Array(passions[$0..<min($0+2, passions.count)])
        }
    }
    var body: some View {
        
        VStack(spacing: 16) {
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
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
        )
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(passions.count < 1 ? Color.accent : Color(red: 0.85, green: 0.85, blue: 0.85), lineWidth: 0.5))
        
    }
    
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}


struct InterestsView: View {
    @Bindable var vm: EditProfileViewModel
    var body: some View {
        InterestsHolder(title: "Interests") {
            InterestsLayout(vm: vm)
        } destination: {
            EditInterests(vm: vm)
        }
    }
}
