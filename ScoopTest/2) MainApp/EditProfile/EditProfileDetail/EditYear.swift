//
//  EditYear.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/07/2025.
//

import SwiftUI

struct EditYear: View {
    
    @State private var isSelected: String? = EditProfileViewModel.instance.user?.year
    
    let title: String?

    @Binding var screenTracker: OnboardingViewModel
        
    
    var isOnboarding: Bool
    
    init(isOnboarding: Bool = false, title: String? = nil, screenTracker: Binding<OnboardingViewModel>? = nil) {
        self.isOnboarding = isOnboarding
        self.title = title
        self._screenTracker = screenTracker ?? .constant(OnboardingViewModel())}
    
    var body: some View {
        EditOptionLayout(title: title, isSelected: $isSelected) {
            HStack{
                ForEach(0..<5) { i in
                    OptionPill(title: "U\(i)", counter: $screenTracker.screen,  width: 61, isSelected: $isSelected) {EditProfileViewModel.instance.updateYear(year: "U\(i)")}
                    Spacer()
                }
            }
        }
        .customNavigation(isOnboarding: isOnboarding)
    }
}

#Preview {
    EditYear()
}



struct YearCell: View {
    
    let title: String
    @State var isSelected: Bool = false
    var onTap: (() -> Void)
    
    
    
    
    var body: some View {
        Text(title)
            .frame(width: 50, height: 44)
            .font(.body(16, .bold))
            .overlay ( RoundedRectangle(cornerRadius: 20).stroke(isSelected ? Color.black : Color.grayBackground, lineWidth: 1))
            .foregroundStyle(isSelected ? Color.accent : Color.grayText
            )            .onTapGesture {
                
                isSelected.toggle()
            }
    }
}
