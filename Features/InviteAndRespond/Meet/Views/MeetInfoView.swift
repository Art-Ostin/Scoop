//
//  MeetInformationView.swift
//  Scoop
//
//  Created by Art Ostin on 13/02/2026.
//

import SwiftUI

//To expand when needed
struct MeetInfoView: View {
    
    @Bindable var vm: InviteViewModel
    
    @Bindable var ui: MeetUIState
    
    var body: some View {
        VStack(spacing: 60) {
            newProfileTimer
        }
    }
}

extension MeetInfoView {
    
    private var newProfileTimer: some View {
        HStack(spacing: 0) {
            Text("new profiles in: ")
                .foregroundStyle(Color.grayText)
            SimpleClockView(targetTime: Calendar.current.date(byAdding: .day, value: 3, to: .now)!) {}
        }
        .font(.body(14))
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
}

