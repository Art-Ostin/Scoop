//
//  MeetContainer2.swift
//  ScoopTest
//
//  Created by Art Ostin on 08/08/2025.
//

import SwiftUI

struct MeetContainer: View {
    
    var dep: AppDependencies
    
    @State private var vm: MeetUpViewModel2
    
    @State var showProfiles: Bool
    @State private var selectedProfile: UserProfile?
    
    init(dep: AppDependencies) {
        self.dep = dep
        _vm = .init(initialValue: MeetUpViewModel2(dep: dep))
        self.showProfiles = dep.defaultsManager.getDailyProfileTimerEnd() != nil
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                Text("Meet")
                    .font(.body(32, .bold))
                ZStack {
                    if showProfiles {
                        DailyProfiles(vm: $vm, showProfile: $showProfiles, selectedProfile: $selectedProfile)
                    } else {
                        IntroView2(vm: $vm, showProfiles: $showProfiles)
                    }
                }
            }
            .padding(.top, 36)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            if let profile = selectedProfile {
                ZStack {
                    Color.clear
                        .contentShape(Rectangle())
                        .ignoresSafeArea()
                        .onTapGesture { }
                    ProfileView(profile: profile, dep: dep, onDismiss: { withAnimation(.easeInOut(duration: 0.2)) { selectedProfile = nil } })
                }
                .transition(.asymmetric(insertion: .identity, removal: .move(edge: .bottom)))
                .zIndex(1)
            }
        }

    }
}
