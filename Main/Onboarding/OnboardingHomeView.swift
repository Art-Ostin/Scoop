import SwiftUI

struct OnboardingHomeView: View {
    @Environment(\.appDependencies) private var dep
    
    @Environment(\.appState) private var appState
    @State var showOnboarding = false
    @State var current: Int = 0
    @State var showAlert: Bool = false
    
    @State private var tabSelection: TabBarItem = .meet
    
    var body: some View {
        
        ZStack {
            if #available(iOS 26.0, *) {
                TabView(selection: $tabSelection) {
                    meetView
                        .tag(TabBarItem.meet)
                        .tabItem {
                            Label("", image: tabSelection == .meet ? "BlackLogo" : "AppLogoBlack")
                        }
                        .ignoresSafeArea()
                    
                    meetingView
                        .tag(TabBarItem.events)
                        .tabItem {
                            Label("", image: tabSelection == .events ? "EventBlack" : "EventIcon")
                        }
                    
                    matchesView
                        .tag(TabBarItem.matches)
                        .tabItem {
                            Label("", image: tabSelection == .matches ? "BlackMessage" : "MessageIcon")
                        }
                }
            } else {
                CustomTabBarContainerView(selection: $tabSelection) {
                    meetView .tabBarItem(.meet, selection: $tabSelection)
                    meetingView.tabBarItem(.events, selection: $tabSelection)
                    matchesView.tabBarItem(.matches, selection: $tabSelection)
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
            
            if let user = await dep.authManager.fetchAuthUser() {
                print(user)
            } else {
                appState = .login
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingContainer(vm: EditProfileViewModel(cacheManager: dep.cacheManager, s: dep.sessionManager, userManager: dep.userManager, storageManager: dep.storageManager, cycleManager: dep.cycleManager, eventManager: dep.eventManager, defaults: dep.defaultsManager), defaults: dep.defaultsManager, current: $current)
        }
    }
}

extension OnboardingHomeView {
    
    private var meetView: some View {
        LimitedAccessPage(logOut: false, title: "Meet", imageName: "CoolGuys", description: "2 Profiles a Day. Send a Time & Place to Meet. No Texting.", onTap: {})
    }
    
    private var meetingView: some View {
        LimitedAccessPage(logOut: false, title: "Meeting", imageName: "EventCups", description: "Details for upcoming meet ups appear here."){}
    }
    
    private var matchesView: some View {
        LimitedAccessPage(logOut: true, title: "Message", imageName: "DancingCats", description: "View your previous matches here") {
            showOnboarding = true
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
                    .font(.tabTitle())
                
            }
            
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
            
            Image(imageName)
                .resizable()
                .frame(width: 240, height: 240)
            
            Text(description)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 32)
                .font(.body(18, .medium))
            
        }
        
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 96)
        .frame(maxHeight: .infinity, alignment: .top)
        .overlay(alignment: .topTrailing) {
            if logOut {
                LogOutButton {
                    onTap()
                }
            }
        }
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
/*
 print( await dep.authManager.fetchAuthUser() ?? appState = .login)
 */
