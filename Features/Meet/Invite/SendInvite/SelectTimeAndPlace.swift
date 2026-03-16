import SwiftUI
import MapKit



struct SelectTimeAndPlace: View {
    
    @State var vm: TimeAndPlaceViewModel
    @State private var ui = TimeAndPlaceUIState ()
    
    @Binding var showInvite: Bool
    
    let firstImage: UIImage
    let onSubmit: (EventDraft) -> ()
    
    var showProposeTwoDays: Bool {
        (vm.event.type == .drink || vm.event.type == .doubleDate) &&
        !ui.showTypePopup &&
        ((ui.showTimePopup && vm.event.proposedTimes.dates.count < 2) || vm.event.proposedTimes.dates.count == 1)
    }

    init(d: DefaultsManaging, s: SessionManager, p: UserProfile, showInvite: Binding<Bool>, onSubmit: @escaping (EventDraft) -> ()) {
        _vm = .init(initialValue: .init(defaults: d, sessionManager: s, profile: p))
        self._showInvite = showInvite
        self.onSubmit = onSubmit
    }
    
    var body: some View {
        ZStack {
            CustomScreenCover {showInvite = false}
            sendInviteScreen
                .overlay(alignment: .topTrailing) {
                    TabInfoButton(showScreen: $showInfoScreen)
                        .scaleEffect(0.9)
                        .offset(x: -12, y: -48)
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .toolbar(.hidden, for: .tabBar)
        .tabBarHidden(true) // This is custom Tool bar hidden
        .sheet(isPresented: $vm.showMessageScreen) {AddMessageView(vm: vm)}
        .fullScreenCover(isPresented: $vm.showMapView) {
            MapView(defaults: vm.defaults, eventVM: vm)
        }
        .customAlert(isPresented: $vm.showAlert, title: "Event Commitment", cancelTitle: "Cancel", okTitle: "I Understand", message: "If they accept & you don't show, you'll be blocked from Scoop", showTwoButtons: true, isConfirmInvite: true) {
            inviteSent()
        }
        .tint(.blue)
        .sheet(isPresented: $showInfoScreen) {
            Text("Info screen here")
        }
        
    }
    private var InviteIsValid: Bool {
        return !vm.event.proposedTimes.dates.isEmpty && vm.event.location != nil
    }
}


extension SelectTimeAndPlace {
    
    
    @ViewBuilder
    private var sendInviteScreen: some View {
        
        VStack {
            popupTitle
            

            VStack(spacing: 10) {
                
                InviteTypeRow(vm: vm, ui: ui)
                
                Divider()
                
                
                
                DropDownView(showOptions: $vm.showTimePopup) {
                    InviteTimeRow(vm: vm)
                        .frame(height: 50)
                } dropDown: {
                    SelectTimeView(vm: vm, showTimePopup: $vm.showTimePopup)
                        .zIndex(2)
                }
                Divider()
                InvitePlaceRow
                    .frame(height: 50)
            }
            .zIndex(1) //so pop ups always appear above the Action Button
            .overlay(alignment: .top) {proposeTwoDaysText}
            
            sendInviteButton
        
        }
        .frame(alignment: .top)
        .padding(.top, 24)
        .padding([.leading, .trailing, .bottom], 32)

        
        
        
        
        .frame(width: 365)
        .background (cardBackground)
        .onChange(of: ui.showTypePopup) {
            if ui.showTypePopup == true {
                ui.showTimePopup = false
            }
        }
        .onChange(of: vm.showTimePopup) {
            if vm.showTimePopup == true {
                vm.showTypePopup = false
            }
        }
        .overlay(alignment: .topLeading) { clearButton}
    }
    
    private var clearButton: some View {
        Button {
            vm.deleteEventDefault()
        } label: {
            if !vm.event.proposedTimes.dates.isEmpty || vm.event.location != nil || vm.event.type != .drink || vm.event.message != nil {
                Text("Clear")
                    .font(.body(12, .regular))
                    .foregroundStyle(Color (red: 0.7, green: 0.7, blue: 0.7))
                    .padding()
                    .padding()
                    .offset(x: -7)
                    .offset(y: -7)
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
            if showProposeTwoDays {
                Text("Propose at least two days")
            }
            else if vm.showTimePopup && vm.event.proposedTimes.dates.count > 1 {
                (
                    Text("They only accept ")
                    +
                    Text("one day")
                        .font(.body(12, .bold))
                )
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
            CirclePhoto(image: firstImage)
            Text("Meet \(vm.profile.name)")
                .font(.custom("SFProRounded-Bold", size: 24))
        }
    }
    
    private var sendInviteButton: some View {
        ActionButton(isValid: !ui.showAlert && InviteIsValid && !showProposeTwoDays, text: "Confirm & Send") {
            ui.showAlert.toggle()
        }
    }
    
    private func inviteSent() {
        Task { await onSubmit(vm.event)}
    }
}
