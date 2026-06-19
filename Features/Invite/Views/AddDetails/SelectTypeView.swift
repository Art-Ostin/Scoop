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

    //Card corners. Default uniform 16; the invite menu passes top 16 / bottom 10 so it
    //pairs with the "Add a Message" footer beneath it.
    var cardCorners: RectangleCornerRadii = RectangleCornerRadii(uniform: 16)

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
        .modifier(SelectTypeCardBackground(corners: cardCorners))
    }
}

extension SelectTypeView {
        
    private func typeRow(_ type: Event.EventType) -> some View {
        //spacing 0: the 8pt gap under the title now lives inside the revealed region
        //(RevealingInfoText) so it wipes open with the text and leaves no gap when closed.
        VStack(spacing: 0) {
            typeText(type)
            typeInfo(type)
        }
        .padding(.top, 20)
        .padding(.bottom, openTypes.contains(type) ? 12 : 20) //All padding for view done within each row, so it is incorporated into the tap region. Key
        .padding(.horizontal, 24)
        .overlay(alignment: .topTrailing) { infoButton(type) } // out of flow: its tap region is free (Test)
        .padding(.top, type == Event.EventType.allCases.first ? 2 : 0) //extra padding for the first one
        .shrinkPress {selectType(eventType: type) }
    }
    
    private func typeText(_ type: Event.EventType) -> some View {
        HStack(spacing: 6) {
            Text(type.emoji)
                .font(.body(16))
                .frame(width: 25, alignment: .leading) //So all same width
            
            
            Text(type.longTitle)
                .font(.body(18, type == selectedType ? .bold : .medium))
                .kerning(kerningAmount(type)) //Fine tuned kerning so all same width
                .kerning(type == selectedType && type != .custom ? -0.55 : 0)
                .foregroundStyle(type == selectedType ? Color.accent : Color.black)
            
            Spacer(minLength: 4) // reserve trailing space so a long title clears the overlaid icon
        }
    }
            
    private func infoButton(_ type: Event.EventType) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.3)) { //Changing animation here, causes bug with the stroke, which must be updated in the inviteMorph. Be careful
                toggleTypeInfo(type)
            }
        } label: {
            SmallInfoIcon(size: 10, colour: Color(red: 0.88, green: 0.88, blue: 0.88))
                //Fine tuned padding so hit area large, but not intruding on main button
                .padding(.trailing, 16)
                .padding(.top, 8)
                .padding(.leading, 10)
                .padding(.bottom, 10)
                .contentShape(Rectangle())
        }
        .shrinkButton()
    }

    private func typeInfo(_ type: Event.EventType) -> some View {
        RevealingInfoText(text: type.howItWorks, isOpen: openTypes.contains(type))
    }
    
    private var thinDivider: some View {
        //Display scale gives 1 point height. Must do this method to get half height consistently
        let thickness = (0.5 * displayScale).rounded() / displayScale
        return RoundedRectangle(cornerRadius: 10)
            .frame(maxWidth: .infinity)
            .frame(height: thickness)
            .foregroundStyle(Color(white: 0.95))
    }
}

//Key Functions
extension SelectTypeView {
    
    //1. Each text different kerning so they're all in line
    private func kerningAmount(_ type: Event.EventType) -> CGFloat {
        switch type {
        case .socialMeet:
            return 1.25
            
        case .doubleDate:
            return 0.75
            
        case .drink:
            return 0.525
            
        case .custom:
            return -0.3
        }
    }

    //2. Logic handling when I select a type
    private func selectType(eventType: Event.EventType) {
        if eventType == .custom && message.isEmpty {
            selectedType = .custom
            showMessageScreen = true
            Task {
                try? await Task.sleep(for: .seconds(0.04))
                dismissMenu(.instant)
            }
        } else {
            selectedType = eventType
            showTypePopup = false
            dismissMenu()
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


private struct RevealingInfoText: View {
    let text: String
    let isOpen: Bool

    @State private var contentHeight: CGFloat = 0

    var body: some View {
        Text(text)
            .infoText()
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true) //Bug Fix: keep every line
            .padding(.top, 8) //the gap below the title, revealed together with the text
        
            .onGeometryChange(for: CGFloat.self) { geo in
                geo.size.height
            } action: { newHeight in
                contentHeight = newHeight
            }
        
            .frame(height: isOpen ? contentHeight : 0, alignment: .top)
            .clipped()
    }
}

struct SelectTypeCardBackground: ViewModifier {

    //Defaults to a uniform 16 so existing uses are unchanged; the invite menu passes
    //uneven corners to pair the card with its footer.
    var corners: RectangleCornerRadii = RectangleCornerRadii(uniform: 16)

    //The 'Menu' takes care of background, this simply give it the parameters
    func body(content: Content) -> some View {
        content
            .frame(width: 270)
            .rectangleStroke(corners: corners, lineWidth: 1, color: Color.grayBackground)
    }
}
