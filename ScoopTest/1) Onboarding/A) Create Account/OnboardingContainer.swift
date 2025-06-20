//
//  OnboardingContainerView.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/05/2025.
//

import SwiftUI

struct OnboardingContainer: View {
    
    @Environment(AppState.self) private var appState
    
    
    private var screen: Int {
        
        if case .onboarding(let index) = appState.stage {
            return index
        }
        return 0
    }
    
    let transition: AnyTransition = .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
    
    var body: some View {
        
        ZStack {
            
            Group {
                switch screen {
                    
                case 0:
                    AddEmailView()
                        .transition(transition)
                
                case 1...4:
                    OptionsSelectionView()
                        .transition(transition)
                
                case 5:
                    NationalityView()
                        .transition(transition)
                    
                case 6:
                    FacultyView()
                        .transition(transition)
                    
                case 7:
                    HomeTownView()
                        .transition(transition)
                    
                default:
                    EmptyView()
                }
            }
            XButton()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 12)
        }
        .padding(32)
    }
}

#Preview {
    OnboardingContainer()
        .environment(AppState())
        .offWhite()
}

    
    
    
    
    
    
//
//    var body: some View {
//        
//        ZStack{
//            
//            VStack {
//                if (vm.stageIndex > 0 && vm.stageIndex < 5) {
//                    
//                    let (text, count, padding): (String, Int, CGFloat) = {
//                        
//                        switch vm.stageIndex {
//                        case 1: return ("Sex", 6, 104)
//                        case 2: return ("Attracted To", 5, 104)
//                        case 3: return ("Year", 4, 148)
//                        case 4: return ("Height", 3, 48)
//                            
//                        case 9: return ("I Go Out", 5, 104)
//                        case 10: return ("Looking For", 4, 132)
//                            
//                        default: return ("", 0, 0)
//                        }
//                        
//                    }()
//                    SignUpTitle(text: text, count: count)
//                        .padding(.top, 250)
//                        .padding(.bottom, padding)
//                        .transition(.opacity)
//                }
//                
//                
//                
//                switch vm.stageIndex {
//                    
//                case 0:
//                    AddEmailView(vm: vm)
//                        .transition(transition)
////                case 1:
////                    OptionView()
////                        .transition(transition)
////                case 2:
////                    OptionView(vm: vm, options: genderOptions)
////                        .transition(transition)
//                case 3: yearOptions
//                        .transition(transition)
//                case 4: heightPicker
//                        .transition(transition)
//                    
//                case 5: NationalityView(vm: vm)
//                        .transition(transition)
//                    
//                case 6: FacultyView(vm: vm)
//                        .transition(transition)
//                    
//                case 7: HomeTownView(vm: vm)
//                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .identity))
//                    
//                default: Text("Error")
//                }
//            }
//        }
//        
//        .overlay(alignment: .topTrailing) {
//            if vm.stageIndex < 8 {
//                XButton(validTap: {
//                })
//                .padding(.top, 18)
//            }
//        }
//        .animation(.easeInOut(duration: 0.2), value: vm.stageIndex)
//        .padding(.horizontal, 32)
//        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
//        .ignoresSafeArea(.keyboard)
//    }
//}


//#Preview {
//    OnboardingContainer(startingAt: 0)
//        .environment(AppState())
//}


//extension OnboardingContainer{
//    
//    private var heightPicker: some View {
//        VStack(spacing: 48) {
//            
//            Picker("Height", selection: $height) {
//                ForEach(heightOptions, id: \.self) {option in
//                    Text(option)
//                        .font(.body(20))
//                }
//            }
//            .pickerStyle(.wheel)
//            HStack {
//                Spacer()
//                NextButton(isEnabled: true, validTap: {vm.nextPage()}, onInvalidTap: {}, vm: vm)
//            }
//        }
//    }
//


//    private var yearOptions: some View {
//    
//        return HStack(spacing: 10){
//            ForEach(0..<year.count, id: \.self) { index in
//                Text(year[index])
//                    .frame(width: 61, height: 41, alignment: .center)
//                    .background(selectedIndex == index ? Color.accentColor :
//                                    Color(red: 0.93, green: 0.93, blue: 0.93))
//                    .cornerRadius(20)
//                    .font(.body(16, .bold))
//                    .foregroundStyle(selectedIndex == index ? .white : .black)
//                    .onTapGesture {
//                        selectedIndex = index
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
//                            vm.nextPage()
//                        }
//                    }
//            }
//        }
//    }
//}
