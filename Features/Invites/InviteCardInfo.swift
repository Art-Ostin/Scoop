//
//  InviteCardInfo.swift
//  Scoop
//
//  Created by Art Ostin on 18/03/2026.
//

import SwiftUI

struct InviteCardInfo: View {
    
    let image: UIImage?
    let name: String
    
    let event: UserEvent
    
    var isPopup: Bool {
        image != nil
    }
 
    @Bindable var vm: RespondViewModel
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: isPopup ? 24 : 16) {
            title
            time
            place
                .padding(.bottom, 8)
            responseRow
        }
        .padding(.horizontal, 24)
    }
}

extension InviteCardInfo {
    
    private var responseRow: some View {
        HStack {
            DeclineButton(vm: vm)
            Spacer()
            AcceptButton(vm: vm)
        }
    }
    
    private var title: some View {
        HStack(alignment: .top, spacing: 12) {
            if let image {
                CirclePhoto(image: image)
            }
            
            Text("\(name)'s Invite")
                .font(.body(20, .bold))
            
            
            Spacer()
            
            HStack {
                Text("\(event.type.description.emoji ?? "")  \(event.type.description.label)")
                    .font(.body(17, .medium))
                    .foregroundStyle(Color(red: 0.11, green: 0.11, blue: 0.11))
            }
        }
    }
    
    private var time: some View {
        HStack(spacing: 9) {
            Image("MiniClockIcon")
            
            Text(EventFormatting.fullDateAndTime(event.proposedTimes.dates.first?.date ?? Date()))
                .font(.body(16, .medium))
                .foregroundStyle(Color(red: 0.11, green: 0.11, blue: 0.11))
        }
    }
    
    private var place: some View {
        
        HStack(spacing: 12) {
            Image("MiniMapIcon")
            
            Text(address())
                .font(.body(14, .regular))
                .foregroundStyle(Color(red: 0.11, green: 0.11, blue: 0.11))
                .underline()
                .lineLimit(1)
        }
     }
    
    private func address() -> String {
        String(
            [event.location.name, event.location.address]
                .compactMap { $0 }
                .joined(separator: ", ")
                .prefix(50)
        )
    }
}





