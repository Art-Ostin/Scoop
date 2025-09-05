import SwiftUI

struct OnboardingHomeView: View {
    
    
    @Environment(\.appDependencies) private var dep
    @Environment(\.appState) private var appState
    @State var showOnboarding = false
    @State var current: Int = 0
    @State var showAlert: Bool = false
    
    var body: some View {
        
        ZStack {
            TabView {
                Tab("", image: "LetterIcon") {
                    ZStack{
                        Color.background.ignoresSafeArea()
                        LimitedAccessPage(logOut: false, title: "Meet", imageName: "CoolGuys", description: "2 Profiles a Day. Send a Time & Place to Meet. No Texting."){}
                            .toolbarBackgroundVisibility(.visible, for: .tabBar)
                            .toolbarBackground(Color.background, for: .tabBar)
                    }
                }
                
                Tab("", image: "LogoIcon") {
                    ZStack{
                        Color.background.ignoresSafeArea()
                        LimitedAccessPage(logOut: false, title: "Meeting", imageName: "EventCups", description: "Details for upcoming meet ups appear here."){}
                            .toolbarBackgroundVisibility(.visible, for: .tabBar)
                            .toolbarBackground(Color.background, for: .tabBar)
                    }
                }
                
                Tab("", image: "MessageIcon") {
                    ZStack {
                        Color.background.ignoresSafeArea()
                        LimitedAccessPage(logOut: true, title: "Matches", imageName: "DancingCats", description: "View your previous matches here")
                        {showAlert = true}
                            .toolbarBackgroundVisibility(.visible, for: .tabBar)
                            .toolbarBackground(Color.background, for: .tabBar)
                    }
                    .alert("Sign Out", isPresented: $showAlert) {
                        Button("Cancel", role: .cancel) {}
                        Button("Sign Out") {
                            Task {
                                do {
                                    try await dep.authManager.deleteAuthUser()
                                } catch {
                                    print (error)
                                }
                                dep.defaultsManager.deleteDefaults()
                                appState.wrappedValue = .login
                            }
                        }
                    } message: {
                        if dep.defaultsManager.onboardingStep == 0 {
                            Text("Are you sure you want to sign Out?")
                        } else {
                            Text("Are you sure you want to sign Out? Your Progress will be lost.")
                        }
                    }
                }
            }
            ActionButton(text: (dep.defaultsManager.onboardingStep == 0) ? "Create Profile" : "Complete \(dep.defaultsManager.onboardingStep)/10") {
                showOnboarding = true
            }
            .padding(.top, 420)
        } .onAppear {
            let draft = dep.defaultsManager.fetch()
            print(draft ?? "No draft")
        }
        .task {
            print ( await dep.authManager.fetchAuthUser() ?? "NO current user")
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingContainer(vm: EditProfileViewModel(cacheManager: dep.cacheManager, s: dep.sessionManager, userManager: dep.userManager, storageManager: dep.storageManager, cycleManager: dep.cycleManager, eventManager: dep.eventManager, defaults: dep.defaultsManager), defaults: dep.defaultsManager, current: $current)
        }
    }
}


struct LimitedAccessPage: View {
    
    let logOut: Bool
    
    let title, imageName, description: String
    
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 72) {
            VStack(spacing: 48) {
                    Text(title)
                        .font(.title())
                
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
        .overlay(alignment: .topTrailing) {
            if logOut {
                LogOutButton {
                    onTap()
                }
            }
        }
        .padding(.top, 36)
    }
}

struct LogOutButton : View {
    
    let onTap: () -> Void
    
    var body: some View {
        
        Button {
            onTap()
        } label : {
            Text("Sign out")
                .font(.body(14, .bold))
                .padding(8)
                .foregroundStyle(.black)
                .background (
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white )
                        .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)
                )
                .overlay (
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.black, lineWidth: 1)
                )
                .padding(.horizontal, 16)
        }
    }
}
