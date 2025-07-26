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

        let startingOffsetY: CGFloat = UIScreen.main.bounds.height * 0.78
        var currentDragOffsetY: CGFloat = 0
        var endingOffsetY: CGFloat = 0
        

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
                .offset(y: startingOffsetY)
                .offset(y: currentDragOffsetY)
                .offset(y: endingOffsetY)
                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
                .onTapGesture {
                    withAnimation(.spring()) {
                        endingOffsetY = (endingOffsetY == 0)
                        ? (topGap - startingOffsetY)
                            : 0
                    }
                }
                .gesture (
                    DragGesture()
                        .onChanged { value in
                            withAnimation(.spring()){
                                currentDragOffsetY = value.translation.height
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring()) {
                                if currentDragOffsetY < -50 {
                                    endingOffsetY = (endingOffsetY == 0)
                                    ? (topGap - startingOffsetY)
                                      : 0
                                    
                                } else if endingOffsetY != 0 && currentDragOffsetY > 100 {
                                    endingOffsetY = 0
                                }
                                currentDragOffsetY = 0
                            }
                        }
                )
            }
        }
    }

#Preview {
    ProfileDetailsView(vm: .constant(ProfileViewModel()))
}
