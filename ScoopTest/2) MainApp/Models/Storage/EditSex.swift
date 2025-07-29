//
//  EditSex.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/07/2025.
//

//import SwiftUI
//
//struct EditSex: View {
//    
//    var isOnboarding: Bool
//    @State private var isSelected: String?
//    @Environment(\.appDependencies) private var dependencies: AppDependencies
//    let title: String?
//    
//    @Binding var screenTracker: OnboardingViewModel
//    
//    init(isOnboarding: Bool = false, title: String? = nil, screenTracker: Binding<OnboardingViewModel>? = nil/*, vm: Binding<EditProfileViewModel>*/) {
//        self.isOnboarding = isOnboarding
//        self.title = title
//        self._screenTracker = screenTracker ?? .constant(OnboardingViewModel())
//    }
//    
//    
//    var body: some View {
//        
//        let manager = dependencies.profileManager
//
//        
//        EditOptionLayout(title: title, isSelected: $isSelected) {
//            HStack {
//                OptionPill(title: "Man", counter: $screenTracker.screen, isSelected: $isSelected) {
//                    Task{try? await manager.update(values: [.sex: "Man"])}
//                }
//                
//                Spacer()
//                OptionPill(title: "Women", counter: $screenTracker.screen, isSelected: $isSelected) {
//                    Task{try? await manager.update(values: [.sex: "Women"])}
//                }
//                HStack {
//                    Spacer()
//                    OptionPill(title: "Beyond Binary", counter: $screenTracker.screen, isSelected: $isSelected) {
//                        Task{try? await manager.update(values: [.sex: "Women"])}
//                    }
//                    Spacer()
//                }
//            }
//            .customNavigation(isOnboarding: isOnboarding)
//        }
//    }
//}
////#Preview {
////    EditSex(vm: .constant(EditProfileViewModel()))
////}
