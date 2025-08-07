//
//  ProfileImageScrollView.swift
//  ScoopTest
//
//  Created by Art Ostin on 25/06/2025.

//import SwiftUI
//
//struct ProfileImageScroller: View {
//    
//    @Binding var vm: ProfileViewModel
//    
//    
//    
//    
//    var body: some View {
//        
//        ScrollViewReader { proxy in
//            ScrollView (.horizontal, showsIndicators: false) {
//                HStack (spacing: 48) {
//                                        
//                    
//                    ForEach(imageUrls.indices, id: \.self) {index in
//                        
//                        let url = imageUrls[index]
//                        if let url = URL(string: url) {
//                            CachedAsyncImage(url: url) { image in
//                                image.resizable()
//                                    .scaledToFill()
//                                    .frame(width: 60, height: 60)
//                                    .clipShape(RoundedRectangle(cornerRadius: 16))
//                                    .overlay {
//                                        RoundedRectangle(cornerRadius: 16)
//                                            .stroke(Color.accentColor, lineWidth: vm.imageSelection == index ? 1 : 0)
//                                    }
//                            }
//                            .id(index)
//                            .shadow(color: vm.imageSelection == index ? Color.black.opacity(0.2) : Color.clear, radius: 4, x: 0, y: 10)
//                            .onTapGesture {
//                                withAnimation(.easeInOut(duration: 0.2)){vm.imageSelection = index}
//                            }
//                        }
//                    }
//                }
//                .padding()
//            }
//            .onChange(of: vm.imageSelection) {oldIndex, newIndex in
//                if oldIndex < 3 && newIndex == 3 {
//                    withAnimation { proxy.scrollTo(newIndex, anchor: .leading) }
//                }
//                if oldIndex >= 3 && newIndex == 2 {
//                    withAnimation(.easeInOut(duration: 0.3)) { proxy.scrollTo(newIndex, anchor: .trailing)}
//                }
//            }
//        }
//    }
//}

//#Preview {
//    ProfileImageScroller(vm: .constant(ProfileViewModel(profile: CurrentUserStore.shared.user!)))
//}
//
