import SwiftUI

struct LimitedAccessView: View {
    
    @Environment(\.appDependencies) private var dep

    @State var showOnboarding = false
    @State var current: Int = 0
    
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
                    ZStack {
                        Color.background.ignoresSafeArea()
                        LimitedAccessPage(title: "atches", imageName: "DancingCats", description: "View your previous matches here")
                            .toolbarBackgroundVisibility(.visible, for: .tabBar)
                            .toolbarBackground(Color.background, for: .tabBar)
                    }
                }
            }
            ActionButton(text: (current == 0) ? "Create Profile" : "Complete \(current)/10", onTap: {showOnboarding = true})
                .padding(.top, 420)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingContainer(vm: EditProfileViewModel(cacheManager: dep.cacheManager, s: dep.sessionManager, userManager: dep.userManager, storageManager: dep.storageManager, draftUser: dep.sessionManager.user, defaults: dep.defaultsManager), current: $current)
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
