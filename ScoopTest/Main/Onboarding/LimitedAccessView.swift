import SwiftUI

struct LimitedAccessView: View {
    
    @Environment(\.appDependencies) private var dep
    @Binding var appState: AppState

    @State var showOnboarding = false
    @State var current: Int = 0
    
    var body: some View {
        
        ZStack {
            TabView {
                Tab("", image: "LetterIcon") {
                    ZStack{
                        Color.background.ignoresSafeArea()
                        LimitedAccessPage(logOut: false, title: "eet", imageName: "CoolGuys", description: "2 Profiles a Day. Send a Time & Place to Meet. No Texting."){}
                            .toolbarBackgroundVisibility(.visible, for: .tabBar)
                            .toolbarBackground(Color.background, for: .tabBar)
                    }
                }
                Tab("", image: "LogoIcon") {
                    ZStack{
                        Color.background.ignoresSafeArea()
                        LimitedAccessPage(logOut: false, title: "eeting", imageName: "EventCups", description: "Details for upcoming meet ups appear here."){}
                            .toolbarBackgroundVisibility(.visible, for: .tabBar)
                            .toolbarBackground(Color.background, for: .tabBar)
                    }
                }
                Tab("", image: "MessageIcon") {
                    ZStack {
                        Color.background.ignoresSafeArea()
                        LimitedAccessPage(logOut: true, title: "atches", imageName: "DancingCats", description: "View your previous matches here") {
                            Task {
                                appState = .login
                                try? await dep.authManager.deleteAuthUser()
                            }                            
                        }
                            .toolbarBackgroundVisibility(.visible, for: .tabBar)
                            .toolbarBackground(Color.background, for: .tabBar)
                    }
                }
            }
            ActionButton(text: (dep.defaultsManager.onboardingStep == 0) ? "Create Profile" : "Complete\(dep.defaultsManager.onboardingStep)/10") {
                showOnboarding = true
            }
            .padding(.top, 420)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingContainer(vm: EditProfileViewModel(cacheManager: dep.cacheManager, s: dep.sessionManager, userManager: dep.userManager, storageManager: dep.storageManager, defaults: dep.defaultsManager), defaults: dep.defaultsManager, current: $current)
        }
        .task {
            await dep.sessionManager.loadUser()
        }
    }
}

#Preview {
    LimitedAccessView()
}

struct LimitedAccessPage: View {
    
    let logOut: Bool
    
    let title, imageName, description: String
    
    let onTap: () -> Void
    
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
        .overlay(alignment: .topLeading) {
            LogOutButton {
                onTap()
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 72)
    }
}

struct LogOutButton : View {
    
    let onTap: () -> Void
    
    var body: some View {
        
        Text("Sign Out")
            .font(.body(14, .bold))
            .padding(8)
            .background (
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white )
            )
            .overlay (
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.black, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)
    }
}
