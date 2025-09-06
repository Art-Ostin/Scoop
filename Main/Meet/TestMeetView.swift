//
//  NewMeetView.swift
//  Scoop
//
//  Created by Art Ostin on 02/09/2025.
//

/*
 import SwiftUI

 struct MeetHeaderOffsetKey: PreferenceKey {
     static let defaultValue: CGFloat = 34
     static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue()}
 }

 struct NewMeetView: View {
     
     @State var vm: MeetViewModel
     @State var scrollViewOffset: CGFloat = 0
     @State var selectedProfile: ProfileModel?

     init(vm: MeetViewModel) { _vm = State(initialValue: vm) }

     @State var title = "Hello World"
     
     var body: some View {
         ScrollView {
             VStack {
                 
                 VStack(spacing: 0) {
                     GeometryReader { geo in
                         Color.clear
                             .preference(key: MeetHeaderOffsetKey.self,
                                         value: geo.frame(in: .global).minY)
                             .id(vm.profiles.count)
                     }
                     tabTitle
                 }
                 
                 Text(vm.profiles.first?.profile.email ?? "No Name")
                 
                 profileScroller
             }
         }
         .onPreferenceChange(MeetHeaderOffsetKey.self) { scrollViewOffset = $0 }
         .overlay(Text(String(format: "%.1f", scrollViewOffset)))
         .padding()
         .onAppear {
             print(vm.profiles)
         }
     }
 }

 extension NewMeetView {
     
     
     private var tabTitle: some View {
         Text(title)
             .font(.tabTitle())
             .frame(maxWidth: .infinity, alignment: .leading)
             .padding(.horizontal, 32)
     }
     
     
     private var profileScroller: some View {
         VStack {
             ForEach(vm.profiles) { profileInvite in
                 Text(profileInvite.profile.name)
                 ProfileCard(vm: vm, profile: profileInvite, selectedProfile: $selectedProfile)
         }
         }
     }
 }

 */
