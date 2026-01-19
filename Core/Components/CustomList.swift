//
//  CustomList.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/07/2025.
//

import SwiftUI


struct CustomList<Content: View> : View {
    
    let content: () -> Content
    var title: String?
    
    init(
        title: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ){
        self.title = title
        self.content = content
    }
    
    var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                if let title = title {
                    Text(title)
                        .font(.body(12, .bold))
                        .foregroundStyle(Color.grayText)
                        .padding(.horizontal, 16)
                }
                VStack(spacing: 6) {
                    content()
                }
                .padding(.vertical, 12)
                .background(Color.white)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.02), radius: 8, x: 0, y: 0.05)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .containerRelativeFrame(.horizontal)
    }
    }

#Preview {
    CustomList(content: {})
}

struct ListItem<Value: Hashable>: View {
    
    let title: String
    
    var response: [String]
    
    let value: Value
    
    var body: some View {
        let isEmpty = response.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        NavigationLink(value: value) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.body(.bold))
                        .foregroundStyle(Color.black)
                    Text(isEmpty ? "Add Info" : response.joined(separator: ", "))
                        .foregroundStyle(isEmpty ? .accent : Color.grayText)
                        .font(.body(15))
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.body(13, .bold))
                    .foregroundStyle(isEmpty ? .accent : Color.grayText)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 6)
        }
        .onAppear {
            print("Title is: \(title), value is: \(response)")
        }
    }
}
