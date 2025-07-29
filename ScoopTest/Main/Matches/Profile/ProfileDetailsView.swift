//
//  profileDetailsView.swift
//  ScoopTest
//
//  Created by Art Ostin on 23/06/2025.
//

import SwiftUI

struct profileDetailsView: View {
    
    @Binding var vm: ProfileViewModel
    
    var body: some View {

        
        ScrollView {
            
            VStack {
                
                Text(vm.p.nationality)
                
                Text (vm.p.hometown)
                
                Text(vm.p.lookingFor)
                
                Text(vm.p.year)
                
                Text(vm.p.degree)
                
                Text(vm.p.degree)
                
                Text(vm.p.height)
                
                Text(vm.p.interests)
                
                Text(vm.p.attractedTo)
                
                Text(vm.p.drinking)
                
                Text(vm.p.marijuana)
                
                Text(vm.p.smoking)
                
                Text(vm.p.drugs)
                
                Text(vm.p.favouriteBook)
                
                Text(vm.p.favouriteMovie)
                
                Text(vm.p.favouriteSong)
                
                Text (vm.p.languages)
            }
            
            
            
            
            
            
        }
        
        
        
        
    }
}




///vm.pREVIOUS vm.pERSONAL DETAILS VIEW. USE IF NEEDED.
/*
 struct vm.profileDetailsView: View {
     
     @Binding var vm: vm.profileViewModel
     
     
     var body: some View {
         
         let startingOffsetY: CGFloat = UIScreen.main.bounds.height * 0.78
         var currentDragOffsetY: CGFloat = 0
         var endingOffsetY: CGFloat = 0
         
         
         GeometryReader { geo in
             
             let tovm.pGavm.p = geo.size.height * 0.07
             
             ZStack {
                 
                 VStack{
                     
                     vm.profileDetailsViewInfo(vm: $vm)
                     
                     TabView {
                         vm.promvm.ptResvm.ponseView(vm: vm, inviteButton: true)
                             .frame(maxHeight: .infinity, alignment: .tovm.p)
                         
                         vm.promvm.ptResvm.ponseView(vm: vm, inviteButton: true)
                             .frame(maxHeight: .infinity, alignment: .tovm.p)
                         
                     }
                     .vm.padding(.tovm.p)
                     .tabViewStyle(vm.pageTabViewStyle(indexDisvm.playMode: .automatic))
                     .frame(width: geo.size.width, alignment: .center)
                     
                 }
                 .background(Color.background)
                 .cornerRadius(30)
                 .font(.body(17))
             }
             .offset(y: startingOffsetY)
             .offset(y: currentDragOffsetY)
             .offset(y: endingOffsetY)
             .shadow(color: .black.ovm.pacity(0.25), radius: 4, x: 0, y: 4)
             .onTavm.pGesture {
                 withAnimation(.svm.pring()) {
                     endingOffsetY = (endingOffsetY == 0)
                     ? (tovm.pGavm.p - startingOffsetY)
                     : 0
                 }
             }
             .gesture (
                 DragGesture()
                     .onChanged { value in
                         withAnimation(.svm.pring()){
                             currentDragOffsetY = value.translation.height
                         }
                     }
                     .onEnded { value in
                         withAnimation(.svm.pring()) {
                             if currentDragOffsetY < -50 {
                                 endingOffsetY = (endingOffsetY == 0)
                                 ? (tovm.pGavm.p - startingOffsetY)
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
 */
