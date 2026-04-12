


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
    
    let sendInvite: (EventDraft) -> ()
    
    var body: some View {
        SelectTimeAndPlace(
            event: $vm.event,
            showInvite: $showInvite,
            name: vm.profile.name,
            image: vm.image,
            defaults: vm.defaults,
            respondWithInvite: false) {
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
    
    var body: some View {
        SelectTimeAndPlace(event: $vm.respondDraft.newEvent, showInvite: $showInvite, name: vm.respondDraft.originalInvite.event.otherUserName, image: vm.image, defaults: vm.defaults, respondWithInvite: true) {
            vm.deleteEventDefault()
        } sendInvite: {
            vm.sendNewInvite()
        }
    }
}


struct SelectTimeAndPlace: View {
    @State private var ui = TimeAndPlaceUIState()
    
    
    @Binding var event: EventDraft
    @Binding var showInvite: Bool
    
    let name: String
    let image: UIImage
    let defaults: DefaultsManaging
    let respondWithInvite: Bool
    
    let deleteEventDefault: () -> ()
    let sendInvite: () -> ()
    
    var isLotsOfText: Bool {
        (event.message?.count ?? 0) > 35
    }
    
    var body: some View {
        ZStack {
            if !respondWithInvite {
                CustomScreenCover {showInvite = false}
            }
            VStack(spacing: 0) {
                popupTitle
                VStack(spacing: 12) {
                    InviteTypeRow(ui: ui, eventType: $event.type, unparsedMessage: $event.message)
                    MapDivider()
                    InviteTimeRow(showTimePopup: $ui.showTimePopup, proposedTimes: $event.proposedTimes, type: event.type)
                    MapDivider()
                    InvitePlaceRow(eventLocation: $event.location, showMapView: $ui.showMapView)
                }
//                .padding(.vertical, decreaseVerticalPadding ? 16 : 24)
                .padding(.top, decreaseVerticalPadding ? 16 : 24)
                .padding(.bottom, (event.location != nil) ? decreaseVerticalPadding ? 16  : 24 : (decreaseVerticalPadding ? 16 : 18)) //Works for complex reasons
                
                
                
//                .padding(.top, decreaseVerticalPadding ? 16 : 24)
//                .padding(.bottom, decreaseVerticalPadding ? 16 : 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .zIndex(1) //so pop ups always appear above the Action Button
                .overlay(alignment: .top) {proposeTwoDaysText}
                sendInviteButton
            }
            .frame(alignment: .top)
            .padding(.horizontal, (isLotsOfText || event.location != nil) ? 28 : 32)
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
        }
        .hideTabBar()
        .customAlert(isPresented: $ui.showAlert, title: "Event Commitment", cancelTitle: "Cancel", okTitle: "I Understand", message: "If they accept & you don't show, you'll be blocked from Scoop", showTwoButtons: true, isConfirmInvite: true) {
            sendInvite()
        }
        .fullScreenCover(isPresented: $ui.showMapView) {
            MapView(defaults: defaults, eventLocation: $event.location)
        }
        .sheet(isPresented: $ui.showMessageScreen) {
            AddMessageView(eventType: $event.type, showMessageScreen: $ui.showMessageScreen, message: $event.message, isRespondMessage: false)
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
            }
            .padding(.top, 24)
            .padding(.horizontal, (isLotsOfText || event.location != nil) ? 28 : 32)
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
    
    private var proposeTwoDaysText: some View {
        Group {
            if showTwoDays {
                Text("Propose at least two days")
            } else if ui.showTimePopup && event.proposedTimes.dates.count > 1 {
                HStack(spacing: 0) {
                    Text("They only accept ")
                    Text("one day")
                        .font(.body(12, .bold))
                }
            }
        }
        .font(.body(12, .regular))
        .foregroundStyle(Color.grayText)
        .padding(.horizontal)
        .background(Color.background)
        .padding(.top, 64)
        .zIndex(0)
    }
    
    private var popupTitle: some View {
        HStack(spacing: respondWithInvite ? 8 : 16) {
            CirclePhoto(image: image, showShadow: false, height: 30)
            Text(respondWithInvite ? "New Event" : "Meet \(name)")
                .font(.custom("SFProRounded-Bold", size: 24))
        }
    }
    
    private var sendInviteButton: some View {
        ActionButton(isValid: !ui.showAlert && InviteIsValid && !showTwoDays, text: "Send Invite", showShadow: false) {
            ui.showAlert.toggle()
        }
    }
    
    private var showTwoDays: Bool {
        (event.type == .drink || event.type == .doubleDate) &&
        !ui.showTypePopup &&
        ((ui.showTimePopup && event.proposedTimes.dates.count < 2) || event.proposedTimes.dates.count == 1)
    }

    private var hasDraftChanges: Bool {
        !event.proposedTimes.dates.isEmpty || event.location != nil || event.type != .drink || event.message != nil
    }
    
    private var InviteIsValid: Bool {
        !event.proposedTimes.dates.isEmpty && event.location != nil
    }
    
    private func horizontalPadding() -> CGFloat {
        let messageLarge: Bool = (event.message?.count ?? 0) > 35
        let messageVLarge: Bool = (event.message?.count ?? 0) > 80
        let placeLarge: Bool = event.location != nil
        
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
    
    //        return (messageLarge && dateLarge) || (messageLarge && placeLarge) || (placeLarge && dateLarge)

    
    
    
    
    private var decreaseVerticalPadding: Bool {
        return (event.message?.count ?? 0) > 40 && event.location != nil
    }
//    private var decreaseEventInfoVerticalPadding: some
}
