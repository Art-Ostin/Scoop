//
//  SelectAvailableDayView.swift
//  Scoop
//
//  Created by Art Ostin on 18/03/2026.
//

import SwiftUI

struct SelectAvailableDay: View {
    
    let event: UserEvent
    
    @Binding var selectedDay: Date?
    @Binding var showTimePopup: Bool
    
    private var dates: [Date] {
        event.proposedTimes.availableDates()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            
            VStack(spacing: 10) {
                ForEach(dates.indices, id: \.self) { idx in
                    availableDayRow(idx: idx, date: dates[idx])
                }
                proposeNewDay
            }
        }
        .frame(width: 290)
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
}

extension SelectAvailableDay {
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Invited Times")
                .font(.body(18, .bold))
                .foregroundStyle(Color.black.opacity(0.88))
            
        }
    }
    
    
    private var proposeNewDay: some View {
        VStack {
            HStack {
                Text("Propose a new time")
                    .font(.body(16, .medium))
                    .foregroundStyle(Color.black.opacity(0.88))
                
                Spacer()
                
                Image("EditGray")
            }
        }
        .frame(height: 34)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.92))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.grayBackground, lineWidth: 1)
        }
    }
    
    @ViewBuilder
    private func availableDayRow(idx: Int, date: Date) -> some View {
        let isSelected = selectedDay == date
        
        Button {
            selectDay(date: date)
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    
                    Text(EventFormatting.fullDate(date))
                        .font(.body(16, isSelected ? .bold : .medium))
                        .foregroundStyle(Color.black.opacity(0.88))
                    
                    Text(EventFormatting.hourTime(date))
                        .font(.body(14, .medium))
                        .foregroundStyle(isSelected ? Color.appGreen : Color.grayText)
                }
                Spacer()
//                selectionIndicator(isSelected: isSelected)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.92))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.appGreen.opacity(0.35) : Color.grayBackground, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
    
    private func selectionIndicator(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(isSelected ? Color.appGreen : Color.grayBackground, lineWidth: 1.5)
                .frame(width: 24, height: 24)
            
            if isSelected {
                Circle()
                    .fill(Color.appGreen)
                    .frame(width: 24, height: 24)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white)
            }
        }
    }
    
    private func selectDay(date: Date) {
        selectedDay = date
        
        withAnimation(.easeInOut(duration: 0.25)) {
            showTimePopup = false
        }
    }
}

/*
 Text("OPTION \(idx + 1)")
     .font(.body(11, .bold))
     .kerning(0.9)
     .foregroundStyle(isSelected ? Color.appGreen: Color.grayText)
 */

/*
 //            Text("Choose a day or propose a new time to meet.")
 //                .font(.body(13, .medium))
 //                .foregroundStyle(Color.grayText)

 */
