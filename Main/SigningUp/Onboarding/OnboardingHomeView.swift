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
                limitedAccessView(page: .meet)
                    .tag(TabBarItem.meet)
                    .tabItem { Label("", image: tabSelection == .meet ? "BlackLogo" : "AppLogoBlack")}
                limitedAccessView(page: .meeting)
                    .tag(TabBarItem.events)
                    .tabItem {Label("", image: tabSelection == .events ? "EventBlack" : "EventIcon")}
                
                limitedAccessView(page: .message)
                    .tag(TabBarItem.matches)
                    .tabItem {Label("", image: tabSelection == .matches ? "BlackMessage" : "MessageIcon")}
            }} else {
                CustomTabBarContainerView(selection: $tabSelection) {
                    limitedAccessView(page: .meet)
                        .tabBarItem(.meet, selection: $tabSelection)
                    limitedAccessView(page: .meeting)
                        .tabBarItem(.events, selection: $tabSelection)
                    limitedAccessView(page: .message)
                        .tabBarItem(.events, selection: $tabSelection)
                }
            }
        }
        .task {
            if vm == nil {
                await MainActor.run {
                    vm = OnboardingViewModel(
                        authService: dep.authService,
                        defaultManager: dep.defaultsManager,
                        sessionManager: dep.sessionManager,
                        userRepo: dep.userRepo,
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
            Button("Cancel", role: .cancel){}
            Button("Sign Out") {
                appState.wrappedValue = .login
                Task {try? await vm?.signOut()}
            }
        } message: {
            vm?.onboardingStep == 0 ?
            Text("Are you sure you want to sign Out?") :
            Text("Are you sure you want to sign Out? Your Progress will be lost.")
        }
    }
}

extension OnboardingHomeView {
    private func limitedAccessView(page: OnboardingPage) -> some View {
        LimitedAccessPage(page: page, showOnboarding: $showOnboarding, showLogout: $showAlert, onboardingStep: vm?.onboardingStep ?? 0)
    }
}
