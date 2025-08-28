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
            .padding(.vertical)
            .padding(.horizontal, 32)
        }
    }

#Preview {
    CustomList(content: {})
}

struct ListItem<Destination: View>: View {
    
    let title: String
    
    let response: [String]
    
    let destination: () -> Destination
    
    var body: some View {
        
        NavigationLink {
            destination()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.body(.bold))
                        .foregroundStyle(Color.black)
                    Text(response.joined(separator: ", "))
                        .foregroundStyle(Color.grayText)
                        .font(.body(15))
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Spacer()
                Image("EditGray")
                    .font(.body(13, .bold))
                    .foregroundStyle(Color.grayText)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 6)
        }
    }
}
