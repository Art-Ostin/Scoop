import SwiftUI
import MapKit



struct SelectTimeAndPlace: View {
    
    let firstImage: UIImage
    @State var vm: TimeAndPlaceViewModel
    @Binding var showInvite: Bool
    
    let onSubmit: @Sendable (EventDraft) async -> Void
    @State var showInfoScreen: Bool = false
    
    var showProposeTwoDays: Bool {
        (vm.event.type == .drink || vm.event.type == .doubleDate) &&
        !vm.showTypePopup &&
        ((vm.showTimePopup && vm.event.proposedTimes.dates.count < 2) || vm.event.proposedTimes.dates.count == 1)
    }

    init(defaults: DefaultsManaging, sessionManager: SessionManager, profile: UserProfile, showInvite: Binding<Bool>, onSubmit: @escaping (EventDraft) async -> ()) {
        _vm = .init(initialValue: .init(defaults: defaults, sessionManager: sessionManager, profile: profile))
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
        VStack(spacing: 20) {
            HStack(spacing: 16) {
                CirclePhoto(image: firstImage)
                
                
                Text("Meet \(vm.profile.name)")
                        .font(.custom("SFProRounded-Bold", size: 24))
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
                    SelectTimeView(vm: vm, showTimePopup: $vm.showTimePopup)
                        .zIndex(2)
                }
                Divider()
                InvitePlaceRow
                    .frame(height: 50)
            }
            .zIndex(1) //so pop ups always appear above the Action Button
            .overlay(alignment: .top) {
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
            ActionButton(isValid: !vm.showAlert && InviteIsValid && !showProposeTwoDays, text: "Confirm & Send") {
                vm.showAlert.toggle()
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
        .overlay(alignment: .topLeading) {
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
    }
    
    private var InvitePlaceRow: some View {
        HStack {
            if let location = vm.event.location {
                VStack(alignment: .leading) {
                    Text(location.name ?? "")
                        .font(.body(18, .bold))
                    Text(addressWithoutCountry(location.address))
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
    
    func addressWithoutCountry(_ address: String?) -> String {
        let parts = (address ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        return parts.dropLast().joined(separator: ", ")
    }
    
    private func inviteSent() {
        Task { await onSubmit(vm.event)}
    }
}
