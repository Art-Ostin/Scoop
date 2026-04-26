


import SwiftUI
import MapKit

@Observable class TimeAndPlaceUIState {
    var showTypePopup: Bool = false
    var showTimePopup: Bool = false
    var showMessageScreen: Bool = false
    var showMapView: Bool = false
    var showAlert: Bool = false
    var isMessageTap: Bool = false
    var showInfoScreen: Bool = false
    let rowHeight: CGFloat = 50
}


@MainActor
struct InviteTimeAndPlaceView: View {
    
    @State var vm: TimeAndPlaceViewModel
    @Binding var showInvite: Bool
    var isNewEvent: Bool = false
    
    let sendInvite: (EventFieldsDraft) -> ()
    
    
    var body: some View {
        //Update the 'draft' to new place
        SelectTimeAndPlace(
            draft: $vm.event,
            showInvite: $showInvite,
            name:vm.profile.name,
            image: vm.image,
            defaults: vm.defaults,
            respondWithInvite: false,
            isNewEvent: isNewEvent) {
                vm.deleteEventDefault()
            } sendInvite: {
                sendInvite(vm.event)
            }
    }
}

@MainActor
struct RespondTimeAndPlaceView: View {
    @Bindable var vm: RespondViewModel
    @Binding var showInvite: Bool
    @Binding var showConfirmSendInvite: Bool
    var isNewEvent: Bool = false
    let sendInvite: (String) -> ()
    
    var body: some View {
        SelectTimeAndPlace(
            draft: $vm.respondDraft.newEvent,
            showInvite: $showInvite,
            showConfirmSendInvite: $showConfirmSendInvite,
            name: vm.respondDraft.originalInvite.event.otherUserName,
            image: vm.image,
            defaults: vm.defaults,
            respondWithInvite: true,
            isNewEvent: isNewEvent) {
                vm.deleteEventDefault()
            } sendInvite: {
                sendInvite(vm.respondDraft.originalInvite.event.id)
            }
    }
}

struct SelectTimeAndPlace: View {
    @State private var ui = TimeAndPlaceUIState()
    
    @Binding var draft: EventFieldsDraft
    @Binding var showInvite: Bool
    var showConfirmSendInvite: Binding<Bool>?

    let name: String
    let image: UIImage
    let defaults: DefaultsManaging
    let respondWithInvite: Bool
    var isNewEvent: Bool = false
    
    let deleteEventDefault: () -> ()
    let sendInvite: () -> ()
    
    
    var isLotsOfText: Bool {
        (draft.message?.count ?? 0) > 35
    }
    
    
    var body: some View {
        ZStack {
            if !respondWithInvite {
                CustomScreenCover {showInvite = false}
            }
            VStack(spacing: 0) {
                popupTitle
                VStack(spacing: 12) {
                    InviteTypeRow(ui: ui, eventType: $draft.type, unparsedMessage: $draft.message)
                    MapDivider()
                    InviteTimeRow(showTimePopup: $ui.showTimePopup, proposedTimes: $draft.time, type: draft.type)
                    MapDivider()
                    InvitePlaceRow(eventLocation: $draft.place, showMapView: $ui.showMapView)
                }
                .padding(.top, decreaseVerticalPadding ? 16 : 24)
                .padding(.bottom, (draft.place != nil) ? decreaseVerticalPadding ? 16  : 24 : (decreaseVerticalPadding ? 16 : 18)) //Works for complex reasons
                .frame(maxWidth: .infinity, alignment: .leading)
                .zIndex(1) //so pop ups always appear above the Action Button
                sendInviteButton
            }
            .frame(alignment: .top)
            .padding(.horizontal, (isLotsOfText || draft.place != nil) ? 28 : 32)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .background (cardBackground)
            .overlay(alignment: .topLeading) { clearButton }
            .padding(.horizontal, horizontalPadding())
            .onChange(of: ui.showTypePopup) {_, newValue in
                if newValue { ui.showTimePopup = false}
            }
            .onChange(of: ui.showTimePopup) { _, newValue in
                if newValue { ui.showTypePopup = false}
            }
            .overlay(alignment: .topTrailing) { infoButton }
            .offset(y: !respondWithInvite ? 24 : 0)
            .overlay(alignment: .top) {
                    let dayCount = draft.time.dates.count
                SelectTimeMessage(type: draft.type, dayCount: dayCount, showTimePopup: ui.showTimePopup, isCardMessage: true)
            }
        }
        .hideTabBar()
        .customAlert(isPresented: $ui.showAlert, title: "Event Commitment", cancelTitle: "Cancel", okTitle: "I Understand", message: "If they accept & you don't show, you'll be blocked from Scoop", showTwoButtons: true, isConfirmInvite: true) {
            sendInvite()
        }
        .fullScreenCover(isPresented: $ui.showMapView) {
            MapView(defaults: defaults, eventLocation: $draft.place)
        }
        .sheet(isPresented: $ui.showMessageScreen) {
            AddMessageView(eventType: $draft.type, showMessageScreen: $ui.showMessageScreen, message: $draft.message, isRespondMessage: false)
        }
        .sheet(isPresented: $ui.showInfoScreen) { Text("Info screen here") }
    }
}

