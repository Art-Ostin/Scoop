//
//  IdealMeetupView.swift
//  Scoop Test
//
//  Created by Art Ostin on 20/09/2026.
//

import SwiftUI

struct IdealMeetupView: View {
    
    
    let vm: EditProfileViewModel
    @Binding var path: [EditProfileRoute]

    var body: some View {
        Section {
            VStack {
                Text("Hello World")
                Text("Hello World")
                Text("Hello World")
            }
            .onTapGesture {
                path.append(.idealMeetup)
            }
        } header: {
            Text("Ideal Meetup")
                .padding(.leading, -Spacing.sm) //Geometry: negates the header's row inset so it lines up with the large title
        }
    }
}


/*
 
 
 ForEach(prompts.indices, id: \.self) { i in
     Button { path.append(.prompt(i)) } label: {
         promptResponse(prompt: prompts[i].prompt, response: prompts[i].response)
     }
     .listRowInsets(EdgeInsets(top: 20, leading: Spacing.md, bottom: i == 2 ? 20 : Spacing.xxs, trailing: Spacing.md))
     .buttonStyle(.plain)
     .listRowSeparator(.hidden)
 }

 */
