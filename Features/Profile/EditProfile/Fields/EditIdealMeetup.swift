//
//  EditIdealMeetup.swift
//  Scoop
//
//  Created by Art Ostin on 19/09/2026.
//

import SwiftUI

struct EditIdealMeetup: View {

    @FocusState var isFocused
    
    let vm: EditProfileViewModel
    
    @State var idealMeetupTypes: [String]
    @State var dreamDateText: String?
    @State var selectedDays: [String]
    
    @State private var showIncompleteAlert = false

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
    
    init(vm: EditProfileViewModel) {
        self.vm = vm
        _idealMeetupTypes = .init(wrappedValue: vm.draft.preferredMeetUpType)
        _dreamDateText = .init(wrappedValue: vm.draft.dreamDateNote)
        _selectedDays = .init(wrappedValue: vm.draft.availableDays)
    }
    
    var body: some View {
        content
            .keyboardDoneButton(isFocused: $isFocused, hide: .dismiss)
            .background(Color.appCanvas.ignoresSafeArea())
            .onDisappear { savePreferences() }
            .checkBeforePop(invalid: !idealMeetupTypes.isEmpty && idealMeetupTypes.count < 3, triggerAlert: $showIncompleteAlert)
            .customAlertCard(
                isPresented: $showIncompleteAlert,
                title: "Error",
                message: "Please choose 3 meetup types",
                onOK: { showIncompleteAlert.toggle() }
            )
    }
}


// MARK: - The column
extension EditIdealMeetup {

    private static let chipsReturnLag: TimeInterval = 0.15

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
                        .transition(.asymmetric(
                            insertion: .blurPop().animation(.transition.delay(Self.chipsReturnLag)),
                            removal: .blurPop()))
                }
                addDreamMeet
            }
            
            if !isFocused {
                inputtedDays
                    .padding(.top, 12)
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
                        OptionCell(text: option,  maxCount: 3, isCapsule: true, selection: $idealMeetupTypes)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var addDreamMeet: some View {
        PromptInput(text: Binding(unwrapping: $dreamDateText), isFocused: $isFocused, isPrompt: false)
    }
    
    private var inputtedDays: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Your Preferred Days To Meet")
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
    
    private func savePreferences() {
        if idealMeetupTypes != vm.draft.preferredMeetUpType {
            vm.set(.preferredMeetUpType, \.preferredMeetUpType, to: idealMeetupTypes)
        }
        if dreamDateText != vm.draft.dreamDateNote {
            vm.set(.dreamDateNote, \.dreamDateNote, to: dreamDateText)
        }
        if selectedDays != vm.draft.availableDays {
            vm.set(.availableDays, \.availableDays, to: selectedDays)
        }
    }
}
