


import SwiftUI
import MapKit



@MainActor
struct InviteTimeAndPlaceView {
    
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
struct RespondTimeAndPlaceView {
    
    @Bindable var vm: RespondViewModel
    @Binding var showInvite: Bool
    
    var body: some View {
        SelectTimeAndPlace(event: $vm.respondDraft.eventDraft, showInvite: $showInvite, name: vm.respondDraft.event.otherUserName, image: vm.image, defaults: vm.defaults, respondWithInvite: true) {
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
    
    var body: some View {
        ZStack {
            if !respondWithInvite {
                CustomScreenCover {showInvite = false}
            }
            sendInviteScreen
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
            AddMessageView(eventType: $event.type, showMessageScreen: $ui.showMessageScreen, message: $event.message)
        }
        .sheet(isPresented: $ui.showInfoScreen) { Text("Info screen here") }
    }
}

extension SelectTimeAndPlace {
    
    @ViewBuilder
    private var sendInviteScreen: some View {
        
        VStack(spacing: 16) {
            popupTitle
            VStack(spacing: 10) {
                InviteTypeRow(ui: ui, eventType: $event.type, unparsedMessage: $event.message)
                Divider()
                InviteTimeRow(showTimePopup: $ui.showTimePopup, proposedTimes: $event.proposedTimes)
                Divider()
                InvitePlaceRow(eventLocation: $event.location, showMapView: $ui.showMapView)
            }
            .zIndex(1) //so pop ups always appear above the Action Button
            .overlay(alignment: .top) {proposeTwoDaysText}
            sendInviteButton
        }
        .frame(alignment: .top)
        .padding(.vertical, 24)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
        .background (cardBackground)
        .padding(.horizontal, 16)
        .onChange(of: ui.showTypePopup) {_, newValue in
            if newValue { ui.showTimePopup = false}
        }
        .onChange(of: ui.showTimePopup) { _, newValue in
            if newValue { ui.showTypePopup = false}
        }
        .overlay(alignment: .topLeading) { clearButton}
    }
    
    private var infoButton: some View {
        TabInfoButton(showScreen: $ui.showInfoScreen)
            .scaleEffect(0.9)
            .offset(x: -16, y: -48)
    }

    private var clearButton: some View {
        Button {
            deleteEventDefault()
        } label: {
            if !event.proposedTimes.dates.isEmpty || event.location != nil || event.type != .drink || event.message != nil {
                Text("Clear")
                    .font(.body(12, .regular))
                    .foregroundStyle(Color (red: 0.7, green: 0.7, blue: 0.7))
                    .padding()
                    .padding()
                    .offset(x: 4)
                    .offset(y: -12)
            }
        }
    }
    
    private var cardBackground: some View {
        ZStack { //Background done like this to fix bugs when popping up
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.background)
                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 4)
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
        HStack(spacing: 16) {
            CirclePhoto(image: image, showShadow: false)
            //HERE IS ONE
            Text("Meet \(name)")
                .font(.custom("SFProRounded-Bold", size: 24))
        }
    }
    
    private var sendInviteButton: some View {
        ActionButton(isValid: !ui.showAlert && InviteIsValid && !showTwoDays, text: "Confirm & Send") {
            ui.showAlert.toggle()
        }
    }
    
    private var showTwoDays: Bool {
        (event.type == .drink || event.type == .doubleDate) &&
        !ui.showTypePopup &&
        ((ui.showTimePopup && event.proposedTimes.dates.count < 2) || event.proposedTimes.dates.count == 1)
    }
    
    private var InviteIsValid: Bool {
        return !event.proposedTimes.dates.isEmpty && event.location != nil
    }
}
