import SwiftUI

struct LimitedAccessView: View {
    
    
    
    @State private var vm: OnboardingViewModel
    
    
    @Environment(\.appDependencies) private var dependencies: AppDependencies
    
    
    @State private var showOnboarding = false
    @Binding var showLogin: Bool
    
    init(showLogin: Binding<Bool>, auth: AuthenticationManaging) {
        self._showLogin = showLogin
        self._vm = State(initialValue: OnboardingViewModel(authManager: auth))
    }
    
    var body: some View {
        
        
        ZStack {
            TabView {
                Tab("", image: "LetterIcon") {
                    ZStack{
                        Color.background.ignoresSafeArea()
                        LimitedAccessPage(title: "eet", imageName: "CoolGuys", description: "2 Profiles a Day. Send a Time & Place to Meet. No Texting.")
                            .toolbarBackgroundVisibility(.visible, for: .tabBar)
                            .toolbarBackground(Color.background, for: .tabBar)
                    }
                }
                Tab("", image: "LogoIcon") {
                    ZStack{
                        Color.background.ignoresSafeArea()
                        LimitedAccessPage(title: "eeting", imageName: "EventCups", description: "Details for upcoming meet ups appear here.")
                            .toolbarBackgroundVisibility(.visible, for: .tabBar)
                            .toolbarBackground(Color.background, for: .tabBar)
                    }
                }
                Tab("", image: "MessageIcon") {
                    ZStack{
                        Color.background.ignoresSafeArea()
                        LimitedAccessPage(title: "atches", imageName: "DancingCats", description: "View your previous matches here")
                            .toolbarBackgroundVisibility(.visible, for: .tabBar)
                            .toolbarBackground(Color.background, for: .tabBar)
                    }
                }
            }
            ActionButton(text: (vm.screen == 0) ? "Create Profile" : "Complete \(vm.screen)/10", onTap: {showOnboarding = true})
                .padding(.top, 420)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            NewOnboardingContainer(showLogin: $showLogin)
//            OnboardingContainer(vm: $vm, showLogin: $showLogin)
        }
    }
}

#Preview {
    LimitedAccessView(showLogin: .constant(true), auth: AuthenticationManager(profile: ProfileManager()))
}


struct LimitedAccessPage: View {
    
    let title, imageName, description: String
    
    var body: some View {
        
        VStack(spacing: 72) {
            VStack(spacing: 48) {
                HStack(spacing: 3) {
                    Image("MIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                    Text(title)
                        .font(.title())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                
                Image(imageName)
                    .resizable()
                    .frame(width: 240, height: 240)
                
            }
            
            Text(description)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 32)
                .font(.body(18, .medium))
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 72)
    }
}


//    .safeAreaInset(edge: .bottom) {
//        ActionButton(
//            text: vm.screen == 0
//                ? "Create Profile"
//                : "Complete Profile \(vm.screen)/10"
//        ) {
//            showOnboarding = true
//        }
//        .padding(.horizontal)
//        .padding(.top, 8)
//        .background(Color.background)
//
//    .fullScreenCover(isPresented: $showOnboarding) {
//        OnboardingContainer(vm: $vm, showLogin: $showLogin)
//    }
