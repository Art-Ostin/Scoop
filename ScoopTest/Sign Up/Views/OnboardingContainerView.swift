//
//  OnboardingContainerView.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/05/2025.
//

import SwiftUI

struct OnboardingContainerView: View {
    
    //MARK: Properties
    
    
    @Environment(ScoopViewModel.self) private var viewModel
    
    //Animation Used
    let transition: AnyTransition = .asymmetric(
        insertion: .move(edge: .trailing),
        removal: .move(edge: .leading))
    
    
    // Different Options for the Sex, and Gender
    @State private var Sexoptions: [String] = ["Women", "Man", "Beyond Binary"]
    @State private var genderOptions: [String] = ["Man", "Women", "Man & Women", "All Genders"]
    
    // Different Options for the Year group, and selectingindex 
    @State private var year: [String] = ["U0", "U1", "U2", "U3", "U4"]
    @State private var selectedIndex: Int? = nil
    
    
    // Different Options for the Height
    @State private var height: String = "5' 9"
    let heightOptions: [String] = ["5' 4", "5' 5", "5' 6", "5' 7", "5' 8", "5' 9", "5' 10", "6, 0", "6' 1", "6' 2", "6' 3", "6' 4", "6' 5", "6' 6", "6' 7", "6' 8", "6' 9", "7' 0"]
    
    // Going Out Options
    @State private var goingOut: [String] = ["🌞 Everyday", "🍻5/6 a week", "🎟 3/4 a week", "🎶 twice a week", "🎊 Once a week", "🌙 Sometimes", "📝Rarely" ]
    
    // Looking For Options
    @State private var lookingFor: [String] = ["🌳 Long-term", "🌀 Exploring", "🍹 Something Casual" ]
    

    
    //MARK: View
    
    var body: some View {
        
        ZStack{
            VStack {
                if (viewModel.stageIndex > 0 && viewModel.stageIndex < 5) || (viewModel.stageIndex > 8 && viewModel.stageIndex < 11)  {
                    let (text, count, padding): (String, Int, CGFloat) = {
                        
                        switch viewModel.stageIndex {
                        case 1: return ("Sex", 6, 104)
                        case 2: return ("Attracted To", 5, 104)
                        case 3: return ("Year", 4, 148)
                        case 4: return ("Height", 3, 48)
                            
                        case 9: return ("I Go Out", 5, 104)
                        case 10: return ("Looking For", 4, 132)
                            
                        default: return ("", 0, 0)
                        }
                        
                    }()
                    titleView(text: text, count: count)
                        .padding(.top, 250)
                        .padding(.bottom, padding)
                        .transition(.opacity)
                }
                
                switch viewModel.stageIndex {
                    
                case 0:
                    AddEmailView()
                        .transition(transition)
                case 1:
                    optionsView(options: Sexoptions, isFilled: true, width: 148)
                        .transition(transition)
                case 2:
                    optionsView(options: genderOptions,isFilled: true, width: 148)
                        .transition(transition)
                case 3: yearOptions
                        .transition(transition)
                case 4: heightPicker
                        .transition(transition)
                case 5: NationalityView()
                        .transition(transition)
                case 6: FacultyView()
                        .transition(transition)
                case 7: HomeTownView()
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .identity))
                case 8: CreateProfileView()
                    
                case 9: optionsView(options: goingOut,isFilled: false, width: 163)
                    
                case 10: optionsView(options: lookingFor, isFilled: false, width: 163)
                    
                    
                    
                default: Text("Error")
                }
            }
            
        }
        
        .overlay(alignment: .topTrailing) {
            if viewModel.stageIndex < 8 {
                XButton()
                    .padding(.top, 18)
            }
            if viewModel.stageIndex > 8 {
                
                
                
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.stageIndex)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    OnboardingContainerView()
        .environment(ScoopViewModel())
}


extension OnboardingContainerView {

    private var heightPicker: some View {
        VStack(spacing: 48) {
            
            Picker("Height", selection: $height) {
                ForEach(heightOptions, id: \.self) {option in
                    Text(option)
                        .font(.custom("ModernEra-Medium", size: 20))
                }
            }
            .pickerStyle(.wheel)
            HStack {
                Spacer()
                NextButton(isEnabled: true, onInvalidTap: {})
            }
        }
    }
    
    private var yearOptions: some View {
        
        HStack(spacing: 10){
            ForEach(0..<year.count, id: \.self) { index in
                Text(year[index])
                    .frame(width: 61, height: 41, alignment: .center)
                    .background(selectedIndex == index ? Color.accentColor :
                                Color(red: 0.93, green: 0.93, blue: 0.93))
                    .cornerRadius(20)
                    .font(.custom("ModernEra-Bold", size: 16))
                    .foregroundStyle(selectedIndex == index ? .white : .black)
                    .onTapGesture {
                        selectedIndex = index
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                            viewModel.nextPage()
                        }
                    }
            }
        }
    }
}
