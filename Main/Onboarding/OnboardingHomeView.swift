import SwiftUI
import FirebaseAuth

struct OnboardingHomeView: View {
    @Environment(\.appDependencies) private var dep
    
    @Environment(\.appState) private var appState
    @State private var vm: OnboardingViewModel?
    @State var showOnboarding = false
    @State var current: Int = 0
    @State var showAlert: Bool = false
    @State private var tabSelection: TabBarItem = .meet
    
    var body: some View {
        ZStack {
            if #available(iOS 26.0, *) {TabView(selection: $tabSelection) {
                meetView
                    .tag(TabBarItem.meet)
                    .tabItem { Label("", image: tabSelection == .meet ? "BlackLogo" : "AppLogoBlack")}
                meetingView
                    .tag(TabBarItem.events)
                    .tabItem {Label("", image: tabSelection == .events ? "EventBlack" : "EventIcon")}
                
                matchesView
                    .tag(TabBarItem.matches)
                    .tabItem {Label("", image: tabSelection == .matches ? "BlackMessage" : "MessageIcon")}
            }} else {
                CustomTabBarContainerView(selection: $tabSelection) {
                    meetView .tabBarItem(.meet, selection: $tabSelection)
                    meetingView.tabBarItem(.events, selection: $tabSelection)
                    matchesView.tabBarItem(.matches, selection: $tabSelection)
                }
            }
        }
        .task {
            if vm == nil {
                await MainActor.run {
                    vm = OnboardingViewModel(
                        authManager: dep.authManager,
                        defaultManager: dep.defaultsManager,
                        sessionManager: dep.sessionManager,
                        userManager: dep.userManager,
                    )
                }
            }
            guard let vm = vm, await vm.isLoggedIn() else {
                appState.wrappedValue = .login
                return
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            if let vm {OnboardingContainer(vm: vm, storage: dep.storageManager)}
        }
        .alert("Sign Out", isPresented: $showAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out") {
                Task {
                    do {
                        try await vm?.signOut()
                        appState.wrappedValue = .login
                    } catch { print("THIS IS THE ERROR\(error)")}
                }
            }
        } message: {
            vm?.onboardingStep == 0 ?
            Text("Are you sure you want to sign Out?") :
            Text("Are you sure you want to sign Out? Your Progress will be lost.")
        }
    }
}

extension OnboardingHomeView {
    private var meetView: some View {
        LimitedAccessPage(title: "Meet", imageName: "Plants", description: "View weekly profiles here & send a Time and Place to Meet.", showOnboarding: $showOnboarding, showLogout: $showAlert, onboardingStep: vm?.onboardingStep ?? 0)
    }
    private var meetingView: some View {
        LimitedAccessPage(title: "Meeting", imageName: "EventCups", description: "Details for upcoming meet ups appear here.", showOnboarding: $showOnboarding, showLogout: $showAlert, onboardingStep: vm?.onboardingStep ?? 0)
    }
    private var matchesView: some View {
        LimitedAccessPage(title: "Message", imageName: "DancingCats", description: "View & message your previous matches here", showOnboarding: $showOnboarding, showLogout: $showAlert, onboardingStep: vm?.onboardingStep ?? 0)
    }
}


struct LimitedAccessPage: View {
    
    let title, imageName, description: String
    
    @Binding var showOnboarding: Bool
    @Binding var showLogout: Bool
    let onboardingStep: Int
    
    var body: some View {
        VStack(spacing: 60) {
            Text(title)
                .font(.tabTitle())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 240, height: 240)
            
            
            Text(description)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 32)
                .font(.body(18, .medium))
            
            ActionButton(text: onboardingStep == 0 ? "Create Profile" : "Complete \(onboardingStep)/12") {
                showOnboarding = true
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .overlay(alignment: .topTrailing) {
            if title == "Message" {
                LogOutButton { showLogout = true }
                    .padding(.top, 24)
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

