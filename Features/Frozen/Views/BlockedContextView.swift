//
//  BlockedContextView.swift
//  Scoop
//
//  Created by Art Ostin on 23/01/2026.
//

import SwiftUI

struct BlockedContextView: View {
    
    //Injected
    let frozenContext: BlockedContext
    let vm: FrozenViewModel
    let isBlock: Bool

    //Local view state
    @State private var profileImage: UIImage?
    
    var body: some View {
        
        VStack(spacing: 6)  {
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 8) {
                    if let image = profileImage {
                        SmallImage(image: image, size: 25, isCircle: true)
                    }
                    
                    Text("\(frozenContext.profileName)")
                        .font(.body(18, .bold))
                    
                    Spacer()
                    
                    Text("\(frozenContext.eventType.title)  \(frozenContext.eventType.emoji)")
                        .font(.body(14, .medium))
                        .offset(x: 6)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text(frozenContext.eventTime)
                    Text(frozenContext.eventPlace)
                }
                .foregroundStyle(Color.textSecondary)
                .font(.body(16, .regular))
            }
            .padding(22)
            .padding(.bottom, 8)
            .frame(width: 330, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .foregroundStyle(Color.appCanvas)
                    .shadow(.button, tint: .accent)
            )
            .stroke(CornerRadius.md)
            .overlay(alignment: .bottomTrailing) {
                Text("\(vm.user.name) " + (isBlock ? "didn't show" : "cancelled"))
                    .font(.body(12, .bold))
                    .foregroundStyle(.accent)
                    .padding()
                    .offset(y: 6)
            }
            .task {
                profileImage = try? await fetchImage() //Optional read: card just omits the avatar on failure
            }
        }
    }
}

extension BlockedContextView {
    func fetchImage() async throws  -> UIImage? {
        guard let url = URL(string: frozenContext.profileImage) else {
            return nil
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return UIImage(data: data)
    }
}
