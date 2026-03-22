//
//  RespondTimeDropDown.swift
//  Scoop
//
//  Created by Art Ostin on 22/03/2026.
//

import SwiftUI

struct RespondTimeDropDown: View {

    @Binding var selectedDay: Date?
    
    let dates: [Date]
    
    var body: some View {
        
        
        VStack(alignment: .leading, spacing: 16) {
            
            
            
            VStack(spacing: 12) {
                ForEach(dates.indices, id: \.self) {idx in
                    let date = dates[idx]
                    availableDay(idx: idx, date: date)
                }
            }
            
            
        }
        
        
        
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(CardBackground())
        .padding(.horizontal, 24 + 22) //Total adding of content so in middle with card content.
    }
    
    
    @ViewBuilder
    private func availableDay(idx: Int, date: Date) -> some View {
        let isSelected = selectedDay == date
        
        Button {
            selectedDay = date
        } label : {
            VStack(alignment: .leading, spacing: 4) {
                Text("Option \(idx)")
                    .font(.body(14, .medium))
                    .foregroundStyle(isSelected ? Color.appGreen : Color.grayText)
                
                let formattedDate = "\(date.formatted(.dateTime.weekday(.wide))) \(date.formatted(.dateTime.month(.wide).day()))"
                Text(formattedDate)
                    .font(.body(16, .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background ( Color.white)
            .stroke(16, lineWidth: 1, color: isSelected ? Color.appGreen.opacity(0.35) : Color.grayBackground)
        }
    }
}
