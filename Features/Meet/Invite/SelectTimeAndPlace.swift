import SwiftUI
import MapKit



struct SelectTimeAndPlace: View {
    
    @State var vm: TimeAndPlaceViewModel
    let onDismiss: () -> Void
    let onSubmit: @Sendable (EventDraft) async -> Void
    @State var showInfoScreen: Bool = false
    
    let rowHeight = CGFloat(60)

    init(
        defaults: DefaultsManaging,
        sessionManager: SessionManager,
        profile: ProfileModel? = nil,
        text: String = "Confirm & Send",
        onDismiss: @escaping () -> Void,
        onSubmit: @escaping (EventDraft) async -> ()
    ) {
        _vm = .init(initialValue: .init(defaults: defaults, sessionManager: sessionManager, text: text, profile: profile))
        self.onDismiss = onDismiss
        self.onSubmit = onSubmit
    }
    
    var body: some View {
        ZStack {
            CustomScreenCover {onDismiss()}
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
        .sheet(isPresented: $vm.showMessageScreen) {AddMessageView(vm: $vm)}
        .fullScreenCover(isPresented: $vm.showMapView) {
            MapView(defaults: vm.defaults, eventVM: vm)
        }
        .animation(.easeInOut(duration: 0.2), value: vm.showTypePopup)
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
    
    private var sendInviteScreen: some View {
        VStack(spacing: 20) {
            if vm.text == "Confirm & Send" {
                HStack(spacing: 16) {
                    CirclePhoto(image: vm.profile?.image ?? UIImage())
                    
                    
                    if let name = vm.profile?.profile.name {
                        Text("Meet \(name)")
                            .font(.custom("SFProRounded-Bold", size: 24))
                    }
                }
            }

            VStack(spacing: 10) {
                DropDownView(showOptions: $vm.showTypePopup) {
                    InviteTypeRow(vm: vm)
                        .frame(height: 50)
                } dropDown: {
                    SelectTypeView(vm: vm, selectedType: vm.event.type, showTypePopup: $vm.showTypePopup)
                }
                
                Divider()
                DropDownView(showOptions: $vm.showTimePopup) {
                    InviteTimeRow(vm: vm)
                        .frame(height: 50)
                } dropDown: {
                    SelectTimeView(vm: vm)
                        .zIndex(2)
                }
                Divider()
                InvitePlaceRow
                    .frame(height: 50)
            }
            .zIndex(1) //so pop ups always appear above the Action Button
            .overlay(alignment: .top) {
                if (vm.event.type == .drink || vm.event.type == .doubleDate) && !vm.showTypePopup
                        && ((vm.showTimePopup && vm.event.proposedTimes.dates.count < 3)
                            || vm.event.proposedTimes.dates.count == 1) {
                        Text("Propose at least two days")
                            .font(.body(12, .regular))
                            .foregroundStyle(Color.grayText)
                            .padding(.horizontal)
                            .background(Color.background)
                            .padding(.top, 66)
                            .zIndex(0)
                }
            }
            ActionButton(isValid: !vm.showAlert && InviteIsValid, text: vm.text) {
                vm.showAlert.toggle()
            }
        }
        .frame(alignment: .top)
        .padding(.top, 24)
        .padding([.leading, .trailing, .bottom], 32)
        .frame(width: 365)
        .background (
            ZStack { //Background done like this to fix bugs when popping up
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.background)
                    .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 4)
                RoundedRectangle(cornerRadius: 30)
                    .inset(by: 0.5)
                    .stroke(Color.grayBackground, lineWidth: 0.5)
            }
        )
        .onChange(of: vm.showTypePopup) {
            if vm.showTypePopup == true {
                vm.showTimePopup = false
            }
        }
        .onChange(of: vm.showTimePopup) {
            if vm.showTimePopup == true {
                vm.showTypePopup = false
            }
        }
    }
    
    private var InvitePlaceRow: some View {
        HStack {
            if let location = vm.event.location {
                VStack(alignment: .leading) {
                    Text(location.name ?? "")
                        .font(.body(18, .bold))
                    Text(location.address ?? "")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                }
            } else {
                Text("Place")
                    .font(.body(20, .bold))
            }
            Spacer()
            Button {
                withAnimation(.snappy) {
                    vm.showMapView.toggle()
                }
            } label:  {
                Image("InvitePlace")
            }
        }
    }
    private func inviteSent() {
        Task { await onSubmit(vm.event)}
    }
}



/*
 .alert("Event Commitment", isPresented: $vm.showAlert) {
     Button("Cancel", role: .cancel) { }
     Button ("I Understand") {
         onDismiss()
         Task { await onSubmit(vm.event)}
     }
 } message : {
     Text("If you don't show, you'll be blocked from Scoop")
 }

 */
