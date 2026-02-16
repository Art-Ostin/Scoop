//
//  AcceptInviteView.swift
//  Scoop
//
//  Created by Art Ostin on 15/02/2026.
//

import SwiftUI

struct AcceptInviteView: View {
    
    @Binding var showInvite: Bool
    
    
    
    
    var body: some View {
        ZStack {
            CustomScreenCover {showInvite = false }
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 8) {
//                    if let image = profileImage {
//                        Image(uiImage: image)
//                            .resizable()
//                            .scaledToFill()
//                            .frame(width: 25, height: 25)
//                            .clipShape(Circle())
//                    }
                    
                    Text("Arthur")
                        .font(.body(18, .bold))
                    
                    Spacer()
                    
                    Text("🍻  Drink")
                        .font(.body(14, .medium))
                        .offset(x: 6)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Thursday, 14th February · 22:30")
                    Text("Brendy Melville")
                }
                .foregroundStyle(Color(red: 0.32, green: 0.32, blue: 0.32))
                .font(.body(16, .regular))
            }
            .padding(22)
            .padding(.bottom, 8)
            .frame(width: 330, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .foregroundStyle(Color.background)
                    .shadow(color: .accent.opacity(0.15), radius: 4, y: 2)
            )
            .stroke(16, lineWidth: 1, color: Color.grayPlaceholder)
//            .overlay(alignment: .bottomTrailing) {
//                Text("\(vm.user.name) " + (isBlock ? "didn't show" : "cancelled"))
//                    .font(.body(12, .bold))
//                    .foregroundStyle(.accent)
//                    .padding()
//                    .offset(y: 6)
//            }
//            .task {
//                do {
//                    profileImage = try await fetchImage()
//                } catch {
//                    print(error)
//                }
//            }
        }
    }
}

extension AcceptInviteView {
    
    
}



#Preview {
    AcceptInviteView(showInvite: .constant(true))
}

/*
 let eventTime = "\(EventFormatting.expandedDate(acceptedTime)) · \(EventFormatting.hourTime(acceptedTime))"

 */
