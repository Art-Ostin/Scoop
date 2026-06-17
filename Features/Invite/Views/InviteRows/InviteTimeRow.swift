//
//  InviteTimeRow.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI


struct InviteTimeRow: View {

    @Binding var showTimePopup: Bool
    @Binding var proposedTimes: ProposedTimes

    let type: Event.EventType
    
    var times: [Date] {
        proposedTimes.dates.map(\.date)
    }
    
    var hour: String {
        times.first?.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)) ?? ""
    }
    
    var body: some View {
        
        //Shows two different views if there is more than one time proposed
        Group {
            if times.count <= 1 {
                singleTimeOrLessRow
            } else {
                multipleTimeView
            }
        }
        //1. Adaptive padding based of content
        .padding(.top, timeVerticalTopPadding)
        .padding(.bottom, timeVerticalBottomPadding)
        
    }
}

//If less than 2 proposed times
extension InviteTimeRow {
    
    private var singleTimeOrLessRow: some View {
        HStack {
            inviteTypeText(.when)
            Spacer()
            selectTimeButton
        }
    }
    
    private var selectTimeButton: some View {
        CustomMenu {
            SelectTimeView(proposedTimes: $proposedTimes, type: type, showTimePopup: $showTimePopup)
                .zIndex(2)
        } label: {
            selectTimeLabel
        }
    }
    
    @ViewBuilder
    private var selectTimeLabel: some View {
        HStack(spacing: 12) {
            if let proposedDay = times.first {
               Text( FormatEvent.dayAndTime(proposedDay, wide: true, withHour: true))
                    .font(.body(17, .medium))
            } else {
                Text("Choose Time")
                    .kerning(0.32)
                    .font(.body(16, .regular))
                    .foregroundStyle(Color(white: 0.4))
            }
            Image("InviteChevron")
        }
    }
    
}

extension InviteTimeRow {
    
    private var multipleTimeView: some View {
        
        HStack(spacing: 12) {
            VStack(spacing: 8){
                multipleTimeTitleAndHour
                ForEach(times.indices, id: \.self) {idx in
                    let time = times[idx]
                    multipleTimeRow(idx: idx, time: time)
                }
            }
        }
    }
    
    private var customMenu: some View {
        
        CustomMenu(
            placementOffsetY: CustomMenuSpec.placementOffsetY + Self.chevronTapInsetY
        ) {
            SelectTimeView(proposedTimes: $proposedTimes, type: type, showTimePopup: $showTimePopup)
                .zIndex(2)
        } label: {
            Image("InviteChevron")
                .frame(width: Self.chevronTapTarget, height: Self.chevronTapTarget)//Expands hit area
        }
        .frame(width: Self.chevronArtSize.width, height: Self.chevronArtSize.height)//Expands hit area
    }
    
    
    
    
    @ViewBuilder
    private var multipleTimeTitleAndHour: some View {
        HStack {
            Text("When")
                .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.65))
                .font(.body(12, .bold))
            
            Spacer()
            
            if let firstDay = times.first {
                Text(FormatEvent.hourTime(firstDay))
                    .font(.body(13, .bold))
            }
        }
    }
    
    private func multipleTimeRow(idx: Int, time: Date) -> some View {
        HStack {
            Text("Option \(idx + 1)")
                .kerning(0.24)
                .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.65))
                .font(.body(12, .regular))
            Spacer()
            Text(FormatEvent.dayAndTime(time, withHour: false))
                .font(.body(15, .regular))
        }
    }
}






extension InviteTimeRow {
    //Padding adjusted pased of view
    private var timeVerticalTopPadding: CGFloat {
        if times.count <= 1 {
            return 28
        } else if times.count == 2 {
            return 20
        } else {
            return 16
        }
    }

    private var timeVerticalBottomPadding: CGFloat {
        if times.count <= 1 {
            return 28
        } else if times.count == 2 {
            return 18
        } else  {
            return 14
        }
    }
}

// MARK: - Multiple-times chevron tap target
extension InviteTimeRow {
    /// Side of the enlarged chevron hit region (Apple HIG minimum touch target).
    fileprivate static let chevronTapTarget: CGFloat = 44
    /// `InviteChevron.pdf` intrinsic size (asset MediaBox: 7.22 × 11.99pt). The
    /// 44×44 tap target overflows a frame of this size so the row layout is
    /// unchanged — update if the chevron art is ever re-exported.
    fileprivate static let chevronArtSize = CGSize(width: 7.22, height: 11.99)
    /// Half the vertical growth from the 44pt target, re-applied to the menu
    /// placement so the popup opens where it did with the small chevron anchor.
    fileprivate static let chevronTapInsetY: CGFloat = (chevronTapTarget - chevronArtSize.height) / 2
}
