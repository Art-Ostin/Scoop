//
//  TwoDailyProfilesView.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/06/2025.
//

import SwiftUI

struct TwoDailyProfilesView: View {
        
    @Binding var vm: MeetUpViewModel?
    
    private var selectionBinding: Binding<Int> {
        Binding(get: { vm?.selection ?? 0 }, set: { vm?.selection = $0 })
    }
    
    var body: some View {
        
        VStack(spacing: 36) {
            title
            heading
            TabView(selection: selectionBinding) {
                profileImageTab(url: firstImageURL(for: vm?.profile1))
                    .tag(0)
                    .onTapGesture {
                        vm?.state = .profile1
                    }
                
                profileImageTab(url: firstImageURL(for: vm?.profile2))
                    .tag(1)
                    .onTapGesture {
                        vm?.state = .profile2
                    }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .padding(.horizontal, 32)
        .frame(maxHeight: .infinity, alignment: .top)
        .overlay(
            Image("NightImages")
                .padding(.bottom, 72),
            alignment: .bottom
            )
    }
}

extension TwoDailyProfilesView {
    
    private var title: some View {
        HStack{
            Text("Meet")
                .font(.title())
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .resizable()
                .frame(width: 20, height: 20)
        }
        .padding(.top, 48)
    }
    
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
    
    @ViewBuilder private func profileImageTab(url: URL?) -> some View {
        if let url = url {
            CachedAsyncImage(url: url) { Image in
                Image
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
    }
    
    private func firstImageURL(for profile: UserProfile?) -> URL? {
        profile?.imagePathURL?.first.flatMap(URL.init(string:))
    }
}
