//
//  OptionSelectionView.swift
//  ScoopTest
//
//  Created by Art Ostin on 10/07/2025.
//

import SwiftUI

struct EditHeight: View {
    
    @Binding var vm: EditProfileViewModel
    @Environment(\.flowMode) private var mode
    
    let heightOptions = (53...84).map { inches in
        "\(inches / 12)' \(inches % 12)"
    }
    
    @State var height = "5' 8"
    var body: some View {
        VStack {
            SignUpTitle(text: "Height")
            ZStack {
                Picker("Height", selection: $height) {
                    ForEach(heightOptions, id: \.self) { option in
                        Text(option).font(.body(20))
                            .onChange(of: height) {Task{try await vm.updateUser(values: [.height : height])}}
                    }
                }
                .pickerStyle(.wheel)
                
                if case .onboarding(_, let advance) = mode {
                    NextButton(isEnabled: true) {
                        Task { try? await vm.updateUser(values: [.height : height]) }
                        advance()
                    }
                }
            }
            .flowNavigation()
            .task {
                height = vm.fetchUserField(\.height) ?? "" 
            }
        }
    }
}
