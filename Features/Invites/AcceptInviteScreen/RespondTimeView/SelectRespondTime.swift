//
//  RespondTimeDropDown.swift
//  Scoop
//
//  Created by Art Ostin on 22/03/2026.
//

import SwiftUI

struct SelectRespondTime: View {

    @Binding var selectedDay: Date?
    @Binding var showTimePopup: Bool
    
    let dates: [Date]
    
    @State var showCustomTime: Bool = false
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 16) {
            timeDropDownTitle

            VStack(spacing: 12) {
                ForEach(dates.indices, id: \.self) {idx in
                    let date = dates[idx]
                    availableDay(idx: idx, date: date)
                }
            }
        }
        .frame(width: 290, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.background)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.grayBackground, lineWidth: 1)
                }
        )
    }
    
    
    @ViewBuilder
    private func availableDay(idx: Int, date: Date) -> some View {
        let isSelected = selectedDay == date
        
        Button {
            selectedDay = date
            withAnimation(.easeInOut(duration: 0.25)) {
                showTimePopup = false
            }
        } label : {
            VStack(alignment: .leading, spacing: 4) {
                Text("Option \(idx + 1)")
                    .font(.body(14, .medium))
                    .foregroundStyle(isSelected ? Color.appGreen : Color.grayText)
                
                let formattedDate = "\(date.formatted(.dateTime.weekday(.wide))) \(date.formatted(.dateTime.month(.wide).day()))"
                Text(formattedDate)
                    .font(.body(16, .medium))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background ( Color.white)
            .stroke(16, lineWidth: 1, color: isSelected ? Color.appGreen.opacity(0.35) : Color.grayBackground)
        }
        .buttonStyle(.plain)
    }
}

extension SelectRespondTime {
    
    private var timeDropDownTitle: some View {
        HStack {
            Text("Invited Days")
                .font(.custom("SFProRounded-Semibold", size: 16))
            Spacer()
            
            Button {
                showCustomTime = true
            } label: {
                Text("Can't make it?")
                    .font(.body(12, .bold))
                    .foregroundStyle((Color(red: 0.45, green: 0.45, blue: 0.45)))
                    .kerning(0.5)
            }
        }
    }
}
