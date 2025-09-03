//
//  NewMeetView.swift
//  Scoop
//
//  Created by Art Ostin on 02/09/2025.
//

import SwiftUI

struct NewMeetView: View {
    
    @State var vm: MeetViewModel
    @State var scrollViewOffset: CGFloat = 0
    @State var selectedProfile: ProfileModel?

    init(vm: MeetViewModel) { _vm = State(initialValue: vm) }

    @State var title = "Hello World"
    
    var body: some View {
        ScrollView {
            VStack {
                tabTitle
                    .background (
                        GeometryReader { proxy  in
                            Color.clear
                                .preference(key: MeetHeaderOffsetKey.self, value: proxy.frame(in: .global).minY)
                        })
                profileScroller
            }
        }
        .onPreferenceChange(MeetHeaderOffsetKey.self) { scrollViewOffset = $0 }
        .overlay(
            Text("\(scrollViewOffset)")
        )
        .padding()
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
            ForEach(vm.profiles) { profileInvite in
                ProfileCard(vm: vm, profile: profileInvite, selectedProfile: $selectedProfile)
        }
    }
}

struct MeetHeaderOffsetKey: PreferenceKey {
    
    static let defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
