//
//  TwoDailyProfilesView.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/06/2025.
//

import SwiftUI

struct DailyProfiles: View {
        
    @Binding var vm: MeetUpViewModel?
    
    private var selectionBinding: Binding<Int> {
        Binding(get: { vm?.selection ?? 0 }, set: { vm?.selection = $0 })
    }
    
    @State var countdownVM = CountdownViewModel(dateKey: "dailyProfilesDate")
    
    var body: some View {
        
        VStack(spacing: 36) {
            
            Text("\(countdownVM.hourRemaining):\(countdownVM.minuteRemaining):\(countdownVM.secondRemaining)")
            
            MeetTitle()
            heading
            TabView(selection: selectionBinding) {
                profileTab(for: vm?.profile1, tag: 0)
                profileTab(for: vm?.profile2, tag: 1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .padding(.horizontal, 32)
        .frame(maxHeight: .infinity, alignment: .top)
        .onChange(of: countdownVM.secondRemaining) {
            if countdownVM.hourRemaining == "00" &&
                countdownVM.minuteRemaining == "00" &&
                countdownVM.secondRemaining == "00" {
                Task {
                    await vm?.refresh()
                    await MainActor.run {
                        countdownVM.updateTimeRemaining()
                    }
                }
            }
        }
        
        .overlay(
            Image("NightImages")
                .padding(.bottom, 72),
            alignment: .bottom
            )
    }
}

extension DailyProfiles {
    
    private var heading: some View {
        
        VStack (spacing: 6){
            
            HStack{
                Text(vm?.profile1?.name ?? "")
                    .font(.title(16, vm?.selection == 0 ? .bold : .medium))
                    .foregroundStyle(vm?.selection == 0 ? Color.accent : Color.black)
                
                Spacer()
                
                Text(vm?.profile2?.name ?? "")
                    .font(.title(16, vm?.selection == 1 ? .bold : .medium))
                    .foregroundStyle(vm?.selection == 1 ? Color.accent : Color.black)
            }
            .padding(.horizontal, 2)
            HStack {
                if vm?.selection == 1 {
                    Spacer()
                }
                Rectangle()
                    .frame(width: vm?.selection == 0 ? 53 : 43, height: 1.6)
                    .foregroundStyle(Color.accentColor)
                if vm?.selection == 0 {
                    Spacer()
                }
            }
        }
    }
    
    @ViewBuilder private func profileTab(for profile: UserProfile?, tag: Int) -> some View {
        if let url = firstImageURL(for: profile) {
            profileImage(url: url)
                .tag(tag)
                .onTapGesture {
                    if tag == 0 {
                        if let profile = self.vm?.profile1 { self.vm?.state = .profile(profile) }
                    }
                    if tag == 1 {
                        if let profile = self.vm?.profile2 { self.vm?.state = .profile(profile) }
                    }
                }
        }
    }
    
    private func profileImage(url: URL) -> some View {
        CachedAsyncImage(url: url) { image in
            image
                .resizable()
                .scaledToFill()
                .frame(width: 320, height: 422)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 5)
        } placeholder: {
            ProgressView()
        }
    }
    
    private func firstImageURL(for profile: UserProfile?) -> URL? {
        profile?.imagePathURL?.first.flatMap(URL.init(string:))
    }
}

struct MeetTitle: View {
    var body: some View {
        HStack {
            Text("Meet")
                .font(.title())
            Spacer()
            Image(systemName: "magnifyingglass")
                .resizable()
                .frame(width: 20, height: 20)
        }
        .padding(.top, 48)
    }
}
