//
//  MeetSuggestionView.swift
//  Scoop
//
//  Created by Art Ostin on 25/10/2025.
//

import SwiftUI

struct MeetSuggestionView: View {
    
    
    
    var body: some View {
        VStack {
            
            Text("My Meet suggestion")
                .font(.body(12, .medium))
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
            
            VStack{
                EventFormatter(time: <#T##Date#>, type: <#T##String#>, message: <#T##String?#>, isInvite: <#T##Bool#>, place: <#T##EventLocation#>, size: <#T##CGFloat#>, isProfile: <#T##Bool#>)
                
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            
            
            
        }
    }
}

#Preview {
    MeetSuggestionView()
}
