//
//  OptionSelect.swift
//  ScoopTest
//
//  Created by Art Ostin on 10/07/2025.
//

import SwiftUI

struct OptionSelect<Content: View>: View {

    var title: String
    @Binding var isSelected: String?
    @ViewBuilder let content: () -> Content

    
    var body: some View {
            VStack(alignment: .leading, spacing: 48) {
                SignUpTitle(text: title)
                    .padding(.top, 48)
                VStack(spacing: 48){
                    content()
                }
            }
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CustomBackButton()
                }
            }
            .padding(.horizontal)
    }
}

#Preview {
//    OptionSelect<Content: View>(title: {}, isSelected: "Attracted To")
}
