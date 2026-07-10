//
//  CustomList.swift
//  Scoop
//
//  Created by Art Ostin on 12/07/2025.
//

import SwiftUI


struct CustomList<Content: View> : View {

    let content: () -> Content
    var title: String?
    let showInfoText: Bool


    init(
        title: String? = nil,
        showInfoText: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ){
        self.title = title
        self.showInfoText = showInfoText
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                Text(title)
                    .font(.body(12, .bold))
                    .foregroundStyle(Color.textTertiary)
                    .padding(.horizontal, 16)

                if showInfoText {
                    Text("Choose which map app opens for seeing the locations of events")
                        .infoText()
                        .padding(.horizontal, 16)
                }
            }
            VStack(spacing: 6) {
                content()
            }
            .padding(.vertical, 12)
            .background(Color.white)
            .background(Color.white, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        
        let writeAll = response == ["U0", "U1", "U2", "U3", "U4"]
        
        NavigationLink(value: value) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.body(.bold))
                        .foregroundStyle(Color.textPrimary)
                    Text(isEmpty ? "Add Info" : (writeAll ? "All" : response.joined(separator: ", ")))
                        .foregroundStyle(isEmpty ? Color.textAccent : Color.textTertiary)
                        .font(.body(15))
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.body(13, .bold))
                    .foregroundStyle(isEmpty ? Color.textAccent : Color.textTertiary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 6)
        }
    }
}
