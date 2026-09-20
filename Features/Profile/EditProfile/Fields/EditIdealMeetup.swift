//
//  EditIdealMeetup.swift
//  Scoop
//
//  Created by Art Ostin on 19/09/2026.
//

import SwiftUI

struct EditIdealMeetup: View {

    @State var dreamDateText: String = ""
    
    @FocusState var isFocused
    
    
    //Local view state
    @State private var selected: [String] = []
    
    @State private var selectedDays: [String] = []

    private let rows: [[String]] = [
        ["Drinks", "Coffee", "Brunch", "Lunch"],
        ["Live Music", "Double Date", "Base Jumping"],
        ["Dinner", "Rave", "A Walk", "Pastries"],
        ["A Movie", "Thrifting", "Park", "Ice Cream"]
    ]
    
    private let days: [String] = [
        "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"
    ]
    
    private let timeOfDay: [String] = [
        "Lunch", "Afternoon", "Evening", "Night"
    ]

    var body: some View {
        content
            .keyboardDoneButton(isFocused: $isFocused, hide: .dismiss)
            .background(Color.appCanvas.ignoresSafeArea())
    }
}


// MARK: - The column
extension EditIdealMeetup {

    //The chips wait out the field's return before they fade back in: the space they take reopens on the
    //keyboard's clock, they arrive into it a beat behind. Going, they leave with everything else
    private static let chipsReturnLag: TimeInterval = 0.15

    //Everything the keyboard must not shove: it holds still and lifts the one fixed amount instead
    private var content: some View {
        VStack(spacing: isFocused ? Spacing.lg : Spacing.xl) { //24 focused, 36 at rest: the field comes up to the title, the title never moves
            VStack(alignment: .leading, spacing: 8) {
                SignUpTitle(text: "Ideal Meetup")
                Text("Choose 3")
                    .blurPop(visible: !isFocused, scale: 1)
                    .customCaption()
            }

            VStack(spacing: 24) {
                if !isFocused {
                    defaultOptions
                        //The delay belongs ON the transition — `AnyTransition.blurPop` has no curve of its
                        //own, so an outer `.animation(_:value:)` would time the whole column, not the chips
                        .transition(.asymmetric(
                            insertion: .blurPop().animation(.transition.delay(Self.chipsReturnLag)),
                            removal: .blurPop()))
                }
                addDreamMeet
            }
            
            if !isFocused {
                inputtedDays
                    .padding(.top, 12)
                    //The transition form, not the modifier: nothing sits below these, so holding a slot
                    //while hidden only makes the column report a height it is not drawing. It also puts
                    //them on the same lever as the chips — a transition takes a `.delay()`, a `blurPop`
                    //modifier carries its own curve and cannot
                    .transition(.asymmetric(
                        insertion: .blurPop().animation(.transition.delay(Self.chipsReturnLag)),
                        removal: .blurPop()))
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 84)
        .animation(.keyboard, value: isFocused) //one transaction: the gap, the chips and the caption all leave on it
    }

    private var defaultOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 18) {      // one row of chips
                    ForEach(row, id: \.self) { option in
                        OptionCell(text: option,  maxCount: 3, isCapsule: true, selection: $selected)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var addDreamMeet: some View {
        PromptInput(text: $dreamDateText, isFocused: $isFocused, isPrompt: false)
    }
    
    private var inputtedDays: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Preferred Days")
                .font(.title(18, .medium))
            
            HStack(spacing: 0) {      // spacing 0: the Spacers carry the gap, so the ends stay on the margin
                ForEach(days, id: \.self) { day in
                    OptionCell(text: day, maxCount: 4, isCapsule: true, selection: $selectedDays, isCircle: true)

                    if day != days.last {
                        Spacer(minLength: Spacing.xxs)
                    }
                }
            }
        }
    }
    
    private var preferredTimeOfDay: some View {
        HStack(spacing: 0) {      // spacing 0: an HStack gap lands on BOTH sides of a Spacer
            ForEach(timeOfDay, id: \.self) { day in
                OptionCell(text: day, maxCount: 100, isCapsule: true, selection: $selectedDays)

                if day != timeOfDay.last {
                    Spacer(minLength: Spacing.xxs)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    EditIdealMeetup()
}
