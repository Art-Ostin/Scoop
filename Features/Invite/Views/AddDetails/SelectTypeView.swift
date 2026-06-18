//
//  SelectTypeView.swift
//  ScoopTest
//
//  Created by Art Ostin on 24/06/2025.
//

import SwiftUI

struct SelectTypeView: View {
    
    //1. Needed to sharply display a divider under 1 CGFloat
    @Environment(\.displayScale) private var displayScale

    //2. Needed to dismiss menu
    @Environment(\.customMenuDismiss) private var dismissMenu
    
    //3. types with info open given in a binding, as needed to pass up to
    @Binding var openTypes: Set<Event.EventType>
    

    @Binding var selectedType: Event.EventType
    @Binding var showMessageScreen: Bool
    @Binding var showTypePopup: Bool
    
    let message: String
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Event.EventType.allCases, id: \.self) {eventType in
                    typeRow(eventType)
                    
                    if eventType != Event.EventType.allCases.last {
                        thinDivider
                            .padding(.horizontal, 24)
                    }
            }
        }
        .modifier(SelectTypeCardBackground())
    }
}

extension SelectTypeView {
        
    private func typeRow(_ type: Event.EventType) -> some View {
        VStack(spacing: 8) {
            typeText(type)
            typeInfo(type)
        }
        .padding(.vertical, openTypes.contains(type) ? 16 : 20) //All padding for view done within each row, so it is incorporated into the tap region. Key
        .padding(.horizontal, 24)
        .overlay(alignment: .topTrailing) { infoButton(type) } // out of flow: its tap region is free (Test)
        .shrinkPress {selectType(eventType: type) }
    }
    
    private func typeText(_ type: Event.EventType) -> some View {
        HStack(spacing: 6) {
            Text(type.emoji)
                .font(.body(16))
                .frame(width: 25, alignment: .leading) //So all same width
            
            
            Text(type.longTitle)
                .font(.body(18, type == selectedType ? .bold : .medium))
                .kerning(kerningAmount(type))
                .foregroundStyle(type == selectedType ? Color.accent : Color.black)
            
            Spacer(minLength: 4) // reserve trailing space so a long title clears the overlaid icon
        }
    }
            
    private func infoButton(_ type: Event.EventType) -> some View {
        Button {
            withAnimation(.smooth(duration: 0.3)) {
                toggleTypeInfo(type)
            }
        } label: {
            SmallInfoIcon(size: 10)
                //Fine tuned padding so hit area large, but not intruding on main button
                .padding(.trailing, 16)
                .padding(.top, 8)
                .padding(.leading, 10)
                .padding(.bottom, 10)
                .contentShape(Rectangle())
        }
        .shrinkButton()
    }

    //3. The Info drop down section
    private func typeInfo(_ type: Event.EventType) -> some View {
        let infoIsOpen = openTypes.contains(type)
        return Group {
            if infoIsOpen {
                Text(type.howItWorks)
                    .infoText()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    private var thinDivider: some View {
        //Display scale gives 1 point height. Must do this method to get half height consistently
        let thickness = (0.5 * displayScale).rounded() / displayScale
        return RoundedRectangle(cornerRadius: 10)
            .frame(maxWidth: .infinity)
            .frame(height: thickness)
            .foregroundStyle(Color(white: 0.93))
    }
}

//Key Functions
extension SelectTypeView {
    
    //1. Each text different kerning so they're all in line
    private func kerningAmount(_ type: Event.EventType) -> CGFloat {
        switch type {
        case .socialMeet:
            return 1.17
            
        case .doubleDate:
            return 0.75
            
        case .drink:
            return 0.525
            
        case .custom:
            return 0
        }
    }

    //2. Logic handling when I select a type
    private func selectType(eventType: Event.EventType) {
        if eventType == .custom && message.isEmpty {
            showMessageScreen = true
        }
        selectedType = eventType
        withAnimation(.easeInOut(duration: 0.25)) {
            showTypePopup = false
        }
        dismissMenu()
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




struct SelectTypeCardBackground: ViewModifier {

    //The 'Menu' takes care of background, this simply give it the parameters
    func body(content: Content) -> some View {
        content
            .frame(width: 280)
            .rectangleStroke(radius: 16, lineWidth: 1, color: Color.grayBackground)
    }
}
