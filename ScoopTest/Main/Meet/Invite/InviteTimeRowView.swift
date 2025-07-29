//
//  InviteTimeRowView.swift
//  ScoopTest
//
//  Created by Art Ostin on 25/06/2025.
//

import SwiftUI

struct InviteTimeRowView: View {
    
    
    @Binding var showTimePopup: Bool
    
    @Binding var selectedTime: Date?

    
    var body: some View {
        
        let formattedTime: String = {
            
            guard let date = selectedTime else {return "Time"}
            let formatter = DateFormatter()
            formatter.dateFormat = "E, MMM d – h:mm a"
            
            return formatter.string(from: date)
        }()
        
        var font: Font {
            if selectedTime == nil {
                return .body(20, .bold)
            } else {
                return .body(18)
            }
        }
        
        HStack {
            Text(selectedTime == nil ? "Time" : formattedTime)
                .font(font)
            Spacer()
            Image("InviteTime")
                .onTapGesture {
                    showTimePopup.toggle()
                }
                
        }
        
        
    }
}

#Preview {
    InviteTimeRowView(showTimePopup: .constant(false), selectedTime: .constant(nil))
        .padding()
}
