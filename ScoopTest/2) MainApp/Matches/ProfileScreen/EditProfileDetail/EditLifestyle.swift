//
//  VicesView.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/07/2025.
//

import SwiftUI

struct VicesView: View {
    @State var isSelectedDrinking: String? = nil
    @State var isSelectedSmoking: String? = nil
    @State var isSelectedMarijuana: String? = nil
    @State var isSelectedDrugs: String? = nil

    var body: some View {
        
        VStack(spacing: 36) {
            vicesOptions(title: "Drinking", isSelected: $isSelectedDrinking)
            vicesOptions(title: "Smoking", isSelected: $isSelectedSmoking)
            vicesOptions(title: "Marijuana", isSelected: $isSelectedMarijuana)
            vicesOptions(title: "Drugs", isSelected: $isSelectedDrugs)
        }
        .padding(.horizontal, 32)

    }
    
    private func vicesOptions(title: String, isSelected: Binding<String?>) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(title)
                .font(.title(28))
            HStack {
                OptionCell2(title: "Yes", width: 75, isSelected: isSelected, onTap: {})
                Spacer()
                OptionCell2(title: "No", width: 75, isSelected: isSelected, onTap: {})
                Spacer()
                OptionCell2(title: "Occasionally", isSelected: isSelected, onTap: {} )
            }
        }
    }
}

#Preview {
    VicesView()
}



