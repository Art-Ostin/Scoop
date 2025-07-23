//
//  OptionSelectionView.swift
//  ScoopTest
//
//  Created by Art Ostin on 10/07/2025.
//

import SwiftUI

struct EditHeight: View {
    
    @State private var isSelected: String? = EditProfileViewModel.instance.user?.height
    
    let heightOptions = ["4' 5", "4' 6","4' 7","4' 8", "4' 9","4' 10","5' 0","5' 1","5' 2","5' 3", "5' 4", "5' 5", "5' 6", "5' 7", "5' 8", "5' 9", "5' 10", "6' 0", "6' 1", "6' 2", "6' 3", "6' 4", "6' 5", "6' 6", "6' 7", "6' 8", "6' 9", "7' 0"]
    
    @State var height = "5' 8"
    
    let title: String?
    
    var isOnboarding: Bool
    
    init(isOnboarding: Bool = false, title: String? = nil) {
        self.isOnboarding = isOnboarding
        self.title = title
    }
    var body: some View {
        
        EditOptionLayout(title: title, isSelected: $isSelected) {
            Picker("Height", selection: $height) {
                ForEach(heightOptions, id: \.self) { option in
                    Text(option).font(.body(20))
                        .onChange(of: height) { EditProfileViewModel.instance.updateHeight(height: height)
                        }
                }
            }
            .customNavigation(isOnboarding: isOnboarding)
            .pickerStyle(.wheel)
        }
    }
}
