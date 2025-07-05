//
//  ProfileView.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/06/2025.
//

import SwiftUI


struct ProfileView: View {
    
    @State var vm = ProfileViewModel()
    
    @Binding var state: MeetSections

        
    var body: some View {

        GeometryReader { geo in
            
            let topGap = geo.size.height * 0.07
            
            ZStack {
                Color.background.edgesIgnoringSafeArea(.all)
                
                VStack {
                    heading
                        .padding()

                    imageSection
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .frame(width: geo.size.width, height: 430)
                    
                    imageScrollSection
                }
                .frame(maxHeight: .infinity, alignment: .top)
                
                ProfileDetailsView(vm: vm)
                    .offset(y: vm.startingOffsetY)
                    .offset(y: vm.currentDragOffsetY)
                    .offset(y: vm.endingOffsetY)
                    .frame(width: geo.size.width)
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
                    .frame(width: 300)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            vm.endingOffsetY = (vm.endingOffsetY == 0)
                            ? (topGap - vm.startingOffsetY)
                                : 0
                        }
                    }
                    .gesture (
                        DragGesture()
                            .onChanged { value in
                                withAnimation(.spring()){
                                    vm.currentDragOffsetY = value.translation.height
                                }
                            }
                            .onEnded { value in
                                withAnimation(.spring()) {
                                    if vm.currentDragOffsetY < -50 {
                                        vm.endingOffsetY = (vm.endingOffsetY == 0)
                                        ? (topGap - vm.startingOffsetY)
                                          : 0
                                        
                                    } else if vm.endingOffsetY != 0 && vm.currentDragOffsetY > 100 {
                                        vm.endingOffsetY = 0
                                    }
                                    vm.currentDragOffsetY = 0
                                }
                            }
                    )
                if vm.showInvite {
                    
                    Rectangle()
                        .fill(.regularMaterial)
                        .ignoresSafeArea(.all)
                    
                    SendInviteView(ProfileViewModel: vm, name: "Arthur")
                }
            }
        }
    }
}


#Preview {
    ProfileView(state: .constant(.profile))
        .environment(AppState())
        .offWhite()
}

extension ProfileView {
    
    private var heading: some View {
        HStack {
            Text(vm.profile.name)
                .font(.body(24, .bold))
            ForEach (vm.profile.nationality, id: \.self) {flag in
                Text(flag)
                    .font(.body(24))
            }
            Spacer()
            Image(systemName: "chevron.down")
                .font(.body(20, .bold))
                .onTapGesture {
                    state = .twoDailyProfiles
                }
        }
    }
    
    private var imageSection: some View {
        GeometryReader { geo in
            
            TabView(selection: $vm.imageSelection) {
                ForEach(vm.profile.images.indices, id: \.self) {index in
                    Image(vm.profile.images[index])
                        .frame(height: 380)
                        .overlay(alignment: .bottomTrailing) {
                            InviteButton(vm: vm)
                                .padding(24)
                        }
                        .tag(index)
                }
            }
        }
    }
    
    private var imageScrollSection: some View {
        ScrollViewReader {proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack (spacing: 48) {
                    ForEach(vm.profile.images.indices, id: \.self) {index in
                        ZStack {
                            Image(vm.profile.images[index])
                                .resizable()
                                .scaledToFit( )
                                .frame(width: 60, height: 60)
                                .cornerRadius(16)
                                .shadow(color: vm.imageSelection == index ? Color.black.opacity(0.2) : Color.clear, radius: 4, x: 0, y: 10)
                            if vm.imageSelection == index {
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.accentColor, lineWidth: 1)
                                    .frame(width: 60, height: 60)
                            }
                            
                        }
                        .id(index)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)){
                                vm.imageSelection = index
                            }
                        }
                    }
                }
                .padding()
            }
            .onChange(of: vm.imageSelection) {oldIndex,newIndex in
                if oldIndex < 3 && newIndex == 3 {
                    withAnimation {
                        proxy.scrollTo(newIndex, anchor: .leading)
                    }
                }
                if oldIndex >= 3 && newIndex == 2 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(newIndex, anchor: .trailing)
                    }
                }
            }
        }
    }
    
    private var inviteButton: some View {
        
        Button {
            
        } label: {
            Image("LetterIconProfile")
                .foregroundStyle(.white)
                .frame(width: 53, height: 53)
            
                .background(
                    Circle()
                        .fill(Color.accent.opacity(0.95))
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 5)
                )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}
