//
//  EventSlot.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/08/2025.
//

import SwiftUI

struct EventSlot: View {

    let vm: EventViewModel
    @Binding var selectedProfile: ProfileModel?
    @State var profileModel: ProfileModel
    @State var imageSize: CGFloat = 0
    @State var showMessageScreen: Bool = false
    
    
    var body: some View {
        Group {
            if let event = profileModel.event {
                ScrollView {
                    VStack(spacing: 48) {
                        Text("You're Meeting \(profileModel.profile.name)!")
                            .font(.title(28, .medium))
                        
                        if let image = profileModel.image {
                            Image(uiImage: image)
                                .resizable()
                                .defaultImage(imageSize)
                                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 4)
                        }
                        
                        // VStack {
                        //     FormatTimeAndPlace(time: profileModel.event, place: <#T##EventLocation#>)
                        // }
                        
                    }
                }
                .measure(key: ImageSizeKey.self) { $0.size.width }
                .onPreferenceChange(ImageSizeKey.self) { screenWidth in
                    imageSize = screenWidth - 32 //Adds 16 padding on each side
                }
                .fullScreenCover(isPresented: $showMessageScreen) {
                    Text("Message Screen here")
                    Button("Close") { showMessageScreen = false}
                }

                VStack(spacing: 60) {
                    Text("You're Meeting \(profileModel.profile.name)!")
                        .font(.title(28, .medium))
                        
                        
//                imageContainer(image: profileModel.image, size: 300)
//                    .onTapGesture {
//                        selectedProfile = profileModel
//                    }

                    VStack(spacing: 48) {
                        EventFormatter(time: event.time, type: event.type, message: event.message, isInvite: false, place: event.place)
                            .padding(.horizontal, 32)
                        
                        LargeClockView(targetTime: event.time) {}
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                EmptyView()
            }
        }
    }
}
extension EventSlot {
    
    private var messageButton: some View {
        
        Button {
            
        } label: {
            Image("ChatIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .font(.body(17, .bold))
                .padding()
                .background (
                    Circle()
                        .foregroundStyle(Color.background)
                        .stroke(100, lineWidth: 1.5, color: .black)
                )
                .defaultShadow()
        }
    }
}
