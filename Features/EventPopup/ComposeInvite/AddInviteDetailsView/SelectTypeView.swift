//
//  SelectTypeView.swift
//  Scoop
//
//  Created by Art Ostin on 24/06/2025.
//

import SwiftUI

struct SelectTypeView: View {

    static let cardWidth: CGFloat = 300
    
    //1. Needed to dismiss menu
    @Environment(\.dropdownCustomMenuDismiss) private var dismissMenu
    @Environment(\.timeCustomMenuDismiss) private var dismissTimeMenu
    @Environment(\.dropdownCustomMenuFreezeLabel) private var freezeMenuLabel

    //2. types with info open given in a binding, as needed to pass up to
    @Binding var openTypes: Set<Event.EventType>
    

    @Binding var selectedType: Event.EventType
    @Binding var showMessageScreen: Bool

    let message: String

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Event.EventType.allCases, id: \.self) {eventType in
                    typeRow(eventType)
            }
        }
        .frame(width: Self.cardWidth, alignment: .leading)
    }
}

extension SelectTypeView {
        
    private func typeRow(_ type: Event.EventType) -> some View {
        VStack(spacing: 0) {
            typeText(type)
            typeInfo(type)
        }
        .padding(.top, 20)
        .overlay(alignment: .topTrailing) { infoButton(type) } // out of flow: its tap region is free (Test)
        .padding(.bottom, (openTypes.contains(type) && type != .custom) ? 0 : 20)
        .padding(.horizontal, Spacing.lg)
        .padding(.top, type == Event.EventType.allCases.first ? Spacing.hairline : 0) //extra padding for the first one
        .shrinkPress {selectType(eventType: type) }
    }
    
    private func typeText(_ type: Event.EventType) -> some View {
        HStack(spacing: Spacing.sm) {
            Text(type.emoji)
                .font(.body(16))
                .frame(width: 25, alignment: .leading) //So all same width
            
            
            Text(type == .socialMeet ? "Social Meet" : type.longTitle)
                .font(.body(17, type == selectedType ? .bold : .medium))
                .kerning(kerningAmount(type)) //Fine tuned kerning so all same width
                .kerning(type == selectedType && type != .custom ? -0.55 : 0)
                .foregroundStyle(type == selectedType ? Color.accent : Color.black)
            
            Spacer(minLength: 4) // reserve trailing space so a long title clears the overlaid icon
        }
    }
            
    private func infoButton(_ type: Event.EventType) -> some View {
        Button {
            withAnimation(.expand) {
                toggleTypeInfo(type)
            }
        } label: {
            SmallInfoIcon(size: 11, colour: Color.black.opacity(0.3))
                .padding(.top, 20)
                .contentShape(Rectangle())
        }
        .shrinkButton()
    }

    private func typeInfo(_ type: Event.EventType) -> some View {
        RevealingInfoText(text: type.howItWorks, isOpen: openTypes.contains(type))
    }
}

//Key Functions
extension SelectTypeView {
    
    //1. Each text different kerning so they're all in line
    private func kerningAmount(_ type: Event.EventType) -> CGFloat {
        switch type {
        case .socialMeet: 1.25
        case .doubleDate: 0.75
        case .drink: 0.8
        case .custom: -0.3
        }
    }

    //2. Logic handling when I select a type
    private func selectType(eventType: Event.EventType) {
        if message.isEmpty {
            selectedType = eventType
            showMessageScreen = true
            Task {
                try? await Task.sleep(for: .seconds(0.04))
                dismissMenu(.instant)
                dismissTimeMenu()
            }
        } else {
            let changed = eventType != selectedType
            if changed {
                freezeMenuLabel()
                selectedType = eventType
            }
            dismissMenu(changed ? .morph : .retract)
            dismissTimeMenu()
        }
    }
    
    //3. Logic to open info of a section
    func toggleTypeInfo(_ type: Event.EventType)  {
        if openTypes.contains(type) {
            openTypes.remove(type)
        } else {
            openTypes.insert(type)
        }
    }
}


/*
 //2. Logic handling when I select a type
 private func selectType(eventType: Event.EventType) {
     if eventType == .custom && message.isEmpty {
         selectedType = .custom
         showMessageScreen = true
         Task {
             try? await Task.sleep(for: .seconds(0.04))
             dismissMenu(.instant)
             dismissTimeMenu()
         }
     } else {
         let changed = eventType != selectedType
         if changed {
             freezeMenuLabel()
             selectedType = eventType
         }
         dismissMenu(changed ? .morph : .retract)
         dismissTimeMenu()
     }
 }

 */
