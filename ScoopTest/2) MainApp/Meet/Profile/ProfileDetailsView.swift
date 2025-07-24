//
//  ProfileDetailsView.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/06/2025.
//

import SwiftUI

struct ProfileDetailsView: View {
    
    @Binding var vm: ProfileViewModel
            
    
    var body: some View {
    
            GeometryReader { geo in
                
                let topGap = geo.size.height * 0.07

                ZStack {
                    VStack{
                    
                        ProfileDetailsViewInfo(vm: $vm)
                        
                        TabView {
                            PromptResponseView(vm: vm, inviteButton: true)
                                    .frame(maxHeight: .infinity, alignment: .top)
                                    
                            PromptResponseView(vm: vm, inviteButton: true)
                                .frame(maxHeight: .infinity, alignment: .top)
                            
                        }
                        .padding(.top)
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                        .frame(width: geo.size.width, alignment: .center)
                        
                    }
                    .background(Color.background)
                    .cornerRadius(30)
                    .font(.body(17))
                }
                .offset(y: vm.startingOffsetY)
                .offset(y: vm.currentDragOffsetY)
                .offset(y: vm.endingOffsetY)
                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
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
            }
        }
    }

#Preview {
    ProfileDetailsView(vm: .constant(ProfileViewModel()))
}
