//
//  OptionsSelectionView.swift
//  ScoopTest
//
//  Created by Art Ostin on 19/06/2025.
//

import SwiftUI

struct OptionsSelectionView: View {
    
    @Environment(AppState.self) private var appState
    
    private var screen: Int {
        if case .onboarding(let index) = appState.stage { return index }
        return 0
    }
    
    @State private var genderOptions = ["Man", "Women", "Man & Women", "All Genders"]
    @State private var sexOptions = ["Women", "Man", "Beyond Binary"]
    @State private var year = ["U0", "U1", "U2", "U3", "U4"]
    let heightOptions = ["5' 4", "5' 5", "5' 6", "5' 7", "5' 8", "5' 9", "5' 10", "6, 0", "6' 1", "6' 2", "6' 3", "6' 4", "6' 5", "6' 6", "6' 7", "6' 8", "6' 9", "7' 0"]
    
    @State private var height: String = "5' 8"
    
    var body: some View {
        VStack(alignment: .leading) {
            
            ZStack {
                switch screen {
                case 1: SignUpTitle(text: "Sex", count: 5)
                case 2: SignUpTitle(text: "Attracted to", count: 4)
                case 3: SignUpTitle(text: "Year", count: 3)
                case 4: SignUpTitle(text: "Height", count: 2)
                default: EmptyView()
                }
            }
            .id("title\(screen)")
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: screen)
            .padding(.top, 224)

            
            ZStack {
                switch screen {
                case 1:
                    OptionView(options: sexOptions, width: 148)
                        .padding(.top, 104)
                case 2:
                    OptionView(options: genderOptions, width: 148)
                        .padding(.top, 104)
                case 3:
                    OptionView(options: year, width: 61, HSpacing: 8)
                        .padding(.top, 148)
                case 4:
                    heightPicker
                default:
                    EmptyView()
                }
            }
            .id("options\(screen)")
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal:   .move(edge: .leading)
              ))
            .animation(.easeInOut(duration: 0.3), value: screen)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

extension OptionsSelectionView {
    private var heightPicker: some View {
        VStack(spacing: 48) {
            Picker("Height", selection: $height) {
                ForEach(heightOptions, id: \.self) { option in
                    Text(option).font(.body(20))
                }
            }
            .pickerStyle(.wheel)
            HStack {
                Spacer()
//                NextButton(isEnabled: true, onInvalidTap: {})
            }
        }
    }
}


