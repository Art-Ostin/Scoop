//
//  IntroView2.swift
//  ScoopTest
//
//  Created by Art Ostin on 14/08/2025.
//

import SwiftUI

struct IntroView: View {
    @Bindable var timeVm: InviteViewModel
    @Bindable var vm: MeetViewModel
    @State var showIdealTime: Bool = false
    
    
    
    let quote = quotes.shared.allQuotes.randomElement()!
    var body: some View {
        ZStack {
            VStack(spacing: 72) {
                VStack(spacing: 36) {
                    Text(quote.quoteText)
                        .font(.body(.italic))
                        .lineSpacing(8)
                        .multilineTextAlignment(.center)
                    
                    Text("- \(quote.name)")
                        .font(.body(14, .bold))
                }
                ActionButton(text: "View Profiles") {
                    showIdealTime.toggle()
                }
            }
            
            if showIdealTime {
                Rectangle()
                    .fill(.thinMaterial)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { showIdealTime = false }
                SendInvitePopup(vm: InviteViewModel(eventManager: vm.eventManager, cycleManager: vm.cycleManager, profileModel: vm.profileModel, sessionManager: vm.sessionManager, userManager: vm.userManager)) {
            }
        }
    }
}