extension SelectTimeAndPlace {
    
    private var infoButton: some View {
        TabInfoButton(showScreen: $ui.showInfoScreen)
            .scaleEffect(0.9)
            .offset(y: -48)
            .padding(.horizontal, horizontalPadding())
    }

    @ViewBuilder
    private var clearButton: some View {
        if hasDraftChanges {
            Button {
                deleteEventDefault()
            } label: {
                Text("Clear")
                    .font(.body(12, .regular))
                    .foregroundStyle(Color (red: 0.7, green: 0.7, blue: 0.7))
                    .offset(x: -10, y: -8)
            }
            .padding(.top, 24)
            .padding(.horizontal, (isLotsOfText || draft.place != nil) ? 28 : 32)
        }
    }
    
    private var cardBackground: some View {
        ZStack { //Background done like this to fix bugs when popping up
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.background)
                .shadow(color: .accent.opacity(0.15), radius: 4, y: 2)
                .shadow(color: .white.opacity(0.2), radius: 7, x: 0, y: 5)
            RoundedRectangle(cornerRadius: 30)
                .inset(by: 0.5)
                .stroke(Color.grayBackground, lineWidth: 0.5)
        }
    }
        
    private var popupTitle: some View {
        HStack(spacing: 8) {
            CirclePhoto(image: image, showShadow: false, height: 30)
            Text(respondWithInvite ? "New Invite" : (isNewEvent ? "Send New Invite" : "Meet \(name)"))
                .font(.custom("SFProRounded-Bold", size: 24))
        }
    } //respondWithInvite ? "New Event" : (
    
    
    private var sendInviteButton: some View {
        ActionButton(isValid: !ui.showAlert && InviteIsValid && !showTwoDays, text: "Send Invite", showShadow: false) {
            if let showConfirmSendInvite {
                showConfirmSendInvite.wrappedValue = true
            } else {
                ui.showAlert.toggle()
            }
        }
    }
    
    private var showTwoDays: Bool {
        (draft.type == .drink || draft.type == .doubleDate) &&
        !ui.showTypePopup &&
        ((ui.showTimePopup && draft.time.dates.count < 2) || draft.time.dates.count == 1)
    }

    private var hasDraftChanges: Bool {
        !draft.time.dates.isEmpty || draft.place != nil || draft.type != .drink || draft.message != nil
    }
    
    private var InviteIsValid: Bool {
        !draft.time.dates.isEmpty && draft.place != nil
    }
    
    private func horizontalPadding() -> CGFloat {
        let messageLarge: Bool = (draft.message?.count ?? 0) > 35
        let messageVLarge: Bool = (draft.message?.count ?? 0) > 80
        let placeLarge: Bool = draft.place != nil
        
        var originalHPadding:CGFloat = 30
        
        if messageLarge {
            originalHPadding -= 2
        }
        
        if messageVLarge {
            originalHPadding -= 2
        }
        
        if placeLarge {
            originalHPadding -= 2
        }
        return originalHPadding
    }
    
    private var decreaseVerticalPadding: Bool {
        return (draft.message?.count ?? 0) > 40 && draft.place != nil
    }
}
